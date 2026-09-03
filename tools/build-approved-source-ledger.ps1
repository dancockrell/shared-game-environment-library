[CmdletBinding()]
param(
    [string]$ManifestPath = "catalog/source-intake-manifest.json",
    [string]$OutputPath = "catalog/approved-source-ledger.json"
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

$root = (Get-Location).Path
$manifest = Get-Content -Raw -LiteralPath $ManifestPath | ConvertFrom-Json
$ledgerEntries = [System.Collections.Generic.List[object]]::new()

foreach ($entry in $manifest.entries) {
    $archiveDirectory = Join-Path $root (Join-Path $manifest.archiveRoot (Join-Path $entry.publisher $entry.sourceId))
    $reportPath = Join-Path $archiveDirectory 'intake-report.json'
    if (-not (Test-Path -LiteralPath $reportPath)) { throw "Missing intake report for $($entry.sourceId). Run sync-source-archives first." }
    $report = Get-Content -Raw -LiteralPath $reportPath | ConvertFrom-Json
    $archivePath = Join-Path $root $report.archivePath
    $licensePath = Join-Path $root $report.capturedLicensePath
    if (-not (Test-Path -LiteralPath $archivePath)) { throw "Missing archive for $($entry.sourceId): $($report.archivePath)" }
    if (-not (Test-Path -LiteralPath $licensePath)) { throw "Missing captured license for $($entry.sourceId): $($report.capturedLicensePath)" }
    $licenseText = Get-Content -Raw -LiteralPath $licensePath
    if ($report.licenseSpdx -ne 'CC0-1.0' -or $licenseText -notmatch '(?i)(CC0|Creative Commons Zero)') {
        throw "CC0 evidence check failed for $($entry.sourceId)."
    }
    $actualHash = (Get-FileHash -Algorithm SHA256 $archivePath).Hash.ToLower()
    if ($actualHash -ne $report.sha256) { throw "Archive hash changed after intake for $($entry.sourceId)." }

    $zip = [System.IO.Compression.ZipFile]::OpenRead($archivePath)
    try {
        $topLevel = @($zip.Entries | ForEach-Object { ($_.FullName -split '/')[0] } | Where-Object { $_ } | Sort-Object -Unique)
        $formats = @($zip.Entries | ForEach-Object { [System.IO.Path]::GetExtension($_.FullName).TrimStart('.').ToUpperInvariant() } | Where-Object { $_ -in @('OBJ', 'FBX', 'DAE', 'GLTF', 'GLB', 'BLEND', 'PNG', 'TGA', 'JPG', 'JPEG', 'WAV', 'OGG') } | Sort-Object -Unique)
    }
    finally { $zip.Dispose() }

    $ledgerEntries.Add([ordered]@{
        sourceId = $entry.sourceId
        sourceArchiveStatus = 'approved_cc0_source_archive'
        runtimeStatus = 'not_reviewed'
        assetKind = 'source_archive'
        originKind = $entry.originKind
        sourcePublisher = $entry.publisher
        sourcePage = $entry.sourcePage
        directDownloadUrl = $entry.downloadUrl
        sourceArchivePath = $report.archivePath
        originalArchiveFilename = $report.archiveFilename
        sha256 = $report.sha256
        bytes = $report.bytes
        licenseSpdx = $report.licenseSpdx
        capturedLicensePath = $report.capturedLicensePath
        commercialUseConfirmed = $true
        redistributionConfirmed = $true
        archiveContents = [ordered]@{
            entryCount = $report.archiveEntryCount
            topLevelDirectories = $topLevel
            observedFormats = $formats
        }
        classification = [ordered]@{
            typeTags = @($entry.typeTags)
            styleTags = @($entry.styleTags)
            qualityRole = $entry.qualityRole
        }
        requiredBeforeRuntimeAdmission = @(
            'select individual source member by literal semantics',
            'record member archive path and checksum',
            'validate engine import, units, forward axis, pivot, and material slots',
            'author collision and LOD policy',
            'add typed resource-pack metadata and consuming-project review'
        )
        review = [ordered]@{
            legal = 'passed_embedded_cc0_evidence'
            archiveIntegrity = 'passed_sha256_matches_intake_report'
            technical = 'archive_only_individual_asset_review_pending'
            visual = 'archive_only_individual_asset_review_pending'
        }
    })
}

$ledger = [ordered]@{
    ledgerVersion = 2
    policy = 'Approved source archives are CC0-cleared upstream inputs. Runtime assets are admitted only through typed resource packs with separate technical and visual review.'
    sourceArchiveCount = $ledgerEntries.Count
    entries = @($ledgerEntries)
}
$ledger | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $OutputPath -Encoding utf8
Write-Host "Built approved source ledger with $($ledgerEntries.Count) CC0 source archives."
