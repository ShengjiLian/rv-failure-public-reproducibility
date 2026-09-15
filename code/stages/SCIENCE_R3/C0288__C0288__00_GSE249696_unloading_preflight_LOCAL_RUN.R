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
# RV Project — R3 GSE249696 Step 0
# CTEPH UNLOADING: ACQUISITION + SAMPLE/PAIR/SITE-CONFOUND PREFLIGHT ONLY
#
# Public GEO design expected:
#   95 RNA-seq samples total
#   71 baseline (BL) samples from RV myocardial FREE WALL
#   24 follow-up (FU) samples ~12 months post-PEA from INTERVENTRICULAR SEPTUM
#   22 patients with a matched BL/FU pair
#   2 FU-only patients (expected from GEO titles: Pat-9, Pat-83)
#
# Baseline risk groups expected:
#   moderate=30, intermediate=23, severe=18
#
# CENTRAL DESIGN LIMITATION TO FREEZE BEFORE ANY OUTCOME TEST:
#   Main paired BL -> FU contrast changes BOTH
#     1) hemodynamic state/time after PEA
#     2) biopsy anatomical site (RV free wall -> septum)
#   Therefore observed paired change cannot be interpreted as a pure treatment/
#   unloading effect without an anatomical-site sensitivity analysis.
#
# GSE249694 (n=3 septum pre/post; Pat-33/72/91) will be audited later as a
# planned anatomical-site sensitivity dataset. It is NOT independent validation.
#
# This step DOES NOT:
#   - fit DESeq2 / limma / edgeR models
#   - test R0/R1/R2 candidate genes
#   - define recovery/persistence thresholds
#   - download SRA FASTQ/BAM
#   - use GSE249694 yet
# ==============================================================================

options(stringsAsFactors=FALSE, warn=1)

ROOT <- normalizePath(getwd(), winslash="/", mustWork=TRUE)
if(!identical(ROOT,RV_PROJECT_ROOT)) stop("Expected D:/RV_project")

DATA_DIR <- file.path(ROOT,"data","processed","GSE249696")
META_DIR <- file.path(ROOT,"data","metadata","GSE249696")
RES_DIR  <- file.path(ROOT,"results","R3_GSE249696")
LOG_DIR  <- file.path(ROOT,"logs")
dir.create(DATA_DIR,recursive=TRUE,showWarnings=FALSE)
dir.create(META_DIR,recursive=TRUE,showWarnings=FALSE)
dir.create(RES_DIR,recursive=TRUE,showWarnings=FALSE)
dir.create(LOG_DIR,recursive=TRUE,showWarnings=FALSE)

MAT <- file.path(DATA_DIR,"GSE249696_ext395_rnaseq.txt.gz")
SOFT <- file.path(META_DIR,"GSE249696_family.soft.gz")

MAT_URL <- paste0(
  "https://www.ncbi.nlm.nih.gov/geo/download/?acc=GSE249696",
  "&format=file&file=GSE249696_ext395_rnaseq.txt.gz"
)
SOFT_URL <- paste0(
  "https://ftp.ncbi.nlm.nih.gov/geo/series/GSE249nnn/",
  "GSE249696/soft/GSE249696_family.soft.gz"
)

LOG <- file.path(LOG_DIR,"R3_GSE249696_STEP0_PREFLIGHT.log")
AUDIT <- file.path(RES_DIR,"R3_GSE249696_step0_audit.csv")
SAMPLES <- file.path(RES_DIR,"R3_GSE249696_sample_manifest.csv")
PAIRS <- file.path(RES_DIR,"R3_GSE249696_pair_manifest.csv")
FIELDS <- file.path(RES_DIR,"R3_GSE249696_characteristics_field_summary.csv")
MATRIX_DIAG <- file.path(RES_DIR,"R3_GSE249696_matrix_diagnostic.csv")
SITE <- file.path(RES_DIR,"R3_GSE249696_site_confound_audit.csv")
DOWNLOADS <- file.path(RES_DIR,"R3_GSE249696_download_manifest.csv")
PASS <- file.path(RES_DIR,"R3_GSE249696_STEP0_PREFLIGHT_PASS.txt")
HOLD <- file.path(RES_DIR,"R3_GSE249696_STEP0_PREFLIGHT_HOLD.txt")

if(file.exists(LOG)) {
  old <- file.path(
    LOG_DIR,
    paste0("R3_GSE249696_STEP0_PREFLIGHT_",
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
canon <- function(x) gsub("[^a-z0-9]+","",tolower(as.character(x)))

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
  }, error=function(e) {
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
logline("R3 GSE249696 Step 0 — CTEPH unloading preflight")
logline("NO model fit. NO candidate testing. NO SRA raw download.")
logline("============================================================")

mat_dl <- download_atomic(MAT_URL,MAT)
soft_dl <- download_atomic(SOFT_URL,SOFT)

dl <- data.frame(
  file=c(basename(MAT),basename(SOFT)),
  status=c(mat_dl,soft_dl),
  exists=c(file.exists(MAT),file.exists(SOFT)),
  bytes=c(
    if(file.exists(MAT)) file.info(MAT)$size else NA_real_,
    if(file.exists(SOFT)) file.info(SOFT)$size else NA_real_
  ),
  url=c(MAT_URL,SOFT_URL),
  stringsAsFactors=FALSE
)
awrite(dl,DOWNLOADS)

if(!file.exists(MAT) || !file.exists(SOFT)) {
  twrite(c(
    "R3_GSE249696_STEP0_PREFLIGHT_HOLD_DOWNLOAD",
    "No analysis was run.",
    paste0("processed_matrix_present=",file.exists(MAT)),
    paste0("SOFT_present=",file.exists(SOFT)),
    paste0("processed_matrix_manual_destination=",MAT),
    paste0("SOFT_manual_destination=",SOFT)
  ),HOLD)
  logline("FINAL_GATE: R3_GSE249696_STEP0_PREFLIGHT_HOLD_DOWNLOAD")
  quit(save="no",status=81,runLast=FALSE)
}

add("processed matrix","present",file.info(MAT)$size,
    if(file.info(MAT)$size>0) "PASS" else "FAIL")
add("GEO family SOFT","present",file.info(SOFT)$size,
    if(file.info(SOFT)$size>0) "PASS" else "FAIL")

# --------------------------------------------------------------------------
# Parse GEO SOFT.
# --------------------------------------------------------------------------

soft <- readLines(gzfile(SOFT,"rt"),warn=FALSE)
starts <- grep("^\\^SAMPLE = GSM",soft)
ends <- c(starts[-1]-1L,length(soft))

add("SOFT sample blocks","95",length(starts),
    if(length(starts)==95L) "PASS" else "FAIL")

if(length(starts)!=95L) {
  awrite(do.call(rbind,A),AUDIT)
  twrite(c(
    "R3_GSE249696_STEP0_PREFLIGHT_HOLD",
    "reason=SOFT_SAMPLE_COUNT_MISMATCH",
    "model_fit_executed=NO"
  ),HOLD)
  quit(save="no",status=82,runLast=FALSE)
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
norm_field <- function(x) tolower(trimws(x))

sample_rows <- list()
char_rows <- list()

for(i in seq_along(blocks)) {
  b <- blocks[[i]]
  gsm <- sub("^\\^SAMPLE = ","",b[1])
  title <- pick1(b,"!Sample_title = ")
  source <- pick1(b,"!Sample_source_name_ch1 = ")
  chars <- pickall(b,"!Sample_characteristics_ch1 = ")

  kv <- list()
  if(length(chars)) {
    for(z in chars) {
      if(grepl(":",z,fixed=TRUE)) {
        field <- trimws(sub(":.*$","",z))
        value <- trimws(sub("^[^:]+:","",z))
      } else {
        field <- "UNPARSED"
        value <- z
      }
      kv[[norm_field(field)]] <- value
      char_rows[[length(char_rows)+1L]] <- data.frame(
        geo_accession=gsm,title=title,field=field,value=value,
        stringsAsFactors=FALSE
      )
    }
  }

  getkv <- function(keys) {
    for(k in keys) if(!is.null(kv[[k]])) return(kv[[k]])
    NA_character_
  }

  individual <- getkv(c("individual","patient","patient id","patient_id"))
  if(is.na(individual) || !nzchar(individual)) {
    m <- regmatches(title,regexpr("(?i)pat[ -]*[0-9]+",title,perl=TRUE))
    individual <- if(length(m) && nzchar(m)) m else NA_character_
  }
  patient_num <- suppressWarnings(as.integer(
    sub(".*?([0-9]+).*","\\1",individual)
  ))
  patient_id <- if(is.finite(patient_num)) paste0("Pat-",patient_num) else NA_character_

  treatment <- getkv(c("treatment","timepoint","time point"))
  txt <- tolower(paste(title,source,paste(chars,collapse=" | ")))
  timepoint <- if(grepl("postpea|\\-fu\\b|follow.?up",txt,perl=TRUE)) {
    "FU"
  } else if(grepl("prepea|\\-bl\\b|baseline",txt,perl=TRUE)) {
    "BL"
  } else {
    NA_character_
  }

  tissue <- getkv(c("tissue"))
  if(is.na(tissue) || !nzchar(tissue)) tissue <- source
  tissue_l <- tolower(tissue)
  site_class <- if(grepl("free wall",tissue_l)) {
    "RV_FREE_WALL"
  } else if(grepl("sept",tissue_l)) {
    "INTERVENTRICULAR_SEPTUM"
  } else {
    "UNKNOWN"
  }

  risk <- getkv(c("esc risk group","risk group","esc risk"))
  risk_class <- if(is.na(risk)) NA_character_ else {
    rl <- tolower(risk)
    if(grepl("moderate",rl)) "MODERATE" else
      if(grepl("intermed",rl)) "INTERMEDIATE" else
        if(grepl("severe",rl)) "SEVERE" else toupper(trimws(risk))
  }

  sex <- getkv(c("sex","gender"))

  sample_rows[[i]] <- data.frame(
    geo_accession=gsm,
    title=title,
    source_name=source,
    patient_id=patient_id,
    patient_number=patient_num,
    timepoint=timepoint,
    treatment_raw=treatment,
    tissue_raw=tissue,
    site_class=site_class,
    esc_risk_raw=risk,
    esc_risk_group=risk_class,
    sex=sex,
    stringsAsFactors=FALSE
  )
}

sm <- do.call(rbind,sample_rows)
ch <- if(length(char_rows)) do.call(rbind,char_rows) else
  data.frame(geo_accession=character(),title=character(),
             field=character(),value=character())

field_summary <- if(nrow(ch)) {
  nfield <- aggregate(
    ch$geo_accession,by=list(field=ch$field),
    FUN=function(x) length(unique(x))
  )
  names(nfield)[2] <- "samples_with_field"
  vals <- aggregate(
    ch$value,by=list(field=ch$field),
    FUN=function(x) paste(sort(unique(x)),collapse=" | ")
  )
  names(vals)[2] <- "unique_values"
  merge(nfield,vals,by="field",all=TRUE)
} else {
  data.frame(field=character(),samples_with_field=integer(),
             unique_values=character())
}
awrite(field_summary,FIELDS)

nBL <- sum(sm$timepoint=="BL",na.rm=TRUE)
nFU <- sum(sm$timepoint=="FU",na.rm=TRUE)
add("baseline samples","71",nBL,if(nBL==71L) "PASS" else "FAIL")
add("follow-up samples","24",nFU,if(nFU==24L) "PASS" else "FAIL")
add("unclassified timepoint","0",sum(is.na(sm$timepoint)),
    if(sum(is.na(sm$timepoint))==0L) "PASS" else "FAIL")
add("unique GEO accessions","95",length(unique(sm$geo_accession)),
    if(length(unique(sm$geo_accession))==95L) "PASS" else "FAIL")
add("samples with patient ID","95",sum(!is.na(sm$patient_id)),
    if(sum(!is.na(sm$patient_id))==95L) "PASS" else "FAIL")

# Site authority.
bl_free <- sum(sm$timepoint=="BL" & sm$site_class=="RV_FREE_WALL")
fu_sep <- sum(sm$timepoint=="FU" & sm$site_class=="INTERVENTRICULAR_SEPTUM")
add("BL RV free-wall samples","71",bl_free,
    if(bl_free==71L) "PASS" else "FAIL")
add("FU interventricular-septum samples","24",fu_sep,
    if(fu_sep==24L) "PASS" else "FAIL")

# Baseline risk-group counts.
bl <- sm[sm$timepoint=="BL",,drop=FALSE]
risk_counts <- table(factor(
  bl$esc_risk_group,
  levels=c("MODERATE","INTERMEDIATE","SEVERE")
))
risk_missing <- sum(is.na(bl$esc_risk_group))
add("BL moderate-risk","30",risk_counts["MODERATE"],
    if(risk_counts["MODERATE"]==30L) "PASS" else "FAIL")
add("BL intermediate-risk","23",risk_counts["INTERMEDIATE"],
    if(risk_counts["INTERMEDIATE"]==23L) "PASS" else "FAIL")
add("BL severe-risk","18",risk_counts["SEVERE"],
    if(risk_counts["SEVERE"]==18L) "PASS" else "FAIL")
add("BL risk missing","0",risk_missing,
    if(risk_missing==0L) "PASS" else "FAIL")

# --------------------------------------------------------------------------
# Patient pairing.
# --------------------------------------------------------------------------

ids <- sort(unique(sm$patient_id))
pair_rows <- lapply(ids,function(id) {
  z <- sm[sm$patient_id==id,,drop=FALSE]
  zb <- z[z$timepoint=="BL",,drop=FALSE]
  zf <- z[z$timepoint=="FU",,drop=FALSE]
  data.frame(
    patient_id=id,
    n_BL=nrow(zb),
    n_FU=nrow(zf),
    paired=nrow(zb)==1L && nrow(zf)==1L,
    BL_gsm=if(nrow(zb)==1L) zb$geo_accession else NA_character_,
    BL_title=if(nrow(zb)==1L) zb$title else NA_character_,
    BL_site=if(nrow(zb)==1L) zb$site_class else NA_character_,
    BL_risk=if(nrow(zb)==1L) zb$esc_risk_group else NA_character_,
    BL_sex=if(nrow(zb)==1L) zb$sex else NA_character_,
    FU_gsm=if(nrow(zf)==1L) zf$geo_accession else NA_character_,
    FU_title=if(nrow(zf)==1L) zf$title else NA_character_,
    FU_site=if(nrow(zf)==1L) zf$site_class else NA_character_,
    FU_sex=if(nrow(zf)==1L) zf$sex else NA_character_,
    site_changed=if(nrow(zb)==1L && nrow(zf)==1L)
      zb$site_class != zf$site_class else NA,
    stringsAsFactors=FALSE
  )
})
pm <- do.call(rbind,pair_rows)

npaired <- sum(pm$paired)
fu_only <- sort(pm$patient_id[pm$n_BL==0L & pm$n_FU==1L])
bl_only <- sort(pm$patient_id[pm$n_BL==1L & pm$n_FU==0L])

add("matched BL/FU patient pairs","22",npaired,
    if(npaired==22L) "PASS" else "FAIL")
add("FU-only patients","2",length(fu_only),
    if(length(fu_only)==2L) "PASS" else "FAIL",
    paste(fu_only,collapse=";"))
add("expected FU-only identities","Pat-9;Pat-83",
    paste(fu_only,collapse=";"),
    if(identical(fu_only,c("Pat-83","Pat-9")) ||
       identical(fu_only,c("Pat-9","Pat-83"))) "PASS" else "FAIL")
add("paired rows with anatomical site change","22",
    sum(pm$paired & pm$site_changed,na.rm=TRUE),
    if(sum(pm$paired & pm$site_changed,na.rm=TRUE)==22L)
      "PASS" else "FAIL")

awrite(pm,PAIRS)

# --------------------------------------------------------------------------
# Processed matrix structure; this matrix is for preflight only.
# --------------------------------------------------------------------------

logline("[INFO] Reading GEO supplementary processed matrix.")
mat <- tryCatch(
  read.delim(gzfile(MAT,"rt"),stringsAsFactors=FALSE,
             check.names=FALSE,quote="",comment.char=""),
  error=function(e) {
    logline("[READ ERROR] ",conditionMessage(e))
    NULL
  }
)

if(is.null(mat)) {
  awrite(do.call(rbind,A),AUDIT)
  twrite(c(
    "R3_GSE249696_STEP0_PREFLIGHT_HOLD",
    "reason=PROCESSED_MATRIX_READ_ERROR",
    "model_fit_executed=NO"
  ),HOLD)
  quit(save="no",status=83,runLast=FALSE)
}

add("processed matrix gene rows",">=10000",nrow(mat),
    if(nrow(mat)>=10000L) "PASS" else "FAIL")
add("processed matrix columns",">=96",ncol(mat),
    if(ncol(mat)>=96L) "PASS" else "FAIL")

cn <- names(mat)

# IMPORTANT:
# The GEO matrix sample columns are named like "Pat-54-BL_1", whereas
# GEO SOFT titles are "Pat 54-BL".  The "_1" suffix is a matrix-export
# artifact and is not part of the biological sample identity.
#
# Canonicalization must lowercase BEFORE removing non-[a-z0-9]
# characters.  Doing this in the opposite order would drop uppercase
# letters (P/B/L/F/U) and can create false numeric collisions such as
# Pat 61-BL vs Pat-6-BL_1.
cc <- canon(cn)
cn_base <- sub("_[0-9]+$","",cn)
cc_base <- canon(cn_base)

sm$title_canon <- canon(sm$title)
sm$gsm_canon <- canon(sm$geo_accession)

match_col <- rep(NA_integer_,nrow(sm))
match_mode <- rep(NA_character_,nrow(sm))

for(i in seq_len(nrow(sm))) {
  # Prefer exact biological title after stripping the matrix-only suffix.
  ht <- which(cc_base==sm$title_canon[i])

  # Keep a GSM path if a future matrix exposes GEO accessions directly.
  hg <- which(cc==sm$gsm_canon[i])

  hits <- unique(c(ht,hg))
  if(length(hits)==1L) {
    match_col[i] <- hits
    match_mode[i] <- if(length(hg)==1L && length(ht)==0L) {
      "GSM"
    } else {
      "TITLE_SUFFIX_STRIPPED"
    }
  }
}

# Explicit patient/timepoint fallback; still suffix-aware and collision-safe.
if(any(is.na(match_col))) {
  for(i in which(is.na(match_col))) {
    target <- canon(paste0(
      "Pat-",sm$patient_number[i],"-",
      if(sm$timepoint[i]=="BL") "BL" else "FU"
    ))
    h <- which(cc_base==target)
    if(length(h)==1L) {
      match_col[i] <- h
      match_mode[i] <- "PATIENT_TIMEPOINT_SUFFIX_STRIPPED"
    }
  }
}

sm$matrix_column <- ifelse(is.na(match_col),NA_character_,cn[match_col])
sm$matrix_column_index <- match_col
sm$matrix_match_mode <- match_mode

nmatched <- sum(!is.na(sm$matrix_column))
uniqmatched <- length(unique(sm$matrix_column[!is.na(sm$matrix_column)]))
duplicate_matrix_reuse <- nmatched - uniqmatched

add("SOFT-to-matrix matched samples","95",nmatched,
    if(nmatched==95L && uniqmatched==95L) "PASS" else "FAIL")
add("duplicate matrix-column reuse","0",duplicate_matrix_reuse,
    if(duplicate_matrix_reuse==0L) "PASS" else "FAIL")

sample_col_indices <- sort(unique(match_col[!is.na(match_col)]))
non_sample_idx <- setdiff(seq_along(mat),sample_col_indices)

# Numeric diagnostics on matched sample columns.
min_numeric_frac <- NA_real_
min_nonnegative_frac <- NA_real_
median_integer_frac <- NA_real_

if(nmatched==95L && uniqmatched==95L) {
  nums <- lapply(sample_col_indices,function(j)
    suppressWarnings(as.numeric(mat[[j]])))
  numeric_frac <- vapply(nums,function(v) mean(is.finite(v)),numeric(1))
  nonneg_frac <- vapply(nums,function(v)
    mean(is.finite(v) & v>=0),numeric(1))
  integer_frac <- vapply(nums,function(v) {
    ok <- is.finite(v)
    if(!any(ok)) return(NA_real_)
    mean(abs(v[ok]-round(v[ok]))<1e-8)
  },numeric(1))

  min_numeric_frac <- min(numeric_frac)
  min_nonnegative_frac <- min(nonneg_frac)
  median_integer_frac <- median(integer_frac,na.rm=TRUE)

  add("matched matrix sample columns numeric",">=99.9% each",
      min_numeric_frac,
      if(min_numeric_frac>=0.999) "PASS" else "FAIL")
  add("matched matrix sample columns nonnegative",">=99.9% each",
      min_nonnegative_frac,
      if(min_nonnegative_frac>=0.999) "PASS" else "FAIL")
}

scale_class <- if(is.finite(median_integer_frac)) {
  if(median_integer_frac<0.99)
    "NONINTEGER_NORMALIZED_COUNTS_COMPATIBLE"
  else
    "INTEGER_LIKE_REQUIRES_METHOD_REVIEW"
} else "UNKNOWN"

mdiag <- data.frame(
  metric=c(
    "matrix_rows","matrix_columns","matched_sample_columns",
    "non_sample_columns","non_sample_column_names",
    "minimum_sample_numeric_fraction",
    "minimum_sample_nonnegative_fraction",
    "median_sample_integer_like_fraction",
    "processed_matrix_scale_observed"
  ),
  value=c(
    nrow(mat),ncol(mat),nmatched,length(non_sample_idx),
    paste(cn[non_sample_idx],collapse=" | "),
    min_numeric_frac,min_nonnegative_frac,median_integer_frac,scale_class
  ),
  stringsAsFactors=FALSE
)
awrite(mdiag,MATRIX_DIAG)

# Save sample manifest only after matrix linkage added.
awrite(sm,SAMPLES)

# --------------------------------------------------------------------------
# Freeze the central site-confound fact before any expression outcome.
# --------------------------------------------------------------------------

paired_site_change <- sum(pm$paired & pm$site_changed,na.rm=TRUE)

site_audit <- data.frame(
  item=c(
    "BL_tissue_authority",
    "FU_tissue_authority",
    "paired_patients",
    "paired_patients_with_site_change",
    "treatment_timepoint_confounded_with_site",
    "main_paired_contrast_interpretation",
    "planned_anatomical_sensitivity_dataset",
    "planned_anatomical_sensitivity_role"
  ),
  value=c(
    "RV_FREE_WALL",
    "INTERVENTRICULAR_SEPTUM",
    npaired,
    paired_site_change,
    if(paired_site_change==npaired) "YES_COMPLETE" else "NOT_COMPLETE",
    "PEA_TIME_PLUS_ANATOMICAL_SITE_CHANGE",
    "GSE249694",
    "SAME_PATIENT_SITE_SENSITIVITY_NOT_INDEPENDENT_VALIDATION"
  ),
  stringsAsFactors=FALSE
)
awrite(site_audit,SITE)

audit <- do.call(rbind,A)
awrite(audit,AUDIT)

hard_fail <- sum(audit$status=="FAIL")

if(hard_fail>0L) {
  twrite(c(
    "R3_GSE249696_STEP0_PREFLIGHT_HOLD",
    paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
    paste0("hard_failures=",hard_fail),
    "model_fit_executed=NO",
    "candidate_testing_executed=NO",
    "raw_SRA_download_executed=NO",
    "next_action=Return audit outputs/log to ChatGPT; do not fit a model."
  ),HOLD)
  logline("FINAL_GATE: R3_GSE249696_STEP0_PREFLIGHT_HOLD")
  quit(save="no",status=84,runLast=FALSE)
}

twrite(c(
  "R3_GSE249696_STEP0_PREFLIGHT_PASS",
  paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
  "dataset=GSE249696",
  "role=CTEPH_UNLOADING_MAIN_COHORT_PREFLIGHT",
  "samples_total=95",
  "baseline_samples=71",
  "followup_samples=24",
  "matched_BL_FU_pairs=22",
  paste0("FU_only_patients=",paste(fu_only,collapse=";")),
  "baseline_moderate=30",
  "baseline_intermediate=23",
  "baseline_severe=18",
  "BL_tissue=RV_FREE_WALL",
  "FU_tissue=INTERVENTRICULAR_SEPTUM",
  "paired_site_change=22_of_22",
  "treatment_timepoint_confounded_with_anatomical_site=YES_COMPLETE",
  "main_paired_contrast_interpretation=PEA_TIME_PLUS_ANATOMICAL_SITE_CHANGE",
  "planned_site_sensitivity_dataset=GSE249694",
  "GSE249694_role=SAME_PATIENT_ANATOMICAL_SITE_SENSITIVITY_NOT_INDEPENDENT_VALIDATION",
  paste0("processed_matrix_rows=",nrow(mat)),
  paste0("processed_matrix_columns=",ncol(mat)),
  paste0("processed_matrix_scale_observed=",scale_class),
  "processed_matrix_authority=GEO_DESEQ_NORMALIZED_GENE_COUNTS",
  "raw_SRA_available=YES",
  "raw_SRA_download_executed=NO",
  "model_formula_frozen=NO",
  "recovery_persistence_rule_frozen=NO",
  "candidate_testing_executed=NO",
  "model_fit_executed=NO",
  "next_stage=ChatGPT audit then R3 model/data-authority contract"
),PASS)

logline("FINAL_GATE: R3_GSE249696_STEP0_PREFLIGHT_PASS")
quit(save="no",status=0,runLast=FALSE)
