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
    }
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Error $_ }
    throw "Resource pack validation failed with $($failures.Count) issue(s)."
}

Write-Host "Validated $($packFiles.Count) resource pack(s)."
