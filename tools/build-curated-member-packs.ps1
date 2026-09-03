[CmdletBinding()]
param(
    [string]$ManifestPath = "catalog/curated-member-pack-manifest.json"
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

$root = (Get-Location).Path
$manifest = Get-Content -Raw -LiteralPath $ManifestPath | ConvertFrom-Json
foreach ($definition in $manifest.packs) {
    $packRoot = Join-Path $root $definition.packPath
    $modelDirectory = Join-Path $packRoot 'artifacts/models'
    New-Item -ItemType Directory -Force -Path $modelDirectory | Out-Null
    $archivePath = Join-Path $root $definition.upstreamArchive
    $zip = [System.IO.Compression.ZipFile]::OpenRead($archivePath)
    try {
        $outputs = [System.Collections.Generic.List[object]]::new()
        foreach ($memberPath in $definition.members) {
            $entry = $zip.GetEntry($memberPath)
            if ($null -eq $entry) { throw "Missing expected archive member: $memberPath" }
            $filename = [System.IO.Path]::GetFileName($memberPath)
            $destination = Join-Path $modelDirectory $filename
            [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $destination, $true)
            $outputs.Add([ordered]@{
                assetId = "$($definition.packId).$([System.IO.Path]::GetFileNameWithoutExtension($filename)).mesh.v1"
                path = "artifacts/models/$filename"
                format = 'GLB'
                sourceMember = $memberPath
                sha256 = (Get-FileHash -Algorithm SHA256 $destination).Hash.ToLower()
                originPolicy = 'upstream_member_origin_pending_engine_pivot_review'
                forwardAxis = 'pending_engine_review'
                scaleMeters = 'pending_engine_review'
                materialSlots = @('pending_engine_review')
                collisionPolicy = 'pending_authored_static_collision'
                lodPolicy = 'pending'
                thumbnailPolicy = 'pending_fixed_three_quarter_view'
                selectionHook = 'static_prop'
                statusHook = 'none'
            })
        }
    }
    finally { $zip.Dispose() }

    $pack = [ordered]@{
        packId = $definition.packId
        displayName = $definition.displayName
        packType = $definition.packType
        authoringStatus = 'source_origin'
        engineEligibility = 'source_ready_not_engine_reviewed'
        style = $definition.style
        sourceLineage = [ordered]@{ kind = 'CC0_member_extraction'; upstreamSourceId = $definition.upstreamSourceId; upstreamArchive = $definition.upstreamArchive; upstreamLicenseSpdx = 'CC0-1.0'; sourceMembers = @($definition.members) }
        outputs = @($outputs)
        review = [ordered]@{ legal = 'approved_cc0_source_lineage'; literalSemantics = 'approved_literal_member_selection'; technical = 'source_member_hashes_verified_import_pending'; visual = 'source_member_preview_pending'; reviewer = 'Codex'; createdAt = '2026-09-03' }
        searchTags = @($definition.searchTags)
    }
    $pack | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path $packRoot 'pack.json') -Encoding utf8
    Write-Host "Built curated member pack: $($definition.packId)"
}
