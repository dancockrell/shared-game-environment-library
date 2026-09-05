$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path $PSScriptRoot -Parent
$source = Join-Path $repoRoot 'resource_packs/character-support/illustrated-adult-adventurers'
$tempParent = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath()).TrimEnd([char]'\')
$testRoot = Join-Path $tempParent ('shared-art-validation-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $testRoot | Out-Null
try {
    Copy-Item -LiteralPath $source -Destination (Join-Path $testRoot 'fixture') -Recurse
    $manifestPath = Join-Path $testRoot 'fixture/pack.json'
    $baseline = Get-Content -LiteralPath $manifestPath -Raw
    & (Join-Path $PSScriptRoot 'validate-resource-packs.ps1') -Root $testRoot
    $cases = @(
        @{ Name='runtime promotion'; Error='reference-only pack'; Change={param($p) $p.engineEligibility='runtime_ready'} },
        @{ Name='image hash'; Error='SHA-256'; Change={param($p) $p.outputs[0].sha256=('0' * 64)} },
        @{ Name='prompt hash'; Error='prompt hash'; Change={param($p) $p.outputs[0].generation.promptSha256=('0' * 64)} },
        @{ Name='missing parent'; Error='parent ID/hash'; Change={param($p) $p.outputs[0].lineage.parents[0].assetId='missing.parent'} },
        @{ Name='image dimensions'; Error='PNG dimensions'; Change={param($p) $p.outputs[0].width=1} }
    )
    foreach ($case in $cases) {
        $pack = $baseline | ConvertFrom-Json
        & $case.Change $pack
        $pack | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $manifestPath -Encoding utf8
        $caught = $null
        try { & (Join-Path $PSScriptRoot 'validate-resource-packs.ps1') -Root $testRoot }
        catch { $caught = $_.ToString() }
        if (-not $caught -or $caught -notlike ('*' + $case.Error + '*')) { throw "Expected rejection for $($case.Name), received: $caught" }
        Write-Host "Passed negative fixture: $($case.Name)"
    }
    Write-Host 'Passed valid fixture and five negative reference-metadata fixtures.'
}
finally {
    $resolved = [System.IO.Path]::GetFullPath($testRoot)
    if ((Split-Path $resolved -Parent) -ne $tempParent -or (Split-Path $resolved -Leaf) -notlike 'shared-art-validation-*') { throw 'Refusing unexpected temporary cleanup path.' }
    Remove-Item -LiteralPath $resolved -Recurse -Force
}
