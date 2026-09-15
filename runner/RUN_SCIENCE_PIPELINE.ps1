#requires -Version 5.1
param([switch]$DryRun,[switch]$Execute,[string]$RscriptPath)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'Public.Science.Common.ps1')
. (Join-Path $PSScriptRoot 'Portable.Execution.ps1')
try{
    Initialize-PublicRoot
    Test-PublicRepository
    $dag=@(Get-FrozenDag)
    if($DryRun){
        $dag|Select-Object sequence,full94_sequence,node_id,layer,engine,expected_exit,transition_policy,required_postcondition|ConvertTo-Csv -NoTypeInformation
        Write-Output 'PUBLIC_SCIENCE_DRY_RUN_COMPLETE nodes=59 analysis_nodes_executed=0'
        exit 0
    }
    if(-not$Execute){throw 'EXPLICIT_EXECUTE_SWITCH_REQUIRED'}
    $failures=@(Get-ReadinessFailures)
    if($failures.Count){
        Write-PublicReceipt 'SciencePipeline' 'INPUT_PREFLIGHT_HOLD' $failures
        $failures|Write-Output
        exit 2
    }
    Assert-PublicRPrerequisites $RscriptPath
    Assert-NoPreseed
    $context=New-PublicInvocation -ProjectRoot $script:RVRoot
    $env:RV_PROJECT_ROOT=$script:RVRoot
    $childLib=Initialize-PublicChildLibraryStack -Context $context -RscriptPath $RscriptPath
    Write-Output ('PUBLIC_CHILD_R_LIBS_USER='+$childLib)
    $nodeRows=[System.Collections.Generic.List[object]]::new()
    $expectedSequence=1
    foreach($node in $dag){
        Assert-NextSequence $expectedSequence ([int]$node.sequence)
        $emission=@(Invoke-PublicNode -Context $context -Node $node -RscriptPath $RscriptPath)
        $result=@($emission|Where-Object{
            $_ -ne $null -and
            $_.PSObject.Properties.Name -contains 'node_id' -and
            $_.PSObject.Properties.Name -contains 'sequence' -and
            $_.PSObject.Properties.Name -contains 'status'
        })
        if($result.Count-ne1){throw "STRUCTURED_NODE_RESULT_COUNT_$($node.node_id)=$($result.Count)"}
        foreach($x in $emission){
            $isResult=($x-ne$null-and$x.PSObject.Properties.Name-contains'node_id'-and$x.PSObject.Properties.Name-contains'sequence'-and$x.PSObject.Properties.Name-contains'status')
            if(-not$isResult){Write-Output $x}
        }
        $nodeRows.Add($result[0])
        $nodeRows.ToArray()|Export-Csv -LiteralPath $context.NodeLedger -NoTypeInformation -Encoding UTF8
        $expectedSequence++
    }
    Write-Output "PUBLIC_SCIENCE_PIPELINE_COMPLETE invocation_id=$($context.InvocationId) nodes=59"
    exit 0
}catch{
    Write-Error $_ -ErrorAction Continue
    exit 2
}
