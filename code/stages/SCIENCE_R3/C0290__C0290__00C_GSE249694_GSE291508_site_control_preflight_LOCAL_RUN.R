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
# RV Project — R3 Step 0C
# SITE-SENSITIVITY + HEALTHY-CONTROL PREFLIGHT
#
# Datasets:
#   GSE249694 — 3 patients, interventricular septum prePEA vs postPEA
#               Same-patient, same-anatomical-site sensitivity dataset.
#               NOT independent validation.
#
#   GSE291508 — 10 healthy controls, each with RV and interventricular septum.
#               Matching-site residual-abnormality comparator for postPEA septum.
#               Supportive comparator only; not yet a frozen model.
#
# This gate is STRUCTURAL ONLY:
#   - sample counts / patient identities / pairing / tissue
#   - processed matrix structure and sample-column matching
#   - gene-ID overlap with accepted GSE249696 matrix
#   - records that all public matrices are processed normalized counts
#
# NO DESeq2 / limma / edgeR model.
# NO candidate-gene testing.
# NO recovery/persistence classification.
# NO raw SRA download.
# ==============================================================================

options(stringsAsFactors=FALSE, warn=1)

ROOT <- normalizePath(getwd(), winslash="/", mustWork=TRUE)
if(!identical(ROOT,RV_PROJECT_ROOT)) stop("Expected D:/RV_project")

RES <- file.path(ROOT,"results","R3_GSE249696")
LOGDIR <- file.path(ROOT,"logs")
dir.create(RES,recursive=TRUE,showWarnings=FALSE)
dir.create(LOGDIR,recursive=TRUE,showWarnings=FALSE)

D694 <- file.path(ROOT,"data","processed","GSE249694")
M694 <- file.path(ROOT,"data","metadata","GSE249694")
D508 <- file.path(ROOT,"data","processed","GSE291508")
M508 <- file.path(ROOT,"data","metadata","GSE291508")
dir.create(D694,recursive=TRUE,showWarnings=FALSE)
dir.create(M694,recursive=TRUE,showWarnings=FALSE)
dir.create(D508,recursive=TRUE,showWarnings=FALSE)
dir.create(M508,recursive=TRUE,showWarnings=FALSE)

MAT694 <- file.path(D694,"GSE249694_ext327_rnaseq.txt.gz")
SOFT694 <- file.path(M694,"GSE249694_family.soft.gz")
MAT508 <- file.path(D508,"GSE291508_ext300_rnaseq.txt.gz")
SOFT508 <- file.path(M508,"GSE291508_family.soft.gz")

MAIN_MAT <- file.path(
  ROOT,"data","processed","GSE249696","GSE249696_ext395_rnaseq.txt.gz"
)

AUDIT <- file.path(RES,"R3_STEP0C_site_control_preflight_audit.csv")
MAN694 <- file.path(RES,"R3_GSE249694_sample_manifest.csv")
PAIR694 <- file.path(RES,"R3_GSE249694_pair_manifest.csv")
MAN508 <- file.path(RES,"R3_GSE291508_sample_manifest.csv")
PAIR508 <- file.path(RES,"R3_GSE291508_RV_IVS_pair_manifest.csv")
MATRIX_AUD <- file.path(RES,"R3_STEP0C_matrix_gene_overlap_audit.csv")
ROLE <- file.path(RES,"R3_STEP0C_dataset_roles.csv")
PASS <- file.path(RES,"R3_STEP0C_SITE_CONTROL_PREFLIGHT_PASS.txt")
HOLD <- file.path(RES,"R3_STEP0C_SITE_CONTROL_PREFLIGHT_HOLD.txt")
LOG <- file.path(LOGDIR,"R3_STEP0C_SITE_CONTROL_PREFLIGHT.log")

if(file.exists(LOG)) {
  old <- file.path(
    LOGDIR,
    paste0("R3_STEP0C_SITE_CONTROL_PREFLIGHT_",
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
    item=as.character(item), expected=as.character(expected),
    observed=as.character(observed), status=as.character(status),
    notes=as.character(notes), stringsAsFactors=FALSE
  )
  logline("[",status,"] ",item," | expected=",expected,
          " | observed=",observed)
}

required <- c(MAT694,SOFT694,MAT508,SOFT508,MAIN_MAT)
missing <- required[!file.exists(required)]

if(length(missing)) {
  twrite(c(
    "R3_STEP0C_SITE_CONTROL_PREFLIGHT_HOLD_MISSING_FILES",
    paste0("missing=",paste(missing,collapse=";")),
    "model_fit_executed=NO",
    "candidate_testing_executed=NO",
    "raw_SRA_download_executed=NO"
  ),HOLD)
  cat("Missing required files:\n",paste(missing,collapse="\n"),"\n")
  quit(save="no",status=101,runLast=FALSE)
}

logline("============================================================")
logline("R3 Step0C — site sensitivity + healthy control preflight")
logline("NO statistical model. NO candidate testing.")
logline("============================================================")

# --------------------------------------------------------------------------
# Generic GEO SOFT parser.
# --------------------------------------------------------------------------

parse_soft <- function(path,dataset) {
  s <- readLines(gzfile(path,"rt"),warn=FALSE)
  starts <- grep("^\\^SAMPLE = GSM",s)
  ends <- c(starts[-1]-1L,length(s))
  blocks <- Map(function(a,b) s[a:b],starts,ends)

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

  rows <- vector("list",length(blocks))
  for(i in seq_along(blocks)) {
    b <- blocks[[i]]
    gsm <- sub("^\\^SAMPLE = ","",b[1])
    title <- pick1(b,"!Sample_title = ")
    source <- pick1(b,"!Sample_source_name_ch1 = ")
    chars <- pickall(b,"!Sample_characteristics_ch1 = ")

    txt <- tolower(paste(title,source,paste(chars,collapse=" | ")))

    m <- regmatches(title,regexpr("(?i)pat[ -]*[0-9]+",title,perl=TRUE))
    patient_num <- if(length(m) && nzchar(m))
      suppressWarnings(as.integer(sub(".*?([0-9]+).*","\\1",m))) else NA_integer_
    patient_id <- if(is.finite(patient_num)) paste0("Pat-",patient_num) else NA_character_

    timepoint <- NA_character_
    if(dataset=="GSE249694") {
      if(grepl("prebl|pre.?pea|baseline",txt,perl=TRUE)) timepoint <- "PRE"
      if(grepl("(^|[^a-z])fu([^a-z]|$)|post.?pea|follow.?up",txt,perl=TRUE))
        timepoint <- "POST"
    }

    site <- "UNKNOWN"
    if(dataset=="GSE249694") {
      # This subseries is explicitly septum-only by GEO design.
      site <- "INTERVENTRICULAR_SEPTUM"
    } else if(dataset=="GSE291508") {
      if(grepl("ivs|sept",txt,perl=TRUE)) site <- "INTERVENTRICULAR_SEPTUM"
      if(grepl("(^|[^a-z])rv([^a-z]|$)|right vent",txt,perl=TRUE))
        site <- "RIGHT_VENTRICLE"
    }

    rows[[i]] <- data.frame(
      dataset=dataset,
      geo_accession=gsm,
      title=title,
      source_name=source,
      patient_id=patient_id,
      patient_number=patient_num,
      timepoint=timepoint,
      site_class=site,
      stringsAsFactors=FALSE
    )
  }
  do.call(rbind,rows)
}

s694 <- parse_soft(SOFT694,"GSE249694")
s508 <- parse_soft(SOFT508,"GSE291508")

# --------------------------------------------------------------------------
# GSE249694 structural authority.
# --------------------------------------------------------------------------

add("GSE249694 total samples","6",nrow(s694),
    if(nrow(s694)==6L) "PASS" else "FAIL")
add("GSE249694 PRE septum","3",
    sum(s694$timepoint=="PRE" & s694$site_class=="INTERVENTRICULAR_SEPTUM"),
    if(sum(s694$timepoint=="PRE" &
           s694$site_class=="INTERVENTRICULAR_SEPTUM")==3L) "PASS" else "FAIL")
add("GSE249694 POST septum","3",
    sum(s694$timepoint=="POST" & s694$site_class=="INTERVENTRICULAR_SEPTUM"),
    if(sum(s694$timepoint=="POST" &
           s694$site_class=="INTERVENTRICULAR_SEPTUM")==3L) "PASS" else "FAIL")

ids694 <- sort(unique(s694$patient_id))
add("GSE249694 patient identities","Pat-33;Pat-72;Pat-91",
    paste(ids694,collapse=";"),
    if(identical(ids694,c("Pat-33","Pat-72","Pat-91"))) "PASS" else "FAIL")

p694 <- do.call(rbind,lapply(ids694,function(id) {
  z <- s694[s694$patient_id==id,,drop=FALSE]
  pre <- z[z$timepoint=="PRE",,drop=FALSE]
  post <- z[z$timepoint=="POST",,drop=FALSE]
  data.frame(
    patient_id=id,
    n_PRE=nrow(pre), n_POST=nrow(post),
    paired=(nrow(pre)==1L && nrow(post)==1L),
    PRE_gsm=if(nrow(pre)==1L) pre$geo_accession else NA_character_,
    PRE_title=if(nrow(pre)==1L) pre$title else NA_character_,
    PRE_site=if(nrow(pre)==1L) pre$site_class else NA_character_,
    POST_gsm=if(nrow(post)==1L) post$geo_accession else NA_character_,
    POST_title=if(nrow(post)==1L) post$title else NA_character_,
    POST_site=if(nrow(post)==1L) post$site_class else NA_character_,
    same_site=if(nrow(pre)==1L && nrow(post)==1L)
      pre$site_class==post$site_class else NA,
    stringsAsFactors=FALSE
  )
}))
add("GSE249694 exact PRE/POST pairs","3",sum(p694$paired),
    if(sum(p694$paired)==3L) "PASS" else "FAIL")
add("GSE249694 same-site pairs","3",
    sum(p694$paired & p694$same_site,na.rm=TRUE),
    if(sum(p694$paired & p694$same_site,na.rm=TRUE)==3L) "PASS" else "FAIL")

awrite(s694,MAN694)
awrite(p694,PAIR694)

# --------------------------------------------------------------------------
# GSE291508 healthy-control structure.
# --------------------------------------------------------------------------

add("GSE291508 total samples","20",nrow(s508),
    if(nrow(s508)==20L) "PASS" else "FAIL")
add("GSE291508 healthy control RV","10",
    sum(s508$site_class=="RIGHT_VENTRICLE"),
    if(sum(s508$site_class=="RIGHT_VENTRICLE")==10L) "PASS" else "FAIL")
add("GSE291508 healthy control septum","10",
    sum(s508$site_class=="INTERVENTRICULAR_SEPTUM"),
    if(sum(s508$site_class=="INTERVENTRICULAR_SEPTUM")==10L) "PASS" else "FAIL")

ids508 <- sort(unique(s508$patient_id))
add("GSE291508 unique healthy donors","10",length(ids508),
    if(length(ids508)==10L) "PASS" else "FAIL")

p508 <- do.call(rbind,lapply(ids508,function(id) {
  z <- s508[s508$patient_id==id,,drop=FALSE]
  rv <- z[z$site_class=="RIGHT_VENTRICLE",,drop=FALSE]
  ivs <- z[z$site_class=="INTERVENTRICULAR_SEPTUM",,drop=FALSE]
  data.frame(
    patient_id=id,
    n_RV=nrow(rv), n_IVS=nrow(ivs),
    paired=(nrow(rv)==1L && nrow(ivs)==1L),
    RV_gsm=if(nrow(rv)==1L) rv$geo_accession else NA_character_,
    RV_title=if(nrow(rv)==1L) rv$title else NA_character_,
    IVS_gsm=if(nrow(ivs)==1L) ivs$geo_accession else NA_character_,
    IVS_title=if(nrow(ivs)==1L) ivs$title else NA_character_,
    stringsAsFactors=FALSE
  )
}))
add("GSE291508 matched RV/IVS healthy donors","10",sum(p508$paired),
    if(sum(p508$paired)==10L) "PASS" else "FAIL")

awrite(s508,MAN508)
awrite(p508,PAIR508)

# --------------------------------------------------------------------------
# Processed matrix matching and gene-ID overlap.
# --------------------------------------------------------------------------

read_matrix <- function(path) {
  read.delim(gzfile(path,"rt"),stringsAsFactors=FALSE,
             check.names=FALSE,quote="",comment.char="")
}

m696 <- read_matrix(MAIN_MAT)
m694 <- read_matrix(MAT694)
m508 <- read_matrix(MAT508)

find_gene_col <- function(x) {
  n <- names(x)
  cand <- which(tolower(n) %in% c(
    "ensembl gene id","ensembl_gene_id","geneid","gene_id"
  ))
  if(length(cand)) return(cand[1])
  # fallback: first annotation column with ENSG-like values
  for(j in seq_len(min(10L,ncol(x)))) {
    v <- as.character(x[[j]])
    frac <- mean(grepl("^ENSG[0-9]+",v))
    if(is.finite(frac) && frac>0.5) return(j)
  }
  NA_integer_
}

match_samples <- function(mat,sm) {
  cn <- names(mat)
  base <- sub("_[0-9]+$","",cn)
  cc <- canon(cn)
  cb <- canon(base)
  tc <- canon(sm$title)
  idx <- rep(NA_integer_,nrow(sm))
  for(i in seq_len(nrow(sm))) {
    h <- unique(c(which(cc==tc[i]),which(cb==tc[i])))
    if(length(h)==1L) idx[i] <- h
  }
  idx
}

idx694 <- match_samples(m694,s694)
idx508 <- match_samples(m508,s508)

add("GSE249694 matrix sample matches","6",
    sum(!is.na(idx694)),
    if(sum(!is.na(idx694))==6L &&
       length(unique(idx694[!is.na(idx694)]))==6L) "PASS" else "FAIL")
add("GSE291508 matrix sample matches","20",
    sum(!is.na(idx508)),
    if(sum(!is.na(idx508))==20L &&
       length(unique(idx508[!is.na(idx508)]))==20L) "PASS" else "FAIL")

gc696 <- find_gene_col(m696)
gc694 <- find_gene_col(m694)
gc508 <- find_gene_col(m508)

if(any(is.na(c(gc696,gc694,gc508)))) {
  add("Ensembl gene-ID columns","present",
      paste(gc696,gc694,gc508,sep=";"),"FAIL")
  genes696 <- genes694 <- genes508 <- character()
} else {
  add("Ensembl gene-ID columns","present",
      paste(names(m696)[gc696],names(m694)[gc694],
            names(m508)[gc508],sep=" | "),"PASS")
  stripver <- function(x) sub("\\.[0-9]+$","",as.character(x))
  genes696 <- unique(stripver(m696[[gc696]]))
  genes694 <- unique(stripver(m694[[gc694]]))
  genes508 <- unique(stripver(m508[[gc508]]))
}

over696_694 <- length(intersect(genes696,genes694))
over696_508 <- length(intersect(genes696,genes508))
over_all <- length(Reduce(intersect,list(genes696,genes694,genes508)))

matrix_aud <- data.frame(
  dataset=c("GSE249696","GSE249694","GSE291508"),
  matrix_rows=c(nrow(m696),nrow(m694),nrow(m508)),
  sample_columns_expected=c(95,6,20),
  sample_columns_matched=c(95,sum(!is.na(idx694)),sum(!is.na(idx508))),
  unique_ensembl_ids=c(length(genes696),length(genes694),length(genes508)),
  overlap_with_GSE249696=c(length(genes696),over696_694,over696_508),
  stringsAsFactors=FALSE
)
matrix_aud <- rbind(
  matrix_aud,
  data.frame(
    dataset="ALL_THREE_INTERSECTION",
    matrix_rows=NA,
    sample_columns_expected=NA,
    sample_columns_matched=NA,
    unique_ensembl_ids=over_all,
    overlap_with_GSE249696=over_all,
    stringsAsFactors=FALSE
  )
)
awrite(matrix_aud,MATRIX_AUD)

add("GSE249694 gene overlap with GSE249696",">=90% of smaller universe",
    over696_694,
    if(length(genes694)>0 &&
       over696_694/min(length(genes696),length(genes694))>=0.90)
      "PASS" else "FAIL")
add("GSE291508 gene overlap with GSE249696",">=90% of smaller universe",
    over696_508,
    if(length(genes508)>0 &&
       over696_508/min(length(genes696),length(genes508))>=0.90)
      "PASS" else "FAIL")

# --------------------------------------------------------------------------
# Freeze roles/limitations, NOT models.
# --------------------------------------------------------------------------

roles <- data.frame(
  dataset=c("GSE249696","GSE249694","GSE291508_IVS","GSE291508_RV"),
  planned_role=c(
    "MAIN_21_PAIR_UNLOADING_ASSOCIATION",
    "SAME_PATIENT_SAME_SITE_PRE_POST_SENSITIVITY",
    "POSTPEA_SEPTUM_RESIDUAL_ABNORMALITY_SUPPORTIVE_COMPARATOR",
    "BASELINE_RV_HEALTHY_REFERENCE_SUPPORTIVE_COMPARATOR"
  ),
  independent_validation=c("NO","NO","NO","NO"),
  major_limitation=c(
    "BL_RV_FREE_WALL_TO_FU_SEPTUM_COMPLETE_SITE_CONFOUND",
    "N_EQUALS_3_LOW_POWER_SAME_PATIENTS_AS_MAIN_COHORT",
    "SEPARATE_HEALTHY_CONTROL_COHORT_PROCESSING_ANNOTATION_DIFFERENCES",
    "SEPARATE_HEALTHY_CONTROL_COHORT_PROCESSING_ANNOTATION_DIFFERENCES"
  ),
  model_frozen="NO",
  stringsAsFactors=FALSE
)
awrite(roles,ROLE)

audit <- do.call(rbind,A)
awrite(audit,AUDIT)

fails <- sum(audit$status=="FAIL")

if(fails>0L) {
  twrite(c(
    "R3_STEP0C_SITE_CONTROL_PREFLIGHT_HOLD",
    paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
    paste0("hard_failures=",fails),
    "model_fit_executed=NO",
    "candidate_testing_executed=NO",
    "recovery_persistence_classification_executed=NO",
    "raw_SRA_download_executed=NO",
    "next_action=Return Step0C outputs/log to ChatGPT."
  ),HOLD)
  logline("FINAL_GATE: R3_STEP0C_SITE_CONTROL_PREFLIGHT_HOLD")
  quit(save="no",status=102,runLast=FALSE)
}

twrite(c(
  "R3_STEP0C_SITE_CONTROL_PREFLIGHT_PASS",
  paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
  "GSE249694_samples=6",
  "GSE249694_patients=Pat-33;Pat-72;Pat-91",
  "GSE249694_PRE_septum=3",
  "GSE249694_POST_septum=3",
  "GSE249694_same_site_pairs=3",
  "GSE249694_role=SAME_PATIENT_SAME_SITE_PRE_POST_SENSITIVITY",
  "GSE249694_independent_validation=NO",
  "GSE291508_samples=20",
  "GSE291508_healthy_RV=10",
  "GSE291508_healthy_septum=10",
  "GSE291508_matched_RV_IVS_donors=10",
  "GSE291508_IVS_role=POSTPEA_SEPTUM_RESIDUAL_ABNORMALITY_SUPPORTIVE_COMPARATOR",
  "GSE291508_independent_validation=NO",
  paste0("genes_overlap_GSE249696_GSE249694=",over696_694),
  paste0("genes_overlap_GSE249696_GSE291508=",over696_508),
  paste0("genes_common_all_three=",over_all),
  "public_processed_matrices=DESEQ_NORMALIZED_COUNTS",
  "processed_matrices_as_raw_DESeq2_input_allowed=NO",
  "model_formula_frozen=NO",
  "recovery_persistence_rule_frozen=NO",
  "candidate_testing_executed=NO",
  "model_fit_executed=NO",
  "raw_SRA_download_executed=NO",
  "next_stage=ChatGPT audit then R3 analysis-route/model/recovery-persistence contract"
),PASS)

logline("FINAL_GATE: R3_STEP0C_SITE_CONTROL_PREFLIGHT_PASS")
quit(save="no",status=0,runLast=FALSE)
