[CmdletBinding()]
param(
    [string[]]$SourceId,
    [string]$ManifestPath = "catalog/source-intake-manifest.json"
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

function Assert-RelativePath([string]$Value, [string]$Name) {
    if ([System.IO.Path]::IsPathRooted($Value) -or $Value -match '(^|[\\/])\.\.([\\/]|$)') {
        throw "$Name must be a repository-relative path."
    }
}

$manifest = Get-Content -Raw -LiteralPath $ManifestPath | ConvertFrom-Json
$root = (Get-Location).Path
$selected = if ($SourceId -and $SourceId.Count -gt 0) { @($manifest.entries | Where-Object { $_.sourceId -in $SourceId }) } else { @($manifest.entries) }
if ($selected.Count -eq 0) { throw 'No matching source IDs were found in the intake manifest.' }
if ($SourceId -and $selected.Count -ne $SourceId.Count) { throw 'At least one requested source ID was not found in the intake manifest.' }

foreach ($entry in $selected) {
    Assert-RelativePath $manifest.archiveRoot 'archiveRoot'
    $targetDirectory = Join-Path $root (Join-Path $manifest.archiveRoot (Join-Path $entry.publisher $entry.sourceId))
    $archiveDirectory = Join-Path $targetDirectory 'source_archive'
    $licenseDirectory = Join-Path $root (Join-Path 'licenses/upstream' $entry.publisher.ToLowerInvariant())
    New-Item -ItemType Directory -Force -Path $archiveDirectory, $licenseDirectory | Out-Null

    $archivePath = Join-Path $archiveDirectory $entry.archiveFilename
    if (-not (Test-Path -LiteralPath $archivePath)) {
        $temporaryPath = "$archivePath.partial"
        Remove-Item -LiteralPath $temporaryPath -Force -ErrorAction SilentlyContinue
        Invoke-WebRequest -Uri $entry.downloadUrl -OutFile $temporaryPath
        Move-Item -LiteralPath $temporaryPath -Destination $archivePath
    }

    $zip = [System.IO.Compression.ZipFile]::OpenRead($archivePath)
    try {
        $licenseEntry = $zip.Entries | Where-Object { $_.FullName -ieq $entry.licenseEvidencePath } | Select-Object -First 1
        if ($null -eq $licenseEntry) { throw "Expected license entry '$($entry.licenseEvidencePath)' was not found in $($entry.archiveFilename)." }
        $licensePath = Join-Path $licenseDirectory "$($entry.sourceId)-LICENSE.txt"
        [System.IO.Compression.ZipFileExtensions]::ExtractToFile($licenseEntry, $licensePath, $true)
        $report = [ordered]@{
            sourceId = $entry.sourceId
            sourceArchiveStatus = 'downloaded_license_captured_pending_manual_approval'
            originKind = $entry.originKind
            publisher = $entry.publisher
            sourcePage = $entry.sourcePage
            downloadUrl = $entry.downloadUrl
            archivePath = [System.IO.Path]::GetRelativePath($root, $archivePath).Replace('\', '/')
            archiveFilename = $entry.archiveFilename
            sha256 = (Get-FileHash -Algorithm SHA256 $archivePath).Hash.ToLower()
            bytes = (Get-Item -LiteralPath $archivePath).Length
            licenseSpdx = $entry.licenseSpdx
            capturedLicensePath = [System.IO.Path]::GetRelativePath($root, $licensePath).Replace('\', '/')
            archiveEntryCount = $zip.Entries.Count
            typeTags = @($entry.typeTags)
            styleTags = @($entry.styleTags)
            qualityRole = $entry.qualityRole
        }
    }
    finally { $zip.Dispose() }
    $reportPath = Join-Path $targetDirectory 'intake-report.json'
    $report | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $reportPath -Encoding utf8
    Write-Host "Downloaded and captured license: $($entry.sourceId)"
}
