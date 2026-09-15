#requires -Version 5.1
# Strict public execution envelope. Frozen scientific/support files are never edited.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Test-SafeRunBasename {
    param([string]$Name)
    return $Name -match '^\d{8}_\d{6}$' -and $Name -notmatch '[/\\:]|\.\.'
}

function Assert-NoReparseChain {
    param([Parameter(Mandatory=$true)][string]$Root,[Parameter(Mandatory=$true)][string]$Path)
    $rootFull=[IO.Path]::GetFullPath($Root).TrimEnd('\','/')
    $pathFull=[IO.Path]::GetFullPath($Path)
    if ($pathFull -ne $rootFull -and -not $pathFull.StartsWith($rootFull+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) {
        throw 'REJECT_PATH_ESCAPE'
    }
    $relative=$pathFull.Substring($rootFull.Length).TrimStart('\','/')
    $walk=$rootFull
    foreach($part in @($relative -split '[\\/]' | Where-Object { $_ })) {
        $walk=Join-Path $walk $part
        if(Test-Path -LiteralPath $walk) {
            $item=Get-Item -LiteralPath $walk -Force
            if(($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw 'REJECT_REPARSE_POINT' }
        }
    }
}

function Read-InvocationLedger {
    param([Parameter(Mandatory=$true)]$Context)
    if(-not (Test-Path -LiteralPath $Context.StageLedger -PathType Leaf)) { return @() }
    return @(Import-Csv -LiteralPath $Context.StageLedger)
}

function Write-InvocationLedger {
    param([Parameter(Mandatory=$true)]$Context,[Parameter(Mandatory=$true)][AllowEmptyCollection()][array]$Rows)
    $tmp=$Context.StageLedger+'.tmp_'+[guid]::NewGuid().ToString('N')
    if(@($Rows).Count) {@($Rows) | Export-Csv -LiteralPath $tmp -NoTypeInformation -Encoding UTF8}
    else {Set-Content -LiteralPath $tmp -Value '"invocation_id","stage_root","run_basename","run_path","producer_node","sequence","postcondition_status","status","registered_utc"' -Encoding UTF8}
    Move-Item -LiteralPath $tmp -Destination $Context.StageLedger -Force
}

function New-PublicInvocation {
    param([Parameter(Mandatory=$true)][string]$ProjectRoot,[switch]$SkipPreseedCheck)
    $root=[IO.Path]::GetFullPath($ProjectRoot)
    if(-not $SkipPreseedCheck) { Assert-NoPreseed }
    $id='inv_'+[DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ')+'_'+[guid]::NewGuid().ToString('N')
    $control=Join-Path $root ('logs\invocations\'+$id)
    $null=New-Item -ItemType Directory -Path $control -Force
    $context=[pscustomobject]@{
        InvocationId=$id;ProjectRoot=$root;ResultsRoot=(Join-Path $root 'results');ControlRoot=$control
        StageLedger=(Join-Path $control 'stage_ledger.csv');StateLedger=(Join-Path $control 'result_state.csv')
        NodeLedger=(Join-Path $control 'node_ledger.csv');CreatedUtc=[DateTime]::UtcNow.ToString('o')
    }
    Write-InvocationLedger $context @()
    [ordered]@{invocation_id=$id;project_root=$root;created_utc=$context.CreatedUtc;checkpoint_reuse_allowed='NO';historical_fallback_allowed='NO'} |
        ConvertTo-Json | Set-Content -LiteralPath (Join-Path $control 'invocation.json') -Encoding UTF8
    return $context
}

function Resolve-StrictStageRun {
    param([Parameter(Mandatory=$true)]$Context,[Parameter(Mandatory=$true)][string]$StageRoot)
    $stage=[IO.Path]::GetFullPath($StageRoot)
    Assert-NoReparseChain $Context.ResultsRoot $stage
    if(-not (Test-Path -LiteralPath $stage -PathType Container)) { throw 'REJECT_STAGE_ROOT_MISSING' }
    $pointer=Join-Path $stage 'CURRENT_RUN.txt'
    $ledger=@(Read-InvocationLedger $Context)
    if(Test-Path -LiteralPath $pointer -PathType Leaf) {
        $values=@(Get-Content -LiteralPath $pointer | ForEach-Object { $_.Trim() } | Where-Object { $_ })
        if($values.Count -ne 1 -or -not (Test-SafeRunBasename $values[0])) { throw 'REJECT_UNSAFE_CURRENT_RUN_VALUE' }
        $basename=$values[0]
    } else {
        $eligible=@($ledger | Where-Object { $_.invocation_id -eq $Context.InvocationId -and $_.stage_root -eq $stage -and $_.status -eq 'VALIDATED' })
        if($eligible.Count -ne 1) { throw 'REJECT_NO_CURRENT_INVOCATION_AUTHORITY' }
        $basename=$eligible[0].run_basename
    }
    if(-not (Test-SafeRunBasename $basename)) { throw 'REJECT_UNSAFE_RUN_BASENAME' }
    $target=[IO.Path]::GetFullPath((Join-Path $stage $basename))
    if(-not [string]::Equals([IO.Path]::GetFullPath((Split-Path -Parent $target)),$stage,[StringComparison]::OrdinalIgnoreCase)) {
        throw 'REJECT_NOT_DIRECT_CHILD'
    }
    Assert-NoReparseChain $stage $target
    if(-not (Test-Path -LiteralPath $target -PathType Container)) { throw 'REJECT_RUN_TARGET_MISSING' }
    $match=@($ledger | Where-Object { $_.invocation_id -eq $Context.InvocationId -and $_.stage_root -eq $stage -and
        $_.run_basename -eq $basename -and $_.run_path -eq $target -and $_.status -eq 'VALIDATED' -and $_.postcondition_status -eq 'PASS' })
    if($match.Count -ne 1) { throw 'REJECT_RUN_NOT_VALIDATED_IN_CURRENT_LEDGER' }
    return $target
}

function Get-ResultState {
    param([Parameter(Mandatory=$true)]$Context)
    if(-not (Test-Path -LiteralPath $Context.ResultsRoot)) { return @() }
    $rows=[System.Collections.Generic.List[object]]::new()
    $queue=New-Object 'System.Collections.Generic.Queue[string]';$queue.Enqueue($Context.ResultsRoot)
    while($queue.Count) {
        $dir=$queue.Dequeue();Assert-NoReparseChain $Context.ResultsRoot $dir
        foreach($item in Get-ChildItem -LiteralPath $dir -Force) {
            Assert-NoReparseChain $Context.ResultsRoot $item.FullName
            $rel=$item.FullName.Substring($Context.ResultsRoot.Length).TrimStart('\','/').Replace('\','/')
            if($item.PSIsContainer) {$queue.Enqueue($item.FullName);$kind='DIRECTORY';$hash=''}
            else {$kind='FILE';$hash=Get-PublicSha256 $item.FullName}
            $rows.Add([pscustomobject]@{relative_path=$rel;kind=$kind;sha256=$hash})
        }
    }
    return $rows.ToArray()
}

function Save-CurrentInvocationState {
    param([Parameter(Mandatory=$true)]$Context,[Parameter(Mandatory=$true)][string]$ProducerNode,[int]$Sequence)
    $state=@(Get-ResultState $Context | Where-Object { $_.relative_path -ne 'README.md' } | ForEach-Object {
        [pscustomobject]@{invocation_id=$Context.InvocationId;relative_path=$_.relative_path;kind=$_.kind;sha256=$_.sha256;
            producer_node=$ProducerNode;sequence=$Sequence;validated='YES'}
    })
    $state | Export-Csv -LiteralPath $Context.StateLedger -NoTypeInformation -Encoding UTF8
}

function Write-ResultSnapshot {
    param([Parameter(Mandatory=$true)]$Context,[Parameter(Mandatory=$true)][string]$NodeId,[int]$Sequence,[ValidateSet('before','after')][string]$Moment)
    $path=Join-Path $Context.ControlRoot (('{0:d3}_{1}_{2}.csv' -f $Sequence,$NodeId,$Moment))
    @(Get-ResultState $Context) | Export-Csv -LiteralPath $path -NoTypeInformation -Encoding UTF8
}

function Assert-NextSequence {
    param([int]$Expected,[int]$Observed)
    if($Observed -ne $Expected) {throw "SEQUENCE_VIOLATION: expected=$Expected observed=$Observed"}
}

function Assert-CurrentInvocationResults {
    param([Parameter(Mandatory=$true)]$Context)
    $actual=@(Get-ResultState $Context | Where-Object { $_.relative_path -ne 'README.md' })
    $ledger=if(Test-Path -LiteralPath $Context.StateLedger){@(Import-Csv -LiteralPath $Context.StateLedger)}else{@()}
    foreach($a in $actual) {
        $m=@($ledger | Where-Object { $_.invocation_id -eq $Context.InvocationId -and $_.relative_path -eq $a.relative_path -and $_.kind -eq $a.kind -and $_.validated -eq 'YES' })
        if($m.Count -ne 1) { throw "REJECT_RESULT_NOT_CURRENT_INVOCATION: $($a.relative_path)" }
        if($a.kind -eq 'FILE' -and $m[0].sha256 -ne $a.sha256) { throw "REJECT_RESULT_CHANGED_OUTSIDE_NODE: $($a.relative_path)" }
    }
    foreach($m in $ledger) {
        if(-not @($actual | Where-Object {$_.relative_path -eq $m.relative_path}).Count) { throw "REJECT_LEDGER_RESULT_MISSING: $($m.relative_path)" }
    }
    foreach($p in Get-ChildItem -LiteralPath $Context.ResultsRoot -Filter CURRENT_RUN.txt -File -Recurse -Force) {
        $null=Resolve-StrictStageRun $Context (Split-Path -Parent $p.FullName)
    }
}

function Register-CurrentInvocationRuns {
    param([Parameter(Mandatory=$true)]$Context,[Parameter(Mandatory=$true)][string]$ProducerNode,[int]$Sequence,[string]$PostconditionStatus='PASS')
    $ledger=[System.Collections.Generic.List[object]]::new()
    foreach($r in @(Read-InvocationLedger $Context)) {$ledger.Add($r)}
    $existing=@{};foreach($r in $ledger){$existing[$r.run_path]=$true}
    foreach($d in Get-ChildItem -LiteralPath $Context.ResultsRoot -Directory -Recurse -Force) {
        if(-not (Test-SafeRunBasename $d.Name)) {continue}
        Assert-NoReparseChain $Context.ResultsRoot $d.FullName
        if($existing.ContainsKey($d.FullName)) {continue}
        $parent=[IO.Path]::GetFullPath((Split-Path -Parent $d.FullName))
        $ledger.Add([pscustomobject]@{invocation_id=$Context.InvocationId;stage_root=$parent;run_basename=$d.Name;
            run_path=[IO.Path]::GetFullPath($d.FullName);producer_node=$ProducerNode;sequence=$Sequence;
            postcondition_status=$PostconditionStatus;status=$(if($PostconditionStatus -eq 'PASS'){'VALIDATED'}else{'REJECTED'});
            registered_utc=[DateTime]::UtcNow.ToString('o')})
    }
    Write-InvocationLedger $Context $ledger.ToArray()
    # Any pointer written by the node must now bind a validated run.
    foreach($p in Get-ChildItem -LiteralPath $Context.ResultsRoot -Filter CURRENT_RUN.txt -File -Recurse -Force) {
        $null=Resolve-StrictStageRun $Context (Split-Path -Parent $p.FullName)
    }
}

function Test-NodePostcondition {
    param([Parameter(Mandatory=$true)]$Context,[Parameter(Mandatory=$true)]$Node,[AllowEmptyCollection()][array]$BeforeState=@())
    if($Node.required_postcondition -eq 'NONE') { return }
    $contracts=@(Import-Csv -LiteralPath (Join-Path $Context.ProjectRoot 'reproducibility\ORCHESTRATOR_HANDOFF_CONTRACT.csv') |
        Where-Object {$_.node_id -eq $Node.node_id})
    if($contracts.Count -lt 1) { throw "UNSPECIFIED_REQUIRED_POSTCONDITION: $($Node.node_id)" }
    foreach($c in $contracts) {
        $p=[IO.Path]::GetFullPath((Join-Path $Context.ProjectRoot ($c.required_relative_path -replace '/','\')))
        Assert-NoReparseChain $Context.ResultsRoot $p
        if(-not (Test-Path -LiteralPath $p -PathType Leaf)) { throw "POSTCONDITION_FILE_MISSING: $($c.required_relative_path)" }
        $resultRel=$p.Substring($Context.ResultsRoot.Length).TrimStart('\','/').Replace('\','/')
        if(@($BeforeState | Where-Object {$_.relative_path -eq $resultRel}).Count) {throw "POSTCONDITION_NOT_NEW_THIS_NODE: $($c.required_relative_path)"}
        switch -Regex ($c.validation) {
            '^FILE_EXISTS' { }
            '^FIRST_LINE_EQUALS_(.+)$' {if((Get-Content -LiteralPath $p -TotalCount 1) -ne $Matches[1]){throw "POSTCONDITION_TEXT_MISMATCH: $($c.required_relative_path)"}}
            '^CSV_21_ROWS' {
                $a=@(Import-Csv -LiteralPath $p)
                $comp=@($a|Where-Object {$_.item -eq 'Compensated samples'});$decomp=@($a|Where-Object {$_.item -eq 'Decompensated samples'})
                if($a.Count -ne 21 -or @($a|Where-Object {$_.status -eq 'PASS'}).Count -ne 19 -or @($a|Where-Object {$_.status -eq 'FAIL'}).Count -ne 2 -or
                   $comp.Count -ne 1 -or $comp[0].observed -ne '12' -or $decomp.Count -ne 1 -or $decomp[0].observed -ne '15') {throw 'POSTCONDITION_R1_SEMANTIC_HANDOFF_MISMATCH'}
            }
            default { throw "UNKNOWN_POSTCONDITION_VALIDATOR: $($c.validation)" }
        }
    }
}

function Assert-NodeContract {
    param([Parameter(Mandatory=$true)]$Node,[int]$ObservedExit)
    if($ObservedExit -ne [int]$Node.expected_exit) {throw "UNEXPECTED_EXIT: $($Node.node_id) expected=$($Node.expected_exit) observed=$ObservedExit"}
    if($Node.transition_policy -eq 'REQUIRE_EXIT0' -and $ObservedExit -ne 0) {throw 'EXIT0_REQUIRED'}
    if($Node.transition_policy -notin @('REQUIRE_EXIT0','EXPECTED_INTERMEDIATE_HANDOFF','EXPECTED_SEMANTIC_HANDOFF')) {throw 'UNKNOWN_TRANSITION_POLICY'}
}

function Get-PublicMd5 {
    param([Parameter(Mandatory=$true)][string]$Path)
    if(-not (Test-Path -LiteralPath $Path -PathType Leaf)) {throw "MD5_SOURCE_MISSING: $Path"}
    $stream=[IO.File]::OpenRead($Path)
    $algorithm=[Security.Cryptography.MD5]::Create()
    try {return [BitConverter]::ToString($algorithm.ComputeHash($stream)).Replace('-','').ToLowerInvariant()}
    finally {$stream.Dispose();$algorithm.Dispose()}
}

function Initialize-PublicChildLibraryStack {
    param([Parameter(Mandatory=$true)]$Context,[string]$RscriptPath)
    $r=Get-PublicRscript $RscriptPath
    $projectLib=[IO.Path]::GetFullPath((Join-Path $Context.ProjectRoot 'R_library\R-4.6'))
    if(-not (Test-Path -LiteralPath $projectLib -PathType Container)) {throw 'PROJECT_R_LIBRARY_MISSING'}

    $candidates=New-Object 'System.Collections.Generic.List[string]'
    $candidates.Add($projectLib)|Out-Null
    if($env:LOCALAPPDATA) {
        $defaultUser=Join-Path $env:LOCALAPPDATA 'R\win-library\4.6'
        if(Test-Path -LiteralPath $defaultUser -PathType Container) {$candidates.Add([IO.Path]::GetFullPath($defaultUser))|Out-Null}
    }

    $baselineOutput=@(& $r --vanilla -e "cat(.libPaths(),sep=.Platform`$path.sep)" 2>&1)
    $baselineRc=$LASTEXITCODE
    if($baselineRc -ne 0) {throw ("BASELINE_R_LIBPATH_QUERY_FAILED: exit="+$baselineRc+"; output="+($baselineOutput -join ' | '))}
    $baselineText=($baselineOutput -join '').Trim()
    if($baselineText) {
        foreach($p in @($baselineText -split [regex]::Escape([string][IO.Path]::PathSeparator))) {
            if([string]::IsNullOrWhiteSpace($p)){continue}
            try{$full=[IO.Path]::GetFullPath($p.Trim())}catch{continue}
            if(Test-Path -LiteralPath $full -PathType Container){$candidates.Add($full)|Out-Null}
        }
    }

    $unique=New-Object 'System.Collections.Generic.List[string]'
    $seen=@{}
    foreach($p in $candidates) {
        $key=$p.TrimEnd('\','/').ToLowerInvariant()
        if($seen.ContainsKey($key)){continue}
        $seen[$key]=$true
        $unique.Add($p)|Out-Null
    }
    if($unique.Count -lt 1 -or -not [string]::Equals($unique[0].TrimEnd('\','/'),$projectLib.TrimEnd('\','/'),[StringComparison]::OrdinalIgnoreCase)) {
        throw 'PROJECT_R_LIBRARY_NOT_FIRST'
    }
    $env:R_LIBS_USER=([string[]]$unique.ToArray()) -join [IO.Path]::PathSeparator
    return $env:R_LIBS_USER
}

function Write-PublicIdentityLedger {
    param(
        [Parameter(Mandatory=$true)][string]$OutFile,
        [Parameter(Mandatory=$true)][string[]]$Roles,
        [Parameter(Mandatory=$true)][string[]]$Paths,
        [hashtable]$FrozenExpected=@{}
    )
    if($Roles.Count -ne $Paths.Count){throw 'IDENTITY_LEDGER_ROLE_PATH_LENGTH_MISMATCH'}
    $rows=[System.Collections.Generic.List[object]]::new()
    for($i=0;$i-lt$Paths.Count;$i++) {
        $role=[string]$Roles[$i]
        $path=[IO.Path]::GetFullPath([string]$Paths[$i])
        $exists=Test-Path -LiteralPath $path -PathType Leaf
        $actual=if($exists){Get-PublicSha256 $path}else{''}
        $expected=if($FrozenExpected.ContainsKey($role)){[string]$FrozenExpected[$role]}else{$actual}
        $bytes=if($exists){[int64](Get-Item -LiteralPath $path).Length}else{$null}
        $match=$exists -and $expected -match '^[a-fA-F0-9]{64}$' -and [string]::Equals($actual,$expected,[StringComparison]::OrdinalIgnoreCase)
        $rows.Add([pscustomobject]@{role=$role;path=$path;exists=$exists;bytes=$bytes;expected_sha256=$expected;actual_sha256=$actual;sha_match=$match})|Out-Null
    }
    $parent=Split-Path -Parent $OutFile
    if(-not (Test-Path -LiteralPath $parent -PathType Container)){$null=New-Item -ItemType Directory -Path $parent -Force}
    $rows.ToArray() | Export-Csv -LiteralPath $OutFile -NoTypeInformation -Encoding UTF8
    $bad=@($rows|Where-Object{-not $_.sha_match})
    if($bad.Count){throw ('LAUNCHER_SUPPORT_IDENTITY_FAILURE: '+(($bad|ForEach-Object{$_.role}) -join ';'))}
    return [IO.Path]::GetFullPath($OutFile)
}

function Copy-PublicLauncherArtifact {
    param([Parameter(Mandatory=$true)][string]$SourcePath,[Parameter(Mandatory=$true)][string]$DestPath,[Parameter(Mandatory=$true)][string]$Role)
    if(-not (Test-Path -LiteralPath $SourcePath -PathType Leaf)){throw "LAUNCHER_SUPPORT_SOURCE_MISSING: $Role"}
    $parent=Split-Path -Parent $DestPath
    if(-not (Test-Path -LiteralPath $parent -PathType Container)){$null=New-Item -ItemType Directory -Path $parent -Force}
    if(Test-Path -LiteralPath $DestPath -PathType Leaf) {
        if((Get-PublicSha256 $DestPath) -ne (Get-PublicSha256 $SourcePath)){throw "LAUNCHER_SUPPORT_EXISTING_DEST_SHA_MISMATCH: $Role"}
    } else {
        Copy-Item -LiteralPath $SourcePath -Destination $DestPath -ErrorAction Stop
    }
    $sha=Get-PublicSha256 $DestPath
    if($sha -ne (Get-PublicSha256 $SourcePath)){throw "LAUNCHER_SUPPORT_REBIND_SHA_MISMATCH: $Role"}
    return [pscustomobject]@{role=$Role;source_path=[IO.Path]::GetFullPath($SourcePath);dest_path=[IO.Path]::GetFullPath($DestPath);sha256=$sha;byte_exact=$true}
}

function Get-PublicExactHallmarkGmt {
    param([Parameter(Mandatory=$true)]$Context)
    $p=[IO.Path]::GetFullPath((Join-Path $Context.ProjectRoot 'data\authority\MSigDB\h.all.v2026.1.Hs.symbols.gmt'))
    if(-not (Test-Path -LiteralPath $p -PathType Leaf)){throw 'EXACT_HALLMARK_GMT_MISSING'}
    if((Get-Item -LiteralPath $p).Length -ne 48686){throw 'EXACT_HALLMARK_GMT_BYTE_MISMATCH'}
    if((Get-PublicSha256 $p) -ne 'eecaf6dad908334ae885406ec72bdc0646d8917588ed7c219fac92fc5363f596'){throw 'EXACT_HALLMARK_GMT_SHA_MISMATCH'}
    return $p
}

function Clear-PublicR3LauncherEnvironment {
    foreach($name in @('R3_STEP4E_PREHASH','R3_STEP4F_PRE1_PREHASH','R3_STEP4D_V14_PREHASH','R3_STEP4D_V14_PUBLIC_ID','R3_STEP4F_V11_PREHASH','R3_STEP4F_V11_GMT_DISCOVERY')) {
        Remove-Item -Path ('Env:'+ $name) -ErrorAction SilentlyContinue
    }
}

function Prepare-PublicLauncherSupport {
    param([Parameter(Mandatory=$true)]$Context,[Parameter(Mandatory=$true)]$Node)
    Clear-PublicR3LauncherEnvironment
    if($Node.node_id -eq 'GATE9G_CANONICAL_STEP4B') {$env:RV_R3_STEP4B_OUTDIR=[IO.Path]::GetFullPath((Join-Path $Context.ResultsRoot 'R3_GSE249696'))}
    else {Remove-Item Env:RV_R3_STEP4B_OUTDIR -ErrorAction SilentlyContinue}

    if($Node.node_id -in @('C0328','C0331')) {
        $env:OMP_NUM_THREADS='1';$env:OPENBLAS_NUM_THREADS='1';$env:MKL_NUM_THREADS='1';$env:BLIS_NUM_THREADS='1'
    }

    if($Node.node_id -eq 'GATE9G_CANONICAL_STEP4B') {return 'STEP4B_OUTDIR_BOUND'}
    if($Node.node_id -notin @('C0328','C0329','C0324','C0331')) {return 'NOT_REQUIRED'}

    $support=Join-Path $Context.ControlRoot 'launcher_support'
    if(-not (Test-Path -LiteralPath $support -PathType Container)){$null=New-Item -ItemType Directory -Path $support -Force}
    $r3=Join-Path $Context.ResultsRoot 'R3_GSE249696'
    $sn=Join-Path $Context.ProjectRoot 'data\raw\GSE345646\GSE345646_snRV_ref.rds'
    $xe=Join-Path $Context.ProjectRoot 'data\raw\GSE345643\GSE345643_RV_Xenium_ambient_corrected_568651cells.rds'
    $frozen=@{
        SNRNA_RDS='a5b6b452566bac584c2d62180ef36a360d8e83e64451fb9de7d46779da64bfb1'
        XENIUM_RDS='afe397aed68d0b5fa4cf683c1702b86f990df73c14f1e7f82e38c9f61c255a9a'
    }

    if($Node.node_id -eq 'C0328') {
        $v13=Resolve-StrictStageRun $Context (Join-Path $r3 'R3_STEP4D_V1_3_runs')
        [string[]]$roles=@('SNRNA_RDS','XENIUM_RDS','V13_STATUS','V13_AUDIT','V13_REGISTRY','V13_SEMANTICS','V13_GUARDS','V13_OVERLAY','STEP4C_LABELS','METHOD','TIER','FDR','STEP4D_MASTER')
        [string[]]$paths=@($sn,$xe,(Join-Path $v13 'R3_STEP4D_V1_3_STATUS.txt'),(Join-Path $v13 'R3_STEP4D_V1_3_implementation_audit.csv'),(Join-Path $v13 'R3_STEP4D_V1_3_DETERMINISTIC_TEST_REGISTRY.csv'),(Join-Path $v13 'R3_STEP4D_V1_3_implementation_semantics.csv'),(Join-Path $v13 'R3_STEP4D_V1_3_STEP4F_FAIL_CLOSED_GUARDS.csv'),(Join-Path $v13 'R3_STEP4D_V1_3_DETERMINISTIC_IMPLEMENTATION_OVERLAY_FROZEN.txt'),(Join-Path $r3 'R3_STEP4C_V1_2_frozen_annotation_labels.csv'),(Join-Path $r3 'R3_STEP4D_localization_method_contract.csv'),(Join-Path $r3 'R3_STEP4D_program_modality_tier_contract.csv'),(Join-Path $r3 'R3_STEP4D_fixed_FDR_family_contract.csv'),(Join-Path $r3 'R3_STEP4D_LOCALIZATION_ANALYSIS_CONTRACT_FROZEN.txt'))
        $env:R3_STEP4E_PREHASH=Write-PublicIdentityLedger (Join-Path $support 'C0328_R3_STEP4E_SOURCE_SHA256_PREFLIGHT.csv') $roles $paths $frozen
    }
    elseif($Node.node_id -eq 'C0329') {
        $v13=Resolve-StrictStageRun $Context (Join-Path $r3 'R3_STEP4D_V1_3_runs')
        [string[]]$roles=@('SNRNA_RDS','METHOD','V13_GUARDS')
        [string[]]$paths=@($sn,(Join-Path $r3 'R3_STEP4D_localization_method_contract.csv'),(Join-Path $v13 'R3_STEP4D_V1_3_STEP4F_FAIL_CLOSED_GUARDS.csv'))
        $env:R3_STEP4F_PRE1_PREHASH=Write-PublicIdentityLedger (Join-Path $support 'C0329_R3_STEP4F_PRE1_SOURCE_SHA256_PREFLIGHT.csv') $roles $paths $frozen
    }
    elseif($Node.node_id -eq 'C0324') {
        $v13=Resolve-StrictStageRun $Context (Join-Path $r3 'R3_STEP4D_V1_3_runs')
        $pre1=Resolve-StrictStageRun $Context (Join-Path $r3 'R3_STEP4F_PRE1_runs')
        [string[]]$roles=@('PRE1_STATUS','PRE1_AUDIT','PRE1_VALUES','PRE1_NCOUNT','PRE1_INVENTORY','PRE1_NOTE','METHOD','TIER','FDR','CLASS','V13_REGISTRY','V13_GUARDS')
        [string[]]$paths=@((Join-Path $pre1 'R3_STEP4F_PRE1_STATUS.txt'),(Join-Path $pre1 'R3_STEP4F_PRE1_audit.csv'),(Join-Path $pre1 'R3_STEP4F_PRE1_value_semantics.csv'),(Join-Path $pre1 'R3_STEP4F_PRE1_RNA_counts_metadata_concordance.csv'),(Join-Path $pre1 'R3_STEP4F_PRE1_assay_layer_inventory.csv'),(Join-Path $pre1 'R3_STEP4F_PRE1_ADJUDICATION_NOTE.txt'),(Join-Path $r3 'R3_STEP4D_localization_method_contract.csv'),(Join-Path $r3 'R3_STEP4D_program_modality_tier_contract.csv'),(Join-Path $r3 'R3_STEP4D_fixed_FDR_family_contract.csv'),(Join-Path $r3 'R3_STEP4D_localization_classification_contract.csv'),(Join-Path $v13 'R3_STEP4D_V1_3_DETERMINISTIC_TEST_REGISTRY.csv'),(Join-Path $v13 'R3_STEP4D_V1_3_STEP4F_FAIL_CLOSED_GUARDS.csv'))
        $env:R3_STEP4D_V14_PREHASH=Write-PublicIdentityLedger (Join-Path $support 'C0324_R3_STEP4D_V14_SOURCE_SHA256_PREFLIGHT.csv') $roles $paths @{}
        $md5=Get-PublicMd5 $sn
        if($md5 -ne 'b13511f74a7abbebecb40ddd0cc04f32'){throw 'SNRNA_RDS_ZENODO_MD5_MISMATCH'}
        $pub=Join-Path $support 'C0324_R3_STEP4D_V14_PUBLIC_OBJECT_IDENTITY.csv'
        [pscustomobject]@{local_path=[IO.Path]::GetFullPath($sn);local_md5=$md5;zenodo_filename='shared__snRV_ref.rds';zenodo_md5='b13511f74a7abbebecb40ddd0cc04f32';zenodo_md5_match=$true} | Export-Csv -LiteralPath $pub -NoTypeInformation -Encoding UTF8
        $env:R3_STEP4D_V14_PUBLIC_ID=[IO.Path]::GetFullPath($pub)
    }
    elseif($Node.node_id -eq 'C0331') {
        $v13=Resolve-StrictStageRun $Context (Join-Path $r3 'R3_STEP4D_V1_3_runs')
        $v14=Resolve-StrictStageRun $Context (Join-Path $r3 'R3_STEP4D_V1_4_runs')
        $e=Resolve-StrictStageRun $Context (Join-Path $r3 'R3_STEP4E_runs')
        $rb=@(
            Copy-PublicLauncherArtifact (Join-Path $support 'C0328_R3_STEP4E_SOURCE_SHA256_PREFLIGHT.csv') (Join-Path $e 'R3_STEP4E_SOURCE_SHA256_PREFLIGHT.csv') 'STEP4E_SOURCE'
            Copy-PublicLauncherArtifact (Join-Path $support 'C0324_R3_STEP4D_V14_PUBLIC_OBJECT_IDENTITY.csv') (Join-Path $v14 'R3_STEP4D_V1_4_ZENODO_PUBLIC_OBJECT_IDENTITY.csv') 'V14_PUBLIC_ID'
        )
        $rbPath=Join-Path $support 'C0331_LAUNCHER_SUPPORT_REBINDING.csv'
        $rb | Export-Csv -LiteralPath $rbPath -NoTypeInformation -Encoding UTF8
        if($rb.Count -ne 2 -or @($rb|Where-Object{-not $_.byte_exact}).Count){throw 'C0331_LAUNCHER_SUPPORT_REBINDING_FAILED'}
        [string[]]$roles=@('SNRNA_RDS','XENIUM_RDS','STEP4E_STATUS','STEP4E_AUDIT','STEP4E_RUNTIME','STEP4E_PACKAGES','STEP4E_SMOKE','STEP4E_LAYER','STEP4E_ROLE','STEP4E_CROSS','STEP4E_COUNTS','STEP4E_DESIGN','STEP4E_REGFEAS','STEP4E_SOURCE','V13_REGISTRY','V13_SEMANTICS','V13_GUARD','METHOD','TIER','FDR','CLASS','LABELS','V14_STATUS','V14_AUDIT','V14_OVERLAY','V14_DELTA','V14_REPAIR','V14_PRECEDENCE','V14_PUBLIC_ID')
        [string[]]$paths=@($sn,$xe,(Join-Path $e 'R3_STEP4E_STATUS.txt'),(Join-Path $e 'R3_STEP4E_audit.csv'),(Join-Path $e 'R3_STEP4E_runtime_environment.csv'),(Join-Path $e 'R3_STEP4E_package_versions.csv'),(Join-Path $e 'R3_STEP4E_synthetic_mroast_smoke.csv'),(Join-Path $e 'R3_STEP4E_Assay5_sparse_layer_manifest.csv'),(Join-Path $e 'R3_STEP4E_metadata_role_freeze.csv'),(Join-Path $e 'R3_STEP4E_patient_crosswalk.csv'),(Join-Path $e 'R3_STEP4E_patient_group_annotation_cell_count_manifest.csv'),(Join-Path $e 'R3_STEP4E_design_feasibility.csv'),(Join-Path $e 'R3_STEP4E_registry_design_feasibility.csv'),(Join-Path $e 'R3_STEP4E_SOURCE_SHA256_PREFLIGHT.csv'),(Join-Path $v13 'R3_STEP4D_V1_3_DETERMINISTIC_TEST_REGISTRY.csv'),(Join-Path $v13 'R3_STEP4D_V1_3_implementation_semantics.csv'),(Join-Path $v13 'R3_STEP4D_V1_3_STEP4F_FAIL_CLOSED_GUARDS.csv'),(Join-Path $r3 'R3_STEP4D_localization_method_contract.csv'),(Join-Path $r3 'R3_STEP4D_program_modality_tier_contract.csv'),(Join-Path $r3 'R3_STEP4D_fixed_FDR_family_contract.csv'),(Join-Path $r3 'R3_STEP4D_localization_classification_contract.csv'),(Join-Path $r3 'R3_STEP4C_V1_2_frozen_annotation_labels.csv'),(Join-Path $v14 'R3_STEP4D_V1_4_STATUS.txt'),(Join-Path $v14 'R3_STEP4D_V1_4_audit.csv'),(Join-Path $v14 'R3_STEP4D_V1_4_SNRNA_SOURCE_SEMANTICS_OVERLAY.csv'),(Join-Path $v14 'R3_STEP4D_V1_4_EFFECTIVE_METHOD_DELTA.csv'),(Join-Path $v14 'R3_STEP4F_V1_1_IMPLEMENTATION_REPAIR_CONTRACT.csv'),(Join-Path $v14 'R3_STEP4D_V1_4_AUTHORITY_PRECEDENCE.txt'),(Join-Path $v14 'R3_STEP4D_V1_4_ZENODO_PUBLIC_OBJECT_IDENTITY.csv'))
        $env:R3_STEP4F_V11_PREHASH=Write-PublicIdentityLedger (Join-Path $support 'C0331_R3_STEP4F_V11_SOURCE_SHA256_PREFLIGHT.csv') $roles $paths $frozen
        $gmt=Get-PublicExactHallmarkGmt $Context
        $gd=Join-Path $support 'C0331_R3_STEP4F_V11_GMT_DISCOVERY.csv'
        [pscustomobject]@{path=[IO.Path]::GetFullPath($gmt);bytes=[int64](Get-Item -LiteralPath $gmt).Length;sha256=(Get-PublicSha256 $gmt);exact_sha=$true;selected=$true} | Export-Csv -LiteralPath $gd -NoTypeInformation -Encoding UTF8
        $env:R3_STEP4F_V11_GMT_DISCOVERY=[IO.Path]::GetFullPath($gd)
    }
    return 'PASS'
}

function Get-PublicRscript {
    param([string]$ExplicitPath)
    if($ExplicitPath) {$p=$ExplicitPath} elseif($env:RV_RSCRIPT) {$p=$env:RV_RSCRIPT} else {$p=(Get-Command Rscript.exe -ErrorAction SilentlyContinue).Source}
    if(-not $p -or -not (Test-Path -LiteralPath $p -PathType Leaf)) {throw 'RSCRIPT_PATH_REQUIRED'}
    return [IO.Path]::GetFullPath($p)
}

function Assert-PublicRPrerequisites {
    param([string]$RscriptPath)
    $r=Get-PublicRscript $RscriptPath
    $expr=@'
if(as.character(getRversion())!='4.6.1') quit(save='no',status=42L)
req <- c(fgsea='1.38.0',SeuratObject='5.4.0')
for(n in names(req)) if(!requireNamespace(n,quietly=TRUE) || as.character(utils::packageVersion(n))!=req[[n]]) quit(save='no',status=43L)
for(n in c('digest','BiocManager','edgeR','limma')) if(!requireNamespace(n,quietly=TRUE)) quit(save='no',status=44L)
cat('R=',as.character(getRversion()),';fgsea=',as.character(utils::packageVersion('fgsea')),';SeuratObject=',as.character(utils::packageVersion('SeuratObject')),';digest=',as.character(utils::packageVersion('digest')),sep='')
'@
    $out=@(& $r --vanilla -e $expr 2>&1)
    if($LASTEXITCODE -ne 0){throw ('R_PREREQUISITE_PARITY_FAILURE: '+($out -join ' | '))}
    return ($out -join '')
}

function Invoke-PublicNode {
    param([Parameter(Mandatory=$true)]$Context,[Parameter(Mandatory=$true)]$Node,[string]$RscriptPath)
    Assert-CurrentInvocationResults $Context
    $script=[IO.Path]::GetFullPath((Join-Path $Context.ProjectRoot ($Node.public_relative_path -replace '/','\')))
    if(-not $Node.public_relative_path.StartsWith('code/stages/')) {throw 'DISPATCH_REJECT_NON_EFFECTIVE_PATH'}
    if((Get-PublicSha256 $script) -ne $Node.effective_sha256) {throw 'DISPATCH_REJECT_SHA_MISMATCH'}
    $launcherSupportStatus=Prepare-PublicLauncherSupport $Context $Node
    $beforeState=@(Get-ResultState $Context)
    Write-ResultSnapshot $Context $Node.node_id ([int]$Node.sequence) 'before'
    Push-Location $Context.ProjectRoot
    try {
        if($Node.engine -eq 'R') {& (Get-PublicRscript $RscriptPath) --vanilla $script}
        elseif($Node.engine -eq 'POWERSHELL') {& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $script}
        else {throw 'DISPATCH_REJECT_ENGINE'}
        $exit=$LASTEXITCODE
    } finally {Pop-Location}
    Assert-NodeContract $Node $exit
    Assert-FrozenIdentities
    Test-NodePostcondition $Context $Node $beforeState
    Register-CurrentInvocationRuns $Context $Node.node_id ([int]$Node.sequence) 'PASS'
    Save-CurrentInvocationState $Context $Node.node_id ([int]$Node.sequence)
    Write-ResultSnapshot $Context $Node.node_id ([int]$Node.sequence) 'after'
    [pscustomobject]@{invocation_id=$Context.InvocationId;sequence=$Node.sequence;node_id=$Node.node_id;engine=$Node.engine;
        expected_exit=$Node.expected_exit;observed_exit=$exit;transition_policy=$Node.transition_policy;
        required_postcondition=$Node.required_postcondition;postcondition_status='PASS';launcher_support_status=$launcherSupportStatus;status='PASS';completed_utc=[DateTime]::UtcNow.ToString('o')}
}
