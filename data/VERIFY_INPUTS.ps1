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

$rows=@(Import-Csv -LiteralPath $Spec)
if($rows.Count-ne22){throw "INPUT_SPEC_COUNT=$($rows.Count)"}
$ledger=@()
foreach($r in $rows){
    $p=Join-Path $Root ($r.expected_relative_path.Replace('/','\'))
    $exists=Test-Path -LiteralPath $p -PathType Leaf
    $bytes=if($exists){[int64](Get-Item -LiteralPath $p).Length}else{0}
    $sha=if($exists){Sha $p}else{''}
    $ok=$exists -and $bytes-eq[int64]$r.expected_bytes -and $sha-eq$r.expected_sha256.ToLowerInvariant()
    $ledger += [pscustomobject]@{
        input_id=$r.input_id;relative_path=$r.expected_relative_path;exists=$exists;
        expected_bytes=$r.expected_bytes;observed_bytes=$bytes;
        expected_sha256=$r.expected_sha256;observed_sha256=$sha;
        status=$(if($ok){'PASS'}else{'FAIL'})
    }
}
$ledger|Format-Table -AutoSize
$bad=@($ledger|Where-Object{$_.status-ne'PASS'})
if($bad.Count){Write-Host '';Write-Host "HOLD: $($bad.Count) / 22 input(s) failed exact verification.";exit 2}
Write-Host '';Write-Host 'PASS: 22/22 frozen inputs exact.'
exit 0
