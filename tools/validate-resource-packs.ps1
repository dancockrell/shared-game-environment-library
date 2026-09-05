[CmdletBinding()]
param(
    [string]$Root = "resource_packs"
)

$ErrorActionPreference = 'Stop'
$failures = [System.Collections.Generic.List[string]]::new()
$packFiles = Get-ChildItem -LiteralPath $Root -Filter 'pack.json' -Recurse -File

if ($packFiles.Count -eq 0) {
    throw "No resource pack manifests found beneath $Root."
}

function Assert-PackCondition([bool]$Condition, [string]$Message) {
    if (-not $Condition) { $failures.Add($Message) }
}

foreach ($packFile in $packFiles) {
    $packDirectory = $packFile.Directory.FullName
    try { $pack = Get-Content -Raw -LiteralPath $packFile.FullName | ConvertFrom-Json }
    catch { $failures.Add("$($packFile.FullName): invalid JSON: $($_.Exception.Message)"); continue }

    foreach ($field in @('packId', 'packType', 'authoringStatus', 'engineEligibility', 'style', 'sourceLineage', 'outputs', 'review', 'searchTags')) {
        Assert-PackCondition ($null -ne $pack.$field) "$($packFile.FullName): missing required field '$field'."
    }
    Assert-PackCondition ($pack.authoringStatus -in @('source_origin', 'derivative', 'reference_only')) "$($packFile.FullName): unsupported authoringStatus '$($pack.authoringStatus)'."
    Assert-PackCondition ($pack.searchTags.Count -ge 3) "$($packFile.FullName): requires at least three search tags."

    if ($pack.authoringStatus -eq 'derivative') {
        Assert-PackCondition ($pack.sourceLineage.kind -eq 'CC0_derived') "$($packFile.FullName): a derivative must declare CC0_derived lineage."
        Assert-PackCondition ($pack.sourceLineage.sourceMembers.Count -gt 0) "$($packFile.FullName): derivative sourceMembers are missing."
        Assert-PackCondition (Test-Path -LiteralPath (Join-Path $packDirectory 'build-report.json')) "$($packFile.FullName): derivative build-report.json is missing."
    }

    foreach ($output in $pack.outputs) {
        $assetPath = Join-Path $packDirectory $output.path
        Assert-PackCondition (Test-Path -LiteralPath $assetPath) "$($packFile.FullName): output '$($output.assetId)' is missing at '$($output.path)'."
        if ($output.sha256 -and (Test-Path -LiteralPath $assetPath)) {
            Assert-PackCondition ((Get-FileHash -Algorithm SHA256 -LiteralPath $assetPath).Hash.ToLower() -eq $output.sha256) "${assetPath}: output hash mismatch."
        }
        if ([System.IO.Path]::GetExtension($assetPath).ToLowerInvariant() -eq '.obj' -and (Test-Path -LiteralPath $assetPath)) {
            $lines = Get-Content -LiteralPath $assetPath
            $vertices = @($lines | Where-Object { $_ -match '^v\s' }).Count
            $uvs = @($lines | Where-Object { $_ -match '^vt\s' }).Count
            $normals = @($lines | Where-Object { $_ -match '^vn\s' }).Count
            Assert-PackCondition ($vertices -gt 0) "${assetPath}: OBJ has no vertices."
            foreach ($face in $lines | Where-Object { $_ -match '^f\s' }) {
                foreach ($token in $face.Substring(2).Split(' ', [System.StringSplitOptions]::RemoveEmptyEntries)) {
                    $parts = $token.Split('/')
                    if ([int]$parts[0] -gt $vertices) { $failures.Add("${assetPath}: vertex index out of range in '$face'.") }
                    if ($parts.Length -gt 1 -and $parts[1] -ne '' -and [int]$parts[1] -gt $uvs) { $failures.Add("${assetPath}: UV index out of range in '$face'.") }
                    if ($parts.Length -gt 2 -and $parts[2] -ne '' -and [int]$parts[2] -gt $normals) { $failures.Add("${assetPath}: normal index out of range in '$face'.") }
                }
            }
        }
        if ([System.IO.Path]::GetExtension($assetPath).ToLowerInvariant() -eq '.glb' -and (Test-Path -LiteralPath $assetPath)) {
            $stream = [System.IO.File]::OpenRead($assetPath)
            try {
                if ($stream.Length -lt 20) { $failures.Add("${assetPath}: GLB is shorter than its required header and first chunk header."); continue }
                $reader = [System.IO.BinaryReader]::new($stream)
                $magic = $reader.ReadUInt32()
                $version = $reader.ReadUInt32()
                $declaredLength = $reader.ReadUInt32()
                $chunkLength = $reader.ReadUInt32()
                $chunkType = $reader.ReadUInt32()
                Assert-PackCondition ($magic -eq 0x46546C67) "${assetPath}: invalid GLB magic."
                Assert-PackCondition ($version -eq 2) "${assetPath}: expected GLB version 2, found $version."
                Assert-PackCondition ($declaredLength -eq $stream.Length) "${assetPath}: declared GLB length $declaredLength does not match file length $($stream.Length)."
                Assert-PackCondition ($chunkType -eq 0x4E4F534A) "${assetPath}: first GLB chunk is not JSON."
                Assert-PackCondition (($chunkLength + 20) -le $stream.Length) "${assetPath}: first GLB chunk length exceeds file size."
                if (($chunkLength + 20) -le $stream.Length) {
                    $gltf = [Text.Encoding]::UTF8.GetString($reader.ReadBytes($chunkLength)) | ConvertFrom-Json
                    foreach ($resource in @($gltf.images) + @($gltf.buffers)) {
                        if (-not $resource.uri -or $resource.uri.StartsWith('data:')) { continue }
                        $uri = [Uri]::UnescapeDataString($resource.uri)
                        if ($uri -match '(^[/\\]|:|(^|[/\\])\.\.([/\\]|$))') { $failures.Add("${assetPath}: unsafe dependency URI."); continue }
                        $dependencyPath = Join-Path ([IO.Path]::GetDirectoryName($assetPath)) $uri
                        Assert-PackCondition (Test-Path -LiteralPath $dependencyPath) "${assetPath}: missing external dependency '$uri'."
                        $relativeDependency = [IO.Path]::GetRelativePath($packDirectory, $dependencyPath).Replace('\', '/')
                        Assert-PackCondition (@($pack.dependencies | Where-Object path -EQ $relativeDependency).Count -eq 1) "${assetPath}: dependency '$uri' has no unique provenance record."
                    }
                }
            }
            finally { $stream.Dispose() }
        }
    }
    foreach ($dependency in $pack.dependencies) {
        $dependencyPath = Join-Path $packDirectory $dependency.path
        Assert-PackCondition (Test-Path -LiteralPath $dependencyPath) "${dependencyPath}: dependency missing."
        if (Test-Path -LiteralPath $dependencyPath) {
            Assert-PackCondition ((Get-FileHash -Algorithm SHA256 -LiteralPath $dependencyPath).Hash.ToLower() -eq $dependency.sha256) "${dependencyPath}: dependency hash mismatch."
        }
    }
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Error $_ }
    throw "Resource pack validation failed with $($failures.Count) issue(s)."
}

Write-Host "Validated $($packFiles.Count) resource pack(s)."
