#requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$script:RVRoot=[IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))

function Resolve-PublicPath {
    param([Parameter(Mandatory=$true)][string]$RelativePath)
    if([IO.Path]::IsPathRooted($RelativePath)-or$RelativePath-match '(^|[\\/])\.\.([\\/]|$)|:'){throw 'REJECT_NON_RELATIVE_PATH'}
    $path=[IO.Path]::GetFullPath((Join-Path $script:RVRoot $RelativePath))
    $prefix=$script:RVRoot.TrimEnd('\','/')+[IO.Path]::DirectorySeparatorChar
    if(-not$path.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'REJECT_PATH_ESCAPE'}
    $walk=$script:RVRoot
    foreach($part in @('')+($RelativePath-split'[\\/]')){
        if($part){$walk=Join-Path $walk $part}
        if(Test-Path -LiteralPath $walk){
            $item=Get-Item -LiteralPath $walk -Force
            if(($item.Attributes-band[IO.FileAttributes]::ReparsePoint)-ne0){throw 'REJECT_REPARSE_POINT'}
        }
    }
    return $path
}
function Get-PublicSha256 {
    param([string]$Path)
    $s=[IO.File]::OpenRead($Path);$h=[Security.Cryptography.SHA256]::Create()
    try{return [BitConverter]::ToString($h.ComputeHash($s)).Replace('-','').ToLowerInvariant()}
    finally{$s.Dispose();$h.Dispose()}
}
function Assert-PublicAsset {
    param([string]$RelativePath,[string]$ExpectedSha256,[string]$ExpectedBytes)
    $p=Resolve-PublicPath $RelativePath
    if(-not(Test-Path -LiteralPath $p -PathType Leaf)){throw "MISSING_REQUIRED_ASSET: $RelativePath"}
    if((Get-Item $p).Length-ne[long]$ExpectedBytes){throw "BYTE_MISMATCH: $RelativePath"}
    if((Get-PublicSha256 $p)-ne$ExpectedSha256.ToLowerInvariant()){throw "SHA_MISMATCH: $RelativePath"}
}
function Initialize-PublicRoot {
    foreach($rel in @(
        'README.md',
        'reproducibility/RV_PUBLIC_SCIENCE_NODE_MANIFEST_V1_2.csv',
        'reproducibility/RV_PUBLIC_RELEASE_FILE_MANIFEST_V1_1.csv',
        'reproducibility/authority/G9L_FULL94_GENERATION_INPUT_FREEZE_V1_2.csv'
    )){
        if(-not(Test-Path -LiteralPath (Resolve-PublicPath $rel)-PathType Leaf)){throw 'INVALID_REPOSITORY_ROOT'}
    }
    $env:RV_PROJECT_ROOT=$script:RVRoot
}
function Assert-NoPreseed {
    $p=Resolve-PublicPath 'results'
    if(-not(Test-Path $p)){return}
    foreach($entry in Get-ChildItem -LiteralPath $p -Force){
        $child='results/'+$entry.Name
        if($entry.PSIsContainer){throw "PRESEEDED_RESULTS_DIRECTORY_FORBIDDEN: $child"}
        elseif($child-ne'results/README.md'){throw "PRESEEDED_RESULTS_FORBIDDEN: $child"}
    }
}
function Assert-FrozenIdentities {
    $rows=@(Import-Csv -LiteralPath (Resolve-PublicPath 'reproducibility/RV_PUBLIC_RELEASE_FILE_MANIFEST_V1_1.csv'))
    if($rows.Count-lt70){throw 'PUBLIC_RELEASE_MANIFEST_TOO_SMALL'}
    foreach($r in $rows){Assert-PublicAsset $r.relative_path $r.sha256 $r.bytes}
}
function Get-FrozenDag {
    $rows=@(Import-Csv -LiteralPath (Resolve-PublicPath 'reproducibility/RV_PUBLIC_SCIENCE_NODE_MANIFEST_V1_2.csv'))
    if($rows.Count-ne59){throw 'SCIENCE_DAG_COUNT_MISMATCH'}
    for($i=0;$i-lt59;$i++){
        if([int]$rows[$i].sequence-ne($i+1)){throw 'SCIENCE_DAG_ORDER_MISMATCH'}
        Assert-PublicAsset $rows[$i].public_relative_path $rows[$i].effective_sha256 ((Get-Item (Resolve-PublicPath $rows[$i].public_relative_path)).Length)
    }
    return $rows
}
function Test-PublicRepository {
    Assert-FrozenIdentities
    $null=@(Get-FrozenDag)
    Assert-NoPreseed
}
function Get-ReadinessFailures {
    $fail=New-Object 'System.Collections.Generic.List[string]'
    $inputs=@(Import-Csv -LiteralPath (Resolve-PublicPath 'data/INPUT_ACQUISITION_SPEC.csv'))
    $frozen=@(Import-Csv -LiteralPath (Resolve-PublicPath 'reproducibility/authority/G9L_FULL94_GENERATION_INPUT_FREEZE_V1_2.csv'))
    if($inputs.Count-ne22-or$frozen.Count-ne22){throw 'INPUT_CONTRACT_COUNT_MISMATCH'}
    foreach($f in $frozen){
        $x=@($inputs|Where-Object{$_.input_id-eq$f.input_id})
        if($x.Count-ne1-or$x[0].required-ne'YES'-or$x[0].expected_relative_path-ne$f.relative_path-or
           $x[0].expected_sha256-ne$f.expected_sha256-or$x[0].expected_bytes-ne$f.expected_bytes){throw 'INPUT_CONTRACT_CHANGED'}
        try{Assert-PublicAsset $f.relative_path $f.expected_sha256 $f.expected_bytes}catch{$fail.Add($_.Exception.Message)}
    }
    return $fail.ToArray()
}
function Write-PublicReceipt {
    param([string]$Mode,[string]$Status,[string[]]$Failures)
    $dir=Resolve-PublicPath 'logs/preflight';$null=New-Item -ItemType Directory -Force -Path $dir
    $name='logs/preflight/'+[guid]::NewGuid().ToString('N')+'.json'
    [ordered]@{mode=$Mode;status=$Status;failures=@($Failures);analysis_nodes_executed=0;public_scope='59_CORE_SCIENCE_NODES';utc=[DateTime]::UtcNow.ToString('o')}|
      ConvertTo-Json -Depth 4|Set-Content -LiteralPath (Resolve-PublicPath $name)-Encoding UTF8
    Write-Output "Receipt: $name"
}
