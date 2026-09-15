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
# RV Project — R3 Step4D
# LOCALIZATION ANALYSIS CONTRACT FREEZE — PRE-RESULTS
#
# PURPOSE
#   Freeze the complete statistical/localization analysis algorithm BEFORE any
#   snRNA or Xenium localization result is computed.
#
# SCIENTIFIC ALIGNMENT
#   - Primary atlas contrast = RVF vs pRV, matching frozen R0 failure contrast.
#   - All seven frozen primary localization programs are UP_IN_FAILURE in R0.
#   - GSE345646/GSE345643 belong to the same multimodal atlas and therefore
#     provide localization support, NOT independent etiologic validation.
#
# PRIMARY SNRNA METHOD
#   1) RNA raw counts.
#   2) Aggregate by patient × annotation label (pseudobulk).
#   3) A patient-label stratum is eligible only with >=20 nuclei.
#   4) A contrast is testable only with >=3 eligible patients in EACH group.
#   5) edgeR filterByExpr with explicit frozen thresholds.
#   6) TMM normalization.
#   7) limma voom.
#   8) limma mroast self-contained rotation gene-set test:
#        set.statistic="mean", nrot=9999, midp=TRUE.
#      This preserves sample-level inference and accounts for within-set
#      gene correlation without treating genes as independent replicates.
#   9) Program requires >=10 retained genes in the tested lineage.
#
# XENIUM METHOD
#   - Ambient-corrected 477-gene non-integer matrix only.
#   - Aggregate by patient × annotation label.
#   - No NB/count-model inference on corrected fractional counts.
#   - Deterministic log2(1 + CPM) from all 477 measured genes.
#   - mroast on program genes present in the measured panel.
#   - Module-level spatial support requires >=10 measured program genes.
#   - Programs with <10 measured genes remain gene-level context only.
#
# MULTIPLE TESTING
#   - Fixed BH families.
#   - Structurally unassessable tests are padded with P_for_BH=1 so missing
#     strata do not shrink the family.
#   - No pooling across modalities, annotation levels, or contrasts.
#
# NO LOCALIZATION RESULT IS CALCULATED IN THIS GATE.
# ==============================================================================

options(stringsAsFactors = FALSE, warn = 1)

ROOT <- normalizePath(getwd(), winslash="/", mustWork=TRUE)
if (!identical(tolower(ROOT), tolower(RV_PROJECT_ROOT)))
  stop("Expected D:/RV_project")

R3 <- file.path(ROOT, "results", "R3_GSE249696")
LOGD <- file.path(ROOT, "logs")
dir.create(LOGD, recursive=TRUE, showWarnings=FALSE)

C_GATE <- file.path(R3, "R3_STEP4C_V1_2_ANNOTATION_AUTHORITY_TERMINAL_FROZEN.txt")
C_AUD <- file.path(R3, "R3_STEP4C_V1_2_final_annotation_authority_audit.csv")
C_CONTRACT <- file.path(R3, "R3_STEP4C_V1_2_final_annotation_authority_contract.csv")
C_LABELS <- file.path(R3, "R3_STEP4C_V1_2_frozen_annotation_labels.csv")

A_PROGRAM <- file.path(R3, "R3_STEP4A_localization_program_contract.csv")
A_GENE <- file.path(R3, "R3_STEP4A_supported_program_gene_manifest.csv")
B_COV <- file.path(R3, "R3_STEP4B_V1_6_supported_program_feature_coverage.csv")
B_GATE <- file.path(R3, "R3_STEP4B_V1_7_STRUCTURAL_PREFLIGHT_TERMINAL_FROZEN.txt")

OUT_AUD <- file.path(R3, "R3_STEP4D_localization_analysis_contract_audit.csv")
OUT_METHOD <- file.path(R3, "R3_STEP4D_localization_method_contract.csv")
OUT_PROGRAM <- file.path(R3, "R3_STEP4D_program_modality_tier_contract.csv")
OUT_FDR <- file.path(R3, "R3_STEP4D_fixed_FDR_family_contract.csv")
OUT_CLASS <- file.path(R3, "R3_STEP4D_localization_classification_contract.csv")
OUT_PASS <- file.path(R3, "R3_STEP4D_LOCALIZATION_ANALYSIS_CONTRACT_FROZEN.txt")
OUT_HOLD <- file.path(R3, "R3_STEP4D_LOCALIZATION_ANALYSIS_CONTRACT_HOLD.txt")
LOG <- file.path(LOGD, "R3_STEP4D_LOCALIZATION_ANALYSIS_CONTRACT_FREEZE.log")

if (file.exists(LOG)) {
  old <- file.path(
    LOGD,
    paste0(
      "R3_STEP4D_LOCALIZATION_ANALYSIS_CONTRACT_FREEZE_",
      format(Sys.time(), "%Y%m%d_%H%M%S"), "_previous.log"
    )
  )
  file.rename(LOG, old)
}

logline <- function(...) {
  z <- paste0(format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
              " | ", paste0(..., collapse=""))
  cat(z, "\n", sep="")
  cat(z, "\n", file=LOG, append=TRUE, sep="")
  flush.console()
}
replace_file <- function(tmp, dest) {
  if (file.exists(dest)) unlink(dest, force=TRUE)
  if (!file.rename(tmp, dest)) {
    unlink(tmp, force=TRUE)
    stop("Atomic replacement failed: ", dest)
  }
}
awrite <- function(x, p) {
  t <- paste0(p, ".tmp_", Sys.getpid())
  write.csv(x, t, row.names=FALSE, na="")
  replace_file(t, p)
}
twrite <- function(x, p) {
  t <- paste0(p, ".tmp_", Sys.getpid())
  writeLines(x, t, useBytes=TRUE)
  replace_file(t, p)
}

A <- list()
add <- function(item, expected, observed, status, notes="") {
  A[[length(A)+1L]] <<- data.frame(
    item=as.character(item),
    expected=as.character(expected),
    observed=as.character(observed),
    status=as.character(status),
    notes=as.character(notes),
    stringsAsFactors=FALSE
  )
  logline(
    "[", status, "] ", item,
    " | expected=", expected,
    " | observed=", observed,
    if (nzchar(notes)) paste0(" | ", notes) else ""
  )
}
flush_audit <- function() {
  if (length(A)) awrite(do.call(rbind, A), OUT_AUD)
}
hold <- function(reason, code=441L) {
  flush_audit()
  twrite(c(
    "R3_STEP4D_LOCALIZATION_ANALYSIS_CONTRACT_HOLD",
    paste0("timestamp=", format(Sys.time(), "%Y-%m-%d %H:%M:%S %z")),
    paste0("reason=", reason),
    "RDS_loaded=NO",
    "expression_values_used=NO",
    "pseudobulk_generated=NO",
    "mroast_executed=NO",
    "module_scoring_executed=NO",
    "disease_group_testing_executed=NO",
    "program_reclassification=NO",
    "automatic_rerun_allowed=NO"
  ), OUT_HOLD)
  logline("FINAL_GATE: HOLD | ", reason)
  quit(save="no", status=code, runLast=FALSE)
}
options(error=function() {
  msg <- geterrmessage()
  try(logline("[UNHANDLED_R_ERROR] ",
              gsub("[\r\n]+"," | ",msg)), silent=TRUE)
  try(flush_audit(), silent=TRUE)
  try(twrite(c(
    "R3_STEP4D_LOCALIZATION_ANALYSIS_CONTRACT_HOLD_RUNTIME_ERROR",
    paste0("error=", gsub("[\r\n]+"," | ",msg)),
    "automatic_rerun_allowed=NO"
  ), OUT_HOLD), silent=TRUE)
  q(save="no", status=442, runLast=FALSE)
})

parse_kv <- function(p) {
  z <- readLines(p, warn=FALSE, encoding="UTF-8")
  z <- z[nzchar(trimws(z)) & grepl("=", z, fixed=TRUE)]
  v <- sub("^[^=]*=", "", z)
  names(v) <- sub("=.*$", "", z)
  v
}

logline("============================================================")
logline("R3 Step4D localization analysis contract freeze")
logline("PRE-RESULTS ONLY: no RDS load, no expression use")
logline("============================================================")

needed <- c(C_GATE,C_AUD,C_CONTRACT,C_LABELS,A_PROGRAM,A_GENE,B_COV,B_GATE)
for (p in needed) {
  ok <- file.exists(p)
  add(paste0("file_exists:",basename(p)),
      "YES", if(ok)"YES" else "NO", if(ok)"PASS" else "FAIL")
}
if (any(!file.exists(needed)))
  hold("MISSING_REQUIRED_FROZEN_INPUT",443L)

# --------------------------------------------------------------------------
# Step4C terminal authority must be exact and clean.
# --------------------------------------------------------------------------
cg <- parse_kv(C_GATE)
req_c <- c(
  Step4C_status="FINAL_CLOSED",
  strict_parent_child_hierarchy_assumed="NO",
  snRNA_primary_broad_annotation="Names",
  snRNA_primary_broad_labels="12",
  snRNA_fine_annotation="Subnames_manual",
  snRNA_fine_labels="34",
  Xenium_primary_spatial_annotation="cell_type_rctd_doublet",
  Xenium_primary_spatial_labels="12",
  Xenium_secondary_fine_annotation="cell_type_seurat",
  Xenium_secondary_fine_labels="34",
  cross_modal_primary_broad_label_sets_exact_match="YES",
  inferential_replicate="PATIENT",
  cell_level_pseudoreplication_allowed="NO",
  Xenium_measured_panel_genes="477",
  Xenium_imputation_to_expand_primary_evidence_allowed="NO",
  localization_can_redefine_Step3F_program_class="NO"
)
for (k in names(req_c)) {
  obs <- if(k %in% names(cg)) unname(cg[[k]]) else "<MISSING>"
  exp <- unname(req_c[[k]])
  add(paste0("Step4C invariant:",k), exp, obs,
      if(identical(obs,exp))"PASS" else "FAIL")
}

ca <- read.csv(C_AUD, stringsAsFactors=FALSE, check.names=FALSE)
# Clean Step4C V1.2 no longer emits the three historical V1.0 replay/input checks
# removed from the public cold-start path. Its accepted audit cardinality is 41.
add("Step4C V1.2 audit rows","41",nrow(ca),
    if(nrow(ca)==41L)"PASS" else "FAIL")
add("Step4C V1.2 audit FAIL rows","0",
    sum(ca$status=="FAIL",na.rm=TRUE),
    if(sum(ca$status=="FAIL",na.rm=TRUE)==0L)"PASS" else "FAIL")

# --------------------------------------------------------------------------
# Exact broad/fine annotation universes.
# --------------------------------------------------------------------------
labs <- read.csv(C_LABELS, stringsAsFactors=FALSE, check.names=FALSE)
broad_sn <- sort(as.character(labs$label[
  labs$dataset=="GSE345646_snRNA" & labs$field=="Names"
]))
broad_xe <- sort(as.character(labs$label[
  labs$dataset=="GSE345643_Xenium_ambient_corrected" &
  labs$field=="cell_type_rctd_doublet"
]))
fine_sn <- sort(as.character(labs$label[
  labs$dataset=="GSE345646_snRNA" & labs$field=="Subnames_manual"
]))
fine_xe <- sort(as.character(labs$label[
  labs$dataset=="GSE345643_Xenium_ambient_corrected" &
  labs$field=="cell_type_seurat"
]))

broad_expected <- sort(c(
  "Adipo","CM","EC","Endo","Epi","FB","LEC","Myeloid",
  "NKT","Neuron","PC","SM"
))
add("snRNA broad labels exact 12",
    paste(broad_expected,collapse=";"),
    paste(broad_sn,collapse=";"),
    if(identical(broad_sn,broad_expected))"PASS" else "FAIL")
add("Xenium broad labels exact 12",
    paste(broad_expected,collapse=";"),
    paste(broad_xe,collapse=";"),
    if(identical(broad_xe,broad_expected))"PASS" else "FAIL")
add("snRNA fine label count","34",length(fine_sn),
    if(length(fine_sn)==34L)"PASS" else "FAIL")
add("Xenium fine label count","34",length(fine_xe),
    if(length(fine_xe)==34L)"PASS" else "FAIL")

# --------------------------------------------------------------------------
# Exact seven programs / Step3F class / R0 failure direction.
# --------------------------------------------------------------------------
pc <- read.csv(A_PROGRAM, stringsAsFactors=FALSE, check.names=FALSE)
pg <- pc[pc$primary_localization_target %in% c(TRUE,"TRUE"),,drop=FALSE]
pg <- pg[order(pg$pathway),,drop=FALSE]

expected_programs <- sort(c(
  "HALLMARK_APICAL_JUNCTION",
  "HALLMARK_ESTROGEN_RESPONSE_EARLY",
  "HALLMARK_IL2_STAT5_SIGNALING",
  "HALLMARK_IL6_JAK_STAT3_SIGNALING",
  "HALLMARK_INTERFERON_ALPHA_RESPONSE",
  "HALLMARK_INTERFERON_GAMMA_RESPONSE",
  "HALLMARK_TNFA_SIGNALING_VIA_NFKB"
))
add("primary localization program identities",
    paste(expected_programs,collapse=";"),
    paste(sort(pg$pathway),collapse=";"),
    if(identical(sort(pg$pathway),expected_programs))"PASS" else "FAIL")
add("primary localization program count","7",nrow(pg),
    if(nrow(pg)==7L)"PASS" else "FAIL")
add("all primary localization failure directions",
    "UP_IN_FAILURE",
    paste(unique(as.character(pg$failure_direction)),collapse=";"),
    if(nrow(pg)==7L && all(pg$failure_direction=="UP_IN_FAILURE"))"PASS" else "FAIL")
add("reversal / worsening program counts","5_REVERSAL_2_WORSENING",
    paste0(
      sum(pg$program_class=="PROGRAM_REVERSAL_SUPPORTED"),
      "_REVERSAL_",
      sum(pg$program_class=="PROGRAM_MALADAPTIVE_NONREVERSAL_WORSENING_SUPPORTED"),
      "_WORSENING"
    ),
    if(
      sum(pg$program_class=="PROGRAM_REVERSAL_SUPPORTED")==5L &&
      sum(pg$program_class=="PROGRAM_MALADAPTIVE_NONREVERSAL_WORSENING_SUPPORTED")==2L
    ) "PASS" else "FAIL"
)

gm <- read.csv(A_GENE, stringsAsFactors=FALSE, check.names=FALSE)
add("frozen primary module membership rows","1183",nrow(gm),
    if(nrow(gm)==1183L)"PASS" else "FAIL")
add("frozen module duplicate pathway-gene pairs","0",
    sum(duplicated(gm[,c("pathway","gene_symbol")])),
    if(!anyDuplicated(gm[,c("pathway","gene_symbol")]))"PASS" else "FAIL")

# --------------------------------------------------------------------------
# Xenium pre-outcome panel coverage tiers.
# --------------------------------------------------------------------------
cov <- read.csv(B_COV, stringsAsFactors=FALSE, check.names=FALSE)
xc <- cov[
  cov$dataset=="GSE345643_Xenium_ambient_corrected" &
  cov$pathway %in% expected_programs,
  c("pathway","frozen_module_genes","genes_present","coverage_fraction"),
  drop=FALSE
]
xc <- xc[order(xc$pathway),,drop=FALSE]
expected_present <- c(
  HALLMARK_APICAL_JUNCTION=14L,
  HALLMARK_ESTROGEN_RESPONSE_EARLY=9L,
  HALLMARK_IL2_STAT5_SIGNALING=20L,
  HALLMARK_IL6_JAK_STAT3_SIGNALING=11L,
  HALLMARK_INTERFERON_ALPHA_RESPONSE=3L,
  HALLMARK_INTERFERON_GAMMA_RESPONSE=17L,
  HALLMARK_TNFA_SIGNALING_VIA_NFKB=25L
)
coverage_ok <- nrow(xc)==7L &&
  all(as.integer(xc$genes_present)==
        as.integer(expected_present[xc$pathway]))
add("Xenium 7-program measured-gene coverage",
    "14,9,20,11,3,17,25_BY_FROZEN_PATHWAY",
    if(coverage_ok)"14,9,20,11,3,17,25_BY_FROZEN_PATHWAY" else "MISMATCH",
    if(coverage_ok)"PASS" else "FAIL")

if (any(vapply(A,function(x)any(x$status=="FAIL"),logical(1))))
  hold("UPSTREAM_AUTHORITY_OR_IDENTITY_DRIFT",444L)

# --------------------------------------------------------------------------
# Program modality tier contract.
# --------------------------------------------------------------------------
program <- merge(
  pg[,c("pathway","failure_direction","program_class")],
  xc,
  by="pathway",
  all.x=TRUE,
  sort=TRUE
)
program$snRNA_primary_module_status <- "FULL_MODULE_PRIMARY_ELIGIBLE"
program$snRNA_min_retained_genes_per_test <- 10L
program$Xenium_module_status <- ifelse(
  program$genes_present >= 10L,
  "PANEL_RESTRICTED_MODULE_LEVEL_ELIGIBLE",
  "LOW_COVERAGE_GENE_LEVEL_CONTEXT_ONLY"
)
program$Xenium_module_family_member <- program$genes_present >= 10L
program$Xenium_imputed_gene_use <- "PROHIBITED"
program$can_redefine_Step3F_class <- "NO"
awrite(program,OUT_PROGRAM)

add("Xenium module-level eligible programs","5",
    sum(program$Xenium_module_family_member),
    if(sum(program$Xenium_module_family_member)==5L)"PASS" else "FAIL")
low <- sort(program$pathway[!program$Xenium_module_family_member])
low_exp <- sort(c(
  "HALLMARK_ESTROGEN_RESPONSE_EARLY",
  "HALLMARK_INTERFERON_ALPHA_RESPONSE"
))
add("Xenium low-coverage context-only programs",
    paste(low_exp,collapse=";"),
    paste(low,collapse=";"),
    if(identical(low,low_exp))"PASS" else "FAIL")

# --------------------------------------------------------------------------
# Frozen method contract.
# --------------------------------------------------------------------------
method <- data.frame(
  scope=c(
    "GLOBAL","GLOBAL","GLOBAL","GLOBAL","GLOBAL","GLOBAL","GLOBAL",
    "SNRNA","SNRNA","SNRNA","SNRNA","SNRNA","SNRNA","SNRNA","SNRNA",
    "SNRNA","SNRNA",
    "XENIUM","XENIUM","XENIUM","XENIUM","XENIUM","XENIUM","XENIUM",
    "XENIUM","XENIUM","XENIUM","XENIUM",
    "CROSS_MODAL","CROSS_MODAL","CROSS_MODAL","CROSS_MODAL"
  ),
  parameter=c(
    "PRIMARY_CONTRAST",
    "SECONDARY_BROAD_CONTRAST_1",
    "SECONDARY_BROAD_CONTRAST_2",
    "INFERENTIAL_REPLICATE",
    "MIN_CELLS_PER_PATIENT_LABEL",
    "MIN_ELIGIBLE_PATIENTS_PER_GROUP",
    "PROGRAM_MIN_GENES_PER_TEST",
    "COUNT_INPUT",
    "PRIMARY_BROAD_ANNOTATION",
    "SECONDARY_FINE_ANNOTATION",
    "PSEUDOBULK_AGGREGATION",
    "FILTER_BY_EXPR",
    "NORMALIZATION",
    "VOOM",
    "GENE_SET_TEST",
    "MROAST_SETTINGS",
    "PRIMARY_BROAD_CLASSIFICATION_ROLE",
    "COUNT_INPUT",
    "PRIMARY_BROAD_ANNOTATION",
    "SECONDARY_FINE_ANNOTATION",
    "PSEUDOBULK_AGGREGATION",
    "NEGATIVE_VALUE_POLICY",
    "LIBRARY_NORMALIZATION",
    "COUNT_MODEL_ALLOWED",
    "GENE_SET_TEST",
    "MROAST_SETTINGS",
    "MODULE_ELIGIBILITY",
    "PER_CELL_SPATIAL_MAP_ROLE",
    "PRIMARY_SHARED_LABEL_SPACE",
    "FINE_LABEL_HARMONIZATION",
    "COMBINED_P_VALUE_ALLOWED",
    "INDEPENDENT_VALIDATION_WORDING_ALLOWED"
  ),
  frozen_value=c(
    "RVF_MINUS_pRV",
    "pRV_MINUS_NF",
    "RVF_MINUS_NF",
    "PATIENT",
    "20",
    "3",
    "10",
    "RNA_RAW_COUNTS",
    "Names_12",
    "Subnames_manual_34_INDEPENDENT_VIEW",
    "SUM_COUNTS_WITHIN_PATIENT_X_LABEL",
    "edgeR_filterByExpr_min.count10_min.total.count15_large.n10_min.prop0.7",
    "edgeR_TMM",
    "limma_voom",
    "limma_mroast_SELF_CONTAINED_ROTATION_TEST",
    "set.statistic=mean;nrot=9999;midp=TRUE;two_sided_directional_PValue",
    "PRIMARY_CELLULAR_LOCALIZATION_SUPPORT",
    "AMBIENT_CORRECTED_NONINTEGER_XENIUM_COUNTS_477_GENES",
    "cell_type_rctd_doublet_12",
    "cell_type_seurat_34_INDEPENDENT_VIEW",
    "SUM_CORRECTED_COUNTS_WITHIN_PATIENT_X_LABEL",
    "ANY_NEGATIVE_VALUE_HOLD",
    "log2(1+1e6*gene_sum/total_477_gene_sum)",
    "NO_NEGATIVE_BINOMIAL_OR_POISSON_COUNT_MODEL",
    "limma_mroast_SELF_CONTAINED_ROTATION_TEST",
    "set.statistic=mean;nrot=9999;midp=TRUE;trend.var=TRUE;two_sided_directional_PValue",
    ">=10_MEASURED_AND_NONZERO_PROGRAM_GENES_IN_TEST",
    "DESCRIPTIVE_ONLY_NO_P_FDR_NO_HOTSPOT_THRESHOLD",
    "EXACT_12_BROAD_LABELS",
    "NONE_34_LEVEL_LABELS_REMAIN_WITHIN_DATASET_ONLY",
    "NO",
    "NO"
  ),
  rationale=c(
    "Matches frozen R0 failure contrast and directly localizes the failure-associated programs.",
    "Trajectory context only; cannot define primary localization.",
    "Trajectory context only; cannot define primary localization.",
    "Prevents cell/nucleus pseudoreplication.",
    "Pre-frozen technical stability threshold for a patient-label pseudobulk.",
    "Avoids inference from fewer than three biological replicates per group.",
    "Matches the existing Hallmark minimum-size convention and avoids tiny-set module claims.",
    "Unmodified raw UMI layer is the pseudobulk source.",
    "Frozen Step4C primary shared broad-lineage authority.",
    "Frozen Step4C fine annotation; analyzed independently, not nested under Names.",
    "All qualifying nuclei contribute; cells are never inferential replicates.",
    "Explicit thresholds prevent version-default drift.",
    "Library-size normalization at patient pseudobulk level.",
    "Preserves RNA-seq mean-variance modeling and weights.",
    "Self-contained rotation test asks whether the prespecified program changes within a lineage and preserves within-set correlation.",
    "Fixed settings before outcomes; use Direction plus two-sided PValue, not Mixed PValue.",
    "Primary claims arise only from snRNA broad RVF-vs-pRV family.",
    "Official processed spatial matrix; fractional corrected values are not treated as raw integer counts.",
    "Frozen RCTD cell-type authority from Step4C.",
    "Secondary fine spatial context only.",
    "Patient-level biological aggregation.",
    "Fail closed if correction produced negative values incompatible with frozen transform.",
    "Deterministic within-panel library normalization; no TMM assumption on targeted panel.",
    "Ambient-corrected noninteger values are not modeled as raw count likelihoods.",
    "Self-contained test avoids using a targeted 477-gene panel as a competitive background.",
    "Fixed settings; trend variance used for unweighted logCPM-like continuous matrix.",
    "Prevents module-level claims from very small measured subsets.",
    "Maps may illustrate spatial distribution but cannot create inferential significance.",
    "Only broad labels have exact cross-modal identity.",
    "No outcome-driven manual subtype mapping.",
    "Same-cohort modalities are not combined into meta-analytic evidence.",
    "Same multimodal atlas provides corroboration/localization, not independent validation."
  ),
  stringsAsFactors=FALSE
)
awrite(method,OUT_METHOD)

# --------------------------------------------------------------------------
# Fixed BH families — unassessable tests padded with P=1.
# --------------------------------------------------------------------------
fdr <- data.frame(
  family_id=c(
    "SN_BROAD_RVF_vs_pRV_PRIMARY",
    "SN_BROAD_pRV_vs_NF_CONTEXT",
    "SN_BROAD_RVF_vs_NF_CONTEXT",
    "SN_FINE_RVF_vs_pRV_SECONDARY",
    "XE_BROAD_RVF_vs_pRV_PANEL_PRIMARY_SUPPORT",
    "XE_BROAD_pRV_vs_NF_PANEL_CONTEXT",
    "XE_BROAD_RVF_vs_NF_PANEL_CONTEXT",
    "XE_FINE_RVF_vs_pRV_PANEL_SECONDARY"
  ),
  dataset=c(
    rep("GSE345646_snRNA",4),
    rep("GSE345643_Xenium_ambient_corrected",4)
  ),
  annotation_level=c(
    "BROAD_12","BROAD_12","BROAD_12","FINE_34",
    "BROAD_12","BROAD_12","BROAD_12","FINE_34"
  ),
  contrast=c(
    "RVF_MINUS_pRV","pRV_MINUS_NF","RVF_MINUS_NF","RVF_MINUS_pRV",
    "RVF_MINUS_pRV","pRV_MINUS_NF","RVF_MINUS_NF","RVF_MINUS_pRV"
  ),
  n_fixed_labels=c(12L,12L,12L,34L,12L,12L,12L,34L),
  n_fixed_programs=c(7L,7L,7L,7L,5L,5L,5L,5L),
  max_family_tests=c(84L,84L,84L,238L,60L,60L,60L,170L),
  unassessable_BH_input="P_EQUALS_1",
  adjustment="BH",
  threshold=0.05,
  primary_claim_role=c(
    "YES","NO_CONTEXT_ONLY","NO_CONTEXT_ONLY","NO_SECONDARY",
    "NO_PANEL_CORROBORATION_ONLY","NO_CONTEXT_ONLY","NO_CONTEXT_ONLY","NO_SECONDARY"
  ),
  stringsAsFactors=FALSE
)
awrite(fdr,OUT_FDR)

# --------------------------------------------------------------------------
# Classification semantics frozen before results.
# --------------------------------------------------------------------------
classes <- data.frame(
  dataset_scope=c(
    "SNRNA_PRIMARY_BROAD",
    "SNRNA_PRIMARY_BROAD",
    "SNRNA_PRIMARY_BROAD",
    "SNRNA_PRIMARY_BROAD",
    "XENIUM_PANEL_MODULE",
    "XENIUM_PANEL_MODULE",
    "XENIUM_PANEL_MODULE",
    "XENIUM_PANEL_MODULE",
    "XENIUM_LOW_COVERAGE",
    "CROSS_MODAL",
    "CROSS_MODAL",
    "GLOBAL"
  ),
  condition=c(
    "assessable_AND_BH_lt_0.05_AND_Direction_Up",
    "assessable_AND_BH_lt_0.05_AND_Direction_Down",
    "assessable_AND_BH_ge_0.05",
    "not_assessable",
    "module_eligible_AND_assessable_AND_BH_lt_0.05_AND_Direction_Up",
    "module_eligible_AND_assessable_AND_BH_lt_0.05_AND_Direction_Down",
    "module_eligible_AND_assessable_AND_BH_ge_0.05",
    "module_eligible_AND_not_assessable",
    "measured_program_genes_lt_10",
    "snRNA_supported_AND_Xenium_supported_same_broad_label",
    "significant_direction_opposite_between_modalities",
    "anything_else"
  ),
  frozen_label=c(
    "SNRNA_CELLULAR_FAILURE_PROGRAM_LOCALIZATION_SUPPORTED",
    "SNRNA_CELLULAR_DIRECTION_CONFLICT",
    "SNRNA_CELLULAR_INDETERMINATE_NO_SIGNAL",
    "SNRNA_CELLULAR_UNASSESSABLE",
    "XENIUM_PANEL_SPATIAL_CORROBORATION_SUPPORTED",
    "XENIUM_PANEL_DIRECTION_CONFLICT",
    "XENIUM_PANEL_INDETERMINATE_NO_SIGNAL",
    "XENIUM_PANEL_UNASSESSABLE",
    "XENIUM_LOW_COVERAGE_GENE_LEVEL_CONTEXT_ONLY",
    "CROSS_MODAL_BROAD_CORROBORATION_SAME_COHORT",
    "CROSS_MODAL_SIGNIFICANT_DIRECTION_CONFLICT",
    "NO_NEW_STEP3F_PROGRAM_CLASS"
  ),
  wording_guard=c(
    "Failure-program localization support; not causal cell-of-origin proof.",
    "Do not reinterpret upstream Step3F trajectory class.",
    "Nonsignificance is indeterminate, not absence.",
    "No inference.",
    "Panel-restricted same-cohort spatial corroboration only.",
    "Report conflict; do not rescue by fine-label remapping.",
    "Nonsignificance is indeterminate, not absence.",
    "No inference.",
    "No Xenium module-level program claim.",
    "Do not call independent validation.",
    "Report discordance; do not combine p-values.",
    "Localization cannot redefine reversal/worsening/site-conflict/indeterminate classes."
  ),
  stringsAsFactors=FALSE
)
awrite(classes,OUT_CLASS)

# Contract guards.
add("primary atlas contrast","RVF_MINUS_pRV","RVF_MINUS_pRV","PASS")
add("patient-label minimum cells","20","20","PASS")
add("minimum eligible patients per group","3","3","PASS")
add("snRNA test method","MROAST_AFTER_TMM_VOOM",
    "MROAST_AFTER_TMM_VOOM","PASS")
add("Xenium test method","MROAST_AFTER_LOG2_1PLUS_CPM",
    "MROAST_AFTER_LOG2_1PLUS_CPM","PASS")
add("mroast set statistic","mean","mean","PASS")
add("mroast rotations","9999","9999","PASS")
add("mroast p-value used","TWO_SIDED_DIRECTIONAL_PValue",
    "TWO_SIDED_DIRECTIONAL_PValue","PASS")
add("unassessable BH padding","P_EQUALS_1","P_EQUALS_1","PASS")
add("snRNA primary broad BH family max","84","84","PASS")
add("Xenium module broad BH family max","60","60","PASS")
add("cell-level p/FDR allowed","NO","NO","PASS")
add("Xenium count likelihood model allowed","NO","NO","PASS")
add("Xenium module eligibility minimum measured genes","10","10","PASS")
add("Xenium low-coverage programs","2","2","PASS")
add("cross-modal combined p-value allowed","NO","NO","PASS")
add("localization is independent validation","NO","NO","PASS")
add("localization can redefine Step3F class","NO","NO","PASS")
add("RDS loaded","NO","NO","PASS")
add("expression values used","NO","NO","PASS")
add("pseudobulk generated","NO","NO","PASS")
add("mroast executed","NO","NO","PASS")
add("disease-group testing executed","NO","NO","PASS")
add("program reclassification","NO","NO","PASS")

if (any(vapply(A,function(x)any(x$status=="FAIL"),logical(1))))
  hold("CONTRACT_ACCOUNTING_FAILURE",445L)

flush_audit()

twrite(c(
  "R3_STEP4D_LOCALIZATION_ANALYSIS_CONTRACT_FROZEN",
  paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
  "upstream_Step4C_status=FINAL_CLOSED",
  "role=PRERESULT_LOCALIZATION_ANALYSIS_CONTRACT",
  "primary_contrast=RVF_MINUS_pRV",
  "secondary_broad_contrasts=pRV_MINUS_NF;RVF_MINUS_NF",
  "inferential_replicate=PATIENT",
  "minimum_cells_per_patient_annotation=20",
  "minimum_eligible_patients_per_group=3",
  "minimum_program_genes_per_test=10",
  "snRNA_primary_broad_annotation=Names_12",
  "snRNA_secondary_fine_annotation=Subnames_manual_34_INDEPENDENT_VIEW",
  "snRNA_input=RNA_RAW_COUNTS",
  "snRNA_pseudobulk=SUM_BY_PATIENT_X_ANNOTATION",
  "snRNA_filterByExpr=min.count10;min.total.count15;large.n10;min.prop0.7",
  "snRNA_normalization=TMM",
  "snRNA_mean_variance=VOOM",
  "snRNA_program_test=MROAST_SELF_CONTAINED_ROTATION",
  "Xenium_primary_broad_annotation=cell_type_rctd_doublet_12",
  "Xenium_secondary_fine_annotation=cell_type_seurat_34_INDEPENDENT_VIEW",
  "Xenium_input=AMBIENT_CORRECTED_NONINTEGER_477_GENE_MATRIX",
  "Xenium_pseudobulk=SUM_BY_PATIENT_X_ANNOTATION",
  "Xenium_normalization=LOG2_1PLUS_CPM_USING_TOTAL_477_MEASURED_GENES",
  "Xenium_count_likelihood_model=PROHIBITED",
  "Xenium_module_level_programs=5",
  "Xenium_low_coverage_gene_level_context_programs=HALLMARK_ESTROGEN_RESPONSE_EARLY;HALLMARK_INTERFERON_ALPHA_RESPONSE",
  "Xenium_imputation_to_expand_primary_evidence=PROHIBITED",
  "mroast_set_statistic=mean",
  "mroast_nrot=9999",
  "mroast_midp=TRUE",
  "mroast_primary_PValue=TWO_SIDED_DIRECTIONAL",
  "BH_unassessable_padding=P_EQUALS_1",
  "snRNA_primary_broad_fixed_family=84",
  "Xenium_primary_broad_module_fixed_family=60",
  "BH_threshold=0.05",
  "nonsignificant_localization=INDETERMINATE_NOT_ABSENT",
  "cross_modal_combined_pvalue=NO",
  "cross_modal_role=SAME_COHORT_CORROBORATION_NOT_INDEPENDENT_VALIDATION",
  "localization_can_redefine_Step3F_program_class=NO",
  "RDS_loaded=NO",
  "expression_values_used=NO",
  "pseudobulk_generated=NO",
  "mroast_executed=NO",
  "disease_group_testing_executed=NO",
  "program_reclassification=NO",
  "next_stage=R3_STEP4E_LOCALIZATION_RUNTIME_ENVIRONMENT_PREFLIGHT_THEN_EXECUTION_UNDER_FROZEN_STEP4D_CONTRACT"
), OUT_PASS)

if (file.exists(OUT_HOLD)) unlink(OUT_HOLD, force=TRUE)
logline("FINAL_GATE: R3_STEP4D_LOCALIZATION_ANALYSIS_CONTRACT_FROZEN")
quit(save="no", status=0, runLast=FALSE)
