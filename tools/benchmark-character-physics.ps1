param(
    [Parameter(Mandatory=$true)][string]$Python,
    [ValidateSet('vbd','xpbd','style3d')][string]$Solver = 'vbd',
    [ValidateSet('cpu','cuda:0')][string]$Device = 'cuda:0',
    [ValidateRange(1,3600)][int]$Frames = 300,
    [ValidateRange(10,1800)][int]$TimeoutSeconds = 300,
    [string]$PatternMesh,
    [string]$FittingBody
)
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$pythonPath = (Resolve-Path -LiteralPath $Python).Path
$isFitting = -not [string]::IsNullOrEmpty($PatternMesh)
if ($isFitting -and (-not $FittingBody -or $Solver -ne 'vbd' -or $Frames -gt 600)) { throw 'Fitting requires body, VBD, and at most 600 frames.' }
$freeRamKiB = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory
if ($freeRamKiB -lt 8GB/1KB) { throw 'Defer cloth work: preserve at least 8 GiB free system RAM before starting.' }
$runId = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssfffZ') + '-' + $Solver
$output = Join-Path $repo "artifacts/character-iterations/$runId"
New-Item -ItemType Directory -Path $output | Out-Null
$stdout = Join-Path $output 'stdout.log'
$stderr = Join-Path $output 'stderr.log'
$smi = Get-Command nvidia-smi -ErrorAction SilentlyContinue
$samples = [System.Collections.Generic.List[object]]::new()
function Get-GpuSample {
    if (-not $smi) { return $null }
    $line = & $smi.Source --id=0 --query-gpu=memory.used --format=csv,noheader,nounits 2>$null
    $value = 0.0
    if ($LASTEXITCODE -eq 0 -and [double]::TryParse([string]$line,[ref]$value)) { return $value }
    return $null
}
$baselineGpu = Get-GpuSample
if ($Device -eq 'cuda:0' -and ($null -eq $baselineGpu -or $baselineGpu -gt 5000)) { throw 'Defer cloth work: GPU baseline unavailable or already over 5000 MiB.' }
if ($isFitting) {
    $patternPath = (Resolve-Path -LiteralPath $PatternMesh).Path
    $bodyPath = (Resolve-Path -LiteralPath $FittingBody).Path
    $arguments = @('-u','-X','utf8',(Join-Path $PSScriptRoot 'fit-period-pattern.py'),'--panels',$patternPath,'--body',$bodyPath,'--output',(Join-Path $output 'fitting'),'--frames',"$Frames",'--device',$Device)
} else {
    $arguments = @('-X','utf8','-m','newton.examples','cloth_hanging','--viewer','null','--solver',$Solver,'--device',$Device,'--num-frames',"$Frames",'--test')
}
$watch = [System.Diagnostics.Stopwatch]::StartNew()
$startInfo = [System.Diagnostics.ProcessStartInfo]::new()
$startInfo.FileName = $pythonPath
$startInfo.Arguments = ($arguments | ForEach-Object { '"' + $_ + '"' }) -join ' '
$startInfo.WorkingDirectory = $repo
$startInfo.UseShellExecute = $false
$startInfo.CreateNoWindow = $true
$startInfo.RedirectStandardOutput = $true
$startInfo.RedirectStandardError = $true
$process = [System.Diagnostics.Process]::new()
$process.StartInfo = $startInfo
if (-not $process.Start()) { throw 'Could not start upstream benchmark.' }
$process.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::BelowNormal
$outTask = $process.StandardOutput.ReadToEndAsync()
$errTask = $process.StandardError.ReadToEndAsync()
$timedOut = $false
$resourceStopped = $false
$terminationReason = $null
try {
    while (-not $process.HasExited) {
        if ($watch.Elapsed.TotalSeconds -gt $TimeoutSeconds) {
            $timedOut = $true
            $terminationReason = 'time-limit'
            $process.Kill($true)
            break
        }
        $process.Refresh()
        $treeWorkingSet = $process.WorkingSet64
        # Windows venv Python can launch the actual interpreter as a child.
        $children = @(Get-CimInstance Win32_Process -Filter "ParentProcessId=$($process.Id)" -ErrorAction SilentlyContinue)
        foreach ($child in $children) { $treeWorkingSet += [long]$child.WorkingSetSize }
        $gpuNow = Get-GpuSample
        $samples.Add([pscustomobject][ordered]@{seconds=$watch.Elapsed.TotalSeconds; processTreeWorkingSetMiB=$treeWorkingSet/1MB; wholeGpuUsedMiB=$gpuNow})
        if ($treeWorkingSet -gt 2GB -or ($null -ne $gpuNow -and $gpuNow -gt 8192)) {
            $resourceStopped = $true
            $terminationReason = 'sampled-memory-pressure'
            $process.Kill($true)
            break
        }
        Start-Sleep -Milliseconds 250
    }
    $process.WaitForExit()
} finally {
    if (-not $process.HasExited) { $process.Kill($true); $process.WaitForExit() }
    $watch.Stop()
}
$exitCode = $process.ExitCode
[System.IO.File]::WriteAllText($stdout,$outTask.GetAwaiter().GetResult())
[System.IO.File]::WriteAllText($stderr,$errTask.GetAwaiter().GetResult())
$packageCode = 'import importlib.metadata as m,json,hashlib; d=m.distribution("newton"); p=d.locate_file("newton/examples/cloth/example_cloth_hanging.py"); print(json.dumps({"newton":d.version,"warp":m.version("warp-lang"),"numpy":m.version("numpy"),"source":json.loads(d.read_text("direct_url.json") or "{}"),"upstreamExampleSha256":hashlib.sha256(p.read_bytes()).hexdigest()}))'
$packageOutput = & $pythonPath -X utf8 -c $packageCode
$packageInfo = if ($LASTEXITCODE -eq 0) { $packageOutput | ConvertFrom-Json } else { $null }
if ($isFitting -and $packageInfo) { $packageInfo.PSObject.Properties.Remove('upstreamExampleSha256') }
$gpuSamples = @($samples | Where-Object { $null -ne $_.wholeGpuUsedMiB })
$receipt = [ordered]@{
    schemaVersion=1; purpose=if ($isFitting) {'Measured-panel Newton sewing study, not fit or art admission'} else {'Unmodified upstream hanging-cloth feasibility benchmark, not garment or art admission'}
    invocation=$arguments; python=$pythonPath; packages=$packageInfo
    runnerSha256=(Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash.ToLower()
    exitCode=$exitCode; timedOut=$timedOut; resourceStopped=$resourceStopped; terminationReason=$terminationReason; elapsedSeconds=$watch.Elapsed.TotalSeconds
    baselineWholeGpuMiB=$baselineGpu
    sampledPeakWholeGpuMiB=if ($gpuSamples.Count) { ($gpuSamples | Measure-Object wholeGpuUsedMiB -Maximum).Maximum } else { $null }
    sampledPeakProcessTreeWorkingSetMiB=if ($samples.Count) { ($samples | Measure-Object processTreeWorkingSetMiB -Maximum).Maximum } else { $null }
    measurementLimit='GPU samples cover all processes on device 0, not isolated allocation or an enforced 8 GB cap. Compilation is included in elapsed time. Unsampled peaks may be missed.'
    samples=$samples; artAdmission='not-assessed'; eightGbCertification=$false
    stdoutSha256=(Get-FileHash -LiteralPath $stdout -Algorithm SHA256).Hash.ToLower()
    stderrSha256=(Get-FileHash -LiteralPath $stderr -Algorithm SHA256).Hash.ToLower()
}
$receipt | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path $output 'receipt.json') -Encoding utf8
Write-Output "Receipt: $output/receipt.json"
Write-Output "Upstream exit: $exitCode; timeout: $timedOut; elapsed: $($watch.Elapsed.TotalSeconds)s"
Get-Content -LiteralPath $stdout -Tail 8
Get-Content -LiteralPath $stderr -Tail 8
if ($timedOut) { exit 124 }
if ($resourceStopped) { exit 125 }
if ($null -eq $exitCode) { exit 1 }
exit $exitCode
