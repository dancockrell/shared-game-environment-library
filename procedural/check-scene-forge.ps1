param(
    [string]$Godot,
    [string]$Cargo = 'cargo',
    [ValidateRange(10,600)][int]$TimeoutSeconds = 90,
    [ValidateRange(4,128)][int]$MinimumFreeRamGiB = 6,
    [ValidateRange(256,2048)][int]$MaximumProcessMiB = 1024
)
$ErrorActionPreference = 'Stop'
$forgeRoot = $PSScriptRoot
if ($Godot) { throw 'Automatic Godot launches are retired. Omit -Godot for CPU-only checks. Engine validation requires a separately managed reusable session; this command will not open or close it.' }
$runRoot = Join-Path $forgeRoot ('generated/reviews/' + [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $runRoot -Force | Out-Null
$report = [ordered]@{
    started_utc = [DateTime]::UtcNow.ToString('o'); status = 'running';
    scope = 'CPU compiler and deterministic fixtures only; no engine launched';
    engine_checks = 'not_run'; visual_review = 'not_run'; gpu_memory = 'not_measured';
    limits = @{minimum_free_ram_gib=$MinimumFreeRamGiB; maximum_process_mib=$MaximumProcessMiB; timeout_seconds=$TimeoutSeconds; cargo_jobs=1; test_threads=1};
    steps = [System.Collections.Generic.List[object]]::new();
    fixtures = [System.Collections.Generic.List[object]]::new();
    source_hashes = [ordered]@{}
}
function Invoke-NativeCheck([string]$Name, [string]$Executable, [string[]]$Arguments) {
    $log = Join-Path $runRoot ($Name + '.log')
    $errorLog = Join-Path $runRoot ($Name + '.stderr.log')
    $freeRam = { [long](Get-CimInstance Win32_OperatingSystem -ErrorAction Stop).FreePhysicalMemory * 1024 }
    if ((& $freeRam) -lt $MinimumFreeRamGiB * 1GB) { throw "Insufficient shared-machine RAM headroom before $Name" }
    $resolved = (Get-Command $Executable -ErrorAction Stop).Source
    if ($Arguments | Where-Object { $_.Contains('"') }) { throw 'Unexpected quote in native argument' }
    $quoted = $Arguments | ForEach-Object { '"' + $_ + '"' }
    $watch = [Diagnostics.Stopwatch]::StartNew()
    $process = Start-Process -FilePath $resolved -ArgumentList $quoted -WindowStyle Hidden -PassThru -RedirectStandardOutput $log -RedirectStandardError $errorLog
    $peak = $null
    $minFree = [long]::MaxValue
    $failure = $null
    try {
        if (-not $process.HasExited) { $process.PriorityClass = 'BelowNormal' }
        while (-not $process.WaitForExit(500)) {
            $process.Refresh()
            if ($null -eq $peak -or $process.WorkingSet64 -gt $peak) { $peak = $process.WorkingSet64 }
            $free = & $freeRam
            $minFree = [Math]::Min($minFree, $free)
            if ($process.WorkingSet64 -gt $MaximumProcessMiB * 1MB) { throw "$Name exceeded its root-process RAM ceiling" }
            if ($free -lt $MinimumFreeRamGiB * 1GB) { throw "$Name stopped to preserve shared-machine RAM headroom" }
            if ($watch.Elapsed.TotalSeconds -gt $TimeoutSeconds) { throw "$Name timed out" }
        }
        $process.Refresh()
        if ($process.ExitCode -ne 0) { throw "$Name failed with exit $($process.ExitCode); see $errorLog" }
    } catch {
        $failure = $_.Exception.Message
        if (-not $process.HasExited) { $process.Kill($true); $process.WaitForExit() }
        throw
    } finally {
        $report.steps.Add(@{name=$Name; seconds=$watch.Elapsed.TotalSeconds; log=$log; stderr=$errorLog; error=$failure; sampled_root_working_set_peak_bytes=$peak; minimum_sampled_free_ram_bytes=$(if ($minFree -eq [long]::MaxValue) {$null} else {$minFree}); memory_scope='root working set plus whole-machine free RAM; not tree peak or VRAM'})
        $process.Dispose()
    }
}
try {
    $manifest = Join-Path $forgeRoot 'Cargo.toml'
    foreach ($path in @('src','examples','godot/addons/scene_forge','unity')) {
        foreach ($file in Get-ChildItem -LiteralPath (Join-Path $forgeRoot $path) -File -Recurse | Sort-Object FullName) {
            $relative = [IO.Path]::GetRelativePath($forgeRoot,$file.FullName)
            $report.source_hashes[$relative] = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
        }
    }
    foreach ($path in @('Cargo.toml','Cargo.lock','check-scene-forge.ps1','godot/test_import.gd','godot/pack_scene.gd')) {
        $report.source_hashes[$path] = (Get-FileHash -LiteralPath (Join-Path $forgeRoot $path) -Algorithm SHA256).Hash
    }
    Invoke-NativeCheck 'rust-tests' $Cargo @('test','--locked','-j','1','--manifest-path',$manifest,'--','--test-threads=1')
    Invoke-NativeCheck 'rust-format' $Cargo @('fmt','--manifest-path',$manifest,'--','--check')
    Invoke-NativeCheck 'rust-clippy' $Cargo @('clippy','--locked','-j','1','--manifest-path',$manifest,'--all-targets','--','-D','warnings')
    Invoke-NativeCheck 'rust-release' $Cargo @('build','--release','--locked','-j','1','--manifest-path',$manifest)
    $compiler = Join-Path $forgeRoot 'target/release/scene-forge-cli.exe'
    $report.compiler_sha256 = (Get-FileHash -LiteralPath $compiler).Hash
    foreach ($recipe in Get-ChildItem -LiteralPath (Join-Path $forgeRoot 'examples') -Filter '*.json' -File | Sort-Object Name) {
        $name = $recipe.BaseName
        $scenePath = Join-Path $runRoot ($name + '.json')
        $repeatPath = Join-Path $runRoot ($name + '-repeat.json')
        Invoke-NativeCheck "$name-compile" $compiler @($recipe.FullName,$scenePath)
        Invoke-NativeCheck "$name-determinism" $compiler @($recipe.FullName,$repeatPath)
        if ((Get-FileHash $scenePath).Hash -ne (Get-FileHash $repeatPath).Hash) { throw "$name is not byte deterministic" }
        # Do not inflate entire scene arrays into PowerShell objects.
        $report.fixtures.Add(@{name=$name; output=$scenePath; sha256=(Get-FileHash $scenePath).Hash; file_bytes=(Get-Item $scenePath).Length; render=$null; package=$null; engine_checks='not_run'})
    }
    foreach ($relative in $report.source_hashes.Keys) {
        if ((Get-FileHash -LiteralPath (Join-Path $forgeRoot $relative)).Hash -ne $report.source_hashes[$relative]) {
            throw "Source changed during verification: $relative; results cannot certify one version"
        }
    }
    $report.status = 'passed'
} catch {
    $report.status = 'failed'
    $report.error = $_.Exception.Message
    throw
} finally {
    $report.finished_utc = [DateTime]::UtcNow.ToString('o')
    $report | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath (Join-Path $runRoot 'report.json') -Encoding utf8
    Write-Output "Scene Forge CPU-only verification $($report.status): $runRoot"
}
