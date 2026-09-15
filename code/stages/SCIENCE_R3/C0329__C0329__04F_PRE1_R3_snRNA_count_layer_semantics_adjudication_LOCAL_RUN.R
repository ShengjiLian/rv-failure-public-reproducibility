# ---- RV PUBLIC PRIMARY DAG GATE9J REWRITE V1.0 ----
# source_id=C0329
# rewrite_scope=TIMESTAMP_PLUS_HISTORY_CHAIN
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


# R3 Step4F-PRE1
# snRNA COUNT-LAYER SEMANTICS CHARACTERIZATION / ADJUDICATION INPUT
#
# Trigger:
#   Step4F V1.0 (run 20260910_170154) stopped before any real localization
#   test because an implementation-added integer-count guard found fractional
#   values in snRNA RNA/counts.
#
# IMPORTANT:
#   The integer-only guard was NOT part of the frozen Step4D/V1.3 contract.
#   However, the frozen Step4D wording calls the snRNA source
#   "RNA_RAW_COUNTS / unmodified raw UMI", while the observed object is
#   fractional. We therefore characterize the actual processed count layer
#   BEFORE any corrected Step4F execution.
#
# THIS GATE IS ZERO-RESULT:
#   - NO disease contrast
#   - NO patient×annotation pseudobulk
#   - NO filterByExpr
#   - NO TMM/voom
#   - NO mroast
#   - NO P values / BH
#   - NO localization classification
#
# It reads expression values only to characterize source semantics.

options(stringsAsFactors = FALSE, warn = 1)

ROOT <- RV_PROJECT_ROOT
RES <- file.path(ROOT, "results", "R3_GSE249696")
UPLOAD <- file.path(ROOT, "upload")
PROJECT_LIB <- file.path(RV_PROJECT_ROOT, "R_library/R-4.6")

SN_RDS <- file.path(RV_PROJECT_ROOT, "data/raw/GSE345646/GSE345646_snRV_ref.rds")

P_METHOD <- file.path(RES, "R3_STEP4D_localization_method_contract.csv")
P_V13_GUARDS <- rv_stage_file(
  file.path(RES, "R3_STEP4D_V1_3_runs"),
  "R3_STEP4D_V1_3_STEP4F_FAIL_CLOSED_GUARDS.csv"
)

P_PREHASH <- Sys.getenv("R3_STEP4F_PRE1_PREHASH", unset = "")
if (!nzchar(P_PREHASH)) {
  stop("Run through the PRE1 BAT; R3_STEP4F_PRE1_PREHASH is missing.", call. = FALSE)
}

args <- commandArgs(trailingOnly = TRUE)
RUN_ID <- if (length(args) >= 1L && nzchar(args[1L])) args[1L] else format(Sys.time(), "%Y%m%d_%H%M%S")

RUNROOT <- file.path(RES, "R3_STEP4F_PRE1_runs")
RUNDIR <- file.path(RUNROOT, RUN_ID)
STAGING <- file.path(UPLOAD, "R3_STEP4F_PRE1_STAGING")

dir.create(RUNDIR, recursive = TRUE, showWarnings = FALSE)
dir.create(UPLOAD, recursive = TRUE, showWarnings = FALSE)
if (dir.exists(STAGING)) unlink(STAGING, recursive = TRUE, force = TRUE)
dir.create(STAGING, recursive = TRUE, showWarnings = FALSE)

P_STATUS <- file.path(RUNDIR, "R3_STEP4F_PRE1_STATUS.txt")
P_AUDIT <- file.path(RUNDIR, "R3_STEP4F_PRE1_audit.csv")
P_INVENTORY <- file.path(RUNDIR, "R3_STEP4F_PRE1_assay_layer_inventory.csv")
P_VALUES <- file.path(RUNDIR, "R3_STEP4F_PRE1_value_semantics.csv")
P_LIB <- file.path(RUNDIR, "R3_STEP4F_PRE1_RNA_counts_library_sums.csv")
P_META <- file.path(RUNDIR, "R3_STEP4F_PRE1_RNA_counts_metadata_concordance.csv")
P_COMPARE <- file.path(RUNDIR, "R3_STEP4F_PRE1_count_layer_pairwise_comparison.csv")
P_PROV <- file.path(RUNDIR, "R3_STEP4F_PRE1_object_provenance_structure.txt")
P_NOTE <- file.path(RUNDIR, "R3_STEP4F_PRE1_ADJUDICATION_NOTE.txt")
P_SESSION <- file.path(RUNDIR, "R3_STEP4F_PRE1_sessionInfo.txt")

audit <- data.frame(
  check_id = character(),
  status = character(),
  detail = character(),
  stringsAsFactors = FALSE
)

add <- function(id, status, detail) {
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

PASS <- function(id, detail) add(id, "PASS", detail)
INFO <- function(id, detail) add(id, "INFO", detail)

HOLD <- function(id, detail) {
  add(id, "FAIL", detail)
  stop(paste0("HOLD: ", detail), call. = FALSE)
}

write_csv <- function(x, p) {
  write.csv(x, p, row.names = FALSE, na = "", fileEncoding = "UTF-8")
}

copy_stage <- function(paths) {
  for (p in unique(paths[file.exists(paths)])) {
    ok <- file.copy(
      p, file.path(STAGING, basename(p)),
      overwrite = TRUE, copy.mode = TRUE, copy.date = TRUE
    )
    if (!isTRUE(ok)) stop(paste("Could not stage:", p), call. = FALSE)
  }
}

final_state <- "HOLD_STEP4F_PRE1_SNRNA_COUNT_LAYER_SEMANTICS"

finalize <- function() {
  try(write_csv(audit, P_AUDIT), silent = TRUE)

  try(writeLines(
    c(
      paste0("RUN_ID=", RUN_ID),
      paste0("FINAL_STATE=", final_state),
      "STEP4F_V1_0=TECHNICAL_HOLD_SUPERSEDED_FOR_EXECUTION",
      "STEP4D_SCIENTIFIC_CONTRACT=NOT_CHANGED_IN_PRE1",
      "STEP4D_V1_3_IMPLEMENTATION_OVERLAY=NOT_CHANGED_IN_PRE1",
      "REAL_SNRNA_EXPRESSION_VALUES_READ_FOR_SOURCE_CHARACTERIZATION=YES_IF_RUNTIME_REACHED",
      "DISEASE_GROUP_COMPARISON=NO",
      "PATIENT_X_ANNOTATION_PSEUDOBULK=NO",
      "FILTERBYEXPR=NO",
      "TMM=NO",
      "VOOM=NO",
      "MROAST=NO",
      "P_VALUE=NO",
      "BH_FDR=NO",
      "LOCALIZATION_CLASSIFICATION=NO",
      "SCIENTIFIC_LOCALIZATION_RESULT=NO"
    ),
    P_STATUS,
    useBytes = TRUE
  ), silent = TRUE)

  try(copy_stage(c(
    P_PREHASH,
    P_STATUS, P_AUDIT, P_INVENTORY, P_VALUES, P_LIB, P_META,
    P_COMPARE, P_PROV, P_NOTE, P_SESSION,
    P_METHOD, P_V13_GUARDS
  )), silent = TRUE)
}
on.exit(finalize(), add = TRUE)

read_csv_req <- function(p, id) {
  if (!file.exists(p)) HOLD(id, paste("Missing:", p))
  if (file.info(p)$size <= 0) HOLD(id, paste("Zero-byte:", p))
  x <- tryCatch(
    read.csv(p, check.names = FALSE, stringsAsFactors = FALSE),
    error = function(e) NULL
  )
  if (is.null(x)) HOLD(id, paste("Could not read:", p))
  x
}

require_cols <- function(x, cols, id) {
  missing <- setdiff(cols, names(x))
  if (length(missing)) HOLD(id, paste("Missing columns:", paste(missing, collapse = ", ")))
}

# Chunked exact numeric characterization avoids large temporary vectors.
characterize_numeric <- function(x, assay, layer, chunk = 2000000L) {
  is_sparse <- inherits(x, "sparseMatrix")
  if (is_sparse) {
    vals <- x@x
    nnz <- length(vals)
    total_slots <- as.double(nrow(x)) * as.double(ncol(x))
  } else if (is.matrix(x)) {
    vals <- as.vector(x)
    nnz <- sum(vals != 0)
    total_slots <- length(vals)
  } else {
    HOLD("LAYER_NUMERIC_CLASS", paste(assay, layer, "unsupported class:", paste(class(x), collapse = "|")))
  }

  n <- length(vals)
  n_nonfinite <- 0
  n_negative <- 0
  n_integerish <- 0
  n_fractional <- 0
  minv <- Inf
  maxv <- -Inf
  minpos <- Inf

  # deterministic sample for distribution summaries; not a scientific sample.
  sample_n <- min(n, 1000000L)
  if (sample_n > 0L) {
    sample_idx <- unique(as.integer(round(seq(1, n, length.out = sample_n))))
    sample_vals <- vals[sample_idx]
    sample_dist <- abs(sample_vals - round(sample_vals))
  } else {
    sample_vals <- numeric()
    sample_dist <- numeric()
  }

  if (n > 0L) {
    starts <- seq.int(1L, n, by = chunk)
    for (s in starts) {
      e <- min(n, s + chunk - 1L)
      v <- vals[s:e]
      fin <- is.finite(v)
      n_nonfinite <- n_nonfinite + sum(!fin)

      vf <- v[fin]
      if (length(vf)) {
        n_negative <- n_negative + sum(vf < 0)
        minv <- min(minv, min(vf))
        maxv <- max(maxv, max(vf))
        pos <- vf[vf > 0]
        if (length(pos)) minpos <- min(minpos, min(pos))

        d <- abs(vf - round(vf))
        ii <- d <= 1e-8
        n_integerish <- n_integerish + sum(ii)
        n_fractional <- n_fractional + sum(!ii)
      }
      rm(v, vf, fin)
    }
  }

  qv <- function(v) {
    if (!length(v)) return(rep(NA_real_, 9L))
    as.numeric(quantile(v, probs = c(0, .01, .05, .25, .5, .75, .95, .99, 1), na.rm = TRUE, names = FALSE, type = 7))
  }

  vq <- qv(sample_vals[is.finite(sample_vals)])
  dq <- qv(sample_dist[is.finite(sample_dist)])

  data.frame(
    assay = assay,
    layer = layer,
    class = paste(class(x), collapse = "|"),
    n_genes = nrow(x),
    n_cells = ncol(x),
    sparse = is_sparse,
    stored_value_count = n,
    matrix_total_slots = total_slots,
    stored_nonzero_fraction_of_matrix = if (total_slots > 0) nnz / total_slots else NA_real_,
    nonfinite_stored_values = n_nonfinite,
    negative_stored_values = n_negative,
    integerish_stored_values_tol_1e_8 = n_integerish,
    fractional_stored_values_tol_1e_8 = n_fractional,
    fractional_fraction_of_finite_stored = if ((n_integerish + n_fractional) > 0) n_fractional / (n_integerish + n_fractional) else NA_real_,
    min_finite_value = if (is.finite(minv)) minv else NA_real_,
    min_positive_value = if (is.finite(minpos)) minpos else NA_real_,
    max_finite_value = if (is.finite(maxv)) maxv else NA_real_,
    sampled_value_q0 = vq[1], sampled_value_q01 = vq[2], sampled_value_q05 = vq[3],
    sampled_value_q25 = vq[4], sampled_value_q50 = vq[5], sampled_value_q75 = vq[6],
    sampled_value_q95 = vq[7], sampled_value_q99 = vq[8], sampled_value_q100 = vq[9],
    sampled_abs_distance_to_integer_q50 = dq[5],
    sampled_abs_distance_to_integer_q95 = dq[7],
    sampled_abs_distance_to_integer_q99 = dq[8],
    sampled_abs_distance_to_integer_max = dq[9],
    stringsAsFactors = FALSE
  )
}

inventory_assays <- function(obj) {
  rows <- list()
  k <- 0L

  # Inventory layer NAMES without pulling every layer into a temporary object.
  # Numeric access is restricted below to RNA/counts, RNA/data and plausible
  # alternate count layers only.
  for (a in names(obj@assays)) {
    ao <- obj[[a]]
    lays <- tryCatch(SeuratObject::Layers(ao), error = function(e) character())
    if (!length(lays)) lays <- ""

    for (ly in lays) {
      k <- k + 1L
      rows[[k]] <- data.frame(
        assay = a,
        assay_class = paste(class(ao), collapse = "|"),
        layer = ly,
        layer_accessed_in_inventory = FALSE,
        numeric_characterization_planned = (
          (a == "RNA" && ly %in% c("counts","data")) ||
          (grepl("decont|cellbender|sct", a, ignore.case = TRUE) && ly == "counts")
        ),
        stringsAsFactors = FALSE
      )
    }
  }

  do.call(rbind, rows)
}

compare_sparse_exact <- function(x, y, name_x, name_y) {
  same_dim <- identical(dim(x), dim(y))
  same_rn <- identical(rownames(x), rownames(y))
  same_cn <- identical(colnames(x), colnames(y))
  same_class <- identical(class(x), class(y))

  exact_sparse_payload <- FALSE
  same_sparse_structure <- FALSE
  sampled_max_abs_difference_if_same_structure <- NA_real_

  if (inherits(x, "dgCMatrix") && inherits(y, "dgCMatrix") &&
      same_dim && same_rn && same_cn) {
    same_sparse_structure <- identical(x@p, y@p) && identical(x@i, y@i)
    exact_sparse_payload <- same_sparse_structure && identical(x@x, y@x)

    if (same_sparse_structure && length(x@x)) {
      n <- length(x@x)
      idx <- unique(as.integer(round(seq(1, n, length.out = min(n, 1000000L)))))
      sampled_max_abs_difference_if_same_structure <- max(abs(x@x[idx] - y@x[idx]))
    } else if (same_sparse_structure) {
      sampled_max_abs_difference_if_same_structure <- 0
    }
  }

  data.frame(
    layer_x = name_x,
    layer_y = name_y,
    same_dimensions = same_dim,
    same_rownames = same_rn,
    same_colnames = same_cn,
    same_R_class = same_class,
    same_dgC_sparse_structure = same_sparse_structure,
    exact_dgCMatrix_payload = exact_sparse_payload,
    sampled_max_abs_difference_if_same_structure = sampled_max_abs_difference_if_same_structure,
    full_sparse_difference_matrix_constructed = FALSE,
    stringsAsFactors = FALSE
  )
}

main <- function() {
  # -------------------------------------------------------------------
  # 1. Exact identity and exact prior HOLD binding.
  # -------------------------------------------------------------------
  ph <- read_csv_req(P_PREHASH, "PREHASH_READ")
  require_cols(ph, c("role","path","exists","expected_sha256","actual_sha256","sha_match"), "PREHASH_COLUMNS")
  if (!all(tolower(as.character(ph$sha_match)) == "true")) {
    HOLD("PREHASH_EXACT", paste("Mismatch:", paste(ph$role[tolower(as.character(ph$sha_match)) != "true"], collapse = " | ")))
  }
  hist_role <- grepl("V10|STEP4F_V1_0", as.character(ph$role), ignore.case=TRUE)
  if(any(hist_role)) {
    HOLD("PREHASH_HISTORICAL_INPUT", paste("Public PREHASH contains forbidden historical Step4F V1.0 role(s):",
         paste(ph$role[hist_role],collapse=" | ")))
  }
  PASS("PREHASH_EXACT", paste(nrow(ph), "/", nrow(ph), "current-authority source identities PASS"))
  PASS("HISTORICAL_STEP4F_V1_0_REPLAYED",
       "NO — failed integer-only V1.0 execution remains provenance only")

  # -------------------------------------------------------------------
  # 2. Demonstrate that integer-only guard is not in frozen V1.3 guards.
  # -------------------------------------------------------------------
  guards <- read_csv_req(P_V13_GUARDS, "V13_GUARDS_READ")
  if (nrow(guards) != 12L || any(!grepl("^G[0-9]{2}_", guards$guard_id))) {
    HOLD("V13_GUARD_SET", "Frozen V1.3 guard set is not exact 12-row form")
  }

  integer_guard_tokens <- grepl("integer", tolower(paste(guards$guard_id, guards$check_semantics)))
  if (any(integer_guard_tokens)) {
    HOLD("INTEGER_GUARD_AUTHORITY", "Frozen V1.3 unexpectedly contains an integer-only guard")
  }
  PASS("INTEGER_GUARD_AUTHORITY", "Frozen V1.3 has 12 guards and no integer-only snRNA count requirement")

  method <- read_csv_req(P_METHOD, "METHOD_READ")
  sn_count_row <- method[method$scope == "SNRNA" & method$parameter == "COUNT_INPUT", , drop = FALSE]
  if (nrow(sn_count_row) != 1L) HOLD("SNRNA_COUNT_INPUT_ROW", "Frozen SNRNA COUNT_INPUT row not unique")
  INFO(
    "SNRNA_COUNT_INPUT_WORDING_UNDER_ADJUDICATION",
    paste("frozen_value=", sn_count_row$frozen_value, "; rationale=", sn_count_row$rationale)
  )

  # -------------------------------------------------------------------
  # 3. Runtime — no repair/install.
  # -------------------------------------------------------------------
  if (!identical(as.character(getRversion()), "4.6.1")) {
    HOLD("R_VERSION", paste("Expected R 4.6.1; observed", getRversion()))
  }
  expected_lib <- normalizePath(PROJECT_LIB, winslash = "/", mustWork = TRUE)
  if (tolower(normalizePath(.libPaths()[1L], winslash = "/", mustWork = FALSE)) != tolower(expected_lib)) {
    HOLD("PROJECT_LIBRARY", "Project library is not first .libPaths()")
  }

  req <- c("Matrix", "SeuratObject")
  miss <- req[!vapply(req, requireNamespace, logical(1), quietly = TRUE)]
  if (length(miss)) HOLD("RUNTIME_PACKAGES", paste("Missing/unloadable:", paste(miss, collapse = ", ")))
  if (as.character(packageVersion("SeuratObject")) != "5.4.0") {
    HOLD("SEURATOBJECT_VERSION", paste("Observed", packageVersion("SeuratObject")))
  }

  suppressPackageStartupMessages(library(Matrix))
  suppressPackageStartupMessages(library(SeuratObject))
  if ("Seurat" %in% loadedNamespaces()) HOLD("FULL_SEURAT", "Full Seurat namespace loaded unexpectedly")
  PASS("RUNTIME", "R 4.6.1; Matrix + SeuratObject 5.4.0; no full Seurat")

  # -------------------------------------------------------------------
  # 4. Load exact snRNA object for source semantics only.
  # -------------------------------------------------------------------
  cat("Loading frozen snRNA RDS for source-semantics characterization...\n")
  obj <- readRDS(SN_RDS)

  if (!inherits(obj, "Seurat")) HOLD("OBJECT_CLASS", paste("Expected Seurat; observed", paste(class(obj), collapse = "|")))
  if (ncol(obj) != 61398L) HOLD("OBJECT_NCELL", paste("Expected 61,398; found", ncol(obj)))
  if (!"RNA" %in% names(obj@assays)) HOLD("RNA_ASSAY", "RNA assay absent")

  inventory <- inventory_assays(obj)
  write_csv(inventory, P_INVENTORY)
  PASS("ASSAY_LAYER_INVENTORY", paste("Assays:", paste(names(obj@assays), collapse = ", ")))

  # RNA/counts is the frozen intended source, but its semantics are under adjudication.
  rna_counts <- SeuratObject::LayerData(obj[["RNA"]], layer = "counts")
  if (!inherits(rna_counts, "sparseMatrix")) HOLD("RNA_COUNTS_SPARSE", "RNA/counts is not sparse")
  if (!identical(colnames(rna_counts), rownames(obj@meta.data))) HOLD("RNA_COUNTS_META_ID", "RNA/counts columns != metadata rows")
  if (anyDuplicated(rownames(rna_counts)) || anyDuplicated(colnames(rna_counts))) HOLD("RNA_COUNTS_NAMES", "RNA/counts dimnames duplicated")

  val_rows <- list()
  val_rows[[1L]] <- characterize_numeric(rna_counts, "RNA", "counts")

  # Characterize RNA/data as a semantic comparator, without using it analytically.
  if ("data" %in% SeuratObject::Layers(obj[["RNA"]])) {
    rna_data <- SeuratObject::LayerData(obj[["RNA"]], layer = "data")
    val_rows[[length(val_rows) + 1L]] <- characterize_numeric(rna_data, "RNA", "data")
  } else {
    rna_data <- NULL
  }

  # Characterize count layers of plausible alternate assays if present.
  alt_count_layers <- list()
  for (a in names(obj@assays)) {
    if (a == "RNA") next
    if (!grepl("decont|cellbender|sct", a, ignore.case = TRUE)) next
    lays <- SeuratObject::Layers(obj[[a]])
    if (!"counts" %in% lays) next

    x <- SeuratObject::LayerData(obj[[a]], layer = "counts")
    val_rows[[length(val_rows) + 1L]] <- characterize_numeric(x, a, "counts")
    alt_count_layers[[a]] <- x
  }

  vals <- do.call(rbind, val_rows)
  write_csv(vals, P_VALUES)

  rna_row <- vals[vals$assay == "RNA" & vals$layer == "counts", , drop = FALSE]
  if (rna_row$nonfinite_stored_values != 0L) HOLD("RNA_COUNTS_FINITE", "RNA/counts has nonfinite stored values")
  if (rna_row$negative_stored_values != 0L) HOLD("RNA_COUNTS_NONNEGATIVE", "RNA/counts has negative stored values")

  if (rna_row$fractional_stored_values_tol_1e_8 <= 0L) {
    HOLD("RNA_COUNTS_FRACTIONAL_REPRODUCTION", "V1.0 reported fractional values but PRE1 cannot reproduce any fractional RNA/counts values")
  }

  PASS(
    "RNA_COUNTS_FRACTIONAL_REPRODUCTION",
    paste(
      "Fractional RNA/counts reproduced exactly at tol=1e-8:",
      rna_row$fractional_stored_values_tol_1e_8,
      "stored values;",
      sprintf("%.6f%%", 100 * rna_row$fractional_fraction_of_finite_stored)
    )
  )

  # -------------------------------------------------------------------
  # 5. Count-scale diagnostics: per-cell library sums and nCount_RNA.
  # -------------------------------------------------------------------
  lib <- Matrix::colSums(rna_counts)
  if (any(!is.finite(lib)) || any(lib < 0)) HOLD("RNA_LIBRARY_SUMS", "RNA/counts column sums nonfinite/negative")

  q <- as.numeric(quantile(lib, probs = c(0,.01,.05,.25,.5,.75,.95,.99,1), names = FALSE))
  lib_summary <- data.frame(
    n_cells = length(lib),
    n_zero_library_cells = sum(lib == 0),
    min = q[1], q01 = q[2], q05 = q[3], q25 = q[4], median = q[5],
    q75 = q[6], q95 = q[7], q99 = q[8], max = q[9],
    total_sum = sum(lib),
    stringsAsFactors = FALSE
  )
  write_csv(lib_summary, P_LIB)

  meta_rows <- list()
  if ("nCount_RNA" %in% names(obj@meta.data)) {
    m <- suppressWarnings(as.numeric(obj@meta.data$nCount_RNA))
    if (length(m) != length(lib)) HOLD("NCOUNT_RNA_LENGTH", "nCount_RNA length mismatch")

    d <- m - lib
    exact <- is.finite(m) & is.finite(lib) & abs(d) <= 1e-8
    meta_rows[[1L]] <- data.frame(
      metadata_field = "nCount_RNA",
      n_cells = length(m),
      n_nonfinite_metadata = sum(!is.finite(m)),
      exact_or_tol1e8_matches = sum(exact),
      match_fraction = mean(exact),
      max_abs_difference = if (all(is.finite(d))) max(abs(d)) else NA_real_,
      pearson_correlation = if (all(is.finite(m)) && sd(m) > 0 && sd(lib) > 0) cor(m, lib) else NA_real_,
      interpretation = "STRUCTURAL_COUNT_SCALE_CONCORDANCE_ONLY",
      stringsAsFactors = FALSE
    )
  } else {
    meta_rows[[1L]] <- data.frame(
      metadata_field = "nCount_RNA",
      n_cells = ncol(obj),
      n_nonfinite_metadata = NA_integer_,
      exact_or_tol1e8_matches = NA_integer_,
      match_fraction = NA_real_,
      max_abs_difference = NA_real_,
      pearson_correlation = NA_real_,
      interpretation = "FIELD_ABSENT",
      stringsAsFactors = FALSE
    )
  }
  meta_conc <- do.call(rbind, meta_rows)
  write_csv(meta_conc, P_META)
  INFO(
    "RNA_NCOUNT_CONCORDANCE",
    paste(
      "nCount_RNA match_fraction=", meta_conc$match_fraction[1L],
      "; correlation=", meta_conc$pearson_correlation[1L]
    )
  )

  # -------------------------------------------------------------------
  # 6. Compare plausible count-layer alternatives without dense matrices.
  # -------------------------------------------------------------------
  cmp <- list()
  k <- 0L

  if (length(alt_count_layers)) {
    for (a in names(alt_count_layers)) {
      x <- alt_count_layers[[a]]
      if (inherits(rna_counts, "dgCMatrix") && inherits(x, "dgCMatrix")) {
        k <- k + 1L
        cmp[[k]] <- compare_sparse_exact(rna_counts, x, "RNA/counts", paste0(a, "/counts"))
      }
    }
  }

  if (length(cmp)) {
    cmp_df <- do.call(rbind, cmp)
  } else {
    cmp_df <- data.frame(
      layer_x = character(), layer_y = character(),
      same_dimensions = logical(), same_rownames = logical(),
      same_colnames = logical(), same_R_class = logical(),
      same_dgC_sparse_structure = logical(),
      exact_dgCMatrix_payload = logical(),
      sampled_max_abs_difference_if_same_structure = numeric(),
      full_sparse_difference_matrix_constructed = logical(),
      stringsAsFactors = FALSE
    )
  }
  write_csv(cmp_df, P_COMPARE)

  # -------------------------------------------------------------------
  # 7. Structural provenance breadcrumbs from the object itself.
  # -------------------------------------------------------------------
  command_names <- tryCatch(names(obj@commands), error = function(e) character())
  misc_names <- tryCatch(names(obj@misc), error = function(e) character())

  writeLines(
    c(
      "R3 STEP4F-PRE1 — OBJECT PROVENANCE STRUCTURE",
      paste0("RUN_ID=", RUN_ID),
      paste0("object_class=", paste(class(obj), collapse = "|")),
      paste0("n_cells=", ncol(obj)),
      paste0("assays=", paste(names(obj@assays), collapse = "|")),
      paste0("command_names=", paste(command_names, collapse = "|")),
      paste0("misc_names=", paste(misc_names, collapse = "|")),
      paste0("metadata_columns=", paste(names(obj@meta.data), collapse = "|")),
      "",
      "No disease-group contrast or expression inference was performed."
    ),
    P_PROV,
    useBytes = TRUE
  )

  # -------------------------------------------------------------------
  # 8. PRE1 interpretation boundary.
  # -------------------------------------------------------------------
  writeLines(
    c(
      "R3 STEP4F-PRE1 — ADJUDICATION NOTE",
      paste0("RUN_ID=", RUN_ID),
      "",
      "FACTS ESTABLISHED LOCALLY:",
      "- Step4F V1.0 stopped before real pseudobulk/model/test results.",
      "- The V1.0 integer-only snRNA guard was not part of the frozen V1.3 12-guard set.",
      "- RNA/counts fractional-value status has been directly characterized.",
      "- Assay/layer inventory and plausible alternate count-layer semantics have been recorded.",
      "- RNA/counts per-cell library sums and nCount_RNA concordance have been recorded.",
      "",
      "NOT DECIDED BY THIS LOCAL SCRIPT:",
      "- Whether frozen Step4D wording 'unmodified raw UMI' accurately describes the deposited processed object.",
      "- Whether a version-forward source-semantics correction is required.",
      "- Whether RNA/counts remains the correct count-scale input for the already-frozen edgeR/TMM/voom pipeline.",
      "",
      "Those decisions require independent audit together with the official public preprocessing/source documentation.",
      "",
      "NO LOCALIZATION SCIENTIFIC RESULT WAS PRODUCED."
    ),
    P_NOTE,
    useBytes = TRUE
  )

  writeLines(capture.output(sessionInfo()), P_SESSION, useBytes = TRUE)

  PASS("ZERO_RESULT_BOUNDARY", "No disease contrast, pseudobulk, filterByExpr, TMM, voom, mroast, P, BH, or localization classification")
  final_state <<- "PASS_STEP4F_PRE1_SNRNA_COUNT_LAYER_CHARACTERIZATION_READY_FOR_INDEPENDENT_ADJUDICATION"
  PASS("FINAL_GATE", final_state)
}

rc <- 0L
tryCatch(
  main(),
  error = function(e) {
    cat("\nERROR/HOLD:\n", conditionMessage(e), "\n", sep = "")
    if (!grepl("^HOLD:", conditionMessage(e))) {
      add("UNEXPECTED_RUNTIME_ERROR", "FAIL", conditionMessage(e))
    }
    rc <<- 2L
  }
)

finalize()
cat("\nFINAL STATE: ", final_state, "\n", sep = "")
cat("RUN DIR: ", RUNDIR, "\n", sep = "")
cat("STAGING DIR: ", STAGING, "\n", sep = "")
quit(save = "no", status = rc)
