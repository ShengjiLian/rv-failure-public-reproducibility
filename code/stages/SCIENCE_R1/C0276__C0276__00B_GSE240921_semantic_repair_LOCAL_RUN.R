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
# RV Project — R1 GSE240921 Step 0B
# Semantic repair of clinical-state classification + technical batch mapping
#
# WHY THIS EXISTS
#   The repaired Step 0 correctly established workbook/count/sample mapping,
#   but its broad text classifier misclassified exactly two samples because it
#   searched title + primary + secondary labels together.
#
# AUTHORITATIVE CLINICAL STATE FOR THIS STEP:
#   GEO field "primary disease_characterization"
#
# TECHNICAL BATCH CANDIDATE:
#   Author info-table FASTQ block:
#     Prakash_*  -> batch 1, single-end, n=15
#     US-*       -> batch 2, paired-end, n=25
#
# NO workbook reread
# NO count-matrix reread
# NO download
# NO DESeq2 model
# NO differential-expression analysis
# ==============================================================================

options(stringsAsFactors=FALSE, warn=1)

ROOT <- normalizePath(getwd(), winslash="/", mustWork=TRUE)
if (!identical(ROOT,RV_PROJECT_ROOT)) stop("Expected D:/RV_project")

RES <- file.path(ROOT,"results","R1_GSE240921")
LOGDIR <- file.path(ROOT,"logs")
dir.create(RES,recursive=TRUE,showWarnings=FALSE)
dir.create(LOGDIR,recursive=TRUE,showWarnings=FALSE)

AUD0 <- file.path(RES,"R1_GSE240921_step0_audit.csv")
INFO <- file.path(RES,"R1_GSE240921_info_table_raw.csv")
SOFT_MAN <- file.path(RES,"R1_GSE240921_soft_sample_manifest.csv")
MAP0 <- file.path(RES,"R1_GSE240921_sample_mapping_audit.csv")
COUNT0 <- file.path(RES,"R1_GSE240921_count_column_summary.csv")

OUT_MAN <- file.path(RES,"R1_GSE240921_sample_manifest_semantic_repair.csv")
OUT_CROSS <- file.path(RES,"R1_GSE240921_batch_state_crosscheck.csv")
OUT_AUD <- file.path(RES,"R1_GSE240921_step0_semantic_repair_audit.csv")
OUT_MIS <- file.path(RES,"R1_GSE240921_original_classifier_misclassified_samples.csv")
OUT_GATE <- file.path(RES,"R1_GSE240921_STEP0_SEMANTIC_REPAIR_PASS.txt")
LOG <- file.path(LOGDIR,"R1_GSE240921_STEP0B_SEMANTIC_REPAIR.log")

logline <- function(...) {
  z <- paste0(format(Sys.time(),"%Y-%m-%d %H:%M:%S")," | ",paste0(...,collapse=""))
  cat(z,"\n",sep="")
  cat(z,"\n",file=LOG,append=TRUE,sep="")
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

must(all(file.exists(c(AUD0,INFO,SOFT_MAN,MAP0,COUNT0))),
     "One or more required Step-0 outputs are missing.")

audit0 <- read.csv(AUD0,stringsAsFactors=FALSE,check.names=FALSE)
info <- read.csv(INFO,stringsAsFactors=FALSE,check.names=FALSE)
soft <- read.csv(SOFT_MAN,stringsAsFactors=FALSE,check.names=FALSE)
map0 <- read.csv(MAP0,stringsAsFactors=FALSE,check.names=FALSE)
cntsum <- read.csv(COUNT0,stringsAsFactors=FALSE,check.names=FALSE)

# --------------------------------------------------------------------------
# Bind exact prior HOLD signature: 19 PASS + exactly two semantic FAIL rows.
# --------------------------------------------------------------------------

must(nrow(audit0)==21L,"Expected 21 rows in prior Step-0 audit.")
must(sum(audit0$status=="PASS")==19L,"Expected 19 PASS rows in prior audit.")
must(sum(audit0$status=="FAIL")==2L,"Expected exactly two prior FAIL rows.")

bad <- audit0$item[audit0$status=="FAIL"]
must(setequal(bad,c("Compensated samples","Decompensated samples")),
     "Prior failures are not exactly the expected clinical-state classifier rows.")

obs_comp <- audit0$observed[audit0$item=="Compensated samples"]
obs_decomp <- audit0$observed[audit0$item=="Decompensated samples"]
must(as.integer(obs_comp)==12L && as.integer(obs_decomp)==15L,
     "Prior misclassification signature changed from 12 compensated / 15 decompensated.")

# Established structural invariants from Step 0.
must(nrow(soft)==40L,"SOFT manifest is not 40 rows.")
must(nrow(map0)==40L && all(as.logical(map0$present_in_count_matrix)),
     "Sample mapping audit is not exact 40/40.")
must(length(unique(map0$count_matrix_column))==40L,
     "Count-matrix sample names are not unique 40.")
must(nrow(cntsum)==41L,"Count-column summary must have 41 columns including gene id.")
must(all(cntsum$numeric_fraction[-1]>=0.999),
     "Count sample columns are no longer numeric.")
must(all(cntsum$nonnegative_numeric[-1]==48738L),
     "Count sample columns are no longer fully nonnegative.")
must(all(cntsum$integer_like_numeric[-1]==48738L),
     "Count sample columns are no longer fully integer-like.")

# --------------------------------------------------------------------------
# Correct clinical state using ONLY primary disease_characterization.
# --------------------------------------------------------------------------

extract_field <- function(x,field) {
  pat <- paste0("(?i)",field,":\\s*([^|]+)")
  m <- regexec(pat,x,perl=TRUE)
  z <- regmatches(x,m)
  vapply(z,function(q) if(length(q)>=2L) trimws(q[2]) else NA_character_,
         FUN.VALUE=character(1))
}

primary <- extract_field(soft$characteristics,"primary disease_characterization")
secondary <- extract_field(soft$characteristics,"secondary group_characterization")

state <- ifelse(
  tolower(primary)=="normal rv","NORMAL_CONTROL",
  ifelse(
    tolower(primary)=="compensated rv","COMPENSATED",
    ifelse(tolower(primary)=="decompensated rv","DECOMPENSATED",NA_character_)
  )
)

must(sum(is.na(state))==0L,"Some primary disease_characterization values are unclassified.")
must(sum(state=="NORMAL_CONTROL")==13L,"Primary-authority Normal count must be 13.")
must(sum(state=="COMPENSATED")==14L,"Primary-authority Compensated count must be 14.")
must(sum(state=="DECOMPENSATED")==13L,"Primary-authority Decompensated count must be 13.")

old_state <- as.character(soft$clinical_state)
mis_idx <- which(old_state != state)
must(length(mis_idx)==2L,"Expected exactly two samples corrected by primary-field authority.")

mis <- data.frame(
  geo_accession=soft$geo_accession[mis_idx],
  title=soft$title[mis_idx],
  count_matrix_column=soft$count_matrix_column[mis_idx],
  old_classifier_state=old_state[mis_idx],
  primary_disease_characterization=primary[mis_idx],
  secondary_group_characterization=secondary[mis_idx],
  corrected_state=state[mis_idx],
  stringsAsFactors=FALSE
)
awrite(mis,OUT_MIS)

must(setequal(mis$geo_accession,c("GSM7712111","GSM7712117")),
     "The two corrected GSM accessions are not the expected pair.")

# --------------------------------------------------------------------------
# Derive technical batch from the first author ID-MAPPING/FASTQ block.
# info table layout already audited as 146 x 15.
# Rows after CSV import:
#   row 1 (R index 1) has subheader id / cluster ids / fastq
#   next 40 rows are sample mappings.
# We identify them by exact count-matrix sample-name membership, not row number alone.
# --------------------------------------------------------------------------

must(nrow(info)==146L && ncol(info)==15L,"Info table dimensions changed.")

id_col <- names(info)[1]
cluster_col <- names(info)[2]
fastq1_col <- names(info)[3]
fastq2_col <- names(info)[4]

candidate <- info[
  as.character(info[[id_col]]) %in% soft$count_matrix_column,
  c(id_col,cluster_col,fastq1_col,fastq2_col),
  drop=FALSE
]

# The same sample IDs recur later in STAR/featureCounts sections.
# Keep only rows whose FASTQ1 field actually looks like an input FASTQ.
fq1 <- as.character(candidate[[fastq1_col]])
is_fastq_mapping <- grepl("\\.fastq$",fq1,ignore.case=TRUE)
idm <- candidate[is_fastq_mapping,,drop=FALSE]

names(idm) <- c("count_matrix_column","author_cluster_id","fastq1","fastq2")
must(nrow(idm)==40L,"Expected exactly 40 author FASTQ mapping rows.")
must(length(unique(idm$count_matrix_column))==40L,
     "Author FASTQ mapping does not uniquely cover 40 sample columns.")
must(setequal(idm$count_matrix_column,soft$count_matrix_column),
     "Author FASTQ mapping sample set differs from GEO/count matrix.")

batch <- ifelse(
  grepl("^Prakash_",idm$fastq1),"BATCH1_PRAKASH_SINGLE_END",
  ifelse(grepl("^US-",idm$fastq1),"BATCH2_US_PAIRED_END",NA_character_)
)
must(sum(is.na(batch))==0L,"Unexpected FASTQ naming outside Prakash_/US-.")

paired <- !is.na(idm$fastq2) & nzchar(trimws(as.character(idm$fastq2)))
must(sum(batch=="BATCH1_PRAKASH_SINGLE_END")==15L,"Batch1 size must be 15.")
must(sum(batch=="BATCH2_US_PAIRED_END")==25L,"Batch2 size must be 25.")
must(all(!paired[batch=="BATCH1_PRAKASH_SINGLE_END"]),
     "Prakash batch expected single-end.")
must(all(paired[batch=="BATCH2_US_PAIRED_END"]),
     "US batch expected paired-end.")

idm$technical_batch <- batch
idm$paired_end <- paired

# Merge in GEO order.
m <- merge(
  data.frame(
    geo_accession=soft$geo_accession,
    title=soft$title,
    count_matrix_column=soft$count_matrix_column,
    primary_disease_characterization=primary,
    secondary_group_characterization=secondary,
    clinical_state=state,
    sex=extract_field(soft$characteristics,"Sex"),
    stringsAsFactors=FALSE
  ),
  idm,
  by="count_matrix_column",
  all.x=TRUE,
  sort=FALSE
)

# Restore exact GEO order.
m <- m[match(soft$count_matrix_column,m$count_matrix_column),,drop=FALSE]
must(nrow(m)==40L && all(!is.na(m$technical_batch)),
     "Final semantic manifest is not complete 40/40.")

# Batch x state crossing must establish estimability of later batch-adjusted state model.
cross <- as.data.frame.matrix(table(m$technical_batch,m$clinical_state))
cross$technical_batch <- rownames(cross)
rownames(cross) <- NULL
cross <- cross[,c("technical_batch","NORMAL_CONTROL","COMPENSATED","DECOMPENSATED")]
awrite(cross,OUT_CROSS)

b1 <- cross[cross$technical_batch=="BATCH1_PRAKASH_SINGLE_END",]
b2 <- cross[cross$technical_batch=="BATCH2_US_PAIRED_END",]

must(b1$NORMAL_CONTROL==5L && b1$COMPENSATED==5L && b1$DECOMPENSATED==5L,
     "Batch1 state distribution must be 5/5/5.")
must(b2$NORMAL_CONTROL==8L && b2$COMPENSATED==9L && b2$DECOMPENSATED==8L,
     "Batch2 state distribution must be 8/9/8.")

awrite(m,OUT_MAN)

# --------------------------------------------------------------------------
# Repair audit
# --------------------------------------------------------------------------

aud <- data.frame(
  item=c(
    "prior audit PASS rows",
    "prior audit semantic FAIL rows",
    "primary-authority Normal/Control",
    "primary-authority Compensated",
    "primary-authority Decompensated",
    "samples corrected vs old broad classifier",
    "corrected GSM set",
    "author FASTQ mapping rows",
    "author FASTQ mapping exact sample set",
    "technical batch1 size",
    "technical batch2 size",
    "batch1 state crossing N/C/D",
    "batch2 state crossing N/C/D",
    "count mapping retained 40/40",
    "count columns retained numeric/nonnegative/integer-like",
    "model fit executed",
    "differential expression executed"
  ),
  expected=c(
    "19","2","13","14","13","2",
    "GSM7712111;GSM7712117",
    "40","exact","15","25","5/5/5","8/9/8",
    "40/40","PASS","NO","NO"
  ),
  observed=c(
    sum(audit0$status=="PASS"),
    sum(audit0$status=="FAIL"),
    sum(state=="NORMAL_CONTROL"),
    sum(state=="COMPENSATED"),
    sum(state=="DECOMPENSATED"),
    length(mis_idx),
    paste(sort(mis$geo_accession),collapse=";"),
    nrow(idm),
    if(setequal(idm$count_matrix_column,soft$count_matrix_column)) "exact" else "mismatch",
    sum(batch=="BATCH1_PRAKASH_SINGLE_END"),
    sum(batch=="BATCH2_US_PAIRED_END"),
    paste(b1$NORMAL_CONTROL,b1$COMPENSATED,b1$DECOMPENSATED,sep="/"),
    paste(b2$NORMAL_CONTROL,b2$COMPENSATED,b2$DECOMPENSATED,sep="/"),
    paste0(sum(as.logical(map0$present_in_count_matrix)),"/40"),
    if(all(cntsum$numeric_fraction[-1]>=0.999) &&
       all(cntsum$nonnegative_numeric[-1]==48738L) &&
       all(cntsum$integer_like_numeric[-1]==48738L)) "PASS" else "FAIL",
    "NO","NO"
  ),
  status="PASS",
  stringsAsFactors=FALSE
)

awrite(aud,OUT_AUD)

twrite(c(
  "R1_GSE240921_STEP0_SEMANTIC_REPAIR_PASS",
  paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
  "supersedes=STEP0_BROAD_TEXT_CLINICAL_STATE_CLASSIFIER_ONLY",
  "clinical_state_authority=GEO_PRIMARY_DISEASE_CHARACTERIZATION",
  "normal_control=13",
  "compensated=14",
  "decompensated=13",
  "corrected_samples=GSM7712111;GSM7712117",
  "technical_batch_authority=AUTHOR_INFO_TABLE_FASTQ_MAPPING",
  "batch1=BATCH1_PRAKASH_SINGLE_END",
  "batch1_n=15",
  "batch1_state_distribution=5_normal_5_compensated_5_decompensated",
  "batch2=BATCH2_US_PAIRED_END",
  "batch2_n=25",
  "batch2_state_distribution=8_normal_9_compensated_8_decompensated",
  "sample_to_count_matrix_mapping=EXACT_40_OF_40",
  "count_matrix_reprocessed=NO",
  "workbook_reread=NO",
  "download_executed=NO",
  "model_formula_frozen=NO",
  "model_fit_executed=NO",
  "differential_expression_executed=NO",
  "next_stage=ChatGPT audit then R1 Step 1 model-contract freeze"
),OUT_GATE)

logline("Corrected samples: ",paste(sort(mis$geo_accession),collapse=";"))
logline("Clinical states: 13 normal / 14 compensated / 13 decompensated")
logline("Technical batches: 15 Prakash single-end / 25 US paired-end")
logline("FINAL_GATE: R1_GSE240921_STEP0_SEMANTIC_REPAIR_PASS")
quit(save="no",status=0,runLast=FALSE)
