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
# RV Project — R2 GSE198618 Step 1
# SUPPORTING-REPLICATION MODEL CONTRACT + PRIMARY25 MAPPING PREFLIGHT
#
# NO differential-expression model is fitted in this step.
#
# Dataset role:
#   SUPPORTING_PAH_REPLICATION
#   Patient overlap with GSE240921 remains UNKNOWN.
#   Therefore this dataset cannot be described as a fully independent
#   validation cohort.
#
# Frozen intended analysis:
#   data       : author-supplied edgeR CPM-normalized matrix
#   transform  : log2(CPM + 1)
#   model      : limma ~ clinical_state, all 32 samples
#   reference  : COMPENSATED
#   contrast   : DECOMPENSATED vs COMPENSATED
#   eBayes     : trend=TRUE
#
# Why not DESeq2/edgeR count GLM:
#   the public matrix is non-integer normalized CPM, not raw counts.
#
# Supporting candidate family:
#   EXACT frozen GSE240921 FINAL PRIMARY25.
#   R2 cannot add new genes to that core set.
#
# Expression assessability, frozen before outcome testing:
#   CPM >= 1 in at least 7 of the 32 samples
#   (7 = smallest clinical group size).
#
# Supporting strict evidence, to be used only after later fitting:
#   - unique gene mapping
#   - expression assessability passed
#   - finite limma p-value
#   - same unshrunk log2FC sign as the frozen R0/R1 direction
#   - BH-FDR < 0.05 across the FULL 25-gene family
#   - unmapped/unassessable p is padded to 1
#
# Because overlap with GSE240921 is unknown, even strict evidence here is
# "SUPPORTING", not a new independent replication claim.
# ==============================================================================

options(stringsAsFactors=FALSE, warn=1)

ROOT <- normalizePath(getwd(), winslash="/", mustWork=TRUE)
if (!identical(ROOT,RV_PROJECT_ROOT)) stop("Expected D:/RV_project")

RES <- file.path(ROOT,"results","R2_GSE198618")
R1RES <- file.path(ROOT,"results","R1_GSE240921")
DATA <- file.path(ROOT,"data","processed","GSE198618")
LOGDIR <- file.path(ROOT,"logs")
dir.create(LOGDIR,recursive=TRUE,showWarnings=FALSE)

STEP0 <- file.path(RES,"R2_GSE198618_STEP0_PREFLIGHT_PASS.txt")
MANIFEST <- file.path(RES,"R2_GSE198618_sample_manifest.csv")
FIELDS <- file.path(RES,"R2_GSE198618_characteristics_field_summary.csv")
OVERLAP <- file.path(RES,"R2_GSE198618_vs_GSE240921_overlap_audit.csv")
MATRIX <- file.path(DATA,"GSE198618_Normalized_Counts_RV_ALL.csv.gz")
PRIMARY25 <- file.path(R1RES,"R1_GSE240921_FINAL_PRIMARY25.csv")
TX2GENE <- file.path(ROOT,"data","tximport","GSE345645",
                    "GSE345645_transcript_to_gene.csv.gz")

OUT_AUD <- file.path(RES,"R2_GSE198618_step1_model_contract_audit.csv")
OUT_GENE <- file.path(RES,"R2_GSE198618_gene_label_diagnostic.csv")
OUT_MAP <- file.path(RES,"R2_GSE198618_PRIMARY25_mapping.csv")
OUT_MAPSUM <- file.path(RES,"R2_GSE198618_PRIMARY25_mapping_summary.csv")
OUT_DESIGN <- file.path(RES,"R2_GSE198618_design_matrix_audit.csv")
OUT_CONTRACT <- file.path(RES,"R2_GSE198618_MODEL_CONTRACT_FROZEN.txt")
OUT_HOLD <- file.path(RES,"R2_GSE198618_STEP1_MODEL_CONTRACT_HOLD.txt")
LOG <- file.path(LOGDIR,"R2_GSE198618_STEP1_MODEL_CONTRACT.log")

if(file.exists(LOG)) {
  old <- file.path(
    LOGDIR,
    paste0("R2_GSE198618_STEP1_MODEL_CONTRACT_",
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

A <- list()
add <- function(item,expected,observed,status,notes="") {
  A[[length(A)+1L]] <<- data.frame(
    item=as.character(item),
    expected=as.character(expected),
    observed=as.character(observed),
    status=as.character(status),
    notes=as.character(notes),
    stringsAsFactors=FALSE
  )
  logline("[",status,"] ",item," | expected=",expected,
          " | observed=",observed)
}

logline("============================================================")
logline("R2 GSE198618 Step 1 — model contract + PRIMARY25 mapping")
logline("NO differential-expression fit.")
logline("============================================================")

for(p in c(STEP0,MANIFEST,FIELDS,OVERLAP,MATRIX,PRIMARY25)) {
  must(file.exists(p),paste0("Missing required input: ",p))
}

g0 <- readLines(STEP0,warn=FALSE)
must(g0[1]=="R2_GSE198618_STEP0_PREFLIGHT_PASS",
     "Unexpected Step0 gate")
must(any(g0=="human_RV_samples=32"),"Step0 sample total changed")
must(any(g0=="control=14"),"Step0 control count changed")
must(any(g0=="compensated=11"),"Step0 compensated count changed")
must(any(g0=="decompensated=7"),"Step0 decompensated count changed")
must(any(g0=="data_scale=NORMALIZED_NONINTEGER_CPM_COMPATIBLE"),
     "Step0 data-scale authority changed")
must(any(g0=="patient_overlap_with_GSE240921=UNKNOWN"),
     "Overlap status changed")
must(any(g0=="full_independence_claim_allowed=NO"),
     "Independence rule changed")

m <- read.csv(MANIFEST,stringsAsFactors=FALSE,check.names=FALSE)
fields <- read.csv(FIELDS,stringsAsFactors=FALSE,check.names=FALSE)
ov <- read.csv(OVERLAP,stringsAsFactors=FALSE,check.names=FALSE)

must(nrow(m)==32L,"Manifest must contain 32 samples")
must(length(unique(m$matrix_column))==32L,"Matrix sample names must be unique")
must(all(!is.na(m$matrix_column)),"All samples must map to matrix columns")

# Metadata authority: public SOFT contains only condition and tissue.
field_names <- tolower(as.character(fields$field))
has_sex <- any(grepl("^sex$",field_names))
has_batch <- any(grepl("batch",field_names))

add("sample manifest rows","32",nrow(m),
    if(nrow(m)==32L) "PASS" else "FAIL")
add("clinical state counts","14/11/7",
    paste(
      sum(m$clinical_state=="CONTROL"),
      sum(m$clinical_state=="COMPENSATED"),
      sum(m$clinical_state=="DECOMPENSATED"),
      sep="/"
    ),
    if(sum(m$clinical_state=="CONTROL")==14L &&
       sum(m$clinical_state=="COMPENSATED")==11L &&
       sum(m$clinical_state=="DECOMPENSATED")==7L) "PASS" else "FAIL")
add("public sex covariate available","FALSE",has_sex,
    if(!has_sex) "PASS" else "FAIL")
add("public batch covariate available","FALSE",has_batch,
    if(!has_batch) "PASS" else "FAIL")
add("patient overlap status","PATIENT_OVERLAP_UNKNOWN",
    ov$value[ov$item=="patient_level_overlap_status"],
    if(any(ov$value[ov$item=="patient_level_overlap_status"]==
           "PATIENT_OVERLAP_UNKNOWN")) "PASS" else "FAIL")

# --------------------------------------------------------------------------
# Read normalized CPM matrix and identify exact gene-label column.
# --------------------------------------------------------------------------

logline("[INFO] Reading local normalized CPM matrix.")
mat <- read.csv(gzfile(MATRIX,"rt"),stringsAsFactors=FALSE,check.names=FALSE)
must(nrow(mat)==19943L && ncol(mat)==33L,
     "Matrix dimensions changed from Step0")

sample_idx <- match(m$matrix_column,names(mat))
must(all(!is.na(sample_idx)) && length(unique(sample_idx))==32L,
     "Manifest-to-matrix sample mapping changed")

gene_idx <- setdiff(seq_along(mat),sample_idx)
must(length(gene_idx)==1L,"Expected exactly one non-sample gene-label column")
gene_col_name <- names(mat)[gene_idx]
gene_label <- trimws(as.character(mat[[gene_idx]]))

must(length(gene_label)==19943L,"Gene-label vector length changed")
must(all(!is.na(gene_label) & nzchar(gene_label)),
     "Gene-label column contains blank values")

gene_noversion <- sub("\\.[0-9]+$","",gene_label)
ensg_fraction <- mean(grepl("^ENSG[0-9]+$",gene_noversion))
symbol_fraction <- mean(grepl("^[A-Za-z][A-Za-z0-9._-]*$",gene_label))
gene_unique <- length(unique(gene_label))
gene_noversion_unique <- length(unique(gene_noversion))

id_mode <- if(ensg_fraction>=0.90) {
  "ENSEMBL_GENE_ID"
} else {
  "DIRECT_GENE_LABEL"
}

gdiag <- data.frame(
  metric=c(
    "gene_column_index",
    "gene_column_name",
    "gene_rows",
    "gene_labels_unique",
    "gene_noVersion_unique",
    "fraction_ENSG_like",
    "fraction_symbol_like",
    "identifier_mode",
    "example_1","example_2","example_3","example_4","example_5"
  ),
  value=c(
    gene_idx,gene_col_name,length(gene_label),gene_unique,
    gene_noversion_unique,ensg_fraction,symbol_fraction,id_mode,
    head(gene_label,5)
  ),
  stringsAsFactors=FALSE
)
awrite(gdiag,OUT_GENE)

add("gene rows","19943",length(gene_label),
    if(length(gene_label)==19943L) "PASS" else "FAIL")
add("gene labels unique","19943",gene_unique,
    if(gene_unique==19943L) "PASS" else "FAIL")
add("gene identifier mode","deterministically classified",id_mode,"PASS")

# --------------------------------------------------------------------------
# Frozen PRIMARY25 family from GSE240921 terminal authority.
# --------------------------------------------------------------------------

p25 <- read.csv(PRIMARY25,stringsAsFactors=FALSE,check.names=FALSE)
must(nrow(p25)==25L,"GSE240921 FINAL PRIMARY25 must contain 25 rows")
must(length(unique(p25$r0_gene_id))==25L,
     "GSE240921 PRIMARY25 symbols must be unique")
must(all(as.logical(p25$primary_replicated)),
     "Every GSE240921 FINAL PRIMARY25 row must be primary replicated")
must(all(is.finite(as.numeric(p25$r0_log2FC))) &&
     all(as.numeric(p25$r0_log2FC)!=0),
     "Frozen R0 directions missing in PRIMARY25")

cand <- data.frame(
  r0_gene_id=as.character(p25$r0_gene_id),
  frozen_r0_log2FC=as.numeric(p25$r0_log2FC),
  frozen_direction=ifelse(as.numeric(p25$r0_log2FC)>0,
                          "UP","DOWN"),
  mapping_status=NA_character_,
  gse198618_gene_label=NA_character_,
  expression_pass=FALSE,
  expression_rule="CPM_GE_1_IN_AT_LEAST_7_OF_32",
  n_samples_CPM_ge_1=NA_integer_,
  stringsAsFactors=FALSE
)

# Matrix sample numeric values.
x <- mat[,sample_idx,drop=FALSE]
num <- do.call(cbind,lapply(x,function(v) suppressWarnings(as.numeric(v))))
rownames(num) <- gene_label
colnames(num) <- m$matrix_column
must(all(is.finite(num)) && all(num>=0),
     "Normalized CPM matrix contains nonfinite/negative sample values")

# Candidate mapping.
if(id_mode=="ENSEMBL_GENE_ID") {
  must(file.exists(TX2GENE),
       "Ensembl IDs detected but local frozen tx2gene mapping is missing")
  tx <- read.csv(gzfile(TX2GENE),stringsAsFactors=FALSE,check.names=FALSE)

  gc <- c("ensembl_gene_id","gene_id","ensembl_gene_id_version")
  sc <- c("external_gene_name","gene_symbol","symbol")
  gc <- gc[gc %in% names(tx)]
  sc <- sc[sc %in% names(tx)]
  must(length(gc)>=1L && length(sc)>=1L,
       "Frozen tx2gene lacks usable gene/symbol columns")

  gcol <- gc[1]
  scol <- sc[1]
  tx_gene <- sub("\\.[0-9]+$","",as.character(tx[[gcol]]))
  tx_sym <- trimws(as.character(tx[[scol]]))
  ok <- !is.na(tx_gene) & nzchar(tx_gene) &
        !is.na(tx_sym) & nzchar(tx_sym)
  mp <- unique(data.frame(
    ensembl=tx_gene[ok],
    symbol=tx_sym[ok],
    stringsAsFactors=FALSE
  ))
  count_ens <- gene_noversion

  for(i in seq_len(nrow(cand))) {
    ids <- unique(mp$ensembl[
      mp$symbol==cand$r0_gene_id[i] &
      mp$ensembl %in% count_ens
    ])
    if(length(ids)==1L) {
      rows <- which(count_ens==ids)
      if(length(rows)==1L) {
        cand$mapping_status[i] <- "UNIQUE_MAPPED"
        cand$gse198618_gene_label[i] <- gene_label[rows]
      } else {
        cand$mapping_status[i] <- "AMBIGUOUS_MULTIPLE_MATRIX_ROWS"
      }
    } else if(length(ids)==0L) {
      cand$mapping_status[i] <- "NOT_MAPPED"
    } else {
      cand$mapping_status[i] <- "AMBIGUOUS_MULTIPLE_ENSEMBL_IDS"
    }
  }
  mapping_authority <- paste0("FROZEN_TX2GENE_",gcol,"_TO_",scol)

} else {
  # Direct exact gene-label matching; case-sensitive to avoid alias guessing.
  for(i in seq_len(nrow(cand))) {
    hits <- which(gene_label==cand$r0_gene_id[i])
    if(length(hits)==1L) {
      cand$mapping_status[i] <- "UNIQUE_MAPPED"
      cand$gse198618_gene_label[i] <- gene_label[hits]
    } else if(length(hits)==0L) {
      cand$mapping_status[i] <- "NOT_MAPPED"
    } else {
      cand$mapping_status[i] <- "AMBIGUOUS_MULTIPLE_MATRIX_ROWS"
    }
  }
  mapping_authority <- "DIRECT_EXACT_GENE_LABEL"
}

# Frozen expression assessability: >=1 CPM in >=7 of ALL 32 samples.
mapped <- which(cand$mapping_status=="UNIQUE_MAPPED")
for(i in mapped) {
  ri <- match(cand$gse198618_gene_label[i],rownames(num))
  must(!is.na(ri),"Mapped candidate disappeared from CPM matrix")
  n_ge1 <- sum(num[ri,]>=1)
  cand$n_samples_CPM_ge_1[i] <- n_ge1
  cand$expression_pass[i] <- n_ge1>=7L
}

awrite(cand,OUT_MAP)

mapsum <- data.frame(
  metric=c(
    "PRIMARY25_family",
    "unique_mapped",
    "not_mapped",
    "ambiguous",
    "expression_pass_among_unique_mapped",
    "expression_fail_among_unique_mapped"
  ),
  value=c(
    25,
    sum(cand$mapping_status=="UNIQUE_MAPPED"),
    sum(cand$mapping_status=="NOT_MAPPED"),
    sum(grepl("^AMBIGUOUS",cand$mapping_status)),
    sum(cand$mapping_status=="UNIQUE_MAPPED" & cand$expression_pass),
    sum(cand$mapping_status=="UNIQUE_MAPPED" & !cand$expression_pass)
  ),
  stringsAsFactors=FALSE
)
awrite(mapsum,OUT_MAPSUM)

add("frozen supporting candidate family","25",nrow(cand),
    if(nrow(cand)==25L) "PASS" else "FAIL")
add("candidate ambiguous mappings","0",
    sum(grepl("^AMBIGUOUS",cand$mapping_status)),
    if(sum(grepl("^AMBIGUOUS",cand$mapping_status))==0L) "PASS" else "FAIL")
add("unique candidate mappings","informational",
    sum(cand$mapping_status=="UNIQUE_MAPPED"),"PASS")
add("expression-assessable candidates","informational",
    sum(cand$mapping_status=="UNIQUE_MAPPED" & cand$expression_pass),"PASS")

# --------------------------------------------------------------------------
# Frozen design: all 32 samples, no invented covariates.
# --------------------------------------------------------------------------

m$clinical_state <- factor(
  m$clinical_state,
  levels=c("COMPENSATED","CONTROL","DECOMPENSATED")
)
X <- model.matrix(~ clinical_state,data=m)
design_audit <- data.frame(
  model="~ clinical_state",
  samples=nrow(X),
  columns=ncol(X),
  rank=qr(X)$rank,
  full_rank=qr(X)$rank==ncol(X),
  reference="COMPENSATED",
  direct_coefficient="clinical_stateDECOMPENSATED",
  stringsAsFactors=FALSE
)
awrite(design_audit,OUT_DESIGN)

add("supporting design full rank","TRUE",design_audit$full_rank,
    if(isTRUE(design_audit$full_rank)) "PASS" else "FAIL")

# Package availability: discover now; never install automatically.
limma_available <- requireNamespace("limma",quietly=TRUE)
limma_version <- if(limma_available) {
  as.character(utils::packageVersion("limma"))
} else {
  "MISSING"
}
add("limma package","available",limma_version,
    if(limma_available) "PASS" else "HOLD",
    "No automatic package installation.")

audit <- do.call(rbind,A)
awrite(audit,OUT_AUD)

hard_fail <- sum(audit$status=="FAIL")
holds <- sum(audit$status=="HOLD")

# Freeze scientific contract even if the local limma package is missing.
twrite(c(
  "R2_GSE198618_MODEL_CONTRACT_FROZEN",
  paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
  "dataset=GSE198618",
  "role=SUPPORTING_PAH_REPLICATION",
  "patient_overlap_with_GSE240921=UNKNOWN",
  "full_independence_claim_allowed=NO",
  "samples=32",
  "control=14",
  "compensated=11",
  "decompensated=7",
  "public_sex_covariate_available=NO",
  "public_batch_covariate_available=NO",
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
  paste0("gene_mapping_authority=",mapping_authority),
  paste0("candidate_unique_mapped=",
         sum(cand$mapping_status=="UNIQUE_MAPPED")),
  paste0("candidate_expression_assessable=",
         sum(cand$mapping_status=="UNIQUE_MAPPED" & cand$expression_pass)),
  "support_FDR_family=FULL_25_PADDED",
  "unmapped_or_expression_unassessable_p=1",
  "support_FDR_method=BH",
  "support_FDR_alpha=0.05",
  "support_direction_requirement=SAME_UNSHRUNKEN_SIGN_AS_FROZEN_R0_R1",
  "strict_R2_label=SUPPORTING_STRICT_SUPPORT_NOT_INDEPENDENT_REPLICATION",
  "nominal_directional_support_role=SECONDARY",
  "new_genes_can_be_added_to_PRIMARY25=NO",
  paste0("limma_available=",limma_available),
  paste0("limma_version=",limma_version),
  "model_fit_executed=NO",
  "candidate_outcome_testing_executed=NO",
  "next_stage=R2 Step2 limma supporting fit after ChatGPT audit"
),OUT_CONTRACT)

if(hard_fail>0L || holds>0L) {
  twrite(c(
    "R2_GSE198618_STEP1_MODEL_CONTRACT_HOLD",
    paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
    paste0("hard_failures=",hard_fail),
    paste0("hold_items=",holds),
    paste0("limma_available=",limma_available),
    "scientific_contract_written=YES",
    "model_fit_executed=NO",
    "next_action=Return Step1 outputs to ChatGPT; do not fit."
  ),OUT_HOLD)
  logline("FINAL_GATE: R2_GSE198618_STEP1_MODEL_CONTRACT_HOLD")
  quit(save="no",status=71,runLast=FALSE)
}

logline("FINAL_GATE: R2_GSE198618_MODEL_CONTRACT_FROZEN")
quit(save="no",status=0,runLast=FALSE)
