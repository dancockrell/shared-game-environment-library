param(
    [Parameter(Mandatory=$true)][string]$Python,
    [ValidateSet('vbd','xpbd','style3d')][string]$Solver = 'vbd',
    [ValidateSet('cpu','cuda:0')][string]$Device = 'cuda:0',
    [ValidateRange(1,3600)][int]$Frames = 300,
    [ValidateRange(1,40)][int]$Iterations = 10,
    [ValidateRange(10,1800)][int]$TimeoutSeconds = 300,
    [string]$PatternMesh,
    [string]$FittingBody,
    [string]$ReviewResult,
    [string]$RetargetSource,
    [string]$CMake,
    [string]$Vcpkg,
    [string]$PkgConfig,
    [switch]$InstallRetargetDependencies,
    [switch]$DependencyDryRun
)
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$pythonPath = (Resolve-Path -LiteralPath $Python).Path
$isFitting = -not [string]::IsNullOrEmpty($PatternMesh)
$isRetargetConfigure = -not [string]::IsNullOrEmpty($RetargetSource)
if ($isRetargetConfigure -and ($isFitting -or $ReviewResult -or $Device -ne 'cpu' -or (-not $CMake -and -not $InstallRetargetDependencies))) { throw 'Retarget configuration requires CPU, CMake and no fitting inputs.' }
if ($InstallRetargetDependencies -and (-not $isRetargetConfigure -or -not $Vcpkg)) { throw 'Dependency installation requires RetargetSource, CPU and Vcpkg.' }
if ($DependencyDryRun -and -not $InstallRetargetDependencies) { throw 'DependencyDryRun requires InstallRetargetDependencies.' }
if ($Vcpkg -and -not $isRetargetConfigure) { throw 'Vcpkg is only supported for retarget work.' }
if ($PkgConfig -and -not $InstallRetargetDependencies) { throw 'PkgConfig override requires dependency installation.' }
if ($PkgConfig) { $pkgConfigPath = (Resolve-Path -LiteralPath $PkgConfig).Path }
if ($CMake -and -not $isRetargetConfigure) { throw 'CMake requires RetargetSource.' }
if (-not $isFitting -and $Iterations -ne 10) { throw 'Iterations override is only supported for measured-pattern fitting.' }
if ($ReviewResult -and (-not $isFitting -or $Device -ne 'cuda:0')) { throw 'Depth review requires pattern/body inputs and GPU resource monitoring.' }
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
if ($isRetargetConfigure) {
    $sourcePath = (Resolve-Path -LiteralPath $RetargetSource).Path
    $dependencyRoot = Join-Path ([Environment]::GetFolderPath('UserProfile')) '.cache/cf/dependencies'
    $manifestRoot = Join-Path $PSScriptRoot 'retarget-dependencies'
    if ($Vcpkg) { $vcpkgPath = (Resolve-Path -LiteralPath $Vcpkg).Path }
    $executablePath = if ($InstallRetargetDependencies) { $vcpkgPath } else { (Resolve-Path -LiteralPath $CMake).Path }
    if (-not (Test-Path -LiteralPath (Join-Path $sourcePath 'CMakeLists.txt'))) { throw 'Missing author CMake project.' }
    # MSBuild still hits MAX_PATH under the long shared checkout; keep only
    # disposable compiler output in a short cache, with its path in the receipt.
    $buildPath = Join-Path ([Environment]::GetFolderPath('UserProfile')) ".cache/cf/$runId"
    $arguments = @('-S',$sourcePath,'-B',$buildPath,'-G','Visual Studio 17 2022','-A','x64',
        '-DPOLYFEM_WITH_TESTS=OFF','-DPOLYSOLVE_WITH_CHOLMOD=OFF','-DPOLYSOLVE_WITH_PARDISO=OFF',
        '-DPOLYSOLVE_WITH_CUSOLVER=OFF','-DIPC_TOOLKIT_WITH_CUDA=OFF',"-DPYTHON_EXECUTABLE=$pythonPath")
    if ($InstallRetargetDependencies) {
        $arguments = @('install',"--x-manifest-root=$manifestRoot", "--x-install-root=$dependencyRoot", '--triplet=x64-windows',
            "--x-buildtrees-root=$dependencyRoot/buildtrees", "--x-packages-root=$dependencyRoot/packages")
        if ($DependencyDryRun) { $arguments += '--dry-run' }
        # KEEP_ENV_VARS is not part of vcpkg's ABI hash. Do not reuse/publish
        # binary-cache entries built with an untracked helper override.
        if ($PkgConfig) { $arguments += '--binarysource=clear' }
    } elseif ($Vcpkg) {
        $toolchain = Join-Path (Split-Path $vcpkgPath -Parent) 'scripts/buildsystems/vcpkg.cmake'
        if (-not (Test-Path -LiteralPath $toolchain)) { throw 'Missing vcpkg CMake toolchain.' }
        $arguments += @("-DCMAKE_TOOLCHAIN_FILE=$toolchain", "-DVCPKG_INSTALLED_DIR=$dependencyRoot", '-DVCPKG_MANIFEST_INSTALL=OFF', '-DVCPKG_TARGET_TRIPLET=x64-windows')
    }
} elseif ($isFitting) {
    $patternPath = (Resolve-Path -LiteralPath $PatternMesh).Path
    $bodyPath = (Resolve-Path -LiteralPath $FittingBody).Path
    $arguments = @('-u','-X','utf8',(Join-Path $PSScriptRoot 'fit-period-pattern.py'),'--panels',$patternPath,'--body',$bodyPath,'--output',(Join-Path $output 'fitting'),'--frames',"$Frames",'--device',$Device)
    $arguments += @('--iterations',"$Iterations")
    if ($ReviewResult) { $arguments += @('--review-only',(Resolve-Path -LiteralPath $ReviewResult).Path,'--depth-render') }
} else {
    $arguments = @('-X','utf8','-m','newton.examples','cloth_hanging','--viewer','null','--solver',$Solver,'--device',$Device,'--num-frames',"$Frames",'--test')
}
$watch = [System.Diagnostics.Stopwatch]::StartNew()
$startInfo = [System.Diagnostics.ProcessStartInfo]::new()
$startInfo.FileName = if ($isRetargetConfigure) { $executablePath } else { $pythonPath }
$startInfo.Arguments = ($arguments | ForEach-Object { '"' + $_ + '"' }) -join ' '
$startInfo.WorkingDirectory = $repo
$startInfo.UseShellExecute = $false
$startInfo.CreateNoWindow = $true
$startInfo.RedirectStandardOutput = $true
$startInfo.RedirectStandardError = $true
$startInfo.Environment['CMAKE_BUILD_PARALLEL_LEVEL'] = '1'
$startInfo.Environment['OMP_NUM_THREADS'] = '1'
$startInfo.Environment['VCPKG_MAX_CONCURRENCY'] = '1'
if ($PkgConfig) {
    $startInfo.Environment['PKG_CONFIG'] = $pkgConfigPath
    $startInfo.Environment['VCPKG_KEEP_ENV_VARS'] = 'PKG_CONFIG'
}
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
        # Include compiler/interpreter grandchildren, not only direct children.
        $snapshot = @(Get-CimInstance Win32_Process -ErrorAction Stop)
        $ownedIds = [System.Collections.Generic.HashSet[uint32]]::new()
        [void]$ownedIds.Add([uint32]$process.Id)
        do {
            $added = $false
            foreach ($child in $snapshot) {
                if ($ownedIds.Contains([uint32]$child.ParentProcessId) -and $ownedIds.Add([uint32]$child.ProcessId)) {
                    $treeWorkingSet += [long]$child.WorkingSetSize
                    $added = $true
                }
            }
        } while ($added)
        $freeNowKiB = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory
        if ($freeNowKiB -lt 8GB/1KB) {
            $resourceStopped = $true
            $terminationReason = 'system-memory-pressure'
            $process.Kill($true)
            break
        }
        $gpuNow = Get-GpuSample
        $samples.Add([pscustomobject][ordered]@{seconds=$watch.Elapsed.TotalSeconds; processTreeWorkingSetMiB=$treeWorkingSet/1MB; wholeGpuUsedMiB=$gpuNow})
        # CPU-only provisioning/configuration cannot allocate CUDA memory.
        # Keep reporting shared GPU use, but do not kill CPU work for another
        # application's allocations. CUDA fitting/review keeps its GPU guard.
        if ($treeWorkingSet -gt 2GB -or ($Device -eq 'cuda:0' -and $null -ne $gpuNow -and $gpuNow -gt 8192)) {
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
if ($ReviewResult) { $packageCode = 'import importlib.metadata as m,json; print(json.dumps({n:m.version(n) for n in ("pyrender","pyglet","PyOpenGL","numpy","trimesh","ipctk")}))' }
if ($isRetargetConfigure) {
    $versionArgument = if ($InstallRetargetDependencies) { 'version' } else { '--version' }
    $packageInfo = @{executableVersion=(& $executablePath $versionArgument | Select-Object -First 1); source=$sourcePath;
        sourceCMakeSha256=(Get-FileHash -LiteralPath (Join-Path $sourcePath 'CMakeLists.txt')).Hash.ToLower()}
    if ($Vcpkg) {
        $packageInfo.dependencyManifestSha256 = (Get-FileHash -LiteralPath (Join-Path $manifestRoot 'vcpkg.json')).Hash.ToLower()
        $packageInfo.dependencyInstallRoot = $dependencyRoot
        $packageInfo.dependencyDryRun = [bool]$DependencyDryRun
    }
    if ($PkgConfig) {
        $packageInfo.pkgConfig = $pkgConfigPath
        $packageInfo.pkgConfigSha256 = (Get-FileHash -LiteralPath $pkgConfigPath).Hash.ToLower()
    }
} else {
    $packageOutput = & $pythonPath -X utf8 -c $packageCode
    $packageInfo = if ($LASTEXITCODE -eq 0) { $packageOutput | ConvertFrom-Json } else { $null }
}
if ($isFitting -and $packageInfo) { $packageInfo.PSObject.Properties.Remove('upstreamExampleSha256') }
$gpuSamples = @($samples | Where-Object { $null -ne $_.wholeGpuUsedMiB })
$receipt = [ordered]@{
    schemaVersion=1; purpose=if ($isRetargetConfigure) {'CPU author-retargeter CMake feasibility check; no solver execution or art admission'} elseif ($ReviewResult) {'Depth-buffered exported-mesh review, not final art admission'} elseif ($isFitting) {'Measured-panel Newton sewing study, not fit or art admission'} else {'Unmodified upstream hanging-cloth feasibility benchmark, not garment or art admission'}
    invocation=$arguments; executable=$startInfo.FileName; python=$pythonPath; packages=$packageInfo
    childEnvironment=@{CMAKE_BUILD_PARALLEL_LEVEL='1'; OMP_NUM_THREADS='1'; VCPKG_MAX_CONCURRENCY='1'}
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
if ($InstallRetargetDependencies) {
    $receipt.purpose = if ($DependencyDryRun) { 'Pinned retarget prerequisite resolution only; no installation or solver execution' } else { 'Pinned retarget prerequisite installation; no solver execution or art admission' }
}
if ($PkgConfig) { $receipt.childEnvironment.PKG_CONFIG = $pkgConfigPath }
$receipt | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path $output 'receipt.json') -Encoding utf8
Write-Output "Receipt: $output/receipt.json"
Write-Output "Upstream exit: $exitCode; timeout: $timedOut; elapsed: $($watch.Elapsed.TotalSeconds)s"
Get-Content -LiteralPath $stdout -Tail 8
Get-Content -LiteralPath $stderr -Tail 8
if ($timedOut) { exit 124 }
if ($resourceStopped) { exit 125 }
if ($null -eq $exitCode) { exit 1 }
exit $exitCode
