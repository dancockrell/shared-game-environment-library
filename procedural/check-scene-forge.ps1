param(
    [Parameter(Mandatory)][string]$Godot,
    [string]$Cargo = 'cargo',
    [ValidateRange(10,600)][int]$TimeoutSeconds = 90
)
$ErrorActionPreference = 'Stop'
$forgeRoot = $PSScriptRoot
$Godot = (Resolve-Path -LiteralPath $Godot).Path
if ($Godot.EndsWith('_console.exe')) { throw 'Use the graphics executable, not its console wrapper, so timeout ownership is exact.' }
$runRoot = Join-Path $forgeRoot ('generated/reviews/' + [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $runRoot -Force | Out-Null
$report = [ordered]@{
    started_utc = [DateTime]::UtcNow.ToString('o'); status = 'running';
    scope = 'Compiler and Godot graphics-backed fixtures; not artistic admission, Unity certification or VRAM measurement';
    godot = $Godot; steps = [System.Collections.Generic.List[object]]::new();
    fixtures = [System.Collections.Generic.List[object]]::new();
    source_hashes = [ordered]@{}
}
function Invoke-NativeCheck([string]$Name, [string]$Executable, [string[]]$Arguments) {
    $log = Join-Path $runRoot ($Name + '.log')
    $watch = [Diagnostics.Stopwatch]::StartNew()
    & $Executable @Arguments *> $log
    $code = $LASTEXITCODE
    $report.steps.Add(@{name=$Name; exit_code=$code; seconds=$watch.Elapsed.TotalSeconds; log=$log})
    if ($code -ne 0) { throw "$Name failed with exit $code; see $log" }
}
function Invoke-GodotCheck([string]$Name, [string]$Script, [string[]]$Inputs, [string]$Marker, [switch]$ExpectDummyFailure) {
    $log = Join-Path $runRoot ($Name + '.log')
    $arguments = @('--path',(Join-Path $forgeRoot 'godot'),'--log-file',$log,'--script',$Script)
    if ($ExpectDummyFailure) { $arguments += '--headless' }
    else { $arguments += @('--position','-4000,-4000','--no-focus','--max-fps','10','--rendering-method','gl_compatibility') }
    $arguments += @('--') + $Inputs
    # Windows paths cannot contain quote characters. Quote all arguments, including spaces.
    $quoted = $arguments | ForEach-Object { '"' + $_ + '"' }
    $watch = [Diagnostics.Stopwatch]::StartNew()
    $process = Start-Process -FilePath $Godot -ArgumentList $quoted -WindowStyle Hidden -PassThru
    try {
        if (-not $process.HasExited) { $process.PriorityClass = 'BelowNormal' }
        if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
            # Only the process created by this invocation is terminated.
            $process.Kill(); $process.WaitForExit()
            throw "$Name timed out; retained log: $log"
        }
        $process.Refresh()
        $code = $process.ExitCode
        $text = Get-Content -LiteralPath $log -Raw
        $report.steps.Add(@{name=$Name; exit_code=$code; seconds=$watch.Elapsed.TotalSeconds; log=$log})
        $expectedCode = if ($ExpectDummyFailure) { 1 } else { 0 }
        if ($code -ne $expectedCode -or -not $text.Contains($Marker)) { throw "$Name failed its exit/marker contract; see $log" }
        if (-not $ExpectDummyFailure -and $text -match '(?m)^(SCRIPT ERROR:|ERROR:)') { throw "$Name logged an engine error; see $log" }
    } finally { $process.Dispose() }
}
try {
    $manifest = Join-Path $forgeRoot 'Cargo.toml'
    foreach ($path in @('src','examples','godot/addons/scene_forge','unity/Editor')) {
        foreach ($file in Get-ChildItem -LiteralPath (Join-Path $forgeRoot $path) -File -Recurse | Sort-Object FullName) {
            $relative = [IO.Path]::GetRelativePath($forgeRoot,$file.FullName)
            $report.source_hashes[$relative] = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
        }
    }
    foreach ($path in @('Cargo.toml','Cargo.lock','check-scene-forge.ps1','godot/test_import.gd','godot/pack_scene.gd')) {
        $report.source_hashes[$path] = (Get-FileHash -LiteralPath (Join-Path $forgeRoot $path) -Algorithm SHA256).Hash
    }
    Invoke-NativeCheck 'rust-tests' $Cargo @('test','--locked','--manifest-path',$manifest)
    Invoke-NativeCheck 'rust-format' $Cargo @('fmt','--manifest-path',$manifest,'--','--check')
    Invoke-NativeCheck 'rust-clippy' $Cargo @('clippy','--locked','--manifest-path',$manifest,'--all-targets','--','-D','warnings')
    Invoke-NativeCheck 'rust-release' $Cargo @('build','--release','--locked','--manifest-path',$manifest)
    $compiler = Join-Path $forgeRoot 'target/release/scene-forge-cli.exe'
    $report.compiler_sha256 = (Get-FileHash -LiteralPath $compiler).Hash
    foreach ($recipe in Get-ChildItem -LiteralPath (Join-Path $forgeRoot 'examples') -Filter '*.json' -File | Sort-Object Name) {
        $name = $recipe.BaseName
        $scenePath = Join-Path $runRoot ($name + '.json')
        $repeatPath = Join-Path $runRoot ($name + '-repeat.json')
        Invoke-NativeCheck "$name-compile" $compiler @($recipe.FullName,$scenePath)
        Invoke-NativeCheck "$name-determinism" $compiler @($recipe.FullName,$repeatPath)
        if ((Get-FileHash $scenePath).Hash -ne (Get-FileHash $repeatPath).Hash) { throw "$name is not byte deterministic" }
        $scene = Get-Content -LiteralPath $scenePath -Raw | ConvertFrom-Json
        $png = Join-Path $runRoot ($name + '.png')
        $package = Join-Path $runRoot ($name + '.scn')
        Invoke-GodotCheck "$name-render" 'res://test_import.gd' @($scenePath,$png) 'Spatial checks: graphics-backed transforms and bounds verified'
        if (-not (Test-Path -LiteralPath $png) -or (Get-Item -LiteralPath $png).Length -eq 0) { throw "$name has no render" }
        Invoke-GodotCheck "$name-package" 'res://pack_scene.gd' @($scenePath,$package) 'Verified native package buffers, bounds and materials'
        $report.fixtures.Add(@{name=$name; instances=$scene.instances.Count; shared_meshes=$scene.meshes.Count; estimated_geometry_bytes=$scene.estimated_geometry_bytes; render=$png; package=$package; package_sha256=(Get-FileHash $package).Hash; visual_review='pending'})
    }
    $firstScene = Join-Path $runRoot ($report.fixtures[0].name + '.json')
    $dummyOutput = Join-Path $runRoot 'dummy-must-not-save.scn'
    Invoke-GodotCheck 'reject-dummy-export' 'res://pack_scene.gd' @($firstScene,$dummyOutput) 'Missing MultiMesh instance buffer' -ExpectDummyFailure
    if (Test-Path -LiteralPath $dummyOutput) { throw 'Dummy export left an invalid package' }
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
    Write-Output "Scene Forge verification $($report.status): $runRoot"
}
