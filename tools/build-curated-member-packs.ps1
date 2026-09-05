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
        $dependencies = @{}
        foreach ($memberPath in $definition.members) {
            $entry = $zip.GetEntry($memberPath)
            if ($null -eq $entry) { throw "Missing expected archive member: $memberPath" }
            $filename = [System.IO.Path]::GetFileName($memberPath)
            $destination = Join-Path $modelDirectory $filename
            [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $destination, $true)
            # A GLB may still reference external images or buffers. Preserve
            # the relative layout from the SAME archive; never guess a palette.
            $bytes = [IO.File]::ReadAllBytes($destination)
            $jsonLength = [BitConverter]::ToUInt32($bytes, 12)
            $gltf = [Text.Encoding]::UTF8.GetString($bytes, 20, $jsonLength) | ConvertFrom-Json
            foreach ($resource in @($gltf.images) + @($gltf.buffers)) {
                $uri = $resource.uri
                if (-not $uri -or $uri.StartsWith('data:')) { continue }
                $decoded = [Uri]::UnescapeDataString($uri)
                if ($decoded -match '(^[/\\]|:|(^|[/\\])\.\.([/\\]|$))') { throw "Unsafe GLB dependency: $uri" }
                $relative = $decoded.Replace('\', '/')
                $archiveMember = $memberPath.Substring(0, $memberPath.LastIndexOf('/') + 1) + $relative
                $dependency = $zip.GetEntry($archiveMember)
                if ($null -eq $dependency) { throw "Missing GLB dependency: $archiveMember" }
                $dependencyPath = Join-Path $modelDirectory $relative
                New-Item -ItemType Directory -Force -Path ([IO.Path]::GetDirectoryName($dependencyPath)) | Out-Null
                [IO.Compression.ZipFileExtensions]::ExtractToFile($dependency, $dependencyPath, $true)
                $dependencies[$relative] = [ordered]@{path="artifacts/models/$relative"; sourceMember=$archiveMember; sha256=(Get-FileHash -Algorithm SHA256 $dependencyPath).Hash.ToLower()}
            }
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
        dependencies = @($dependencies.Keys | Sort-Object | ForEach-Object { $dependencies[$_] })
        review = [ordered]@{ legal = 'approved_cc0_source_lineage'; literalSemantics = 'approved_literal_member_selection'; technical = 'source_member_hashes_verified_import_pending'; visual = 'source_member_preview_pending'; reviewer = 'Codex'; createdAt = '2026-09-03' }
        searchTags = @($definition.searchTags)
    }
    $pack | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path $packRoot 'pack.json') -Encoding utf8
    Write-Host "Built curated member pack: $($definition.packId)"
}
