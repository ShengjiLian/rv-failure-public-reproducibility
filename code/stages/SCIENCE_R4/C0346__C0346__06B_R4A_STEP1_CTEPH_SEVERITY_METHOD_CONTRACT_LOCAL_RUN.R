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
# RV Project — R4A Step1
# CTEPH BASELINE SEVERITY METHOD CONTRACT FREEZE
#
# CONTRACT-ONLY GATE.
# NO severity-outcome association test.
# NO program score calculation.
# NO Primary25 severity test.
# NO new discovery.
#
# Accepted upstream:
#   R4A Step0 V1.2 RUN_ID = 20260911_001437
#
# Purpose:
#   Freeze, before any molecular severity result is seen:
#   - 71-patient analysis universe and risk ordering
#   - exact gene-symbol/GMT mapping policy
#   - expression transform
#   - sample-level program scoring
#   - frozen failure-direction orientation
#   - primary ordinal trend test and FDR family
#   - sex-adjusted and non-monotonic sensitivity analyses
#   - secondary Primary25 gene test and FDR family
# ==============================================================================
# Gate9K V1.25 overlay: current Step0 status/audit semantic binding only.
# No scientific/statistical method, target, threshold, model, or FDR rule changes.
# ==============================================================================

options(stringsAsFactors=FALSE, warn=1)
args <- commandArgs(trailingOnly=TRUE)
STAMP <- if(length(args)>=1 && nzchar(args[1])) args[1] else format(Sys.time(),"%Y%m%d_%H%M%S")

ROOT <- normalizePath(getwd(),winslash="/",mustWork=TRUE)
if(!identical(ROOT,RV_PROJECT_ROOT)) stop("Expected working directory D:/RV_project",call.=FALSE)

RESROOT <- file.path(ROOT,"results","R4A_CTEPH_SEVERITY_METHOD_CONTRACT")
OUT <- file.path(RESROOT,STAMP)
dir.create(OUT,recursive=TRUE,showWarnings=FALSE)

STEP0 <- rv_resolve_stage_run(file.path(ROOT, "results", "R4A_CTEPH_SEVERITY_PREFLIGHT_V1_2"))
STEP0_STATUS   <- file.path(STEP0,"R4A_STEP0_STATUS.csv")
STEP0_AUDIT    <- file.path(STEP0,"R4A_STEP0_PREFLIGHT_AUDIT.csv")
STEP0_BOUNDARY <- file.path(STEP0,"R4A_STEP0_CONTRACT_BOUNDARY.csv")
STEP0_TARGETS  <- file.path(STEP0,"R4A_STEP0_TARGET_IDENTITY.csv")

MAT    <- file.path(ROOT,"data","processed","GSE249696","GSE249696_ext395_rnaseq.txt.gz")
SAMPLE <- file.path(ROOT,"results","R3_GSE249696","R3_GSE249696_sample_manifest.csv")
GMT    <- file.path(ROOT,"data","authority","MSigDB","h.all.v2026.1.Hs.symbols.gmt")
A05    <- file.path(ROOT,"results","R1_GSE240921","R1_GSE240921_FINAL_PRIMARY25.csv")
A20    <- file.path(ROOT,"results","R3_GSE249696","R3_STEP3F_V1_1_stable_program_identity_class_freeze.csv")

EXPECTED_SHA <- c(
  # STEP0_STATUS / STEP0_AUDIT are current-run authorities and are bound
  # semantically below. Their whole-file SHA legitimately changes with RUN_ID
  # and current absolute paths under cold-start / FAST-resume execution.
  STEP0_BOUNDARY ="128fcbe429ff990261f0b26c483855c1239c29fb4d0b9cbdc4cf6978c0dffb48",
  STEP0_TARGETS  ="feede6c7b6ad2403795ff11a92143aad1de42131a900b1792b85300d67779872",
  MAT            ="2ac6465ed35a45a8b3b56c30df7e6a0b3dc9469bddd340ad36d92a0eae09a5f2",
  SAMPLE         ="27225258bc196313b527a3c5cdf1daa8356e0ffe0f6fe1091e214ce5fbea27d0",
  GMT            ="eecaf6dad908334ae885406ec72bdc0646d8917588ed7c219fac92fc5363f596",
  A05            ="00dd5abaf1f6ffbcf67c34d2f95a79d6f96ca13705a2200bc7111063d4f0ce55",
  A20            ="49cd4da614f699f1c35d91e61d1bc59e2add6483c71aa23947fdab49a6a60068"
)

if(!requireNamespace("digest",quietly=TRUE)) {
  stop("R package 'digest' is required for SHA256 verification",call.=FALSE)
}
sha256 <- function(p) digest::digest(file=p,algo="sha256",serialize=FALSE)

awrite <- function(x,p) {
  t <- paste0(p,".tmp_",Sys.getpid())
  write.csv(x,t,row.names=FALSE,na="")
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
  STEP0_STATUS=STEP0_STATUS, STEP0_AUDIT=STEP0_AUDIT,
  STEP0_BOUNDARY=STEP0_BOUNDARY, STEP0_TARGETS=STEP0_TARGETS,
  MAT=MAT, SAMPLE=SAMPLE, GMT=GMT, A05=A05, A20=A20
)

for(nm in names(P)) {
  check(paste0("FILE_",nm),paste0(nm," exists"),file.exists(P[[nm]]),P[[nm]])
}
if(any(!vapply(P,file.exists,logical(1)))) {
  awrite(do.call(rbind,AUD),file.path(OUT,"R4A_STEP1_METHOD_CONTRACT_AUDIT.csv"))
  awrite(data.frame(
    final_state="HOLD_R4A_STEP1_METHOD_CONTRACT",
    run_id=STAMP,
    hard_failures=sum(vapply(AUD,function(x) x$status[1]=="FAIL" && x$critical[1]=="YES",logical(1))),
    severity_outcome_testing_executed="NO",
    program_scores_calculated="NO",
    gene_severity_tests_executed="NO",
    stringsAsFactors=FALSE
  ),file.path(OUT,"R4A_STEP1_STATUS.csv"))
  quit(save="no",status=71,runLast=FALSE)
}

for(nm in names(EXPECTED_SHA)) {
  got <- sha256(P[[nm]])
  check(paste0("SHA_",nm),paste0(nm," exact accepted SHA256"),
        identical(tolower(got),tolower(EXPECTED_SHA[[nm]])),got)
}

s0 <- read.csv(STEP0_STATUS,stringsAsFactors=FALSE,check.names=FALSE)

# Gate9K V1.25 current-run portability repair:
# Status and audit are generated afresh by C0345. Fail closed on their exact
# semantic identity instead of impossible historical whole-file SHA equality.
step0_run_id <- basename(STEP0)
step0_status_cols <- c(
  "final_state","run_id","version","hard_failures",
  "severity_outcome_testing_executed","program_scores_calculated",
  "gene_severity_tests_executed","new_discovery_executed","next_stage"
)
step0_status_ok <- nrow(s0)==1L &&
  all(step0_status_cols %in% names(s0)) &&
  identical(as.character(s0$final_state[1]),"PASS_R4A_STEP0_PREFLIGHT_READY_FOR_INDEPENDENT_AUDIT") &&
  identical(as.character(s0$run_id[1]),step0_run_id) &&
  identical(as.character(s0$version[1]),"V1.2") &&
  identical(as.integer(s0$hard_failures[1]),0L) &&
  identical(as.character(s0$severity_outcome_testing_executed[1]),"NO") &&
  identical(as.character(s0$program_scores_calculated[1]),"NO") &&
  identical(as.character(s0$gene_severity_tests_executed[1]),"NO") &&
  identical(as.character(s0$new_discovery_executed[1]),"NO") &&
  identical(as.character(s0$next_stage[1]),"CHATGPT_INDEPENDENT_AUDIT_THEN_R4A_STEP1_METHOD_CONTRACT")
check("STEP0_CURRENT_STATUS_BINDING",
      "Current C0345 Step0 status is exact PASS V1.2 and bound to resolved current RUN_ID",
      step0_status_ok,
      if(nrow(s0)) paste(s0$run_id[1],s0$final_state[1],s0$hard_failures[1],sep=" | ") else "NO_ROW")

s0a <- read.csv(STEP0_AUDIT,stringsAsFactors=FALSE,check.names=FALSE)
expected_step0_checks <- c(
  "FILE_MAT","FILE_SAMPLE","FILE_FIELDS","FILE_MDIAG","FILE_A34","FILE_A05","FILE_A20","FILE_A31",
  "SHA_A05","SHA_A20","SHA_A31","SHA_A34",
  "SAMPLE_SCHEMA","SAMPLE_ROWS","SAMPLE_UNIQUE_GSM","BASELINE_N","FOLLOWUP_N",
  "BASELINE_PATIENT_UNIQUE","BASELINE_SITE","RISK_COUNTS","RISK_COMPLETE","SEX_PRESENT",
  "PRIMARY25_N","STABLE16_N","PROGRAM_CLASSES","GMT_AUTHORITY_EXACT","GMT_SNAPSHOT_INVENTORY",
  "GMT_50","STABLE16_IN_GMT","MATRIX_BYTES","MATRIX_ROWS","MATRIX_COLS","MATRIX_LINK_95",
  "BASELINE_NUMERIC","BASELINE_NONNEG","NON_SAMPLE_COLS"
)
expected_step0_critical <- ifelse(
  expected_step0_checks %in% c("FOLLOWUP_N","SEX_PRESENT","GMT_SNAPSHOT_INVENTORY","NON_SAMPLE_COLS"),
  "NO","YES"
)
step0_audit_ok <- nrow(s0a)==length(expected_step0_checks) &&
  all(c("guard_id","status","critical") %in% names(s0a)) &&
  identical(as.character(s0a$guard_id),expected_step0_checks) &&
  identical(as.character(s0a$status),rep("PASS",length(expected_step0_checks))) &&
  identical(as.character(s0a$critical),expected_step0_critical)
check("STEP0_CURRENT_AUDIT_EXACT",
      "Current C0345 Step0 audit has exact 36-check sequence, criticality and all PASS",
      step0_audit_ok,
      paste0("rows=",nrow(s0a),"; pass=",sum(s0a$status=="PASS",na.rm=TRUE),
             "; hard_fail=",sum(s0a$status=="FAIL" & s0a$critical=="YES",na.rm=TRUE)))

check("STEP0_PASS","Accepted Step0 V1.2 is PASS",
      nrow(s0)==1L &&
      identical(s0$final_state[1],"PASS_R4A_STEP0_PREFLIGHT_READY_FOR_INDEPENDENT_AUDIT") &&
      identical(as.integer(s0$hard_failures[1]),0L),
      if(nrow(s0)) paste(s0$final_state[1],s0$hard_failures[1],sep=" | ") else "NO_ROW")
check("STEP0_NO_OUTCOME","Step0 did not test severity outcomes",
      nrow(s0)==1L &&
      identical(s0$severity_outcome_testing_executed[1],"NO") &&
      identical(s0$program_scores_calculated[1],"NO") &&
      identical(s0$gene_severity_tests_executed[1],"NO"),
      if(nrow(s0)) paste(s0$severity_outcome_testing_executed[1],
                         s0$program_scores_calculated[1],
                         s0$gene_severity_tests_executed[1],sep=" | ") else "NO_ROW")

sm <- read.csv(SAMPLE,stringsAsFactors=FALSE,check.names=FALSE)
bl <- sm[sm$timepoint=="BL",,drop=FALSE]
risk_levels <- c("MODERATE","INTERMEDIATE","SEVERE")
risk_counts <- table(factor(bl$esc_risk_group,levels=risk_levels))
sex_counts <- table(factor(bl$sex,levels=c("Female","Male")))

check("BL71","Analysis universe is 71 baseline patients",nrow(bl)==71L,nrow(bl))
check("BL71_UNIQUE","71 baseline rows are unique patients",length(unique(bl$patient_id))==71L,length(unique(bl$patient_id)))
check("RVFW71","All baseline samples are RV free wall",all(bl$site_class=="RV_FREE_WALL"),sum(bl$site_class=="RV_FREE_WALL"))
check("RISK_ORDER_COUNTS","Risk counts are 30/23/18",
      identical(as.integer(risk_counts),c(30L,23L,18L)),
      paste(paste(risk_levels,as.integer(risk_counts)),collapse=";"))
check("SEX_COMPLETE","Sex is complete for all 71 baseline patients",
      sum(is.na(bl$sex) | !nzchar(trimws(bl$sex)))==0L,
      paste0("Female=",sex_counts["Female"],";Male=",sex_counts["Male"]))
check("SEX_LEVELS","Only Female/Male are present",
      setequal(unique(bl$sex),c("Female","Male")),
      paste(sort(unique(bl$sex)),collapse=";"))

# --------------------------------------------------------------------------
# Pre-outcome target mapping audit.
# Reading expression values here is ONLY to identify non-finite or zero-SD genes
# before the scoring rule is frozen. No risk label is used in these calculations.
# --------------------------------------------------------------------------
mat <- read.delim(gzfile(MAT,"rt"),stringsAsFactors=FALSE,check.names=FALSE,
                  quote="",comment.char="")
req_meta <- c("Ensembl gene id","Ensembl gene")
check("MATRIX_META","Required matrix gene columns present",all(req_meta %in% names(mat)),
      paste(setdiff(req_meta,names(mat)),collapse=";"))
check("MATRIX_ROWS","Matrix rows remain 40,932",nrow(mat)==40932L,nrow(mat))
check("MATRIX_COLS","Matrix columns remain 103",ncol(mat)==103L,ncol(mat))

bl_cols <- bl$matrix_column
check("BL_COLUMNS","All 71 baseline expression columns present uniquely",
      length(bl_cols)==71L && length(unique(bl_cols))==71L && all(bl_cols %in% names(mat)),
      paste0(sum(bl_cols %in% names(mat)),"/71"))

symbols <- trimws(as.character(mat[["Ensembl gene"]]))
sym_nonblank <- !is.na(symbols) & nzchar(symbols)
sym_tab <- table(symbols[sym_nonblank])

# Exact Hallmark parsing.
gl <- readLines(GMT,warn=FALSE)
parts <- strsplit(gl,"\t",fixed=TRUE)
gmt_names <- vapply(parts,`[`,character(1),1L)
gmt_genes <- lapply(parts,function(x) if(length(x)>=3L) x[3:length(x)] else character())
names(gmt_genes) <- gmt_names
check("GMT50","Hallmark GMT contains exactly 50 sets",length(gmt_genes)==50L,length(gmt_genes))

targ <- read.csv(STEP0_TARGETS,stringsAsFactors=FALSE,check.names=FALSE)
prog_ids <- targ$target_id[targ$target_family=="STABLE_PROGRAM_16"]
gene_ids <- targ$target_id[targ$target_family=="PRIMARY25_GENE"]
check("PROG16","Frozen program family contains 16 targets",length(prog_ids)==16L,length(prog_ids))
check("GENE25","Frozen gene family contains 25 targets",length(gene_ids)==25L,length(gene_ids))
check("PROG16_GMT","All frozen programs are present in GMT",all(prog_ids %in% names(gmt_genes)),
      paste(setdiff(prog_ids,names(gmt_genes)),collapse=";"))

# Fail closed if any target symbol would map to >1 matrix row.
all_prog_symbols <- unique(unlist(gmt_genes[prog_ids],use.names=FALSE))
target_union <- unique(c(all_prog_symbols,gene_ids))
dup_target <- names(sym_tab)[names(sym_tab) %in% target_union & as.integer(sym_tab)>1L]
check("TARGET_SYMBOL_UNIQUENESS",
      "Every frozen target symbol maps to at most one matrix row",
      length(dup_target)==0L,
      paste(dup_target,collapse=";"),
      notes="No post-hoc duplicate collapsing is allowed")

# Pre-outcome variance audit using all 71 baseline samples with NO risk labels.
X <- as.matrix(mat[,bl_cols,drop=FALSE])
storage.mode(X) <- "double"
logX <- log2(X+1)
row_sd <- apply(logX,1,sd,na.rm=TRUE)
names(row_sd) <- symbols
finite71 <- apply(logX,1,function(v) all(is.finite(v)))
names(finite71) <- symbols

program_map <- list()
for(pid in prog_ids) {
  members <- unique(gmt_genes[[pid]])
  idx <- match(members,symbols)
  mapped <- !is.na(idx)
  mapped_symbols <- members[mapped]
  mapped_idx <- idx[mapped]
  finite_ok <- if(length(mapped_idx)) finite71[mapped_idx] else logical()
  sd_ok <- if(length(mapped_idx)) is.finite(row_sd[mapped_idx]) & row_sd[mapped_idx]>0 else logical()
  usable <- finite_ok & sd_ok
  program_map[[length(program_map)+1L]] <- data.frame(
    pathway=pid,
    gmt_member_n=length(members),
    exact_symbol_mapped_n=sum(mapped),
    mapped_fraction=sum(mapped)/length(members),
    finite_71_n=sum(finite_ok),
    zero_or_nonfinite_sd_n=sum(!sd_ok),
    usable_gene_n=sum(usable),
    mapping_rule="TRIMMED_EXACT_HGNC_SYMBOL",
    duplicate_policy="FAIL_IF_TARGET_SYMBOL_MAPS_TO_MULTIPLE_MATRIX_ROWS",
    zero_variance_policy="EXCLUDE_PREOUTCOME_ZERO_OR_NONFINITE_SD_GENE",
    assessable=(sum(mapped)/length(members)>=0.80 && sum(usable)>=10),
    stringsAsFactors=FALSE
  )
}
program_map <- do.call(rbind,program_map)
check("PROGRAM_COVERAGE80","All 16 programs have >=80% exact-symbol mapping",
      all(program_map$mapped_fraction>=0.80),
      paste0("min=",format(min(program_map$mapped_fraction),digits=6)))
check("PROGRAM_USABLE10","All 16 programs have >=10 usable genes after pre-outcome variance audit",
      all(program_map$usable_gene_n>=10L),
      paste0("min=",min(program_map$usable_gene_n)))

gene_map <- data.frame(
  gene=gene_ids,
  exact_symbol_mapped=gene_ids %in% symbols,
  matrix_row_count=vapply(gene_ids,function(g) sum(symbols==g,na.rm=TRUE),integer(1)),
  finite_71=vapply(gene_ids,function(g) {
    i <- which(symbols==g)
    length(i)==1L && isTRUE(finite71[i])
  },logical(1)),
  nonzero_sd=vapply(gene_ids,function(g) {
    i <- which(symbols==g)
    length(i)==1L && is.finite(row_sd[i]) && row_sd[i]>0
  },logical(1)),
  stringsAsFactors=FALSE
)
check("PRIMARY25_MAPPING","All 25 genes map exactly once",all(gene_map$matrix_row_count==1L),
      paste0(sum(gene_map$matrix_row_count==1L),"/25"))
check("PRIMARY25_VARIANCE","All 25 genes are finite with nonzero SD across 71 baseline patients",
      all(gene_map$finite_71 & gene_map$nonzero_sd),
      paste0(sum(gene_map$finite_71 & gene_map$nonzero_sd),"/25"))

# Frozen direction map.
dir_prog <- targ[targ$target_family=="STABLE_PROGRAM_16",
                 c("target_id","failure_direction"),drop=FALSE]
check("PROGRAM_DIRECTION","Every program has frozen UP/DOWN failure direction",
      all(dir_prog$failure_direction %in% c("UP_IN_FAILURE","DOWN_IN_FAILURE")),
      paste(sort(unique(dir_prog$failure_direction)),collapse=";"))

dir_gene <- targ[targ$target_family=="PRIMARY25_GENE",
                 c("target_id","failure_direction"),drop=FALSE]
check("GENE_DIRECTION","Every Primary25 gene has frozen RVF-vs-pRV direction",
      all(dir_gene$failure_direction %in% c("UP_RVF_vs_pRV","DOWN_RVF_vs_pRV")),
      paste(sort(unique(dir_gene$failure_direction)),collapse=";"))

# --------------------------------------------------------------------------
# METHOD CONTRACT — frozen before any association result.
# --------------------------------------------------------------------------
contract <- data.frame(
  item=c(
    "module_role",
    "cohort",
    "biological_replicate",
    "analysis_universe",
    "tissue",
    "risk_order",
    "risk_numeric_coding",
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
    "primary_program_test",
    "primary_program_test_sidedness",
    "primary_program_FDR",
    "primary_program_family_size",
    "primary_support_rule",
    "primary_opposite_rule",
    "primary_nonsignificant_rule",
    "sex_adjusted_sensitivity",
    "sex_reference",
    "sex_adjusted_FDR",
    "sex_adjusted_role",
    "nonmonotonic_sensitivity",
    "nonmonotonic_FDR",
    "nonmonotonic_role",
    "primary25_expression",
    "primary25_failure_orientation",
    "primary25_test",
    "primary25_FDR",
    "primary25_family_size",
    "primary25_role",
    "unassessable_padding",
    "posthoc_pairwise_testing",
    "new_pathway_discovery",
    "new_gene_discovery",
    "threshold_retuning_after_results",
    "primary_rescue_by_sensitivity",
    "site_confounding_relevance",
    "severity_outcome_testing_executed_in_step1",
    "program_scores_calculated_in_step1",
    "gene_severity_tests_executed_in_step1",
    "next_stage"
  ),
  value=c(
    "SECONDARY_DEPTH_VALIDATION",
    "GSE249696_BASELINE_CTEPH",
    "PATIENT",
    "71_BASELINE_PATIENTS",
    "RV_FREE_WALL",
    "MODERATE<INTERMEDIATE<SEVERE",
    "MODERATE=0;INTERMEDIATE=1;SEVERE=2",
    "GEO_DESEQ_NORMALIZED_GENE_COUNTS",
    "LOG2_NORMALIZED_COUNT_PLUS_1",
    "Ensembl gene",
    "TRIMMED_EXACT_HGNC_SYMBOL",
    "FAIL_IF_FROZEN_TARGET_SYMBOL_MAPS_TO_MULTIPLE_MATRIX_ROWS",
    "FINITE_IN_ALL_71_AND_SAMPLE_SD_GREATER_THAN_0;ZERO_SD_EXCLUDED_BEFORE_OUTCOME_TEST",
    "0.80",
    "10",
    "GENEWISE_Z_ACROSS_ALL_71_BASELINE_PATIENTS_USING_SAMPLE_SD",
    "MEAN_OF_USABLE_MEMBER_GENE_Z_SCORES_PER_PATIENT",
    "RAW_SCORE_X_PLUS1_IF_UP_IN_FAILURE_ELSE_MINUS1_IF_DOWN_IN_FAILURE",
    "SPEARMAN_CORRELATION_FAILURE_ORIENTED_SCORE_VS_RISK_ORDINAL",
    "TWO_SIDED_EXACT_FALSE_DUE_TO_RISK_TIES",
    "BH_ACROSS_PADDED_16_PROGRAM_FAMILY",
    "16",
    "BH_FDR_LT_0.05_AND_RHO_GT_0",
    "BH_FDR_LT_0.05_AND_RHO_LT_0",
    "BH_FDR_GE_0.05",
    "OLS_FAILURE_ORIENTED_SCORE_TILDE_RISK_ORDINAL_PLUS_SEX",
    "Female",
    "BH_ACROSS_16_SEX_ADJUSTED_RISK_COEFFICIENT_P_VALUES",
    "SENSITIVITY_ONLY_CANNOT_RESCUE_PRIMARY",
    "KRUSKAL_WALLIS_FAILURE_ORIENTED_SCORE_ACROSS_3_RISK_GROUPS",
    "BH_ACROSS_16_KRUSKAL_WALLIS_P_VALUES",
    "SENSITIVITY_ONLY_NONMONOTONIC_GROUP_DIFFERENCE",
    "GENEWISE_LOG2_NORMALIZED_COUNT_PLUS_1_THEN_Z_ACROSS_71",
    "PLUS1_IF_UP_RVF_vs_pRV_ELSE_MINUS1_IF_DOWN_RVF_vs_pRV",
    "SPEARMAN_CORRELATION_FAILURE_ORIENTED_GENE_Z_VS_RISK_ORDINAL_TWO_SIDED",
    "BH_ACROSS_PADDED_25_GENE_FAMILY",
    "25",
    "SECONDARY_TARGET_FAMILY_NOT_PROGRAM_PRIMARY",
    "IF_PREDEFINED_TARGET_UNASSESSABLE_SET_P_EQUAL_1_AND_RETAIN_IN_BH_DENOMINATOR",
    "NO_INFERENTIAL_PAIRWISE_TESTS",
    "NO",
    "NO",
    "NO",
    "NO",
    "NONE_FOR_R4A_BASELINE_ONLY_ALL_SAMPLES_SAME_RV_FREE_WALL_SITE",
    "NO",
    "NO",
    "NO",
    "R4A_STEP2_DETERMINISTIC_SEVERITY_EXECUTION_AFTER_INDEPENDENT_AUDIT"
  ),
  stringsAsFactors=FALSE
)

design <- as.data.frame.matrix(table(
  factor(bl$esc_risk_group,levels=risk_levels),
  factor(bl$sex,levels=c("Female","Male"))
))
design$risk_group <- rownames(design)
rownames(design) <- NULL
design <- design[,c("risk_group","Female","Male")]
design$total <- design$Female + design$Male

awrite(contract,file.path(OUT,"R4A_STEP1_METHOD_CONTRACT.csv"))
awrite(program_map,file.path(OUT,"R4A_STEP1_PROGRAM_MAPPING_AUDIT.csv"))
awrite(gene_map,file.path(OUT,"R4A_STEP1_PRIMARY25_MAPPING_AUDIT.csv"))
awrite(design,file.path(OUT,"R4A_STEP1_DESIGN_BALANCE.csv"))
awrite(do.call(rbind,AUD),file.path(OUT,"R4A_STEP1_METHOD_CONTRACT_AUDIT.csv"))

# Input identity ledger.
inp <- do.call(rbind,lapply(names(P),function(nm) data.frame(
  input_id=nm,
  path=P[[nm]],
  bytes=file.info(P[[nm]])$size,
  sha256=sha256(P[[nm]]),
  stringsAsFactors=FALSE
)))
awrite(inp,file.path(OUT,"R4A_STEP1_INPUT_SHA256.csv"))

audit <- do.call(rbind,AUD)
hard_fail <- sum(audit$status=="FAIL" & audit$critical=="YES")
state <- if(hard_fail==0L) {
  "PASS_R4A_STEP1_METHOD_CONTRACT_READY_FOR_INDEPENDENT_AUDIT"
} else {
  "HOLD_R4A_STEP1_METHOD_CONTRACT"
}

awrite(data.frame(
  final_state=state,
  run_id=STAMP,
  hard_failures=hard_fail,
  severity_outcome_testing_executed="NO",
  program_scores_calculated="NO",
  gene_severity_tests_executed="NO",
  new_discovery_executed="NO",
  next_stage=if(hard_fail==0L)
    "CHATGPT_INDEPENDENT_AUDIT_THEN_R4A_STEP2_DETERMINISTIC_SEVERITY_EXECUTION"
  else "STOP_AND_REPAIR_METHOD_CONTRACT",
  stringsAsFactors=FALSE
),file.path(OUT,"R4A_STEP1_STATUS.csv"))

cat("FINAL_STATE:",state,"\n")
cat("RUN_ID:",STAMP,"\n")
cat("HARD_FAILURES:",hard_fail,"\n")
cat("SEVERITY_OUTCOME_TESTING_EXECUTED:NO\n")
cat("PROGRAM_SCORES_CALCULATED:NO\n")
cat("GENE_SEVERITY_TESTS_EXECUTED:NO\n")
quit(save="no",status=if(hard_fail==0L) 0 else 72,runLast=FALSE)
