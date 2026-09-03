[CmdletBinding()]
param(
    [string]$LedgerPath = "catalog/approved-material-ledger.json",
    [string]$OutputPath = "catalog/material-validation-report.json"
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

function Get-ExpectedColorSpace([string]$Role) {
    if ($Role -in @('albedo', 'emission')) { return 'sRGB' }
    return 'linear'
}

$root = (Get-Location).Path
$ledger = Get-Content -Raw -LiteralPath $LedgerPath | ConvertFrom-Json
$validated = [System.Collections.Generic.List[object]]::new()

foreach ($entry in $ledger.entries) {
    $roles = @($entry.files.role)
    if ($roles -notcontains 'albedo') { throw "$($entry.sourceId) is missing an albedo source map." }
    if ($roles -notcontains 'normal_gl') { throw "$($entry.sourceId) is missing an OpenGL normal source map." }
    $fileResults = [System.Collections.Generic.List[object]]::new()
    foreach ($file in $entry.files) {
        $path = Join-Path $root $file.path
        if ((Get-FileHash -Algorithm SHA256 $path).Hash.ToLower() -ne $file.sha256) { throw "Hash mismatch: $($file.path)" }
        $image = [System.Drawing.Image]::FromFile($path)
        try {
            if ($image.Width -lt 512 -or $image.Height -lt 512) { throw "Material map is below the 512px source floor: $($file.path)" }
            $fileResults.Add([ordered]@{
                role = $file.role
                path = $file.path
                width = $image.Width
                height = $image.Height
                expectedEngineColorSpace = Get-ExpectedColorSpace $file.role
                sha256 = $file.sha256
                status = 'passed_source_integrity_and_dimensions'
            })
        }
        finally { $image.Dispose() }
    }
    $validated.Add([ordered]@{
        sourceId = $entry.sourceId
        sourceStatus = $entry.sourceAssetStatus
        runtimeStatus = $entry.runtimeStatus
        literalUse = $entry.literalUse
        files = @($fileResults)
        nextGate = 'author engine material and review a representative rendered surface'
    })
}

[ordered]@{
    reportVersion = 1
    policy = 'This confirms source-file integrity, dimensions, and expected import color space. It does not pass visual tiling, engine material, or runtime-performance review.'
    materialSourceCount = $validated.Count
    entries = @($validated)
} | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $OutputPath -Encoding utf8

Write-Host "Validated $($validated.Count) Poly Haven material source sets."
