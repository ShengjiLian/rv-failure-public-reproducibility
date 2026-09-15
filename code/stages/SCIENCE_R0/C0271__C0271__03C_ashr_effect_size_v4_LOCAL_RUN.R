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
# RV Project — Exact R0 Step 3C
# ASHR effect-size shrinkage on the frozen PRIMARY ASSESSABLE universe
#
# AUTHOR-COMPATIBLE SHRINKAGE:
#   lfcShrink(..., contrast=c("category","RVF","pRV"), type="ashr")
#
# PRIMARY INFERENCE AUTHORITY REMAINS STEP 3B:
#   - assessable universe: default-fit betaConv == TRUE (18,621 genes)
#   - pvalue / padj: Step-3B DESeq2 results on assessable universe
#   - FDR: Step-3B DESeq2 independent filtering + BH, alpha=0.05
#
# THIS STEP ONLY ADDS SHRUNKEN EFFECT SIZE.
#
# DOES NOT:
#   - refit DESeq model
#   - rerun nbinomWaldTest
#   - alter primary pvalue/padj
#   - use maxit1000 as primary
#   - run PCA / enrichment
# ==============================================================================

options(stringsAsFactors=FALSE, warn=1)

ROOT <- normalizePath(getwd(), winslash="/", mustWork=TRUE)
if (!identical(ROOT,RV_PROJECT_ROOT)) stop("Expected D:/RV_project")

user_lib <- file.path(Sys.getenv("LOCALAPPDATA"),"R","win-library","4.6")
if (dir.exists(user_lib)) .libPaths(unique(c(user_lib,.libPaths())))

suppressPackageStartupMessages({
  library(DESeq2)
  library(ashr)
})

RES <- file.path(ROOT,"results","R0","v4_LOCAL_RUN")
LOGDIR <- file.path(ROOT,"logs")
dir.create(LOGDIR,recursive=TRUE,showWarnings=FALSE)

DDS_PATH <- file.path(RES,"R0_fitted_dds.rds")
PRIMARY_RES_RDS <- file.path(RES,"R0_RVF_vs_pRV_primary_assessable_results.rds")
PRIMARY_LEDGER <- file.path(RES,"R0_RVF_vs_pRV_primary_inference_ledger.csv")
STEP3B_GATE <- file.path(RES,"R0_STEP3B_PRIMARY_INFERENCE_UNIVERSE_PASS.txt")

OUT_ASHR_RDS <- file.path(RES,"R0_RVF_vs_pRV_primary_assessable_ashr_results.rds")
OUT_FULL <- file.path(RES,"R0_RVF_vs_pRV_primary_with_ashr_effects.csv")
OUT_SUMMARY <- file.path(RES,"R0_exact_step3C_ashr_summary.csv")
OUT_GATE <- file.path(RES,"R0_STEP3C_ASHR_EFFECT_SIZE_PASS.txt")
LOG <- file.path(LOGDIR,"R0_STEP3C_ashr_v4_LOCAL_RUN.log")

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
num_equal <- function(a,b,tol=1e-12) {
  if(!identical(is.na(a),is.na(b))) return(FALSE)
  ii <- which(!is.na(a) & !is.na(b))
  if(!length(ii)) return(TRUE)
  max(abs(a[ii]-b[ii])) <= tol
}

logline("============================================================")
logline("Exact R0 Step 3C — ASHR effect-size shrinkage")
logline("Primary p-values/FDR remain frozen from Step 3B.")
logline("============================================================")

must(file.exists(DDS_PATH),"Missing default fitted DDS")
must(file.exists(PRIMARY_RES_RDS),"Missing Step-3B assessable results RDS")
must(file.exists(PRIMARY_LEDGER),"Missing Step-3B primary inference ledger")
must(file.exists(STEP3B_GATE),"Missing Step-3B PASS gate")

if (file.exists(OUT_GATE) && file.exists(OUT_FULL) && file.exists(OUT_ASHR_RDS)) {
  logline("FINAL_GATE: R0_STEP3C_ASHR_EFFECT_SIZE_ALREADY_PASS__NO_RERUN")
  quit(save="no",status=0,runLast=FALSE)
}

dds <- readRDS(DDS_PATH)
must(inherits(dds,"DESeqDataSet"),"Invalid default fitted DDS")
must(nrow(dds)==19428L && ncol(dds)==142L,"Unexpected fitted dimensions")

mc <- as.data.frame(S4Vectors::mcols(dds))
must("betaConv" %in% names(mc),"betaConv missing")
bc <- as.logical(mc$betaConv)
must(sum(bc)==18621L && sum(!bc)==807L && sum(is.na(bc))==0L,
     "Unexpected default betaConv state")

dds_assess <- dds[bc,]
res_primary <- readRDS(PRIMARY_RES_RDS)
must(nrow(res_primary)==18621L,"Primary assessable result row count changed")
must(identical(rownames(res_primary),rownames(dds_assess)),
     "Primary result gene order differs from assessable DDS")

ledger <- read.csv(PRIMARY_LEDGER,stringsAsFactors=FALSE,check.names=FALSE)
must(nrow(ledger)==19428L,"Primary ledger row count changed")
must(identical(ledger$gene_id,rownames(dds)),"Primary ledger gene order changed")
must(sum(ledger$primary_inference_status=="ASSESSABLE_DEFAULT_FIT_CONVERGED")==18621L,
     "Primary ledger assessable count changed")

logline("Running author-compatible ASHR shrinkage on 18,621 assessable genes...")
shr <- DESeq2::lfcShrink(
  dds=dds_assess,
  contrast=c("category","RVF","pRV"),
  res=res_primary,
  type="ashr"
)

must(nrow(shr)==18621L,"ASHR result row count changed")
must(identical(rownames(shr),rownames(res_primary)),"ASHR result gene order changed")

sdf <- as.data.frame(shr)
must(all(c("baseMean","log2FoldChange","lfcSE") %in% names(sdf)),
     "ASHR result missing required effect-size columns")

# Do not trust/use shrunken-object inference columns as primary authority.
# Explicitly verify that the primary RDS still matches Step-3B ledger.
idx <- which(bc)
must(num_equal(as.numeric(res_primary$log2FoldChange),ledger$primary_log2FoldChange[idx],1e-10),
     "Step-3B unshrunk LFC authority mismatch")
must(num_equal(as.numeric(res_primary$lfcSE),ledger$primary_lfcSE[idx],1e-10),
     "Step-3B SE authority mismatch")
must(num_equal(as.numeric(res_primary$stat),ledger$primary_stat[idx],1e-10),
     "Step-3B stat authority mismatch")
must(num_equal(as.numeric(res_primary$pvalue),ledger$primary_pvalue[idx],1e-12),
     "Step-3B pvalue authority mismatch")
must(num_equal(as.numeric(res_primary$padj),ledger$primary_padj[idx],1e-12),
     "Step-3B padj authority mismatch")

shr_lfc <- as.numeric(sdf$log2FoldChange)
shr_se <- as.numeric(sdf$lfcSE)

finite_lfc <- is.finite(shr_lfc)
finite_se <- is.finite(shr_se)

unshr_lfc <- ledger$primary_log2FoldChange[idx]
sign_discordant <- is.finite(unshr_lfc) & is.finite(shr_lfc) &
                   sign(unshr_lfc) != 0 & sign(shr_lfc) != 0 &
                   sign(unshr_lfc) != sign(shr_lfc)

# Add shrinkage as EFFECT-SIZE columns only.
ledger$ashr_log2FoldChange <- NA_real_
ledger$ashr_lfcSE <- NA_real_
ledger$ashr_effect_status <- ifelse(
  bc,
  "ASSESSABLE_ASHR_PENDING",
  "NOT_ASSESSABLE_NO_SHRINKAGE"
)

ledger$ashr_log2FoldChange[idx] <- shr_lfc
ledger$ashr_lfcSE[idx] <- shr_se
ledger$ashr_effect_status[idx] <- ifelse(
  finite_lfc & finite_se,
  "ASSESSABLE_ASHR_EFFECT_AVAILABLE",
  "ASSESSABLE_ASHR_EFFECT_NONFINITE"
)

# Primary significance remains exactly the Step-3B flag.
must(sum(ledger$primary_FDR_lt_0_05)==330L,
     "Primary Step-3B FDR discovery count changed")

sig_idx <- idx[ledger$primary_FDR_lt_0_05[idx]]
sig_shr_lfc <- ledger$ashr_log2FoldChange[sig_idx]

summary <- data.frame(
  metric=c(
    "total_filtered_genes",
    "primary_assessable_genes",
    "primary_not_assessable_genes",
    "ashr_effect_finite_LFC_assessable",
    "ashr_effect_finite_SE_assessable",
    "ashr_effect_nonfinite_any_assessable",
    "unshrunk_vs_ashr_sign_discordant_assessable",
    "primary_FDR_lt_0_05_frozen",
    "primary_FDR_sig_with_finite_ashr_LFC",
    "primary_FDR_sig_ashr_positive",
    "primary_FDR_sig_ashr_negative",
    "primary_FDR_sig_ashr_zero",
    "pvalue_padj_modified_by_step3C"
  ),
  value=c(
    19428,
    18621,
    807,
    sum(finite_lfc),
    sum(finite_se),
    sum(!(finite_lfc & finite_se)),
    sum(sign_discordant),
    sum(ledger$primary_FDR_lt_0_05),
    sum(is.finite(sig_shr_lfc)),
    sum(is.finite(sig_shr_lfc) & sig_shr_lfc>0),
    sum(is.finite(sig_shr_lfc) & sig_shr_lfc<0),
    sum(is.finite(sig_shr_lfc) & sig_shr_lfc==0),
    0
  ),
  stringsAsFactors=FALSE
)

awrite(ledger,OUT_FULL)
asave(shr,OUT_ASHR_RDS)
awrite(summary,OUT_SUMMARY)

twrite(c(
  "R0_STEP3C_ASHR_EFFECT_SIZE_PASS",
  paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
  "primary_fit=DEFAULT_AUTHOR_MODEL",
  "primary_contrast=RVF_vs_pRV",
  "primary_assessable_genes=18621",
  "ashr_type=ashr",
  "ashr_scope=ASSESSABLE_GENES_ONLY",
  "ashr_role=EFFECT_SIZE_VISUALIZATION_AND_RANKING_ONLY",
  "primary_pvalue_authority=STEP3B_UNSHRUNKEN_WALD",
  "primary_padj_authority=STEP3B_DESEQ2_ASSESSABLE_UNIVERSE_BH",
  "primary_FDR_alpha=0.05",
  "pvalues_modified=NO",
  "padj_modified=NO",
  "model_refit_executed=NO",
  "maxit1000_primary_use=NO",
  "next_stage=Step 3D final R0 freeze only after ChatGPT audit"
),OUT_GATE)

logline("ASHR finite LFC=",sum(finite_lfc),"/18621")
logline("Sign discordance unshrunk vs ASHR=",sum(sign_discordant))
logline("Frozen primary FDR discoveries=",sum(ledger$primary_FDR_lt_0_05))
logline("FINAL_GATE: R0_STEP3C_ASHR_EFFECT_SIZE_PASS")
quit(save="no",status=0,runLast=FALSE)
