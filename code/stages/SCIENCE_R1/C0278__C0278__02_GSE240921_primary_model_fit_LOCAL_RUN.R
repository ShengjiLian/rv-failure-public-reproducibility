# ---- RV PUBLIC REPRODUCIBILITY PORTABILITY OVERLAY V1.0 ----
.RV_PROJECT_ROOT_ENV <- Sys.getenv('RV_PROJECT_ROOT', unset='')
RV_PROJECT_ROOT <- if (nzchar(.RV_PROJECT_ROOT_ENV)) {
  normalizePath(.RV_PROJECT_ROOT_ENV, winslash='/', mustWork=TRUE)
} else {
  normalizePath(getwd(), winslash='/', mustWork=TRUE)
}
# This overlay changes path binding only; scientific/statistical semantics remain historical authority.

source(file.path(RV_PROJECT_ROOT, 'code', 'lib', 'rv_runtime_helpers.R'))


# RV Project — R1 GSE240921 Step 2
# PRIMARY DESeq2 MODEL FIT ONLY
#
# Frozen model: ~ technical_batch + clinical_state
# Direct coefficient: clinical_state_DECOMPENSATED_vs_COMPENSATED
#
# This stage performs one default DESeq fit only.
# It does not extract contrast statistics, shrink effects, run BH/FDR,
# fit the sex-adjusted sensitivity model, or tune convergence settings.

options(stringsAsFactors=FALSE, warn=1)

ROOT <- normalizePath(getwd(), winslash="/", mustWork=TRUE)
if (!identical(ROOT,RV_PROJECT_ROOT)) stop("Expected D:/RV_project")

user_lib <- file.path(Sys.getenv("LOCALAPPDATA"),"R","win-library","4.6")
if (dir.exists(user_lib)) .libPaths(unique(c(user_lib,.libPaths())))

suppressPackageStartupMessages({
  library(DESeq2)
  library(readxl)
})

RES <- file.path(ROOT,"results","R1_GSE240921")
LOGDIR <- file.path(ROOT,"logs")
dir.create(RES,recursive=TRUE,showWarnings=FALSE)
dir.create(LOGDIR,recursive=TRUE,showWarnings=FALSE)

CONTRACT <- file.path(RES,"R1_GSE240921_MODEL_CONTRACT_FROZEN.txt")
MANIFEST <- file.path(RES,"R1_GSE240921_sample_manifest_semantic_repair.csv")
CANDMAP <- file.path(RES,"R1_GSE240921_R0_330_candidate_mapping.csv")
XLSX <- file.path(ROOT,"data","processed","GSE240921","GSE240921_processed-data-human.xlsx")

PREFIT <- file.path(RES,"R1_GSE240921_primary_prefit_dds.rds")
FITTED <- file.path(RES,"R1_GSE240921_primary_fitted_dds.rds")
AUDIT <- file.path(RES,"R1_GSE240921_step2_fit_audit.csv")
CANDSTAT <- file.path(RES,"R1_GSE240921_step2_candidate_fit_status.csv")
WARN <- file.path(RES,"R1_GSE240921_step2_warnings.txt")
SESSION <- file.path(RES,"R1_GSE240921_step2_sessionInfo.txt")
PASS <- file.path(RES,"R1_GSE240921_PRIMARY_MODEL_FIT_PASS.txt")
HOLD <- file.path(RES,"R1_GSE240921_PRIMARY_MODEL_FIT_HOLD.txt")
LOG <- file.path(LOGDIR,"R1_GSE240921_STEP2_PRIMARY_MODEL_FIT.log")

if (file.exists(LOG)) {
  old <- file.path(
    LOGDIR,
    paste0("R1_GSE240921_STEP2_PRIMARY_MODEL_FIT_",
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
  if(!file.rename(t,p)) {unlink(t); stop("Atomic CSV write failed: ",p)}
}
twrite <- function(x,p) {
  t <- paste0(p,".tmp_",Sys.getpid())
  writeLines(x,t,useBytes=TRUE)
  if(!file.rename(t,p)) {unlink(t); stop("Atomic text write failed: ",p)}
}

logline("============================================================")
logline("R1 GSE240921 Step 2 — primary DESeq2 model fit only")
logline("============================================================")

# Re-entry protection.
if (file.exists(FITTED) && file.exists(PASS)) {
  logline("FINAL_GATE: R1_GSE240921_PRIMARY_MODEL_FIT_ALREADY_PASS__NO_RERUN")
  quit(save="no",status=0,runLast=FALSE)
}
if (file.exists(FITTED) && !file.exists(PASS)) {
  stop("Fitted checkpoint exists without PASS gate. Refusing overwrite/rerun.")
}

# Frozen contract guards.
must(file.exists(CONTRACT),"Missing frozen Step-1 model contract")
ct <- readLines(CONTRACT,warn=FALSE)
must(length(ct)>0L && ct[1]=="R1_GSE240921_MODEL_CONTRACT_FROZEN",
     "Unexpected model-contract gate")
must(any(ct=="primary_model=~ technical_batch + clinical_state"),
     "Frozen primary model changed")
must(any(ct=="primary_contrast=DECOMPENSATED_vs_COMPENSATED"),
     "Frozen primary contrast changed")
must(any(ct=="R0_replication_family_size=330"),
     "Frozen replication family changed")
must(any(ct=="primary_replication_FDR_family=FULL_330_PADDED"),
     "Frozen FDR family changed")
must(any(ct=="replication_results_peeked=NO"),
     "Contract indicates outcome results were already peeked")

must(file.exists(MANIFEST),"Missing repaired sample manifest")
must(file.exists(CANDMAP),"Missing frozen candidate mapping")
must(file.exists(XLSX),"Missing processed workbook")
must(file.info(XLSX)$size==9035174,
     "Processed workbook byte size changed from audited value")

m <- read.csv(MANIFEST,stringsAsFactors=FALSE,check.names=FALSE)
must(nrow(m)==40L,"Manifest must contain 40 samples")
must(length(unique(m$count_matrix_column))==40L,"Manifest sample names not unique")

m$technical_batch <- factor(
  m$technical_batch,
  levels=c("BATCH1_PRAKASH_SINGLE_END","BATCH2_US_PAIRED_END")
)
m$clinical_state <- factor(
  m$clinical_state,
  levels=c("COMPENSATED","NORMAL_CONTROL","DECOMPENSATED")
)

must(sum(is.na(m$technical_batch))==0L,"Unexpected technical batch")
must(sum(is.na(m$clinical_state))==0L,"Unexpected clinical state")
must(sum(m$clinical_state=="COMPENSATED")==14L,"Compensated n must be 14")
must(sum(m$clinical_state=="DECOMPENSATED")==13L,"Decompensated n must be 13")
must(sum(m$clinical_state=="NORMAL_CONTROL")==13L,"Normal n must be 13")

X <- model.matrix(~ technical_batch + clinical_state,data=m)
must(qr(X)$rank==ncol(X),"Primary model matrix is not full rank")

# Build or validate prefit checkpoint.
if (file.exists(PREFIT)) {
  logline("[INFO] Loading existing prefit checkpoint.")
  dds <- readRDS(PREFIT)
  must(inherits(dds,"DESeqDataSet"),"Existing prefit object invalid")
  must(nrow(dds)==48738L && ncol(dds)==40L,"Existing prefit dimensions changed")
  must(identical(colnames(dds),m$count_matrix_column),
       "Existing prefit sample order changed")
  must(identical(levels(colData(dds)$clinical_state),
                 c("COMPENSATED","NORMAL_CONTROL","DECOMPENSATED")),
       "Existing prefit clinical-state levels changed")
  must(identical(levels(colData(dds)$technical_batch),
                 c("BATCH1_PRAKASH_SINGLE_END","BATCH2_US_PAIRED_END")),
       "Existing prefit batch levels changed")
} else {
  logline("[INFO] Reading official count matrix.")
  cnt <- as.data.frame(
    readxl::read_excel(XLSX,sheet="count matrix",.name_repair="unique"),
    stringsAsFactors=FALSE,check.names=FALSE
  )
  must(nrow(cnt)==48738L && ncol(cnt)==41L,
       "Count matrix must be 48,738 x 41")

  gene_id <- as.character(cnt[[1]])
  must(length(unique(gene_id))==48738L,"Gene IDs must be unique")
  must(setequal(names(cnt)[-1],m$count_matrix_column),
       "Workbook sample columns differ from frozen manifest")

  x <- cnt[,m$count_matrix_column,drop=FALSE]
  count_mat <- do.call(cbind,lapply(x,function(v) suppressWarnings(as.numeric(v))))
  rownames(count_mat) <- gene_id
  colnames(count_mat) <- m$count_matrix_column

  must(all(is.finite(count_mat)),"Count matrix contains non-finite values")
  must(all(count_mat>=0),"Count matrix contains negative values")
  must(max(abs(count_mat-round(count_mat)))<1e-8,
       "Count matrix contains non-integer-like values")
  must(max(count_mat)<=.Machine$integer.max,
       "Count matrix exceeds R integer range")

  count_mat <- round(count_mat)
  storage.mode(count_mat) <- "integer"

  cd <- data.frame(
    technical_batch=m$technical_batch,
    clinical_state=m$clinical_state,
    geo_accession=m$geo_accession,
    sex=m$sex,
    row.names=m$count_matrix_column,
    stringsAsFactors=FALSE
  )

  dds <- DESeq2::DESeqDataSetFromMatrix(
    countData=count_mat,
    colData=cd,
    design=~ technical_batch + clinical_state
  )

  must(nrow(dds)==48738L && ncol(dds)==40L,"Prefit dimensions wrong")
  must(identical(colnames(dds),m$count_matrix_column),"Prefit sample order changed")
  must(!("betaConv" %in% names(S4Vectors::mcols(dds))),
       "Prefit object unexpectedly already contains fit metadata")

  asave(dds,PREFIT)
  logline("[INFO] Saved prefit checkpoint.")
}

# Environment.
r_ver <- paste(R.version$major,R.version$minor,sep=".")
deseq_ver <- as.character(utils::packageVersion("DESeq2"))
readxl_ver <- as.character(utils::packageVersion("readxl"))
must(r_ver=="4.6.1",paste0("Expected R 4.6.1; observed ",r_ver))
must(deseq_ver=="1.52.0",
     paste0("Expected DESeq2 1.52.0; observed ",deseq_ver))

# One default model fit.
warnings_seen <- character()
fit_error <- NULL
logline("[INFO] Starting one default DESeq2 model fit.")
t0 <- Sys.time()

dds_fit <- tryCatch(
  withCallingHandlers(
    DESeq2::DESeq(dds),
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

if (is.null(dds_fit)) {
  twrite(c(
    "R1_GSE240921_PRIMARY_MODEL_FIT_HOLD_ERROR",
    paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
    paste0("error=",fit_error),
    paste0("runtime_seconds=",runtime),
    "fitted_checkpoint_saved=NO",
    "automatic_rerun=NO",
    "next_action=Return HOLD/log to ChatGPT."
  ),HOLD)
  twrite(c(paste0("warning_count=",length(warnings_seen)),warnings_seen),WARN)
  logline("FINAL_GATE: R1_GSE240921_PRIMARY_MODEL_FIT_HOLD_ERROR")
  quit(save="no",status=41,runLast=FALSE)
}

# Save immediately after successful return.
asave(dds_fit,FITTED)
logline("[INFO] Fit returned; fitted checkpoint saved.")

# Post-fit diagnostics only.
must(nrow(dds_fit)==48738L && ncol(dds_fit)==40L,"Fitted dimensions changed")
must(identical(colnames(dds_fit),m$count_matrix_column),"Fitted sample order changed")

rn <- DESeq2::resultsNames(dds_fit)
expected_coef <- "clinical_state_DECOMPENSATED_vs_COMPENSATED"
must(expected_coef %in% rn,
     paste0("Expected coefficient absent. names=",paste(rn,collapse=";")))

mc <- as.data.frame(S4Vectors::mcols(dds_fit))
must("betaConv" %in% names(mc),"Fitted object lacks betaConv")
bc <- as.logical(mc$betaConv)

allzero <- rowSums(DESeq2::counts(dds_fit))==0L
nonzero <- !allzero
beta_true_nonzero <- sum(nonzero & bc %in% TRUE,na.rm=TRUE)
beta_false_nonzero <- sum(nonzero & bc %in% FALSE,na.rm=TRUE)
beta_na_nonzero <- sum(nonzero & is.na(bc))

fit_type <- tryCatch(
  attr(DESeq2::dispersionFunction(dds_fit),"fitType"),
  error=function(e) NA_character_
)
if (is.null(fit_type) || !length(fit_type)) fit_type <- NA_character_

replace_present <- "replaceCounts" %in% SummarizedExperiment::assayNames(dds_fit)
replace_genes <- if("replace" %in% names(mc)) {
  sum(as.logical(mc$replace),na.rm=TRUE)
} else {
  NA_integer_
}

# Candidate-level pre-result assessability only.
cand <- read.csv(CANDMAP,stringsAsFactors=FALSE,check.names=FALSE)
must(nrow(cand)==330L,"Candidate mapping must have 330 rows")
must(sum(cand$mapping_status=="UNIQUE_MAPPED")==326L,
     "Unique-mapped candidate count changed")
must(sum(cand$mapping_status=="NOT_MAPPED")==4L,
     "Unmapped candidate count changed")

cand$fit_row_present <- FALSE
cand$baseMean <- NA_real_
cand$baseMean_ge_5 <- FALSE
cand$betaConv <- NA
cand$pre_result_status <- "UNMAPPED_PAD_P1"

mapped <- which(cand$mapping_status=="UNIQUE_MAPPED")
mi <- match(cand$gse240921_gene_id[mapped],rownames(dds_fit))
must(all(!is.na(mi)),"A uniquely mapped candidate disappeared from fitted object")

cand$fit_row_present[mapped] <- TRUE
cand$baseMean[mapped] <- as.numeric(mc$baseMean[mi])
cand$baseMean_ge_5[mapped] <- is.finite(cand$baseMean[mapped]) &
                              cand$baseMean[mapped]>=5
cand$betaConv[mapped] <- bc[mi]

for (j in seq_along(mapped)) {
  i <- mapped[j]
  k <- mi[j]
  if (!cand$baseMean_ge_5[i]) {
    cand$pre_result_status[i] <- "LOW_EXPRESSION_PAD_P1"
  } else if (is.na(bc[k])) {
    cand$pre_result_status[i] <- "BETA_CONV_NA_PAD_P1"
  } else if (!bc[k]) {
    cand$pre_result_status[i] <- "BETA_NONCONVERGED_PAD_P1"
  } else {
    cand$pre_result_status[i] <- "PENDING_WALD_RESULT"
  }
}

awrite(cand,CANDSTAT)

pending <- sum(cand$pre_result_status=="PENDING_WALD_RESULT")
lowexp <- sum(cand$pre_result_status=="LOW_EXPRESSION_PAD_P1")
cand_beta_fail <- sum(cand$pre_result_status=="BETA_NONCONVERGED_PAD_P1")
cand_beta_na <- sum(cand$pre_result_status=="BETA_CONV_NA_PAD_P1")

audit <- data.frame(
  metric=c(
    "R_version","DESeq2_version","readxl_version",
    "samples","genes_total","design",
    "design_matrix_rank","design_matrix_columns",
    "direct_primary_coefficient_present",
    "all_zero_genes","nonzero_genes",
    "betaConv_TRUE_nonzero","betaConv_FALSE_nonzero","betaConv_NA_nonzero",
    "dispersion_fit_type","replaceCounts_assay_present","replace_flagged_genes",
    "R0_candidate_family","R0_candidates_unique_mapped","R0_candidates_unmapped",
    "candidate_low_expression_baseMean_lt5",
    "candidate_beta_nonconverged_after_expression_gate",
    "candidate_betaConv_NA_after_expression_gate",
    "candidate_pending_Wald_result",
    "warning_count","runtime_seconds","contrast_statistics_executed"
  ),
  value=c(
    r_ver,deseq_ver,readxl_ver,
    40,48738,"~ technical_batch + clinical_state",
    qr(X)$rank,ncol(X),
    expected_coef %in% rn,
    sum(allzero),sum(nonzero),
    beta_true_nonzero,beta_false_nonzero,beta_na_nonzero,
    fit_type,replace_present,replace_genes,
    330,326,4,
    lowexp,cand_beta_fail,cand_beta_na,pending,
    length(warnings_seen),runtime,"NO"
  ),
  stringsAsFactors=FALSE
)

awrite(audit,AUDIT)
twrite(c(paste0("warning_count=",length(warnings_seen)),warnings_seen),WARN)
capture.output(sessionInfo(),file=SESSION)

twrite(c(
  "R1_GSE240921_PRIMARY_MODEL_FIT_PASS",
  paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
  "dataset=GSE240921",
  "samples=40",
  "genes=48738",
  "model=~ technical_batch + clinical_state",
  "clinical_state_reference=COMPENSATED",
  "technical_batch_reference=BATCH1_PRAKASH_SINGLE_END",
  "direct_primary_coefficient=clinical_state_DECOMPENSATED_vs_COMPENSATED",
  "DESeq_default_fit_executed=YES",
  "DESeq_rerun_executed=NO",
  "contrast_statistics_executed=NO",
  "effect_shrinkage_executed=NO",
  "replication_BH_executed=NO",
  "sensitivity_model_executed=NO",
  paste0("all_zero_genes=",sum(allzero)),
  paste0("betaConv_FALSE_nonzero=",beta_false_nonzero),
  paste0("betaConv_NA_nonzero=",beta_na_nonzero),
  paste0("R0_candidates_low_expression=",lowexp),
  paste0("R0_candidates_beta_nonconverged_after_expression_gate=",cand_beta_fail),
  paste0("R0_candidates_betaConv_NA_after_expression_gate=",cand_beta_na),
  paste0("R0_candidates_pending_Wald=",pending),
  "nonconverged_candidate_policy=PAD_P1_PER_FROZEN_CONTRACT_NO_REFIT",
  paste0("runtime_seconds=",runtime),
  paste0("fitted_checkpoint=",FITTED),
  "next_stage=R1 Step 3 primary Wald extraction and frozen 330-family adjudication after ChatGPT audit"
),PASS)

logline("Fit complete.")
logline("Nonzero beta failures=",beta_false_nonzero,
        "; beta NA=",beta_na_nonzero)
logline("Candidate pending=",pending,
        "; low-expression=",lowexp,
        "; beta-fail=",cand_beta_fail,
        "; beta-NA=",cand_beta_na,
        "; unmapped=4")
logline("FINAL_GATE: R1_GSE240921_PRIMARY_MODEL_FIT_PASS")
quit(save="no",status=0,runLast=FALSE)
