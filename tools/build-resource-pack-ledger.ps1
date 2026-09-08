[CmdletBinding()]
param(
    [string]$Root = "resource_packs",
    [string]$OutputPath = "catalog/resource-pack-ledger.json"
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Get-Location).Path
$packFiles = Get-ChildItem -LiteralPath $Root -Recurse -Filter 'pack.json' -File | Sort-Object FullName
$entries = [System.Collections.Generic.List[object]]::new()

foreach ($packFile in $packFiles) {
    $pack = Get-Content -Raw -LiteralPath $packFile.FullName | ConvertFrom-Json
    if ($pack.policyStatus -eq 'rejected_3d_pending_deletion') { continue }
    foreach ($output in $pack.outputs) {
        if ($output.format -notin @('PNG', 'JPG', 'JPEG', 'WEBP', 'SVG', 'GIF')) {
            throw "Only 2D artwork may enter the active ledger: $($pack.packId)"
        }
    }
    $outputEntries = [System.Collections.Generic.List[object]]::new()
    foreach ($output in $pack.outputs) {
        $assetPath = Join-Path $packFile.Directory.FullName $output.path
        $outputEntries.Add([ordered]@{
            assetId = $output.assetId
            relativePath = [System.IO.Path]::GetRelativePath($repoRoot, $assetPath).Replace('\', '/')
            format = $output.format
            sha256 = if ($output.sha256) { $output.sha256 } else { (Get-FileHash -Algorithm SHA256 $assetPath).Hash.ToLower() }
            bytes = (Get-Item -LiteralPath $assetPath).Length
            literalSelectionState = $pack.review.literalSemantics
            engineEligibility = $pack.engineEligibility
        })
    }
    $entries.Add([ordered]@{
        packId = $pack.packId
        displayName = $pack.displayName
        packType = $pack.packType
        authoringStatus = $pack.authoringStatus
        engineEligibility = $pack.engineEligibility
        sourceLineage = $pack.sourceLineage
        searchTags = @($pack.searchTags)
        sceneRoles = @($pack.style.sceneRoles)
        outputs = @($outputEntries)
        review = $pack.review
    })
}

[ordered]@{
    ledgerVersion = 1
    policy = '2D artwork only. Rejected model packs remain on disk pending deletion and are excluded from this active ledger. Reference availability does not imply runtime approval.'
    resourcePackCount = $entries.Count
    assetCount = @($entries.outputs).Count
    entries = @($entries)
} | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $OutputPath -Encoding utf8

Write-Host "Built resource pack ledger with $($entries.Count) packs and $(@($entries.outputs).Count) outputs."
