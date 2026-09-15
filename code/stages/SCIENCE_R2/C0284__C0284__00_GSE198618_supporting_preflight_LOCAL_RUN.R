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
# RV Project — R2 GSE198618 Step 0
# SUPPORTING PAH REPLICATION: ACQUISITION + STRUCTURAL/METADATA PREFLIGHT ONLY
#
# Dataset role is frozen here as SUPPORTING, not an additional fully
# independent validation cohort, because patient overlap with GSE240921
# remains unknown.
#
# Public GEO facts expected:
#   32 human RV samples:
#     14 Control
#     11 Compensated
#      7 Decompensated
#
# Public processed file:
#   GSE198618_Normalized_Counts_RV_ALL.csv.gz
# GEO states these are RSEM raw counts normalized by edgeR CPM.
#
# THIS STEP DOES NOT:
#   - fit limma/DESeq2/edgeR models
#   - test R0/R1 candidate genes
#   - calculate replication statistics
#   - assume patient independence from GSE240921
#   - download SRA raw FASTQ/BAM data
# ==============================================================================

options(stringsAsFactors=FALSE, warn=1)

ROOT <- normalizePath(getwd(), winslash="/", mustWork=TRUE)
if (!identical(ROOT,RV_PROJECT_ROOT)) stop("Expected D:/RV_project")

DATA_DIR <- file.path(ROOT,"data","processed","GSE198618")
META_DIR <- file.path(ROOT,"data","metadata","GSE198618")
RES_DIR  <- file.path(ROOT,"results","R2_GSE198618")
LOG_DIR  <- file.path(ROOT,"logs")
dir.create(DATA_DIR,recursive=TRUE,showWarnings=FALSE)
dir.create(META_DIR,recursive=TRUE,showWarnings=FALSE)
dir.create(RES_DIR, recursive=TRUE,showWarnings=FALSE)
dir.create(LOG_DIR, recursive=TRUE,showWarnings=FALSE)

NORM <- file.path(DATA_DIR,"GSE198618_Normalized_Counts_RV_ALL.csv.gz")
SOFT <- file.path(META_DIR,"GSE198618_family.soft.gz")

NORM_URL <- paste0(
  "https://www.ncbi.nlm.nih.gov/geo/download/?acc=GSE198618",
  "&file=GSE198618_Normalized_Counts_RV_ALL.csv.gz&format=file"
)
SOFT_URL <- paste0(
  "https://ftp.ncbi.nlm.nih.gov/geo/series/GSE198nnn/",
  "GSE198618/soft/GSE198618_family.soft.gz"
)

LOG <- file.path(LOG_DIR,"R2_GSE198618_STEP0_PREFLIGHT.log")
AUDIT <- file.path(RES_DIR,"R2_GSE198618_step0_audit.csv")
MANIFEST <- file.path(RES_DIR,"R2_GSE198618_sample_manifest.csv")
META_LONG <- file.path(RES_DIR,"R2_GSE198618_characteristics_long.csv")
META_FIELDS <- file.path(RES_DIR,"R2_GSE198618_characteristics_field_summary.csv")
COLSUM <- file.path(RES_DIR,"R2_GSE198618_matrix_column_summary.csv")
GENEDIAG <- file.path(RES_DIR,"R2_GSE198618_gene_id_diagnostic.csv")
OVERLAP <- file.path(RES_DIR,"R2_GSE198618_vs_GSE240921_overlap_audit.csv")
DOWNLOADS <- file.path(RES_DIR,"R2_GSE198618_download_manifest.csv")
PASS <- file.path(RES_DIR,"R2_GSE198618_STEP0_PREFLIGHT_PASS.txt")
HOLD <- file.path(RES_DIR,"R2_GSE198618_STEP0_PREFLIGHT_HOLD.txt")

if(file.exists(LOG)) {
  old <- file.path(
    LOG_DIR,
    paste0("R2_GSE198618_STEP0_PREFLIGHT_",
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
canon <- function(x) tolower(gsub("[^a-z0-9]+","",as.character(x)))

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

download_atomic <- function(url,dest) {
  if(file.exists(dest) && file.info(dest)$size>0) {
    logline("[INFO] Existing file retained: ",dest)
    return("EXISTING")
  }
  tmp <- paste0(dest,".part_",Sys.getpid())
  if(file.exists(tmp)) unlink(tmp,force=TRUE)
  logline("[INFO] Downloading: ",url)
  ok <- tryCatch({
    suppressWarnings(
      utils::download.file(url,tmp,mode="wb",method="libcurl",quiet=FALSE)
    )
    file.exists(tmp) && file.info(tmp)$size>0
  },error=function(e) {
    logline("[DOWNLOAD ERROR] ",conditionMessage(e))
    FALSE
  })
  if(!ok) {
    if(file.exists(tmp)) unlink(tmp,force=TRUE)
    return("FAILED")
  }
  if(!file.rename(tmp,dest)) {
    unlink(tmp,force=TRUE)
    return("FAILED_RENAME")
  }
  "DOWNLOADED"
}

logline("============================================================")
logline("R2 GSE198618 Step 0 — supporting PAH replication preflight")
logline("NO statistical model. NO candidate testing.")
logline("============================================================")

norm_dl <- download_atomic(NORM_URL,NORM)
soft_dl <- download_atomic(SOFT_URL,SOFT)

dl <- data.frame(
  file=c(basename(NORM),basename(SOFT)),
  status=c(norm_dl,soft_dl),
  exists=c(file.exists(NORM),file.exists(SOFT)),
  bytes=c(
    if(file.exists(NORM)) file.info(NORM)$size else NA_real_,
    if(file.exists(SOFT)) file.info(SOFT)$size else NA_real_
  ),
  url=c(NORM_URL,SOFT_URL),
  stringsAsFactors=FALSE
)
awrite(dl,DOWNLOADS)

if(!file.exists(NORM) || !file.exists(SOFT)) {
  twrite(c(
    "R2_GSE198618_STEP0_PREFLIGHT_HOLD_DOWNLOAD",
    "No analysis was run.",
    paste0("normalized_counts_present=",file.exists(NORM)),
    paste0("SOFT_present=",file.exists(SOFT)),
    paste0("normalized_counts_manual_destination=",NORM),
    paste0("SOFT_manual_destination=",SOFT)
  ),HOLD)
  logline("FINAL_GATE: R2_GSE198618_STEP0_PREFLIGHT_HOLD_DOWNLOAD")
  quit(save="no",status=61,runLast=FALSE)
}

add("normalized processed file","present",file.info(NORM)$size,
    if(file.info(NORM)$size>0) "PASS" else "FAIL")
add("GEO family SOFT","present",file.info(SOFT)$size,
    if(file.info(SOFT)$size>0) "PASS" else "FAIL")

# --------------------------------------------------------------------------
# Parse GEO SOFT: 32 sample blocks and all characteristics.
# --------------------------------------------------------------------------

soft <- readLines(gzfile(SOFT,"rt"),warn=FALSE)
starts <- grep("^\\^SAMPLE = GSM",soft)
ends <- c(starts[-1]-1L,length(soft))

add("SOFT sample blocks","32",length(starts),
    if(length(starts)==32L) "PASS" else "FAIL")

if(length(starts)!=32L) {
  awrite(do.call(rbind,A),AUDIT)
  twrite(c(
    "R2_GSE198618_STEP0_PREFLIGHT_HOLD",
    "reason=SOFT_SAMPLE_COUNT_MISMATCH",
    "model_fit_executed=NO"
  ),HOLD)
  quit(save="no",status=62,runLast=FALSE)
}

blocks <- Map(function(a,b) soft[a:b],starts,ends)

pick1 <- function(b,prefix) {
  x <- b[startsWith(b,prefix)]
  if(!length(x)) return(NA_character_)
  substring(x[1],nchar(prefix)+1L)
}
pickall <- function(b,prefix) {
  x <- b[startsWith(b,prefix)]
  if(!length(x)) return(character())
  substring(x,nchar(prefix)+1L)
}

sample_rows <- list()
char_rows <- list()

for(i in seq_along(blocks)) {
  b <- blocks[[i]]
  gsm <- sub("^\\^SAMPLE = ","",b[1])
  title <- pick1(b,"!Sample_title = ")
  source <- pick1(b,"!Sample_source_name_ch1 = ")
  chars <- pickall(b,"!Sample_characteristics_ch1 = ")

  condition <- NA_character_
  for(z in chars) {
    if(grepl("^genotype/condition\\s*:",z,ignore.case=TRUE)) {
      condition <- trimws(sub("^[^:]+:","",z))
    }
  }
  if(is.na(condition)) {
    txt <- tolower(paste(title,paste(chars,collapse=" | ")))
    condition <- if(grepl("decompensated",txt)) "Decompensated" else
      if(grepl("compensated",txt)) "Compensated" else
        if(grepl("control",txt)) "Control" else NA_character_
  }

  state <- if(tolower(condition)=="control") "CONTROL" else
    if(tolower(condition)=="compensated") "COMPENSATED" else
      if(tolower(condition)=="decompensated") "DECOMPENSATED" else NA_character_

  sample_rows[[i]] <- data.frame(
    geo_accession=gsm,
    title=title,
    source_name=source,
    condition_raw=condition,
    clinical_state=state,
    stringsAsFactors=FALSE
  )

  if(length(chars)) {
    for(z in chars) {
      if(grepl(":",z,fixed=TRUE)) {
        field <- trimws(sub(":.*$","",z))
        value <- trimws(sub("^[^:]+:","",z))
      } else {
        field <- "UNPARSED"
        value <- z
      }
      char_rows[[length(char_rows)+1L]] <- data.frame(
        geo_accession=gsm,
        title=title,
        field=field,
        value=value,
        stringsAsFactors=FALSE
      )
    }
  }
}

sm <- do.call(rbind,sample_rows)
ch <- if(length(char_rows)) do.call(rbind,char_rows) else
  data.frame(geo_accession=character(),title=character(),
             field=character(),value=character())

awrite(ch,META_LONG)

field_summary <- if(nrow(ch)) {
  z <- aggregate(
    ch$geo_accession,
    by=list(field=ch$field),
    FUN=function(x) length(unique(x))
  )
  names(z)[2] <- "samples_with_field"
  vals <- aggregate(
    ch$value,
    by=list(field=ch$field),
    FUN=function(x) paste(sort(unique(x)),collapse=" | ")
  )
  names(vals)[2] <- "unique_values"
  merge(z,vals,by="field",all=TRUE)
} else {
  data.frame(field=character(),samples_with_field=integer(),
             unique_values=character())
}
awrite(field_summary,META_FIELDS)

tab <- table(factor(sm$clinical_state,
                    levels=c("CONTROL","COMPENSATED","DECOMPENSATED")))
add("Control samples","14",tab["CONTROL"],
    if(tab["CONTROL"]==14L) "PASS" else "FAIL")
add("Compensated samples","11",tab["COMPENSATED"],
    if(tab["COMPENSATED"]==11L) "PASS" else "FAIL")
add("Decompensated samples","7",tab["DECOMPENSATED"],
    if(tab["DECOMPENSATED"]==7L) "PASS" else "FAIL")
add("unclassified samples","0",sum(is.na(sm$clinical_state)),
    if(sum(is.na(sm$clinical_state))==0L) "PASS" else "FAIL")
add("unique GEO accessions","32",length(unique(sm$geo_accession)),
    if(length(unique(sm$geo_accession))==32L) "PASS" else "FAIL")

# --------------------------------------------------------------------------
# Read author-supplied normalized CPM matrix.
# --------------------------------------------------------------------------

logline("[INFO] Reading normalized CPM matrix.")
mat <- tryCatch(
  read.csv(gzfile(NORM,"rt"),stringsAsFactors=FALSE,check.names=FALSE),
  error=function(e) {
    logline("[READ ERROR] ",conditionMessage(e))
    NULL
  }
)

if(is.null(mat)) {
  awrite(do.call(rbind,A),AUDIT)
  twrite(c(
    "R2_GSE198618_STEP0_PREFLIGHT_HOLD",
    "reason=NORMALIZED_MATRIX_READ_ERROR",
    "model_fit_executed=NO"
  ),HOLD)
  quit(save="no",status=63,runLast=FALSE)
}

add("normalized matrix gene rows",">=10000",nrow(mat),
    if(nrow(mat)>=10000L) "PASS" else "FAIL")
add("normalized matrix columns",">=33",ncol(mat),
    if(ncol(mat)>=33L) "PASS" else "FAIL")

# Identify exactly 32 sample columns by matching GEO title/GSM canonically.
cn <- names(mat)
cc <- canon(cn)
sm$title_canon <- canon(sm$title)
sm$gsm_canon <- canon(sm$geo_accession)

match_col <- rep(NA_integer_,nrow(sm))
match_mode <- rep(NA_character_,nrow(sm))

for(i in seq_len(nrow(sm))) {
  hit_title <- which(cc==sm$title_canon[i])
  hit_gsm <- which(cc==sm$gsm_canon[i])
  hits <- unique(c(hit_title,hit_gsm))
  if(length(hits)==1L) {
    match_col[i] <- hits
    match_mode[i] <- if(length(hit_gsm)==1L) "GSM" else "TITLE"
  }
}

# If direct canonical matching fails, use structured group/order pattern.
if(any(is.na(match_col))) {
  for(i in which(is.na(match_col))) {
    st <- sm$clinical_state[i]
    num <- suppressWarnings(as.integer(sub(".*_","",sm$title[i])))
    if(!is.finite(num)) next
    group_pat <- if(st=="CONTROL") "control" else
      if(st=="COMPENSATED") "compensated" else "decompensated"
    target <- canon(paste0(group_pat,"rv",num))
    h <- which(cc==target)
    if(length(h)==1L) {
      match_col[i] <- h
      match_mode[i] <- "STRUCTURED_TITLE"
    }
  }
}

sm$matrix_column <- ifelse(is.na(match_col),NA_character_,cn[match_col])
sm$matrix_column_index <- match_col
sm$matrix_match_mode <- match_mode

nmatched <- sum(!is.na(sm$matrix_column))
uniqmatched <- length(unique(sm$matrix_column[!is.na(sm$matrix_column)]))
add("SOFT-to-matrix matched samples","32",nmatched,
    if(nmatched==32L && uniqmatched==32L) "PASS" else "FAIL")

# Matrix column summaries for all columns.
colsum <- do.call(rbind,lapply(seq_along(mat),function(j) {
  v <- mat[[j]]
  suppressWarnings(vn <- as.numeric(v))
  finite <- is.finite(vn)
  data.frame(
    column_index=j,
    column_name=names(mat)[j],
    finite_numeric=sum(finite),
    numeric_fraction=sum(finite)/nrow(mat),
    nonnegative_fraction=sum(finite & vn>=0)/nrow(mat),
    integer_like_fraction=sum(finite & abs(vn-round(vn))<1e-8)/nrow(mat),
    q0=if(any(finite)) min(vn[finite]) else NA_real_,
    q50=if(any(finite)) median(vn[finite]) else NA_real_,
    q99=if(any(finite)) unname(quantile(vn[finite],0.99)) else NA_real_,
    q100=if(any(finite)) max(vn[finite]) else NA_real_,
    stringsAsFactors=FALSE
  )
}))
awrite(colsum,COLSUM)

if(nmatched==32L && uniqmatched==32L) {
  sj <- match(sm$matrix_column,colsum$column_name)
  sample_numeric_ok <- all(colsum$numeric_fraction[sj]>=0.999)
  sample_nonneg_ok <- all(colsum$nonnegative_fraction[sj]>=0.999)
  median_integer_fraction <- median(colsum$integer_like_fraction[sj],na.rm=TRUE)
} else {
  sample_numeric_ok <- FALSE
  sample_nonneg_ok <- FALSE
  median_integer_fraction <- NA_real_
}

add("matched sample columns numeric",">=99.9% each",
    if(nmatched==32L) min(colsum$numeric_fraction[match(sm$matrix_column,colsum$column_name)],
                          na.rm=TRUE) else NA,
    if(sample_numeric_ok) "PASS" else "FAIL")
add("matched sample columns nonnegative",">=99.9% each",
    if(nmatched==32L) min(colsum$nonnegative_fraction[match(sm$matrix_column,colsum$column_name)],
                          na.rm=TRUE) else NA,
    if(sample_nonneg_ok) "PASS" else "FAIL")

data_scale <- if(is.finite(median_integer_fraction) &&
                 median_integer_fraction<0.99) {
  "NORMALIZED_NONINTEGER_CPM_COMPATIBLE"
} else if(is.finite(median_integer_fraction)) {
  "INTEGER_LIKE_REQUIRES_REVIEW"
} else {
  "UNKNOWN"
}
add("processed data scale","normalized CPM/noninteger expected",data_scale,
    if(data_scale=="NORMALIZED_NONINTEGER_CPM_COMPATIBLE") "PASS" else "HOLD",
    "GEO states RSEM raw counts were normalized by edgeR cpm().")

# Gene identifier diagnostic: all non-sample columns are candidates.
sample_col_indices <- sort(unique(match_col[!is.na(match_col)]))
gene_candidate_indices <- setdiff(seq_along(mat),sample_col_indices)

gdiag <- data.frame(
  metric=c(
    "matrix_rows","matrix_columns","matched_sample_columns",
    "non_sample_columns","non_sample_column_names",
    "median_sample_integer_like_fraction","data_scale"
  ),
  value=c(
    nrow(mat),ncol(mat),length(sample_col_indices),
    length(gene_candidate_indices),
    paste(names(mat)[gene_candidate_indices],collapse=" | "),
    median_integer_fraction,data_scale
  ),
  stringsAsFactors=FALSE
)
awrite(gdiag,GENEDIAG)

# --------------------------------------------------------------------------
# Patient-overlap audit versus GSE240921: intentionally conservative.
# --------------------------------------------------------------------------

prev <- file.path(ROOT,"results","R1_GSE240921",
                  "R1_GSE240921_sample_manifest_semantic_repair.csv")

exact_gsm_overlap <- NA_integer_
exact_title_overlap <- NA_integer_

if(file.exists(prev)) {
  p <- read.csv(prev,stringsAsFactors=FALSE,check.names=FALSE)
  exact_gsm_overlap <- length(intersect(sm$geo_accession,p$geo_accession))
  exact_title_overlap <- length(intersect(canon(sm$title),canon(p$title)))
}

ov <- data.frame(
  item=c(
    "GSE198618_GSM_vs_GSE240921_GSM_exact_overlap",
    "GSE198618_title_vs_GSE240921_title_exact_canonical_overlap",
    "patient_level_overlap_status",
    "interpretation_rule"
  ),
  value=c(
    exact_gsm_overlap,
    exact_title_overlap,
    "PATIENT_OVERLAP_UNKNOWN",
    "DO_NOT_CLAIM_FULL_INDEPENDENCE"
  ),
  stringsAsFactors=FALSE
)
awrite(ov,OVERLAP)

sm$patient_overlap_with_GSE240921 <- "UNKNOWN"
awrite(sm,MANIFEST)

audit <- do.call(rbind,A)
awrite(audit,AUDIT)

hard_fail <- sum(audit$status=="FAIL")
hold_items <- sum(audit$status=="HOLD")

if(hard_fail>0L || hold_items>0L) {
  twrite(c(
    "R2_GSE198618_STEP0_PREFLIGHT_HOLD",
    paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
    paste0("hard_failures=",hard_fail),
    paste0("hold_items=",hold_items),
    paste0("data_scale=",data_scale),
    "patient_overlap_with_GSE240921=UNKNOWN",
    "model_fit_executed=NO",
    "candidate_testing_executed=NO",
    "next_action=Return audit outputs to ChatGPT; do not fit a model."
  ),HOLD)
  logline("FINAL_GATE: R2_GSE198618_STEP0_PREFLIGHT_HOLD")
  quit(save="no",status=64,runLast=FALSE)
}

twrite(c(
  "R2_GSE198618_STEP0_PREFLIGHT_PASS",
  paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
  "dataset=GSE198618",
  "role=SUPPORTING_PAH_REPLICATION",
  "human_RV_samples=32",
  "control=14",
  "compensated=11",
  "decompensated=7",
  paste0("matrix_rows=",nrow(mat)),
  paste0("matrix_columns=",ncol(mat)),
  "matched_sample_columns=32",
  paste0("data_scale=",data_scale),
  "processed_data_authority=AUTHOR_SUPPLIED_RSEM_COUNTS_NORMALIZED_BY_EDGE_R_CPM",
  "raw_SRA_download_executed=NO",
  "patient_overlap_with_GSE240921=UNKNOWN",
  "full_independence_claim_allowed=NO",
  "model_formula_frozen=NO",
  "model_fit_executed=NO",
  "candidate_testing_executed=NO",
  "next_stage=ChatGPT audit then supporting-replication model contract"
),PASS)

logline("FINAL_GATE: R2_GSE198618_STEP0_PREFLIGHT_PASS")
quit(save="no",status=0,runLast=FALSE)
