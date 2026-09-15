# ---- RV PUBLIC REPRODUCIBILITY PORTABILITY OVERLAY V1.0 ----
.RV_PROJECT_ROOT_ENV <- Sys.getenv('RV_PROJECT_ROOT', unset='')
RV_PROJECT_ROOT <- if (nzchar(.RV_PROJECT_ROOT_ENV)) {
  normalizePath(.RV_PROJECT_ROOT_ENV, winslash='/', mustWork=TRUE)
} else {
  normalizePath(getwd(), winslash='/', mustWork=TRUE)
}
# This overlay changes path binding only; scientific/statistical semantics remain historical authority.

source(file.path(RV_PROJECT_ROOT, 'code', 'lib', 'rv_runtime_helpers.R'))


# R3 Step4D V1.4
# snRNA SOURCE-SEMANTICS VERSION-FORWARD CORRECTION / FREEZE
#
# Trigger:
#   Step4F V1.0 added an unauthorized integer-only guard and stopped on
#   fractional RNA/counts values before any scientific localization test.
#   Step4F-PRE1 independently characterized the exact frozen snRV_ref.rds:
#     - RNA/counts is nonnegative and finite
#     - 98.027233% of stored nonzero values are fractional
#     - colSums(RNA/counts) == metadata nCount_RNA for 61,398 / 61,398 nuclei
#     - the object contains only the RNA assay (counts/data/scale.data)
#
# Purpose:
#   Correct ONLY the inaccurate old wording "RNA_RAW_COUNTS / unmodified raw UMI".
#   Freeze the effective semantics of the already-selected RNA/counts layer.
#
# ZERO-RESULT GATE:
#   - NO RDS read
#   - NO expression read
#   - NO pseudobulk
#   - NO filterByExpr / TMM / voom / mroast
#   - NO P value / BH / localization classification
#
# The original Step4D scientific contract and V1.3 implementation artifacts
# remain byte-immutable provenance. V1.4 is a version-forward overlay with
# precedence ONLY for the explicitly enumerated snRNA source-semantics fields.

options(stringsAsFactors = FALSE, warn = 1)

ROOT <- RV_PROJECT_ROOT
RES <- file.path(ROOT, "results", "R3_GSE249696")
UPLOAD <- file.path(ROOT, "upload")
RUNROOT <- file.path(RES, "R3_STEP4D_V1_4_runs")

PRE1_RUN_ID <- basename(rv_resolve_stage_run(file.path(RES, "R3_STEP4F_PRE1_runs")))
PRE1 <- file.path(RES, "R3_STEP4F_PRE1_runs", PRE1_RUN_ID)
V13 <- rv_resolve_stage_run(file.path(RES, "R3_STEP4D_V1_3_runs"))

P_PRE1_STATUS <- file.path(PRE1, "R3_STEP4F_PRE1_STATUS.txt")
P_PRE1_AUDIT <- file.path(PRE1, "R3_STEP4F_PRE1_audit.csv")
P_PRE1_VALUES <- file.path(PRE1, "R3_STEP4F_PRE1_value_semantics.csv")
P_PRE1_NCOUNT <- file.path(PRE1, "R3_STEP4F_PRE1_RNA_counts_metadata_concordance.csv")
P_PRE1_INVENTORY <- file.path(PRE1, "R3_STEP4F_PRE1_assay_layer_inventory.csv")
P_PRE1_NOTE <- file.path(PRE1, "R3_STEP4F_PRE1_ADJUDICATION_NOTE.txt")

P_METHOD <- file.path(RES, "R3_STEP4D_localization_method_contract.csv")
P_TIER <- file.path(RES, "R3_STEP4D_program_modality_tier_contract.csv")
P_FDR <- file.path(RES, "R3_STEP4D_fixed_FDR_family_contract.csv")
P_CLASS <- file.path(RES, "R3_STEP4D_localization_classification_contract.csv")
P_REGISTRY <- file.path(V13, "R3_STEP4D_V1_3_DETERMINISTIC_TEST_REGISTRY.csv")
P_GUARDS <- file.path(V13, "R3_STEP4D_V1_3_STEP4F_FAIL_CLOSED_GUARDS.csv")

P_PREHASH <- Sys.getenv("R3_STEP4D_V14_PREHASH", unset = "")
P_PUBLIC_ID <- Sys.getenv("R3_STEP4D_V14_PUBLIC_ID", unset = "")
if (!nzchar(P_PREHASH) || !nzchar(P_PUBLIC_ID)) {
  stop("Run through the Step4D V1.4 BAT; identity-ledger environment variables are missing.", call. = FALSE)
}

args <- commandArgs(trailingOnly = TRUE)
RUN_ID <- if (length(args) >= 1L && nzchar(args[1L])) args[1L] else format(Sys.time(), "%Y%m%d_%H%M%S")

RUNDIR <- file.path(RUNROOT, RUN_ID)
STAGING <- file.path(UPLOAD, "R3_STEP4D_V1_4_STAGING")
dir.create(RUNDIR, recursive = TRUE, showWarnings = FALSE)
dir.create(UPLOAD, recursive = TRUE, showWarnings = FALSE)
if (dir.exists(STAGING)) unlink(STAGING, recursive = TRUE, force = TRUE)
dir.create(STAGING, recursive = TRUE, showWarnings = FALSE)

P_STATUS <- file.path(RUNDIR, "R3_STEP4D_V1_4_STATUS.txt")
P_AUDIT <- file.path(RUNDIR, "R3_STEP4D_V1_4_audit.csv")
P_DELTA <- file.path(RUNDIR, "R3_STEP4D_V1_4_EFFECTIVE_METHOD_DELTA.csv")
P_OVERLAY <- file.path(RUNDIR, "R3_STEP4D_V1_4_SNRNA_SOURCE_SEMANTICS_OVERLAY.csv")
P_EVIDENCE <- file.path(RUNDIR, "R3_STEP4D_V1_4_EVIDENCE_LEDGER.csv")
P_PRECEDENCE <- file.path(RUNDIR, "R3_STEP4D_V1_4_AUTHORITY_PRECEDENCE.txt")
P_SCOPE_REPAIR <- file.path(RUNDIR, "R3_STEP4F_V1_1_IMPLEMENTATION_REPAIR_CONTRACT.csv")
P_NOTE <- file.path(RUNDIR, "R3_STEP4D_V1_4_FREEZE_NOTE.txt")

audit <- data.frame(check_id=character(), status=character(), detail=character(), stringsAsFactors=FALSE)
add <- function(id, status, detail) {
  audit <<- rbind(audit, data.frame(check_id=id, status=status, detail=as.character(detail), stringsAsFactors=FALSE))
  cat(sprintf("[%s] %s :: %s\n", status, id, detail))
}
PASS <- function(id, detail) add(id, "PASS", detail)
HOLD <- function(id, detail) {
  add(id, "FAIL", detail)
  stop(paste0("HOLD: ", detail), call. = FALSE)
}
write_csv <- function(x,p) write.csv(x,p,row.names=FALSE,na="",fileEncoding="UTF-8")

copy_stage <- function(paths) {
  for (p in unique(paths[file.exists(paths)])) {
    ok <- file.copy(p, file.path(STAGING, basename(p)), overwrite=TRUE, copy.mode=TRUE, copy.date=TRUE)
    if (!isTRUE(ok)) stop(paste("Could not stage:", p), call.=FALSE)
  }
}

final_state <- "HOLD_STEP4D_V1_4_SNRNA_SOURCE_SEMANTICS_FREEZE"

finalize <- function() {
  try(write_csv(audit, P_AUDIT), silent=TRUE)
  try(writeLines(c(
    paste0("RUN_ID=", RUN_ID),
    paste0("FINAL_STATE=", final_state),
    "ORIGINAL_STEP4D_CONTRACT_BYTES_MODIFIED=NO",
    "STEP4D_V1_3_BYTES_MODIFIED=NO",
    "PRECEDENCE_SCOPE=SNRNA_SOURCE_SEMANTICS_ONLY",
    "FROZEN_840_TEST_REGISTRY_CHANGED=NO",
    "FROZEN_8_FDR_FAMILIES_CHANGED=NO",
    "FROZEN_7_PROGRAMS_CHANGED=NO",
    "FROZEN_ANNOTATIONS_CHANGED=NO",
    "FROZEN_CONTRASTS_CHANGED=NO",
    "FROZEN_PATIENT_REPLICATE_RULE_CHANGED=NO",
    "FROZEN_FILTERBYEXPR_TMM_VOOM_MROAST_CHANGED=NO",
    "SNRNA_ROUNDING_ADDED=NO",
    "INTEGER_ONLY_GUARD_EFFECTIVE=NO",
    "REAL_RDS_READ=NO",
    "REAL_EXPRESSION_READ=NO",
    "SCIENTIFIC_LOCALIZATION_RESULT=NO"
  ), P_STATUS, useBytes=TRUE), silent=TRUE)

  try(copy_stage(c(
    P_PREHASH, P_PUBLIC_ID, P_STATUS, P_AUDIT, P_DELTA, P_OVERLAY,
    P_EVIDENCE, P_PRECEDENCE, P_SCOPE_REPAIR, P_NOTE,
    P_PRE1_STATUS, P_PRE1_AUDIT, P_PRE1_VALUES, P_PRE1_NCOUNT,
    P_PRE1_INVENTORY, P_PRE1_NOTE, P_METHOD, P_TIER, P_FDR, P_CLASS,
    P_REGISTRY, P_GUARDS
  )), silent=TRUE)
}
on.exit(finalize(), add=TRUE)

read_csv_req <- function(p,id) {
  if(!file.exists(p)) HOLD(id,paste("Missing:",p))
  if(file.info(p)$size<=0) HOLD(id,paste("Zero-byte:",p))
  x <- tryCatch(read.csv(p,check.names=FALSE,stringsAsFactors=FALSE),error=function(e)NULL)
  if(is.null(x)) HOLD(id,paste("Could not read:",p))
  x
}

main <- function() {
  # 1. Exact local artifact identity.
  ph <- read_csv_req(P_PREHASH, "PREHASH_READ")
  if(!all(c("role","path","expected_sha256","actual_sha256","sha_match") %in% names(ph))) {
    HOLD("PREHASH_COLUMNS","Prehash schema incomplete")
  }
  if(!all(tolower(as.character(ph$sha_match))=="true")) {
    HOLD("PREHASH_EXACT",paste("Mismatch:",paste(ph$role[tolower(as.character(ph$sha_match))!="true"],collapse=" | ")))
  }
  PASS("PREHASH_EXACT",paste(nrow(ph),"/",nrow(ph),"frozen artifact SHA256 identities exact"))

  pub <- read_csv_req(P_PUBLIC_ID, "PUBLIC_ID_READ")
  if(nrow(pub)!=1L ||
     tolower(as.character(pub$local_md5))!="b13511f74a7abbebecb40ddd0cc04f32" ||
     !isTRUE(as.logical(pub$zenodo_md5_match))) {
    HOLD("ZENODO_PUBLIC_IDENTITY","Local snRNA RDS MD5 does not match public Zenodo shared__snRV_ref.rds")
  }
  PASS("ZENODO_PUBLIC_IDENTITY","Local frozen snRNA RDS MD5 exact-match to Zenodo shared__snRV_ref.rds")

  # 2. Bind PRE1 exact zero-result characterization.
  st <- readLines(P_PRE1_STATUS,warn=FALSE,encoding="UTF-8")
  run_lines <- grep("^RUN_ID=",st,value=TRUE)
  req_status <- c(
    "FINAL_STATE=PASS_STEP4F_PRE1_SNRNA_COUNT_LAYER_CHARACTERIZATION_READY_FOR_INDEPENDENT_ADJUDICATION",
    "PATIENT_X_ANNOTATION_PSEUDOBULK=NO",
    "MROAST=NO",
    "P_VALUE=NO",
    "BH_FDR=NO",
    "SCIENTIFIC_LOCALIZATION_RESULT=NO"
  )
  if(length(run_lines)!=1L ||
     !nzchar(sub("^RUN_ID=","",run_lines[1L])) ||
     !all(req_status %in% st)) {
    HOLD("PRE1_STATUS","Current cold-start PRE1 zero-result status sentinels mismatch")
  }

  pa <- read_csv_req(P_PRE1_AUDIT,"PRE1_AUDIT_READ")
  if(nrow(pa)!=10L || any(pa$status=="FAIL")) {
    HOLD("PRE1_AUDIT","PRE1 audit not exact 10 rows with no FAIL")
  }

  vals <- read_csv_req(P_PRE1_VALUES,"PRE1_VALUES_READ")
  rc <- vals[vals$assay=="RNA" & vals$layer=="counts",,drop=FALSE]
  if(nrow(rc)!=1L) HOLD("PRE1_RNA_COUNTS_ROW","RNA/counts characterization row not unique")

  expected_fractional <- 175268242
  expected_stored <- 178795460
  expected_frac_prop <- 0.980272329062494

  if(as.numeric(rc$stored_value_count)!=expected_stored ||
     as.numeric(rc$fractional_stored_values_tol_1e_8)!=expected_fractional ||
     abs(as.numeric(rc$fractional_fraction_of_finite_stored)-expected_frac_prop)>1e-15 ||
     as.numeric(rc$nonfinite_stored_values)!=0 ||
     as.numeric(rc$negative_stored_values)!=0) {
    HOLD("PRE1_NUMERIC_IDENTITY","PRE1 RNA/counts numeric characterization differs from independently audited values")
  }

  nc <- read_csv_req(P_PRE1_NCOUNT,"PRE1_NCOUNT_READ")
  if(nrow(nc)!=1L || as.integer(nc$n_cells)!=61398L ||
     as.numeric(nc$match_fraction)!=1 ||
     as.numeric(nc$max_abs_difference)!=0 ||
     as.numeric(nc$pearson_correlation)!=1) {
    HOLD("PRE1_NCOUNT_IDENTITY","RNA/counts colSum vs nCount_RNA exact identity failed")
  }

  inv <- read_csv_req(P_PRE1_INVENTORY,"PRE1_INVENTORY_READ")
  if(nrow(inv)!=3L ||
     !identical(as.character(inv$assay),rep("RNA",3L)) ||
     !setequal(as.character(inv$layer),c("counts","data","scale.data"))) {
    HOLD("PRE1_ASSAY_IDENTITY","Expected exact RNA-only Assay5 with counts/data/scale.data")
  }

  PASS("PRE1_CHARACTERIZATION","Fractional nonnegative finite RNA/counts + exact nCount_RNA identity + RNA-only assay structure bound")

  # 3. Bind old contract wording and prove integer-only guard was never frozen.
  method <- read_csv_req(P_METHOD,"METHOD_READ")
  old <- method[method$scope=="SNRNA" & method$parameter=="COUNT_INPUT",,drop=FALSE]
  if(nrow(old)!=1L ||
     as.character(old$frozen_value)!="RNA_RAW_COUNTS" ||
     as.character(old$rationale)!="Unmodified raw UMI layer is the pseudobulk source.") {
    HOLD("OLD_COUNT_INPUT","Old Step4D SNRNA COUNT_INPUT wording is not exact expected authority")
  }

  guards <- read_csv_req(P_GUARDS,"GUARDS_READ")
  if(nrow(guards)!=12L) HOLD("V13_GUARD_N","Expected 12 frozen V1.3 guards")
  if(any(grepl("integer",tolower(paste(guards$guard_id,guards$check_semantics))))) {
    HOLD("INTEGER_GUARD_AUTHORITY","Frozen V1.3 unexpectedly contains integer-only guard")
  }
  PASS("OLD_WORDING_AND_GUARD","Old raw-UMI wording exact; frozen V1.3 contains no integer-only snRNA guard")

  # 4. Frozen universe remains byte-inherited / structurally unchanged.
  reg <- read_csv_req(P_REGISTRY,"REGISTRY_READ")
  if(nrow(reg)!=840L ||
     length(unique(reg$test_key))!=840L ||
     !identical(as.integer(reg$test_ordinal),1:840) ||
     length(unique(reg$family_id))!=8L) {
    HOLD("REGISTRY_UNCHANGED","Frozen 840-test registry integrity failed")
  }

  tier <- read_csv_req(P_TIER,"TIER_READ")
  if(nrow(tier)!=7L || length(unique(tier$pathway))!=7L) HOLD("TIER_UNCHANGED","Frozen seven-program tier integrity failed")
  fdr <- read_csv_req(P_FDR,"FDR_READ")
  if(nrow(fdr)!=8L) HOLD("FDR_UNCHANGED","Frozen eight-family FDR contract integrity failed")
  PASS("SCIENTIFIC_UNIVERSE_UNCHANGED","840 tests / 7 programs / 8 FDR families unchanged")

  # 5. Version-forward source-semantics overlay.
  overlay <- data.frame(
    scope=rep("SNRNA",10),
    key=c(
      "COUNT_INPUT_LAYER",
      "COUNT_INPUT_EFFECTIVE_SEMANTICS",
      "UPSTREAM_PREPROCESSING_PROVENANCE",
      "NUMERIC_VALUE_POLICY",
      "FRACTIONAL_VALUES_ALLOWED",
      "INTEGER_ONLY_GUARD",
      "CELL_LEVEL_ROUNDING",
      "PSEUDOBULK_AGGREGATION",
      "PSEUDOBULK_ROUNDING",
      "DOWNSTREAM_PIPELINE"
    ),
    effective_value=c(
      "RNA/counts",
      "DEPOSITED_PROCESSED_COUNT_SCALE",
      "CELLBENDER_BACKGROUND_CORRECTED_H5_UPSTREAM",
      "NONNEGATIVE_FINITE_COUNT_SCALE_VALUES",
      "TRUE",
      "PROHIBITED_UNAUTHORIZED",
      "NONE",
      "SUM_VALUES_AS_STORED_WITHIN_PATIENT_X_LABEL",
      "NONE",
      "filterByExpr_EXACT_FROZEN -> TMM -> voom -> mroast_EXACT_FROZEN"
    ),
    supersedes_old_value=c(
      "",
      "RNA_RAW_COUNTS",
      "Unmodified raw UMI layer is the pseudobulk source.",
      "",
      "",
      "",
      "",
      "",
      "",
      ""
    ),
    rationale=c(
      "The exact public snRV_ref.rds RNA/counts layer is the already-selected frozen layer.",
      "PRE1 proves values are fractional, nonnegative, finite and exactly define nCount_RNA; therefore 'raw UMI' is inaccurate.",
      "Official RV_Atlas preprocessing documents CellBender-corrected H5 input before Seurat construction.",
      "Count-scale compatibility is empirically supported by exact per-cell colSum == nCount_RNA.",
      "98.027233% of stored RNA/counts values are fractional; edgeR/limma count workflows permit count-scale fractional values.",
      "The Step4F V1.0 integer-only guard was never part of frozen V1.3 and must not be reintroduced.",
      "No cell-level rounding is authorized.",
      "Preserves the pre-result frozen patient×annotation sum aggregation.",
      "No rounding is added for the RV edgeR/voom pipeline; author repository rounds only in its DESeq2 reanalysis path.",
      "All inferential settings remain byte/semantic equivalents of the pre-result frozen contract."
    ),
    stringsAsFactors=FALSE
  )
  write_csv(overlay,P_OVERLAY)

  delta <- data.frame(
    authority_field=c(
      "SNRNA COUNT_INPUT label",
      "SNRNA COUNT_INPUT rationale",
      "SNRNA fractional-value policy",
      "SNRNA rounding policy",
      "STEP4F integer-only guard"
    ),
    old_effective=c(
      "RNA_RAW_COUNTS",
      "Unmodified raw UMI layer is the pseudobulk source.",
      "UNSPECIFIED",
      "UNSPECIFIED",
      "ADDED_IN_STEP4F_V1_0_BUT_NOT_FROZEN"
    ),
    new_effective=c(
      "RNA_COUNTS_DEPOSITED_PROCESSED_COUNT_SCALE",
      "CellBender-corrected upstream provenance; RNA/counts is nonnegative finite fractional count-scale input.",
      "FRACTIONAL_ALLOWED",
      "NO_ROUNDING_CELL_OR_PSEUDOBULK",
      "PROHIBITED"
    ),
    changes_scientific_question=FALSE,
    changes_test_universe=FALSE,
    changes_threshold=FALSE,
    changes_FDR_family=FALSE,
    changes_downstream_test=FALSE,
    stringsAsFactors=FALSE
  )
  write_csv(delta,P_DELTA)

  evidence <- data.frame(
    evidence_id=c("E01","E02","E03","E04","E05","E06"),
    evidence_type=c(
      "LOCAL_EXACT_OBJECT",
      "PUBLIC_ZENODO_IDENTITY",
      "OFFICIAL_RV_ATLAS_PREPROCESSING",
      "OFFICIAL_RV_ATLAS_SNRNA_REANALYSIS",
      "CELLBENDER_DOCUMENTATION",
      "EDGER_DOCUMENTATION"
    ),
    source=c(
      paste0("Current cold-start Step4F-PRE1 run ",basename(PRE1)),
      "Zenodo record 20115563",
      "https://github.com/ikuznet1/RV_Atlas/blob/main/preprocess_pipeline/preprocess_sn.R",
      "https://github.com/ikuznet1/RV_Atlas/blob/main/additional_scripts/snRNAReanalysis.r",
      "https://cellbender.readthedocs.io/en/latest/usage/index.html",
      "https://bioconductor.org/packages/release/bioc/manuals/edgeR/man/edgeR.pdf"
    ),
    frozen_fact=c(
      "RNA/counts: 178795460 stored values; 175268242 fractional; 0 negative; 0 nonfinite; 61398/61398 colSums exactly equal nCount_RNA.",
      "Local frozen object MD5 exact-match to public shared__snRV_ref.rds MD5 b13511f74a7abbebecb40ddd0cc04f32.",
      "Adult snRNA preprocessing starts from CellBender-corrected filtered H5 and supplies that matrix to CreateSeuratObject(counts=...).",
      "Repository reanalysis loads snRV_ref.rds, pseudobulks RNA slot=counts, and rounds only before DESeq2.",
      "CellBender remove-background output is a background-corrected count matrix intended for downstream Seurat/scanpy analysis.",
      "edgeR/voom count workflows require nonnegative count-scale values and permit fractional counts."
    ),
    role=c(
      "EMPIRICAL_SOURCE_SEMANTICS",
      "PUBLIC_OBJECT_PROVENANCE",
      "UPSTREAM_PROVENANCE",
      "EXACT_OBJECT_ANALYTIC_INTENT",
      "TOOL_SEMANTICS",
      "METHOD_COMPATIBILITY"
    ),
    stringsAsFactors=FALSE
  )
  write_csv(evidence,P_EVIDENCE)

  # 6. Also freeze the implementation-only repair needed before Step4F rerun.
  scope_repair <- data.frame(
    repair_id=c("R01","R02","R03","R04"),
    problem=c(
      "Mixed local result <- reg and result$... <<- subassignment in Step4F V1.0",
      "Unauthorized SN_RAW_COUNT_INTEGER guard",
      "Potential stale partial-result ambiguity after technical HOLD",
      "Scientific-method drift risk during repair"
    ),
    required_repair=c(
      "Use one result object in main() with ordinary <- subassignment only; helper functions return values and never mutate result via <<-.",
      "Remove integer-only guard; retain nonnegative + finite checks and exact source identity.",
      "Initialize explicit 840-row result skeleton and write partial with all result columns present from start.",
      "No change to 840 registry, seeds, contrasts, annotations, program sets, thresholds, mroast settings or fixed-family BH."
    ),
    scientific_change=FALSE,
    stringsAsFactors=FALSE
  )
  write_csv(scope_repair,P_SCOPE_REPAIR)

  writeLines(c(
    "R3 STEP4D V1.4 — AUTHORITY PRECEDENCE",
    paste0("RUN_ID=",RUN_ID),
    "",
    "ORIGINAL AUTHORITIES REMAIN BYTE-IMMUTABLE:",
    "- R3 Step4D scientific contract",
    "- R3 Step4D V1.3 deterministic implementation overlay",
    "",
    "V1.4 PRECEDENCE IS NARROW:",
    "Only the old snRNA COUNT_INPUT wording/provenance/value/rounding semantics are superseded.",
    "",
    "EFFECTIVE SNRNA COUNT SOURCE:",
    "Exact frozen snRV_ref.rds -> RNA/counts.",
    "Semantics: deposited processed count-scale matrix with CellBender-corrected upstream provenance.",
    "Fractional values are allowed; values must remain nonnegative and finite.",
    "No cell-level or pseudobulk rounding is performed in the frozen RV edgeR/TMM/voom/mroast workflow.",
    "",
    "UNCHANGED:",
    "patient replicate; >=20 cells; >=3 patients/group; 7 programs; 840 tests;",
    "pairwise contrasts; filterByExpr thresholds; TMM; voom; mroast; seeds;",
    "8 fixed FDR families; classification rules; no cross-modal P-value combination.",
    "",
    "STEP4F V1.0 remains a technical HOLD with zero localization result.",
    "Next after independent CLEAN audit: generate/run corrected Step4F V1.1 only."
  ),P_PRECEDENCE,useBytes=TRUE)

  writeLines(c(
    "R3 STEP4D V1.4 — SOURCE-SEMANTICS FREEZE NOTE",
    paste0("RUN_ID=",RUN_ID),
    "",
    "WHY THIS REPAIR EXISTS:",
    "The pre-result frozen method correctly selected RNA/counts but inaccurately described it as unmodified raw UMI.",
    "The exact public processed object contains predominantly fractional RNA/counts values.",
    "Public RV_Atlas preprocessing identifies CellBender-corrected H5 as the upstream input.",
    "Public RV_Atlas snRNA reanalysis uses snRV_ref.rds RNA/counts for pseudobulk.",
    "",
    "WHAT CHANGES:",
    "Source/provenance wording and explicit fractional/no-rounding semantics only.",
    "",
    "WHAT DOES NOT CHANGE:",
    "No scientific question, candidate/program universe, annotation, contrast, threshold, normalization,",
    "voom/mroast setting, RNG seed, FDR family or classification rule changes.",
    "",
    "NO REAL EXPRESSION OR SCIENTIFIC LOCALIZATION RESULT WAS GENERATED IN THIS GATE."
  ),P_NOTE,useBytes=TRUE)

  PASS("OVERLAY_WRITTEN","Narrow source-semantics overlay + implementation repair contract written")
  final_state <<- "PASS_STEP4D_V1_4_SNRNA_SOURCE_SEMANTICS_OVERLAY_READY_FOR_INDEPENDENT_AUDIT"
  PASS("FINAL_GATE",final_state)
}

rc <- 0L
tryCatch(
  main(),
  error=function(e) {
    cat("\nERROR/HOLD:\n",conditionMessage(e),"\n",sep="")
    if(!grepl("^HOLD:",conditionMessage(e))) add("UNEXPECTED_RUNTIME_ERROR","FAIL",conditionMessage(e))
    rc <<- 2L
  }
)
finalize()
cat("\nFINAL STATE: ",final_state,"\n",sep="")
cat("RUN DIR: ",RUNDIR,"\n",sep="")
cat("STAGING DIR: ",STAGING,"\n",sep="")
quit(save="no",status=rc)
