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
# RV Project — R1 GSE240921 Step 3C
# SEX-ADJUSTED SENSITIVITY MODEL
#
# Frozen primary result:
#   25 strict replicated genes from Step 3A
#
# Sensitivity model frozen before outcome inspection:
#   ~ technical_batch + sex + clinical_state
# contrast:
#   DECOMPENSATED vs COMPENSATED
#
# IMPORTANT:
#   - primary 25-gene result is NOT recomputed or replaced
#   - same frozen 330-candidate family
#   - same 74 primary-unassessable candidates stay padded p=1
#   - among the 256 primary-assessable candidates, any sensitivity-model
#     nonconvergence/nonfinite Wald p is additionally padded p=1
#   - sensitivity BH is across exactly 330 candidates
#   - no ASHR in this step
# ==============================================================================

options(stringsAsFactors=FALSE, warn=1)

ROOT <- normalizePath(getwd(), winslash="/", mustWork=TRUE)
if (!identical(ROOT,RV_PROJECT_ROOT)) stop("Expected D:/RV_project")

user_lib <- file.path(Sys.getenv("LOCALAPPDATA"),"R","win-library","4.6")
if (dir.exists(user_lib)) .libPaths(unique(c(user_lib,.libPaths())))

suppressPackageStartupMessages(library(DESeq2))

RES <- file.path(ROOT,"results","R1_GSE240921")
LOGDIR <- file.path(ROOT,"logs")
dir.create(LOGDIR,recursive=TRUE,showWarnings=FALSE)

CONTRACT <- file.path(RES,"R1_GSE240921_MODEL_CONTRACT_FROZEN.txt")
STEP3A_GATE <- file.path(RES,"R1_GSE240921_STEP3A_PRIMARY_REPLICATION_PASS.txt")
STEP3B_GATE <- file.path(RES,"R1_GSE240921_STEP3B_ASHR_EFFECT_SIZE_PASS.txt")
PRIMARY_DDS <- file.path(RES,"R1_GSE240921_primary_fitted_dds.rds")
PRIMARY_LEDGER <- file.path(RES,"R1_GSE240921_R0_330_primary_replication_ledger.csv")

SENS_DDS <- file.path(RES,"R1_GSE240921_sex_sensitivity_fitted_dds.rds")
OUT_LEDGER <- file.path(RES,"R1_GSE240921_R0_330_sex_sensitivity_ledger.csv")
OUT_P25 <- file.path(RES,"R1_GSE240921_PRIMARY25_sex_sensitivity.csv")
OUT_SUM <- file.path(RES,"R1_GSE240921_step3C_sex_sensitivity_summary.csv")
OUT_WARN <- file.path(RES,"R1_GSE240921_step3C_sex_sensitivity_warnings.txt")
OUT_GATE <- file.path(RES,"R1_GSE240921_STEP3C_SEX_SENSITIVITY_PASS.txt")
LOG <- file.path(LOGDIR,"R1_GSE240921_STEP3C_SEX_SENSITIVITY.log")

if (file.exists(LOG)) {
  old <- file.path(
    LOGDIR,
    paste0("R1_GSE240921_STEP3C_SEX_SENSITIVITY_",
           format(Sys.time(),"%Y%m%d_%H%M%S"),"_previous.log")
  )
  file.rename(LOG,old)
}

logline <- function(...) {
  z <- paste0(format(Sys.time(),"%Y-%m-%d %H:%M:%S")," | ",paste0(...,collapse=""))
  cat(z,"\n",sep="")
  cat(z,"\n",file=LOG,append=TRUE,sep="")
  flush.console()
}
must <- function(x,msg) if(!isTRUE(x)) stop(msg,call.=FALSE)
asave <- function(x,p) {
  t <- paste0(p,".tmp_",Sys.getpid())
  saveRDS(x,t,compress=TRUE)
  if(!file.rename(t,p)) {unlink(t); stop("Atomic RDS save failed: ",p)}
}
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
logline("R1 GSE240921 Step 3C — sex-adjusted sensitivity")
logline("============================================================")

# Re-entry protection.
if (file.exists(OUT_GATE) && file.exists(OUT_LEDGER) && file.exists(OUT_P25)) {
  logline("FINAL_GATE: R1_GSE240921_STEP3C_SEX_SENSITIVITY_ALREADY_PASS__NO_RERUN")
  quit(save="no",status=0,runLast=FALSE)
}
if (file.exists(SENS_DDS) && !file.exists(OUT_GATE)) {
  stop("Sensitivity fitted checkpoint exists without PASS gate. Refusing to overwrite/rerun.")
}

# Frozen authorities.
must(file.exists(CONTRACT),"Missing frozen model contract")
must(file.exists(STEP3A_GATE),"Missing Step3A primary replication PASS")
must(file.exists(STEP3B_GATE),"Missing Step3B ASHR PASS")
must(file.exists(PRIMARY_DDS),"Missing primary fitted DDS")
must(file.exists(PRIMARY_LEDGER),"Missing frozen 330 primary ledger")

ct <- readLines(CONTRACT,warn=FALSE)
g3a <- readLines(STEP3A_GATE,warn=FALSE)
g3b <- readLines(STEP3B_GATE,warn=FALSE)

must(ct[1]=="R1_GSE240921_MODEL_CONTRACT_FROZEN","Unexpected model contract")
must(g3a[1]=="R1_GSE240921_STEP3A_PRIMARY_REPLICATION_PASS","Unexpected Step3A gate")
must(g3b[1]=="R1_GSE240921_STEP3B_ASHR_EFFECT_SIZE_PASS","Unexpected Step3B gate")
must(any(ct=="sensitivity_model=~ technical_batch + sex + clinical_state"),
     "Frozen sensitivity model changed")
must(any(ct=="sensitivity_model_full_rank=YES"),
     "Frozen sensitivity design was not full rank")
must(any(g3a=="primary_replicated=25"),
     "Frozen primary replicated set is not 25")
must(any(g3a=="primary_assessable=256"),
     "Frozen primary assessable set is not 256")
must(any(g3b=="primary_replicated_set=FROZEN_25_UNCHANGED"),
     "Step3B did not preserve primary 25")

# Load primary fitted object only as count/metadata authority.
pdds <- readRDS(PRIMARY_DDS)
must(inherits(pdds,"DESeqDataSet"),"Primary fitted object invalid")
must(nrow(pdds)==48738L && ncol(pdds)==40L,"Primary DDS dimensions changed")

cd <- as.data.frame(SummarizedExperiment::colData(pdds))
must(all(c("technical_batch","clinical_state","sex") %in% names(cd)),
     "Required sensitivity covariates missing")

cd$technical_batch <- factor(
  as.character(cd$technical_batch),
  levels=c("BATCH1_PRAKASH_SINGLE_END","BATCH2_US_PAIRED_END")
)
cd$clinical_state <- factor(
  as.character(cd$clinical_state),
  levels=c("COMPENSATED","NORMAL_CONTROL","DECOMPENSATED")
)
cd$sex <- factor(as.character(cd$sex),levels=c("F","M"))

must(sum(is.na(cd$technical_batch))==0L,"Unexpected batch values")
must(sum(is.na(cd$clinical_state))==0L,"Unexpected clinical-state values")
must(sum(is.na(cd$sex))==0L,"Unexpected/missing sex values")

X <- model.matrix(~ technical_batch + sex + clinical_state,data=cd)
must(nrow(X)==40L && ncol(X)==5L && qr(X)$rank==5L,
     "Sensitivity design matrix is not 40x5 full rank")

# Build a clean sensitivity DDS from the same exact raw counts.
raw_counts <- DESeq2::counts(pdds,normalized=FALSE)
must(nrow(raw_counts)==48738L && ncol(raw_counts)==40L,"Raw count dimensions changed")
must(all(raw_counts>=0),"Negative raw counts detected")

sdds <- DESeq2::DESeqDataSetFromMatrix(
  countData=raw_counts,
  colData=cd,
  design=~ technical_batch + sex + clinical_state
)

# Exactly one sensitivity fit.
warnings_seen <- character()
fit_error <- NULL
logline("[INFO] Starting one sex-adjusted DESeq2 sensitivity fit.")
t0 <- Sys.time()

sfit <- tryCatch(
  withCallingHandlers(
    DESeq2::DESeq(sdds),
    warning=function(w) {
      warnings_seen <<- c(warnings_seen,conditionMessage(w))
      logline("[R WARNING] ",conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  ),
  error=function(e) {
    fit_error <<- conditionMessage(e)
    NULL
  }
)

runtime <- as.numeric(difftime(Sys.time(),t0,units="secs"))

if (is.null(sfit)) {
  twrite(c(
    "R1_GSE240921_STEP3C_SEX_SENSITIVITY_HOLD_ERROR",
    paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
    paste0("error=",fit_error),
    paste0("runtime_seconds=",runtime),
    "automatic_rerun=NO"
  ),file.path(RES,"R1_GSE240921_STEP3C_SEX_SENSITIVITY_HOLD.txt"))
  twrite(c(paste0("warning_count=",length(warnings_seen)),warnings_seen),OUT_WARN)
  logline("FINAL_GATE: R1_GSE240921_STEP3C_SEX_SENSITIVITY_HOLD_ERROR")
  quit(save="no",status=51,runLast=FALSE)
}

asave(sfit,SENS_DDS)
logline("[INFO] Sensitivity fit saved.")

coef_name <- "clinical_state_DECOMPENSATED_vs_COMPENSATED"
must(coef_name %in% DESeq2::resultsNames(sfit),
     "Direct sensitivity coefficient absent")

smc <- as.data.frame(S4Vectors::mcols(sfit))
must("betaConv" %in% names(smc),"Sensitivity fit lacks betaConv")
sbc <- as.logical(smc$betaConv)

# One unshrunk Wald extraction; no independent filtering because the
# candidate family is externally frozen.
sres <- DESeq2::results(
  sfit,
  name=coef_name,
  independentFiltering=FALSE
)
sr <- as.data.frame(sres)

must(nrow(sr)==48738L && identical(rownames(sr),rownames(sfit)),
     "Sensitivity result row identity changed")

# Frozen primary candidate ledger.
led <- read.csv(PRIMARY_LEDGER,stringsAsFactors=FALSE,check.names=FALSE)
must(nrow(led)==330L,"Primary candidate ledger is not 330 rows")
must(sum(as.logical(led$primary_replicated))==25L,
     "Primary replicated set changed")
must(sum(led$primary_assessability=="ASSESSABLE_WALD_FINITE")==256L,
     "Primary assessable set changed")
must(sum(led$primary_assessability=="LOW_EXPRESSION_PAD_P1")==70L,
     "Primary low-expression set changed")
must(sum(led$primary_assessability=="UNMAPPED_PAD_P1")==4L,
     "Primary unmapped set changed")

out <- led
out$sensitivity_baseMean <- NA_real_
out$sensitivity_log2FC <- NA_real_
out$sensitivity_lfcSE <- NA_real_
out$sensitivity_stat <- NA_real_
out$sensitivity_pvalue <- NA_real_
out$sensitivity_betaConv <- NA
out$sensitivity_status <- "PRIMARY_UNASSESSABLE_PAD_P1"
out$sensitivity_p_for_BH330 <- 1
out$sensitivity_BH_FDR_330 <- NA_real_
out$sensitivity_direction_concordant_with_R0 <- FALSE
out$sensitivity_strict_replicated <- FALSE

mapped <- which(out$mapping_status=="UNIQUE_MAPPED")
mi <- match(out$gse240921_gene_id[mapped],rownames(sfit))
must(all(!is.na(mi)),"A mapped candidate disappeared in sensitivity fit")

out$sensitivity_baseMean[mapped] <- as.numeric(sr$baseMean[mi])
out$sensitivity_log2FC[mapped] <- as.numeric(sr$log2FoldChange[mi])
out$sensitivity_lfcSE[mapped] <- as.numeric(sr$lfcSE[mi])
out$sensitivity_stat[mapped] <- as.numeric(sr$stat[mi])
out$sensitivity_pvalue[mapped] <- as.numeric(sr$pvalue[mi])
out$sensitivity_betaConv[mapped] <- sbc[mi]

# The 256 primary-assessable candidates are the fixed sensitivity analysis set.
eligible <- which(out$primary_assessability=="ASSESSABLE_WALD_FINITE")
must(length(eligible)==256L,"Sensitivity eligible set is not 256")

for(i in eligible) {
  if(is.na(out$sensitivity_betaConv[i])) {
    out$sensitivity_status[i] <- "SENS_BETA_CONV_NA_PAD_P1"
  } else if(!out$sensitivity_betaConv[i]) {
    out$sensitivity_status[i] <- "SENS_BETA_NONCONVERGED_PAD_P1"
  } else if(!is.finite(out$sensitivity_pvalue[i])) {
    out$sensitivity_status[i] <- "SENS_WALD_P_NONFINITE_PAD_P1"
  } else {
    out$sensitivity_status[i] <- "SENS_ASSESSABLE_WALD_FINITE"
    out$sensitivity_p_for_BH330[i] <- out$sensitivity_pvalue[i]
  }
}

sens_assess <- which(out$sensitivity_status=="SENS_ASSESSABLE_WALD_FINITE")

must(length(out$sensitivity_p_for_BH330)==330L,
     "Sensitivity BH vector is not 330")
must(all(is.finite(out$sensitivity_p_for_BH330)),
     "Sensitivity BH vector contains nonfinite values")
must(all(out$sensitivity_p_for_BH330>=0 & out$sensitivity_p_for_BH330<=1),
     "Sensitivity BH vector outside [0,1]")

out$sensitivity_BH_FDR_330 <- stats::p.adjust(
  out$sensitivity_p_for_BH330,
  method="BH"
)

out$sensitivity_direction_concordant_with_R0[sens_assess] <- (
  sign(out$r0_log2FC[sens_assess]) != 0 &
  sign(out$sensitivity_log2FC[sens_assess]) != 0 &
  sign(out$r0_log2FC[sens_assess]) ==
    sign(out$sensitivity_log2FC[sens_assess])
)

out$sensitivity_strict_replicated <- (
  out$sensitivity_status=="SENS_ASSESSABLE_WALD_FINITE" &
  out$sensitivity_direction_concordant_with_R0 &
  out$sensitivity_BH_FDR_330 < 0.05
)

# Primary 25 must remain immutable.
p25 <- which(as.logical(out$primary_replicated))
must(length(p25)==25L,"Primary replicated set is not 25")

out$primary_vs_sensitivity_LFC_delta <- NA_real_
out$primary_vs_sensitivity_LFC_delta[sens_assess] <- (
  out$sensitivity_log2FC[sens_assess] -
  out$gse240921_log2FC[sens_assess]
)

p25_tab <- out[p25,,drop=FALSE]
p25_tab$primary25_sensitivity_same_sign <- (
  is.finite(p25_tab$sensitivity_log2FC) &
  sign(p25_tab$gse240921_log2FC)==sign(p25_tab$sensitivity_log2FC)
)
p25_tab$primary25_sensitivity_nominal_p_lt_0_05 <- (
  is.finite(p25_tab$sensitivity_pvalue) &
  p25_tab$sensitivity_pvalue<0.05
)
p25_tab$primary25_sensitivity_strict_FDR_support <- (
  p25_tab$sensitivity_strict_replicated
)

# Correlations are descriptive robustness metrics.
cor256_pearson <- if(length(sens_assess)>=3L) {
  cor(out$gse240921_log2FC[sens_assess],
      out$sensitivity_log2FC[sens_assess],
      method="pearson")
} else NA_real_

cor256_spearman <- if(length(sens_assess)>=3L) {
  cor(out$gse240921_log2FC[sens_assess],
      out$sensitivity_log2FC[sens_assess],
      method="spearman")
} else NA_real_

cor25_pearson <- cor(
  p25_tab$gse240921_log2FC,
  p25_tab$sensitivity_log2FC,
  method="pearson",
  use="complete.obs"
)

max_abs_delta25 <- max(
  abs(p25_tab$sensitivity_log2FC-p25_tab$gse240921_log2FC),
  na.rm=TRUE
)

awrite(out,OUT_LEDGER)
awrite(p25_tab,OUT_P25)

summary <- data.frame(
  metric=c(
    "sensitivity_model",
    "sensitivity_design_rank",
    "sensitivity_design_columns",
    "sensitivity_all_genes_betaConv_FALSE",
    "sensitivity_all_genes_betaConv_NA",
    "frozen_primary_candidate_family",
    "frozen_primary_assessable_candidates",
    "sensitivity_assessable_of_primary256",
    "sensitivity_beta_nonconverged_of_primary256",
    "sensitivity_betaConv_NA_of_primary256",
    "sensitivity_Wald_p_nonfinite_of_primary256",
    "sensitivity_direction_concordant_with_R0",
    "sensitivity_strict_replicated_BH330_plus_direction",
    "PRIMARY25_sensitivity_same_sign",
    "PRIMARY25_sensitivity_nominal_p_lt_0_05",
    "PRIMARY25_sensitivity_strict_FDR_support",
    "primary_vs_sensitivity_LFC_pearson_256",
    "primary_vs_sensitivity_LFC_spearman_256",
    "primary_vs_sensitivity_LFC_pearson_primary25",
    "PRIMARY25_max_abs_LFC_delta",
    "warning_count",
    "runtime_seconds",
    "primary25_set_modified",
    "ASHR_executed_in_step3C"
  ),
  value=c(
    "~ technical_batch + sex + clinical_state",
    qr(X)$rank,ncol(X),
    sum(sbc %in% FALSE,na.rm=TRUE),
    sum(is.na(sbc)),
    330,
    256,
    length(sens_assess),
    sum(out$sensitivity_status=="SENS_BETA_NONCONVERGED_PAD_P1"),
    sum(out$sensitivity_status=="SENS_BETA_CONV_NA_PAD_P1"),
    sum(out$sensitivity_status=="SENS_WALD_P_NONFINITE_PAD_P1"),
    sum(out$sensitivity_direction_concordant_with_R0),
    sum(out$sensitivity_strict_replicated),
    sum(p25_tab$primary25_sensitivity_same_sign),
    sum(p25_tab$primary25_sensitivity_nominal_p_lt_0_05),
    sum(p25_tab$primary25_sensitivity_strict_FDR_support),
    cor256_pearson,
    cor256_spearman,
    cor25_pearson,
    max_abs_delta25,
    length(warnings_seen),
    runtime,
    "NO",
    "NO"
  ),
  stringsAsFactors=FALSE
)
awrite(summary,OUT_SUM)
twrite(c(paste0("warning_count=",length(warnings_seen)),warnings_seen),OUT_WARN)

twrite(c(
  "R1_GSE240921_STEP3C_SEX_SENSITIVITY_PASS",
  paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
  "primary_result=FROZEN_25_UNCHANGED",
  "sensitivity_model=~ technical_batch + sex + clinical_state",
  "sensitivity_contrast=DECOMPENSATED_vs_COMPENSATED",
  "sensitivity_candidate_family=FULL_330_PADDED",
  "sensitivity_eligible_set=FROZEN_PRIMARY_ASSESSABLE_256",
  paste0("sensitivity_assessable=",length(sens_assess)),
  paste0("sensitivity_strict_replicated=",sum(out$sensitivity_strict_replicated)),
  paste0("PRIMARY25_same_sign=",sum(p25_tab$primary25_sensitivity_same_sign)),
  paste0("PRIMARY25_nominal_p_lt_0.05=",
         sum(p25_tab$primary25_sensitivity_nominal_p_lt_0_05)),
  paste0("PRIMARY25_strict_FDR_support=",
         sum(p25_tab$primary25_sensitivity_strict_FDR_support)),
  paste0("LFC_pearson_primary256=",cor256_pearson),
  paste0("LFC_spearman_primary256=",cor256_spearman),
  paste0("LFC_pearson_PRIMARY25=",cor25_pearson),
  "primary25_set_modified=NO",
  "ASHR_executed=NO",
  "automatic_rerun=NO",
  "next_stage=ChatGPT audit then GSE240921 R1 terminal freeze"
),OUT_GATE)

logline("Sensitivity assessable=",length(sens_assess),"/256")
logline("Sensitivity strict replicated=",sum(out$sensitivity_strict_replicated))
logline("Primary25 same sign=",sum(p25_tab$primary25_sensitivity_same_sign),"/25")
logline("Primary25 nominal p<0.05=",
        sum(p25_tab$primary25_sensitivity_nominal_p_lt_0_05),"/25")
logline("Primary25 strict FDR support=",
        sum(p25_tab$primary25_sensitivity_strict_FDR_support),"/25")
logline("FINAL_GATE: R1_GSE240921_STEP3C_SEX_SENSITIVITY_PASS")
quit(save="no",status=0,runLast=FALSE)
