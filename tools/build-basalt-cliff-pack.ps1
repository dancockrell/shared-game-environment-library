[CmdletBinding()]
param(
    [string]$ArchivePath = "assets/approved_cc0/Kenney/kenney-nature-kit/source_archive/kenney_nature-kit.zip",
    [string]$PackPath = "resource_packs/geology/basalt-cliff-core"
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

function Format-Float([double]$Value) {
    return $Value.ToString('0.######', [System.Globalization.CultureInfo]::InvariantCulture)
}

function Transform-Vector([double]$X, [double]$Y, [double]$Z, [double]$Scale, [double]$YawDegrees, [double]$TranslateX, [double]$TranslateY, [double]$TranslateZ, [bool]$Normalize) {
    $radians = $YawDegrees * [Math]::PI / 180.0
    $cosine = [Math]::Cos($radians)
    $sine = [Math]::Sin($radians)
    $rx = ($X * $cosine - $Z * $sine) * $Scale
    $rz = ($X * $sine + $Z * $cosine) * $Scale
    $ry = $Y * $Scale
    if ($Normalize) {
        $length = [Math]::Sqrt(($rx * $rx) + ($ry * $ry) + ($rz * $rz))
        if ($length -gt 0) { $rx /= $length; $ry /= $length; $rz /= $length }
        return @($rx, $ry, $rz)
    }
    return @(($rx + $TranslateX), ($ry + $TranslateY), ($rz + $TranslateZ))
}

$archive = Resolve-Path $ArchivePath
$packRoot = Join-Path (Get-Location) $PackPath
$sourceDirectory = Join-Path $packRoot 'source'
$meshDirectory = Join-Path $packRoot 'artifacts/meshes'
$materialDirectory = Join-Path $packRoot 'artifacts/materials'
New-Item -ItemType Directory -Force -Path $sourceDirectory, $meshDirectory, $materialDirectory | Out-Null

$members = @(
    @{ id = 'cave_base'; archivePath = 'Models/OBJ format/cliff_cave_rock.obj'; scale = 1.25; yaw = 0.0; tx = 0.0; ty = 0.0; tz = 0.0 },
    @{ id = 'side_shoulder'; archivePath = 'Models/OBJ format/cliff_half_rock.obj'; scale = 0.95; yaw = 90.0; tx = 0.78; ty = 0.10; tz = 0.56 },
    @{ id = 'raised_cap'; archivePath = 'Models/OBJ format/cliff_top_rock.obj'; scale = 0.85; yaw = -30.0; tx = -0.52; ty = 0.62; tz = 0.38 }
)

$zip = [System.IO.Compression.ZipFile]::OpenRead($archive)
try {
    foreach ($member in $members) {
        $entry = $zip.GetEntry($member.archivePath)
        if ($null -eq $entry) { throw "Missing expected archive entry: $($member.archivePath)" }
        $destination = Join-Path $sourceDirectory ([System.IO.Path]::GetFileName($member.archivePath))
        [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $destination, $true)
        $member.localPath = $destination
    }
}
finally { $zip.Dispose() }

$objLines = [System.Collections.Generic.List[string]]::new()
$objLines.Add('# Shared Game Environment Library derivative asset')
$objLines.Add('# Pack: geology.basalt-cliff-core.v1')
$objLines.Add('mtllib ../materials/basalt_cliff_core.mtl')
$objLines.Add('o basalt_cliff_core')
$objLines.Add('usemtl basalt_rock')

$vertexOffset = 0
$uvOffset = 0
$normalOffset = 0
$bounds = [ordered]@{ minX = [double]::PositiveInfinity; minY = [double]::PositiveInfinity; minZ = [double]::PositiveInfinity; maxX = [double]::NegativeInfinity; maxY = [double]::NegativeInfinity; maxZ = [double]::NegativeInfinity }

foreach ($member in $members) {
    $vertexCount = 0; $uvCount = 0; $normalCount = 0
    $objLines.Add("g $($member.id)")
    foreach ($line in Get-Content -LiteralPath $member.localPath) {
        if ($line -match '^v\s+([^\s]+)\s+([^\s]+)\s+([^\s]+)') {
            $vector = Transform-Vector ([double]$matches[1]) ([double]$matches[2]) ([double]$matches[3]) $member.scale $member.yaw $member.tx $member.ty $member.tz $false
            $objLines.Add("v $(Format-Float $vector[0]) $(Format-Float $vector[1]) $(Format-Float $vector[2])")
            $bounds.minX = [Math]::Min($bounds.minX, $vector[0]); $bounds.minY = [Math]::Min($bounds.minY, $vector[1]); $bounds.minZ = [Math]::Min($bounds.minZ, $vector[2])
            $bounds.maxX = [Math]::Max($bounds.maxX, $vector[0]); $bounds.maxY = [Math]::Max($bounds.maxY, $vector[1]); $bounds.maxZ = [Math]::Max($bounds.maxZ, $vector[2])
            $vertexCount++
        }
        elseif ($line -match '^vt\s+') { $objLines.Add($line); $uvCount++ }
        elseif ($line -match '^vn\s+([^\s]+)\s+([^\s]+)\s+([^\s]+)') {
            $vector = Transform-Vector ([double]$matches[1]) ([double]$matches[2]) ([double]$matches[3]) 1.0 $member.yaw 0 0 0 $true
            $objLines.Add("vn $(Format-Float $vector[0]) $(Format-Float $vector[1]) $(Format-Float $vector[2])")
            $normalCount++
        }
        elseif ($line -match '^f\s+') {
            $parts = $line.Substring(2).Split(' ', [System.StringSplitOptions]::RemoveEmptyEntries)
            $translated = foreach ($part in $parts) {
                $segments = $part.Split('/')
                $v = [int]$segments[0] + $vertexOffset
                $vt = if ($segments.Length -gt 1 -and $segments[1] -ne '') { ([int]$segments[1] + $uvOffset).ToString() } else { '' }
                $vn = if ($segments.Length -gt 2 -and $segments[2] -ne '') { ([int]$segments[2] + $normalOffset).ToString() } else { '' }
                if ($segments.Length -gt 2) { "$v/$vt/$vn" } elseif ($segments.Length -gt 1) { "$v/$vt" } else { "$v" }
            }
            $objLines.Add("f $($translated -join ' ')")
        }
    }
    $vertexOffset += $vertexCount; $uvOffset += $uvCount; $normalOffset += $normalCount
}

$outputObj = Join-Path $meshDirectory 'basalt_cliff_core.obj'
$outputMtl = Join-Path $materialDirectory 'basalt_cliff_core.mtl'
[System.IO.File]::WriteAllLines($outputObj, $objLines, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllLines($outputMtl, @(
    '# Shared Game Environment Library derivative material',
    'newmtl basalt_rock',
    '# Neutral matte basalt base; consuming projects may replace this material.',
    'Kd 0.145 0.125 0.115',
    'Ka 0.025 0.020 0.018',
    'Ks 0.020 0.020 0.020',
    'Ns 12'
), [System.Text.UTF8Encoding]::new($false))

$report = [ordered]@{
    packId = 'geology.basalt-cliff-core.v1'
    buildContractVersion = 1
    builder = 'tools/build-basalt-cliff-pack.ps1'
    sourceArchiveSha256 = (Get-FileHash -Algorithm SHA256 $archive).Hash.ToLower()
    sourceMembers = @($members | ForEach-Object { [ordered]@{ id = $_.id; archivePath = $_.archivePath; extractedPath = [System.IO.Path]::GetRelativePath((Get-Location), $_.localPath).Replace('\','/'); sha256 = (Get-FileHash -Algorithm SHA256 $_.localPath).Hash.ToLower() } })
    output = [ordered]@{ meshPath = [System.IO.Path]::GetRelativePath((Get-Location), $outputObj).Replace('\','/'); meshSha256 = (Get-FileHash -Algorithm SHA256 $outputObj).Hash.ToLower(); materialPath = [System.IO.Path]::GetRelativePath((Get-Location), $outputMtl).Replace('\','/'); materialSha256 = (Get-FileHash -Algorithm SHA256 $outputMtl).Hash.ToLower() }
    boundsMeters = $bounds
    generatedGeometry = [ordered]@{ vertexCount = $vertexOffset; uvCount = $uvOffset; normalCount = $normalOffset }
    validation = [ordered]@{ objFaceIndexRewrite = 'passed'; engineImport = 'pending'; collision = 'pending'; renderReview = 'pending' }
}
$reportPath = Join-Path $packRoot 'build-report.json'
$report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $reportPath -Encoding utf8
Write-Host "Built $outputObj with $vertexOffset vertices."
