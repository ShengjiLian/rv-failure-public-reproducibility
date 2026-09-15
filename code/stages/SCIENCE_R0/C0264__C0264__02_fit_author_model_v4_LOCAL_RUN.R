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
if (!identical(ROOT, RV_PROJECT_ROOT)) stop("Expected working directory D:/RV_project")

user_lib <- file.path(Sys.getenv("LOCALAPPDATA"), "R", "win-library", "4.6")
if (dir.exists(user_lib)) .libPaths(unique(c(user_lib, .libPaths())))
suppressPackageStartupMessages(library(DESeq2))

EXPECTED_R <- "4.6.1"
EXPECTED_BIOC <- "3.23"
EXPECTED_DESEQ2 <- "1.52.0"

RES <- file.path(ROOT, "results", "R0", "v4_LOCAL_RUN")
LOGDIR <- file.path(ROOT, "logs")
dir.create(LOGDIR, recursive=TRUE, showWarnings=FALSE)

STEP1_GATE <- file.path(RES, "R0_EXACT_TXIMPORT_PREP_PASS.txt")
PREFIT <- file.path(RES, "R0_prefit_dds.rds")
FITTED <- file.path(RES, "R0_fitted_dds.rds")
AUDIT_PATH <- file.path(RES, "R0_exact_step2_fit_audit.csv")
WARN_PATH <- file.path(RES, "R0_exact_step2_warnings.txt")
SESSION_PATH <- file.path(RES, "R0_exact_step2_sessionInfo.txt")
PASS_PATH <- file.path(RES, "R0_EXACT_MODEL_FIT_PASS.txt")
HOLD_PATH <- file.path(RES, "R0_EXACT_MODEL_FIT_HOLD.txt")
LOG <- file.path(LOGDIR, "R0_STEP2_v4_LOCAL_RUN.log")

if (file.exists(LOG)) {
  old <- file.path(LOGDIR, paste0("R0_STEP2_v4_LOCAL_RUN_", format(Sys.time(), "%Y%m%d_%H%M%S"), "_previous.log"))
  file.rename(LOG, old)
}

log_line <- function(...) {
  z <- paste0(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), " | ", paste0(..., collapse=""))
  cat(z, "\n", sep="")
  cat(z, "\n", file=LOG, append=TRUE, sep="")
  flush.console()
}
atomic_save <- function(x,p) {
  tmp <- paste0(p, ".tmp_", Sys.getpid())
  saveRDS(x,tmp,compress=TRUE)
  if (!file.rename(tmp,p)) {unlink(tmp); stop("Atomic save failed: ",p)}
}
atomic_lines <- function(x,p) {
  tmp <- paste0(p, ".tmp_", Sys.getpid())
  writeLines(x,tmp,useBytes=TRUE)
  if (!file.rename(tmp,p)) {unlink(tmp); stop("Atomic write failed: ",p)}
}
atomic_csv <- function(x,p) {
  tmp <- paste0(p, ".tmp_", Sys.getpid())
  write.csv(x,tmp,row.names=FALSE,na="")
  if (!file.rename(tmp,p)) {unlink(tmp); stop("Atomic CSV write failed: ",p)}
}
must <- function(x,msg) if (!isTRUE(x)) stop(msg,call.=FALSE)

AUD <- list()
add <- function(item,expected,observed,pass,notes="") {
  rr <- data.frame(item=as.character(item), expected=as.character(expected),
                   observed=as.character(observed),
                   status=if(isTRUE(pass)) "PASS" else "FAIL",
                   notes=as.character(notes), stringsAsFactors=FALSE)
  AUD[[length(AUD)+1L]] <<- rr
  log_line("[",rr$status,"] ",item," | expected=",expected," | observed=",observed)
}

log_line("============================================================")
log_line("GSE345645 Exact R0 Step 2 — v4_LOCAL_RUN")
log_line("ONE DESeq fit only -> immediate checkpoint -> betaConv audit -> STOP")
log_line("No downstream result extraction, shrinkage, PCA, tuning, or auto-rerun.")
log_line("============================================================")

rver <- paste(R.version$major,R.version$minor,sep=".")
bver <- if (requireNamespace("BiocManager",quietly=TRUE)) as.character(BiocManager::version()) else NA_character_
dver <- as.character(packageVersion("DESeq2"))
add("R version",EXPECTED_R,rver,identical(rver,EXPECTED_R))
add("Bioconductor version",EXPECTED_BIOC,bver,identical(bver,EXPECTED_BIOC))
add("DESeq2 version",EXPECTED_DESEQ2,dver,identical(dver,EXPECTED_DESEQ2))
must(identical(rver,EXPECTED_R),"R version changed since Step 1")
must(identical(bver,EXPECTED_BIOC),"Bioconductor version changed since Step 1")
must(identical(dver,EXPECTED_DESEQ2),"DESeq2 version changed since Step 1")

if (file.exists(FITTED)) {
  if (file.exists(PASS_PATH)) {
    log_line("FINAL_GATE: R0_EXACT_MODEL_FIT_ALREADY_PASS__NO_RERUN")
    quit(save="no",status=0,runLast=FALSE)
  }
  if (file.exists(HOLD_PATH)) {
    log_line("FINAL_GATE: R0_EXACT_MODEL_FIT_ALREADY_HOLD__NO_RERUN")
    quit(save="no",status=21,runLast=FALSE)
  }
  stop("R0_fitted_dds.rds exists without recognized Step-2 gate; do not overwrite.")
}

must(file.exists(STEP1_GATE),"Missing Step-1 PASS gate")
must(file.exists(PREFIT),"Missing frozen prefit checkpoint")
g <- readLines(STEP1_GATE,warn=FALSE)
add("Step-1 gate","R0_EXACT_TXIMPORT_PREP_PASS",if(length(g)) g[1] else "EMPTY",
    length(g)>0 && identical(g[1],"R0_EXACT_TXIMPORT_PREP_PASS"))
must(length(g)>0 && identical(g[1],"R0_EXACT_TXIMPORT_PREP_PASS"),"Step-1 gate not accepted PASS")

log_line("Loading frozen prefit checkpoint...")
dds <- readRDS(PREFIT)
must(inherits(dds,"DESeqDataSet"),"Prefit object is not DESeqDataSet")
add("prefit genes","19428",nrow(dds),nrow(dds)==19428L)
add("prefit samples","142",ncol(dds),ncol(dds)==142L)

obs_design <- gsub("\\s+"," ",paste(deparse(design(dds)),collapse=" "))
exp_design <- "~category + SV1 + SV2 + SV3 + SV4 + SV5 + SV6 + SV7 + SV8 + SV9 + SV10 + SV11 + SV12 + SV13 + SV14 + SV15 + SV16 + SV17 + SV18 + SV19 + SV20 + SV21"
add("prefit design",exp_design,obs_design,identical(obs_design,exp_design))

avg_present <- "avgTxLength" %in% SummarizedExperiment::assayNames(dds)
avg_ok <- FALSE
if (avg_present) {
  a <- SummarizedExperiment::assay(dds,"avgTxLength")
  avg_ok <- identical(dim(a),c(19428L,142L)) && all(is.finite(a)) && all(a>0)
}
add("prefit avgTxLength","19428x142 finite positive",
    if(avg_present) paste(dim(SummarizedExperiment::assay(dds,"avgTxLength")),collapse="x") else "ABSENT",
    avg_present && avg_ok)

beta_pre <- "betaConv" %in% names(S4Vectors::mcols(dds))
add("prefit is unfitted","betaConv absent",paste0("betaConv_present=",beta_pre),!beta_pre)
must(nrow(dds)==19428L,"Prefit gene count changed")
must(ncol(dds)==142L,"Prefit sample count changed")
must(identical(obs_design,exp_design),"Prefit design changed")
must(avg_present && avg_ok,"Prefit avgTxLength invalid")
must(!beta_pre,"Prefit object already appears fitted")
atomic_csv(do.call(rbind,AUD),AUDIT_PATH)

warnings_seen <- character()
log_line("------------------------------------------------------------")
log_line("Starting DESeq(dds) with default DESeq2 settings...")
log_line("------------------------------------------------------------")
t0 <- Sys.time()

dds_fit <- withCallingHandlers(
  DESeq2::DESeq(dds),
  warning=function(w) {
    warnings_seen <<- c(warnings_seen,conditionMessage(w))
    log_line("[R WARNING] ",conditionMessage(w))
    invokeRestart("muffleWarning")
  }
)

secs <- as.numeric(difftime(Sys.time(),t0,units="secs"))
log_line("DESeq() returned successfully.")
log_line("Immediately saving fitted DDS checkpoint...")
atomic_save(dds_fit,FITTED)
log_line("Fitted checkpoint saved: ",FITTED)

must("betaConv" %in% names(S4Vectors::mcols(dds_fit)),"Fitted DDS lacks betaConv metadata")
bc <- as.logical(S4Vectors::mcols(dds_fit)$betaConv)
n_true <- sum(bc %in% TRUE,na.rm=TRUE)
n_false <- sum(bc %in% FALSE,na.rm=TRUE)
n_na <- sum(is.na(bc))

POST <- rbind(
  data.frame(item="DESeq runtime seconds",expected="informational",observed=secs,status="PASS",notes=""),
  data.frame(item="fitted checkpoint exists",expected="TRUE",observed=file.exists(FITTED),status=if(file.exists(FITTED)) "PASS" else "FAIL",notes=""),
  data.frame(item="beta converged genes",expected="informational",observed=n_true,status="PASS",notes=""),
  data.frame(item="beta non-converged genes",expected="0 for clean Step-2 PASS",observed=n_false,status=if(n_false==0L) "PASS" else "HOLD",notes="Do not tune maxit or rerun automatically."),
  data.frame(item="betaConv NA genes",expected="0",observed=n_na,status=if(n_na==0L) "PASS" else "HOLD",notes="")
)
atomic_csv(rbind(do.call(rbind,AUD),POST),AUDIT_PATH)
atomic_lines(c(paste0("warning_count=",length(warnings_seen)),warnings_seen),WARN_PATH)
capture.output(sessionInfo(),file=SESSION_PATH)

if (n_false>0L || n_na>0L) {
  atomic_lines(c(
    "R0_EXACT_MODEL_FIT_HOLD_BETA_CONVERGENCE",
    paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
    "implementation=v4_LOCAL_RUN",
    "DESeq_executed=YES",
    "DESeq_rerun_authorized=NO",
    paste0("fitted_genes=",nrow(dds_fit)),
    paste0("samples=",ncol(dds_fit)),
    paste0("beta_converged=",n_true),
    paste0("beta_nonconverged=",n_false),
    paste0("betaConv_NA=",n_na),
    paste0("warning_count=",length(warnings_seen)),
    paste0("fit_runtime_seconds=",secs),
    "fitted_checkpoint=results/R0/v4_LOCAL_RUN/R0_fitted_dds.rds",
    "next_action=Return outputs to ChatGPT; do NOT tune maxit or rerun."
  ),HOLD_PATH)
  log_line("============================================================")
  log_line("FINAL_GATE: R0_EXACT_MODEL_FIT_HOLD_BETA_CONVERGENCE")
  log_line("beta converged=",n_true,"; non-converged=",n_false,"; NA=",n_na)
  log_line("Fitted checkpoint IS SAVED. DO NOT RERUN DESeq().")
  log_line("============================================================")
  quit(save="no",status=21,runLast=FALSE)
}

atomic_lines(c(
  "R0_EXACT_MODEL_FIT_PASS",
  paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
  "implementation=v4_LOCAL_RUN",
  "DESeq_executed=YES",
  "DESeq_rerun_authorized=NO",
  paste0("fitted_genes=",nrow(dds_fit)),
  paste0("samples=",ncol(dds_fit)),
  paste0("beta_converged=",n_true),
  paste0("beta_nonconverged=",n_false),
  paste0("betaConv_NA=",n_na),
  paste0("warning_count=",length(warnings_seen)),
  paste0("fit_runtime_seconds=",secs),
  "fitted_checkpoint=results/R0/v4_LOCAL_RUN/R0_fitted_dds.rds",
  "results_export_executed=NO",
  "lfcShrink_executed=NO",
  "PCA_executed=NO",
  "next_stage=Exact R0 Step 3 only after ChatGPT audit"
),PASS_PATH)

log_line("============================================================")
log_line("FINAL_GATE: R0_EXACT_MODEL_FIT_PASS")
log_line("fitted genes=",nrow(dds_fit),"; samples=",ncol(dds_fit))
log_line("beta converged=",n_true,"; non-converged=",n_false,"; NA=",n_na)
log_line("fit runtime seconds=",secs)
log_line("checkpoint: ",FITTED)
log_line("STOP HERE. No downstream result extraction was executed.")
log_line("============================================================")
quit(save="no",status=0,runLast=FALSE)
