# ---- RV PUBLIC REPRODUCIBILITY PORTABILITY OVERLAY V1.0 ----
.RV_PROJECT_ROOT_ENV <- Sys.getenv('RV_PROJECT_ROOT', unset='')
RV_PROJECT_ROOT <- if (nzchar(.RV_PROJECT_ROOT_ENV)) {
  normalizePath(.RV_PROJECT_ROOT_ENV, winslash='/', mustWork=TRUE)
} else {
  normalizePath(getwd(), winslash='/', mustWork=TRUE)
}
# This overlay changes path binding only; scientific/statistical semantics remain historical authority.

source(file.path(RV_PROJECT_ROOT, 'code', 'lib', 'rv_runtime_helpers.R'))


options(stringsAsFactors=FALSE, warn=1)

ROOT <- normalizePath(getwd(), winslash="/", mustWork=TRUE)
if (!identical(ROOT,RV_PROJECT_ROOT)) stop("Expected D:/RV_project")

user_lib <- file.path(Sys.getenv("LOCALAPPDATA"),"R","win-library","4.6")
if (dir.exists(user_lib)) .libPaths(unique(c(user_lib,.libPaths())))
suppressPackageStartupMessages(library(DESeq2))

RES <- file.path(ROOT,"results","R0","v4_LOCAL_RUN")
LOGDIR <- file.path(ROOT,"logs")
dir.create(LOGDIR,recursive=TRUE,showWarnings=FALSE)

FITTED <- file.path(RES,"R0_fitted_dds.rds")
HOLD <- file.path(RES,"R0_EXACT_MODEL_FIT_HOLD.txt")
OUT1 <- file.path(RES,"R0_exact_step2B_nonconverged_gene_diagnostic.csv")
OUT2 <- file.path(RES,"R0_exact_step2B_beta_convergence_summary.csv")
OUT3 <- file.path(RES,"R0_exact_step2B_convergence_group_quantiles.csv")
GATE <- file.path(RES,"R0_STEP2B_BETA_DIAGNOSTIC_PASS.txt")
LOG <- file.path(LOGDIR,"R0_STEP2B_v4_LOCAL_RUN.log")

logline <- function(...) {
  z <- paste0(format(Sys.time(),"%Y-%m-%d %H:%M:%S")," | ",paste0(...,collapse=""))
  cat(z,"\n",sep="")
  cat(z,"\n",file=LOG,append=TRUE,sep="")
}
must <- function(x,msg) if (!isTRUE(x)) stop(msg,call.=FALSE)
awrite <- function(x,p) {
  t <- paste0(p,".tmp_",Sys.getpid())
  write.csv(x,t,row.names=FALSE,na="")
  if (!file.rename(t,p)) {unlink(t); stop("Write failed: ",p)}
}
twrite <- function(x,p) {
  t <- paste0(p,".tmp_",Sys.getpid())
  writeLines(x,t,useBytes=TRUE)
  if (!file.rename(t,p)) {unlink(t); stop("Write failed: ",p)}
}
q5 <- function(x) {
  x <- x[is.finite(x)]
  if (!length(x)) return(rep(NA_real_,5))
  as.numeric(quantile(x,c(0,.25,.5,.75,1),names=FALSE))
}

logline("Step 2B beta-convergence diagnostic; fitted model is read only.")
must(file.exists(FITTED),"Missing fitted checkpoint")
must(file.exists(HOLD),"Missing Step-2 HOLD gate")
ht <- readLines(HOLD,warn=FALSE)
must(length(ht)>0 && ht[1]=="R0_EXACT_MODEL_FIT_HOLD_BETA_CONVERGENCE",
     "Unexpected Step-2 gate")

dds <- readRDS(FITTED)
must(inherits(dds,"DESeqDataSet"),"Not a DESeqDataSet")
must(nrow(dds)==19428L && ncol(dds)==142L,"Unexpected fitted dimensions")

mc <- as.data.frame(S4Vectors::mcols(dds))
must("betaConv" %in% names(mc),"betaConv missing")
bc <- as.logical(mc$betaConv)
must(sum(bc==FALSE,na.rm=TRUE)==807L && sum(is.na(bc))==0L,
     "Expected 807 non-converged and 0 NA")

raw <- DESeq2::counts(dds,normalized=FALSE)
norm <- DESeq2::counts(dds,normalized=TRUE)
cd <- as.data.frame(SummarizedExperiment::colData(dds))
must("category" %in% names(cd),"category missing")
grp <- as.character(cd$category)
must(all(grp %in% c("NF","pRV","RVF")),"Unexpected categories")

getmc <- function(nm) if (nm %in% names(mc)) mc[[nm]] else rep(NA_real_,nrow(dds))

ledger <- data.frame(
  gene_id=rownames(dds),
  betaConv=bc,
  betaIter=getmc("betaIter"),
  baseMean=getmc("baseMean"),
  dispersion=getmc("dispersion"),
  maxCooks=getmc("maxCooks"),
  detected_samples_raw_gt0=rowSums(raw>0),
  samples_norm_ge5=rowSums(norm>=5),
  samples_norm_ge10=rowSums(norm>=10),
  NF_samples_norm_ge5=rowSums(norm[,grp=="NF",drop=FALSE]>=5),
  pRV_samples_norm_ge5=rowSums(norm[,grp=="pRV",drop=FALSE]>=5),
  RVF_samples_norm_ge5=rowSums(norm[,grp=="RVF",drop=FALSE]>=5),
  median_normalized_count=apply(norm,1,median),
  max_normalized_count=apply(norm,1,max),
  stringsAsFactors=FALSE
)
nonc <- ledger[!ledger$betaConv,,drop=FALSE]
must(nrow(nonc)==807L,"Diagnostic ledger is not 807 rows")

mkq <- function(flag,label) {
  z <- ledger[ledger$betaConv==flag,,drop=FALSE]
  bm <- q5(z$baseMean); s5 <- q5(z$samples_norm_ge5)
  det <- q5(z$detected_samples_raw_gt0); dp <- q5(z$dispersion); it <- q5(z$betaIter)
  data.frame(
    convergence_group=label, genes=nrow(z),
    baseMean_min=bm[1],baseMean_q25=bm[2],baseMean_median=bm[3],baseMean_q75=bm[4],baseMean_max=bm[5],
    samples_ge5_min=s5[1],samples_ge5_q25=s5[2],samples_ge5_median=s5[3],samples_ge5_q75=s5[4],samples_ge5_max=s5[5],
    detected_min=det[1],detected_q25=det[2],detected_median=det[3],detected_q75=det[4],detected_max=det[5],
    dispersion_min=dp[1],dispersion_q25=dp[2],dispersion_median=dp[3],dispersion_q75=dp[4],dispersion_max=dp[5],
    betaIter_min=it[1],betaIter_q25=it[2],betaIter_median=it[3],betaIter_q75=it[4],betaIter_max=it[5],
    stringsAsFactors=FALSE
  )
}
quant <- rbind(mkq(TRUE,"CONVERGED"),mkq(FALSE,"NONCONVERGED"))

summary <- data.frame(
  metric=c(
    "total_genes","beta_converged_genes","beta_nonconverged_genes",
    "beta_nonconverged_percent",
    "nonconverged_exactly_3_samples_norm_ge5",
    "nonconverged_3_to_5_samples_norm_ge5",
    "nonconverged_le10_samples_norm_ge5",
    "nonconverged_all_groups_have_ge5_support",
    "nonconverged_betaIter_ge100",
    "nonconverged_baseMean_lt10",
    "nonconverged_baseMean_lt20",
    "nonconverged_baseMean_lt50"
  ),
  value=c(
    nrow(ledger),sum(bc),sum(!bc),100*sum(!bc)/length(bc),
    sum(nonc$samples_norm_ge5==3),
    sum(nonc$samples_norm_ge5>=3 & nonc$samples_norm_ge5<=5),
    sum(nonc$samples_norm_ge5<=10),
    sum(nonc$NF_samples_norm_ge5>0 & nonc$pRV_samples_norm_ge5>0 & nonc$RVF_samples_norm_ge5>0),
    sum(is.finite(nonc$betaIter) & nonc$betaIter>=100),
    sum(is.finite(nonc$baseMean) & nonc$baseMean<10),
    sum(is.finite(nonc$baseMean) & nonc$baseMean<20),
    sum(is.finite(nonc$baseMean) & nonc$baseMean<50)
  ),
  stringsAsFactors=FALSE
)

awrite(nonc,OUT1)
awrite(summary,OUT2)
awrite(quant,OUT3)
twrite(c(
  "R0_STEP2B_BETA_DIAGNOSTIC_PASS",
  paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
  "model_refit_executed=NO",
  "downstream_results_executed=NO",
  "fitted_checkpoint_modified=NO",
  "total_genes=19428",
  "beta_nonconverged=807",
  "next_action=Return diagnostic outputs to ChatGPT"
),GATE)

logline("FINAL_GATE: R0_STEP2B_BETA_DIAGNOSTIC_PASS")
quit(save="no",status=0,runLast=FALSE)
