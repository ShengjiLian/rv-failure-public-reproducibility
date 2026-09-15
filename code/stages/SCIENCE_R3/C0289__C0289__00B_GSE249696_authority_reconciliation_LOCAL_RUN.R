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
# RV Project — R3 GSE249696 Step 0B
# PUBLICATION PAIR-UNIVERSE + DATA-AUTHORITY RECONCILIATION
#
# NO expression model. NO candidate testing. NO recovery/persistence testing.
#
# Inputs:
#   1) Accepted R3 Step0 local pair/sample manifests
#   2) Nature Source Data Fig. 5 XLSX
#   3) Nature Supplementary Tables XLSX
#
# Public authority facts frozen BEFORE this run:
#   GEO GSE249696: 22 matched BL/FU pairs
#   Published Fig. 5 / author README: paired analysis n=21
#   Published paired risk groups: moderate=9, intermediate=8, severe=4
#
# Local GEO Step0 gives 22 pairs = moderate=10, intermediate=8, severe=4.
# Therefore the publication excluded exactly ONE moderate-risk GEO-matched pair.
#
# This gate attempts to identify that exact pair from publication source files.
# If the identity cannot be resolved uniquely, it FAILS CLOSED and no model is run.
#
# Data-authority question:
#   GEO supplementary matrix is DESeq-normalized gene counts.
#   GEO sample records state DESeq2 contrasts were made from the RAW count matrix.
#   Therefore the normalized matrix MUST NOT be passed into DESeq2 as if raw counts.
#   Final model route remains unfrozen until this reconciliation is accepted.
# ==============================================================================

options(stringsAsFactors=FALSE, warn=1)

ROOT <- normalizePath(getwd(), winslash="/", mustWork=TRUE)
if(!identical(ROOT,RV_PROJECT_ROOT)) stop("Expected D:/RV_project")

RES <- file.path(ROOT,"results","R3_GSE249696")
AUTH <- file.path(ROOT,"data","authority","GSE249696")
DATA <- file.path(ROOT,"data","processed","GSE249696")
LOGDIR <- file.path(ROOT,"logs")
dir.create(AUTH,recursive=TRUE,showWarnings=FALSE)
dir.create(RES,recursive=TRUE,showWarnings=FALSE)
dir.create(LOGDIR,recursive=TRUE,showWarnings=FALSE)

PAIR <- file.path(RES,"R3_GSE249696_pair_manifest.csv")
SAMPLE <- file.path(RES,"R3_GSE249696_sample_manifest.csv")
MATRIX <- file.path(DATA,"GSE249696_ext395_rnaseq.txt.gz")

FIG5 <- file.path(AUTH,"44161_2025_672_MOESM7_ESM.xlsx")
SUPP <- file.path(AUTH,"44161_2025_672_MOESM3_ESM.xlsx")

OUT_AUD <- file.path(RES,"R3_GSE249696_step0B_authority_audit.csv")
OUT_SCAN <- file.path(RES,"R3_GSE249696_step0B_publication_patient_scan.csv")
OUT_PAIR <- file.path(RES,"R3_GSE249696_step0B_reconciled_pair_universe.csv")
OUT_DATA <- file.path(RES,"R3_GSE249696_step0B_data_authority.csv")
OUT_PASS <- file.path(RES,"R3_GSE249696_STEP0B_AUTHORITY_RECONCILIATION_PASS.txt")
OUT_HOLD <- file.path(RES,"R3_GSE249696_STEP0B_AUTHORITY_RECONCILIATION_HOLD.txt")
LOG <- file.path(LOGDIR,"R3_GSE249696_STEP0B_AUTHORITY_RECONCILIATION.log")

if(file.exists(LOG)) {
  old <- file.path(
    LOGDIR,
    paste0("R3_GSE249696_STEP0B_AUTHORITY_RECONCILIATION_",
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
    item=as.character(item), expected=as.character(expected),
    observed=as.character(observed), status=as.character(status),
    notes=as.character(notes), stringsAsFactors=FALSE
  )
  logline("[",status,"] ",item," | expected=",expected,
          " | observed=",observed)
}

logline("============================================================")
logline("R3 GSE249696 Step 0B — publication/data authority reconciliation")
logline("NO model fit. NO candidate testing.")
logline("============================================================")

for(p in c(PAIR,SAMPLE,MATRIX)) {
  must(file.exists(p),paste0("Missing accepted Step0 input: ",p))
}

if(!file.exists(FIG5) || !file.exists(SUPP)) {
  twrite(c(
    "R3_GSE249696_STEP0B_AUTHORITY_RECONCILIATION_HOLD_DOWNLOAD",
    paste0("source_data_fig5_present=",file.exists(FIG5)),
    paste0("supplementary_tables_present=",file.exists(SUPP)),
    paste0("source_data_fig5_destination=",FIG5),
    paste0("supplementary_tables_destination=",SUPP),
    "model_fit_executed=NO",
    "candidate_testing_executed=NO"
  ),OUT_HOLD)
  logline("FINAL_GATE: R3_GSE249696_STEP0B_HOLD_MISSING_PUBLICATION_FILES")
  quit(save="no",status=91,runLast=FALSE)
}

must(requireNamespace("readxl",quietly=TRUE),
     "readxl is required but unavailable")

pm <- read.csv(PAIR,stringsAsFactors=FALSE,check.names=FALSE)
sm <- read.csv(SAMPLE,stringsAsFactors=FALSE,check.names=FALSE)

paired <- pm[as.logical(pm$paired),,drop=FALSE]
must(nrow(paired)==22L,"Accepted GEO pair universe changed from 22")

risk_tab <- table(factor(
  paired$BL_risk,
  levels=c("MODERATE","INTERMEDIATE","SEVERE")
))
add("GEO matched pairs","22",nrow(paired),
    if(nrow(paired)==22L) "PASS" else "FAIL")
add("GEO paired moderate","10",risk_tab["MODERATE"],
    if(risk_tab["MODERATE"]==10L) "PASS" else "FAIL")
add("GEO paired intermediate","8",risk_tab["INTERMEDIATE"],
    if(risk_tab["INTERMEDIATE"]==8L) "PASS" else "FAIL")
add("GEO paired severe","4",risk_tab["SEVERE"],
    if(risk_tab["SEVERE"]==4L) "PASS" else "FAIL")

# Publication authority from article/author README.
add("publication paired n","21","21","PASS",
    "Nature Fig.5 / author GitHub README authority")
add("publication paired moderate","9","9","PASS")
add("publication paired intermediate","8","8","PASS")
add("publication paired severe","4","4","PASS")
add("publication-minus-GEO pair delta","-1","-1","PASS",
    "Exactly one moderate-risk GEO-matched pair is absent from publication paired analysis")

# --------------------------------------------------------------------------
# Read every cell of both publication XLSX files as text.
# --------------------------------------------------------------------------

read_all_cells <- function(path,source_label) {
  sheets <- readxl::excel_sheets(path)
  out <- list()
  k <- 0L
  for(sh in sheets) {
    x <- suppressMessages(
      readxl::read_excel(path,sheet=sh,col_names=FALSE,.name_repair="minimal")
    )
    if(!nrow(x) || !ncol(x)) next
    for(j in seq_len(ncol(x))) {
      v <- as.character(x[[j]])
      keep <- !is.na(v) & nzchar(trimws(v))
      if(any(keep)) {
        k <- k+1L
        out[[k]] <- data.frame(
          source=source_label,
          sheet=sh,
          row=which(keep),
          col=j,
          text=v[keep],
          stringsAsFactors=FALSE
        )
      }
    }
  }
  if(!length(out)) {
    data.frame(source=character(),sheet=character(),
               row=integer(),col=integer(),text=character())
  } else do.call(rbind,out)
}

logline("[INFO] Scanning Nature Source Data Fig.5 XLSX.")
cells_fig5 <- read_all_cells(FIG5,"SOURCE_DATA_FIG5")
logline("[INFO] Scanning Nature Supplementary Tables XLSX.")
cells_supp <- read_all_cells(SUPP,"SUPPLEMENTARY_TABLES")
cells <- rbind(cells_fig5,cells_supp)
cells$canon <- canon(cells$text)

must(nrow(cells)>0L,"Publication XLSX files yielded no readable cells")

# --------------------------------------------------------------------------
# Scan publication files for each of the 22 GEO paired patient IDs.
# Match patient identity with numeric-boundary awareness.
# --------------------------------------------------------------------------

scan_rows <- list()

for(i in seq_len(nrow(paired))) {
  id <- paired$patient_id[i]
  num <- as.integer(sub("^Pat-","",id))

  # Text-level pattern accepts Pat-31, Pat 31, Pat31, Pat31.BL, etc.,
  # while guarding against 3 matching 31, 33, etc.
  pat <- paste0("(?i)\\bpat[\\s._-]*0*",num,"(?![0-9])")
  hit <- grepl(pat,cells$text,perl=TRUE)
  h <- cells[hit,,drop=FALSE]

  fig5_hits <- sum(h$source=="SOURCE_DATA_FIG5")
  supp_hits <- sum(h$source=="SUPPLEMENTARY_TABLES")

  scan_rows[[i]] <- data.frame(
    patient_id=id,
    BL_risk=paired$BL_risk[i],
    BL_gsm=paired$BL_gsm[i],
    FU_gsm=paired$FU_gsm[i],
    fig5_hit_count=fig5_hits,
    supplementary_tables_hit_count=supp_hits,
    any_publication_hit=(nrow(h)>0L),
    fig5_example=if(fig5_hits) h$text[h$source=="SOURCE_DATA_FIG5"][1] else NA_character_,
    supp_example=if(supp_hits) h$text[h$source=="SUPPLEMENTARY_TABLES"][1] else NA_character_,
    stringsAsFactors=FALSE
  )
}

scan <- do.call(rbind,scan_rows)
awrite(scan,OUT_SCAN)

# Strongest machine-resolvable authority:
# First prefer an EXPLICIT publication statement naming the excluded pair.
#
# In the Nature Supplementary Tables, the publication states:
#   "Pat-96-BL and Pat-96-FU was excluded from the paired comparison of RNA-seq data"
#
# This is stronger authority than trying to infer the n=21 universe from whether
# patient IDs happen to appear in a figure-source workbook, because the Fig.5
# source-data sheets are mostly pathway/plot values and need not enumerate all
# patient IDs.
fig5_present <- scan$patient_id[scan$fig5_hit_count>0]
fig5_absent <- scan$patient_id[scan$fig5_hit_count==0]

resolution_class <- "UNRESOLVED"
excluded_id <- NA_character_
authority <- NA_character_

# Detect explicit exclusion statements in Supplementary Tables.
supp_cells <- cells[cells$source=="SUPPLEMENTARY_TABLES",,drop=FALSE]
explicit_candidates <- character()

for(i in seq_len(nrow(paired))) {
  id <- paired$patient_id[i]
  num <- as.integer(sub("^Pat-","",id))

  patient_pat <- paste0("(?i)\\bpat[\\s._-]*0*",num,"(?![0-9])")
  exclusion_pat <- "(?i)exclud(ed|e|ing)|omit(ted)?|removed|not included"

  hit_patient <- grepl(patient_pat,supp_cells$text,perl=TRUE)
  hit_excl <- grepl(exclusion_pat,supp_cells$text,perl=TRUE)

  if(any(hit_patient & hit_excl)) {
    explicit_candidates <- c(explicit_candidates,id)
  }
}
explicit_candidates <- unique(explicit_candidates)

if(length(explicit_candidates)==1L) {
  excluded_id <- explicit_candidates
  authority <- "NATURE_SUPPLEMENTARY_TABLES_EXPLICIT_EXCLUSION_STATEMENT"
  resolution_class <- "RESOLVED_EXPLICIT"
} else if(length(fig5_present)==21L && length(fig5_absent)==1L) {
  excluded_id <- fig5_absent
  authority <- "NATURE_SOURCE_DATA_FIG5_EXACT_21_OF_22"
  resolution_class <- "RESOLVED"
} else {
  # Secondary route: if Supplementary Tables contain exactly 21 of 22 pair IDs.
  supp_present <- scan$patient_id[scan$supplementary_tables_hit_count>0]
  supp_absent <- scan$patient_id[scan$supplementary_tables_hit_count==0]
  if(length(supp_present)==21L && length(supp_absent)==1L) {
    excluded_id <- supp_absent
    authority <- "NATURE_SUPPLEMENTARY_TABLES_EXACT_21_OF_22"
    resolution_class <- "RESOLVED_SECONDARY"
  }
}

if(!is.na(excluded_id)) {
  exrisk <- paired$BL_risk[match(excluded_id,paired$patient_id)]
  must(identical(exrisk,"MODERATE"),
       "Publication-excluded pair is not moderate; conflicts with published 9/8/4")
}

add("publication pair identity resolution","publication-excluded pair uniquely resolved",
    resolution_class,
    if(resolution_class %in% c("RESOLVED_EXPLICIT","RESOLVED","RESOLVED_SECONDARY"))
      "PASS" else "HOLD",
    if(is.na(excluded_id))
      paste0("Fig5 IDs found=",length(fig5_present),
             "; explicit exclusion candidates=",paste(explicit_candidates,collapse=";"),
             "; exact excluded patient not machine-resolved")
    else paste0("excluded=",excluded_id,"; authority=",authority))

# Reconciled pair universe is written only if resolved.
if(!is.na(excluded_id)) {
  rec <- paired
  rec$publication_pair_status <- ifelse(
    rec$patient_id==excluded_id,
    "EXCLUDED_FROM_PUBLISHED_N21",
    "INCLUDED_IN_PUBLISHED_N21"
  )
  rec$publication_authority <- authority
  awrite(rec,OUT_PAIR)
}

# --------------------------------------------------------------------------
# Data-authority freeze.
# --------------------------------------------------------------------------

# Confirm local supplementary matrix structure is normalized/processed authority.
mat <- read.delim(
  gzfile(MATRIX,"rt"),stringsAsFactors=FALSE,
  check.names=FALSE,quote="",comment.char=""
)
sample_cols <- sm$matrix_column
idx <- match(sample_cols,names(mat))
must(all(!is.na(idx)),"Sample columns disappeared from processed matrix")

v <- do.call(cbind,lapply(mat[,idx,drop=FALSE],
                          function(z) suppressWarnings(as.numeric(z))))
integer_frac <- mean(abs(v-round(v))<1e-8,na.rm=TRUE)

data_auth <- data.frame(
  item=c(
    "GEO_supplementary_matrix",
    "local_matrix_rows",
    "local_matrix_sample_columns",
    "local_matrix_integer_like_fraction",
    "GEO_declared_scale",
    "DESeq2_contrast_input_declared_by_GEO",
    "processed_matrix_can_be_used_as_raw_DESeq2_input",
    "raw_data_available",
    "raw_SRA_download_executed",
    "primary_model_route_status"
  ),
  value=c(
    "GSE249696_ext395_rnaseq.txt.gz",
    nrow(mat),
    length(idx),
    integer_frac,
    "DESEQ_NORMALIZED_GENE_COUNTS",
    "RAW_COUNT_MATRIX",
    "NO",
    "SRA",
    "NO",
    "UNFROZEN_PENDING_PAIR_RECONCILIATION_AND_STRATEGY"
  ),
  stringsAsFactors=FALSE
)
awrite(data_auth,OUT_DATA)

add("normalized matrix raw-DESeq2 eligibility","NO","NO","PASS",
    "GEO explicitly describes supplementary table as DESeq-normalized gene counts; DESeq2 contrasts used raw count matrix")

audit <- do.call(rbind,A)
awrite(audit,OUT_AUD)

holds <- sum(audit$status=="HOLD")
fails <- sum(audit$status=="FAIL")

if(fails>0L || holds>0L || is.na(excluded_id)) {
  twrite(c(
    "R3_GSE249696_STEP0B_AUTHORITY_RECONCILIATION_HOLD",
    paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
    paste0("hard_failures=",fails),
    paste0("hold_items=",holds),
    paste0("fig5_pair_ids_detected=",length(fig5_present)),
    paste0("excluded_patient_resolved=",ifelse(is.na(excluded_id),"NO","YES")),
    "GEO_pair_universe=22",
    "publication_pair_universe=21",
    "publication_pair_risk=9_MODERATE_8_INTERMEDIATE_4_SEVERE",
    "processed_matrix_is_DESeq_normalized=YES",
    "processed_matrix_as_raw_DESeq2_input_allowed=NO",
    "model_formula_frozen=NO",
    "model_fit_executed=NO",
    "candidate_testing_executed=NO",
    "next_action=Return Step0B outputs to ChatGPT; do not fit a model."
  ),OUT_HOLD)
  logline("FINAL_GATE: R3_GSE249696_STEP0B_AUTHORITY_RECONCILIATION_HOLD")
  quit(save="no",status=92,runLast=FALSE)
}

included <- paired$patient_id[paired$patient_id!=excluded_id]
included_risks <- table(factor(
  paired$BL_risk[paired$patient_id!=excluded_id],
  levels=c("MODERATE","INTERMEDIATE","SEVERE")
))
must(identical(as.integer(included_risks),c(9L,8L,4L)),
     "Reconciled n21 does not reproduce published 9/8/4")

twrite(c(
  "R3_GSE249696_STEP0B_AUTHORITY_RECONCILIATION_PASS",
  paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
  "dataset=GSE249696",
  "GEO_pair_universe=22",
  "publication_pair_universe=21",
  paste0("publication_excluded_pair=",excluded_id),
  paste0("publication_exclusion_authority=",authority),
  "publication_pair_moderate=9",
  "publication_pair_intermediate=8",
  "publication_pair_severe=4",
  paste0("publication_included_pairs=",paste(sort(included),collapse=";")),
  "BL_tissue=RV_FREE_WALL",
  "FU_tissue=INTERVENTRICULAR_SEPTUM",
  "treatment_timepoint_confounded_with_site=YES_COMPLETE",
  "processed_matrix_authority=DESEQ_NORMALIZED_GENE_COUNTS",
  "DESeq2_contrasts_originally_based_on=RAW_COUNT_MATRIX",
  "processed_matrix_as_raw_DESeq2_input_allowed=NO",
  "raw_data_available=SRA",
  "raw_SRA_download_executed=NO",
  "model_formula_frozen=NO",
  "recovery_persistence_rule_frozen=NO",
  "candidate_testing_executed=NO",
  "model_fit_executed=NO",
  "next_stage=ChatGPT audit then R3 analysis-route/model contract"
),OUT_PASS)

logline("[PASS] Publication n21 resolved; excluded pair: ",excluded_id)
logline("[PASS] Reconciled risk counts: 9 moderate / 8 intermediate / 4 severe")
logline("[PASS] Processed normalized matrix is NOT raw-DESeq2 input")
logline("FINAL_GATE: R3_GSE249696_STEP0B_AUTHORITY_RECONCILIATION_PASS")
quit(save="no",status=0,runLast=FALSE)
