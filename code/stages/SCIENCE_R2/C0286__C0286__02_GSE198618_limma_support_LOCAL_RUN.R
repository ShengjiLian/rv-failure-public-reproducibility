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
# RV Project — R2 GSE198618 Step 2
# LIMMA SUPPORTING-REPLICATION FIT
#
# Requires frozen Step1 contract:
#   input      : author-supplied normalized non-integer edgeR CPM
#   transform  : log2(CPM + 1)
#   model      : ~ clinical_state
#   reference  : COMPENSATED
#   contrast   : DECOMPENSATED vs COMPENSATED
#   eBayes     : trend=TRUE
#   gene filter: CPM >= 1 in >= 7 of 32 samples
#
# Supporting family:
#   exact frozen GSE240921 FINAL PRIMARY25 (25 genes)
#   unmapped/expression-unassessable/nonfinite p => padded p=1
#   BH across FULL 25
#   strict support = BH<0.05 + same unshrunk direction as frozen R0/R1
#
# IMPORTANT:
#   GSE198618 is SUPPORTING_PAH_REPLICATION only.
#   Patient overlap with GSE240921 remains UNKNOWN.
#   No gene discovered here can be added to the frozen PRIMARY25.
# ==============================================================================

options(stringsAsFactors=FALSE, warn=1)

ROOT <- normalizePath(getwd(), winslash="/", mustWork=TRUE)
if(!identical(ROOT,RV_PROJECT_ROOT)) stop("Expected D:/RV_project")

RES <- file.path(ROOT,"results","R2_GSE198618")
R1RES <- file.path(ROOT,"results","R1_GSE240921")
DATA <- file.path(ROOT,"data","processed","GSE198618")
LOGDIR <- file.path(ROOT,"logs")
dir.create(RES,recursive=TRUE,showWarnings=FALSE)
dir.create(LOGDIR,recursive=TRUE,showWarnings=FALSE)

CONTRACT <- file.path(RES,"R2_GSE198618_MODEL_CONTRACT_FROZEN.txt")
MANIFEST <- file.path(RES,"R2_GSE198618_sample_manifest.csv")
MAP25 <- file.path(RES,"R2_GSE198618_PRIMARY25_mapping.csv")
MATRIX <- file.path(DATA,"GSE198618_Normalized_Counts_RV_ALL.csv.gz")

FIT_RDS <- file.path(RES,"R2_GSE198618_limma_fit.rds")
GW <- file.path(RES,"R2_GSE198618_genomewide_limma_results.csv.gz")
CAND <- file.path(RES,"R2_GSE198618_PRIMARY25_SUPPORT_RESULTS.csv")
STRICT <- file.path(RES,"R2_GSE198618_PRIMARY25_STRICT_SUPPORT.csv")
SUMMARY <- file.path(RES,"R2_GSE198618_STEP2_LIMMA_FIT_SUMMARY.csv")
GATE <- file.path(RES,"R2_GSE198618_STEP2_LIMMA_SUPPORT_PASS.txt")
LOG <- file.path(LOGDIR,"R2_GSE198618_STEP2_LIMMA_SUPPORT.log")

if(file.exists(LOG)) {
  old <- file.path(
    LOGDIR,
    paste0("R2_GSE198618_STEP2_LIMMA_SUPPORT_",
           format(Sys.time(),"%Y%m%d_%H%M%S"),"_previous.log")
  )
  file.rename(LOG,old)
}

logline <- function(...) {
  z <- paste0(format(Sys.time(),"%Y-%m-%d %H:%M:%S")," | ",
              paste0(...,collapse=""))
  cat(z,"\n",sep="")
  cat(z,"\n",file=LOG,append=TRUE,sep="")
  flush.console()
}
must <- function(x,msg) if(!isTRUE(x)) stop(msg,call.=FALSE)

awrite <- function(x,p) {
  t <- paste0(p,".tmp_",Sys.getpid())
  write.csv(x,t,row.names=FALSE,na="")
  if(file.exists(p)) unlink(p,force=TRUE)
  if(!file.rename(t,p)) {unlink(t); stop("Atomic CSV failed: ",p)}
}
twrite <- function(x,p) {
  t <- paste0(p,".tmp_",Sys.getpid())
  writeLines(x,t,useBytes=TRUE)
  if(file.exists(p)) unlink(p,force=TRUE)
  if(!file.rename(t,p)) {unlink(t); stop("Atomic text failed: ",p)}
}

logline("============================================================")
logline("R2 GSE198618 Step 2 — limma supporting fit")
logline("============================================================")

for(p in c(CONTRACT,MANIFEST,MAP25,MATRIX)) {
  must(file.exists(p),paste0("Missing required input: ",p))
}

ct <- readLines(CONTRACT,warn=FALSE)
must(ct[1]=="R2_GSE198618_MODEL_CONTRACT_FROZEN","Wrong contract gate")
required_contract <- c(
  "role=SUPPORTING_PAH_REPLICATION",
  "patient_overlap_with_GSE240921=UNKNOWN",
  "full_independence_claim_allowed=NO",
  "input_scale=AUTHOR_SUPPLIED_EDGE_R_CPM_NORMALIZED_NONINTEGER",
  "raw_count_model_allowed=NO",
  "transform=log2_CPM_plus_1",
  "analysis_engine=limma",
  "model=~ clinical_state",
  "reference=COMPENSATED",
  "contrast=DECOMPENSATED_vs_COMPENSATED",
  "empirical_bayes=eBayes_trend_TRUE",
  "genomewide_expression_filter=CPM_GE_1_IN_AT_LEAST_7_OF_32",
  "supporting_candidate_family=GSE240921_FINAL_PRIMARY25",
  "supporting_candidate_family_size=25",
  "support_FDR_family=FULL_25_PADDED",
  "unmapped_or_expression_unassessable_p=1",
  "support_FDR_method=BH",
  "support_FDR_alpha=0.05",
  "new_genes_can_be_added_to_PRIMARY25=NO",
  "model_fit_executed=NO",
  "candidate_outcome_testing_executed=NO"
)
for(z in required_contract) must(any(ct==z),paste0("Contract mismatch: ",z))

must(requireNamespace("limma",quietly=TRUE),"limma is unavailable")
logline("[INFO] limma version: ",as.character(utils::packageVersion("limma")))

m <- read.csv(MANIFEST,stringsAsFactors=FALSE,check.names=FALSE)
mp <- read.csv(MAP25,stringsAsFactors=FALSE,check.names=FALSE)

must(nrow(m)==32L,"Manifest row count must remain 32")
must(nrow(mp)==25L,"PRIMARY25 mapping must remain 25 rows")
must(sum(mp$mapping_status=="UNIQUE_MAPPED")==24L,
     "Expected 24 uniquely mapped PRIMARY25 genes")
must(sum(mp$mapping_status=="NOT_MAPPED")==1L,
     "Expected exactly 1 unmapped PRIMARY25 gene")
must(sum(as.logical(mp$expression_pass))==20L,
     "Expected exactly 20 expression-assessable PRIMARY25 genes")

logline("[INFO] Reading normalized CPM matrix.")
dat <- read.csv(gzfile(MATRIX,"rt"),stringsAsFactors=FALSE,check.names=FALSE)
must(nrow(dat)==19943L && ncol(dat)==33L,
     "Matrix dimensions changed")

sample_idx <- match(m$matrix_column,names(dat))
must(all(!is.na(sample_idx)) && length(unique(sample_idx))==32L,
     "Manifest-to-matrix mapping changed")
gene_idx <- setdiff(seq_along(dat),sample_idx)
must(length(gene_idx)==1L,"Expected exactly one gene-label column")
gene_label <- trimws(as.character(dat[[gene_idx]]))
must(length(unique(gene_label))==19943L,"Gene labels are no longer unique")

x <- do.call(cbind,lapply(dat[,sample_idx,drop=FALSE],
                          function(v) suppressWarnings(as.numeric(v))))
colnames(x) <- m$matrix_column
rownames(x) <- gene_label
must(all(is.finite(x)) && all(x>=0),
     "CPM matrix contains nonfinite or negative values")

# Frozen genome-wide expression filter.
keep <- rowSums(x>=1) >= 7L
must(sum(keep)>1000L,"Unexpectedly few genes pass frozen expression filter")
logline("[INFO] Genome-wide genes passing CPM>=1 in >=7 samples: ",sum(keep))

y <- log2(x[keep,,drop=FALSE] + 1)

m$clinical_state <- factor(
  m$clinical_state,
  levels=c("COMPENSATED","CONTROL","DECOMPENSATED")
)
design <- model.matrix(~ clinical_state,data=m)
must(qr(design)$rank==ncol(design),"Design matrix is not full rank")
coef_name <- "clinical_stateDECOMPENSATED"
must(coef_name %in% colnames(design),"Direct coefficient missing")

# One frozen limma fit.
t0 <- proc.time()[["elapsed"]]
fit0 <- limma::lmFit(y,design)
fit <- limma::eBayes(fit0,trend=TRUE)
runtime <- proc.time()[["elapsed"]] - t0

must(all(dim(fit$coefficients)==c(sum(keep),ncol(design))),
     "Unexpected fitted coefficient dimensions")

coef <- fit$coefficients[,coef_name]
tstat <- fit$t[,coef_name]
pval <- fit$p.value[,coef_name]

must(length(coef)==sum(keep),"Coefficient length mismatch")
must(all(is.finite(coef)),"Nonfinite limma coefficients found")
must(all(is.finite(tstat)),"Nonfinite limma t statistics found")
must(all(is.finite(pval)),"Nonfinite limma p-values found")
must(all(pval>=0 & pval<=1),"Invalid limma p-values")

gw <- data.frame(
  gse198618_gene_label=rownames(fit$coefficients),
  log2FC_DECOMP_vs_COMP=as.numeric(coef),
  moderated_t=as.numeric(tstat),
  pvalue=as.numeric(pval),
  aveExpr=as.numeric(fit$Amean),
  row_stringsAsFactors=FALSE
)
names(gw)[names(gw)=="row_stringsAsFactors"] <- "stringsAsFactors_placeholder"
gw$stringsAsFactors_placeholder <- NULL

# Genome-wide FDR is descriptive only, not used for PRIMARY25 support decisions.
gw$genomewide_BH_FDR <- p.adjust(gw$pvalue,method="BH")

con <- gzfile(GW,"wt")
write.csv(gw,con,row.names=FALSE,na="")
close(con)

saveRDS(
  list(
    fit=fit,
    design=design,
    manifest=m,
    keep=keep,
    limma_version=as.character(utils::packageVersion("limma")),
    contract=ct
  ),
  FIT_RDS
)

# --------------------------------------------------------------------------
# Exact frozen 25-gene supporting family.
# --------------------------------------------------------------------------

res <- mp
res$support_assessability <- "UNASSESSABLE"
res$r2_log2FC <- NA_real_
res$r2_moderated_t <- NA_real_
res$r2_pvalue_raw <- NA_real_
res$r2_p_for_BH25 <- 1
res$r2_BH_FDR_25 <- NA_real_
res$direction_concordant <- FALSE
res$nominal_directional_support <- FALSE
res$strict_support <- FALSE
res$strict_label <- "NO_STRICT_SUPPORT"

for(i in seq_len(nrow(res))) {
  if(res$mapping_status[i]!="UNIQUE_MAPPED") {
    res$support_assessability[i] <- "UNMAPPED_PAD_P1"
    next
  }
  if(!isTRUE(as.logical(res$expression_pass[i]))) {
    res$support_assessability[i] <- "LOW_EXPRESSION_PAD_P1"
    next
  }

  gi <- match(res$gse198618_gene_label[i],gw$gse198618_gene_label)
  if(is.na(gi)) {
    stop(paste0("Expression-pass mapped candidate absent from fitted genes: ",
                res$r0_gene_id[i]))
  }

  res$r2_log2FC[i] <- gw$log2FC_DECOMP_vs_COMP[gi]
  res$r2_moderated_t[i] <- gw$moderated_t[gi]
  res$r2_pvalue_raw[i] <- gw$pvalue[gi]

  if(is.finite(res$r2_pvalue_raw[i])) {
    res$support_assessability[i] <- "ASSESSABLE_LIMMA_FINITE"
    res$r2_p_for_BH25[i] <- res$r2_pvalue_raw[i]
  } else {
    res$support_assessability[i] <- "NONFINITE_P_PAD_P1"
  }
}

# Frozen full-25 BH, including padded P=1 rows.
res$r2_BH_FDR_25 <- p.adjust(res$r2_p_for_BH25,method="BH")

assess <- res$support_assessability=="ASSESSABLE_LIMMA_FINITE"
res$direction_concordant[assess] <-
  sign(res$r2_log2FC[assess]) == sign(res$frozen_r0_log2FC[assess])

res$nominal_directional_support <-
  assess &
  res$direction_concordant &
  res$r2_pvalue_raw < 0.05

res$strict_support <-
  assess &
  res$direction_concordant &
  res$r2_BH_FDR_25 < 0.05

res$strict_label[res$strict_support] <-
  "SUPPORTING_STRICT_SUPPORT_NOT_INDEPENDENT_REPLICATION"

# Never modify frozen PRIMARY25 membership.
res$added_to_PRIMARY25 <- "NO"

awrite(res,CAND)
awrite(res[res$strict_support,,drop=FALSE],STRICT)

summary <- data.frame(
  metric=c(
    "dataset",
    "role",
    "samples",
    "control",
    "compensated",
    "decompensated",
    "genomewide_filter_pass_genes",
    "limma_version",
    "fit_runtime_seconds",
    "PRIMARY25_family",
    "PRIMARY25_unique_mapped",
    "PRIMARY25_expression_assessable",
    "PRIMARY25_direction_concordant_among_assessable",
    "PRIMARY25_nominal_directional_support",
    "PRIMARY25_strict_support_full25_BH",
    "PRIMARY25_unmapped",
    "PRIMARY25_low_expression",
    "patient_overlap_with_GSE240921",
    "full_independence_claim_allowed",
    "PRIMARY25_modified"
  ),
  value=c(
    "GSE198618",
    "SUPPORTING_PAH_REPLICATION",
    32,14,11,7,
    sum(keep),
    as.character(utils::packageVersion("limma")),
    runtime,
    25,
    sum(res$mapping_status=="UNIQUE_MAPPED"),
    sum(assess),
    sum(res$direction_concordant & assess),
    sum(res$nominal_directional_support),
    sum(res$strict_support),
    sum(res$support_assessability=="UNMAPPED_PAD_P1"),
    sum(res$support_assessability=="LOW_EXPRESSION_PAD_P1"),
    "UNKNOWN",
    "NO",
    "NO"
  ),
  stringsAsFactors=FALSE
)
awrite(summary,SUMMARY)

twrite(c(
  "R2_GSE198618_STEP2_LIMMA_SUPPORT_PASS",
  paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
  "dataset=GSE198618",
  "role=SUPPORTING_PAH_REPLICATION",
  "patient_overlap_with_GSE240921=UNKNOWN",
  "full_independence_claim_allowed=NO",
  "input=AUTHOR_SUPPLIED_EDGE_R_CPM_NORMALIZED_NONINTEGER",
  "transform=log2_CPM_plus_1",
  "analysis_engine=limma",
  paste0("limma_version=",as.character(utils::packageVersion("limma"))),
  "model=~ clinical_state",
  "reference=COMPENSATED",
  "contrast=DECOMPENSATED_vs_COMPENSATED",
  "empirical_bayes=eBayes_trend_TRUE",
  "genomewide_filter=CPM_GE_1_IN_AT_LEAST_7_OF_32",
  paste0("genomewide_filter_pass_genes=",sum(keep)),
  "supporting_candidate_family=GSE240921_FINAL_PRIMARY25",
  "supporting_candidate_family_size=25",
  "support_FDR_family=FULL_25_PADDED",
  "support_FDR_method=BH",
  "support_FDR_alpha=0.05",
  "support_direction_requirement=SAME_UNSHRUNKEN_SIGN_AS_FROZEN_R0_R1",
  paste0("PRIMARY25_expression_assessable=",sum(assess)),
  paste0("PRIMARY25_direction_concordant=",sum(res$direction_concordant & assess)),
  paste0("PRIMARY25_nominal_directional_support=",
         sum(res$nominal_directional_support)),
  paste0("PRIMARY25_strict_support=",sum(res$strict_support)),
  "strict_R2_label=SUPPORTING_STRICT_SUPPORT_NOT_INDEPENDENT_REPLICATION",
  "new_genes_can_be_added_to_PRIMARY25=NO",
  "PRIMARY25_modified=NO",
  "status=PASS_READY_FOR_CHATGPT_AUDIT"
),GATE)

logline("[PASS] PRIMARY25 assessable: ",sum(assess),"/25")
logline("[PASS] Direction concordant: ",
        sum(res$direction_concordant & assess),"/",sum(assess))
logline("[PASS] Nominal directional support: ",
        sum(res$nominal_directional_support),"/25")
logline("[PASS] Strict supporting evidence: ",
        sum(res$strict_support),"/25")
logline("FINAL_GATE: R2_GSE198618_STEP2_LIMMA_SUPPORT_PASS")
quit(save="no",status=0,runLast=FALSE)
