# ---- RV PUBLIC PRIMARY DAG GATE9J REWRITE V1.0 ----
# source_id=C0319
# rewrite_scope=HISTORY_CHAIN_ONLY
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
# RV Project — R3 Step4C V1.2
# FINAL ANNOTATION AUTHORITY ADJUDICATION / TERMINAL FREEZE
#
# INPUT AUTHORITY
#   Step4B V1.7 = structural preflight FINAL_CLOSED.
#   Step4C V1.0 = CLEAN HOLD before localization results because an untested
#                 strict parent-child annotation assumption failed.
#   Step4C V1.1 = CLEAN annotation-relationship discovery:
#                 26 PASS / 4 INFO / 0 FAIL.
#
# V1.2 ADJUDICATION
#   snRNA:
#     Names            = primary broad-lineage annotation authority (12 labels)
#     Subnames_manual  = fine-grained annotation authority (34 labels)
#     Subnames         = intermediate/context-only annotation (37 labels)
#     IMPORTANT: Names and Subnames_manual are INDEPENDENT ANNOTATION VIEWS;
#                Subnames_manual is NOT asserted to be a strict child of Names.
#
#   Xenium:
#     cell_type_rctd_doublet = primary spatial cell-type authority (12 labels)
#     cell_type_seurat       = secondary fine spatial annotation/context (34)
#     IMPORTANT: these are INDEPENDENT ANNOTATION VIEWS; no strict hierarchy.
#     Official GEO method authority states that spatial cell types were assigned
#     by RCTD against the matched snRNA-seq reference with SPLIT correction.
#
# CROSS-MODAL
#   The 12 broad labels are exactly shared:
#     Adipo, CM, EC, Endo, Epi, FB, LEC, Myeloid, NKT, Neuron, PC, SM
#   Therefore primary cross-modal lineage localization may use these 12 labels.
#   Fine labels are NOT manually harmonized across snRNA and Xenium.
#
# GOVERNANCE
#   Patient is the inferential replicate.
#   Cells/nuclei are not independent inferential replicates.
#   Xenium remains 477-gene panel-restricted spatial support only.
#   No imputation may create unmeasured Xenium genes for primary evidence.
#   Localization cannot redefine Step3F program classes.
#
# THIS GATE DOES NOT LOAD RDS FILES OR USE EXPRESSION VALUES.
# ==============================================================================

options(stringsAsFactors=FALSE, warn=1)

ROOT <- normalizePath(getwd(), winslash="/", mustWork=TRUE)
if (!identical(tolower(ROOT), tolower(RV_PROJECT_ROOT)))
  stop("Expected D:/RV_project")

R3 <- file.path(ROOT, "results", "R3_GSE249696")
LOGD <- file.path(ROOT, "logs")
dir.create(LOGD, recursive=TRUE, showWarnings=FALSE)

B_GATE <- file.path(R3, "R3_STEP4B_V1_7_STRUCTURAL_PREFLIGHT_TERMINAL_FROZEN.txt")

C11_GATE <- file.path(R3, "R3_STEP4C_V1_1_ANNOTATION_RELATIONSHIP_DISCOVERY_FROZEN.txt")
C11_AUD <- file.path(R3, "R3_STEP4C_V1_1_annotation_relationship_audit.csv")
C11_VALUES <- file.path(R3, "R3_STEP4C_V1_1_annotation_value_counts.csv")
C11_CROSS <- file.path(R3, "R3_STEP4C_V1_1_annotation_pairwise_crosswalk.csv")
C11_SUM <- file.path(R3, "R3_STEP4C_V1_1_annotation_relationship_summary.csv")

OUT_AUD <- file.path(R3, "R3_STEP4C_V1_2_final_annotation_authority_audit.csv")
OUT_CONTRACT <- file.path(R3, "R3_STEP4C_V1_2_final_annotation_authority_contract.csv")
OUT_LABELS <- file.path(R3, "R3_STEP4C_V1_2_frozen_annotation_labels.csv")
OUT_EXTERNAL <- file.path(R3, "R3_STEP4C_V1_2_external_method_authority.csv")
OUT_PASS <- file.path(R3, "R3_STEP4C_V1_2_ANNOTATION_AUTHORITY_TERMINAL_FROZEN.txt")
OUT_HOLD <- file.path(R3, "R3_STEP4C_V1_2_ANNOTATION_AUTHORITY_TERMINAL_HOLD.txt")
LOG <- file.path(LOGD, "R3_STEP4C_V1_2_ANNOTATION_AUTHORITY_TERMINAL_FREEZE.log")

if (file.exists(LOG)) {
  old <- file.path(
    LOGD,
    paste0(
      "R3_STEP4C_V1_2_ANNOTATION_AUTHORITY_TERMINAL_FREEZE_",
      format(Sys.time(), "%Y%m%d_%H%M%S"),
      "_previous.log"
    )
  )
  file.rename(LOG, old)
}

logline <- function(...) {
  z <- paste0(
    format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    " | ", paste0(..., collapse="")
  )
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
hold <- function(reason, code=421L) {
  flush_audit()
  twrite(c(
    "R3_STEP4C_V1_2_ANNOTATION_AUTHORITY_TERMINAL_HOLD",
    paste0("timestamp=", format(Sys.time(), "%Y-%m-%d %H:%M:%S %z")),
    paste0("reason=", reason),
    "RDS_loaded=NO",
    "expression_values_used=NO",
    "annotation_relabeling_executed=NO",
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
  try(logline("[UNHANDLED_R_ERROR] ", gsub("[\r\n]+"," | ",msg)), silent=TRUE)
  try(flush_audit(), silent=TRUE)
  try(twrite(c(
    "R3_STEP4C_V1_2_ANNOTATION_AUTHORITY_TERMINAL_HOLD_RUNTIME_ERROR",
    paste0("error=", gsub("[\r\n]+"," | ",msg)),
    "automatic_rerun_allowed=NO"
  ), OUT_HOLD), silent=TRUE)
  q(save="no", status=422, runLast=FALSE)
})

parse_kv <- function(p) {
  z <- readLines(p, warn=FALSE, encoding="UTF-8")
  z <- z[nzchar(trimws(z)) & grepl("=", z, fixed=TRUE)]
  v <- sub("^[^=]*=", "", z)
  names(v) <- sub("=.*$", "", z)
  v
}
get_labels <- function(vdf, dataset, field) {
  sort(as.character(vdf$value[
    vdf$dataset==dataset & vdf$field==field
  ]))
}

logline("============================================================")
logline("R3 Step4C V1.2 final annotation authority adjudication")
logline("NO RDS LOAD / NO EXPRESSION USE")
logline("============================================================")

needed <- c(
  B_GATE,
  C11_GATE, C11_AUD, C11_VALUES, C11_CROSS, C11_SUM
)
for (p in needed) {
  ok <- file.exists(p)
  add(
    paste0("file_exists:", basename(p)),
    "YES",
    if (ok) "YES" else "NO",
    if (ok) "PASS" else "FAIL"
  )
}
if (any(!file.exists(needed)))
  hold("MISSING_REQUIRED_FROZEN_LINEAGE_INPUT", 423L)

# --------------------------------------------------------------------------
# Upstream Step4B terminal gate.
# --------------------------------------------------------------------------
bg <- parse_kv(B_GATE)
req_b <- c(
  Step4B_V1_7_status="STRUCTURAL_PREFLIGHT_TERMINAL_FROZEN",
  GSE345646_cells="61398",
  GSE345646_assay="RNA",
  GSE345643_cells="568651",
  GSE345643_assay="Xenium",
  GSE345643_measured_features="477",
  primary_localization_programs="7",
  program_reclassification="NO"
)
for (k in names(req_b)) {
  obs <- if (k %in% names(bg)) unname(bg[[k]]) else "<MISSING>"
  exp <- unname(req_b[[k]])
  add(
    paste0("Step4B invariant:", k),
    exp, obs,
    if (identical(obs, exp)) "PASS" else "FAIL"
  )
}

# --------------------------------------------------------------------------
# Historical V1.0 failed strict-hierarchy producer is provenance only.
# --------------------------------------------------------------------------
add("Historical Step4C V1.0 HOLD replayed","NO","NO","PASS",
    "Final annotation adjudication starts from Gate9G canonical Step4B and clean Step4C V1.1 structural discovery.")

# --------------------------------------------------------------------------
# V1.1 clean structural discovery.
# --------------------------------------------------------------------------
g11 <- readLines(C11_GATE, warn=FALSE, encoding="UTF-8")
gate11 <- length(g11)>0L &&
  trimws(g11[1])=="R3_STEP4C_V1_1_ANNOTATION_RELATIONSHIP_DISCOVERY_FROZEN"
add(
  "Step4C V1.1 gate identity",
  "R3_STEP4C_V1_1_ANNOTATION_RELATIONSHIP_DISCOVERY_FROZEN",
  if (length(g11)) trimws(g11[1]) else "<EMPTY>",
  if (gate11) "PASS" else "FAIL"
)

a11 <- read.csv(C11_AUD, stringsAsFactors=FALSE, check.names=FALSE)
# Clean Step4C V1.1 deliberately removed five historical V1.0 replay/lineage checks.
# Its accepted cold-start audit cardinality is therefore 21 PASS + 4 INFO + 0 FAIL.
p11 <- sum(a11$status=="PASS",na.rm=TRUE)
i11 <- sum(a11$status=="INFO",na.rm=TRUE)
f11 <- sum(a11$status=="FAIL",na.rm=TRUE)
add(
  "Step4C V1.1 audit status",
  "21_PASS_4_INFO_0_FAIL",
  paste0(p11,"_PASS_",i11,"_INFO_",f11,"_FAIL"),
  if (p11==21L && i11==4L && f11==0L) "PASS" else "FAIL"
)

if (any(vapply(A,function(x)any(x$status=="FAIL"),logical(1))))
  hold("UPSTREAM_LINEAGE_GUARD_FAILURE",424L)

# --------------------------------------------------------------------------
# Exact relationship structure.
# --------------------------------------------------------------------------
s <- read.csv(C11_SUM, stringsAsFactors=FALSE, check.names=FALSE)
expected_rel <- data.frame(
  dataset=c(
    "GSE345643_Xenium_ambient_corrected",
    "GSE345646_snRNA",
    "GSE345646_snRNA",
    "GSE345646_snRNA"
  ),
  field_a=c(
    "cell_type_rctd_doublet",
    "Names","Names","Subnames"
  ),
  field_b=c(
    "cell_type_seurat",
    "Subnames","Subnames_manual","Subnames_manual"
  ),
  n_field_a_labels=c(12L,12L,12L,37L),
  n_field_b_labels=c(34L,37L,34L,34L),
  field_a_labels_mapping_to_multiple_b=c(12L,6L,6L,3L),
  field_b_labels_mapping_to_multiple_a=c(33L,5L,5L,21L),
  stringsAsFactors=FALSE
)

ss <- merge(
  expected_rel,
  s[,c(
    "dataset","field_a","field_b",
    "n_field_a_labels","n_field_b_labels",
    "field_a_labels_mapping_to_multiple_b",
    "field_b_labels_mapping_to_multiple_a",
    "strict_a_to_b_function","strict_b_to_a_function"
  )],
  by=c("dataset","field_a","field_b"),
  suffixes=c("_expected","_observed"),
  all.x=TRUE
)

rel_ok <- (
  nrow(ss)==4L &&
  all(ss$n_field_a_labels_expected==ss$n_field_a_labels_observed) &&
  all(ss$n_field_b_labels_expected==ss$n_field_b_labels_observed) &&
  all(
    ss$field_a_labels_mapping_to_multiple_b_expected ==
    ss$field_a_labels_mapping_to_multiple_b_observed
  ) &&
  all(
    ss$field_b_labels_mapping_to_multiple_a_expected ==
    ss$field_b_labels_mapping_to_multiple_a_observed
  ) &&
  all(ss$strict_a_to_b_function==FALSE) &&
  all(ss$strict_b_to_a_function==FALSE)
)
add(
  "four annotation relationships",
  "EXACT_NON_HIERARCHICAL_STRUCTURE_REPRODUCED",
  if (rel_ok) "EXACT_NON_HIERARCHICAL_STRUCTURE_REPRODUCED" else "MISMATCH",
  if (rel_ok) "PASS" else "FAIL"
)
if (!rel_ok)
  hold("ANNOTATION_RELATIONSHIP_STRUCTURE_DRIFT",425L)

# --------------------------------------------------------------------------
# Exact label universes.
# --------------------------------------------------------------------------
v <- read.csv(C11_VALUES, stringsAsFactors=FALSE, check.names=FALSE)

sn_names_exp <- sort(c(
  "Adipo","CM","EC","Endo","Epi","FB","LEC","Myeloid",
  "NKT","Neuron","PC","SM"
))
sn_manual_exp <- sort(c(
  "Adipo","CCR2- Resident Mac","CM_Baseline","CM_BetaMHC","CM_HAND2",
  "CM_HMGCS2","CM_HTR4","CM_KCNJ3","CM_MYH6","CM_NPP","CM_RORA","CM_XIRP",
  "Dendritic Cell","EC_Arterial","EC_Capillary","EC_Endocardial","EC_Lymph",
  "EC_Venous","Epi","Fb_Adventitial","Fb_Anti-fibrotic","Fb_Elastogenic",
  "Fb_Interstitial","Fb_Pro-fibrotic","Fb_Resident","Fb_Stressed",
  "Mac_Inflammatory","Monocyte / Mac_Mono_Derived","NK_T","Neuron","PC",
  "Proliferating","SM","TREM2+ Mac"
))
sn_sub_exp <- sort(c(
  sn_manual_exp,
  "CM_unc","EC_unc","Myeloid_unc"
))
xe_rctd_exp <- sn_names_exp
xe_seurat_exp <- sort(c(
  "Adipo","CCR2+ rMac","CCR2- rMac1","CCR2- rMac2",
  "Cm1","Cm2","Cm3","Cm4","Cm5","Cm6","Cm7","Cm8","Cm9",
  "DCs","EC_Arterial","EC_Capillary","EC_Endocardial","EC_Lymph",
  "EC_Venous","Epi","Fb1","Fb2","Fb3","Fb4","Fb5","Fb6","Fb7",
  "Mono","NK_T","Neuron","PC","SM","TREM2 Mac","iMac"
))

actual <- list(
  sn_names=get_labels(v,"GSE345646_snRNA","Names"),
  sn_manual=get_labels(v,"GSE345646_snRNA","Subnames_manual"),
  sn_sub=get_labels(v,"GSE345646_snRNA","Subnames"),
  xe_rctd=get_labels(
    v,"GSE345643_Xenium_ambient_corrected","cell_type_rctd_doublet"),
  xe_seurat=get_labels(
    v,"GSE345643_Xenium_ambient_corrected","cell_type_seurat")
)
expected <- list(
  sn_names=sn_names_exp,
  sn_manual=sn_manual_exp,
  sn_sub=sn_sub_exp,
  xe_rctd=xe_rctd_exp,
  xe_seurat=xe_seurat_exp
)

for (nm in names(expected)) {
  ok <- identical(actual[[nm]], expected[[nm]])
  add(
    paste0("label universe:",nm),
    paste(expected[[nm]],collapse=";"),
    paste(actual[[nm]],collapse=";"),
    if (ok) "PASS" else "FAIL"
  )
}

broad_exact <- identical(actual$sn_names, actual$xe_rctd)
add(
  "cross-modal broad 12-label universe",
  "EXACT_MATCH",
  if (broad_exact) "EXACT_MATCH" else "MISMATCH",
  if (broad_exact) "PASS" else "FAIL",
  "This is the only primary label space harmonized across snRNA and Xenium."
)

if (any(vapply(A,function(x)any(x$status=="FAIL"),logical(1))))
  hold("ANNOTATION_LABEL_UNIVERSE_DRIFT",426L)

# --------------------------------------------------------------------------
# Frozen final authority contract.
# --------------------------------------------------------------------------
contract <- data.frame(
  dataset=c(
    rep("GSE345646_snRNA",7),
    rep("GSE345643_Xenium_ambient_corrected",8),
    rep("CROSS_MODAL",4),
    rep("GLOBAL",6)
  ),
  authority_role=c(
    "DISEASE_STATE",
    "INFERENTIAL_SUBJECT",
    "PRIMARY_BROAD_ANNOTATION",
    "FINE_ANNOTATION",
    "INTERMEDIATE_ANNOTATION",
    "BROAD_FINE_RELATIONSHIP",
    "INDEPENDENT_VALIDATION_ROLE",
    "DISEASE_STATE",
    "INFERENTIAL_SUBJECT",
    "PRIMARY_SPATIAL_ANNOTATION",
    "SECONDARY_FINE_SPATIAL_ANNOTATION",
    "BROAD_FINE_RELATIONSHIP",
    "MEASURED_PANEL_SCOPE",
    "IMPUTATION_ROLE",
    "INDEPENDENT_VALIDATION_ROLE",
    "PRIMARY_HARMONIZED_LABEL_SPACE",
    "FINE_LABEL_HARMONIZATION",
    "PRIMARY_COMPARISON_SCOPE",
    "FINE_COMPARISON_SCOPE",
    "INFERENTIAL_REPLICATE",
    "CELL_LEVEL_PSEUDOREPLICATION",
    "ANNOTATION_RELABELING",
    "PROGRAM_CLASS_REDEFINITION",
    "XENIUM_CROSS_PROGRAM_SCORE_MAGNITUDE_COMPARISON",
    "LOCALIZATION_ROLE"
  ),
  field_or_value=c(
    "group",
    "patient",
    "Names",
    "Subnames_manual",
    "Subnames",
    "INDEPENDENT_VIEWS_NOT_STRICT_PARENT_CHILD",
    "NO_SAME_MULTIMODAL_ATLAS_LOCALIZATION_SUPPORT",
    "group",
    "patient",
    "cell_type_rctd_doublet",
    "cell_type_seurat",
    "INDEPENDENT_VIEWS_NOT_STRICT_PARENT_CHILD",
    "477_MEASURED_GENES",
    "NO_IMPUTATION_TO_EXPAND_PRIMARY_EVIDENCE",
    "NO_SAME_MULTIMODAL_ATLAS_LOCALIZATION_SUPPORT",
    "12_SHARED_BROAD_LABELS",
    "NONE_NO_MANUAL_FINE_LABEL_CROSSWALK",
    "BROAD_LINEAGE_LOCALIZATION",
    "WITHIN_DATASET_SECONDARY_CONTEXT_ONLY",
    "PATIENT",
    "PROHIBITED",
    "PROHIBITED",
    "PROHIBITED",
    "PROHIBITED",
    "SUPPORTIVE_INTERPRETIVE_ONLY"
  ),
  frozen_use=c(
    "NF_pRV_RVF",
    "PATIENT_LEVEL_INFERENCE",
    "PRIMARY_SNRNA_LINEAGE_LOCALIZATION_12_LABELS",
    "SECONDARY_FINE_SNRNA_LOCALIZATION_34_OBJECT_NATIVE_LABELS",
    "CONTEXT_ONLY_37_LEVEL_FIELD_INCLUDING_UNC_LABELS",
    "DO_NOT_FORCE_FINE_LABELS_TO_NEST_WITHIN_NAMES",
    "NOT_INDEPENDENT_ETIOLOGIC_REPLICATION",
    "NF_pRV_RVF",
    "PATIENT_LEVEL_INFERENCE",
    "PRIMARY_XENIUM_CELL_TYPE_LOCALIZATION_12_RCTD_LABELS",
    "SECONDARY_FINE_SPATIAL_CONTEXT_34_OBJECT_NATIVE_LABELS",
    "DO_NOT_FORCE_SEURAT_FINE_LABELS_TO_NEST_WITHIN_RCTD_LABELS",
    "PANEL_RESTRICTED_SPATIAL_SUPPORT_ONLY",
    "SPA_GE_OR_OTHER_IMPUTED_GENES_CANNOT_ENTER_PRIMARY_SPATIAL_PROGRAM_EVIDENCE",
    "NOT_INDEPENDENT_ETIOLOGIC_REPLICATION",
    "Names_IN_SNRNA_MATCHED_TO_cell_type_rctd_doublet_IN_XENIUM",
    "DO_NOT_MANUALLY_RENAME_OR_MAP_34_LEVEL_LABELS_ACROSS_MODALITIES",
    "PRIMARY_CROSS_MODAL_LOCALIZATION_AT_12_BROAD_LABEL_LEVEL",
    "NO_PRIMARY_CROSS_MODAL_FINE_SUBTYPE_CLAIM",
    "PATIENT_NOT_CELL",
    "NO_CELL_AS_REPLICATE_P_OR_FDR",
    "NO_OUTCOME_DRIVEN_REMAP",
    "LOCALIZATION_CANNOT_CHANGE_STEP3F_CLASS",
    "NO_DUE_TO_DIFFERENTIAL_477_GENE_PROGRAM_COVERAGE",
    "CELLULAR_AND_SPATIAL_LOCALIZATION_SUPPORT"
  ),
  stringsAsFactors=FALSE
)
awrite(contract, OUT_CONTRACT)

# Exact labels in long-form frozen table.
label_rows <- list()
kk <- 0L
add_label_set <- function(dataset, field, role, labels) {
  for (lab in labels) {
    kk <<- kk + 1L
    label_rows[[kk]] <<- data.frame(
      dataset=dataset,
      field=field,
      role=role,
      label=lab,
      stringsAsFactors=FALSE
    )
  }
}
add_label_set(
  "GSE345646_snRNA","Names",
  "PRIMARY_BROAD_ANNOTATION",actual$sn_names)
add_label_set(
  "GSE345646_snRNA","Subnames_manual",
  "FINE_ANNOTATION_INDEPENDENT_OF_NAMES",actual$sn_manual)
add_label_set(
  "GSE345646_snRNA","Subnames",
  "INTERMEDIATE_CONTEXT_ONLY",actual$sn_sub)
add_label_set(
  "GSE345643_Xenium_ambient_corrected","cell_type_rctd_doublet",
  "PRIMARY_SPATIAL_ANNOTATION",actual$xe_rctd)
add_label_set(
  "GSE345643_Xenium_ambient_corrected","cell_type_seurat",
  "SECONDARY_FINE_SPATIAL_CONTEXT_INDEPENDENT_OF_RCTD",actual$xe_seurat)

labels_out <- do.call(rbind, label_rows)
awrite(labels_out, OUT_LABELS)

external <- data.frame(
  source=c(
    "NCBI_GEO_GSE345643",
    "NCBI_GEO_GSM10012170"
  ),
  authority_type=c(
    "SERIES_DESIGN_AND_MATRIX_ROLE",
    "OFFICIAL_XENIUM_DATA_PROCESSING_METHOD"
  ),
  frozen_statement=c(
    paste0(
      "Nine RV sections; one per patient; 3 NF, 3 pRV, 3 RVF; ",
      "477-gene panel; ambient-corrected 568651-cell matrix is the ",
      "processed spatial-analysis matrix; SpaGE-imputed genes are not deposited."
    ),
    paste0(
      "Cells were resegmented with Proseg; cell types were assigned by RCTD ",
      "against the matched snRNA-seq reference with SPLIT correction."
    )
  ),
  adjudication_use=c(
    "SUPPORTS_PATIENT_SECTION_UNIT_AND_PANEL_RESTRICTED_PRIMARY_SPATIAL_EVIDENCE",
    "SUPPORTS_cell_type_rctd_doublet_AS_PRIMARY_XENIUM_CELL_TYPE_AUTHORITY"
  ),
  stringsAsFactors=FALSE
)
awrite(external, OUT_EXTERNAL)

add("strict parent-child hierarchy assumed","NO","NO","PASS")
add("snRNA primary broad field","Names","Names","PASS")
add("snRNA fine field","Subnames_manual","Subnames_manual","PASS")
add("snRNA Subnames role","CONTEXT_ONLY","CONTEXT_ONLY","PASS")
add("Xenium primary spatial annotation",
    "cell_type_rctd_doublet","cell_type_rctd_doublet","PASS")
add("Xenium secondary fine annotation",
    "cell_type_seurat","cell_type_seurat","PASS")
add("fine-label cross-modal manual harmonization","NO","NO","PASS")
add("primary cross-modal label space","12_SHARED_BROAD_LABELS",
    "12_SHARED_BROAD_LABELS","PASS")
add("inferential replicate","PATIENT","PATIENT","PASS")
add("cell-level P/FDR allowed","NO","NO","PASS")
add("Xenium imputation to expand primary evidence","NO","NO","PASS")
add("localization can redefine Step3F class","NO","NO","PASS")
add("RDS loaded in V1.2","NO","NO","PASS")
add("expression values used in V1.2","NO","NO","PASS")
add("module scoring executed","NO","NO","PASS")
add("disease-group testing executed","NO","NO","PASS")
add("program reclassification","NO","NO","PASS")

if (any(vapply(A,function(x)any(x$status=="FAIL"),logical(1))))
  hold("FINAL_ANNOTATION_AUTHORITY_ACCOUNTING_FAILURE",427L)

flush_audit()

twrite(c(
  "R3_STEP4C_V1_2_ANNOTATION_AUTHORITY_TERMINAL_FROZEN",
  paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
  "upstream_Step4B=FINAL_CLOSED",
  "Step4C_V1_0=CLEAN_HOLD_BEFORE_LOCALIZATION_RESULTS",
  "Step4C_V1_1=CLEAN_ANNOTATION_RELATIONSHIP_DISCOVERY",
  "Step4C_V1_2=FINAL_ANNOTATION_AUTHORITY_ADJUDICATION",
  "strict_parent_child_hierarchy_assumed=NO",
  "snRNA_primary_broad_annotation=Names",
  "snRNA_primary_broad_labels=12",
  "snRNA_fine_annotation=Subnames_manual",
  "snRNA_fine_labels=34",
  "snRNA_fine_relation_to_Names=INDEPENDENT_VIEW_NOT_STRICT_CHILD",
  "snRNA_Subnames_role=INTERMEDIATE_CONTEXT_ONLY",
  "Xenium_primary_spatial_annotation=cell_type_rctd_doublet",
  "Xenium_primary_spatial_labels=12",
  "Xenium_primary_annotation_method=RCTD_AGAINST_MATCHED_SNRNA_REFERENCE_WITH_SPLIT_CORRECTION",
  "Xenium_secondary_fine_annotation=cell_type_seurat",
  "Xenium_secondary_fine_labels=34",
  "Xenium_fine_relation_to_RCTD=INDEPENDENT_VIEW_NOT_STRICT_CHILD",
  "cross_modal_primary_label_space=12_SHARED_BROAD_LABELS",
  "cross_modal_primary_broad_label_sets_exact_match=YES",
  "cross_modal_fine_label_manual_harmonization=NO",
  "primary_cross_modal_fine_subtype_claim_allowed=NO",
  "inferential_replicate=PATIENT",
  "cell_level_pseudoreplication_allowed=NO",
  "Xenium_measured_panel_genes=477",
  "Xenium_primary_spatial_evidence_role=PANEL_RESTRICTED_SPATIAL_SUPPORT_ONLY",
  "Xenium_imputation_to_expand_primary_evidence_allowed=NO",
  "localization_is_independent_etiologic_validation=NO",
  "localization_can_redefine_Step3F_program_class=NO",
  "RDS_loaded=NO",
  "expression_values_used=NO",
  "module_scoring_executed=NO",
  "disease_group_testing_executed=NO",
  "program_reclassification=NO",
  "Step4C_status=FINAL_CLOSED",
  "next_stage=R3_STEP4D_LOCALIZATION_ANALYSIS_CONTRACT_FREEZE_BEFORE_ANY_LOCALIZATION_RESULTS"
), OUT_PASS)

if (file.exists(OUT_HOLD)) unlink(OUT_HOLD, force=TRUE)
logline("FINAL_GATE: R3_STEP4C_V1_2_ANNOTATION_AUTHORITY_TERMINAL_FROZEN")
quit(save="no", status=0, runLast=FALSE)
