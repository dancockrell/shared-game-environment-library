[CmdletBinding()]
param(
    [string]$ManifestPath = "catalog/material-seed-manifest.json",
    [string]$OutputPath = "catalog/approved-material-ledger.json"
)

$ErrorActionPreference = 'Stop'
$root = (Get-Location).Path
$manifest = Get-Content -Raw -LiteralPath $ManifestPath | ConvertFrom-Json
$entries = [System.Collections.Generic.List[object]]::new()

foreach ($source in $manifest.entries) {
    $reportPath = Join-Path $root (Join-Path $manifest.archiveRoot (Join-Path $source.sourceId 'intake-report.json'))
    if (-not (Test-Path -LiteralPath $reportPath)) { throw "Missing intake report for $($source.sourceId)." }
    $report = Get-Content -Raw -LiteralPath $reportPath | ConvertFrom-Json
    if ($report.licenseSpdx -ne 'CC0-1.0') { throw "CC0 evidence check failed for $($source.sourceId)." }
    foreach ($file in $report.files) {
        $filePath = Join-Path $root $file.path
        if (-not (Test-Path -LiteralPath $filePath)) { throw "Missing source file: $($file.path)" }
        if ((Get-FileHash -Algorithm SHA256 $filePath).Hash.ToLower() -ne $file.sha256) { throw "Hash mismatch: $($file.path)" }
    }
    $entries.Add([ordered]@{
        sourceId = $report.sourceId
        sourceAssetStatus = 'approved_cc0_material_source'
        runtimeStatus = 'not_reviewed'
        assetKind = 'material_source_files'
        originKind = $report.originKind
        sourcePublisher = $report.publisher
        sourcePage = $report.sourcePage
        licenseUrl = $report.licenseUrl
        licenseSpdx = $report.licenseSpdx
        commercialUseConfirmed = $true
        redistributionConfirmed = $true
        physicalType = $report.physicalType
        literalUse = $report.literalUse
        files = @($report.files)
        classification = [ordered]@{ typeTags = @($report.typeTags); styleTags = @($report.styleTags); qualityRole = $report.qualityRole }
        requiredBeforeRuntimeAdmission = @('validate texture color space and channel packing', 'author engine material', 'review tiling and scale in a representative scene', 'record resolution and platform budget')
        review = [ordered]@{ legal = 'passed_polyhaven_cc0_policy'; archiveIntegrity = 'passed_sha256_matches_intake_report'; technical = 'individual_material_review_pending'; visual = 'individual_material_review_pending' }
    })
}

[ordered]@{
    ledgerVersion = 1
    policy = 'Approved material source files are CC0-cleared inputs. Runtime material instances require separate engine and visual review.'
    materialSourceCount = $entries.Count
    entries = @($entries)
} | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $OutputPath -Encoding utf8

Write-Host "Built approved material ledger with $($entries.Count) source sets."
