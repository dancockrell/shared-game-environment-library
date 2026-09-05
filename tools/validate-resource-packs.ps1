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

    if ($pack.authoringStatus -eq 'reference_only') {
        Assert-PackCondition ($pack.engineEligibility -eq 'reference_only') "$($packFile.FullName): reference-only pack cannot become runtime eligible."
    }

    if ($pack.authoringStatus -eq 'derivative') {
        Assert-PackCondition ($pack.sourceLineage.kind -eq 'CC0_derived') "$($packFile.FullName): a derivative must declare CC0_derived lineage."
        Assert-PackCondition ($pack.sourceLineage.sourceMembers.Count -gt 0) "$($packFile.FullName): derivative sourceMembers are missing."
        Assert-PackCondition (Test-Path -LiteralPath (Join-Path $packDirectory 'build-report.json')) "$($packFile.FullName): derivative build-report.json is missing."
    }

    foreach ($output in $pack.outputs) {
        $assetPath = Join-Path $packDirectory $output.path
        Assert-PackCondition (Test-Path -LiteralPath $assetPath) "$($packFile.FullName): output '$($output.assetId)' is missing at '$($output.path)'."
        if ((Test-Path -LiteralPath $assetPath) -and $output.sha256) {
            Assert-PackCondition (((Get-FileHash -Algorithm SHA256 -LiteralPath $assetPath).Hash.ToLowerInvariant()) -eq $output.sha256.ToLowerInvariant()) "${assetPath}: SHA-256 does not match manifest."
        }
        if ($pack.sourceLineage.kind -eq 'generated_reference_export') {
            Assert-PackCondition ($output.engineEligibility -eq 'reference_only') "${assetPath}: generated reference cannot become runtime eligible."
            Assert-PackCondition ($output.licenseSpdx -eq 'NOASSERTION') "${assetPath}: generated reference export does not establish a CC0 license."
            Assert-PackCondition ($null -ne $output.generation.creationId) "${assetPath}: generation creation ID is required."
            if ($output.role -eq 'generated_character_concept') {
                $promptPath = Join-Path $packDirectory $output.generation.promptPath
                Assert-PackCondition (Test-Path -LiteralPath $promptPath) "${assetPath}: prompt missing."
                if (Test-Path -LiteralPath $promptPath) {
                    Assert-PackCondition (((Get-FileHash -Algorithm SHA256 -LiteralPath $promptPath).Hash.ToLowerInvariant()) -eq $output.generation.promptSha256) "${assetPath}: prompt hash mismatch."
                }
                Assert-PackCondition ($output.lineage.parents.Count -gt 0) "${assetPath}: input lineage missing."
                foreach ($parent in $output.lineage.parents) {
                    $matches = @($pack.outputs | Where-Object { $_.assetId -eq $parent.assetId -and $_.sha256 -eq $parent.sha256 })
                    Assert-PackCondition ($matches.Count -eq 1) "${assetPath}: parent ID/hash does not resolve uniquely."
                }
            }
            if (Test-Path -LiteralPath $assetPath) {
                $png = [System.IO.File]::ReadAllBytes($assetPath)
                $signature = if ($png.Length -ge 24) { [Convert]::ToHexString($png[0..7]) } else { '' }
                Assert-PackCondition ($signature -eq '89504E470D0A1A0A') "${assetPath}: invalid PNG header."
                if ($signature -eq '89504E470D0A1A0A') {
                    $width = [System.Net.IPAddress]::NetworkToHostOrder([BitConverter]::ToInt32($png, 16))
                    $height = [System.Net.IPAddress]::NetworkToHostOrder([BitConverter]::ToInt32($png, 20))
                    Assert-PackCondition ($width -eq $output.width -and $height -eq $output.height) "${assetPath}: PNG dimensions differ from metadata."
                }
            }
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
            }
            finally { $stream.Dispose() }
        }
    }
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Error $_ }
    throw "Resource pack validation failed with $($failures.Count) issue(s)."
}

Write-Host "Validated $($packFiles.Count) resource pack(s)."
