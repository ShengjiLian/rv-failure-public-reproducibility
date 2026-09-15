# ---- RV PUBLIC REPRODUCIBILITY PORTABILITY OVERLAY V1.0 ----
.RV_PROJECT_ROOT_ENV <- Sys.getenv('RV_PROJECT_ROOT', unset='')
RV_PROJECT_ROOT <- if (nzchar(.RV_PROJECT_ROOT_ENV)) {
  normalizePath(.RV_PROJECT_ROOT_ENV, winslash='/', mustWork=TRUE)
} else {
  normalizePath(getwd(), winslash='/', mustWork=TRUE)
}
# This overlay changes path binding only; scientific/statistical semantics remain historical authority.

source(file.path(RV_PROJECT_ROOT, 'code', 'lib', 'rv_runtime_helpers.R'))


# R3 Step4E
# Gate9K V1.6 clean-authority/environment repair: dynamic current V1.3 RUN_ID + merged child library stack.
# LOCALIZATION RUNTIME + BROAD/FINE DESIGN-FEASIBILITY PREFLIGHT
#
# GOVERNANCE:
#   - Upstream Step4D scientific contract remains frozen.
#   - Step4D V1.3 deterministic implementation overlay is the execution authority.
#   - This Step4E may read the two frozen RDS objects ONLY for:
#       * metadata/design feasibility,
#       * Assay5 layer structure/dimname identity,
#       * sparse-access compatibility.
#   - This Step4E MUST NOT:
#       * create real-data pseudobulk expression matrices,
#       * run filterByExpr/voom/mroast on real data,
#       * compute real-data program P values/FDR,
#       * produce localization scientific results.
#   - Package installation/repair is prohibited in this Gate.
#
# STEP4E OUTPUTS ARE STRUCTURAL/RUNTIME ONLY.

options(stringsAsFactors = FALSE, warn = 1)

ROOT <- RV_PROJECT_ROOT
RES <- file.path(ROOT, "results", "R3_GSE249696")
UPLOAD <- file.path(ROOT, "upload")
RUNROOT <- file.path(RES, "R3_STEP4E_runs")
PROJECT_LIB <- file.path(RV_PROJECT_ROOT, "R_library/R-4.6")

args <- commandArgs(trailingOnly = TRUE)
RUN_ID <- if (length(args) >= 1L && nzchar(args[1L])) args[1L] else format(Sys.time(), "%Y%m%d_%H%M%S")

RUNDIR <- file.path(RUNROOT, RUN_ID)
STAGING <- file.path(UPLOAD, "R3_STEP4E_STAGING")

dir.create(RUNDIR, recursive = TRUE, showWarnings = FALSE)
dir.create(UPLOAD, recursive = TRUE, showWarnings = FALSE)
if (dir.exists(STAGING)) unlink(STAGING, recursive = TRUE, force = TRUE)
dir.create(STAGING, recursive = TRUE, showWarnings = FALSE)

# Accepted Step4D V1.3 run frozen after independent CLEAN audit.
V13_RUN_ID <- basename(rv_resolve_stage_run(file.path(RES, "R3_STEP4D_V1_3_runs")))
V13DIR <- file.path(RES, "R3_STEP4D_V1_3_runs", V13_RUN_ID)

P_V13_STATUS <- file.path(V13DIR, "R3_STEP4D_V1_3_STATUS.txt")
P_V13_AUDIT <- file.path(V13DIR, "R3_STEP4D_V1_3_implementation_audit.csv")
P_V13_REG <- file.path(V13DIR, "R3_STEP4D_V1_3_DETERMINISTIC_TEST_REGISTRY.csv")
P_V13_SEM <- file.path(V13DIR, "R3_STEP4D_V1_3_implementation_semantics.csv")
P_V13_GUARDS <- file.path(V13DIR, "R3_STEP4D_V1_3_STEP4F_FAIL_CLOSED_GUARDS.csv")
P_V13_OVERLAY <- file.path(V13DIR, "R3_STEP4D_V1_3_DETERMINISTIC_IMPLEMENTATION_OVERLAY_FROZEN.txt")

P_LABELS <- file.path(RES, "R3_STEP4C_V1_2_frozen_annotation_labels.csv")
P_METHOD <- file.path(RES, "R3_STEP4D_localization_method_contract.csv")
P_TIER <- file.path(RES, "R3_STEP4D_program_modality_tier_contract.csv")
P_FDR <- file.path(RES, "R3_STEP4D_fixed_FDR_family_contract.csv")
P_STEP4D_MASTER <- file.path(RES, "R3_STEP4D_LOCALIZATION_ANALYSIS_CONTRACT_FROZEN.txt")

SN_RDS <- file.path(RV_PROJECT_ROOT, "data/raw/GSE345646/GSE345646_snRV_ref.rds")
XE_RDS <- file.path(RV_PROJECT_ROOT, "data/raw/GSE345643/GSE345643_RV_Xenium_ambient_corrected_568651cells.rds")

# BAT generates this exact SHA256 preflight before R starts.
P_PREHASH <- Sys.getenv("R3_STEP4E_PREHASH", unset = "")
if (!nzchar(P_PREHASH)) {
  P_PREHASH <- file.path(RUNDIR, "R3_STEP4E_SOURCE_SHA256_PREFLIGHT.csv")
}

# Outputs
P_STATUS <- file.path(RUNDIR, "R3_STEP4E_STATUS.txt")
P_AUDIT <- file.path(RUNDIR, "R3_STEP4E_audit.csv")
P_RUNTIME <- file.path(RUNDIR, "R3_STEP4E_runtime_environment.csv")
P_SESSION <- file.path(RUNDIR, "R3_STEP4E_sessionInfo.txt")
P_EXTSOFT <- file.path(RUNDIR, "R3_STEP4E_extSoftVersion.csv")
P_LIBPATHS <- file.path(RUNDIR, "R3_STEP4E_libPaths.csv")
P_LOCALE <- file.path(RUNDIR, "R3_STEP4E_locale.csv")
P_THREADS <- file.path(RUNDIR, "R3_STEP4E_thread_environment.csv")
P_PACKAGES <- file.path(RUNDIR, "R3_STEP4E_package_versions.csv")
P_SMOKE <- file.path(RUNDIR, "R3_STEP4E_synthetic_mroast_smoke.csv")
P_LAYER <- file.path(RUNDIR, "R3_STEP4E_Assay5_sparse_layer_manifest.csv")
P_ROLE_CAND <- file.path(RUNDIR, "R3_STEP4E_metadata_role_candidates.csv")
P_ROLE_FREEZE <- file.path(RUNDIR, "R3_STEP4E_metadata_role_freeze.csv")
P_PATIENT_CROSS <- file.path(RUNDIR, "R3_STEP4E_patient_crosswalk.csv")
P_CELL_COUNTS <- file.path(RUNDIR, "R3_STEP4E_patient_group_annotation_cell_count_manifest.csv")
P_DESIGN <- file.path(RUNDIR, "R3_STEP4E_design_feasibility.csv")
P_DESIGN_SUM <- file.path(RUNDIR, "R3_STEP4E_design_feasibility_summary.csv")
P_REG_FEAS <- file.path(RUNDIR, "R3_STEP4E_registry_design_feasibility.csv")
P_RDS_ID <- file.path(RUNDIR, "R3_STEP4E_RDS_identity.csv")
P_BOUNDARY <- file.path(RUNDIR, "R3_STEP4E_GATE_BOUNDARY.txt")

audit <- data.frame(
  check_id = character(),
  status = character(),
  detail = character(),
  stringsAsFactors = FALSE
)

add_audit <- function(id, status, detail) {
  audit <<- rbind(
    audit,
    data.frame(
      check_id = as.character(id),
      status = as.character(status),
      detail = as.character(detail),
      stringsAsFactors = FALSE
    )
  )
  cat(sprintf("[%s] %s :: %s\n", status, id, detail))
}

PASS <- function(id, detail) add_audit(id, "PASS", detail)

HOLD <- function(id, detail) {
  add_audit(id, "FAIL", detail)
  stop(paste0("HOLD: ", detail), call. = FALSE)
}

write_csv_utf8 <- function(x, path) {
  write.csv(x, path, row.names = FALSE, na = "", fileEncoding = "UTF-8")
}

copy_stage <- function(paths) {
  paths <- unique(paths[file.exists(paths)])
  for (p in paths) {
    ok <- file.copy(
      p,
      file.path(STAGING, basename(p)),
      overwrite = TRUE,
      copy.mode = TRUE,
      copy.date = TRUE
    )
    if (!isTRUE(ok)) {
      stop(paste("Could not stage:", p), call. = FALSE)
    }
  }
}

final_state <- "HOLD_STEP4E_RUNTIME_AND_DESIGN_FEASIBILITY_PREFLIGHT"

finalize <- function() {
  try(write_csv_utf8(audit, P_AUDIT), silent = TRUE)

  try(writeLines(
    c(
      paste0("RUN_ID=", RUN_ID),
      paste0("FINAL_STATE=", final_state),
      "UPSTREAM_STEP4D_SCIENTIFIC_CONTRACT=UNCHANGED",
      "UPSTREAM_STEP4D_V1_3_DETERMINISTIC_OVERLAY=UNCHANGED",
      "REAL_RDS_READ_FOR_METADATA_AND_LAYER_STRUCTURE=YES_IF_RUNTIME_REACHED",
      "REAL_EXPRESSION_LAYER_DIMNAMES_ACCESSED=YES_IF_RUNTIME_REACHED",
      "REAL_EXPRESSION_VALUES_USED_FOR_SCIENTIFIC_TESTING=NO",
      "REAL_PSEUDOBULK_EXPRESSION_GENERATED=NO",
      "REAL_FILTERBYEXPR_EXECUTED=NO",
      "REAL_VOOM_EXECUTED=NO",
      "REAL_MROAST_EXECUTED=NO",
      "REAL_PROGRAM_PVALUE_GENERATED=NO",
      "REAL_FDR_GENERATED=NO",
      "LOCALIZATION_SCIENTIFIC_RESULT_PRODUCED=NO",
      "PACKAGE_INSTALLATION_PERFORMED=NO"
    ),
    P_STATUS,
    useBytes = TRUE
  ), silent = TRUE)

  try(writeLines(
    c(
      "R3 STEP4E GATE BOUNDARY",
      paste0("RUN_ID=", RUN_ID),
      "",
      "ALLOWED:",
      "- exact frozen-source identity checks",
      "- runtime/package/session provenance",
      "- synthetic-only edgeR/voom/mroast smoke tests",
      "- readRDS for metadata and Assay5 layer structural/dimname checks",
      "- patient/group/annotation metadata counts",
      "- BROAD/FINE patient-design feasibility",
      "- snRNA/Xenium patient crosswalk",
      "",
      "PROHIBITED:",
      "- real-data pseudobulk expression generation",
      "- real-data filterByExpr",
      "- real-data voom",
      "- real-data mroast",
      "- real-data program P values or BH",
      "- localization scientific classification",
      "- package installation/repair in this Gate",
      "",
      "NEXT ONLY AFTER INDEPENDENT CLEAN AUDIT:",
      "R3 Step4F deterministic localization execution"
    ),
    P_BOUNDARY,
    useBytes = TRUE
  ), silent = TRUE)

  try(copy_stage(c(
    P_PREHASH,
    P_STATUS, P_AUDIT, P_BOUNDARY,
    P_RUNTIME, P_SESSION, P_EXTSOFT, P_LIBPATHS, P_LOCALE,
    P_THREADS, P_PACKAGES, P_SMOKE, P_LAYER,
    P_ROLE_CAND, P_ROLE_FREEZE, P_PATIENT_CROSS,
    P_CELL_COUNTS, P_DESIGN, P_DESIGN_SUM, P_REG_FEAS, P_RDS_ID,
    P_V13_STATUS, P_V13_AUDIT, P_V13_REG, P_V13_SEM,
    P_V13_GUARDS, P_V13_OVERLAY,
    P_LABELS, P_METHOD, P_TIER, P_FDR, P_STEP4D_MASTER
  )), silent = TRUE)
}

on.exit(finalize(), add = TRUE)

read_csv_req <- function(path, id) {
  if (!file.exists(path)) HOLD(id, paste("Missing:", path))
  if (file.info(path)$size <= 0) HOLD(id, paste("Zero-byte:", path))
  x <- tryCatch(
    read.csv(path, check.names = FALSE, stringsAsFactors = FALSE),
    error = function(e) NULL
  )
  if (is.null(x)) HOLD(id, paste("Could not read:", path))
  x
}

require_cols <- function(x, cols, id) {
  missing <- setdiff(cols, names(x))
  if (length(missing)) {
    HOLD(id, paste("Missing columns:", paste(missing, collapse = ", ")))
  }
}

as_chr_exact <- function(x) {
  if (is.factor(x)) return(as.character(x))
  if (is.character(x)) return(x)
  as.character(x)
}

# Equivalent-value classes for metadata aliases.
equivalence_classes <- function(meta, candidate_names) {
  classes <- list()

  for (nm in candidate_names) {
    v <- as_chr_exact(meta[[nm]])
    placed <- FALSE

    if (length(classes)) {
      for (i in seq_along(classes)) {
        if (identical(v, classes[[i]]$vector)) {
          classes[[i]]$aliases <- c(classes[[i]]$aliases, nm)
          placed <- TRUE
          break
        }
      }
    }

    if (!placed) {
      classes[[length(classes) + 1L]] <- list(
        aliases = nm,
        canonical = nm,
        vector = v
      )
    }
  }

  classes
}

detect_group_role <- function(meta, dataset_name) {
  candidates <- character()

  for (nm in names(meta)) {
    x <- meta[[nm]]
    if (is.list(x) || is.matrix(x) || is.data.frame(x)) next

    u <- unique(x)
    if (length(u) != 3L) next

    v <- as_chr_exact(x)
    if (anyNA(v) || any(!nzchar(v))) next

    if (setequal(unique(v), c("NF", "pRV", "RVF"))) {
      candidates <- c(candidates, nm)
    }
  }

  if (!length(candidates)) {
    HOLD(
      paste0(dataset_name, "_GROUP_ROLE"),
      "No metadata column has exact complete values {NF,pRV,RVF}"
    )
  }

  classes <- equivalence_classes(meta, candidates)

  if (length(classes) != 1L) {
    HOLD(
      paste0(dataset_name, "_GROUP_ROLE"),
      paste(
        "More than one non-equivalent exact {NF,pRV,RVF} metadata vector:",
        paste(vapply(classes, function(z) paste(z$aliases, collapse = "|"), character(1)), collapse = " ; ")
      )
    )
  }

  z <- classes[[1L]]

  list(
    canonical = z$aliases[1L],
    aliases = z$aliases,
    vector = z$vector
  )
}

detect_patient_classes <- function(meta, group_vector, expected_n, dataset_name) {
  candidate_names <- character()

  for (nm in names(meta)) {
    x <- meta[[nm]]
    if (is.list(x) || is.matrix(x) || is.data.frame(x)) next

    u <- unique(x)
    if (length(u) != expected_n) next

    v <- as_chr_exact(x)
    if (anyNA(v) || any(!nzchar(v))) next

    pair <- unique(data.frame(
      patient_id = v,
      group = group_vector,
      stringsAsFactors = FALSE
    ))

    # A true patient role must map each patient to one and only one disease group.
    if (nrow(pair) != expected_n) next
    if (anyDuplicated(pair$patient_id)) next

    candidate_names <- c(candidate_names, nm)
  }

  if (!length(candidate_names)) {
    HOLD(
      paste0(dataset_name, "_PATIENT_ROLE"),
      paste("No metadata column yields", expected_n, "patients with one-to-one patient->group mapping")
    )
  }

  classes <- equivalence_classes(meta, candidate_names)

  for (i in seq_along(classes)) {
    v <- classes[[i]]$vector
    pair <- unique(data.frame(
      patient_id = v,
      group = group_vector,
      stringsAsFactors = FALSE
    ))

    classes[[i]]$patient_set <- as.character(pair$patient_id)
    classes[[i]]$patient_group <- setNames(
      as.character(pair$group),
      as.character(pair$patient_id)
    )
  }

  classes
}

annotation_exact_guard <- function(meta, field, frozen_labels, dataset_name) {
  if (!field %in% names(meta)) {
    HOLD(paste0(dataset_name, "_ANNOTATION_", field), paste("Missing field:", field))
  }

  v <- as_chr_exact(meta[[field]])

  if (anyNA(v) || any(!nzchar(v))) {
    HOLD(
      paste0(dataset_name, "_ANNOTATION_", field),
      paste(field, "contains NA/empty values")
    )
  }

  observed <- unique(v)

  if (!setequal(observed, frozen_labels)) {
    HOLD(
      paste0(dataset_name, "_ANNOTATION_", field),
      paste(
        field,
        "observed label set differs from frozen authority;",
        "observed_n=", length(observed),
        "frozen_n=", length(frozen_labels)
      )
    )
  }

  invisible(TRUE)
}

process_seurat_structure <- function(
  path,
  dataset_name,
  assay_name,
  layer_specs,
  annotation_specs,
  expected_cells,
  expected_patients
) {
  cat("\n--- Loading structural object:", dataset_name, "---\n")
  obj <- readRDS(path)

  if (!inherits(obj, "Seurat")) {
    HOLD(paste0(dataset_name, "_CLASS"), paste("Expected Seurat; observed:", paste(class(obj), collapse = "|")))
  }

  if (!assay_name %in% names(obj@assays)) {
    HOLD(
      paste0(dataset_name, "_ASSAY"),
      paste("Expected assay", assay_name, "not found; assays:", paste(names(obj@assays), collapse = "|"))
    )
  }

  meta <- obj@meta.data

  if (nrow(meta) != expected_cells) {
    HOLD(
      paste0(dataset_name, "_META_NROW"),
      paste("Expected", expected_cells, "metadata rows; found", nrow(meta))
    )
  }

  if (is.null(rownames(meta)) || anyDuplicated(rownames(meta))) {
    HOLD(paste0(dataset_name, "_META_ROWNAME"), "Metadata rownames missing or duplicated")
  }

  # Frozen annotation identities from Step4C.
  for (sp in annotation_specs) {
    annotation_exact_guard(
      meta,
      sp$field,
      sp$labels,
      dataset_name
    )
  }

  # Metadata role discovery is structural only.
  group_role <- detect_group_role(meta, dataset_name)
  patient_classes <- detect_patient_classes(
    meta,
    group_role$vector,
    expected_patients,
    dataset_name
  )

  layer_rows <- list()

  for (sp in layer_specs) {
    assay_obj <- obj[[assay_name]]

    layers_available <- SeuratObject::Layers(assay_obj)
    if (!sp$layer %in% layers_available) {
      HOLD(
        paste0(dataset_name, "_LAYER_", sp$layer),
        paste("Missing layer", sp$layer, "; available:", paste(layers_available, collapse = "|"))
      )
    }

    x <- SeuratObject::LayerData(assay_obj, layer = sp$layer)

    if (!inherits(x, "sparseMatrix")) {
      HOLD(
        paste0(dataset_name, "_SPARSE_", sp$layer),
        paste("Layer is not sparseMatrix:", paste(class(x), collapse = "|"))
      )
    }

    if (!identical(as.integer(dim(x)), as.integer(sp$dim))) {
      HOLD(
        paste0(dataset_name, "_DIM_", sp$layer),
        paste(
          "Expected", paste(sp$dim, collapse = "x"),
          "found", paste(dim(x), collapse = "x")
        )
      )
    }

    if (!identical(colnames(x), rownames(meta))) {
      HOLD(
        paste0(dataset_name, "_EXPRESSION_METADATA_IDENTITY_", sp$layer),
        "identical(colnames(expression_layer), rownames(meta.data)) is FALSE"
      )
    }

    if (anyDuplicated(colnames(x))) {
      HOLD(
        paste0(dataset_name, "_DUP_CELL_", sp$layer),
        "Expression layer column names duplicated"
      )
    }

    if (is.null(rownames(x)) || anyDuplicated(rownames(x))) {
      HOLD(
        paste0(dataset_name, "_DUP_GENE_", sp$layer),
        "Expression layer gene names missing or duplicated"
      )
    }

    layer_rows[[length(layer_rows) + 1L]] <- data.frame(
      dataset = dataset_name,
      assay = assay_name,
      layer = sp$layer,
      class = paste(class(x), collapse = "|"),
      n_genes = nrow(x),
      n_cells = ncol(x),
      sparseMatrix = TRUE,
      expression_colnames_identical_metadata_rownames = TRUE,
      duplicated_cell_names = 0L,
      duplicated_gene_names = 0L,
      full_as_matrix_used = FALSE,
      expression_values_used_for_scientific_testing = FALSE,
      stringsAsFactors = FALSE
    )

    rm(x, assay_obj)
    gc(verbose = FALSE)
  }

  # Keep only metadata needed downstream; do not keep the full Seurat object.
  ann_small <- as.data.frame(
    lapply(annotation_specs, function(sp) as_chr_exact(meta[[sp$field]])),
    stringsAsFactors = FALSE
  )
  names(ann_small) <- vapply(annotation_specs, function(sp) sp$field, character(1))

  out <- list(
    group_role = group_role,
    patient_classes = patient_classes,
    annotations = ann_small,
    cell_ids = rownames(meta),
    layer_manifest = do.call(rbind, layer_rows)
  )

  rm(meta, obj)
  gc(verbose = FALSE)

  out
}

build_role_candidate_rows <- function(dataset, group_role, patient_classes) {
  rows <- list(
    data.frame(
      dataset = dataset,
      role_type = "GROUP",
      equivalence_class = 1L,
      canonical_column = group_role$canonical,
      equivalent_aliases = paste(group_role$aliases, collapse = "|"),
      unique_values = 3L,
      exact_values_or_patient_set = paste(sort(unique(group_role$vector), method = "radix"), collapse = "|"),
      stringsAsFactors = FALSE
    )
  )

  if (length(patient_classes)) {
    for (i in seq_along(patient_classes)) {
      z <- patient_classes[[i]]
      rows[[length(rows) + 1L]] <- data.frame(
        dataset = dataset,
        role_type = "PATIENT_CANDIDATE",
        equivalence_class = i,
        canonical_column = z$aliases[1L],
        equivalent_aliases = paste(z$aliases, collapse = "|"),
        unique_values = length(z$patient_set),
        exact_values_or_patient_set = paste(sort(z$patient_set, method = "radix"), collapse = "|"),
        stringsAsFactors = FALSE
      )
    }
  }

  do.call(rbind, rows)
}

select_crossmodal_patient_pair <- function(sn_classes, xe_classes) {
  valid <- list()

  for (i in seq_along(sn_classes)) {
    sn <- sn_classes[[i]]

    for (j in seq_along(xe_classes)) {
      xe <- xe_classes[[j]]

      sn_set <- sn$patient_set
      xe_set <- xe$patient_set
      extra_sn <- setdiff(sn_set, xe_set)
      extra_xe <- setdiff(xe_set, sn_set)
      shared <- intersect(sn_set, xe_set)

      if (length(shared) != 9L) next
      if (length(extra_xe) != 0L) next
      if (!setequal(extra_sn, c("1392", "1681"))) next

      group_match <- all(
        unname(sn$patient_group[shared]) ==
          unname(xe$patient_group[shared])
      )

      if (!group_match) next

      valid[[length(valid) + 1L]] <- c(sn_class = i, xe_class = j)
    }
  }

  if (length(valid) != 1L) {
    HOLD(
      "PATIENT_CROSSMODAL_ROLE",
      paste(
        "Expected exactly one patient-identity class pair satisfying:",
        "11 snRNA, 9 Xenium, Xenium subset of snRNA, snRNA extras exactly {1392,1681},",
        "shared group mapping exact. Found", length(valid)
      )
    )
  }

  valid[[1L]]
}

build_cell_count_manifest <- function(
  modality,
  annotation_level,
  annotation_field,
  frozen_labels,
  patient_vector,
  group_vector,
  annotation_vector
) {
  patients <- sort(unique(patient_vector), method = "radix")

  pair <- unique(data.frame(
    patient_id = patient_vector,
    group = group_vector,
    stringsAsFactors = FALSE
  ))

  if (nrow(pair) != length(patients) || anyDuplicated(pair$patient_id)) {
    HOLD(
      paste0(modality, "_PATIENT_GROUP_MAPPING"),
      "Patient-to-group mapping is not one-to-one"
    )
  }

  gmap <- setNames(pair$group, pair$patient_id)

  tab <- table(
    factor(patient_vector, levels = patients),
    factor(annotation_vector, levels = frozen_labels)
  )

  grid <- expand.grid(
    patient_id = patients,
    label = frozen_labels,
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )

  # expand.grid varies first factor fastest; table lookup is exact by names.
  grid$group <- unname(gmap[grid$patient_id])
  grid$cell_count <- mapply(
    function(p, l) as.integer(tab[p, l]),
    grid$patient_id,
    grid$label
  )
  grid$eligible_ge20 <- grid$cell_count >= 20L

  grid$modality <- modality
  grid$annotation_level <- annotation_level
  grid$annotation_field <- annotation_field

  grid[, c(
    "modality", "annotation_level", "annotation_field",
    "label", "patient_id", "group", "cell_count", "eligible_ge20"
  )]
}

make_design_feasibility <- function(blocks, cell_manifest) {
  out <- vector("list", nrow(blocks))

  for (i in seq_len(nrow(blocks))) {
    b <- blocks[i, , drop = FALSE]

    cc <- cell_manifest[
      cell_manifest$modality == b$modality &
        cell_manifest$annotation_level == b$annotation_level &
        cell_manifest$annotation_field == b$annotation_field &
        cell_manifest$label == b$label,
      ,
      drop = FALSE
    ]

    num <- as.character(b$contrast_numerator)
    den <- as.character(b$contrast_denominator)

    p_num <- sort(
      cc$patient_id[cc$group == num & cc$eligible_ge20],
      method = "radix"
    )
    p_den <- sort(
      cc$patient_id[cc$group == den & cc$eligible_ge20],
      method = "radix"
    )

    n_num <- length(p_num)
    n_den <- length(p_den)
    feasible <- n_num >= 3L && n_den >= 3L

    design_rank <- NA_integer_
    design_ncol <- NA_integer_
    design_full_rank <- NA
    contrast_estimable <- NA

    if (feasible) {
      lev <- strsplit(as.character(b$factor_levels), "|", fixed = TRUE)[[1L]]

      if (!identical(lev, c(den, num))) {
        HOLD(
          "DESIGN_FACTOR_LEVEL_SOURCE",
          paste(
            b$modality, b$annotation_level, b$contrast_id, b$label,
            "factor_levels mismatch:", b$factor_levels,
            "expected", paste(c(den, num), collapse = "|")
          )
        )
      }

      g <- factor(
        c(rep(den, n_den), rep(num, n_num)),
        levels = lev
      )

      design <- model.matrix(~0 + g)
      colnames(design) <- levels(g)

      design_rank <- qr(design)$rank
      design_ncol <- ncol(design)
      design_full_rank <- design_rank == design_ncol

      contrast <- setNames(c(-1, +1), c(den, num))

      contrast_estimable <- (
        isTRUE(design_full_rank) &&
          length(contrast) == ncol(design) &&
          identical(names(contrast), colnames(design)) &&
          all(is.finite(contrast))
      )

      if (!isTRUE(design_full_rank) || !isTRUE(contrast_estimable)) {
        HOLD(
          "DESIGN_ARITHMETIC",
          paste(
            b$modality, b$annotation_level, b$contrast_id, b$label,
            "failed full-rank/estimability guard"
          )
        )
      }
    }

    out[[i]] <- data.frame(
      block_ordinal = i,
      modality = b$modality,
      annotation_level = b$annotation_level,
      annotation_field = b$annotation_field,
      contrast_id = b$contrast_id,
      contrast_expression = b$contrast_expression,
      contrast_numerator = num,
      contrast_denominator = den,
      factor_levels = b$factor_levels,
      contrast_vector = b$contrast_vector,
      label = b$label,
      eligible_patients_numerator = n_num,
      eligible_patients_denominator = n_den,
      eligible_patient_ids_numerator = paste(p_num, collapse = "|"),
      eligible_patient_ids_denominator = paste(p_den, collapse = "|"),
      min_cells_per_patient_annotation = 20L,
      min_patients_per_group = 3L,
      patient_design_feasible = feasible,
      design_rank_if_feasible = design_rank,
      design_ncol_if_feasible = design_ncol,
      design_full_rank_if_feasible = design_full_rank,
      contrast_estimable_if_feasible = contrast_estimable,
      final_program_assessability_determined = FALSE,
      stringsAsFactors = FALSE
    )
  }

  do.call(rbind, out)
}

run_synthetic_smoke <- function() {
  # IMPORTANT: all data in this function are synthetic and deterministic.
  # No real RDS expression values enter these tests.

  RNGkind(
    kind = "Mersenne-Twister",
    normal.kind = "Inversion",
    sample.kind = "Rejection"
  )

  group <- factor(
    c(rep("pRV", 4L), rep("RVF", 4L)),
    levels = c("pRV", "RVF")
  )

  design <- model.matrix(~0 + group)
  colnames(design) <- levels(group)
  contrast <- c(pRV = -1, RVF = +1)

  if (qr(design)$rank != ncol(design)) {
    HOLD("SYNTHETIC_DESIGN_RANK", "Synthetic pairwise design is not full rank")
  }

  if (!identical(names(contrast), colnames(design))) {
    HOLD("SYNTHETIC_CONTRAST", "Synthetic contrast names do not match design")
  }

  # snRNA-style synthetic counts -> edgeR -> voom -> mroast
  ng <- 120L
  ns <- 8L
  base <- matrix(
    ((seq_len(ng * ns) * 37L) %% 41L) + 30L,
    nrow = ng,
    ncol = ns
  )
  rownames(base) <- paste0("G", seq_len(ng))
  colnames(base) <- paste0("S", seq_len(ns))
  base[1:20, 5:8] <- base[1:20, 5:8] + 20L

  y <- edgeR::DGEList(counts = base, group = group)

  keep <- edgeR::filterByExpr(
    y,
    design = design,
    min.count = 10,
    min.total.count = 15,
    large.n = 10,
    min.prop = 0.7
  )

  if (sum(keep) < 20L) {
    HOLD("SYNTHETIC_FILTERBYEXPR", paste("Only", sum(keep), "synthetic genes retained"))
  }

  y <- y[keep, , keep.lib.sizes = FALSE]
  y <- edgeR::calcNormFactors(y, method = "TMM")
  v <- limma::voom(y, design = design, plot = FALSE)

  idx_sn <- which(rownames(v$E) %in% paste0("G", 1:20))
  if (length(idx_sn) < 10L) {
    HOLD("SYNTHETIC_SN_INDEX", paste("Synthetic snRNA index only", length(idx_sn)))
  }

  run_sn <- function(seed) {
    set.seed(seed)
    limma::mroast(
      y = v,
      index = list(SMOKE_PROGRAM = idx_sn),
      design = design,
      contrast = contrast,
      set.statistic = "mean",
      nrot = 9999,
      approx.zscore = TRUE,
      legacy = FALSE,
      adjust.method = "none",
      midp = TRUE,
      sort = "none",
      trend.var = FALSE
    )
  }

  sn1 <- run_sn(20260911L)
  sn2 <- run_sn(20260911L)

  # Xenium-style synthetic corrected panel -> CPM/log2 -> mroast
  nx <- 80L
  raw_x <- matrix(
    (((seq_len(nx * ns) * 29L) %% 53L) + 1L) / 3,
    nrow = nx,
    ncol = ns
  )
  rownames(raw_x) <- paste0("X", seq_len(nx))
  colnames(raw_x) <- paste0("XS", seq_len(ns))
  raw_x[1:15, 5:8] <- raw_x[1:15, 5:8] + 2.5

  denom <- colSums(raw_x)
  if (any(!is.finite(denom)) || any(denom <= 0)) {
    HOLD("SYNTHETIC_XE_DENOM", "Synthetic Xenium denominator invalid")
  }

  logcpm <- log2(1 + sweep(raw_x, 2, denom, "/") * 1e6)
  idx_xe <- 1:15

  run_xe <- function(seed) {
    set.seed(seed)
    limma::mroast(
      y = logcpm,
      index = list(SMOKE_PROGRAM = idx_xe),
      design = design,
      contrast = contrast,
      set.statistic = "mean",
      nrot = 9999,
      approx.zscore = TRUE,
      legacy = FALSE,
      adjust.method = "none",
      midp = TRUE,
      sort = "none",
      trend.var = TRUE
    )
  }

  xe1 <- run_xe(20260911L)
  xe2 <- run_xe(20260911L)

  for (nm in c("PValue", "Direction")) {
    if (!nm %in% colnames(sn1)) {
      HOLD("SYNTHETIC_SN_MROAST_SCHEMA", paste("Missing mroast column:", nm))
    }
    if (!nm %in% colnames(xe1)) {
      HOLD("SYNTHETIC_XE_MROAST_SCHEMA", paste("Missing mroast column:", nm))
    }
  }

  sn_identical <- identical(sn1, sn2)
  xe_identical <- identical(xe1, xe2)

  if (!sn_identical) {
    HOLD("SYNTHETIC_SN_DETERMINISM", "Repeated snRNA-style mroast differs at identical seed")
  }

  if (!xe_identical) {
    HOLD("SYNTHETIC_XE_DETERMINISM", "Repeated Xenium-style mroast differs at identical seed")
  }

  data.frame(
    profile = c("SNRNA_STYLE_SYNTHETIC", "XENIUM_STYLE_SYNTHETIC"),
    seed = c(20260911L, 20260911L),
    nrot = c(9999L, 9999L),
    set_statistic = c("mean", "mean"),
    midp = c(TRUE, TRUE),
    adjust_method = c("none", "none"),
    sort = c("none", "none"),
    approx_zscore = c(TRUE, TRUE),
    legacy = c(FALSE, FALSE),
    trend_var = c(FALSE, TRUE),
    repeated_run_exact_identical = c(sn_identical, xe_identical),
    output_direction = c(as.character(sn1$Direction[1L]), as.character(xe1$Direction[1L])),
    output_raw_PValue = c(as.numeric(sn1$PValue[1L]), as.numeric(xe1$PValue[1L])),
    scientific_interpretation = c("NONE_SYNTHETIC_ONLY", "NONE_SYNTHETIC_ONLY"),
    stringsAsFactors = FALSE
  )
}

main <- function() {
  # -----------------------------------------------------------------------
  # 1. Exact prehash identity from BAT
  # -----------------------------------------------------------------------
  prehash <- read_csv_req(P_PREHASH, "SOURCE_SHA256_PREFLIGHT")

  require_cols(
    prehash,
    c("role", "path", "exists", "bytes", "expected_sha256", "actual_sha256", "sha_match"),
    "SOURCE_SHA256_PREFLIGHT_COLUMNS"
  )

  sha_ok <- tolower(as.character(prehash$sha_match)) == "true"

  if (!all(sha_ok)) {
    bad <- prehash$role[!sha_ok]
    HOLD(
      "SOURCE_SHA256_PREFLIGHT",
      paste("SHA mismatch/missing:", paste(bad, collapse = " | "))
    )
  }

  PASS(
    "SOURCE_SHA256_PREFLIGHT",
    paste(nrow(prehash), "/", nrow(prehash), "exact SHA256 identities PASS")
  )

  rds_rows <- prehash[prehash$role %in% c("SNRNA_RDS", "XENIUM_RDS"), , drop = FALSE]
  write_csv_utf8(rds_rows, P_RDS_ID)

  # -----------------------------------------------------------------------
  # 2. Step4D V1.3 accepted authority semantics
  # -----------------------------------------------------------------------
  if (!all(file.exists(c(P_V13_STATUS, P_V13_AUDIT, P_V13_REG, P_V13_SEM, P_V13_GUARDS, P_V13_OVERLAY)))) {
    HOLD("STEP4D_V1_3_FILES", "Accepted Step4D V1.3 run artifacts missing")
  }

  st <- readLines(P_V13_STATUS, warn = FALSE, encoding = "UTF-8")

  run_lines <- grep("^RUN_ID=", st, value = TRUE)
  required_status <- c(
    "FINAL_STATE=PASS_STEP4D_V1_3_DETERMINISTIC_IMPLEMENTATION_OVERLAY_READY_FOR_INDEPENDENT_AUDIT",
    "STEP4D_SCIENTIFIC_CONTRACT=UNCHANGED",
    "REAL_RDS_READ=NO",
    "PSEUDOBULK_EXECUTED=NO",
    "MROAST_EXECUTED=NO",
    "LOCALIZATION_SCIENTIFIC_RESULT_PRODUCED=NO"
  )

  if (length(run_lines) != 1L ||
      !identical(sub("^RUN_ID=", "", run_lines), V13_RUN_ID) ||
      !all(required_status %in% st)) {
    HOLD("STEP4D_V1_3_STATUS", "Current cold-start V1.3 RUN_ID/status sentinels not exact")
  }

  a13 <- read_csv_req(P_V13_AUDIT, "READ_V13_AUDIT")
  require_cols(a13, c("check_id", "status", "detail"), "V13_AUDIT_COLUMNS")

  if (nrow(a13) != 14L || any(a13$status != "PASS")) {
    HOLD(
      "STEP4D_V1_3_AUDIT",
      paste("Expected 14/14 PASS; rows=", nrow(a13), "nonPASS=", sum(a13$status != "PASS"))
    )
  }

  reg <- read_csv_req(P_V13_REG, "READ_V13_REGISTRY")

  if (
    nrow(reg) != 840L ||
      length(unique(reg$test_key)) != 840L ||
      !identical(as.integer(reg$test_ordinal), 1:840) ||
      length(unique(reg$test_seed)) != 840L
  ) {
    HOLD("STEP4D_V1_3_REGISTRY", "Accepted 840-test registry integrity failed")
  }

  PASS("STEP4D_V1_3_AUTHORITY", "Accepted V1.3 status + 14/14 audit + 840-test registry exact")

  # -----------------------------------------------------------------------
  # 3. Runtime + provenance. No installation allowed.
  # -----------------------------------------------------------------------
  if (!identical(as.character(getRversion()), "4.6.1")) {
    HOLD("R_VERSION", paste("Expected R 4.6.1; observed", getRversion()))
  }

  if (!dir.exists(PROJECT_LIB)) {
    HOLD("PROJECT_LIBRARY", paste("Missing project library:", PROJECT_LIB))
  }

  expected_lib <- normalizePath(PROJECT_LIB, winslash = "/", mustWork = TRUE)
  raw_user_lib <- Sys.getenv("R_LIBS_USER", unset = "")
  observed_user_libs <- if (nzchar(raw_user_lib)) strsplit(raw_user_lib, .Platform$path.sep, fixed = TRUE)[[1L]] else character()
  observed_user_libs <- observed_user_libs[nzchar(observed_user_libs)]
  observed_user_libs <- normalizePath(observed_user_libs, winslash = "/", mustWork = FALSE)
  observed_libpaths <- normalizePath(.libPaths(), winslash = "/", mustWork = FALSE)

  if (length(observed_user_libs) < 1L ||
      !identical(tolower(observed_user_libs[1L]), tolower(expected_lib))) {
    HOLD(
      "PROJECT_LIBRARY_R_LIBS_USER",
      paste("R_LIBS_USER must start with project library and may retain normal user libraries; expected first",
            expected_lib, "observed", paste(observed_user_libs, collapse = " | "))
    )
  }

  if (length(observed_libpaths) < 1L ||
      !identical(tolower(observed_libpaths[1L]), tolower(expected_lib))) {
    HOLD(
      "PROJECT_LIBRARY_LIBPATH_FIRST",
      paste("First .libPaths() entry must be project library; observed", paste(observed_libpaths, collapse = " | "))
    )
  }

  required_pkgs <- c("BiocManager", "limma", "edgeR", "Matrix", "SeuratObject")

  installed <- rownames(installed.packages())

  missing_pkg <- setdiff(required_pkgs, installed)

  if (length(missing_pkg)) {
    HOLD(
      "RUNTIME_PACKAGES",
      paste(
        "Required package(s) missing; DO NOT install in this Gate:",
        paste(missing_pkg, collapse = ", ")
      )
    )
  }

  if (!identical(as.character(utils::packageVersion("SeuratObject")), "5.4.0")) {
    HOLD(
      "SEURATOBJECT_VERSION",
      paste("Expected SeuratObject 5.4.0; observed", utils::packageVersion("SeuratObject"))
    )
  }

  # Load only what Step4E needs. Full Seurat is not loaded.
  suppressPackageStartupMessages(library(SeuratObject))
  suppressPackageStartupMessages(library(Matrix))

  if ("Seurat" %in% loadedNamespaces()) {
    HOLD("FULL_SEURAT_NOT_LOADED", "Full Seurat namespace became loaded; Step4E requires SeuratObject-only workflow")
  }

  # Thread variables were set by BAT.
  thread_vars <- c(
    "OMP_NUM_THREADS",
    "OPENBLAS_NUM_THREADS",
    "MKL_NUM_THREADS",
    "BLIS_NUM_THREADS"
  )

  thread_values <- Sys.getenv(thread_vars, unset = "")

  if (any(thread_values != "1")) {
    HOLD(
      "THREAD_ENVIRONMENT",
      paste(
        "Expected all thread guards=1; observed",
        paste(paste0(thread_vars, "=", thread_values), collapse = " | ")
      )
    )
  }

  RNGkind(
    kind = "Mersenne-Twister",
    normal.kind = "Inversion",
    sample.kind = "Rejection"
  )

  rng_now <- RNGkind()

  if (!identical(
    unname(rng_now),
    c("Mersenne-Twister", "Inversion", "Rejection")
  )) {
    HOLD("RNGKIND", paste("Unexpected RNGkind:", paste(rng_now, collapse = "|")))
  }

  bioc_version <- as.character(BiocManager::version())

  package_rows <- data.frame(
    package = required_pkgs,
    version = vapply(
      required_pkgs,
      function(p) as.character(utils::packageVersion(p)),
      character(1)
    ),
    stringsAsFactors = FALSE
  )

  write_csv_utf8(package_rows, P_PACKAGES)

  si <- sessionInfo()
  writeLines(capture.output(si), P_SESSION, useBytes = TRUE)

  es <- extSoftVersion()
  write_csv_utf8(
    data.frame(
      component = names(es),
      value = unname(as.character(es)),
      stringsAsFactors = FALSE
    ),
    P_EXTSOFT
  )

  write_csv_utf8(
    data.frame(
      order = seq_along(.libPaths()),
      libpath = normalizePath(.libPaths(), winslash = "/", mustWork = FALSE),
      stringsAsFactors = FALSE
    ),
    P_LIBPATHS
  )

  locale_categories <- c(
    "LC_ALL", "LC_COLLATE", "LC_CTYPE", "LC_MONETARY",
    "LC_NUMERIC", "LC_TIME"
  )

  write_csv_utf8(
    data.frame(
      category = locale_categories,
      value = vapply(locale_categories, Sys.getlocale, character(1)),
      stringsAsFactors = FALSE
    ),
    P_LOCALE
  )

  write_csv_utf8(
    data.frame(
      variable = thread_vars,
      value = unname(thread_values),
      stringsAsFactors = FALSE
    ),
    P_THREADS
  )

  seurat_installed <- "Seurat" %in% installed

  runtime <- data.frame(
    key = c(
      "R.version",
      "Bioconductor.version",
      "limma.version",
      "edgeR.version",
      "Matrix.version",
      "SeuratObject.version",
      "full_Seurat_installed",
      "full_Seurat_loaded",
      "project_library",
      "R_LIBS_USER",
      "RNGkind.kind",
      "RNGkind.normal.kind",
      "RNGkind.sample.kind",
      "BLAS",
      "LAPACK"
    ),
    value = c(
      as.character(getRversion()),
      bioc_version,
      as.character(utils::packageVersion("limma")),
      as.character(utils::packageVersion("edgeR")),
      as.character(utils::packageVersion("Matrix")),
      as.character(utils::packageVersion("SeuratObject")),
      ifelse(seurat_installed, "YES", "NO"),
      ifelse("Seurat" %in% loadedNamespaces(), "YES", "NO"),
      normalizePath(PROJECT_LIB, winslash = "/", mustWork = TRUE),
      Sys.getenv("R_LIBS_USER"),
      rng_now[1L], rng_now[2L], rng_now[3L],
      if (!is.null(si$BLAS)) as.character(si$BLAS) else "",
      if (!is.null(si$LAPACK)) as.character(si$LAPACK) else ""
    ),
    stringsAsFactors = FALSE
  )

  write_csv_utf8(runtime, P_RUNTIME)

  PASS(
    "RUNTIME_ENVIRONMENT",
    paste(
      "R", getRversion(),
      "; Bioconductor", bioc_version,
      "; limma", utils::packageVersion("limma"),
      "; edgeR", utils::packageVersion("edgeR"),
      "; Matrix", utils::packageVersion("Matrix"),
      "; SeuratObject", utils::packageVersion("SeuratObject")
    )
  )

  PASS(
    "THREAD_AND_RNG",
    "OMP/OPENBLAS/MKL/BLIS threads=1; RNGkind=Mersenne-Twister/Inversion/Rejection"
  )

  # -----------------------------------------------------------------------
  # 4. Synthetic-only deterministic smoke test
  # -----------------------------------------------------------------------
  smoke <- run_synthetic_smoke()
  write_csv_utf8(smoke, P_SMOKE)

  if (!all(smoke$repeated_run_exact_identical)) {
    HOLD("SYNTHETIC_MROAST_SMOKE", "Synthetic repeated mroast calls are not exact")
  }

  PASS(
    "SYNTHETIC_MROAST_SMOKE",
    "snRNA-style edgeR->voom->mroast and Xenium-style logCPM->mroast repeated exactly at frozen seed"
  )

  # Refresh session provenance after limma/edgeR have actually been exercised.
  si <- sessionInfo()
  writeLines(capture.output(si), P_SESSION, useBytes = TRUE)

  # -----------------------------------------------------------------------
  # 5. Frozen labels
  # -----------------------------------------------------------------------
  labels <- read_csv_req(P_LABELS, "READ_FROZEN_LABELS")
  require_cols(labels, c("dataset", "field", "role", "label"), "FROZEN_LABEL_COLUMNS")

  get_labels <- function(dataset, field, n_expected) {
    z <- as.character(
      labels$label[
        labels$dataset == dataset &
          labels$field == field
      ]
    )

    if (length(z) != n_expected || anyDuplicated(z) || anyNA(z) || any(!nzchar(z))) {
      HOLD(
        paste0("FROZEN_LABEL_", field),
        paste(field, "expected", n_expected, "unique exact labels; found", length(z))
      )
    }

    z
  }

  sn_broad <- get_labels("GSE345646_snRNA", "Names", 12L)
  sn_fine <- get_labels("GSE345646_snRNA", "Subnames_manual", 34L)
  xe_broad <- get_labels("GSE345643_Xenium_ambient_corrected", "cell_type_rctd_doublet", 12L)
  xe_fine <- get_labels("GSE345643_Xenium_ambient_corrected", "cell_type_seurat", 34L)

  if (!identical(sn_broad, xe_broad)) {
    HOLD("FROZEN_BROAD_LABEL_MATCH", "Frozen 12 broad labels/order are not exact cross-modal match")
  }

  PASS("FROZEN_LABEL_AUTHORITY", "12 broad + 34 snRNA fine + 34 Xenium fine exact frozen labels loaded")

  # -----------------------------------------------------------------------
  # 6. Real RDS structural + metadata-only feasibility inputs
  # -----------------------------------------------------------------------
  sn <- process_seurat_structure(
    path = SN_RDS,
    dataset_name = "SNRNA",
    assay_name = "RNA",
    layer_specs = list(
      list(layer = "counts", dim = c(32938L, 61398L)),
      list(layer = "data", dim = c(32938L, 61398L))
    ),
    annotation_specs = list(
      list(field = "Names", labels = sn_broad),
      list(field = "Subnames_manual", labels = sn_fine)
    ),
    expected_cells = 61398L,
    expected_patients = 11L
  )

  xe <- process_seurat_structure(
    path = XE_RDS,
    dataset_name = "XENIUM",
    assay_name = "Xenium",
    layer_specs = list(
      list(layer = "counts", dim = c(477L, 568651L))
    ),
    annotation_specs = list(
      list(field = "cell_type_rctd_doublet", labels = xe_broad),
      list(field = "cell_type_seurat", labels = xe_fine)
    ),
    expected_cells = 568651L,
    expected_patients = 9L
  )

  layer_manifest <- rbind(sn$layer_manifest, xe$layer_manifest)
  write_csv_utf8(layer_manifest, P_LAYER)

  PASS(
    "ASSAY5_SPARSE_LAYER_IDENTITY",
    "snRNA RNA/counts+data and Xenium Xenium/counts are sparse; dimensions exact; expression colnames == metadata rownames; names unique"
  )

  # -----------------------------------------------------------------------
  # 7. Patient/group role resolution and cross-modal crosswalk
  # -----------------------------------------------------------------------
  role_candidates <- rbind(
    build_role_candidate_rows("SNRNA", sn$group_role, sn$patient_classes),
    build_role_candidate_rows("XENIUM", xe$group_role, xe$patient_classes)
  )
  write_csv_utf8(role_candidates, P_ROLE_CAND)

  chosen <- select_crossmodal_patient_pair(sn$patient_classes, xe$patient_classes)

  sn_pc <- sn$patient_classes[[chosen["sn_class"]]]
  xe_pc <- xe$patient_classes[[chosen["xe_class"]]]

  role_freeze <- data.frame(
    dataset = c("SNRNA", "SNRNA", "XENIUM", "XENIUM"),
    role = c("GROUP", "PATIENT", "GROUP", "PATIENT"),
    canonical_metadata_column = c(
      sn$group_role$canonical,
      sn_pc$aliases[1L],
      xe$group_role$canonical,
      xe_pc$aliases[1L]
    ),
    equivalent_aliases = c(
      paste(sn$group_role$aliases, collapse = "|"),
      paste(sn_pc$aliases, collapse = "|"),
      paste(xe$group_role$aliases, collapse = "|"),
      paste(xe_pc$aliases, collapse = "|")
    ),
    resolution_rule = c(
      "single equivalence class with exact complete values {NF,pRV,RVF}",
      "unique cross-modal patient identity class: 11 SN; 9 XE subset; SN extras exactly {1392,1681}; patient->group exact",
      "single equivalence class with exact complete values {NF,pRV,RVF}",
      "unique cross-modal patient identity class: 11 SN; 9 XE subset; SN extras exactly {1392,1681}; patient->group exact"
    ),
    stringsAsFactors = FALSE
  )
  write_csv_utf8(role_freeze, P_ROLE_FREEZE)

  sn_pat <- sn_pc$vector
  xe_pat <- xe_pc$vector
  sn_grp <- sn$group_role$vector
  xe_grp <- xe$group_role$vector

  sn_pair <- unique(data.frame(patient_id = sn_pat, snRNA_group = sn_grp, stringsAsFactors = FALSE))
  xe_pair <- unique(data.frame(patient_id = xe_pat, Xenium_group = xe_grp, stringsAsFactors = FALSE))

  all_pat <- sort(unique(c(sn_pair$patient_id, xe_pair$patient_id)), method = "radix")

  cross <- data.frame(
    patient_id = all_pat,
    in_snRNA = all_pat %in% sn_pair$patient_id,
    snRNA_group = sn_pair$snRNA_group[match(all_pat, sn_pair$patient_id)],
    in_Xenium = all_pat %in% xe_pair$patient_id,
    Xenium_group = xe_pair$Xenium_group[match(all_pat, xe_pair$patient_id)],
    stringsAsFactors = FALSE
  )

  cross$shared_patient <- cross$in_snRNA & cross$in_Xenium
  cross$group_match_if_shared <- ifelse(
    cross$shared_patient,
    cross$snRNA_group == cross$Xenium_group,
    NA
  )

  write_csv_utf8(cross, P_PATIENT_CROSS)

  if (
    sum(cross$in_snRNA) != 11L ||
      sum(cross$in_Xenium) != 9L ||
      sum(cross$shared_patient) != 9L ||
      !setequal(cross$patient_id[cross$in_snRNA & !cross$in_Xenium], c("1392", "1681")) ||
      !all(cross$group_match_if_shared[cross$shared_patient])
  ) {
    HOLD("PATIENT_CROSSWALK", "Patient crosswalk failed frozen 11/9/shared9/extras1392+1681/group-match guards")
  }

  PASS(
    "PATIENT_CROSSWALK",
    "snRNA=11; Xenium=9; shared=9; snRNA-only={1392,1681}; shared patient groups exact"
  )

  # -----------------------------------------------------------------------
  # 8. Metadata-only patient×group×annotation counts: BROAD + FINE
  # -----------------------------------------------------------------------
  sn_counts_b <- build_cell_count_manifest(
    modality = "SNRNA",
    annotation_level = "BROAD",
    annotation_field = "Names",
    frozen_labels = sn_broad,
    patient_vector = sn_pat,
    group_vector = sn_grp,
    annotation_vector = sn$annotations$Names
  )

  sn_counts_f <- build_cell_count_manifest(
    modality = "SNRNA",
    annotation_level = "FINE",
    annotation_field = "Subnames_manual",
    frozen_labels = sn_fine,
    patient_vector = sn_pat,
    group_vector = sn_grp,
    annotation_vector = sn$annotations$Subnames_manual
  )

  xe_counts_b <- build_cell_count_manifest(
    modality = "XENIUM",
    annotation_level = "BROAD",
    annotation_field = "cell_type_rctd_doublet",
    frozen_labels = xe_broad,
    patient_vector = xe_pat,
    group_vector = xe_grp,
    annotation_vector = xe$annotations$cell_type_rctd_doublet
  )

  xe_counts_f <- build_cell_count_manifest(
    modality = "XENIUM",
    annotation_level = "FINE",
    annotation_field = "cell_type_seurat",
    frozen_labels = xe_fine,
    patient_vector = xe_pat,
    group_vector = xe_grp,
    annotation_vector = xe$annotations$cell_type_seurat
  )

  cell_manifest <- rbind(sn_counts_b, sn_counts_f, xe_counts_b, xe_counts_f)
  write_csv_utf8(cell_manifest, P_CELL_COUNTS)

  # Every real cell must contribute to exactly one label at each annotation level.
  count_checks <- aggregate(
    cell_count ~ modality + annotation_level,
    data = cell_manifest,
    FUN = sum
  )

  expected_totals <- c(
    "SNRNA|BROAD" = 61398L,
    "SNRNA|FINE" = 61398L,
    "XENIUM|BROAD" = 568651L,
    "XENIUM|FINE" = 568651L
  )

  for (i in seq_len(nrow(count_checks))) {
    key <- paste(count_checks$modality[i], count_checks$annotation_level[i], sep = "|")
    if (as.integer(count_checks$cell_count[i]) != expected_totals[[key]]) {
      HOLD(
        "CELL_COUNT_CONSERVATION",
        paste(key, "expected", expected_totals[[key]], "found", count_checks$cell_count[i])
      )
    }
  }

  PASS(
    "CELL_COUNT_MANIFEST",
    "BROAD/FINE patient×label counts conserve 61,398 snRNA nuclei and 568,651 Xenium cells at each annotation level"
  )

  # -----------------------------------------------------------------------
  # 9. Design-feasibility blocks derived ONLY from the frozen 840 registry
  # -----------------------------------------------------------------------
  block_cols <- c(
    "modality",
    "annotation_level",
    "annotation_field",
    "contrast_id",
    "contrast_expression",
    "contrast_numerator",
    "contrast_denominator",
    "factor_levels",
    "contrast_vector",
    "label"
  )

  require_cols(reg, block_cols, "REGISTRY_BLOCK_COLUMNS")

  blocks <- unique(reg[, block_cols, drop = FALSE])

  # Expected: SN broad 36 + SN fine 34 + XE broad 36 + XE fine 34 = 140.
  if (nrow(blocks) != 140L) {
    HOLD("DESIGN_BLOCK_COUNT", paste("Expected 140 frozen label×contrast blocks; found", nrow(blocks)))
  }

  design_feas <- make_design_feasibility(blocks, cell_manifest)
  write_csv_utf8(design_feas, P_DESIGN)

  summary <- aggregate(
    patient_design_feasible ~ modality + annotation_level + contrast_id,
    data = design_feas,
    FUN = function(x) c(total = length(x), feasible = sum(x))
  )

  # Flatten aggregate matrix column.
  design_summary <- data.frame(
    modality = summary$modality,
    annotation_level = summary$annotation_level,
    contrast_id = summary$contrast_id,
    n_frozen_labels = summary$patient_design_feasible[, "total"],
    n_patient_design_feasible = summary$patient_design_feasible[, "feasible"],
    n_patient_design_unassessable = (
      summary$patient_design_feasible[, "total"] -
        summary$patient_design_feasible[, "feasible"]
    ),
    stringsAsFactors = FALSE
  )

  write_csv_utf8(design_summary, P_DESIGN_SUM)

  # Map the structural feasibility back to all 840 registry rows.
  feas_key <- paste(
    design_feas$modality,
    design_feas$annotation_level,
    design_feas$contrast_id,
    design_feas$label,
    sep = "|"
  )

  reg_key <- paste(
    reg$modality,
    reg$annotation_level,
    reg$contrast_id,
    reg$label,
    sep = "|"
  )

  m <- match(reg_key, feas_key)

  if (anyNA(m)) {
    HOLD("REGISTRY_FEASIBILITY_JOIN", "At least one 840-registry row lacks design-feasibility block")
  }

  reg_feas <- data.frame(
    test_ordinal = reg$test_ordinal,
    test_key = reg$test_key,
    test_seed = reg$test_seed,
    family_id = reg$family_id,
    modality = reg$modality,
    annotation_level = reg$annotation_level,
    contrast_id = reg$contrast_id,
    label = reg$label,
    program = reg$program,
    patient_design_feasible = design_feas$patient_design_feasible[m],
    eligible_patients_numerator = design_feas$eligible_patients_numerator[m],
    eligible_patients_denominator = design_feas$eligible_patients_denominator[m],
    final_program_assessability_determined = FALSE,
    PValue_computed = FALSE,
    BH_computed = FALSE,
    scientific_classification_computed = FALSE,
    stringsAsFactors = FALSE
  )

  if (nrow(reg_feas) != 840L) {
    HOLD("REGISTRY_FEASIBILITY_NROW", paste("Expected 840; found", nrow(reg_feas)))
  }

  write_csv_utf8(reg_feas, P_REG_FEAS)

  PASS(
    "DESIGN_FEASIBILITY",
    paste(
      "140 frozen modality×annotation×contrast×label blocks assessed using metadata only;",
      sum(design_feas$patient_design_feasible),
      "patient-design feasible;",
      sum(!design_feas$patient_design_feasible),
      "structurally unassessable before program-level expression checks"
    )
  )

  PASS(
    "REGISTRY_FEASIBILITY_MAP",
    "840/840 frozen registry rows mapped to metadata-only patient-design feasibility; no P values/BH/classification"
  )

  # -----------------------------------------------------------------------
  # 10. Final hard boundary check
  # -----------------------------------------------------------------------
  # This script contains no real-data calls to DGEList/filterByExpr/voom/mroast.
  # The only such calls occurred inside run_synthetic_smoke().
  PASS(
    "ZERO_REAL_LOCALIZATION_RESULTS",
    "Real RDS used only for metadata + sparse layer structure/dimnames; no real pseudobulk/filterByExpr/voom/mroast/PValue/BH/classification"
  )

  final_state <<- "PASS_STEP4E_RUNTIME_AND_DESIGN_FEASIBILITY_PREFLIGHT_READY_FOR_INDEPENDENT_AUDIT"
  PASS("FINAL_GATE", final_state)
}

rc <- 0L

tryCatch(
  main(),
  error = function(e) {
    cat("\nERROR/HOLD:\n", conditionMessage(e), "\n", sep = "")
    if (!grepl("^HOLD:", conditionMessage(e))) {
      add_audit("UNEXPECTED_RUNTIME_ERROR", "FAIL", conditionMessage(e))
    }
    rc <<- 2L
  }
)

finalize()

cat("\nFINAL STATE: ", final_state, "\n", sep = "")
cat("RUN DIR: ", RUNDIR, "\n", sep = "")
cat("STAGING DIR: ", STAGING, "\n", sep = "")
quit(save = "no", status = rc)
