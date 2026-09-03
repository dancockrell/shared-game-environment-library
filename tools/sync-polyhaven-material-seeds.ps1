[CmdletBinding()]
param(
    [string[]]$SourceId,
    [string]$ManifestPath = "catalog/material-seed-manifest.json"
)

$ErrorActionPreference = 'Stop'

function Assert-RelativePath([string]$Value, [string]$Name) {
    if ([System.IO.Path]::IsPathRooted($Value) -or $Value -match '(^|[\\/])\.\.([\\/]|$)') {
        throw "$Name must be a repository-relative path."
    }
}

$root = (Get-Location).Path
$manifest = Get-Content -Raw -LiteralPath $ManifestPath | ConvertFrom-Json
$selected = if ($SourceId -and $SourceId.Count -gt 0) { @($manifest.entries | Where-Object { $_.sourceId -in $SourceId }) } else { @($manifest.entries) }
if ($selected.Count -eq 0) { throw 'No matching material seed IDs were found.' }
if ($SourceId -and $selected.Count -ne $SourceId.Count) { throw 'At least one requested material seed ID was not found.' }

foreach ($entry in $selected) {
    Assert-RelativePath $manifest.archiveRoot 'archiveRoot'
    $seedDirectory = Join-Path $root (Join-Path $manifest.archiveRoot $entry.sourceId)
    $sourceDirectory = Join-Path $seedDirectory 'source_files'
    New-Item -ItemType Directory -Force -Path $sourceDirectory | Out-Null

    $fileReports = [System.Collections.Generic.List[object]]::new()
    foreach ($file in $entry.files) {
        $destination = Join-Path $sourceDirectory $file.filename
        if (-not (Test-Path -LiteralPath $destination)) {
            $partial = "$destination.partial"
            Remove-Item -LiteralPath $partial -Force -ErrorAction SilentlyContinue
            & curl.exe --fail --location --retry 3 --output $partial $file.url
            if ($LASTEXITCODE -ne 0) { throw "Download failed for $($file.url)" }
            Move-Item -LiteralPath $partial -Destination $destination
        }
        $fileReports.Add([ordered]@{
            role = $file.role
            url = $file.url
            path = [System.IO.Path]::GetRelativePath($root, $destination).Replace('\', '/')
            sha256 = (Get-FileHash -Algorithm SHA256 $destination).Hash.ToLower()
            bytes = (Get-Item -LiteralPath $destination).Length
        })
    }

    $report = [ordered]@{
        sourceId = $entry.sourceId
        sourceAssetStatus = 'downloaded_license_verified_pending_material_review'
        originKind = $entry.originKind
        publisher = $entry.publisher
        sourcePage = $entry.sourcePage
        licenseUrl = $entry.licenseUrl
        licenseSpdx = $entry.licenseSpdx
        physicalType = $entry.physicalType
        literalUse = $entry.literalUse
        typeTags = @($entry.typeTags)
        styleTags = @($entry.styleTags)
        qualityRole = $entry.qualityRole
        files = @($fileReports)
    }
    $report | ConvertTo-Json -Depth 7 | Set-Content -LiteralPath (Join-Path $seedDirectory 'intake-report.json') -Encoding utf8
    Write-Host "Synchronized Poly Haven material seed: $($entry.sourceId)"
}
