# ---- RV PUBLIC REPRODUCIBILITY PORTABILITY OVERLAY V1.0 ----
.RV_PROJECT_ROOT_ENV <- Sys.getenv('RV_PROJECT_ROOT', unset='')
RV_PROJECT_ROOT <- if (nzchar(.RV_PROJECT_ROOT_ENV)) {
  normalizePath(.RV_PROJECT_ROOT_ENV, winslash='/', mustWork=TRUE)
} else {
  normalizePath(getwd(), winslash='/', mustWork=TRUE)
}
# This overlay changes path binding only; scientific/statistical semantics remain historical authority.

source(file.path(RV_PROJECT_ROOT, 'code', 'lib', 'rv_runtime_helpers.R'))


options(stringsAsFactors=FALSE, warn=1)
args <- commandArgs(trailingOnly=TRUE)
STAMP <- if(length(args)>=1 && nzchar(args[1])) args[1] else format(Sys.time(),"%Y%m%d_%H%M%S")
ROOT <- normalizePath(getwd(),winslash="/",mustWork=TRUE)
if(!identical(ROOT,RV_PROJECT_ROOT)) stop("Expected working directory D:/RV_project",call.=FALSE)

RESROOT <- file.path(ROOT,"results","R4A_CTEPH_SEVERITY_PREFLIGHT_V1_2")
OUT <- file.path(RESROOT,STAMP)
dir.create(OUT,recursive=TRUE,showWarnings=FALSE)
SNAP <- file.path(OUT,"input_snapshot")
dir.create(SNAP,recursive=TRUE,showWarnings=FALSE)

sha256 <- function(p) {
  if(!file.exists(p)) return(NA_character_)
  unname(tools::md5sum(p)) # placeholder replaced below if digest available
}
sha256_ps <- function(p) {
  # Windows certutil output is locale-sensitive; use openssl if available, otherwise digest.
  if(requireNamespace("digest",quietly=TRUE)) return(digest::digest(file=p,algo="sha256",serialize=FALSE))
  stop("R package 'digest' is required for SHA256 verification",call.=FALSE)
}

# Gate9L Full94 V1.5 engineering overlay.
# A31 is scientifically stable but h5_path carries the isolated fresh-run root.
# Normalize ONLY the exact current ROOT/data/tximport/GSE345645/h5/ prefix back
# to the frozen canonical path. Require 142 hits plus historical bytes/SHA.
r0_sample_map_path_normalized <- function(path) {
  if(!file.exists(path)) return(list(ok=FALSE,detail="sample map missing"))
  raw <- readBin(path,"raw",n=file.info(path)$size)
  txt <- rawToChar(raw)
  current_prefix <- paste0(
    normalizePath(file.path(ROOT,"data","tximport","GSE345645","h5"),
                  winslash="/",mustWork=TRUE),"/"
  )
  historical_prefix <- "D:/RV_project/data/tximport/GSE345645/h5/"
  m <- gregexpr(current_prefix,txt,fixed=TRUE)[[1L]]
  n_hit <- if(length(m)==1L && identical(as.integer(m[1L]),-1L)) 0L else length(m)
  norm_txt <- gsub(current_prefix,historical_prefix,txt,fixed=TRUE)
  norm_raw <- charToRaw(norm_txt)
  tf <- tempfile(pattern="g9l_v15_c0345_a31_",fileext=".csv")
  con <- file(tf,open="wb")
  on.exit({try(close(con),silent=TRUE);unlink(tf,force=TRUE)},add=TRUE)
  writeBin(norm_raw,con)
  close(con)
  norm_sha <- tolower(sha256_ps(tf))
  ok <- n_hit==142L &&
        length(norm_raw)==15511L &&
        identical(norm_sha,"e4f51929b8d8a928690b8b90969d9e3ecb0349b9f47408e4828b32d6a3b7a175")
  list(ok=ok,
       detail=paste0("hits=",n_hit,
                     "; current_bytes=",length(raw),
                     "; normalized_bytes=",length(norm_raw),
                     "; normalized_sha256=",norm_sha))
}
awrite <- function(x,p) {
  tmp <- paste0(p,".tmp_",Sys.getpid())
  write.csv(x,tmp,row.names=FALSE,na="")
  if(file.exists(p)) unlink(p,force=TRUE)
  if(!file.rename(tmp,p)) {unlink(tmp); stop("Atomic write failed: ",p,call.=FALSE)}
}
copy_exact <- function(src,dst) {
  dir.create(dirname(dst),recursive=TRUE,showWarnings=FALSE)
  ok <- file.copy(src,dst,overwrite=TRUE,copy.mode=TRUE,copy.date=TRUE)
  if(!ok) stop("Failed to snapshot: ",src,call.=FALSE)
  if(!identical(sha256_ps(src),sha256_ps(dst))) stop("Snapshot SHA mismatch: ",src,call.=FALSE)
}
canon <- function(x) gsub("[^a-z0-9]+","",tolower(as.character(x)))

AUD <- list()
add <- function(id,requirement,observed,status,critical=TRUE,notes="") {
  AUD[[length(AUD)+1L]] <<- data.frame(
    guard_id=id, requirement=requirement, observed=as.character(observed),
    status=status, critical=if(critical) "YES" else "NO", notes=notes,
    stringsAsFactors=FALSE
  )
}
pass <- function(id,req,obs,critical=TRUE,notes="") add(id,req,obs,"PASS",critical,notes)
fail <- function(id,req,obs,critical=TRUE,notes="") add(id,req,obs,"FAIL",critical,notes)
check <- function(id,req,ok,obs,critical=TRUE,notes="") if(isTRUE(ok)) pass(id,req,obs,critical,notes) else fail(id,req,obs,critical,notes)

# Accepted upstream paths
MAT <- file.path(ROOT,"data","processed","GSE249696","GSE249696_ext395_rnaseq.txt.gz")
SAMPLE <- file.path(ROOT,"results","R3_GSE249696","R3_GSE249696_sample_manifest.csv")
FIELDS <- file.path(ROOT,"results","R3_GSE249696","R3_GSE249696_characteristics_field_summary.csv")
MDIAG <- file.path(ROOT,"results","R3_GSE249696","R3_GSE249696_matrix_diagnostic.csv")
PAIR34 <- file.path(ROOT,"results","R3_GSE249696","R3_GSE249696_step0B_reconciled_pair_universe.csv")
A05 <- file.path(ROOT,"results","R1_GSE240921","R1_GSE240921_FINAL_PRIMARY25.csv")
A20 <- file.path(ROOT,"results","R3_GSE249696","R3_STEP3F_V1_1_stable_program_identity_class_freeze.csv")
A31 <- file.path(ROOT,"results","R0","v4_LOCAL_RUN","R0_exact_step1_sample_map.csv")

EXPECTED <- c(
  A05="00dd5abaf1f6ffbcf67c34d2f95a79d6f96ca13705a2200bc7111063d4f0ce55",
  A20="49cd4da614f699f1c35d91e61d1bc59e2add6483c71aa23947fdab49a6a60068",
  A31="e4f51929b8d8a928690b8b90969d9e3ecb0349b9f47408e4828b32d6a3b7a175",
  A34="e516420531f4bb9c6e73b9e0c90f30c59a4ced4066a4dcda11965c4216739b24"
)
PATHS <- c(MAT=MAT,SAMPLE=SAMPLE,FIELDS=FIELDS,MDIAG=MDIAG,A34=PAIR34,A05=A05,A20=A20,A31=A31)
for(nm in names(PATHS)) check(paste0("FILE_",nm),paste0(nm," exists"),file.exists(PATHS[[nm]]),PATHS[[nm]])

if(any(!file.exists(PATHS))) {
  awrite(do.call(rbind,AUD),file.path(OUT,"R4A_STEP0_PREFLIGHT_AUDIT.csv"))
  awrite(data.frame(final_state="HOLD_R4A_STEP0_PREFLIGHT",run_id=STAMP,reason="MISSING_REQUIRED_INPUT",outcome_testing_executed="NO"),file.path(OUT,"R4A_STEP0_STATUS.csv"))
  quit(save="no",status=61,runLast=FALSE)
}

# Exact frozen authorities from accepted Step5 lineage.
for(nm in names(EXPECTED)) {
  p <- switch(nm,A05=A05,A20=A20,A31=A31,A34=PAIR34)
  h <- sha256_ps(p)
  if(identical(nm,"A31")) {
    a31_auth <- r0_sample_map_path_normalized(p)
    check(
      "SHA_A31",
      "A31 frozen authority after exact current-run h5_path normalization",
      isTRUE(a31_auth$ok),
      paste0("current_sha256=",tolower(h),"; ",a31_auth$detail),
      notes="Gate9L V1.5: path representation only; historical SHA is retained, not replaced"
    )
  } else {
    check(paste0("SHA_",nm),paste0(nm," exact frozen SHA256"),identical(tolower(h),tolower(EXPECTED[[nm]])),h)
  }
}

# Dataset structure and baseline universe.
sm <- read.csv(SAMPLE,stringsAsFactors=FALSE,check.names=FALSE)
req_sm <- c("geo_accession","patient_id","timepoint","site_class","esc_risk_group","sex","matrix_column")
check("SAMPLE_SCHEMA","Accepted sample-manifest columns present",all(req_sm %in% names(sm)),paste(setdiff(req_sm,names(sm)),collapse=";"))
check("SAMPLE_ROWS","95 accepted GSE249696 samples",nrow(sm)==95L,nrow(sm))
check("SAMPLE_UNIQUE_GSM","95 unique GEO accessions",length(unique(sm$geo_accession))==95L,length(unique(sm$geo_accession)))

bl <- sm[sm$timepoint=="BL",,drop=FALSE]
fu <- sm[sm$timepoint=="FU",,drop=FALSE]
check("BASELINE_N","Baseline n=71",nrow(bl)==71L,nrow(bl))
check("FOLLOWUP_N","Follow-up n=24",nrow(fu)==24L,nrow(fu),critical=FALSE,notes="Follow-up not analyzed in R4A")
check("BASELINE_PATIENT_UNIQUE","Each baseline row is one unique patient",length(unique(bl$patient_id))==71L,length(unique(bl$patient_id)))
check("BASELINE_SITE","All 71 baseline biopsies are RV free wall",all(bl$site_class=="RV_FREE_WALL"),paste(table(bl$site_class),collapse=";"))
lev <- c("MODERATE","INTERMEDIATE","SEVERE")
rt <- table(factor(bl$esc_risk_group,levels=lev))
check("RISK_COUNTS","Risk groups exactly 30/23/18",identical(as.integer(rt),c(30L,23L,18L)),paste(names(rt),as.integer(rt),collapse=";"))
check("RISK_COMPLETE","No missing baseline risk group",sum(is.na(bl$esc_risk_group)|!nzchar(bl$esc_risk_group))==0L,sum(is.na(bl$esc_risk_group)|!nzchar(bl$esc_risk_group)))
check("SEX_PRESENT","Baseline sex nonmissing",sum(is.na(bl$sex)|!nzchar(bl$sex))==0L,sum(is.na(bl$sex)|!nzchar(bl$sex)),critical=FALSE,notes="Availability only; adjustment model not yet frozen")

# Frozen targets.
a05 <- read.csv(A05,stringsAsFactors=FALSE,check.names=FALSE)
a20 <- read.csv(A20,stringsAsFactors=FALSE,check.names=FALSE)
check("PRIMARY25_N","Primary25 target family fixed at 25",nrow(a05)==25L && length(unique(a05$r0_gene_id))==25L,nrow(a05))
check("STABLE16_N","Stable program target family fixed at 16",nrow(a20)==16L && length(unique(a20$pathway))==16L,nrow(a20))
obs_class <- table(a20$program_class)
exp_class <- c(
  PROGRAM_REVERSAL_SUPPORTED=5L,
  PROGRAM_MALADAPTIVE_NONREVERSAL_WORSENING_SUPPORTED=2L,
  PROGRAM_SITE_CONFLICT=4L,
  PROGRAM_INDETERMINATE_NO_MAIN_SIGNAL=5L
)
class_ok <- setequal(names(obs_class),names(exp_class)) &&
  all(as.integer(obs_class[names(exp_class)])==as.integer(exp_class))
check("PROGRAM_CLASSES","Frozen Step3F classes unchanged",class_ok,
      paste(names(obs_class),as.integer(obs_class),collapse=";"),
      notes="V1.1 technical repair: compare category names + integer counts; do not compare table-class attributes")

# V1.2 technical repair:
# Bind the canonical Hallmark authority by its fixed project path + frozen SHA.
# Historical results/staging may legitimately contain byte-identical snapshots;
# their presence must not invalidate the canonical authority.
GMT <- file.path(ROOT,"data","authority","MSigDB","h.all.v2026.1.Hs.symbols.gmt")
EXPECTED_GMT_SHA <- "eecaf6dad908334ae885406ec72bdc0646d8917588ed7c219fac92fc5363f596"
gmt_exists <- file.exists(GMT)
gmt_sha <- if(gmt_exists) sha256_ps(GMT) else NA_character_
gmt_authority_ok <- gmt_exists && identical(tolower(gmt_sha),tolower(EXPECTED_GMT_SHA))
check("GMT_AUTHORITY_EXACT",
      "Canonical Hallmark GMT authority exists at fixed path and matches frozen SHA256",
      gmt_authority_ok,
      if(gmt_exists) paste0(GMT," | ",gmt_sha) else paste0(GMT," | MISSING"),
      notes="V1.2 repair: canonical-path binding replaces invalid whole-project uniqueness assumption")

# Inventory same-name copies for provenance only. They are never selected as runtime authority.
gmt_hits <- list.files(ROOT,pattern="^h\\.all\\.v2026\\.1\\.Hs\\.symbols\\.gmt$",recursive=TRUE,full.names=TRUE,ignore.case=FALSE)
gmt_hits <- unique(normalizePath(gmt_hits,winslash="/",mustWork=FALSE))
gmt_copy_sha <- vapply(gmt_hits,function(g) if(file.exists(g)) sha256_ps(g) else NA_character_,character(1))
same_copy_n <- sum(tolower(gmt_copy_sha)==tolower(EXPECTED_GMT_SHA),na.rm=TRUE)
other_copy_n <- sum(!is.na(gmt_copy_sha) & tolower(gmt_copy_sha)!=tolower(EXPECTED_GMT_SHA))
check("GMT_SNAPSHOT_INVENTORY",
      "Historical/staging same-name GMT copies are provenance only; canonical authority remains fixed",
      TRUE,
      paste0("same_sha_copies=",same_copy_n,";different_sha_copies=",other_copy_n),
      critical=FALSE,
      notes=paste(gmt_hits,collapse=";"))

if(gmt_authority_ok) {
  gl <- readLines(GMT,warn=FALSE)
  sets <- sub("\\t.*$","",gl)
  check("GMT_50","Hallmark GMT contains 50 sets",length(gl)==50L,length(gl))
  check("STABLE16_IN_GMT","All frozen 16 programs present in exact GMT",all(a20$pathway %in% sets),paste(setdiff(a20$pathway,sets),collapse=";"))
}

# Matrix schema/identity only. NO severity outcome computation.
check("MATRIX_BYTES","Processed matrix byte size unchanged from accepted Step0",file.info(MAT)$size==3720825,as.character(file.info(MAT)$size))
mat <- read.delim(gzfile(MAT,"rt"),stringsAsFactors=FALSE,check.names=FALSE,quote="",comment.char="")
check("MATRIX_ROWS","Processed matrix has accepted 40,932 rows",nrow(mat)==40932L,nrow(mat))
check("MATRIX_COLS","Processed matrix has accepted 103 columns",ncol(mat)==103L,ncol(mat))
check("MATRIX_LINK_95","All 95 sample-manifest matrix columns are present and unique",all(sm$matrix_column %in% names(mat)) && length(unique(sm$matrix_column))==95L,paste(sum(sm$matrix_column %in% names(mat)),length(unique(sm$matrix_column)),sep="/"))

# Baseline numeric validity without computing expression-vs-risk statistics.
if(all(bl$matrix_column %in% names(mat))) {
  numeric_frac <- vapply(bl$matrix_column,function(cc) mean(is.finite(suppressWarnings(as.numeric(mat[[cc]])))),numeric(1))
  nonneg_frac <- vapply(bl$matrix_column,function(cc) {v<-suppressWarnings(as.numeric(mat[[cc]])); mean(is.finite(v)&v>=0)},numeric(1))
  check("BASELINE_NUMERIC","Every baseline expression column >=99.9% numeric",min(numeric_frac)>=0.999,min(numeric_frac))
  check("BASELINE_NONNEG","Every baseline expression column >=99.9% nonnegative",min(nonneg_frac)>=0.999,min(nonneg_frac))
}

# Determine non-sample schema only; gene identifier selection remains unfrozen.
non_sample <- setdiff(names(mat),sm$matrix_column)
schema <- data.frame(column=names(mat),role=ifelse(names(mat)%in%sm$matrix_column,"SAMPLE_EXPRESSION","NON_SAMPLE_METADATA"),stringsAsFactors=FALSE)
awrite(schema,file.path(OUT,"R4A_STEP0_MATRIX_SCHEMA.csv"))
check("NON_SAMPLE_COLS","Expected 8 non-sample columns",length(non_sample)==8L,paste(non_sample,collapse=" | "),critical=FALSE,notes="Identifier mapping will be frozen only after independent audit")

# Metadata-field availability for later model-contract choice, no outcome peeking.
fs <- read.csv(FIELDS,stringsAsFactors=FALSE,check.names=FALSE)
awrite(fs,file.path(OUT,"R4A_STEP0_METADATA_FIELD_AVAILABILITY.csv"))

# Target identity ledger.
targets <- rbind(
  data.frame(target_family="STABLE_PROGRAM_16",target_id=a20$pathway,frozen_role=a20$program_class,failure_direction=a20$failure_direction,stringsAsFactors=FALSE),
  data.frame(target_family="PRIMARY25_GENE",target_id=a05$r0_gene_id,frozen_role="R1_STRICT_REPLICATED_PRIMARY25",failure_direction=a05$r0_direction,stringsAsFactors=FALSE)
)
awrite(targets,file.path(OUT,"R4A_STEP0_TARGET_IDENTITY.csv"))

# High-level boundary frozen before any severity outcome is inspected.
boundary <- data.frame(
  item=c(
    "module_role","cohort","biological_replicate","analysis_sample_universe","risk_order",
    "tissue","program_family","gene_family","new_discovery_allowed","program_membership_change_allowed",
    "threshold_tuning_after_results_allowed","primary_program_FDR_family","secondary_gene_FDR_family",
    "expression_source","normalized_matrix_as_raw_DESeq2_input_allowed","sample_level_program_scoring_method",
    "primary_risk_test","covariate_adjustment","outcome_results_seen_in_this_gate","next_gate"
  ),
  value=c(
    "SECONDARY_DEPTH_VALIDATION","GSE249696_BASELINE_CTEPH","PATIENT","71_BASELINE_PATIENTS_ALL_RV_FREE_WALL",
    "MODERATE<INTERMEDIATE<SEVERE","RV_FREE_WALL","FROZEN_STABLE16","FROZEN_PRIMARY25","NO","NO","NO",
    "ALL_16_PROGRAMS_TOGETHER","ALL_25_GENES_TOGETHER","GEO_DESEQ_NORMALIZED_GENE_COUNTS","NO",
    "UNFROZEN_PENDING_STEP0_AUDIT","UNFROZEN_PENDING_STEP0_AUDIT","UNFROZEN_PENDING_METADATA_AUDIT","NO",
    "R4A_STEP1_METHOD_CONTRACT_FREEZE_BEFORE_ANY_SEVERITY_TEST"
  ),stringsAsFactors=FALSE
)
awrite(boundary,file.path(OUT,"R4A_STEP0_CONTRACT_BOUNDARY.csv"))

# Input identity ledger and snapshots.
input_rows <- lapply(names(PATHS),function(nm) data.frame(input_id=nm,path=PATHS[[nm]],bytes=file.info(PATHS[[nm]])$size,sha256=sha256_ps(PATHS[[nm]]),stringsAsFactors=FALSE))
if(gmt_authority_ok) input_rows[[length(input_rows)+1L]] <- data.frame(input_id="HALLMARK_GMT",path=GMT,bytes=file.info(GMT)$size,sha256=sha256_ps(GMT),stringsAsFactors=FALSE)
inputs <- do.call(rbind,input_rows)
awrite(inputs,file.path(OUT,"R4A_STEP0_INPUT_SHA256.csv"))

# Snapshot all compact authorities + the 3.7 MB processed matrix, so ChatGPT can independently inspect next gate.
copy_exact(MAT,file.path(SNAP,"GSE249696_ext395_rnaseq.txt.gz"))
copy_exact(SAMPLE,file.path(SNAP,"R3_GSE249696_sample_manifest.csv"))
copy_exact(FIELDS,file.path(SNAP,"R3_GSE249696_characteristics_field_summary.csv"))
copy_exact(MDIAG,file.path(SNAP,"R3_GSE249696_matrix_diagnostic.csv"))
copy_exact(PAIR34,file.path(SNAP,"A34__R3_GSE249696_step0B_reconciled_pair_universe.csv"))
copy_exact(A05,file.path(SNAP,"A05__R1_GSE240921_FINAL_PRIMARY25.csv"))
copy_exact(A20,file.path(SNAP,"A20__R3_STEP3F_V1_1_stable_program_identity_class_freeze.csv"))
copy_exact(A31,file.path(SNAP,"A31__R0_exact_step1_sample_map.csv"))
if(gmt_authority_ok) copy_exact(GMT,file.path(SNAP,"h.all.v2026.1.Hs.symbols.gmt"))

# Audit must be written last.
aud <- do.call(rbind,AUD)
awrite(aud,file.path(OUT,"R4A_STEP0_PREFLIGHT_AUDIT.csv"))
hard_fail <- sum(aud$status=="FAIL" & aud$critical=="YES")
state <- if(hard_fail==0L) "PASS_R4A_STEP0_PREFLIGHT_READY_FOR_INDEPENDENT_AUDIT" else "HOLD_R4A_STEP0_PREFLIGHT"
awrite(data.frame(
  final_state=state,run_id=STAMP,version="V1.2",hard_failures=hard_fail,
  severity_outcome_testing_executed="NO",program_scores_calculated="NO",gene_severity_tests_executed="NO",
  new_discovery_executed="NO",next_stage=if(hard_fail==0L) "CHATGPT_INDEPENDENT_AUDIT_THEN_R4A_STEP1_METHOD_CONTRACT" else "STOP_AND_REPAIR_PREFLIGHT",
  stringsAsFactors=FALSE
),file.path(OUT,"R4A_STEP0_STATUS.csv"))

cat("FINAL_STATE:",state,"\n")
cat("RUN_ID:",STAMP,"\n")
cat("HARD_FAILURES:",hard_fail,"\n")
cat("SEVERITY_OUTCOME_TESTING_EXECUTED:NO\n")
quit(save="no",status=if(hard_fail==0L) 0 else 62,runLast=FALSE)
