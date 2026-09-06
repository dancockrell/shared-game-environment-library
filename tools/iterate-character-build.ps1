param(
    [Parameter(Mandatory=$true)][string]$GodotPath,
    [ValidateRange(1,10)][int]$Iterations = 1,
    [ValidateRange(10,1800)][int]$StageTimeoutSeconds = 300,
    [switch]$NoRender
)
$ErrorActionPreference = 'Stop'
$repoPath = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$enginePath = (Resolve-Path -LiteralPath $GodotPath).Path
# Godot's Windows console executable is a small launcher. Sample the actual
# engine instead, otherwise a misleading ~7 MB launcher footprint is recorded.
if ($enginePath.EndsWith('_console.exe',[StringComparison]::OrdinalIgnoreCase)) {
    $nativePath = $enginePath.Substring(0,$enginePath.Length-'_console.exe'.Length)+'.exe'
    if (!(Test-Path -LiteralPath $nativePath -PathType Leaf)) { throw 'Native Godot executable required for meaningful process measurement.' }
    $enginePath = $nativePath
}
$runId = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssfffZ') + '-' + [guid]::NewGuid().ToString('N').Substring(0,8)
$runRoot = Join-Path $repoPath ('artifacts/character-iterations/' + $runId)
[IO.Directory]::CreateDirectory($runRoot) | Out-Null
$stages = [Collections.Generic.List[object]]::new()
$inputs = @{}
foreach ($file in @('prepare-character-model.gd','character-workshop.gd','character-outfit.gd','character-textiles.gd','sewing-pattern.gd','cloth-contact.gd','test-cloth-drape.gd','test-sewing-pattern.gd','test-character-workshop.gd','test-character-outfit.gd','test-character-textiles.gd','addons/shared_character_builder/character_package.gd','iterate-character-build.ps1')) {
    $inputs[$file] = (Get-FileHash -LiteralPath (Join-Path $PSScriptRoot $file) -Algorithm SHA256).Hash.ToLowerInvariant()
}
$head = (& git -C $repoPath rev-parse HEAD).Trim()
$receipt = [ordered]@{
    schemaVersion=1; runId=$runId; gitHead=$head; toolHashes=$inputs; enginePath=$enginePath
    requestedIterations=$Iterations; rendered=(!$NoRender); status='running'
    visualAdmission='pending-human-review'; vramBytes=$null
    memoryMetric='sampled process working set bytes, not VRAM or guaranteed peak'
    stages=$stages; results=@()
}
function Save-Receipt {
    [IO.File]::WriteAllText((Join-Path $runRoot 'receipt.json'),($receipt | ConvertTo-Json -Depth 16))
}
function Invoke-Stage([string]$Name,[string]$Script,[string[]]$Tail,[bool]$Headless) {
    Write-Output "Running $Name"
    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $enginePath
    $startInfo.WorkingDirectory = $repoPath
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    if ($Headless) { $startInfo.ArgumentList.Add('--headless') }
    foreach ($arg in @('--path',$PSScriptRoot,'--script',('res://'+$Script),'--') + $Tail) {
        $startInfo.ArgumentList.Add($arg)
    }
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    $watch = [Diagnostics.Stopwatch]::StartNew()
    $sampledMemory = 0L
    $timedOut = $false
    try {
        if (!$process.Start()) { throw "Could not start $Name" }
        $stdout = $process.StandardOutput.ReadToEndAsync()
        $stderr = $process.StandardError.ReadToEndAsync()
        while (!$process.WaitForExit(200)) {
            $process.Refresh()
            if (!$process.HasExited) { $sampledMemory = [Math]::Max($sampledMemory,$process.WorkingSet64) }
            if ($watch.Elapsed.TotalSeconds -gt $StageTimeoutSeconds) {
                $timedOut = $true
                $process.Kill($true)
                $process.WaitForExit()
                break
            }
        }
        $log = $stdout.GetAwaiter().GetResult() + "`n" + $stderr.GetAwaiter().GetResult()
        $exitCode = $process.ExitCode
        [IO.File]::WriteAllText((Join-Path $runRoot ($Name+'.log')),$log)
        $passed = (!$timedOut -and $exitCode -eq 0 -and $log -notmatch 'SCRIPT ERROR|(?m)^FAIL ')
        $stages.Add([ordered]@{name=$Name; passed=$passed; exitCode=$exitCode; timedOut=$timedOut; seconds=[Math]::Round($watch.Elapsed.TotalSeconds,3); sampledWorkingSetBytes=$sampledMemory; assertionsPassed=([regex]::Matches($log,'(?m)^PASS ')).Count; engineErrorLines=@($log -split "`n" | Where-Object { $_ -match '^ERROR:' } | Sort-Object -Unique); log=$Name+'.log'})
        Save-Receipt
        if (!$passed) { throw "$Name failed; inspect its log in $runRoot" }
        Write-Output "$Name passed ($([Math]::Round($watch.Elapsed.TotalSeconds,1)) seconds)"
    } finally {
        $watch.Stop()
        $process.Dispose()
    }
}
try {
    Save-Receipt
    Invoke-Stage 'wardrobe' 'test-character-outfit.gd' @() $true
    Invoke-Stage 'textiles' 'test-character-textiles.gd' @() $true
    Invoke-Stage 'sewing' 'test-sewing-pattern.gd' @((Join-Path $runRoot 'sewing-coupon')) $true
    for ($iteration=1; $iteration -le $Iterations; $iteration++) {
        $directory = Join-Path $runRoot ('iteration-'+$iteration)
        [IO.Directory]::CreateDirectory($directory) | Out-Null
        Invoke-Stage "build-$iteration" 'prepare-character-model.gd' @((Join-Path $repoPath 'assets/character-sources/makehuman-system'),$directory) $true
        foreach ($sex in @('female','male')) {
            Invoke-Stage "$sex-cloth-$iteration" 'test-cloth-drape.gd' @((Join-Path $directory ($sex+'-drape')),(Join-Path $directory ($sex+'-fitting-surface.res'))) $NoRender.IsPresent
            $prefix = Join-Path $directory ($sex+'-review')
            Invoke-Stage "$sex-$iteration" 'test-character-workshop.gd' @((Join-Path $directory ($sex+'-source.glb')),$prefix,(Join-Path $directory ($sex+'-profile.json'))) $NoRender.IsPresent
            Invoke-Stage "$sex-packed-$iteration" 'test-character-workshop.gd' @(($prefix+'.scn'),($prefix+'-packed-reload')) $NoRender.IsPresent
            Invoke-Stage "$sex-portable-$iteration" 'test-character-workshop.gd' @(($prefix+'-portable.character.json'),($prefix+'-portable-reload')) $NoRender.IsPresent
        }
        $receipt.results += [ordered]@{iteration=$iteration; buildReceipt=('iteration-'+$iteration+'/build-receipt.json'); sourceHashes=@{
            female=(Get-FileHash -LiteralPath (Join-Path $directory 'female-source.glb') -Algorithm SHA256).Hash.ToLowerInvariant()
            male=(Get-FileHash -LiteralPath (Join-Path $directory 'male-source.glb') -Algorithm SHA256).Hash.ToLowerInvariant()
        }}
        Save-Receipt
    }
    # Successful repeated builds are not automatically improvements or art approval.
    $receipt.status = 'mechanical-checks-passed-visual-review-required'
} catch {
    $receipt.status = 'failed'
    $receipt.failure = $_.Exception.Message
    throw
} finally {
    Save-Receipt
    Write-Output "Iteration receipt: $runRoot/receipt.json"
}
