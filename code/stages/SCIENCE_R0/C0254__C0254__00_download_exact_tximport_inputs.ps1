$ErrorActionPreference = "Stop"

# Gate9L engineering-only wrapper for accepted C0254.
# Purpose: close the R0 acquisition boundary without changing scientific/statistical semantics.
# Existing D:\RV_project\data files remain authority when their frozen bytes/SHA are exact.
# Public download occurs only for a missing file; mismatched existing files FAIL CLOSED.

$ProjectRoot = if ($env:RV_PROJECT_ROOT) {
    (Resolve-Path -LiteralPath $env:RV_PROJECT_ROOT).Path
} else {
    (Get-Location).Path
}

$PaperDir = Join-Path $ProjectRoot "scripts\paper"
$BaseScript = Join-Path $PaperDir "GATE9L_BASE_C0254_ACCEPTED.ps1"
if (-not (Test-Path -LiteralPath $BaseScript -PathType Leaf)) {
    throw "Accepted C0254 base missing: $BaseScript"
}

$assets = @(
    [PSCustomObject]@{
        Id="R0_RAW_TAR"
        Path=(Join-Path $ProjectRoot "data\tximport\GSE345645\GSE345645_RAW.tar")
        Url="https://ftp.ncbi.nlm.nih.gov/geo/series/GSE345nnn/GSE345645/suppl/GSE345645_RAW.tar"
        Bytes=[int64]2426050560
        Sha256="62252d1749090ec2c382ddc8402555e35b6c164742deccda6dd3a2b1088f3b4f"
    },
    [PSCustomObject]@{
        Id="R0_TX2GENE"
        Path=(Join-Path $ProjectRoot "data\tximport\GSE345645\GSE345645_transcript_to_gene.csv.gz")
        Url="https://ftp.ncbi.nlm.nih.gov/geo/series/GSE345nnn/GSE345645/suppl/GSE345645_transcript_to_gene.csv.gz"
        Bytes=[int64]2330283
        Sha256="2adf0ac4d4f81fc62d4725962b57b19196418c5d152cb1a8d0c51a85268063f9"
    },
    [PSCustomObject]@{
        Id="R0_RELEASED_COUNTS"
        Path=(Join-Path $ProjectRoot "data\processed\GSE345645\GSE345645_gene_counts.csv.gz")
        Url="https://ftp.ncbi.nlm.nih.gov/geo/series/GSE345nnn/GSE345645/suppl/GSE345645_gene_counts.csv.gz"
        Bytes=[int64]13124584
        Sha256="d1740b5890f989797cac9bd28b021a54bccbe9eb022cfd5d5649c7b6d4318ded"
    },
    [PSCustomObject]@{
        Id="R0_SURROGATE_VARS"
        Path=(Join-Path $ProjectRoot "data\processed\GSE345645\GSE345645_subseries1_adult_bulk_surrogate_variables.csv.gz")
        Url="https://ftp.ncbi.nlm.nih.gov/geo/series/GSE345nnn/GSE345645/suppl/GSE345645_subseries1_adult_bulk_surrogate_variables.csv.gz"
        Bytes=[int64]27122
        Sha256="f0307bbb168a874708e75539135896f2b38804901f0fd3adeee3fdf8b7dd2e27"
    },
    [PSCustomObject]@{
        Id="R0_FAMILY_SOFT"
        Path=(Join-Path $ProjectRoot "data\metadata\GSE345645\GSE345645_family.soft.gz")
        Url="https://ftp.ncbi.nlm.nih.gov/geo/series/GSE345nnn/GSE345645/soft/GSE345645_family.soft.gz"
        Bytes=[int64]14140
        Sha256="63d5d98bc092f652d49f6d578e85b0b96944bef3f24021b3def33698ad6621e4"
    }
)

function Assert-ExactAsset {
    param([Parameter(Mandatory=$true)]$Asset)

    if (-not (Test-Path -LiteralPath $Asset.Path -PathType Leaf)) {
        throw "Asset missing after acquisition: $($Asset.Id) :: $($Asset.Path)"
    }

    $item = Get-Item -LiteralPath $Asset.Path
    if ([int64]$item.Length -ne [int64]$Asset.Bytes) {
        throw "Byte mismatch for $($Asset.Id): expected=$($Asset.Bytes) observed=$($item.Length)"
    }

    $got = (Get-FileHash -LiteralPath $Asset.Path -Algorithm SHA256).Hash.ToLower()
    if ($got -ne $Asset.Sha256) {
        throw "SHA256 mismatch for $($Asset.Id): expected=$($Asset.Sha256) observed=$got"
    }
}

function Ensure-ExactAsset {
    param([Parameter(Mandatory=$true)]$Asset)

    $parent = Split-Path -Parent $Asset.Path
    New-Item -ItemType Directory -Force -Path $parent | Out-Null

    if (Test-Path -LiteralPath $Asset.Path -PathType Leaf) {
        # Critical governance rule: existing local data is accepted only if exact.
        # It is never overwritten merely to make the run pass.
        Assert-ExactAsset -Asset $Asset
        Write-Host "[PASS] existing exact local authority: $($Asset.Id)"
        return
    }

    Write-Host "[ACQUIRE] missing public input: $($Asset.Id)"
    & curl.exe -L --fail --output $Asset.Path $Asset.Url
    if ($LASTEXITCODE -ne 0) {
        throw "curl failed for $($Asset.Id) with exit code $LASTEXITCODE"
    }
    Assert-ExactAsset -Asset $Asset
    Write-Host "[PASS] acquired exact public authority: $($Asset.Id)"
}

foreach ($asset in $assets) {
    Ensure-ExactAsset -Asset $asset
}

# Execute the previously accepted C0254 bytes unchanged after the closure layer.
. $BaseScript
