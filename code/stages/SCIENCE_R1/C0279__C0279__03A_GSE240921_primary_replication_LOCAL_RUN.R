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
# RV Project — R1 GSE240921 Step 3A
# PRIMARY WALD EXTRACTION + FROZEN 330-CANDIDATE REPLICATION ADJUDICATION
#
# Frozen authorities:
#   - R1_GSE240921_MODEL_CONTRACT_FROZEN.txt
#   - R1_GSE240921_PRIMARY_MODEL_FIT_PASS.txt
#   - R1_GSE240921_primary_fitted_dds.rds
#   - R1_GSE240921_R0_330_candidate_mapping.csv
#
# Primary coefficient:
#   clinical_state_DECOMPENSATED_vs_COMPENSATED
#
# Primary assessability:
#   UNIQUE_MAPPED
#   + baseMean >= 5
#   + betaConv == TRUE
#   + finite Wald p-value
#
# Primary replication family:
#   FULL 330 R0 discoveries
#   unassessable/unmapped candidate p = 1
#   BH across exactly 330 candidates
#   replicated = BH-FDR < 0.05 AND same unshrunk LFC sign as R0
#
# Sensitivity only:
#   BH among assessable candidates only
#
# Secondary descriptive only:
#   author-style abs(log2FC) >= 0.585
#
# This step:
#   - does NOT refit DESeq()
#   - does NOT run effect-size shrinkage
#   - does NOT fit sex-adjusted sensitivity model
# ==============================================================================

options(stringsAsFactors=FALSE, warn=1)

ROOT <- normalizePath(getwd(), winslash="/", mustWork=TRUE)
if (!identical(ROOT,RV_PROJECT_ROOT)) stop("Expected D:/RV_project")

user_lib <- file.path(Sys.getenv("LOCALAPPDATA"),"R","win-library","4.6")
if (dir.exists(user_lib)) .libPaths(unique(c(user_lib,.libPaths())))

suppressPackageStartupMessages(library(DESeq2))

RES <- file.path(ROOT,"results","R1_GSE240921")
LOGDIR <- file.path(ROOT,"logs")
dir.create(RES,recursive=TRUE,showWarnings=FALSE)
dir.create(LOGDIR,recursive=TRUE,showWarnings=FALSE)

CONTRACT <- file.path(RES,"R1_GSE240921_MODEL_CONTRACT_FROZEN.txt")
FIT_GATE <- file.path(RES,"R1_GSE240921_PRIMARY_MODEL_FIT_PASS.txt")
FITTED <- file.path(RES,"R1_GSE240921_primary_fitted_dds.rds")
CANDMAP <- file.path(RES,"R1_GSE240921_R0_330_candidate_mapping.csv")
PRESTATUS <- file.path(RES,"R1_GSE240921_step2_candidate_fit_status.csv")

OUT_FULL <- file.path(RES,"R1_GSE240921_primary_Wald_all_genes.csv")
OUT_CAND <- file.path(RES,"R1_GSE240921_R0_330_primary_replication_ledger.csv")
OUT_REP <- file.path(RES,"R1_GSE240921_R0_330_PRIMARY_REPLICATED.csv")
OUT_SUM <- file.path(RES,"R1_GSE240921_step3A_primary_replication_summary.csv")
OUT_GATE <- file.path(RES,"R1_GSE240921_STEP3A_PRIMARY_REPLICATION_PASS.txt")
LOG <- file.path(LOGDIR,"R1_GSE240921_STEP3A_PRIMARY_REPLICATION.log")

if (file.exists(LOG)) {
  old <- file.path(
    LOGDIR,
    paste0("R1_GSE240921_STEP3A_PRIMARY_REPLICATION_",
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
logline("R1 GSE240921 Step 3A — primary Wald + frozen 330-family replication")
logline("============================================================")

# --------------------------------------------------------------------------
# Re-entry / authority guards
# --------------------------------------------------------------------------

if (file.exists(OUT_GATE) && file.exists(OUT_CAND) && file.exists(OUT_REP)) {
  logline("FINAL_GATE: R1_GSE240921_STEP3A_PRIMARY_REPLICATION_ALREADY_PASS__NO_RERUN")
  quit(save="no",status=0,runLast=FALSE)
}

must(file.exists(CONTRACT),"Missing frozen model contract")
must(file.exists(FIT_GATE),"Missing primary fit PASS gate")
must(file.exists(FITTED),"Missing fitted DDS")
must(file.exists(CANDMAP),"Missing 330-candidate mapping")
must(file.exists(PRESTATUS),"Missing Step-2 candidate pre-result status")

ct <- readLines(CONTRACT,warn=FALSE)
fg <- readLines(FIT_GATE,warn=FALSE)

must(length(ct)>0L && ct[1]=="R1_GSE240921_MODEL_CONTRACT_FROZEN",
     "Unexpected contract gate")
must(length(fg)>0L && fg[1]=="R1_GSE240921_PRIMARY_MODEL_FIT_PASS",
     "Unexpected fit gate")

must(any(ct=="primary_model=~ technical_batch + clinical_state"),
     "Frozen model changed")
must(any(ct=="primary_contrast=DECOMPENSATED_vs_COMPENSATED"),
     "Frozen contrast changed")
must(any(ct=="primary_expression_assessability=baseMean_ge_5"),
     "Frozen expression gate changed")
must(any(ct=="default_betaConv_required=TRUE"),
     "Frozen beta-convergence rule changed")
must(any(ct=="primary_replication_FDR_family=FULL_330_PADDED"),
     "Frozen 330-family rule changed")
must(any(ct=="unmapped_or_nonassessable_candidate_p_for_primary_FDR=1"),
     "Frozen padded-p rule changed")
must(any(ct=="primary_replication_FDR_method=BH"),
     "Frozen BH method changed")
must(any(ct=="primary_replication_FDR_alpha=0.05"),
     "Frozen alpha changed")
must(any(ct=="primary_replication_direction_requirement=SAME_UNSHRUNKEN_LOG2FC_SIGN_AS_R0"),
     "Frozen direction rule changed")
must(any(ct=="available_only_BH_role=SENSITIVITY_ONLY"),
     "Frozen sensitivity role changed")

must(any(fg=="direct_primary_coefficient=clinical_state_DECOMPENSATED_vs_COMPENSATED"),
     "Fit gate direct coefficient changed")
must(any(fg=="DESeq_rerun_executed=NO"),"Fit gate indicates unexpected rerun")
must(any(fg=="contrast_statistics_executed=NO"),
     "Fit gate indicates contrast statistics were already extracted")

# --------------------------------------------------------------------------
# Load fitted object and extract one unshrunk Wald result.
# --------------------------------------------------------------------------

dds <- readRDS(FITTED)
must(inherits(dds,"DESeqDataSet"),"Fitted object is not DESeqDataSet")
must(nrow(dds)==48738L && ncol(dds)==40L,"Fitted DDS dimensions changed")

coef_name <- "clinical_state_DECOMPENSATED_vs_COMPENSATED"
rn <- DESeq2::resultsNames(dds)
must(coef_name %in% rn,"Direct primary coefficient absent")

mc <- as.data.frame(S4Vectors::mcols(dds))
must("betaConv" %in% names(mc),"betaConv missing from fitted DDS")
bc <- as.logical(mc$betaConv)
must(sum(bc %in% FALSE,na.rm=TRUE)==0L && sum(is.na(bc))==0L,
     "Unexpected betaConv state since Step 2")

logline("[INFO] Extracting unshrunk Wald statistics for direct primary coefficient.")
res <- DESeq2::results(
  dds,
  name=coef_name,
  independentFiltering=FALSE
)

rdf <- as.data.frame(res)
need <- c("baseMean","log2FoldChange","lfcSE","stat","pvalue")
must(all(need %in% names(rdf)),"Required Wald columns missing")
must(nrow(rdf)==48738L && identical(rownames(rdf),rownames(dds)),
     "Wald result row identity changed")

replace_flag <- if("replace" %in% names(mc)) {
  as.logical(mc$replace)
} else {
  rep(FALSE,nrow(dds))
}
replace_flag[is.na(replace_flag)] <- FALSE

full <- data.frame(
  gse240921_gene_id=rownames(dds),
  baseMean=as.numeric(rdf$baseMean),
  log2FoldChange=as.numeric(rdf$log2FoldChange),
  lfcSE=as.numeric(rdf$lfcSE),
  stat=as.numeric(rdf$stat),
  pvalue=as.numeric(rdf$pvalue),
  betaConv=bc,
  DESeq2_outlier_replaced=replace_flag,
  stringsAsFactors=FALSE
)
awrite(full,OUT_FULL)

# --------------------------------------------------------------------------
# Bind 330-candidate family and Step-2 pre-result status.
# --------------------------------------------------------------------------

cand <- read.csv(CANDMAP,stringsAsFactors=FALSE,check.names=FALSE)
pre <- read.csv(PRESTATUS,stringsAsFactors=FALSE,check.names=FALSE)

must(nrow(cand)==330L && nrow(pre)==330L,"Candidate family is not 330")
must(identical(cand$r0_gene_id,pre$r0_gene_id),
     "Candidate order differs between mapping and Step-2 status")
must(sum(cand$mapping_status=="UNIQUE_MAPPED")==326L,
     "Unique mapping count changed")
must(sum(cand$mapping_status=="NOT_MAPPED")==4L,
     "Unmapped count changed")
must(sum(pre$pre_result_status=="PENDING_WALD_RESULT")==256L,
     "Expected exactly 256 candidates pending Wald")
must(sum(pre$pre_result_status=="LOW_EXPRESSION_PAD_P1")==70L,
     "Expected exactly 70 low-expression candidates")
must(sum(pre$pre_result_status=="UNMAPPED_PAD_P1")==4L,
     "Expected exactly 4 unmapped candidates")

out <- cand
out$gse240921_baseMean <- NA_real_
out$gse240921_log2FC <- NA_real_
out$gse240921_lfcSE <- NA_real_
out$gse240921_stat <- NA_real_
out$gse240921_pvalue <- NA_real_
out$gse240921_betaConv <- NA
out$DESeq2_outlier_replaced <- FALSE
out$primary_assessability <- pre$pre_result_status
out$primary_p_for_BH330 <- 1
out$primary_BH_FDR_330 <- NA_real_
out$direction_concordant <- FALSE
out$primary_replicated <- FALSE
out$available_only_BH_FDR <- NA_real_
out$available_only_replicated <- FALSE
out$author_style_absLFC_ge_0_585 <- FALSE

mapped <- which(out$mapping_status=="UNIQUE_MAPPED")
mi <- match(out$gse240921_gene_id[mapped],full$gse240921_gene_id)
must(all(!is.na(mi)),"Mapped candidate missing from Wald table")

out$gse240921_baseMean[mapped] <- full$baseMean[mi]
out$gse240921_log2FC[mapped] <- full$log2FoldChange[mi]
out$gse240921_lfcSE[mapped] <- full$lfcSE[mi]
out$gse240921_stat[mapped] <- full$stat[mi]
out$gse240921_pvalue[mapped] <- full$pvalue[mi]
out$gse240921_betaConv[mapped] <- full$betaConv[mi]
out$DESeq2_outlier_replaced[mapped] <- full$DESeq2_outlier_replaced[mi]

# Verify Step-2 baseMean and betaConv were not altered by result extraction.
tol <- 1e-10
must(
  max(abs(out$gse240921_baseMean[mapped]-as.numeric(pre$baseMean[mapped])),
      na.rm=TRUE) <= tol,
  "Candidate baseMean changed since Step 2"
)
must(
  all(as.logical(out$gse240921_betaConv[mapped]) ==
      as.logical(pre$betaConv[mapped])),
  "Candidate betaConv changed since Step 2"
)

# Final assessability adds finite Wald p-value.
pending <- which(out$primary_assessability=="PENDING_WALD_RESULT")
finite_pending <- pending[is.finite(out$gse240921_pvalue[pending])]
nonfinite_pending <- setdiff(pending,finite_pending)

if(length(finite_pending)>0L) {
  out$primary_assessability[finite_pending] <- "ASSESSABLE_WALD_FINITE"
}
if(length(nonfinite_pending)>0L) {
  out$primary_assessability[nonfinite_pending] <- "WALD_PVALUE_NONFINITE_PAD_P1"
}

# Only truly assessable candidates contribute their observed p-value.
assess <- which(out$primary_assessability=="ASSESSABLE_WALD_FINITE")

out$primary_p_for_BH330[assess] <- out$gse240921_pvalue[assess]

# Exact primary BH universe = 330.
must(length(out$primary_p_for_BH330)==330L,
     "Primary BH vector is not length 330")
must(all(is.finite(out$primary_p_for_BH330)),
     "Primary BH vector contains non-finite values")
must(all(out$primary_p_for_BH330>=0 & out$primary_p_for_BH330<=1),
     "Primary BH vector outside [0,1]")

out$primary_BH_FDR_330 <- stats::p.adjust(
  out$primary_p_for_BH330,
  method="BH"
)

# Frozen direction rule uses UNSHRUNKEN LFC.
out$direction_concordant[assess] <- (
  sign(out$r0_log2FC[assess]) != 0 &
  sign(out$gse240921_log2FC[assess]) != 0 &
  sign(out$r0_log2FC[assess]) == sign(out$gse240921_log2FC[assess])
)

out$primary_replicated <- (
  out$primary_assessability=="ASSESSABLE_WALD_FINITE" &
  out$direction_concordant &
  is.finite(out$primary_BH_FDR_330) &
  out$primary_BH_FDR_330 < 0.05
)

# Sensitivity: BH among assessable only.
if(length(assess)>0L) {
  out$available_only_BH_FDR[assess] <- stats::p.adjust(
    out$gse240921_pvalue[assess],
    method="BH"
  )
}
out$available_only_replicated <- (
  out$primary_assessability=="ASSESSABLE_WALD_FINITE" &
  out$direction_concordant &
  is.finite(out$available_only_BH_FDR) &
  out$available_only_BH_FDR < 0.05
)

# Secondary descriptive effect-size threshold only.
out$author_style_absLFC_ge_0_585[assess] <- (
  abs(out$gse240921_log2FC[assess]) >= 0.585
)

# Internal integrity.
must(sum(out$primary_assessability=="UNMAPPED_PAD_P1")==4L,
     "Unmapped status changed")
must(sum(out$primary_assessability=="LOW_EXPRESSION_PAD_P1")==70L,
     "Low-expression status changed")
must(all(out$primary_p_for_BH330[
  out$primary_assessability!="ASSESSABLE_WALD_FINITE"
]==1),
"Every non-assessable candidate must carry primary p=1")

rep <- out[out$primary_replicated,,drop=FALSE]
if(nrow(rep)>0L) {
  rep <- rep[order(rep$primary_BH_FDR_330,
                   -abs(rep$gse240921_log2FC),
                   rep$r0_gene_id),,drop=FALSE]
}

awrite(out,OUT_CAND)
awrite(rep,OUT_REP)

# --------------------------------------------------------------------------
# Summary
# --------------------------------------------------------------------------

n_assess <- length(assess)
n_nonfinite <- length(nonfinite_pending)
n_direction <- sum(out$direction_concordant & 
                   out$primary_assessability=="ASSESSABLE_WALD_FINITE")
n_nominal <- sum(out$primary_assessability=="ASSESSABLE_WALD_FINITE" &
                 is.finite(out$gse240921_pvalue) &
                 out$gse240921_pvalue<0.05)
n_fullfdr <- sum(out$primary_BH_FDR_330<0.05)
n_primary <- sum(out$primary_replicated)
n_avail <- sum(out$available_only_replicated)
n_author <- sum(out$primary_replicated &
                out$author_style_absLFC_ge_0_585)
n_replaced_cand <- sum(out$DESeq2_outlier_replaced,na.rm=TRUE)
n_replaced_assess <- sum(out$DESeq2_outlier_replaced[assess],na.rm=TRUE)

summary <- data.frame(
  metric=c(
    "R0_candidate_family_total",
    "unique_mapped",
    "unmapped_pad_p1",
    "low_expression_pad_p1",
    "beta_nonconverged_pad_p1",
    "betaConv_NA_pad_p1",
    "Wald_pvalue_nonfinite_pad_p1",
    "primary_assessable_with_finite_Wald_p",
    "direction_concordant_assessable",
    "nominal_p_lt_0_05_assessable_regardless_direction",
    "BH330_FDR_lt_0_05_regardless_direction",
    "PRIMARY_REPLICATED_BH330_FDR_lt_0_05_plus_direction",
    "available_only_replicated_sensitivity",
    "primary_replicated_also_absLFC_ge_0_585",
    "candidate_rows_with_DESeq2_outlier_replacement",
    "assessable_rows_with_DESeq2_outlier_replacement",
    "DESeq_model_refit_in_step3A",
    "effect_shrinkage_in_step3A",
    "sex_sensitivity_model_in_step3A"
  ),
  value=c(
    330,
    sum(out$mapping_status=="UNIQUE_MAPPED"),
    sum(out$primary_assessability=="UNMAPPED_PAD_P1"),
    sum(out$primary_assessability=="LOW_EXPRESSION_PAD_P1"),
    sum(out$primary_assessability=="BETA_NONCONVERGED_PAD_P1"),
    sum(out$primary_assessability=="BETA_CONV_NA_PAD_P1"),
    n_nonfinite,
    n_assess,
    n_direction,
    n_nominal,
    n_fullfdr,
    n_primary,
    n_avail,
    n_author,
    n_replaced_cand,
    n_replaced_assess,
    0,0,0
  ),
  stringsAsFactors=FALSE
)
awrite(summary,OUT_SUM)

twrite(c(
  "R1_GSE240921_STEP3A_PRIMARY_REPLICATION_PASS",
  paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
  "dataset=GSE240921",
  "contrast=DECOMPENSATED_vs_COMPENSATED",
  "primary_fit=~ technical_batch + clinical_state",
  "primary_pvalue_authority=UNSHRUNKEN_WALD",
  "primary_assessability=UNIQUE_MAPPING_PLUS_baseMean_ge5_PLUS_betaConv_TRUE_PLUS_finite_Wald_p",
  "primary_FDR_family=FULL_330_PADDED",
  "primary_FDR_method=BH",
  "primary_FDR_alpha=0.05",
  "unassessable_p=1",
  "primary_direction_requirement=SAME_UNSHRUNKEN_LFC_SIGN_AS_R0",
  paste0("primary_assessable=",n_assess),
  paste0("primary_replicated=",n_primary),
  paste0("available_only_replicated_sensitivity=",n_avail),
  "author_style_absLFC_ge0.585_role=SECONDARY_DESCRIPTIVE_ONLY",
  "DESeq_model_refit_executed=NO",
  "effect_shrinkage_executed=NO",
  "sex_sensitivity_model_executed=NO",
  "next_stage=ChatGPT audit before ASHR and sex-adjusted sensitivity"
),OUT_GATE)

logline("Primary assessable candidates=",n_assess,"/330")
logline("Direction-concordant assessable=",n_direction)
logline("Primary replicated=",n_primary)
logline("Available-only sensitivity replicated=",n_avail)
logline("FINAL_GATE: R1_GSE240921_STEP3A_PRIMARY_REPLICATION_PASS")
quit(save="no",status=0,runLast=FALSE)
