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
# RV Project — R4B Step1
# Gate9K V1.28 portability repair: current Step0 STATUS/AUDIT semantic binding only; science unchanged.
# PEA PATIENT-LEVEL PROGRAM TRAJECTORY — METHOD CONTRACT FREEZE
#
# CONTRACT-ONLY GATE.
# NO patient-level program score.
# NO PRE/POST delta.
# NO concordance proportion.
# NO program-delta correlation.
# NO inferential P value or FDR.
#
# Accepted upstream:
#   R4B Step0 RUN_ID = 20260911_003622
#
# R4B is descriptive heterogeneity characterization using the SAME 21-pair
# GSE249696 cohort that contributed to Step3F program classification.
# Therefore it is NOT independent validation and must not generate circular
# confirmatory significance claims.
# ==============================================================================

options(stringsAsFactors=FALSE, warn=1)
args <- commandArgs(trailingOnly=TRUE)
STAMP <- if(length(args)>=1 && nzchar(args[1])) args[1] else format(Sys.time(),"%Y%m%d_%H%M%S")

ROOT <- normalizePath(getwd(),winslash="/",mustWork=TRUE)
if(!identical(ROOT,RV_PROJECT_ROOT)) stop("Expected working directory D:/RV_project",call.=FALSE)

RESROOT <- file.path(ROOT,"results","R4B_PEA_PATIENT_TRAJECTORY_METHOD_CONTRACT")
OUT <- file.path(RESROOT,STAMP)
dir.create(OUT,recursive=TRUE,showWarnings=FALSE)

STEP0 <- rv_resolve_stage_run(file.path(ROOT, "results", "R4B_PEA_PATIENT_TRAJECTORY_PREFLIGHT"))
S0_STATUS   <- file.path(STEP0,"R4B_STEP0_STATUS.csv")
S0_BOUNDARY <- file.path(STEP0,"R4B_STEP0_CONTRACT_BOUNDARY.csv")
S0_CORE7    <- file.path(STEP0,"R4B_STEP0_CORE7_IDENTITY.csv")
S0_PAIRS    <- file.path(STEP0,"R4B_STEP0_PAIR_UNIVERSE.csv")
S0_MAP      <- file.path(STEP0,"R4B_STEP0_PROGRAM_MAPPING_AUDIT.csv")
S0_AUDIT    <- file.path(STEP0,"R4B_STEP0_PREFLIGHT_AUDIT.csv")

MAT <- file.path(ROOT,"data","processed","GSE249696","GSE249696_ext395_rnaseq.txt.gz")
GMT <- file.path(ROOT,"data","authority","MSigDB","h.all.v2026.1.Hs.symbols.gmt")

EXPECTED_SHA <- c(
  S0_STATUS   ="7118bb2268f0d11cdd83640c528abdb28e2f16e0acabd59ebd485959173990ca",
  S0_BOUNDARY ="230a23eadf7bc5771e8d6f3d9aaddace9980d1b50045d713794560af61d6b69f",
  S0_CORE7    ="a5dfeb25897c4c4d4d0d90bc273706d90364da22e35516f6fac5c8802f36e673",
  S0_PAIRS    ="9ba3899cb48ca6baad62ba34c49dcb54a1593a9dbf70dc233e3c47822e31df57",
  S0_MAP      ="e1b27b1f78a604b0cf7d2dc7d3873df03bf55e8458a9e360797a485af5aff038",
  S0_AUDIT    ="5cd5b876aebae4dd59f37e38baaa4d7227b39ad940c0297387778591f9614aa7",
  MAT         ="2ac6465ed35a45a8b3b56c30df7e6a0b3dc9469bddd340ad36d92a0eae09a5f2",
  GMT         ="eecaf6dad908334ae885406ec72bdc0646d8917588ed7c219fac92fc5363f596"
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

P <- list(
  S0_STATUS=S0_STATUS,S0_BOUNDARY=S0_BOUNDARY,S0_CORE7=S0_CORE7,
  S0_PAIRS=S0_PAIRS,S0_MAP=S0_MAP,S0_AUDIT=S0_AUDIT,MAT=MAT,GMT=GMT
)
for(nm in names(P)) {
  check(paste0("FILE_",nm),paste0(nm," exists"),file.exists(P[[nm]]),P[[nm]])
}
if(any(!vapply(P,file.exists,logical(1)))) {
  awrite(do.call(rbind,AUD),file.path(OUT,"R4B_STEP1_METHOD_CONTRACT_AUDIT.csv"))
  awrite(data.frame(
    final_state="HOLD_R4B_STEP1_MISSING_INPUT",
    run_id=STAMP,hard_failures=1,
    patient_program_scores_calculated="NO",
    pre_post_deltas_calculated="NO",
    expected_direction_concordance_calculated="NO",
    program_delta_correlations_calculated="NO",
    inferential_tests_executed="NO",
    stringsAsFactors=FALSE
  ),file.path(OUT,"R4B_STEP1_STATUS.csv"))
  quit(save="no",status=111,runLast=FALSE)
}

for(nm in names(EXPECTED_SHA)) {
  got <- sha256(P[[nm]])
  if(identical(nm,"S0_STATUS")) {
    s0_pre <- read.csv(S0_STATUS,stringsAsFactors=FALSE,check.names=FALSE)
    s0_run_id <- basename(STEP0)
    need <- c("final_state","run_id","hard_failures","patient_program_scores_calculated",
              "pre_post_deltas_calculated","expected_direction_concordance_calculated",
              "program_delta_correlations_calculated","inferential_tests_executed",
              "new_program_discovery","thresholds_retuned","next_stage")
    ok <- nrow(s0_pre)==1L && all(need %in% names(s0_pre)) &&
      identical(as.character(s0_pre$final_state[1]),"PASS_R4B_STEP0_PREFLIGHT_READY_FOR_INDEPENDENT_AUDIT") &&
      identical(as.character(s0_pre$run_id[1]),s0_run_id) &&
      identical(as.integer(s0_pre$hard_failures[1]),0L) &&
      identical(as.character(s0_pre$patient_program_scores_calculated[1]),"NO") &&
      identical(as.character(s0_pre$pre_post_deltas_calculated[1]),"NO") &&
      identical(as.character(s0_pre$expected_direction_concordance_calculated[1]),"NO") &&
      identical(as.character(s0_pre$program_delta_correlations_calculated[1]),"NO") &&
      identical(as.character(s0_pre$inferential_tests_executed[1]),"NO") &&
      identical(as.character(s0_pre$new_program_discovery[1]),"NO") &&
      identical(as.character(s0_pre$thresholds_retuned[1]),"NO") &&
      identical(as.character(s0_pre$next_stage[1]),"CHATGPT_INDEPENDENT_AUDIT_THEN_R4B_STEP1_TRAJECTORY_METHOD_CONTRACT")
    check(paste0("SHA_",nm),"S0_STATUS exact current-run semantic binding",ok,
          if(nrow(s0_pre)) paste(s0_pre$run_id[1],s0_pre$final_state[1],s0_pre$hard_failures[1],sep=" | ") else "NO_ROW")
  } else if(identical(nm,"S0_AUDIT")) {
    s0_audit_pre <- read.csv(S0_AUDIT,stringsAsFactors=FALSE,check.names=FALSE)
    expected_ids <- c("FILE_R4A_STATUS","FILE_PAIR","FILE_SAMPLE","FILE_A20","FILE_MAT","FILE_GMT","SHA_R4A_STATUS","SHA_PAIR","SHA_SAMPLE","SHA_A20","SHA_MAT","SHA_GMT","R4A_CLOSED","PAIR_N21","PAIR_IDS","PAT96_EXCLUDED","PAIR_ONE_ONE","PAIR_SITE","PAIR_RISK","PAIR_SEX","BL_SAMPLE_LINK","FU_SAMPLE_LINK","BL_TIME_SITE","FU_TIME_SITE","A20_16","CORE5_REVERSAL","CORE2_WORSENING","CORE7_UNIQUE","MATRIX_ROWS","MATRIX_COLS","MATRIX_META","MATRIX_42_COLUMNS","MATRIX_42_NUMERIC","MATRIX_42_NONNEGATIVE","GMT50","CORE7_GMT","CORE_SYMBOL_UNIQUENESS","CORE7_MAPPING80")
    ok <- nrow(s0_audit_pre)==length(expected_ids) &&
      identical(as.character(s0_audit_pre$guard_id),expected_ids) &&
      all(as.character(s0_audit_pre$critical)=="YES") &&
      all(as.character(s0_audit_pre$status)=="PASS")
    check(paste0("SHA_",nm),"S0_AUDIT exact 38-check current-run all-PASS identity",ok,
          paste0("rows=",nrow(s0_audit_pre),";pass=",sum(s0_audit_pre$status=="PASS")))
  } else {
    check(paste0("SHA_",nm),paste0(nm," exact accepted SHA256"),
          identical(tolower(got),tolower(EXPECTED_SHA[[nm]])),got)
  }
}

s0 <- read.csv(S0_STATUS,stringsAsFactors=FALSE,check.names=FALSE)
check("STEP0_PASS","Accepted R4B Step0 is PASS with zero hard failures",
      nrow(s0)==1L &&
      identical(s0$final_state[1],"PASS_R4B_STEP0_PREFLIGHT_READY_FOR_INDEPENDENT_AUDIT") &&
      as.integer(s0$hard_failures[1])==0L,
      if(nrow(s0)) paste(s0$final_state[1],s0$hard_failures[1],sep=" | ") else "NO_ROW")
check("STEP0_NO_TRAJECTORY","Step0 contains no outcome-bearing trajectory analysis",
      nrow(s0)==1L &&
      identical(s0$patient_program_scores_calculated[1],"NO") &&
      identical(s0$pre_post_deltas_calculated[1],"NO") &&
      identical(s0$expected_direction_concordance_calculated[1],"NO") &&
      identical(s0$program_delta_correlations_calculated[1],"NO") &&
      identical(s0$inferential_tests_executed[1],"NO"),
      if(nrow(s0)) paste(
        s0$patient_program_scores_calculated[1],
        s0$pre_post_deltas_calculated[1],
        s0$expected_direction_concordance_calculated[1],
        s0$program_delta_correlations_calculated[1],
        s0$inferential_tests_executed[1],sep=" | ") else "NO_ROW")

pairs <- read.csv(S0_PAIRS,stringsAsFactors=FALSE,check.names=FALSE)
core  <- read.csv(S0_CORE7,stringsAsFactors=FALSE,check.names=FALSE)
map0  <- read.csv(S0_MAP,stringsAsFactors=FALSE,check.names=FALSE)

check("PAIR21","Contract universe remains 21 patients",
      nrow(pairs)==21L && length(unique(pairs$patient_id))==21L,nrow(pairs))
check("PAIR42","Contract universe contains 42 unique sample columns",
      length(unique(c(pairs$BL_matrix_column,pairs$FU_matrix_column)))==42L,
      length(unique(c(pairs$BL_matrix_column,pairs$FU_matrix_column))))
check("SITE21","All 21 pairs remain RV free wall -> septum",
      all(pairs$BL_site=="RV_FREE_WALL" &
          pairs$FU_site=="INTERVENTRICULAR_SEPTUM" &
          as.logical(pairs$site_changed)),
      paste0(sum(pairs$BL_site=="RV_FREE_WALL" &
                 pairs$FU_site=="INTERVENTRICULAR_SEPTUM" &
                 as.logical(pairs$site_changed)),"/21"))
check("CORE7","Frozen trajectory target family remains seven programs",
      nrow(core)==7L && length(unique(core$pathway))==7L,nrow(core))
check("CORE_CLASS_COUNTS","Core7 remains 5 reversal + 2 worsening",
      sum(core$program_class=="PROGRAM_REVERSAL_SUPPORTED")==5L &&
      sum(core$program_class=="PROGRAM_MALADAPTIVE_NONREVERSAL_WORSENING_SUPPORTED")==2L,
      paste0(
        sum(core$program_class=="PROGRAM_REVERSAL_SUPPORTED"),"/",
        sum(core$program_class=="PROGRAM_MALADAPTIVE_NONREVERSAL_WORSENING_SUPPORTED")
      ))
check("MAP7","Step0 mapping audit contains all seven programs",
      nrow(map0)==7L && setequal(map0$pathway,core$pathway),nrow(map0))
check("MAP80","Every core7 program has >=80% exact-symbol mapping",
      all(map0$mapped_fraction>=0.80),
      paste0("min=",format(min(map0$mapped_fraction),digits=6)))

# --------------------------------------------------------------------------
# Pre-outcome eligibility audit only.
# Expression values are inspected across the pooled 42 samples WITHOUT using
# PRE/POST labels or computing any score/delta. This freezes eligible genes.
# --------------------------------------------------------------------------
mat <- read.delim(gzfile(MAT,"rt"),stringsAsFactors=FALSE,check.names=FALSE,
                  quote="",comment.char="")
check("MATRIX_ROWS","Processed matrix remains 40,932 rows",nrow(mat)==40932L,nrow(mat))
check("MATRIX_COLS","Processed matrix remains 103 columns",ncol(mat)==103L,ncol(mat))
check("GENE_SYMBOL_COLUMN","Matrix contains Ensembl gene symbol column",
      "Ensembl gene" %in% names(mat),
      paste(names(mat)[1:min(8,ncol(mat))],collapse=";"))

pair_cols <- c(pairs$BL_matrix_column,pairs$FU_matrix_column)
check("PAIR_COLUMNS_PRESENT","All 42 paired columns are present in matrix",
      length(pair_cols)==42L && length(unique(pair_cols))==42L &&
      all(pair_cols %in% names(mat)),
      paste0(sum(pair_cols %in% names(mat)),"/42"))

symbols <- trimws(as.character(mat[["Ensembl gene"]]))
X42 <- as.matrix(mat[,pair_cols,drop=FALSE])
storage.mode(X42) <- "double"
Y42 <- log2(X42+1)
finite42 <- apply(Y42,1,function(v) all(is.finite(v)))
sd42 <- apply(Y42,1,sd)
eligible42 <- finite42 & is.finite(sd42) & sd42>0

gl <- readLines(GMT,warn=FALSE)
parts <- strsplit(gl,"\t",fixed=TRUE)
gmt_names <- vapply(parts,`[`,character(1),1L)
gmt_genes <- lapply(parts,function(x)
  unique(if(length(x)>=3L) x[3:length(x)] else character()))
names(gmt_genes) <- gmt_names

check("GMT50","Exact GMT contains 50 Hallmark sets",length(gmt_genes)==50L,length(gmt_genes))
check("CORE7_GMT","All seven frozen programs present in exact GMT",
      all(core$pathway %in% names(gmt_genes)),
      paste(setdiff(core$pathway,names(gmt_genes)),collapse=";"))

symtab <- table(symbols[!is.na(symbols) & nzchar(symbols)])
all_core_symbols <- unique(unlist(gmt_genes[core$pathway],use.names=FALSE))
dup_core <- names(symtab)[names(symtab) %in% all_core_symbols & as.integer(symtab)>1L]
check("CORE_TARGET_UNIQUE",
      "Every core7 member symbol maps to at most one matrix row",
      length(dup_core)==0L,paste(dup_core,collapse=";"),
      notes="No outcome-dependent duplicate collapse allowed")

map_rows <- list()
for(pid in core$pathway) {
  members <- gmt_genes[[pid]]
  idx <- match(members,symbols)
  mapped <- !is.na(idx)
  idx2 <- idx[mapped]
  usable <- if(length(idx2)) eligible42[idx2] else logical()
  map_rows[[length(map_rows)+1L]] <- data.frame(
    pathway=pid,
    program_class=core$program_class[match(pid,core$pathway)],
    gmt_member_n=length(members),
    exact_symbol_mapped_n=sum(mapped),
    mapped_fraction=sum(mapped)/length(members),
    finite_42_n=sum(if(length(idx2)) finite42[idx2] else logical()),
    zero_or_nonfinite_sd_42_n=sum(if(length(idx2)) !eligible42[idx2] else logical()),
    usable_gene_n=sum(usable),
    assessable=(sum(mapped)/length(members)>=0.80 && sum(usable)>=10L),
    mapping_rule="TRIMMED_EXACT_HGNC_SYMBOL",
    gene_eligibility="FINITE_IN_ALL_42_AND_SAMPLE_SD_GT_0_BEFORE_TIMEPOINT_USE",
    duplicate_policy="FAIL_IF_CORE7_MEMBER_SYMBOL_MAPS_TO_MULTIPLE_MATRIX_ROWS",
    stringsAsFactors=FALSE
  )
}
map42 <- do.call(rbind,map_rows)
check("CORE7_ASSESSABLE","All core7 programs pass frozen pre-outcome eligibility",
      all(map42$assessable),paste0(sum(map42$assessable),"/7"))
check("CORE7_USABLE10","All core7 programs have >=10 usable genes",
      all(map42$usable_gene_n>=10L),paste0("min=",min(map42$usable_gene_n)))
awrite(map42,file.path(OUT,"R4B_STEP1_PROGRAM_ELIGIBILITY_AUDIT.csv"))

# --------------------------------------------------------------------------
# Freeze method contract before any PRE/POST score or delta is computed.
# --------------------------------------------------------------------------
contract <- data.frame(
  item=c(
    "module_role",
    "cohort",
    "biological_replicate",
    "pair_universe",
    "excluded_patient",
    "PRE_tissue",
    "POST_tissue",
    "site_confounding",
    "same_dataset_selection_issue",
    "independent_validation_allowed",
    "trajectory_target_family",
    "trajectory_target_n",
    "reversal_program_n",
    "worsening_program_n",
    "expression_authority",
    "expression_transform",
    "gene_symbol_column",
    "symbol_mapping",
    "target_duplicate_policy",
    "preoutcome_gene_eligibility",
    "program_min_mapping_fraction",
    "program_min_usable_genes",
    "gene_standardization",
    "raw_program_score",
    "failure_oriented_program_score",
    "pair_delta",
    "expected_delta_reversal",
    "expected_delta_worsening",
    "class_aligned_delta",
    "zero_delta_tolerance",
    "program_expected_direction_count",
    "program_expected_direction_fraction",
    "program_delta_summary",
    "patient_concordance_count_core7",
    "patient_concordance_count_reversal5",
    "patient_concordance_count_worsening2",
    "responder_subgroup_definition",
    "program_delta_correlation",
    "program_delta_correlation_pvalues",
    "paired_inferential_test",
    "binomial_concordance_test",
    "multiple_testing_FDR",
    "risk_stratified_inference",
    "sex_stratified_inference",
    "patient_display_order",
    "outcome_based_patient_reordering",
    "new_program_discovery",
    "new_gene_discovery",
    "threshold_retuning_after_results",
    "allowed_claim",
    "forbidden_claim",
    "patient_program_scores_calculated_in_step1",
    "pre_post_deltas_calculated_in_step1",
    "expected_direction_concordance_calculated_in_step1",
    "program_delta_correlations_calculated_in_step1",
    "inferential_tests_executed_in_step1",
    "next_stage"
  ),
  value=c(
    "DESCRIPTIVE_PATIENT_LEVEL_HETEROGENEITY_CHARACTERIZATION",
    "GSE249696_PUBLISHED_PEA_N21",
    "PATIENT",
    "21_MATCHED_PRE_POST_PATIENTS",
    "Pat-96",
    "RV_FREE_WALL",
    "INTERVENTRICULAR_SEPTUM",
    "YES_COMPLETE_21_OF_21",
    "YES_CORE7_CLASSES_DERIVED_FROM_SAME_21_PAIR_MAIN_ANALYSIS",
    "NO",
    "FROZEN_STEP3F_REVERSAL_PLUS_WORSENING_CORE7",
    "7",
    "5",
    "2",
    "GEO_DESEQ_NORMALIZED_GENE_COUNTS",
    "LOG2_NORMALIZED_COUNT_PLUS_1",
    "Ensembl gene",
    "TRIMMED_EXACT_HGNC_SYMBOL",
    "FAIL_IF_CORE7_MEMBER_SYMBOL_MAPS_TO_MULTIPLE_MATRIX_ROWS",
    "FINITE_IN_ALL_42_AND_SAMPLE_SD_GT_0_BEFORE_TIMEPOINT_USE",
    "0.80",
    "10",
    "GENEWISE_Z_ACROSS_POOLED_42_PRE_POST_SAMPLES_USING_SAMPLE_SD",
    "MEAN_OF_USABLE_MEMBER_GENE_Z_SCORES_PER_SAMPLE",
    "RAW_SCORE_X_PLUS1_IF_UP_IN_FAILURE_ELSE_MINUS1_IF_DOWN_IN_FAILURE",
    "FAILURE_ORIENTED_POST_MINUS_PRE",
    "NEGATIVE",
    "POSITIVE",
    "PAIR_DELTA_X_MINUS1_FOR_REVERSAL_ELSE_PLUS1_FOR_WORSENING;POSITIVE_MEANS_CLASS_CONCORDANT",
    "1e-12",
    "COUNT_CLASS_ALIGNED_DELTA_GT_1E_MINUS_12_OUT_OF_ALL_21",
    "EXPECTED_COUNT_DIVIDED_BY_21_NO_NONZERO_DENOMINATOR_SELECTION",
    "N_MEAN_SD_MEDIAN_Q25_Q75_MIN_MAX_OF_FAILURE_ORIENTED_AND_CLASS_ALIGNED_DELTAS",
    "COUNT_CLASS_ALIGNED_DELTA_GT_1E_MINUS_12_ACROSS_7;TIES_NOT_COUNTED_AS_EXPECTED",
    "COUNT_CLASS_ALIGNED_DELTA_GT_1E_MINUS_12_ACROSS_5_REVERSAL_PROGRAMS",
    "COUNT_CLASS_ALIGNED_DELTA_GT_1E_MINUS_12_ACROSS_2_WORSENING_PROGRAMS",
    "NONE_NO_POSTHOC_RESPONDER_NONRESPONDER_CLASSIFICATION",
    "SPEARMAN_CORRELATION_MATRIX_OF_CLASS_ALIGNED_PROGRAM_DELTAS_ACROSS_21_PATIENTS",
    "NO",
    "NO",
    "NO",
    "NONE_DESCRIPTIVE_MODULE",
    "NO",
    "NO",
    "ASCENDING_PATIENT_NUMBER",
    "NO",
    "NO",
    "NO",
    "NO",
    "PATIENT_LEVEL_TRAJECTORIES_CHARACTERIZE_WITHIN_COHORT_HETEROGENEITY_AND_DIRECTIONAL_CONSISTENCY",
    "NOT_INDEPENDENT_VALIDATION;NO_CAUSAL_UNLOADING_CLAIM;NO_SITE_INDEPENDENT_RECOVERY_OR_PERSISTENCE_CLAIM",
    "NO",
    "NO",
    "NO",
    "NO",
    "NO",
    "R4B_STEP2_DETERMINISTIC_PATIENT_TRAJECTORY_EXECUTION_AFTER_INDEPENDENT_AUDIT"
  ),
  stringsAsFactors=FALSE
)
awrite(contract,file.path(OUT,"R4B_STEP1_TRAJECTORY_METHOD_CONTRACT.csv"))

# Freeze program identities and expected directions in one compact table.
core_contract <- core[,c(
  "pathway","failure_direction","program_class","R4B_expected_delta_direction"
),drop=FALSE]
core_contract$class_alignment_multiplier <- ifelse(
  core_contract$program_class=="PROGRAM_REVERSAL_SUPPORTED",-1L,1L
)
core_contract$class_aligned_positive_semantics <- "CLASS_CONCORDANT_PATIENT_LEVEL_CHANGE"
awrite(core_contract,file.path(OUT,"R4B_STEP1_CORE7_DIRECTION_CONTRACT.csv"))

audit <- do.call(rbind,AUD)
hard_fail <- sum(audit$status=="FAIL" & audit$critical=="YES")
awrite(audit,file.path(OUT,"R4B_STEP1_METHOD_CONTRACT_AUDIT.csv"))

inp <- do.call(rbind,lapply(names(P),function(nm) data.frame(
  input_id=nm,path=P[[nm]],bytes=file.info(P[[nm]])$size,
  sha256=sha256(P[[nm]]),stringsAsFactors=FALSE
)))
awrite(inp,file.path(OUT,"R4B_STEP1_INPUT_SHA256.csv"))

state <- if(hard_fail==0L) {
  "PASS_R4B_STEP1_TRAJECTORY_METHOD_CONTRACT_READY_FOR_INDEPENDENT_AUDIT"
} else {
  "HOLD_R4B_STEP1_TRAJECTORY_METHOD_CONTRACT"
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
  responder_subgroups_defined="NO",
  new_program_discovery="NO",
  thresholds_retuned="NO",
  next_stage=if(hard_fail==0L)
    "CHATGPT_INDEPENDENT_AUDIT_THEN_R4B_STEP2_DETERMINISTIC_PATIENT_TRAJECTORY_EXECUTION"
  else "STOP_AND_REPAIR_METHOD_CONTRACT_ONLY",
  stringsAsFactors=FALSE
),file.path(OUT,"R4B_STEP1_STATUS.csv"))

cat("FINAL_STATE:",state,"\n")
cat("RUN_ID:",STAMP,"\n")
cat("HARD_FAILURES:",hard_fail,"\n")
cat("CORE7_ASSESSABLE:",sum(map42$assessable),"/7\n")
cat("TRAJECTORY_CALCULATED:NO\n")
cat("INFERENTIAL_TESTS_EXECUTED:NO\n")
quit(save="no",status=if(hard_fail==0L) 0 else 112,runLast=FALSE)
