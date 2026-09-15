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
# RV Project — Exact R0 Step 2C
# Wald beta-convergence numerical repair
#
# INPUT AUTHORITY:
#   R0_fitted_dds.rds  (default DESeq2 fit; 807 betaConv=FALSE)
#
# ACTION:
#   nbinomWaldTest(maxit=1000) ONLY
#
# IMPORTANT:
#   - does NOT rerun DESeq()
#   - does NOT re-estimate size factors
#   - does NOT re-estimate dispersions
#   - does NOT overwrite the original fitted DDS
#   - does NOT run results(), lfcShrink(), PCA, GSEA
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

ORIG <- file.path(RES,"R0_fitted_dds.rds")
STEP2_HOLD <- file.path(RES,"R0_EXACT_MODEL_FIT_HOLD.txt")
STEP2B_GATE <- file.path(RES,"R0_STEP2B_BETA_DIAGNOSTIC_PASS.txt")

REPAIRED <- file.path(RES,"R0_fitted_dds_maxit1000.rds")
AUDIT <- file.path(RES,"R0_exact_step2C_maxit1000_audit.csv")
WARN <- file.path(RES,"R0_exact_step2C_maxit1000_warnings.txt")
PASS <- file.path(RES,"R0_EXACT_MODEL_FIT_MAXIT1000_PASS.txt")
HOLD <- file.path(RES,"R0_EXACT_MODEL_FIT_MAXIT1000_HOLD.txt")
LOG <- file.path(LOGDIR,"R0_STEP2C_maxit1000_v4_LOCAL_RUN.log")

if (file.exists(LOG)) {
  old <- file.path(LOGDIR,paste0("R0_STEP2C_maxit1000_",format(Sys.time(),"%Y%m%d_%H%M%S"),"_previous.log"))
  file.rename(LOG,old)
}

logline <- function(...) {
  z <- paste0(format(Sys.time(),"%Y-%m-%d %H:%M:%S")," | ",paste0(...,collapse=""))
  cat(z,"\n",sep="")
  cat(z,"\n",file=LOG,append=TRUE,sep="")
  flush.console()
}
must <- function(x,msg) if (!isTRUE(x)) stop(msg,call.=FALSE)
asave <- function(x,p) {
  t <- paste0(p,".tmp_",Sys.getpid())
  saveRDS(x,t,compress=TRUE)
  if (!file.rename(t,p)) {unlink(t); stop("Atomic save failed: ",p)}
}
acsv <- function(x,p) {
  t <- paste0(p,".tmp_",Sys.getpid())
  write.csv(x,t,row.names=FALSE,na="")
  if (!file.rename(t,p)) {unlink(t); stop("Atomic CSV failed: ",p)}
}
alines <- function(x,p) {
  t <- paste0(p,".tmp_",Sys.getpid())
  writeLines(x,t,useBytes=TRUE)
  if (!file.rename(t,p)) {unlink(t); stop("Atomic text failed: ",p)}
}

logline("============================================================")
logline("Exact R0 Step 2C — nbinomWaldTest(maxit=1000) numerical repair")
logline("Original fitted DDS will NOT be overwritten.")
logline("============================================================")

must(file.exists(ORIG),"Missing original fitted DDS")
must(file.exists(STEP2_HOLD),"Missing Step-2 beta-convergence HOLD")
must(file.exists(STEP2B_GATE),"Missing Step-2B diagnostic PASS")

if (file.exists(REPAIRED)) {
  if (file.exists(PASS)) {
    logline("FINAL_GATE: R0_EXACT_MODEL_FIT_MAXIT1000_ALREADY_PASS__NO_RERUN")
    quit(save="no",status=0,runLast=FALSE)
  }
  if (file.exists(HOLD)) {
    logline("FINAL_GATE: R0_EXACT_MODEL_FIT_MAXIT1000_ALREADY_HOLD__NO_RERUN")
    quit(save="no",status=22,runLast=FALSE)
  }
  stop("Repaired checkpoint exists without recognized gate; refusing overwrite.")
}

dds0 <- readRDS(ORIG)
must(inherits(dds0,"DESeqDataSet"),"Original fitted object invalid")
must(nrow(dds0)==19428L && ncol(dds0)==142L,"Unexpected original fitted dimensions")
mc0 <- as.data.frame(S4Vectors::mcols(dds0))
must("betaConv" %in% names(mc0),"Original betaConv missing")
bc0 <- as.logical(mc0$betaConv)
must(sum(!bc0)==807L && sum(is.na(bc0))==0L,"Expected original 807 beta failures")

# Save old result-like columns for stability check of rows that already converged.
coef_cols <- grep("^(Intercept$|category_|SV[0-9]+$)",names(mc0),value=TRUE)
se_cols <- grep("^SE_",names(mc0),value=TRUE)
stat_cols <- grep("^WaldStatistic_",names(mc0),value=TRUE)
p_cols <- grep("^WaldPvalue_",names(mc0),value=TRUE)

track_cols <- unique(c(coef_cols,se_cols,stat_cols,p_cols))
must(length(track_cols)>0L,"Could not identify stored Wald result columns")

old_track <- as.matrix(mc0[bc0,track_cols,drop=FALSE])
storage.mode(old_track) <- "double"

warnings_seen <- character()
logline("Starting nbinomWaldTest(maxit=1000) using existing normalization and dispersions...")
t0 <- Sys.time()

dds1 <- withCallingHandlers(
  DESeq2::nbinomWaldTest(dds0,maxit=1000),
  warning=function(w) {
    warnings_seen <<- c(warnings_seen,conditionMessage(w))
    logline("[R WARNING] ",conditionMessage(w))
    invokeRestart("muffleWarning")
  }
)

secs <- as.numeric(difftime(Sys.time(),t0,units="secs"))
logline("nbinomWaldTest returned. Saving repaired checkpoint immediately...")
asave(dds1,REPAIRED)
logline("Saved: ",REPAIRED)

mc1 <- as.data.frame(S4Vectors::mcols(dds1))
must("betaConv" %in% names(mc1),"Repaired betaConv missing")
bc1 <- as.logical(mc1$betaConv)

new_fail <- sum(!bc1,na.rm=TRUE)
new_na <- sum(is.na(bc1))
rescued <- sum(!bc0 & bc1,na.rm=TRUE)

# Check that rows already converged under default maxit are numerically stable.
must(all(track_cols %in% names(mc1)),"Tracked Wald columns changed schema")
new_track <- as.matrix(mc1[bc0,track_cols,drop=FALSE])
storage.mode(new_track) <- "double"

d <- abs(new_track-old_track)
finite_d <- d[is.finite(d)]
max_abs_change <- if(length(finite_d)) max(finite_d) else NA_real_
mean_abs_change <- if(length(finite_d)) mean(finite_d) else NA_real_

stable_pass <- is.finite(max_abs_change) && max_abs_change <= 1e-6

audit <- data.frame(
  metric=c(
    "original_genes",
    "original_beta_nonconverged",
    "maxit1000_beta_nonconverged",
    "maxit1000_betaConv_NA",
    "rescued_from_original_807",
    "originally_converged_rows_checked",
    "tracked_wald_columns",
    "max_abs_change_originally_converged_rows",
    "mean_abs_change_originally_converged_rows",
    "fit_runtime_seconds",
    "warning_count"
  ),
  value=c(
    nrow(dds0),
    sum(!bc0),
    new_fail,
    new_na,
    rescued,
    sum(bc0),
    length(track_cols),
    max_abs_change,
    mean_abs_change,
    secs,
    length(warnings_seen)
  ),
  status=c(
    "PASS","PASS",
    if(new_fail==0L) "PASS" else "HOLD",
    if(new_na==0L) "PASS" else "HOLD",
    "PASS","PASS","PASS",
    if(stable_pass) "PASS" else "HOLD",
    if(stable_pass) "PASS" else "HOLD",
    "PASS","PASS"
  ),
  stringsAsFactors=FALSE
)
acsv(audit,AUDIT)
alines(c(paste0("warning_count=",length(warnings_seen)),warnings_seen),WARN)

if (new_fail==0L && new_na==0L && stable_pass) {
  alines(c(
    "R0_EXACT_MODEL_FIT_MAXIT1000_PASS",
    paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
    "repair_scope=nbinomWaldTest_only",
    "maxit=1000",
    "size_factors_reestimated=NO",
    "dispersions_reestimated=NO",
    "original_fitted_dds_overwritten=NO",
    "downstream_results_executed=NO",
    paste0("original_beta_nonconverged=",sum(!bc0)),
    paste0("maxit1000_beta_nonconverged=",new_fail),
    paste0("rescued=",rescued),
    paste0("max_abs_change_original_converged=",format(max_abs_change,digits=12)),
    paste0("runtime_seconds=",secs),
    "next_stage=Step 3 only after ChatGPT audit"
  ),PASS)
  logline("FINAL_GATE: R0_EXACT_MODEL_FIT_MAXIT1000_PASS")
  logline("rescued=",rescued,"; remaining_nonconverged=",new_fail)
  logline("max abs change among original converged rows=",format(max_abs_change,digits=12))
  quit(save="no",status=0,runLast=FALSE)
}

alines(c(
  "R0_EXACT_MODEL_FIT_MAXIT1000_HOLD",
  paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
  "repair_scope=nbinomWaldTest_only",
  "maxit=1000",
  "original_fitted_dds_overwritten=NO",
  paste0("original_beta_nonconverged=",sum(!bc0)),
  paste0("maxit1000_beta_nonconverged=",new_fail),
  paste0("betaConv_NA=",new_na),
  paste0("rescued=",rescued),
  paste0("max_abs_change_original_converged=",format(max_abs_change,digits=12)),
  "next_action=Return outputs to ChatGPT; do not increase maxit again automatically"
),HOLD)

logline("FINAL_GATE: R0_EXACT_MODEL_FIT_MAXIT1000_HOLD")
logline("rescued=",rescued,"; remaining_nonconverged=",new_fail,"; betaConv_NA=",new_na)
logline("DO NOT increase maxit again automatically.")
quit(save="no",status=22,runLast=FALSE)
