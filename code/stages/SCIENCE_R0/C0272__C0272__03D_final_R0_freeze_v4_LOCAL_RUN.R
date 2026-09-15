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
# RV Project — Exact R0 Step 3D
# FINAL freeze of GSE345645 RVF vs pRV primary differential-expression results
#
# INPUT AUTHORITY:
#   R0_RVF_vs_pRV_primary_with_ashr_effects.csv  (Step 3C)
#
# FROZEN PRIMARY RULES:
#   - primary fit: default author model
#   - design: ~ category + SV1 + ... + SV21
#   - contrast: RVF vs pRV
#   - assessable: default-fit betaConv == TRUE
#   - nonconverged: NOT_ASSESSABLE_NUMERICAL_NONCONVERGENCE
#   - p-value authority: Step-3B unshrunken Wald
#   - FDR authority: DESeq2 independent filtering + BH on assessable universe
#   - alpha: 0.05
#   - ASHR: effect-size visualization/ranking only
#
# THIS STEP:
#   - performs NO statistical model fitting
#   - performs NO new multiple-testing correction
#   - performs NO new significance threshold optimization
#   - simply freezes clean final tables and gate
# ==============================================================================

options(stringsAsFactors=FALSE, warn=1)

ROOT <- normalizePath(getwd(), winslash="/", mustWork=TRUE)
if (!identical(ROOT,RV_PROJECT_ROOT)) stop("Expected D:/RV_project")

RES <- file.path(ROOT,"results","R0","v4_LOCAL_RUN")
LOGDIR <- file.path(ROOT,"logs")
dir.create(LOGDIR,recursive=TRUE,showWarnings=FALSE)

IN_LEDGER <- file.path(RES,"R0_RVF_vs_pRV_primary_with_ashr_effects.csv")
STEP3C_GATE <- file.path(RES,"R0_STEP3C_ASHR_EFFECT_SIZE_PASS.txt")

OUT_ALL <- file.path(RES,"R0_FINAL_RVF_vs_pRV_all_filtered_genes.csv")
OUT_ASSESS <- file.path(RES,"R0_FINAL_RVF_vs_pRV_assessable_results.csv")
OUT_SIG <- file.path(RES,"R0_FINAL_RVF_vs_pRV_FDR05.csv")
OUT_NONASSESS <- file.path(RES,"R0_FINAL_RVF_vs_pRV_nonassessable_807.csv")
OUT_SUMMARY <- file.path(RES,"R0_FINAL_RVF_vs_pRV_summary.csv")
OUT_GATE <- file.path(RES,"R0_EXACT_R0_PRIMARY_RESULTS_FROZEN.txt")
LOG <- file.path(LOGDIR,"R0_STEP3D_final_freeze_v4_LOCAL_RUN.log")

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
twrite <- function(x,p) {
  t <- paste0(p,".tmp_",Sys.getpid())
  writeLines(x,t,useBytes=TRUE)
  if(!file.rename(t,p)) {unlink(t); stop("Atomic text failed: ",p)}
}

logline("============================================================")
logline("Exact R0 Step 3D — FINAL primary-results freeze")
logline("NO statistical recomputation.")
logline("============================================================")

must(file.exists(IN_LEDGER),"Missing Step-3C full ledger")
must(file.exists(STEP3C_GATE),"Missing Step-3C PASS gate")

if (file.exists(OUT_GATE) &&
    file.exists(OUT_ALL) &&
    file.exists(OUT_ASSESS) &&
    file.exists(OUT_SIG) &&
    file.exists(OUT_NONASSESS) &&
    file.exists(OUT_SUMMARY)) {
  logline("FINAL_GATE: R0_EXACT_R0_PRIMARY_RESULTS_ALREADY_FROZEN__NO_RERUN")
  quit(save="no",status=0,runLast=FALSE)
}

x <- read.csv(IN_LEDGER,stringsAsFactors=FALSE,check.names=FALSE)
must(nrow(x)==19428L,"Expected 19,428 filtered genes")
must(anyDuplicated(x$gene_id)==0L,"Duplicate gene IDs in Step-3C ledger")

req <- c(
  "gene_id","betaConv","primary_inference_status",
  "raw_default_baseMean","raw_default_log2FoldChange",
  "raw_default_lfcSE","raw_default_stat","raw_default_pvalue","raw_default_padj",
  "primary_baseMean","primary_log2FoldChange","primary_lfcSE","primary_stat",
  "primary_pvalue","primary_padj","primary_FDR_lt_0_05",
  "ashr_log2FoldChange","ashr_lfcSE","ashr_effect_status"
)
must(all(req %in% names(x)),"Step-3C ledger schema missing required columns")

bc <- as.logical(x$betaConv)
sigflag <- as.logical(x$primary_FDR_lt_0_05)
must(sum(bc,na.rm=TRUE)==18621L && sum(!bc,na.rm=TRUE)==807L && sum(is.na(bc))==0L,
     "Assessable/nonassessable counts changed")
must(sum(sigflag,na.rm=TRUE)==330L && sum(is.na(sigflag))==0L,
     "Frozen FDR discovery count changed")

# Hard integrity rules.
must(all(x$primary_inference_status[bc]=="ASSESSABLE_DEFAULT_FIT_CONVERGED"),
     "Assessable inference status changed")
must(all(x$primary_inference_status[!bc]=="NOT_ASSESSABLE_NUMERICAL_NONCONVERGENCE"),
     "Nonassessable inference status changed")
must(all(is.na(x$primary_pvalue[!bc])) && all(is.na(x$primary_padj[!bc])),
     "Nonassessable rows unexpectedly contain primary inference values")
must(!any(sigflag[!bc]),"Nonassessable rows cannot be primary discoveries")
must(all(is.finite(x$ashr_log2FoldChange[bc])) && all(is.finite(x$ashr_lfcSE[bc])),
     "ASHR effect missing in assessable universe")
must(all(is.na(x$ashr_log2FoldChange[!bc])) && all(is.na(x$ashr_lfcSE[!bc])),
     "Nonassessable rows unexpectedly contain ASHR effect values")

# No sign disagreement between unshrunk and ASHR among assessable genes.
disc <- bc &
        is.finite(x$primary_log2FoldChange) &
        is.finite(x$ashr_log2FoldChange) &
        sign(x$primary_log2FoldChange)!=0 &
        sign(x$ashr_log2FoldChange)!=0 &
        sign(x$primary_log2FoldChange)!=sign(x$ashr_log2FoldChange)
must(sum(disc)==0L,"Unexpected unshrunk/ASHR sign discordance")

# Clean all-filtered ledger: preserves both raw default output and primary authority.
all_final <- data.frame(
  gene_id=x$gene_id,
  assessable=bc,
  inference_status=x$primary_inference_status,
  baseMean=x$primary_baseMean,
  log2FoldChange=x$primary_log2FoldChange,
  lfcSE=x$primary_lfcSE,
  stat=x$primary_stat,
  pvalue=x$primary_pvalue,
  padj=x$primary_padj,
  ashr_log2FoldChange=x$ashr_log2FoldChange,
  ashr_lfcSE=x$ashr_lfcSE,
  primary_FDR_lt_0_05=sigflag,
  raw_default_log2FoldChange=x$raw_default_log2FoldChange,
  raw_default_pvalue=x$raw_default_pvalue,
  raw_default_padj=x$raw_default_padj,
  stringsAsFactors=FALSE
)

assess <- all_final[all_final$assessable,,drop=FALSE]
must(nrow(assess)==18621L,"Assessable table row count changed")
must(all(is.finite(assess$pvalue)),"Assessable p-values must all be finite")

assess$direction <- ifelse(
  assess$ashr_log2FoldChange>0,"UP_RVF_vs_pRV",
  ifelse(assess$ashr_log2FoldChange<0,"DOWN_RVF_vs_pRV","ZERO")
)

# Rank only for presentation; significance is already frozen by Step 3B.
assess$FDR_rank <- NA_integer_
finite_padj <- which(is.finite(assess$padj))
assess$FDR_rank[finite_padj] <- rank(
  assess$padj[finite_padj],
  ties.method="min"
)

sig <- assess[assess$primary_FDR_lt_0_05,,drop=FALSE]
sig <- sig[order(sig$padj,-abs(sig$ashr_log2FoldChange),sig$gene_id),,drop=FALSE]
must(nrow(sig)==330L,"Significant table must contain exactly 330 genes")
must(sum(sig$direction=="UP_RVF_vs_pRV")==314L,"Expected 314 upregulated discoveries")
must(sum(sig$direction=="DOWN_RVF_vs_pRV")==16L,"Expected 16 downregulated discoveries")
must(sum(sig$direction=="ZERO")==0L,"No significant zero-direction genes expected")

nonassess <- data.frame(
  gene_id=x$gene_id[!bc],
  inference_status=x$primary_inference_status[!bc],
  raw_default_baseMean=x$raw_default_baseMean[!bc],
  raw_default_log2FoldChange=x$raw_default_log2FoldChange[!bc],
  raw_default_lfcSE=x$raw_default_lfcSE[!bc],
  raw_default_stat=x$raw_default_stat[!bc],
  raw_default_pvalue=x$raw_default_pvalue[!bc],
  raw_default_padj=x$raw_default_padj[!bc],
  exclusion_reason="DEFAULT_FIT_BETA_NONCONVERGENCE",
  stringsAsFactors=FALSE
)
must(nrow(nonassess)==807L,"Nonassessable audit table must contain exactly 807 genes")

summary <- data.frame(
  metric=c(
    "filtered_genes_total",
    "primary_assessable_genes",
    "primary_nonassessable_beta_nonconverged",
    "assessable_finite_pvalue",
    "assessable_finite_padj",
    "primary_FDR_lt_0_05",
    "primary_FDR_lt_0_05_up",
    "primary_FDR_lt_0_05_down",
    "primary_FDR_lt_0_05_zero",
    "ashr_finite_effect_assessable",
    "ashr_sign_discordance_assessable",
    "maxit1000_used_as_primary",
    "new_statistical_computation_in_step3D"
  ),
  value=c(
    nrow(all_final),
    nrow(assess),
    nrow(nonassess),
    sum(is.finite(assess$pvalue)),
    sum(is.finite(assess$padj)),
    nrow(sig),
    sum(sig$direction=="UP_RVF_vs_pRV"),
    sum(sig$direction=="DOWN_RVF_vs_pRV"),
    sum(sig$direction=="ZERO"),
    sum(is.finite(assess$ashr_log2FoldChange) & is.finite(assess$ashr_lfcSE)),
    sum(disc),
    0,
    0
  ),
  stringsAsFactors=FALSE
)

awrite(all_final,OUT_ALL)
awrite(assess,OUT_ASSESS)
awrite(sig,OUT_SIG)
awrite(nonassess,OUT_NONASSESS)
awrite(summary,OUT_SUMMARY)

twrite(c(
  "R0_EXACT_R0_PRIMARY_RESULTS_FROZEN",
  paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
  "dataset=GSE345645",
  "analysis=adult_RV_bulk_RNAseq",
  "primary_fit=DEFAULT_AUTHOR_MODEL",
  "design=category_plus_SV1_to_SV21",
  "contrast=RVF_vs_pRV",
  "author_filter=normalized_count_ge5_in_ge3_samples",
  "filtered_genes=19428",
  "primary_assessable_rule=default_betaConv_TRUE",
  "primary_assessable_genes=18621",
  "primary_nonassessable_genes=807",
  "nonassessable_reason=NUMERICAL_BETA_NONCONVERGENCE",
  "primary_pvalue_authority=UNSHRUNKEN_WALD",
  "primary_FDR_authority=DESEQ2_INDEPENDENT_FILTERING_PLUS_BH_ON_ASSESSABLE_UNIVERSE",
  "primary_FDR_alpha=0.05",
  "primary_FDR_discoveries=330",
  "primary_FDR_up=314",
  "primary_FDR_down=16",
  "ashr_role=EFFECT_SIZE_VISUALIZATION_AND_RANKING_ONLY",
  "ashr_assessable_genes_with_finite_effect=18621",
  "ashr_sign_discordance=0",
  "maxit1000_primary_use=NO",
  "step3D_statistical_recomputation=NO",
  "R0_primary_results_status=FINAL_FROZEN",
  "next_stage=R1_CROSS_COHORT_REPLICATION_GSE240921_AFTER_CHATGPT_AUDIT"
),OUT_GATE)

logline("Frozen assessable genes=",nrow(assess))
logline("Frozen FDR discoveries=",nrow(sig),
        " (up=",sum(sig$direction=="UP_RVF_vs_pRV"),
        "; down=",sum(sig$direction=="DOWN_RVF_vs_pRV"),")")
logline("FINAL_GATE: R0_EXACT_R0_PRIMARY_RESULTS_FROZEN")
quit(save="no",status=0,runLast=FALSE)
