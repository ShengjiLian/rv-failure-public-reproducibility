$ErrorActionPreference = "Stop"

# RV Project R0 exact tximport input download
# Run from D:\RV_project. This script downloads only processed kallisto H5 quantifications
# packaged by GEO plus the transcript-to-gene mapping. It does NOT download FASTQ/SRA.

$ProjectRoot = if ($env:RV_PROJECT_ROOT) { (Resolve-Path -LiteralPath $env:RV_PROJECT_ROOT).Path } else { (Get-Location).Path }

$InputDir = Join-Path $ProjectRoot "data\tximport\GSE345645"
$H5Dir = Join-Path $InputDir "h5"
$LogDir = Join-Path $ProjectRoot "logs"

New-Item -ItemType Directory -Force -Path $InputDir, $H5Dir, $LogDir | Out-Null

$BaseUrl = "https://ftp.ncbi.nlm.nih.gov/geo/series/GSE345nnn/GSE345645/suppl"
$TarUrl = "$BaseUrl/GSE345645_RAW.tar"
$MapUrl = "$BaseUrl/GSE345645_transcript_to_gene.csv.gz"

$TarPath = Join-Path $InputDir "GSE345645_RAW.tar"
$MapPath = Join-Path $InputDir "GSE345645_transcript_to_gene.csv.gz"
$ManifestPath = Join-Path $InputDir "R0_exact_download_manifest.csv"
$StatusPath = Join-Path $LogDir "R0_exact_download_status.txt"

function Download-One {
    param([string]$Url, [string]$OutFile)
    if (Test-Path $OutFile) {
        Write-Host "Already exists: $OutFile"
        return
    }
    Write-Host "Downloading: $Url"
    & curl.exe -L --fail --output $OutFile $Url
    if ($LASTEXITCODE -ne 0) {
        throw "curl failed for $Url with exit code $LASTEXITCODE"
    }
}

try {
    Download-One -Url $TarUrl -OutFile $TarPath
    Download-One -Url $MapUrl -OutFile $MapPath

    # Extract once. The GEO TAR is ~2.3 GB and contains per-sample kallisto abundance.h5 files.
    $existingH5 = @(Get-ChildItem -Path $H5Dir -Filter "*_abundance.h5" -File -ErrorAction SilentlyContinue)
    if ($existingH5.Count -ne 142) {
        Write-Host "Extracting GEO H5 archive..."
        & tar.exe -xf $TarPath -C $H5Dir
        if ($LASTEXITCODE -ne 0) {
            throw "tar extraction failed with exit code $LASTEXITCODE"
        }
    }

    $h5 = @(Get-ChildItem -Path $H5Dir -Filter "*_abundance.h5" -File)
    if ($h5.Count -ne 142) {
        throw "Expected 142 abundance.h5 files after extraction; observed $($h5.Count)."
    }

    $rows = @()
    foreach ($p in @($TarPath, $MapPath)) {
        $item = Get-Item $p
        $hash = (Get-FileHash -Algorithm SHA256 -Path $p).Hash.ToLower()
        $rows += [PSCustomObject]@{
            file_name = $item.Name
            bytes = $item.Length
            sha256 = $hash
            source_url = if ($item.Name -eq "GSE345645_RAW.tar") { $TarUrl } else { $MapUrl }
        }
    }
    $rows | Export-Csv -NoTypeInformation -Encoding UTF8 -Path $ManifestPath

    @(
        "R0_EXACT_DOWNLOAD_PASS"
        "project_root=$ProjectRoot"
        "h5_count=$($h5.Count)"
        "tar=$TarPath"
        "tx2gene=$MapPath"
        "manifest=$ManifestPath"
    ) | Set-Content -Encoding UTF8 $StatusPath

    Write-Host "R0_EXACT_DOWNLOAD_PASS"
}
catch {
    @(
        "R0_EXACT_DOWNLOAD_HOLD"
        "error=$($_.Exception.Message)"
    ) | Set-Content -Encoding UTF8 $StatusPath
    throw
}
