# ---- RV PUBLIC PRIMARY DAG GATE9J REWRITE V1.0 ----
# source_id=C0349
# rewrite_scope=TIMESTAMP_ONLY
# Historical Gate9F source remains immutable provenance.
# This public copy removes only run-history/machine-generation dependencies;
# frozen scientific/statistical semantics, thresholds and accepted outputs are unchanged.
# ----------------------------------------------------
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
# RV Project — R4B Step0
# Gate9K V1.28 portability repair: current R4A terminal STATUS semantic binding only; science unchanged.
# PEA PATIENT-LEVEL PROGRAM TRAJECTORY — PREFLIGHT ONLY
#
# NO patient-level program score.
# NO PRE/POST delta.
# NO concordance proportion.
# NO correlation.
# NO inferential test.
#
# Purpose:
#   Bind exact 21-pair publication universe, frozen PEA core7 program identities,
#   processed expression matrix, exact Hallmark GMT, and program-member mapping
#   BEFORE any patient-level trajectory is calculated.
#
# Scientific boundary:
#   The same 21-pair GSE249696 main contrast contributed to Step3F program
#   classification. Therefore R4B is a DESCRIPTIVE HETEROGENEITY /
#   PATIENT-TRAJECTORY CHARACTERIZATION layer, NOT independent validation.
#   PRE=RV free wall; POST=interventricular septum for all 21 pairs, so the
#   trajectory remains completely confounded by anatomical sampling site.
# ==============================================================================

options(stringsAsFactors=FALSE, warn=1)
args <- commandArgs(trailingOnly=TRUE)
STAMP <- if(length(args)>=1 && nzchar(args[1])) args[1] else format(Sys.time(),"%Y%m%d_%H%M%S")

ROOT <- normalizePath(getwd(),winslash="/",mustWork=TRUE)
if(!identical(ROOT,RV_PROJECT_ROOT)) stop("Expected working directory D:/RV_project",call.=FALSE)

OUTROOT <- file.path(ROOT,"results","R4B_PEA_PATIENT_TRAJECTORY_PREFLIGHT")
OUT <- file.path(OUTROOT,STAMP)
dir.create(OUT,recursive=TRUE,showWarnings=FALSE)

# R4A terminal closure is an orchestration guard only, not a scientific R4B input.
R4A_STATUS <- rv_stage_file(
  file.path(ROOT,"results","R4A_CTEPH_SEVERITY_POSTGEN_VALIDATION"),
  "R4A_STEP3_STATUS.csv"
)

PAIR   <- file.path(ROOT,"results","R3_GSE249696",
                    "R3_GSE249696_step0B_reconciled_pair_universe.csv")
SAMPLE <- file.path(ROOT,"results","R3_GSE249696",
                    "R3_GSE249696_sample_manifest.csv")
A20    <- file.path(ROOT,"results","R3_GSE249696",
                    "R3_STEP3F_V1_1_stable_program_identity_class_freeze.csv")
MAT    <- file.path(ROOT,"data","processed","GSE249696",
                    "GSE249696_ext395_rnaseq.txt.gz")
GMT    <- file.path(ROOT,"data","authority","MSigDB",
                    "h.all.v2026.1.Hs.symbols.gmt")

EXPECTED_SHA <- c(
  R4A_STATUS="ad31262f73595e733a5bb3acff7f215f37a2d0c17ba4f336a40ec5ee0e993526",
  PAIR      ="e516420531f4bb9c6e73b9e0c90f30c59a4ced4066a4dcda11965c4216739b24",
  SAMPLE    ="27225258bc196313b527a3c5cdf1daa8356e0ffe0f6fe1091e214ce5fbea27d0",
  A20       ="49cd4da614f699f1c35d91e61d1bc59e2add6483c71aa23947fdab49a6a60068",
  MAT       ="2ac6465ed35a45a8b3b56c30df7e6a0b3dc9469bddd340ad36d92a0eae09a5f2",
  GMT       ="eecaf6dad908334ae885406ec72bdc0646d8917588ed7c219fac92fc5363f596"
)

if(!requireNamespace("digest",quietly=TRUE)) {
  stop("R package 'digest' is required for SHA256 verification",call.=FALSE)
}
sha256 <- function(p) digest::digest(file=p,algo="sha256",serialize=FALSE)

awrite <- function(x,p) {
  t <- paste0(p,".tmp_",Sys.getpid())
  write.csv(x,t,row.names=FALSE,na="",quote=TRUE)
  if(file.exists(p)) unlink(p,force=TRUE)
  if(!file.rename(t,p)) {unlink(t); stop("Atomic CSV write failed: ",p,call.=FALSE)}
}

AUD <- list()
check <- function(id,requirement,ok,observed="",critical=TRUE,notes="") {
  AUD[[length(AUD)+1L]] <<- data.frame(
    guard_id=as.character(id),
    requirement=as.character(requirement),
    observed=as.character(observed),
    status=if(isTRUE(ok)) "PASS" else "FAIL",
    critical=if(isTRUE(critical)) "YES" else "NO",
    notes=as.character(notes),
    stringsAsFactors=FALSE
  )
}

P <- list(R4A_STATUS=R4A_STATUS,PAIR=PAIR,SAMPLE=SAMPLE,A20=A20,MAT=MAT,GMT=GMT)
for(nm in names(P)) {
  check(paste0("FILE_",nm),paste0(nm," exists"),file.exists(P[[nm]]),P[[nm]])
}

if(any(!vapply(P,file.exists,logical(1)))) {
  awrite(do.call(rbind,AUD),file.path(OUT,"R4B_STEP0_PREFLIGHT_AUDIT.csv"))
  awrite(data.frame(
    final_state="HOLD_R4B_STEP0_MISSING_INPUT",
    run_id=STAMP,hard_failures=1,
    patient_program_scores_calculated="NO",
    pre_post_deltas_calculated="NO",
    concordance_calculated="NO",
    inferential_tests_executed="NO",
    stringsAsFactors=FALSE
  ),file.path(OUT,"R4B_STEP0_STATUS.csv"))
  quit(save="no",status=101,runLast=FALSE)
}

for(nm in names(EXPECTED_SHA)) {
  got <- sha256(P[[nm]])
  if(identical(nm,"R4A_STATUS")) {
    r4a_status_pre <- read.csv(R4A_STATUS,stringsAsFactors=FALSE,check.names=FALSE)
    r4a_run_id <- basename(dirname(R4A_STATUS))
    need <- c("final_state","run_id","hard_failures",
              "source_level_independent_reconstruction","Step2_scientific_outputs_modified",
              "new_scientific_testing","thresholds_retuned","terminal_closed","next_stage")
    ok <- nrow(r4a_status_pre)==1L && all(need %in% names(r4a_status_pre)) &&
      identical(as.character(r4a_status_pre$final_state[1]),"FINAL_CLOSED_R4A_CTEPH_BASELINE_SEVERITY_VALIDATION") &&
      identical(as.character(r4a_status_pre$run_id[1]),r4a_run_id) &&
      identical(as.integer(r4a_status_pre$hard_failures[1]),0L) &&
      identical(as.character(r4a_status_pre$source_level_independent_reconstruction[1]),"YES") &&
      identical(as.character(r4a_status_pre$Step2_scientific_outputs_modified[1]),"NO") &&
      identical(as.character(r4a_status_pre$new_scientific_testing[1]),"NO") &&
      identical(as.character(r4a_status_pre$thresholds_retuned[1]),"NO") &&
      identical(as.character(r4a_status_pre$terminal_closed[1]),"YES") &&
      identical(as.character(r4a_status_pre$next_stage[1]),"R4B_PEA_PATIENT_LEVEL_TRAJECTORY_PREFLIGHT")
    check(paste0("SHA_",nm),
          "R4A_STATUS current-run terminal semantic binding (historical whole-file SHA intentionally not used for run-bearing status)",
          ok,
          if(nrow(r4a_status_pre)) paste(r4a_status_pre$run_id[1],r4a_status_pre$final_state[1],r4a_status_pre$terminal_closed[1],sep=" | ") else "NO_ROW")
  } else {
    check(paste0("SHA_",nm),paste0(nm," exact frozen SHA256"),
          identical(tolower(got),tolower(EXPECTED_SHA[[nm]])),got)
  }
}

r4a <- read.csv(R4A_STATUS,stringsAsFactors=FALSE,check.names=FALSE)
check("R4A_CLOSED","R4A terminal closure complete before R4B starts",
      nrow(r4a)==1L &&
      identical(r4a$final_state[1],"FINAL_CLOSED_R4A_CTEPH_BASELINE_SEVERITY_VALIDATION") &&
      identical(r4a$terminal_closed[1],"YES") &&
      as.integer(r4a$hard_failures[1])==0L,
      if(nrow(r4a)) paste(r4a$final_state[1],r4a$terminal_closed[1],r4a$hard_failures[1],sep=" | ") else "NO_ROW")

pm <- read.csv(PAIR,stringsAsFactors=FALSE,check.names=FALSE)
sm <- read.csv(SAMPLE,stringsAsFactors=FALSE,check.names=FALSE)
a20 <- read.csv(A20,stringsAsFactors=FALSE,check.names=FALSE)

pub <- pm[pm$publication_pair_status=="INCLUDED_IN_PUBLISHED_N21",,drop=FALSE]
pub <- pub[order(as.integer(sub("^Pat-","",pub$patient_id))),,drop=FALSE]

expected_patients <- c("Pat-1","Pat-3","Pat-14","Pat-15","Pat-31","Pat-33",
                       "Pat-42","Pat-49","Pat-50","Pat-54","Pat-56","Pat-65",
                       "Pat-72","Pat-75","Pat-77","Pat-86","Pat-88","Pat-89",
                       "Pat-91","Pat-95","Pat-100")
expected_patients <- expected_patients[order(as.integer(sub("^Pat-","",expected_patients)))]

check("PAIR_N21","Publication pair universe is exactly 21",nrow(pub)==21L,nrow(pub))
check("PAIR_IDS","Publication pair identities exact after Pat-96 exclusion",
      identical(pub$patient_id,expected_patients),paste(pub$patient_id,collapse=";"))
check("PAT96_EXCLUDED","Pat-96 absent from publication n21",
      !"Pat-96" %in% pub$patient_id,paste(pub$patient_id,collapse=";"))
check("PAIR_ONE_ONE","Every publication patient has one BL and one FU",
      all(pub$n_BL==1L & pub$n_FU==1L & as.logical(pub$paired)),
      paste0(sum(pub$n_BL==1L & pub$n_FU==1L),"/21"))
check("PAIR_SITE","All n21 pairs change RV free wall -> septum",
      all(pub$BL_site=="RV_FREE_WALL" &
          pub$FU_site=="INTERVENTRICULAR_SEPTUM" &
          as.logical(pub$site_changed)),
      paste0(sum(pub$BL_site=="RV_FREE_WALL" &
                 pub$FU_site=="INTERVENTRICULAR_SEPTUM" &
                 as.logical(pub$site_changed)),"/21"))
risk_levels <- c("MODERATE","INTERMEDIATE","SEVERE")
risk_counts <- table(factor(pub$BL_risk,levels=risk_levels))
check("PAIR_RISK","Published n21 baseline risk counts are 9/8/4",
      identical(as.integer(risk_counts),c(9L,8L,4L)),
      paste(as.integer(risk_counts),collapse="/"))
check("PAIR_SEX","BL/FU sex is complete and internally consistent",
      all(!is.na(pub$BL_sex) & nzchar(pub$BL_sex) &
          !is.na(pub$FU_sex) & nzchar(pub$FU_sex) &
          pub$BL_sex==pub$FU_sex),
      paste0(sum(pub$BL_sex==pub$FU_sex),"/21"))

# Link all 42 biological samples to accepted sample manifest and matrix columns.
bl_sm <- sm[match(pub$BL_gsm,sm$geo_accession),,drop=FALSE]
fu_sm <- sm[match(pub$FU_gsm,sm$geo_accession),,drop=FALSE]

check("BL_SAMPLE_LINK","All 21 BL GSMs link uniquely to sample manifest",
      nrow(bl_sm)==21L && all(!is.na(bl_sm$geo_accession)) &&
      identical(bl_sm$geo_accession,pub$BL_gsm),
      paste0(sum(!is.na(bl_sm$geo_accession)),"/21"))
check("FU_SAMPLE_LINK","All 21 FU GSMs link uniquely to sample manifest",
      nrow(fu_sm)==21L && all(!is.na(fu_sm$geo_accession)) &&
      identical(fu_sm$geo_accession,pub$FU_gsm),
      paste0(sum(!is.na(fu_sm$geo_accession)),"/21"))
check("BL_TIME_SITE","Linked BL samples are BL/RV_FREE_WALL",
      all(bl_sm$timepoint=="BL" & bl_sm$site_class=="RV_FREE_WALL"),
      paste0(sum(bl_sm$timepoint=="BL" & bl_sm$site_class=="RV_FREE_WALL"),"/21"))
check("FU_TIME_SITE","Linked FU samples are FU/INTERVENTRICULAR_SEPTUM",
      all(fu_sm$timepoint=="FU" & fu_sm$site_class=="INTERVENTRICULAR_SEPTUM"),
      paste0(sum(fu_sm$timepoint=="FU" & fu_sm$site_class=="INTERVENTRICULAR_SEPTUM"),"/21"))

# Exact frozen PEA core7 identities.
REVERSAL <- sort(c(
  "HALLMARK_APICAL_JUNCTION",
  "HALLMARK_ESTROGEN_RESPONSE_EARLY",
  "HALLMARK_IL2_STAT5_SIGNALING",
  "HALLMARK_IL6_JAK_STAT3_SIGNALING",
  "HALLMARK_TNFA_SIGNALING_VIA_NFKB"
))
WORSENING <- sort(c(
  "HALLMARK_INTERFERON_ALPHA_RESPONSE",
  "HALLMARK_INTERFERON_GAMMA_RESPONSE"
))
obs_rev <- sort(a20$pathway[a20$program_class=="PROGRAM_REVERSAL_SUPPORTED"])
obs_wor <- sort(a20$pathway[a20$program_class=="PROGRAM_MALADAPTIVE_NONREVERSAL_WORSENING_SUPPORTED"])
core7 <- sort(c(obs_rev,obs_wor))

check("A20_16","Frozen Step3F table has exactly 16 stable programs",nrow(a20)==16L,nrow(a20))
check("CORE5_REVERSAL","Frozen reversal identities exact 5",
      identical(obs_rev,REVERSAL),paste(obs_rev,collapse=";"))
check("CORE2_WORSENING","Frozen worsening identities exact 2",
      identical(obs_wor,WORSENING),paste(obs_wor,collapse=";"))
check("CORE7_UNIQUE","Frozen trajectory target family is exactly seven unique programs",
      length(core7)==7L && length(unique(core7))==7L,paste(core7,collapse=";"))

core <- a20[a20$pathway %in% core7,
            c("pathway","failure_direction","main_NES","main_BH_FDR",
              "same_site_NES","same_site_BH_FDR","program_class",
              "interpretation_guard"),drop=FALSE]
core <- core[order(core$program_class,core$pathway),,drop=FALSE]
core$R4B_expected_delta_direction <- ifelse(
  core$program_class=="PROGRAM_REVERSAL_SUPPORTED",
  "NEGATIVE_FAILURE_ORIENTED_POST_MINUS_PRE",
  "POSITIVE_FAILURE_ORIENTED_POST_MINUS_PRE"
)
core$R4B_role <- "DESCRIPTIVE_PATIENT_TRAJECTORY_NOT_INDEPENDENT_VALIDATION"
awrite(core,file.path(OUT,"R4B_STEP0_CORE7_IDENTITY.csv"))

# Read matrix for structure/mapping only. NO scores or PRE/POST differences.
mat <- read.delim(gzfile(MAT,"rt"),stringsAsFactors=FALSE,check.names=FALSE,
                  quote="",comment.char="")
check("MATRIX_ROWS","Processed matrix remains 40,932 rows",nrow(mat)==40932L,nrow(mat))
check("MATRIX_COLS","Processed matrix remains 103 columns",ncol(mat)==103L,ncol(mat))
check("MATRIX_META","Matrix contains Ensembl gene symbol column",
      "Ensembl gene" %in% names(mat),paste(names(mat)[1:min(8,ncol(mat))],collapse=";"))

pair_cols <- c(bl_sm$matrix_column,fu_sm$matrix_column)
check("MATRIX_42_COLUMNS","All 42 paired sample columns are present and unique",
      length(pair_cols)==42L && length(unique(pair_cols))==42L &&
      all(pair_cols %in% names(mat)),
      paste0(sum(pair_cols %in% names(mat)),"/42"))

# Numeric/nonnegative input diagnostics only; no outcome contrasts.
num_ok <- vapply(mat[,pair_cols,drop=FALSE],function(v) {
  x <- suppressWarnings(as.numeric(v))
  mean(is.finite(x))>=0.999
},logical(1))
nonneg_ok <- vapply(mat[,pair_cols,drop=FALSE],function(v) {
  x <- suppressWarnings(as.numeric(v))
  mean(is.finite(x) & x>=0)>=0.999
},logical(1))
check("MATRIX_42_NUMERIC","All paired sample columns >=99.9% numeric",
      all(num_ok),paste0(sum(num_ok),"/42"))
check("MATRIX_42_NONNEGATIVE","All paired sample columns >=99.9% nonnegative",
      all(nonneg_ok),paste0(sum(nonneg_ok),"/42"))

# Exact GMT and program-member mapping, still without expression scoring.
gl <- readLines(GMT,warn=FALSE)
parts <- strsplit(gl,"\t",fixed=TRUE)
gmt_names <- vapply(parts,`[`,character(1),1L)
gmt_genes <- lapply(parts,function(x) unique(if(length(x)>=3L) x[3:length(x)] else character()))
names(gmt_genes) <- gmt_names
check("GMT50","Hallmark GMT contains exactly 50 sets",length(gmt_genes)==50L,length(gmt_genes))
check("CORE7_GMT","All frozen core7 programs present in exact GMT",
      all(core7 %in% names(gmt_genes)),paste(setdiff(core7,names(gmt_genes)),collapse=";"))

symbols <- trimws(as.character(mat[["Ensembl gene"]]))
symtab <- table(symbols[!is.na(symbols) & nzchar(symbols)])
all_core_symbols <- unique(unlist(gmt_genes[core7],use.names=FALSE))
dup_core <- names(symtab)[names(symtab) %in% all_core_symbols & as.integer(symtab)>1L]
check("CORE_SYMBOL_UNIQUENESS",
      "Every core7 member symbol maps to at most one matrix row",
      length(dup_core)==0L,paste(dup_core,collapse=";"),
      notes="No outcome-dependent duplicate collapsing is permitted")

map_rows <- list()
for(pid in core7) {
  members <- gmt_genes[[pid]]
  mapped <- members %in% symbols
  map_rows[[length(map_rows)+1L]] <- data.frame(
    pathway=pid,
    program_class=core$program_class[match(pid,core$pathway)],
    gmt_member_n=length(members),
    exact_symbol_mapped_n=sum(mapped),
    mapped_fraction=sum(mapped)/length(members),
    unmapped_symbols=paste(members[!mapped],collapse=";"),
    mapping_rule="TRIMMED_EXACT_HGNC_SYMBOL",
    duplicate_policy="FAIL_IF_CORE7_MEMBER_SYMBOL_MAPS_TO_MULTIPLE_MATRIX_ROWS",
    stringsAsFactors=FALSE
  )
}
map_audit <- do.call(rbind,map_rows)
check("CORE7_MAPPING80","Every core7 program has >=80% exact-symbol mapping",
      all(map_audit$mapped_fraction>=0.80),
      paste0("min=",format(min(map_audit$mapped_fraction),digits=6)))
awrite(map_audit,file.path(OUT,"R4B_STEP0_PROGRAM_MAPPING_AUDIT.csv"))

# Freeze pair universe for downstream contract/execution.
pair_out <- data.frame(
  patient_id=pub$patient_id,
  baseline_risk=pub$BL_risk,
  sex=pub$BL_sex,
  BL_gsm=pub$BL_gsm,
  BL_matrix_column=bl_sm$matrix_column,
  BL_site=pub$BL_site,
  FU_gsm=pub$FU_gsm,
  FU_matrix_column=fu_sm$matrix_column,
  FU_site=pub$FU_site,
  site_changed=pub$site_changed,
  stringsAsFactors=FALSE
)
awrite(pair_out,file.path(OUT,"R4B_STEP0_PAIR_UNIVERSE.csv"))

boundary <- data.frame(
  item=c(
    "module",
    "analysis_role",
    "publication_pair_n",
    "patient_exclusion",
    "biological_replicate",
    "PRE_tissue",
    "POST_tissue",
    "site_confounding",
    "trajectory_target_family",
    "trajectory_target_n",
    "reversal_program_n",
    "worsening_program_n",
    "same_dataset_selection_issue",
    "independent_validation_allowed",
    "patient_program_scores_calculated",
    "pre_post_deltas_calculated",
    "expected_direction_concordance_calculated",
    "program_delta_correlations_calculated",
    "inferential_tests_executed",
    "new_program_discovery",
    "threshold_retuning",
    "next_stage"
  ),
  value=c(
    "R4B_PEA_PATIENT_LEVEL_TRAJECTORY",
    "DESCRIPTIVE_HETEROGENEITY_CHARACTERIZATION",
    "21",
    "Pat-96",
    "PATIENT",
    "RV_FREE_WALL",
    "INTERVENTRICULAR_SEPTUM",
    "YES_COMPLETE_21_OF_21",
    "FROZEN_STEP3F_REVERSAL_PLUS_WORSENING_CORE7",
    "7",
    "5",
    "2",
    "YES_CORE7_CLASSES_DERIVED_FROM_SAME_21_PAIR_MAIN_ANALYSIS",
    "NO",
    "NO",
    "NO",
    "NO",
    "NO",
    "NO",
    "NO",
    "NO",
    "R4B_STEP1_TRAJECTORY_METHOD_CONTRACT_AFTER_INDEPENDENT_AUDIT"
  ),
  stringsAsFactors=FALSE
)
awrite(boundary,file.path(OUT,"R4B_STEP0_CONTRACT_BOUNDARY.csv"))

audit <- do.call(rbind,AUD)
hard_fail <- sum(audit$status=="FAIL" & audit$critical=="YES")
awrite(audit,file.path(OUT,"R4B_STEP0_PREFLIGHT_AUDIT.csv"))

inp <- do.call(rbind,lapply(names(P),function(nm) data.frame(
  input_id=nm,path=P[[nm]],bytes=file.info(P[[nm]])$size,
  sha256=sha256(P[[nm]]),stringsAsFactors=FALSE
)))
awrite(inp,file.path(OUT,"R4B_STEP0_INPUT_SHA256.csv"))

state <- if(hard_fail==0L) {
  "PASS_R4B_STEP0_PREFLIGHT_READY_FOR_INDEPENDENT_AUDIT"
} else {
  "HOLD_R4B_STEP0_PREFLIGHT"
}
awrite(data.frame(
  final_state=state,
  run_id=STAMP,
  hard_failures=hard_fail,
  patient_program_scores_calculated="NO",
  pre_post_deltas_calculated="NO",
  expected_direction_concordance_calculated="NO",
  program_delta_correlations_calculated="NO",
  inferential_tests_executed="NO",
  new_program_discovery="NO",
  thresholds_retuned="NO",
  next_stage=if(hard_fail==0L)
    "CHATGPT_INDEPENDENT_AUDIT_THEN_R4B_STEP1_TRAJECTORY_METHOD_CONTRACT"
  else "STOP_AND_REPAIR_PREFLIGHT_ONLY",
  stringsAsFactors=FALSE
),file.path(OUT,"R4B_STEP0_STATUS.csv"))

cat("FINAL_STATE:",state,"\n")
cat("RUN_ID:",STAMP,"\n")
cat("HARD_FAILURES:",hard_fail,"\n")
cat("PUBLICATION_PAIRS:",nrow(pub),"\n")
cat("CORE7:",length(core7),"\n")
cat("TRAJECTORY_CALCULATED:NO\n")
cat("INFERENTIAL_TESTS_EXECUTED:NO\n")
quit(save="no",status=if(hard_fail==0L) 0 else 102,runLast=FALSE)
