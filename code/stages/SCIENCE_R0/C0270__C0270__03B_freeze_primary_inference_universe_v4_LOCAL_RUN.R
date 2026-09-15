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
# RV Project — Exact R0 Step 3B
# Freeze PRIMARY assessable inference universe
#
# PRIMARY RULE:
#   default-fit betaConv == TRUE  -> ASSESSABLE
#   default-fit betaConv == FALSE -> NOT_ASSESSABLE_NUMERICAL_NONCONVERGENCE
#
# ACTION:
#   subset the already-fitted default DDS to betaConv==TRUE rows
#   -> DESeq2::results(... RVF vs pRV, alpha=0.05)
#   -> DESeq2 performs its own independent filtering + BH on assessable universe
#
# DOES NOT:
#   refit DESeq model
#   estimate size factors
#   estimate dispersions
#   use maxit1000 as primary
#   run lfcShrink / ashr / PCA / enrichment
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
STEP3A_CSV <- file.path(RES,"R0_RVF_vs_pRV_DESeq2_default_results.csv")
STEP3A_GATE <- file.path(RES,"R0_STEP3A_DEFAULT_RESULTS_EXPORT_PASS.txt")

OUT_LEDGER <- file.path(RES,"R0_RVF_vs_pRV_primary_inference_ledger.csv")
OUT_ASSESSABLE_RDS <- file.path(RES,"R0_RVF_vs_pRV_primary_assessable_results.rds")
OUT_SUMMARY <- file.path(RES,"R0_exact_step3B_primary_FDR_summary.csv")
OUT_GATE <- file.path(RES,"R0_STEP3B_PRIMARY_INFERENCE_UNIVERSE_PASS.txt")
LOG <- file.path(LOGDIR,"R0_STEP3B_primary_inference_v4_LOCAL_RUN.log")

logline <- function(...) {
  z <- paste0(format(Sys.time(),"%Y-%m-%d %H:%M:%S")," | ",paste0(...,collapse=""))
  cat(z,"\n",sep="")
  cat(z,"\n",file=LOG,append=TRUE,sep="")
  flush.console()
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
logline("Exact R0 Step 3B — primary assessable inference universe")
logline("Default betaConv TRUE only; NO model refitting.")
logline("============================================================")

must(file.exists(DDS_PATH),"Missing default fitted DDS")
must(file.exists(STEP3A_CSV),"Missing Step-3A raw result export")
must(file.exists(STEP3A_GATE),"Missing Step-3A PASS gate")

if (file.exists(OUT_GATE) && file.exists(OUT_LEDGER) && file.exists(OUT_ASSESSABLE_RDS)) {
  logline("FINAL_GATE: R0_STEP3B_PRIMARY_INFERENCE_UNIVERSE_ALREADY_PASS__NO_RERUN")
  quit(save="no",status=0,runLast=FALSE)
}

dds <- readRDS(DDS_PATH)
must(inherits(dds,"DESeqDataSet"),"Invalid default fitted DDS")
must(nrow(dds)==19428L && ncol(dds)==142L,"Unexpected default fitted dimensions")

mc <- as.data.frame(S4Vectors::mcols(dds))
must("betaConv" %in% names(mc),"betaConv missing")
bc <- as.logical(mc$betaConv)
must(sum(bc)==18621L && sum(!bc)==807L && sum(is.na(bc))==0L,
     "Unexpected default betaConv state")

raw_export <- read.csv(STEP3A_CSV,stringsAsFactors=FALSE,check.names=FALSE)
must(nrow(raw_export)==19428L,"Step-3A export row count changed")
must(identical(raw_export$gene_id,rownames(dds)),"Step-3A export gene order differs")
must(all(as.logical(raw_export$betaConv)==bc),"Step-3A betaConv differs from fitted DDS")

dds_assess <- dds[bc,]
must(nrow(dds_assess)==18621L && ncol(dds_assess)==142L,
     "Assessable DDS dimensions unexpected")

logline("Extracting RVF vs pRV results on assessable universe n=18621...")
res_assess <- DESeq2::results(
  dds_assess,
  contrast=c("category","RVF","pRV"),
  alpha=0.05
)
must(nrow(res_assess)==18621L,"Assessable result row count changed")

adf <- as.data.frame(res_assess)
need <- c("baseMean","log2FoldChange","lfcSE","stat","pvalue","padj")
must(all(need %in% names(adf)),"Expected DESeq2 result columns missing")

# Strong reproducibility check:
# For rows already assessable, subsetting the testing universe must not alter
# unadjusted coefficient-level inference. Only independent filtering/BH may differ.
raw_c <- raw_export[bc,,drop=FALSE]
must(identical(raw_c$gene_id,rownames(res_assess)),"Assessable gene order mismatch")

num_equal <- function(a,b,tol=1e-10) {
  same_na <- identical(is.na(a),is.na(b))
  if(!same_na) return(FALSE)
  idx <- which(!is.na(a) & !is.na(b))
  if(!length(idx)) return(TRUE)
  max(abs(a[idx]-b[idx])) <= tol
}

lfc_same <- num_equal(raw_c$log2FoldChange,adf$log2FoldChange,1e-10)
se_same <- num_equal(raw_c$lfcSE,adf$lfcSE,1e-10)
stat_same <- num_equal(raw_c$stat,adf$stat,1e-10)
p_same <- num_equal(raw_c$pvalue,adf$pvalue,1e-12)

must(lfc_same && se_same && stat_same && p_same,
     "Subsetting assessable universe unexpectedly changed unadjusted Wald inference")

# Full 19,428-row transparent ledger.
ledger <- data.frame(
  gene_id=raw_export$gene_id,
  betaConv=bc,
  primary_inference_status=ifelse(
    bc,
    "ASSESSABLE_DEFAULT_FIT_CONVERGED",
    "NOT_ASSESSABLE_NUMERICAL_NONCONVERGENCE"
  ),
  raw_default_baseMean=raw_export$baseMean,
  raw_default_log2FoldChange=raw_export$log2FoldChange,
  raw_default_lfcSE=raw_export$lfcSE,
  raw_default_stat=raw_export$stat,
  raw_default_pvalue=raw_export$pvalue,
  raw_default_padj=raw_export$padj,
  primary_baseMean=NA_real_,
  primary_log2FoldChange=NA_real_,
  primary_lfcSE=NA_real_,
  primary_stat=NA_real_,
  primary_pvalue=NA_real_,
  primary_padj=NA_real_,
  primary_FDR_lt_0_05=FALSE,
  stringsAsFactors=FALSE
)

idx <- which(bc)
ledger$primary_baseMean[idx] <- adf$baseMean
ledger$primary_log2FoldChange[idx] <- adf$log2FoldChange
ledger$primary_lfcSE[idx] <- adf$lfcSE
ledger$primary_stat[idx] <- adf$stat
ledger$primary_pvalue[idx] <- adf$pvalue
ledger$primary_padj[idx] <- adf$padj
ledger$primary_FDR_lt_0_05[idx] <- is.finite(adf$padj) & adf$padj < 0.05

# Explicitly prove nonconverged rows are excluded from primary inference.
must(all(is.na(ledger$primary_pvalue[!bc])),"Nonconverged primary p-values must be NA")
must(all(is.na(ledger$primary_padj[!bc])),"Nonconverged primary padj must be NA")
must(!any(ledger$primary_FDR_lt_0_05[!bc]),"Nonconverged rows cannot be primary discoveries")

summary <- data.frame(
  metric=c(
    "total_filtered_genes",
    "primary_assessable_genes",
    "primary_not_assessable_beta_nonconverged",
    "assessable_finite_pvalue",
    "assessable_finite_padj_after_DESeq2_independent_filtering",
    "primary_FDR_lt_0_05",
    "primary_FDR_lt_0_05_up",
    "primary_FDR_lt_0_05_down",
    "raw_default_FDR_lt_0_05_all",
    "raw_default_FDR_lt_0_05_nonconverged_excluded",
    "lfc_identity_assessable",
    "se_identity_assessable",
    "stat_identity_assessable",
    "pvalue_identity_assessable"
  ),
  value=c(
    19428,
    18621,
    807,
    sum(is.finite(adf$pvalue)),
    sum(is.finite(adf$padj)),
    sum(is.finite(adf$padj) & adf$padj<0.05),
    sum(is.finite(adf$padj) & adf$padj<0.05 & adf$log2FoldChange>0),
    sum(is.finite(adf$padj) & adf$padj<0.05 & adf$log2FoldChange<0),
    sum(is.finite(raw_export$padj) & raw_export$padj<0.05),
    sum(!bc & is.finite(raw_export$padj) & raw_export$padj<0.05),
    lfc_same,se_same,stat_same,p_same
  ),
  stringsAsFactors=FALSE
)

awrite(ledger,OUT_LEDGER)
asave(res_assess,OUT_ASSESSABLE_RDS)
awrite(summary,OUT_SUMMARY)

twrite(c(
  "R0_STEP3B_PRIMARY_INFERENCE_UNIVERSE_PASS",
  paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
  "primary_fit=DEFAULT_AUTHOR_MODEL",
  "primary_contrast=RVF_vs_pRV",
  "primary_assessable_rule=betaConv_TRUE",
  "nonconverged_rule=NOT_ASSESSABLE_NUMERICAL_NONCONVERGENCE",
  "assessable_genes=18621",
  "not_assessable_genes=807",
  "FDR_engine=DESeq2_results_independent_filtering_plus_BH",
  "FDR_alpha=0.05",
  "maxit1000_primary_use=NO",
  "model_refit_executed=NO",
  "lfcShrink_executed=NO",
  "next_stage=Step 3C effect-size shrinkage only after ChatGPT audit"
),OUT_GATE)

logline("Primary assessable FDR<0.05 = ",
        summary$value[summary$metric=="primary_FDR_lt_0_05"])
logline("Excluded raw-significant nonconverged = ",
        summary$value[summary$metric=="raw_default_FDR_lt_0_05_nonconverged_excluded"])
logline("FINAL_GATE: R0_STEP3B_PRIMARY_INFERENCE_UNIVERSE_PASS")
quit(save="no",status=0,runLast=FALSE)
