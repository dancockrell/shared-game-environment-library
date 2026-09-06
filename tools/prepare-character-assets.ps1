param(
    [Parameter(Mandatory=$true)][string]$Archive
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$expectedHash = 'B542127A8E25547C7C29C19F2D1D2ADB9A664C80396ECD694095DBC8028A0107'
$archivePath = (Resolve-Path -LiteralPath $Archive).Path
if ((Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash -ne $expectedHash) {
    throw 'Archive differs from the inspected 2026-09-06 source. Review it before updating the pinned hash.'
}
$repoRoot = Split-Path $PSScriptRoot -Parent
$destination = [IO.Path]::GetFullPath((Join-Path $repoRoot 'assets/character-sources/makehuman-system'))
$prefixes = @(
    'proxymeshes/female_generic/', 'proxymeshes/male_generic/',
    'clothes/female_casualsuit01/', 'clothes/female_casualsuit02/',
    'clothes/male_casualsuit01/', 'clothes/male_casualsuit02/',
    'clothes/female_elegantsuit01/', 'clothes/male_elegantsuit01/',
    'clothes/fedora01/',
    'clothes/shoes01/', 'hair/ponytail01/', 'hair/short01/',
    'eyes/low-poly/', 'eyes/materials/',
    'eyebrows/eyebrow001/', 'eyebrows/eyebrow005/',
    'eyelashes/eyelashes01/', 'eyelashes/eyelashes04/',
    'skins/young_caucasian_female/', 'skins/young_caucasian_male/'
)
$archiveHandle = [IO.Compression.ZipFile]::OpenRead($archivePath)
$records = [Collections.Generic.List[object]]::new()
try {
    $entries = @($archiveHandle.Entries | Where-Object {
        $entryName = $_.FullName
        -not $entryName.EndsWith('/') -and @($prefixes | Where-Object { $entryName.StartsWith($_, [StringComparison]::Ordinal) }).Count -gt 0
    } | Sort-Object FullName)
    if ($entries.Count -eq 0) { throw 'No selected source assets found.' }
    foreach ($entry in $entries) {
        $targetPath = [IO.Path]::GetFullPath((Join-Path $destination $entry.FullName))
        if (-not $targetPath.StartsWith($destination + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Archive path escapes the source directory: $($entry.FullName)"
        }
        $stream = $entry.Open()
        try {
            $hasher = [Security.Cryptography.SHA256]::Create()
            try { $hash = [Convert]::ToHexString($hasher.ComputeHash($stream)).ToLowerInvariant() }
            finally { $hasher.Dispose() }
        } finally { $stream.Dispose() }
        if (Test-Path -LiteralPath $targetPath) {
            if ((Get-FileHash -LiteralPath $targetPath -Algorithm SHA256).Hash.ToLowerInvariant() -ne $hash) {
                throw "Existing source changed; refusing overwrite: $targetPath"
            }
        } else {
            [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($targetPath)) | Out-Null
            [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $targetPath, $false)
        }
        $records.Add([ordered]@{ path=$entry.FullName; bytes=$entry.Length; sha256=$hash })
    }
    $manifest = [ordered]@{
        schemaVersion=1
        source='https://static.makehumancommunity.org/assets/assetpacks/makehuman_system_assets.html'
        archive='makehuman_system_assets_cc0.zip'
        archiveSha256=$expectedHash.ToLowerInvariant()
        license='CC0-1.0'
        licenseEvidence='Original proxy, OBJ, mhclo and mhmat headers retain explicit September 2020 CC0 release declarations; official pack page identifies the included assets as CC0.'
        status='source-candidate-not-runtime-approved'
        purpose='Shared character workshop body and clothing preparation. Not approved Pirate Island character art.'
        coreRigAndTargetsIncluded=$false
        files=$records.ToArray()
    }
    $manifestPath = Join-Path $destination 'source-manifest.json'
    $manifestText = ($manifest | ConvertTo-Json -Depth 8) + [Environment]::NewLine
    if ((Test-Path -LiteralPath $manifestPath) -and [IO.File]::ReadAllText($manifestPath) -ne $manifestText) {
        $previous = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
        if ($previous.archiveSha256 -ne $manifest.archiveSha256) { throw 'Source archive changed.' }
        foreach ($old in $previous.files) {
            $retained = @($records | Where-Object { $_.path -ceq $old.path -and $_.sha256 -ceq $old.sha256 -and $_.bytes -eq $old.bytes })
            if ($retained.Count -ne 1) { throw "Source selection removed or changed: $($old.path)" }
        }
    }
    [IO.File]::WriteAllText($manifestPath, $manifestText, [Text.UTF8Encoding]::new($false))
    Write-Output "Verified and staged $($records.Count) source files. No paid generation."
} finally { $archiveHandle.Dispose() }
