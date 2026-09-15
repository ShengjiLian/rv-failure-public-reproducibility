# ---- RV PUBLIC REPRODUCIBILITY PORTABILITY OVERLAY V1.0 ----
.RV_PROJECT_ROOT_ENV <- Sys.getenv('RV_PROJECT_ROOT', unset='')
RV_PROJECT_ROOT <- if (nzchar(.RV_PROJECT_ROOT_ENV)) {
  normalizePath(.RV_PROJECT_ROOT_ENV, winslash='/', mustWork=TRUE)
} else {
  normalizePath(getwd(), winslash='/', mustWork=TRUE)
}
# This overlay changes path binding only; scientific/statistical semantics remain historical authority.

source(file.path(RV_PROJECT_ROOT, 'code', 'lib', 'rv_runtime_helpers.R'))


# ==============================================================================
# RV Project — Exact R0 Step 3A
# Export DEFAULT-FIT DESeq2 RVF vs pRV Wald results only
#
# PRIMARY AUTHORITY:
#   R0_fitted_dds.rds (default author-model fit)
#
# DOES:
#   results(dds, contrast=c("category","RVF","pRV"), alpha=0.05)
#   export raw DESeq2 results + betaConv diagnostic
#
# DOES NOT:
#   refit model
#   use maxit1000 as primary
#   run lfcShrink / ashr
#   alter p-values or BH adjustment
#   make final DEG calls
#   run PCA / enrichment
# ==============================================================================

options(stringsAsFactors=FALSE, warn=1)

ROOT <- normalizePath(getwd(), winslash="/", mustWork=TRUE)
if (!identical(ROOT,RV_PROJECT_ROOT)) stop("Expected D:/RV_project")

user_lib <- file.path(Sys.getenv("LOCALAPPDATA"),"R","win-library","4.6")
if (dir.exists(user_lib)) .libPaths(unique(c(user_lib,.libPaths())))
suppressPackageStartupMessages(library(DESeq2))

RES <- file.path(ROOT,"results","R0","v4_LOCAL_RUN")
LOGDIR <- file.path(ROOT,"logs")
dir.create(LOGDIR,recursive=TRUE,showWarnings=FALSE)

DDS_PATH <- file.path(RES,"R0_fitted_dds.rds")
STEP2D <- file.path(RES,"R0_STEP2D_TARGETED_STABILITY_AUDIT_PASS.txt")

OUT_CSV <- file.path(RES,"R0_RVF_vs_pRV_DESeq2_default_results.csv")
OUT_RDS <- file.path(RES,"R0_RVF_vs_pRV_DESeq2_default_results.rds")
OUT_SUMMARY <- file.path(RES,"R0_exact_step3A_results_diagnostic_summary.csv")
OUT_GATE <- file.path(RES,"R0_STEP3A_DEFAULT_RESULTS_EXPORT_PASS.txt")
LOG <- file.path(LOGDIR,"R0_STEP3A_default_results_v4_LOCAL_RUN.log")

logline <- function(...) {
  z <- paste0(format(Sys.time(),"%Y-%m-%d %H:%M:%S")," | ",paste0(...,collapse=""))
  cat(z,"\n",sep="")
  cat(z,"\n",file=LOG,append=TRUE,sep="")
}
must <- function(x,msg) if(!isTRUE(x)) stop(msg,call.=FALSE)
awrite <- function(x,p) {
  t <- paste0(p,".tmp_",Sys.getpid())
  write.csv(x,t,row.names=FALSE,na="")
  if(!file.rename(t,p)) {unlink(t); stop("Atomic CSV failed: ",p)}
}
asave <- function(x,p) {
  t <- paste0(p,".tmp_",Sys.getpid())
  saveRDS(x,t,compress=TRUE)
  if(!file.rename(t,p)) {unlink(t); stop("Atomic RDS failed: ",p)}
}
twrite <- function(x,p) {
  t <- paste0(p,".tmp_",Sys.getpid())
  writeLines(x,t,useBytes=TRUE)
  if(!file.rename(t,p)) {unlink(t); stop("Atomic text failed: ",p)}
}

logline("============================================================")
logline("Exact R0 Step 3A — DEFAULT-FIT RVF vs pRV result export")
logline("No refitting. No shrinkage. No final convergence/FDR adjudication.")
logline("============================================================")

must(file.exists(DDS_PATH),"Missing original default fitted DDS")
must(file.exists(STEP2D),"Missing Step-2D targeted stability PASS gate")

if (file.exists(OUT_GATE) && file.exists(OUT_CSV) && file.exists(OUT_RDS)) {
  logline("FINAL_GATE: R0_STEP3A_DEFAULT_RESULTS_EXPORT_ALREADY_PASS__NO_RERUN")
  quit(save="no",status=0,runLast=FALSE)
}

dds <- readRDS(DDS_PATH)
must(inherits(dds,"DESeqDataSet"),"Invalid fitted DDS")
must(nrow(dds)==19428L && ncol(dds)==142L,"Unexpected fitted dimensions")

mc <- as.data.frame(S4Vectors::mcols(dds))
must("betaConv" %in% names(mc),"betaConv missing")
bc <- as.logical(mc$betaConv)
must(sum(!bc,na.rm=TRUE)==807L && sum(is.na(bc))==0L,
     "Default-fit betaConv state changed")

logline("Extracting DESeq2 results: RVF vs pRV; default filtering/Cook's handling; alpha=0.05")
res <- DESeq2::results(
  dds,
  contrast=c("category","RVF","pRV"),
  alpha=0.05
)

must(nrow(res)==19428L,"Result row count changed")
must(identical(rownames(res),rownames(dds)),"Result gene order changed")

rdf <- as.data.frame(res)
need <- c("baseMean","log2FoldChange","lfcSE","stat","pvalue","padj")
must(all(need %in% names(rdf)),"Expected DESeq2 result columns missing")

out <- data.frame(
  gene_id=rownames(dds),
  betaConv=bc,
  inference_status=ifelse(bc,"DEFAULT_FIT_CONVERGED","DEFAULT_FIT_NONCONVERGED"),
  baseMean=rdf$baseMean,
  log2FoldChange=rdf$log2FoldChange,
  lfcSE=rdf$lfcSE,
  stat=rdf$stat,
  pvalue=rdf$pvalue,
  padj=rdf$padj,
  stringsAsFactors=FALSE
)

idx_c <- which(bc)
idx_n <- which(!bc)

summary <- data.frame(
  metric=c(
    "total_genes",
    "default_fit_converged",
    "default_fit_nonconverged",
    "finite_pvalue_all",
    "finite_padj_all",
    "finite_pvalue_converged",
    "finite_padj_converged",
    "finite_pvalue_nonconverged",
    "finite_padj_nonconverged",
    "raw_DESeq2_padj_lt_0_05_all",
    "raw_DESeq2_padj_lt_0_05_converged",
    "raw_DESeq2_padj_lt_0_05_nonconverged",
    "raw_DESeq2_pvalue_lt_0_05_nonconverged",
    "nonconverged_with_NA_pvalue",
    "nonconverged_with_NA_padj"
  ),
  value=c(
    nrow(out),
    length(idx_c),
    length(idx_n),
    sum(is.finite(out$pvalue)),
    sum(is.finite(out$padj)),
    sum(is.finite(out$pvalue[idx_c])),
    sum(is.finite(out$padj[idx_c])),
    sum(is.finite(out$pvalue[idx_n])),
    sum(is.finite(out$padj[idx_n])),
    sum(is.finite(out$padj) & out$padj<0.05),
    sum(is.finite(out$padj[idx_c]) & out$padj[idx_c]<0.05),
    sum(is.finite(out$padj[idx_n]) & out$padj[idx_n]<0.05),
    sum(is.finite(out$pvalue[idx_n]) & out$pvalue[idx_n]<0.05),
    sum(is.na(out$pvalue[idx_n])),
    sum(is.na(out$padj[idx_n]))
  ),
  stringsAsFactors=FALSE
)

# Important: this step records DESeq2's raw output exactly.
# It does NOT reinterpret betaConv=FALSE p-values as valid or invalid yet.
awrite(out,OUT_CSV)
asave(res,OUT_RDS)
awrite(summary,OUT_SUMMARY)

twrite(c(
  "R0_STEP3A_DEFAULT_RESULTS_EXPORT_PASS",
  paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
  "primary_fit=DEFAULT_AUTHOR_MODEL",
  "contrast=RVF_vs_pRV",
  "results_alpha=0.05",
  "DESeq2_default_independent_filtering=YES",
  "DESeq2_default_cooks_handling=YES",
  "beta_nonconverged=807",
  "pvalues_modified=NO",
  "padj_modified=NO",
  "final_DEG_call_executed=NO",
  "lfcShrink_executed=NO",
  "next_action=Return summary and result export to ChatGPT for convergence/FDR adjudication"
),OUT_GATE)

logline("Export complete.")
logline("finite p-values among 807 nonconverged = ",summary$value[summary$metric=="finite_pvalue_nonconverged"])
logline("raw padj<0.05 among 807 nonconverged = ",summary$value[summary$metric=="raw_DESeq2_padj_lt_0_05_nonconverged"])
logline("FINAL_GATE: R0_STEP3A_DEFAULT_RESULTS_EXPORT_PASS")
quit(save="no",status=0,runLast=FALSE)
