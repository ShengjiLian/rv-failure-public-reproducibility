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
# RV Project — R1 GSE240921 Step 0 repaired preflight
#
# Repair basis:
#   The official workbook actually has:
#     - "info table"   : 146 x 15
#     - "count matrix" : 48,738 x 41
#   Therefore the original heuristic "metadata sheet must have exactly 40 rows"
#   was incorrect and is superseded.
#
# This repaired Step 0:
#   - uses exact official sheet names instead of the failed 40-row heuristic
#   - retains existing XLSX/SOFT; no redownload when already present
#   - exports the complete info table for later batch adjudication
#   - parses the 40 GEO sample blocks from SOFT
#   - reconstructs GEO accession -> count-matrix-column mapping
#   - verifies 13 normal/control + 14 compensated + 13 decompensated
#   - verifies the 40 sample columns in the count matrix exactly
#
# NO DESeq2 MODEL IS FITTED.
# NO DIFFERENTIAL EXPRESSION IS RUN.
# NO BATCH FORMULA IS FROZEN HERE.
# ==============================================================================

options(stringsAsFactors=FALSE, warn=1)

ROOT <- normalizePath(getwd(), winslash="/", mustWork=TRUE)
if (!identical(ROOT,RV_PROJECT_ROOT)) stop("Expected D:/RV_project")

user_lib <- file.path(Sys.getenv("LOCALAPPDATA"),"R","win-library","4.6")
if (dir.exists(user_lib)) .libPaths(unique(c(user_lib,.libPaths())))

if (!requireNamespace("readxl",quietly=TRUE)) {
  stop("readxl is required for the repaired preflight.")
}

DATA_DIR <- file.path(ROOT,"data","processed","GSE240921")
META_DIR <- file.path(ROOT,"data","metadata","GSE240921")
RES_DIR <- file.path(ROOT,"results","R1_GSE240921")
LOG_DIR <- file.path(ROOT,"logs")
dir.create(RES_DIR,recursive=TRUE,showWarnings=FALSE)
dir.create(LOG_DIR,recursive=TRUE,showWarnings=FALSE)

XLSX <- file.path(DATA_DIR,"GSE240921_processed-data-human.xlsx")
SOFT <- file.path(META_DIR,"GSE240921_family.soft.gz")

LOG <- file.path(LOG_DIR,"R1_GSE240921_STEP0_PREFLIGHT.log")
AUDIT <- file.path(RES_DIR,"R1_GSE240921_step0_audit.csv")
SHEETS <- file.path(RES_DIR,"R1_GSE240921_sheet_summary.csv")
INFO_RAW <- file.path(RES_DIR,"R1_GSE240921_info_table_raw.csv")
SOFT_MANIFEST <- file.path(RES_DIR,"R1_GSE240921_soft_sample_manifest.csv")
COUNT_SUMMARY <- file.path(RES_DIR,"R1_GSE240921_count_column_summary.csv")
MAPPING_AUDIT <- file.path(RES_DIR,"R1_GSE240921_sample_mapping_audit.csv")
PASS <- file.path(RES_DIR,"R1_GSE240921_STEP0_PREFLIGHT_PASS.txt")
OLD_HOLD <- file.path(RES_DIR,"R1_GSE240921_STEP0_PREFLIGHT_HOLD.txt")

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

audit_rows <- list()
add <- function(item,expected,observed,status,notes="") {
  rr <- data.frame(
    item=as.character(item),
    expected=as.character(expected),
    observed=as.character(observed),
    status=as.character(status),
    notes=as.character(notes),
    stringsAsFactors=FALSE
  )
  audit_rows[[length(audit_rows)+1L]] <<- rr
  logline("[",status,"] ",item," | expected=",expected," | observed=",observed)
}

logline("============================================================")
logline("R1 GSE240921 Step 0 repaired preflight")
logline("Exact sheet-name repair; no model fitting.")
logline("============================================================")

must(file.exists(XLSX) && file.info(XLSX)$size==9035174,
     "Processed workbook missing or byte size changed from audited 9,035,174.")
must(file.exists(SOFT) && file.info(SOFT)$size==5750,
     "Family SOFT missing or byte size changed from audited 5,750.")

add("processed workbook exact bytes","9035174",file.info(XLSX)$size,"PASS")
add("family SOFT exact bytes","5750",file.info(SOFT)$size,"PASS")
add("XLSX reader","readxl","readxl","PASS")

sheet_names <- readxl::excel_sheets(XLSX)
add("workbook sheet names","info table;count matrix",paste(sheet_names,collapse=";"),
    if(identical(sheet_names,c("info table","count matrix"))) "PASS" else "FAIL")

info <- as.data.frame(
  readxl::read_excel(XLSX,sheet="info table",.name_repair="unique"),
  stringsAsFactors=FALSE,check.names=FALSE
)
cnt <- as.data.frame(
  readxl::read_excel(XLSX,sheet="count matrix",.name_repair="unique"),
  stringsAsFactors=FALSE,check.names=FALSE
)

sheet_summary <- data.frame(
  sheet=c("info table","count matrix"),
  rows=c(nrow(info),nrow(cnt)),
  cols=c(ncol(info),ncol(cnt)),
  duplicated_column_names=c(sum(duplicated(names(info))),sum(duplicated(names(cnt)))),
  stringsAsFactors=FALSE
)
awrite(sheet_summary,SHEETS)

add("info table dimensions","146 x 15",paste(nrow(info),"x",ncol(info)),
    if(nrow(info)==146L && ncol(info)==15L) "PASS" else "FAIL")
add("count matrix dimensions","48738 x 41",paste(nrow(cnt),"x",ncol(cnt)),
    if(nrow(cnt)==48738L && ncol(cnt)==41L) "PASS" else "FAIL")
add("info table duplicate columns","0",sum(duplicated(names(info))),
    if(sum(duplicated(names(info)))==0L) "PASS" else "FAIL")
add("count matrix duplicate columns","0",sum(duplicated(names(cnt))),
    if(sum(duplicated(names(cnt)))==0L) "PASS" else "FAIL")

awrite(info,INFO_RAW)

# --------------------------------------------------------------------------
# Parse SOFT into 40 sample blocks.
# --------------------------------------------------------------------------

soft <- readLines(gzfile(SOFT,"rt"),warn=FALSE)
starts <- grep("^\\^SAMPLE = GSM",soft)
must(length(starts)==40L,"Expected exactly 40 SAMPLE blocks in SOFT.")

ends <- c(starts[-1]-1L,length(soft))
blocks <- Map(function(a,b) soft[a:b],starts,ends)

pick1 <- function(b,prefix) {
  x <- b[startsWith(b,prefix)]
  if(!length(x)) return(NA_character_)
  substring(x[1],nchar(prefix)+1L)
}
pick_all <- function(b,prefix) {
  x <- b[startsWith(b,prefix)]
  if(!length(x)) return(character())
  substring(x,nchar(prefix)+1L)
}

sample_rows <- lapply(blocks,function(b) {
  gsm <- sub("^\\^SAMPLE = ","",b[1])
  title <- pick1(b,"!Sample_title = ")
  desc <- paste(pick_all(b,"!Sample_description = "),collapse=" | ")
  proc <- paste(pick_all(b,"!Sample_data_processing = "),collapse=" | ")
  chars <- paste(pick_all(b,"!Sample_characteristics_ch1 = "),collapse=" | ")

  m <- regexec("count matrix column name:\\s*([^|]+)",desc,ignore.case=TRUE)
  mm <- regmatches(desc,m)[[1]]
  count_col <- if(length(mm)>=2) trimws(mm[2]) else NA_character_

  txt <- tolower(paste(title,chars,sep=" | "))
  state <- if(grepl("decompensated|failing",txt)) {
    "DECOMPENSATED"
  } else if(grepl("compensated|compen",txt)) {
    "COMPENSATED"
  } else if(grepl("control|normal",txt)) {
    "NORMAL_CONTROL"
  } else {
    NA_character_
  }

  data.frame(
    geo_accession=gsm,
    title=title,
    count_matrix_column=count_col,
    clinical_state=state,
    has_mapping_b2=grepl("mapping-b2",proc,ignore.case=TRUE),
    description=desc,
    characteristics=chars,
    stringsAsFactors=FALSE
  )
})

sm <- do.call(rbind,sample_rows)
awrite(sm,SOFT_MANIFEST)

add("SOFT sample blocks","40",nrow(sm),
    if(nrow(sm)==40L) "PASS" else "FAIL")
add("unique GEO accessions","40",length(unique(sm$geo_accession)),
    if(length(unique(sm$geo_accession))==40L) "PASS" else "FAIL")
add("unique count-matrix names parsed from SOFT","40",
    length(unique(sm$count_matrix_column[!is.na(sm$count_matrix_column)])),
    if(sum(!is.na(sm$count_matrix_column))==40L &&
       length(unique(sm$count_matrix_column))==40L) "PASS" else "FAIL")

state_tab <- table(factor(
  sm$clinical_state,
  levels=c("NORMAL_CONTROL","COMPENSATED","DECOMPENSATED")
))
add("Normal/Control samples","13",state_tab["NORMAL_CONTROL"],
    if(state_tab["NORMAL_CONTROL"]==13L) "PASS" else "FAIL")
add("Compensated samples","14",state_tab["COMPENSATED"],
    if(state_tab["COMPENSATED"]==14L) "PASS" else "FAIL")
add("Decompensated samples","13",state_tab["DECOMPENSATED"],
    if(state_tab["DECOMPENSATED"]==13L) "PASS" else "FAIL")
add("unclassified samples","0",sum(is.na(sm$clinical_state)),
    if(sum(is.na(sm$clinical_state))==0L) "PASS" else "FAIL")

# --------------------------------------------------------------------------
# Count matrix structure and exact sample-name set.
# --------------------------------------------------------------------------

count_names <- names(cnt)
gene_col <- count_names[1]
sample_cols <- count_names[-1]

add("count matrix sample columns","40",length(sample_cols),
    if(length(sample_cols)==40L) "PASS" else "FAIL")
add("count matrix sample names unique","40",length(unique(sample_cols)),
    if(length(unique(sample_cols))==40L) "PASS" else "FAIL")

map_ok <- setequal(sample_cols,sm$count_matrix_column)
add("SOFT count-column set equals workbook sample-column set","exact",
    if(map_ok) "exact" else "mismatch",
    if(map_ok) "PASS" else "FAIL")

mapping_audit <- data.frame(
  geo_accession=sm$geo_accession,
  title=sm$title,
  clinical_state=sm$clinical_state,
  count_matrix_column=sm$count_matrix_column,
  present_in_count_matrix=sm$count_matrix_column %in% sample_cols,
  count_matrix_column_index=match(sm$count_matrix_column,sample_cols),
  has_mapping_b2=sm$has_mapping_b2,
  stringsAsFactors=FALSE
)
awrite(mapping_audit,MAPPING_AUDIT)

# Validate count columns are numeric/nonnegative/integer-like.
count_summary <- do.call(rbind,lapply(seq_along(cnt),function(i) {
  v <- cnt[[i]]
  suppressWarnings(vn <- as.numeric(v))
  finite <- is.finite(vn)
  data.frame(
    column_index=i,
    column_name=names(cnt)[i],
    finite_numeric=sum(finite),
    nonnegative_numeric=sum(finite & vn>=0),
    integer_like_numeric=sum(finite & abs(vn-round(vn))<1e-8),
    numeric_fraction=sum(finite)/nrow(cnt),
    stringsAsFactors=FALSE
  )
}))
awrite(count_summary,COUNT_SUMMARY)

sample_num <- count_summary[-1,,drop=FALSE]
numeric_ok <- all(sample_num$numeric_fraction>=0.999)
nonneg_ok <- all(sample_num$nonnegative_numeric==nrow(cnt))
integer_ok <- all(sample_num$integer_like_numeric==nrow(cnt))

add("sample count columns numeric",">=99.9% each",
    min(sample_num$numeric_fraction),
    if(numeric_ok) "PASS" else "FAIL")
add("sample count columns nonnegative","all values",
    min(sample_num$nonnegative_numeric),
    if(nonneg_ok) "PASS" else "FAIL")
add("sample count columns integer-like","all values",
    min(sample_num$integer_like_numeric),
    if(integer_ok) "PASS" else "FAIL")

audit <- do.call(rbind,audit_rows)
awrite(audit,AUDIT)

fails <- sum(audit$status=="FAIL")

if(fails>0L) {
  twrite(c(
    "R1_GSE240921_STEP0_PREFLIGHT_HOLD_REPAIRED",
    paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
    paste0("hard_failures=",fails),
    "model_fit_executed=NO",
    "differential_expression_executed=NO",
    "batch_semantics_frozen=NO",
    "next_action=Return repaired audit outputs to ChatGPT."
  ),file.path(RES_DIR,"R1_GSE240921_STEP0_PREFLIGHT_REPAIRED_HOLD.txt"))
  logline("FINAL_GATE: R1_GSE240921_STEP0_PREFLIGHT_REPAIRED_HOLD")
  quit(save="no",status=34,runLast=FALSE)
}

# Preserve the old false HOLD as provenance if it still exists.
if(file.exists(OLD_HOLD)) {
  superseded <- file.path(
    RES_DIR,
    paste0("R1_GSE240921_STEP0_PREFLIGHT_HOLD_WORKBOOK_STRUCTURE_SUPERSEDED_",
           format(Sys.time(),"%Y%m%d_%H%M%S"),".txt")
  )
  file.rename(OLD_HOLD,superseded)
}

twrite(c(
  "R1_GSE240921_STEP0_PREFLIGHT_PASS",
  paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
  "repair=EXACT_OFFICIAL_SHEET_NAMES",
  "supersedes=FAILED_40_ROW_METADATA_SHEET_HEURISTIC",
  "dataset=GSE240921",
  "samples=40",
  "normal_control=13",
  "compensated=14",
  "decompensated=13",
  "info_table_dimensions=146x15",
  "count_matrix_dimensions=48738x41",
  "count_matrix_sample_columns=40",
  "SOFT_to_count_matrix_mapping=EXACT",
  "batch_semantics_frozen=NO",
  "model_formula_frozen=NO",
  "model_fit_executed=NO",
  "differential_expression_executed=NO",
  "next_stage=R1 Step 1 info-table/batch contract adjudication after ChatGPT audit"
),PASS)

logline("FINAL_GATE: R1_GSE240921_STEP0_PREFLIGHT_PASS")
quit(save="no",status=0,runLast=FALSE)
