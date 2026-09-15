#requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$Root=[IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$ProjectLib=Join-Path $Root 'R_library\R-4.6'
if(-not(Test-Path $ProjectLib -PathType Container)){throw "Project R library missing: $ProjectLib"}
$r=if($env:RV_RSCRIPT){$env:RV_RSCRIPT}else{(Get-Command Rscript.exe -ErrorAction SilentlyContinue).Source}
if(-not$r -or -not(Test-Path $r -PathType Leaf)){throw 'Rscript.exe not found; install R 4.6.1 or set RV_RSCRIPT.'}
$sep=[IO.Path]::PathSeparator
$env:R_LIBS_USER=$ProjectLib
$expr=@'
req <- c(
  BiocManager="1.30.27", DESeq2="1.52.0", tximport="1.40.0", rhdf5="2.56.0",
  ashr="2.2.63", fgsea="1.38.0", limma="3.68.4", edgeR="4.10.1",
  Matrix="1.7.5", SeuratObject="5.4.0", digest="0.6.39", ggplot2="4.0.3",
  `data.table`="1.18.6.1", readxl="1.5.0", S4Vectors="0.50.1",
  SummarizedExperiment="1.42.0", sp="2.2-3", spam="2.11-4"
)
if(as.character(getRversion())!="4.6.1") {
  cat("R_VERSION_FAIL observed=",as.character(getRversion()),"\n",sep="")
  quit(save="no",status=42L)
}
bad <- character()
for(n in names(req)) {
  if(!requireNamespace(n,quietly=TRUE)) bad <- c(bad,paste0(n,"=MISSING"))
  else {
    v <- as.character(utils::packageVersion(n))
    if(v != req[[n]]) bad <- c(bad,paste0(n,"=",v," expected ",req[[n]]))
  }
}
if(length(bad)) {
  cat(paste(bad,collapse="\n"),"\n")
  quit(save="no",status=43L)
}
cat("PASS_ENVIRONMENT R=",as.character(getRversion())," packages=",length(req),"\n",sep="")
'@
& $r --vanilla -e $expr
exit $LASTEXITCODE
