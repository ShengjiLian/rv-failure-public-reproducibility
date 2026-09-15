#requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$Root=[IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$Spec=Join-Path $Root 'data\INPUT_ACQUISITION_SPEC.csv'

function Sha([string]$p){
    $s=[IO.File]::OpenRead($p);$h=[Security.Cryptography.SHA256]::Create()
    try{return [BitConverter]::ToString($h.ComputeHash($s)).Replace('-','').ToLowerInvariant()}
    finally{$s.Dispose();$h.Dispose()}
}
function Exact([string]$p,$r){
    return (Test-Path $p -PathType Leaf) -and
           ((Get-Item $p).Length -eq [int64]$r.expected_bytes) -and
           ((Sha $p) -eq $r.expected_sha256.ToLowerInvariant())
}

$curl=(Get-Command curl.exe -ErrorAction SilentlyContinue).Source
if(-not$curl){throw 'curl.exe is required for automated acquisition.'}
$rows=@(Import-Csv $Spec)
if($rows.Count-ne22){throw "INPUT_SPEC_COUNT=$($rows.Count)"}
foreach($r in $rows){
    $dest=Join-Path $Root ($r.expected_relative_path.Replace('/','\'))
    $dir=Split-Path -Parent $dest
    New-Item -ItemType Directory -Force -Path $dir|Out-Null
    if(Exact $dest $r){Write-Host "[PASS existing] $($r.input_id)";continue}
    if(Test-Path $dest){throw "Existing non-identical file; refusing overwrite: $dest"}

    if($r.acquisition_mode-eq'MANUAL_MSIGDB_LOGIN'){
        Write-Host ''
        Write-Host "[MANUAL] $($r.input_id)"
        Write-Host "  Visit: $($r.source_page_url)"
        Write-Host "  Download: $($r.expected_filename)"
        Write-Host "  Place at: $dest"
        Write-Host "  Expected bytes: $($r.expected_bytes)"
        Write-Host "  SHA256: $($r.expected_sha256)"
        continue
    }

    if($r.acquisition_mode-ne'DIRECT_HTTPS' -or $r.direct_download_url -notmatch '^https://'){
        throw "Unsupported acquisition mode for $($r.input_id)"
    }
    $part=$dest+'.part'
    Write-Host ''
    Write-Host "[DOWNLOAD] $($r.input_id)"
    Write-Host "  $($r.direct_download_url)"
    & $curl --fail --location --retry 3 --retry-delay 2 --continue-at - --output $part $r.direct_download_url
    if($LASTEXITCODE-ne0){throw "curl failed for $($r.input_id): exit=$LASTEXITCODE"}
    if((Get-Item $part).Length-ne[int64]$r.expected_bytes){throw "Downloaded byte mismatch: $($r.input_id)"}
    if((Sha $part)-ne$r.expected_sha256.ToLowerInvariant()){throw "Downloaded SHA256 mismatch: $($r.input_id)"}
    Move-Item -LiteralPath $part -Destination $dest
    Write-Host "  [PASS] exact bytes/SHA."
}
Write-Host ''
Write-Host 'Acquisition pass complete. Manual MSigDB placement may still be required.'
Write-Host 'Run VERIFY_INPUTS.bat; execution requires 22/22 PASS.'
exit 0
