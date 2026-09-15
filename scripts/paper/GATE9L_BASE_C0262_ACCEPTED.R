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
# RV Project — GSE345645 Exact R0 Step 1
# v4_LOCAL_RUN — AUTHOR_TX2GENE_FILTER + GEO_PREFIXED_KALLISTO_H5_DISPATCH_REPAIR
#
# PURPOSE
#   H5 -> tximport -> exact input/concordance audit ->
#   DESeqDataSetFromTximport -> estimateSizeFactors ->
#   author filter (normalized count >=5 in >=3 samples) ->
#   SAVE PREFIT CHECKPOINT.
#
# IMPORTANT
#   This file MUST NOT run DESeq().
#   The expensive model fit belongs to Step 2 only.
#
# Frozen project root:
#   D:/RV_project
#
# Final authority directory on PASS:
#   results/R0/v4_LOCAL_RUN/
# ==============================================================================

options(stringsAsFactors = FALSE, warn = 1)

PROJECT_ROOT <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
if (!identical(PROJECT_ROOT, RV_PROJECT_ROOT)) {
  stop("PROJECT ROOT MISMATCH. Expected exactly D:/RV_project; observed: ", PROJECT_ROOT)
}

USER_LIB <- file.path(Sys.getenv("LOCALAPPDATA"), "R", "win-library", "4.6")
if (dir.exists(USER_LIB)) {
  .libPaths(unique(c(USER_LIB, .libPaths())))
}

args <- commandArgs(trailingOnly = TRUE)
ENV_CHECK_ONLY <- "--env-check" %in% args

EXPECTED_R <- "4.6.1"
EXPECTED_BIOC <- "3.23"
EXPECTED_TXIMPORT <- "1.40.0"
EXPECTED_RHDF5 <- "2.56.0"

ALL_REQUIRED_PACKAGES <- c(
  "BiocManager",
  "tximport",
  "rhdf5",
  "DESeq2",
  "ashr",
  "ggplot2",
  "data.table"
)

env_check <- function() {
  cat("============================================================\n")
  cat("RV Project v4_LOCAL_RUN — LOCAL R ENVIRONMENT CHECK\n")
  cat("============================================================\n")
  cat("R executable: ", file.path(R.home("bin"), "R"), "\n", sep = "")
  cat("R version:    ", R.version.string, "\n", sep = "")
  cat("User library: ", USER_LIB, "\n", sep = "")
  cat(".libPaths():\n")
  for (p in .libPaths()) cat("  - ", p, "\n", sep = "")

  failures <- character()

  r_observed <- paste(R.version$major, R.version$minor, sep = ".")
  if (!identical(r_observed, EXPECTED_R)) {
    failures <- c(failures, paste0("R version expected ", EXPECTED_R, ", observed ", r_observed))
  }

  missing <- ALL_REQUIRED_PACKAGES[
    !vapply(ALL_REQUIRED_PACKAGES, requireNamespace, logical(1), quietly = TRUE)
  ]
  if (length(missing)) {
    failures <- c(failures, paste0("Missing package(s): ", paste(missing, collapse = ", ")))
  }

  cat("\nPackage versions:\n")
  for (pkg in ALL_REQUIRED_PACKAGES) {
    if (requireNamespace(pkg, quietly = TRUE)) {
      cat(sprintf("  %-12s %s\n", pkg, as.character(utils::packageVersion(pkg))))
    } else {
      cat(sprintf("  %-12s MISSING\n", pkg))
    }
  }

  if (requireNamespace("BiocManager", quietly = TRUE)) {
    bioc_observed <- as.character(BiocManager::version())
    cat("Bioconductor:  ", bioc_observed, "\n", sep = "")
    if (!identical(bioc_observed, EXPECTED_BIOC)) {
      failures <- c(
        failures,
        paste0("Bioconductor expected ", EXPECTED_BIOC, ", observed ", bioc_observed)
      )
    }
  }

  if (requireNamespace("tximport", quietly = TRUE)) {
    v <- as.character(utils::packageVersion("tximport"))
    if (!identical(v, EXPECTED_TXIMPORT)) {
      failures <- c(failures, paste0("tximport expected ", EXPECTED_TXIMPORT, ", observed ", v))
    }
  }

  if (requireNamespace("rhdf5", quietly = TRUE)) {
    v <- as.character(utils::packageVersion("rhdf5"))
    if (!identical(v, EXPECTED_RHDF5)) {
      failures <- c(failures, paste0("rhdf5 expected ", EXPECTED_RHDF5, ", observed ", v))
    }
  }

  if (length(failures)) {
    cat("\nFINAL_ENV_GATE: LOCAL_R_ENV_HOLD\n")
    for (x in failures) cat("[FAIL] ", x, "\n", sep = "")
    return(FALSE)
  }

  cat("\nFINAL_ENV_GATE: LOCAL_R_ENV_PASS\n")
  TRUE
}

if (ENV_CHECK_ONLY) {
  ok <- env_check()
  quit(save = "no", status = if (ok) 0L else 10L, runLast = FALSE)
}

if (!env_check()) {
  stop("LOCAL_R_ENV_HOLD. No analysis executed.")
}

suppressPackageStartupMessages({
  library(tximport)
  library(rhdf5)
  library(DESeq2)
})

# ------------------------------------------------------------------------------
# Paths
# ------------------------------------------------------------------------------

PROCESSED_DIR <- file.path(PROJECT_ROOT, "data", "processed", "GSE345645")
TXIMPORT_DIR  <- file.path(PROJECT_ROOT, "data", "tximport", "GSE345645")
H5_DIR        <- file.path(TXIMPORT_DIR, "h5")
RESULTS_R0    <- file.path(PROJECT_ROOT, "results", "R0")
FINAL_DIR     <- file.path(RESULTS_R0, "v4_LOCAL_RUN")
LOG_DIR       <- file.path(PROJECT_ROOT, "logs")

dir.create(RESULTS_R0, recursive = TRUE, showWarnings = FALSE)
dir.create(LOG_DIR, recursive = TRUE, showWarnings = FALSE)

LOG_FILE <- file.path(LOG_DIR, "R0_STEP1_v4_LOCAL_RUN.log")
if (file.exists(LOG_FILE)) {
  old_stamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  old_target <- file.path(
    LOG_DIR,
    paste0("R0_STEP1_v4_LOCAL_RUN_", old_stamp, "_previous.log")
  )
  file.rename(LOG_FILE, old_target)
}

log_line <- function(...) {
  txt <- paste0(..., collapse = "")
  line <- paste0(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), " | ", txt)
  cat(line, "\n", sep = "")
  cat(line, "\n", file = LOG_FILE, append = TRUE, sep = "")
  flush.console()
}

COUNTS_PATH <- file.path(PROCESSED_DIR, "GSE345645_gene_counts.csv.gz")
SV_PATH <- file.path(
  PROCESSED_DIR,
  "GSE345645_subseries1_adult_bulk_surrogate_variables.csv.gz"
)
MANIFEST_PATH <- file.path(RESULTS_R0, "R0_sample_manifest.csv")
TX2GENE_PATH <- file.path(TXIMPORT_DIR, "GSE345645_transcript_to_gene.csv.gz")
TAR_PATH <- file.path(TXIMPORT_DIR, "GSE345645_RAW.tar")

REQUIRED_INPUTS <- c(
  COUNTS_PATH, SV_PATH, MANIFEST_PATH, TX2GENE_PATH, TAR_PATH
)

# ------------------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------------------

canonical_sample_id <- function(x) {
  x <- trimws(as.character(x))
  out <- regmatches(x, regexpr("P[0-9]+", x, perl = TRUE))
  out[!nzchar(out)] <- NA_character_
  out
}

all_sample_tokens <- function(x) {
  regmatches(x, gregexpr("P[0-9]+", x, perl = TRUE))
}

clean_name <- function(x) {
  tolower(gsub("[^a-z0-9]+", "", x))
}

atomic_write_csv <- function(x, path) {
  tmp <- paste0(path, ".tmp_", Sys.getpid())
  utils::write.csv(x, tmp, row.names = FALSE, na = "")
  if (!file.rename(tmp, path)) {
    unlink(tmp)
    stop("Atomic CSV move failed: ", path)
  }
}

atomic_write_lines <- function(x, path) {
  tmp <- paste0(path, ".tmp_", Sys.getpid())
  writeLines(x, tmp, useBytes = TRUE)
  if (!file.rename(tmp, path)) {
    unlink(tmp)
    stop("Atomic text move failed: ", path)
  }
}

atomic_save_rds <- function(x, path) {
  tmp <- paste0(path, ".tmp_", Sys.getpid())
  saveRDS(x, tmp, compress = TRUE)
  if (!file.rename(tmp, path)) {
    unlink(tmp)
    stop("Atomic RDS move failed: ", path)
  }
}

AUDIT <- list()
add_audit <- function(item, expected, observed, pass, notes = "") {
  row <- data.frame(
    item = as.character(item),
    expected = as.character(expected),
    observed = as.character(observed),
    status = if (isTRUE(pass)) "PASS" else "FAIL",
    notes = as.character(notes),
    stringsAsFactors = FALSE
  )
  AUDIT[[length(AUDIT) + 1L]] <<- row
  log_line(
    "[", row$status, "] ", item,
    " | expected=", expected,
    " | observed=", observed
  )
}

require_true <- function(condition, message) {
  if (!isTRUE(condition)) stop(message, call. = FALSE)
}

# ------------------------------------------------------------------------------
# Fail-safe wrapper
# ------------------------------------------------------------------------------

run_step1 <- function() {

  log_line("============================================================")
  log_line("GSE345645 Exact R0 Step 1 — v4_LOCAL_RUN")
  log_line("NO DESeq() WILL BE RUN IN THIS STEP.")
  log_line("============================================================")

  if (dir.exists(FINAL_DIR)) {
    pass_file <- file.path(FINAL_DIR, "R0_EXACT_TXIMPORT_PREP_PASS.txt")
    prefit_file <- file.path(FINAL_DIR, "R0_prefit_dds.rds")
    if (file.exists(pass_file) && file.exists(prefit_file)) {
      log_line("FINAL_GATE: R0_EXACT_TXIMPORT_PREP_ALREADY_PASS__NO_RERUN")
      return(invisible(TRUE))
    }
    stop(
      "Final v4_LOCAL_RUN directory already exists without a complete PASS checkpoint: ",
      FINAL_DIR,
      ". Do not overwrite it automatically."
    )
  }

  build_dir <- file.path(
    RESULTS_R0,
    paste0("_v4_LOCAL_RUN_STEP1_BUILD_", Sys.getpid())
  )
  if (dir.exists(build_dir)) unlink(build_dir, recursive = TRUE, force = TRUE)
  dir.create(build_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit({
    if (dir.exists(build_dir)) unlink(build_dir, recursive = TRUE, force = TRUE)
  }, add = TRUE)

  # --------------------------------------------------------------------------
  # A. Input existence and immutable Step-0 preservation
  # --------------------------------------------------------------------------

  missing_inputs <- REQUIRED_INPUTS[!file.exists(REQUIRED_INPUTS)]
  require_true(
    length(missing_inputs) == 0L,
    paste("Required input(s) missing:", paste(missing_inputs, collapse = "; "))
  )

  add_audit(
    "GSE345645_RAW.tar bytes",
    "2426050560",
    file.info(TAR_PATH)$size,
    identical(as.numeric(file.info(TAR_PATH)$size), 2426050560)
  )

  # --------------------------------------------------------------------------
  # B. Frozen sample manifest
  # --------------------------------------------------------------------------

  manifest <- utils::read.csv(
    MANIFEST_PATH,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  required_manifest_cols <- c("sample_id", "disease_group")
  require_true(
    all(required_manifest_cols %in% names(manifest)),
    paste(
      "R0_sample_manifest.csv missing required columns:",
      paste(setdiff(required_manifest_cols, names(manifest)), collapse = ", ")
    )
  )

  manifest$sample_id <- trimws(as.character(manifest$sample_id))
  manifest$disease_group <- trimws(as.character(manifest$disease_group))

  add_audit("manifest rows", "142", nrow(manifest), nrow(manifest) == 142L)
  add_audit(
    "manifest unique sample_id",
    "142",
    length(unique(manifest$sample_id)),
    !anyNA(manifest$sample_id) &&
      !any(manifest$sample_id == "") &&
      !anyDuplicated(manifest$sample_id) &&
      length(unique(manifest$sample_id)) == 142L
  )
  add_audit(
    "manifest group counts",
    "NF=29;pRV=78;RVF=35",
    paste0(
      "NF=", sum(manifest$disease_group == "NF"), ";",
      "pRV=", sum(manifest$disease_group == "pRV"), ";",
      "RVF=", sum(manifest$disease_group == "RVF")
    ),
    sum(manifest$disease_group == "NF") == 29L &&
      sum(manifest$disease_group == "pRV") == 78L &&
      sum(manifest$disease_group == "RVF") == 35L &&
      all(manifest$disease_group %in% c("NF", "pRV", "RVF"))
  )

  # --------------------------------------------------------------------------
  # C. H5 inventory + patient-ID one-to-one mapping
  # --------------------------------------------------------------------------

  h5_files <- list.files(
    H5_DIR,
    pattern = "\\.h5$",
    recursive = TRUE,
    full.names = TRUE,
    ignore.case = TRUE
  )
  h5_files <- normalizePath(h5_files, winslash = "/", mustWork = TRUE)

  add_audit("H5 count", "142", length(h5_files), length(h5_files) == 142L)
  require_true(length(h5_files) == 142L, "Expected exactly 142 H5 files.")

  token_list <- all_sample_tokens(h5_files)
  token_n <- lengths(token_list)
  add_audit(
    "one canonical P[0-9]+ token per H5 path",
    "142/142 paths have exactly one token",
    paste0(sum(token_n == 1L), "/142"),
    all(token_n == 1L)
  )
  require_true(
    all(token_n == 1L),
    "At least one H5 path has zero or multiple P[0-9]+ patient-ID tokens."
  )

  h5_ids <- vapply(token_list, `[`, character(1), 1L)
  add_audit(
    "H5 unique patient IDs",
    "142",
    length(unique(h5_ids)),
    !anyDuplicated(h5_ids) && length(unique(h5_ids)) == 142L
  )
  add_audit(
    "H5 ID set equals frozen manifest ID set",
    "exact set equality",
    paste0(
      "H5_only=", length(setdiff(h5_ids, manifest$sample_id)),
      ";manifest_only=", length(setdiff(manifest$sample_id, h5_ids))
    ),
    setequal(h5_ids, manifest$sample_id)
  )

  require_true(
    !anyDuplicated(h5_ids) && setequal(h5_ids, manifest$sample_id),
    "H5 patient IDs do not form a one-to-one match with R0_sample_manifest.csv."
  )

  # Force deterministic sample order from frozen manifest.
  h5_files <- h5_files[match(manifest$sample_id, h5_ids)]
  h5_ids <- manifest$sample_id
  names(h5_files) <- h5_ids

  h5_sizes <- file.info(h5_files)$size
  add_audit(
    "all 142 H5 files non-empty",
    "all bytes > 0",
    paste0("min_bytes=", min(h5_sizes)),
    all(is.finite(h5_sizes) & h5_sizes > 0)
  )
  require_true(all(is.finite(h5_sizes) & h5_sizes > 0), "At least one H5 file is empty/unreadable.")

  # --------------------------------------------------------------------------
  # D. tx2gene schema and mapping legality
  # --------------------------------------------------------------------------

  tx2gene_raw <- utils::read.csv(
    gzfile(TX2GENE_PATH),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  require_true(ncol(tx2gene_raw) >= 2L, "tx2gene has fewer than two columns.")

  norm_names <- clean_name(names(tx2gene_raw))
  transcript_candidates <- c(
    "ensembltranscriptidversion",
    "transcriptidversion",
    "ensembltranscriptid",
    "transcriptid",
    "txname",
    "transcript"
  )
  gene_candidates <- c(
    "externalgenename",
    "genesymbol",
    "symbol",
    "geneid",
    "gene"
  )

  tx_hits <- which(norm_names %in% transcript_candidates)
  gene_hits <- which(norm_names %in% gene_candidates)

  if (length(tx_hits) == 0L || length(gene_hits) == 0L) {
    # Public file is expected to be a two-column tx2gene object.
    # Fallback is permitted only when it has exactly two columns.
    require_true(
      ncol(tx2gene_raw) == 2L,
      paste(
        "Could not uniquely infer tx2gene columns and file has >2 columns. Columns:",
        paste(names(tx2gene_raw), collapse = ", ")
      )
    )
    tx_col <- 1L
    gene_col <- 2L
  } else {
    tx_col <- tx_hits[1L]
    gene_hits <- setdiff(gene_hits, tx_col)
    require_true(length(gene_hits) >= 1L, "Could not resolve a distinct gene column in tx2gene.")
    gene_col <- gene_hits[1L]
  }

  tx2gene <- data.frame(
    TXNAME = trimws(as.character(tx2gene_raw[[tx_col]])),
    GENEID = trimws(as.character(tx2gene_raw[[gene_col]])),
    stringsAsFactors = FALSE
  )

  add_audit(
    "tx2gene selected columns",
    "transcript column + gene column",
    paste(names(tx2gene_raw)[c(tx_col, gene_col)], collapse = " -> "),
    tx_col != gene_col
  )
  blank_tx <- is.na(tx2gene$TXNAME) | tx2gene$TXNAME == ""
  blank_gene <- is.na(tx2gene$GENEID) | tx2gene$GENEID == ""

  # Exact author semantics:
  # Figure_1.R constructs tx2gene from
  #   ensembl_transcript_id_version -> external_gene_name
  # and explicitly removes rows with blank external_gene_name before tximport:
  #   tx2gene <- tx2gene[tx2gene$external_gene_name != '',]
  #
  # Therefore blank gene names are EXPECTED PROVIDER ANNOTATION and are
  # excluded, not treated as a malformed-input failure. Blank transcript IDs
  # remain forbidden.
  add_audit(
    "tx2gene blank transcript IDs",
    "0",
    sum(blank_tx),
    sum(blank_tx) == 0L
  )
  require_true(
    sum(blank_tx) == 0L,
    "tx2gene contains blank/NA transcript IDs."
  )

  add_audit(
    "tx2gene blank external_gene_name rows",
    "author rule: exclude before tximport",
    sum(blank_gene),
    TRUE,
    "Replicates Figure_1.R: tx2gene <- tx2gene[tx2gene$external_gene_name != '',]"
  )

  tx2gene <- tx2gene[!blank_gene, , drop = FALSE]

  add_audit(
    "tx2gene post-author-filter nonblank mapping",
    "0 blank/NA transcript or gene IDs",
    sum(
      is.na(tx2gene$TXNAME) | tx2gene$TXNAME == "" |
        is.na(tx2gene$GENEID) | tx2gene$GENEID == ""
    ),
    !any(
      is.na(tx2gene$TXNAME) | tx2gene$TXNAME == "" |
        is.na(tx2gene$GENEID) | tx2gene$GENEID == ""
    )
  )
  require_true(
    nrow(tx2gene) > 0L &&
      !any(
        is.na(tx2gene$TXNAME) | tx2gene$TXNAME == "" |
          is.na(tx2gene$GENEID) | tx2gene$GENEID == ""
      ),
    "tx2gene is empty or still contains blank/NA IDs after the author filter."
  )

  # Identical duplicate rows do not alter mapping; conflicting transcript->gene
  # mappings are forbidden.
  dup_tx <- unique(tx2gene$TXNAME[duplicated(tx2gene$TXNAME)])
  conflicting_tx <- character()
  if (length(dup_tx)) {
    conflicting_tx <- dup_tx[
      vapply(
        dup_tx,
        function(z) length(unique(tx2gene$GENEID[tx2gene$TXNAME == z])) > 1L,
        logical(1)
      )
    ]
  }
  add_audit(
    "tx2gene conflicting transcript mappings",
    "0",
    length(conflicting_tx),
    length(conflicting_tx) == 0L
  )
  require_true(
    length(conflicting_tx) == 0L,
    paste(
      "Conflicting transcript-to-gene mappings detected:",
      paste(head(conflicting_tx, 20L), collapse = ", ")
    )
  )

  tx2gene <- unique(tx2gene)
  require_true(!anyDuplicated(tx2gene$TXNAME), "tx2gene transcript IDs remain duplicated after exact-row deduplication.")

  log_line(
    "tx2gene accepted: rows=", nrow(tx2gene),
    "; unique genes=", length(unique(tx2gene$GENEID))
  )

  # --------------------------------------------------------------------------
  # E. Read frozen released gene counts and SV table
  # --------------------------------------------------------------------------

  released_raw <- utils::read.csv(
    gzfile(COUNTS_PATH),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  require_true(ncol(released_raw) == 143L, "Released count file expected 1 gene column + 142 sample columns.")

  released_gene <- trimws(as.character(released_raw[[1L]]))
  released <- as.matrix(released_raw[-1L])
  storage.mode(released) <- "double"

  released_ids <- canonical_sample_id(colnames(released))
  add_audit("released counts genes", "30123", nrow(released), nrow(released) == 30123L)
  add_audit("released counts samples", "142", ncol(released), ncol(released) == 142L)
  add_audit(
    "released sample IDs one-to-one",
    "142 unique IDs matching manifest",
    paste0(
      "unique=", length(unique(released_ids)),
      ";NA=", sum(is.na(released_ids))
    ),
    !anyNA(released_ids) &&
      !anyDuplicated(released_ids) &&
      setequal(released_ids, manifest$sample_id)
  )
  add_audit(
    "released gene IDs unique",
    "0 duplicates",
    sum(duplicated(released_gene)),
    !anyDuplicated(released_gene)
  )
  add_audit(
    "released counts finite/nonnegative",
    "all finite and >=0",
    paste0(
      "finite=", all(is.finite(released)),
      ";nonnegative=", all(released >= 0)
    ),
    all(is.finite(released)) && all(released >= 0)
  )

  require_true(
    nrow(released) == 30123L &&
      ncol(released) == 142L &&
      !anyNA(released_ids) &&
      !anyDuplicated(released_ids) &&
      setequal(released_ids, manifest$sample_id) &&
      !anyDuplicated(released_gene) &&
      all(is.finite(released)) &&
      all(released >= 0),
    "Released gene-count matrix failed a mandatory structural check."
  )

  released <- released[, match(manifest$sample_id, released_ids), drop = FALSE]
  colnames(released) <- manifest$sample_id
  rownames(released) <- released_gene

  sv_raw <- utils::read.csv(
    gzfile(SV_PATH),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  sv_cols <- paste0("SV", 1:21)
  require_true(
    all(sv_cols %in% names(sv_raw)),
    paste("SV file missing:", paste(setdiff(sv_cols, names(sv_raw)), collapse = ", "))
  )

  sv_ids <- canonical_sample_id(sv_raw[[1L]])
  add_audit("SV rows", "142", nrow(sv_raw), nrow(sv_raw) == 142L)
  add_audit(
    "SV sample IDs one-to-one",
    "142 unique IDs matching manifest",
    paste0("unique=", length(unique(sv_ids)), ";NA=", sum(is.na(sv_ids))),
    !anyNA(sv_ids) &&
      !anyDuplicated(sv_ids) &&
      setequal(sv_ids, manifest$sample_id)
  )
  require_true(
    nrow(sv_raw) == 142L &&
      !anyNA(sv_ids) &&
      !anyDuplicated(sv_ids) &&
      setequal(sv_ids, manifest$sample_id),
    "SV sample IDs failed one-to-one alignment."
  )

  sv_order <- match(manifest$sample_id, sv_ids)
  sv_df <- sv_raw[sv_order, sv_cols, drop = FALSE]
  for (nm in sv_cols) {
    sv_df[[nm]] <- suppressWarnings(as.numeric(sv_df[[nm]]))
  }
  add_audit(
    "SV1-SV21 finite",
    "all 2982 values finite",
    paste0(
      "finite=", sum(vapply(sv_df, function(z) sum(is.finite(z)), integer(1))),
      "/", 142L * 21L
    ),
    all(vapply(sv_df, function(z) all(is.finite(z)), logical(1)))
  )
  require_true(
    all(vapply(sv_df, function(z) all(is.finite(z)), logical(1))),
    "SV1-SV21 contain missing or non-numeric values after coercion."
  )

  # --------------------------------------------------------------------------
  # F. Exact tximport from all 142 kallisto H5 files
  # --------------------------------------------------------------------------

  # GEO's supplementary TAR prefixes the original kallisto filenames, so the
  # basenames are not literally "abundance.h5". tximport's automatic kallisto
  # H5 dispatch tests basename(files[1]) == "abundance.h5"; without an explicit
  # importer these valid HDF5 binaries would be sent to a TSV/text reader.
  #
  # Use tximport's own H5 reader explicitly. This changes only dispatch, not
  # quantification semantics. We do not need kallisto bootstrap/inferential
  # replicates for the author's gene-level DESeq2 model, so dropInfReps=TRUE
  # also avoids dirname-based abundance.h5 bootstrap discovery.
  h5_basename_exact_n <- sum(basename(h5_files) == "abundance.h5")
  add_audit(
    "canonical abundance.h5 basenames",
    "GEO-prefixed files allowed; explicit H5 importer required when <142",
    h5_basename_exact_n,
    TRUE,
    "tximport auto-detects kallisto H5 only when basename(files[1]) is exactly abundance.h5"
  )

  kallisto_h5_importer <- getFromNamespace("read_kallisto_h5", "tximport")

  log_line("Probing first GEO-prefixed H5 with tximport's native kallisto H5 reader...")
  h5_probe <- kallisto_h5_importer(h5_files[1])
  required_h5_cols <- c("target_id", "eff_length", "est_counts", "tpm")
  add_audit(
    "native kallisto H5 reader probe",
    paste(required_h5_cols, collapse = ","),
    paste(names(h5_probe), collapse = ","),
    is.data.frame(h5_probe) &&
      all(required_h5_cols %in% names(h5_probe)) &&
      nrow(h5_probe) > 0L
  )
  require_true(
    is.data.frame(h5_probe) &&
      all(required_h5_cols %in% names(h5_probe)) &&
      nrow(h5_probe) > 0L,
    "tximport native kallisto H5 reader could not read the first H5 file correctly."
  )
  rm(h5_probe)
  invisible(gc())

  log_line("Starting tximport on 142 kallisto H5 files with explicit native H5 importer...")
  txi <- tximport::tximport(
    h5_files,
    type = "kallisto",
    txOut = FALSE,
    tx2gene = tx2gene,
    importer = kallisto_h5_importer,
    dropInfReps = TRUE
  )
  log_line("tximport completed.")

  require_true(is.list(txi), "tximport did not return a list.")
  require_true(all(c("counts", "abundance", "length") %in% names(txi)), "tximport output missing counts/abundance/length.")

  recon <- txi$counts
  storage.mode(recon) <- "double"

  add_audit("tximport reconstructed genes", "30123", nrow(recon), nrow(recon) == 30123L)
  add_audit("tximport reconstructed samples", "142", ncol(recon), ncol(recon) == 142L)
  add_audit(
    "tximport counts finite/nonnegative",
    "all finite and >=0",
    paste0("finite=", all(is.finite(recon)), ";nonnegative=", all(recon >= 0)),
    all(is.finite(recon)) && all(recon >= 0)
  )
  add_audit(
    "tximport length matrix exists",
    "30123 x 142 finite positive matrix",
    paste(dim(txi$length), collapse = "x"),
    is.matrix(txi$length) &&
      identical(dim(txi$length), dim(recon)) &&
      all(is.finite(txi$length)) &&
      all(txi$length > 0)
  )

  require_true(
    nrow(recon) == 30123L &&
      ncol(recon) == 142L &&
      all(is.finite(recon)) &&
      all(recon >= 0),
    "tximport reconstructed matrix failed mandatory structural checks."
  )
  require_true(
    is.matrix(txi$length) &&
      identical(dim(txi$length), dim(recon)) &&
      all(is.finite(txi$length)) &&
      all(txi$length > 0),
    "tximport average transcript-length matrix is absent/invalid."
  )

  add_audit(
    "tximport sample names equal frozen manifest order",
    "exact identity",
    paste0(sum(colnames(recon) == manifest$sample_id), "/142"),
    identical(colnames(recon), manifest$sample_id)
  )
  require_true(
    identical(colnames(recon), manifest$sample_id),
    "tximport output sample order/names do not equal frozen manifest order."
  )

  add_audit(
    "tximport gene set equals released gene set",
    "exact set equality",
    paste0(
      "tximport_only=", length(setdiff(rownames(recon), released_gene)),
      ";released_only=", length(setdiff(released_gene, rownames(recon)))
    ),
    !anyDuplicated(rownames(recon)) &&
      setequal(rownames(recon), released_gene)
  )
  require_true(
    !anyDuplicated(rownames(recon)) && setequal(rownames(recon), released_gene),
    "tximport gene identifiers do not exactly match the released 30,123-gene set."
  )

  # Align reconstructed matrix to released row order solely for concordance audit.
  recon_aligned <- recon[match(released_gene, rownames(recon)), manifest$sample_id, drop = FALSE]
  rownames(recon_aligned) <- released_gene

  # --------------------------------------------------------------------------
  # G. Reconstructed-vs-released count concordance gate
  # --------------------------------------------------------------------------

  log_line("Computing reconstructed-vs-released count concordance...")

  global_cor <- suppressWarnings(stats::cor(
    as.vector(recon_aligned),
    as.vector(released),
    method = "pearson"
  ))
  abs_diff <- abs(recon_aligned - released)
  relative_l1 <- sum(abs_diff) / max(sum(abs(released)), .Machine$double.eps)
  max_abs_diff <- max(abs_diff)
  mean_abs_diff <- mean(abs_diff)

  sample_cor <- vapply(
    seq_len(ncol(released)),
    function(j) suppressWarnings(stats::cor(
      recon_aligned[, j],
      released[, j],
      method = "pearson"
    )),
    numeric(1)
  )
  names(sample_cor) <- manifest$sample_id
  min_sample_cor <- min(sample_cor, na.rm = TRUE)

  # Prospective "obvious mismatch" gate. We do NOT require byte/exact floating
  # identity across tximport versions, but anything materially below these
  # thresholds is a HOLD requiring adjudication before model fitting.
  concordance_pass <- is.finite(global_cor) &&
    global_cor >= 0.999999 &&
    all(is.finite(sample_cor)) &&
    min_sample_cor >= 0.99999 &&
    is.finite(relative_l1) &&
    relative_l1 <= 1e-4

  add_audit(
    "reconstructed vs released global Pearson r",
    ">=0.999999",
    format(global_cor, digits = 12),
    is.finite(global_cor) && global_cor >= 0.999999
  )
  add_audit(
    "minimum per-sample Pearson r",
    ">=0.99999",
    format(min_sample_cor, digits = 12),
    all(is.finite(sample_cor)) && min_sample_cor >= 0.99999
  )
  add_audit(
    "relative L1 count difference",
    "<=1e-4",
    format(relative_l1, scientific = TRUE, digits = 8),
    is.finite(relative_l1) && relative_l1 <= 1e-4,
    "sum(abs(reconstructed-released))/sum(abs(released))"
  )

  count_concordance <- data.frame(
    global_pearson_r = global_cor,
    minimum_sample_pearson_r = min_sample_cor,
    relative_L1_difference = relative_l1,
    mean_absolute_difference = mean_abs_diff,
    max_absolute_difference = max_abs_diff,
    exact_floating_identity = isTRUE(all.equal(
      unname(recon_aligned),
      unname(released),
      tolerance = 0,
      check.attributes = FALSE
    )),
    prospective_gate = if (concordance_pass) "PASS" else "HOLD",
    stringsAsFactors = FALSE
  )

  sample_concordance <- data.frame(
    sample_id = manifest$sample_id,
    disease_group = manifest$disease_group,
    pearson_r = unname(sample_cor[manifest$sample_id]),
    stringsAsFactors = FALSE
  )

  require_true(
    concordance_pass,
    paste0(
      "Reconstructed tximport counts are not sufficiently concordant with released gene counts. ",
      "global_r=", signif(global_cor, 8), "; ",
      "min_sample_r=", signif(min_sample_cor, 8), "; ",
      "relative_L1=", signif(relative_l1, 8),
      ". HOLD before model fitting."
    )
  )

  # --------------------------------------------------------------------------
  # H. Build exact prefit DESeq2 object using public SV1-SV21
  # --------------------------------------------------------------------------

  coldata <- data.frame(
    category = factor(
      manifest$disease_group,
      levels = c("NF", "pRV", "RVF")
    ),
    sv_df,
    row.names = manifest$sample_id,
    check.names = FALSE
  )

  design_formula <- stats::as.formula(
    paste("~ category +", paste(sv_cols, collapse = " + "))
  )

  log_line("Building DESeqDataSetFromTximport with ~ category + SV1 + ... + SV21...")
  dds <- DESeq2::DESeqDataSetFromTximport(
    txi,
    colData = coldata,
    design = design_formula
  )

  avg_present <- "avgTxLength" %in% SummarizedExperiment::assayNames(dds)
  avg_dim_ok <- FALSE
  avg_finite_positive <- FALSE
  if (avg_present) {
    avg <- SummarizedExperiment::assay(dds, "avgTxLength")
    avg_dim_ok <- identical(dim(avg), c(30123L, 142L))
    avg_finite_positive <- all(is.finite(avg)) && all(avg > 0)
  }

  add_audit(
    "DESeq2 avgTxLength assay exists",
    "TRUE",
    avg_present,
    avg_present
  )
  add_audit(
    "DESeq2 avgTxLength dimensions",
    "30123x142",
    if (avg_present) paste(dim(SummarizedExperiment::assay(dds, "avgTxLength")), collapse = "x") else "ABSENT",
    avg_present && avg_dim_ok
  )
  add_audit(
    "DESeq2 avgTxLength finite/positive",
    "TRUE",
    avg_finite_positive,
    avg_present && avg_finite_positive
  )

  require_true(
    avg_present && avg_dim_ok && avg_finite_positive,
    "DESeqDataSetFromTximport did not preserve a valid avgTxLength assay."
  )

  log_line("Estimating normalization factors/size factors...")
  dds <- DESeq2::estimateSizeFactors(dds)

  normalized_pre_filter <- DESeq2::counts(dds, normalized = TRUE)
  require_true(
    all(is.finite(normalized_pre_filter)) && all(normalized_pre_filter >= 0),
    "Normalized counts are non-finite or negative before author filter."
  )

  keep <- rowSums(normalized_pre_filter >= 5) >= 3L
  kept_n <- sum(keep)

  add_audit(
    "author filter executable",
    "normalized count >=5 in >=3 samples",
    paste0("kept=", kept_n, ";removed=", length(keep) - kept_n),
    kept_n > 0L && kept_n < length(keep)
  )

  require_true(
    kept_n > 0L && kept_n < length(keep),
    "Author filter produced an implausible all/none result."
  )

  dds_prefit <- dds[keep, ]

  add_audit(
    "prefit samples",
    "142",
    ncol(dds_prefit),
    ncol(dds_prefit) == 142L
  )
  add_audit(
    "prefit design",
    "~ category + SV1 + ... + SV21",
    paste(deparse(DESeq2::design(dds_prefit)), collapse = ""),
    identical(
      paste(deparse(DESeq2::design(dds_prefit)), collapse = ""),
      paste(deparse(design_formula), collapse = "")
    )
  )
  add_audit(
    "prefit avgTxLength retained",
    "TRUE",
    "avgTxLength" %in% SummarizedExperiment::assayNames(dds_prefit),
    "avgTxLength" %in% SummarizedExperiment::assayNames(dds_prefit)
  )

  require_true(
    ncol(dds_prefit) == 142L &&
      "avgTxLength" %in% SummarizedExperiment::assayNames(dds_prefit),
    "Prefit DESeq2 object failed final structural checks."
  )

  # Explicit proof that Step 1 stops before model fitting.
  beta_conv_present <- "betaConv" %in% names(S4Vectors::mcols(dds_prefit))
  add_audit(
    "DESeq model not fitted in Step 1",
    "betaConv absent",
    paste0("betaConv_present=", beta_conv_present),
    !beta_conv_present
  )
  require_true(!beta_conv_present, "Unexpected fitted-model metadata found in Step 1 prefit object.")

  # --------------------------------------------------------------------------
  # I. Final audit decision
  # --------------------------------------------------------------------------

  audit_df <- do.call(rbind, AUDIT)
  failed <- audit_df$item[audit_df$status != "PASS"]
  require_true(
    length(failed) == 0L,
    paste("Mandatory Step 1 audit failure(s):", paste(failed, collapse = "; "))
  )

  sample_map <- data.frame(
    sample_id = manifest$sample_id,
    disease_group = manifest$disease_group,
    h5_path = unname(h5_files),
    h5_bytes = unname(h5_sizes),
    released_count_column = colnames(released),
    stringsAsFactors = FALSE
  )

  env_versions <- data.frame(
    component = c(
      "R", "Bioconductor",
      "tximport", "rhdf5", "DESeq2", "ashr", "ggplot2", "data.table"
    ),
    version = c(
      paste(R.version$major, R.version$minor, sep = "."),
      as.character(BiocManager::version()),
      vapply(
        c("tximport", "rhdf5", "DESeq2", "ashr", "ggplot2", "data.table"),
        function(p) as.character(utils::packageVersion(p)),
        character(1)
      )
    ),
    stringsAsFactors = FALSE
  )

  # --------------------------------------------------------------------------
  # J. Write complete build directory, then atomically promote directory
  # --------------------------------------------------------------------------

  log_line("Writing Step 1 checkpoint objects to temporary build directory...")

  atomic_save_rds(txi, file.path(build_dir, "R0_tximport_exact.rds"))
  atomic_save_rds(dds_prefit, file.path(build_dir, "R0_prefit_dds.rds"))

  atomic_write_csv(
    audit_df,
    file.path(build_dir, "R0_exact_step1_audit.csv")
  )
  atomic_write_csv(
    sample_map,
    file.path(build_dir, "R0_exact_step1_sample_map.csv")
  )
  atomic_write_csv(
    count_concordance,
    file.path(build_dir, "R0_exact_step1_count_concordance.csv")
  )
  atomic_write_csv(
    sample_concordance,
    file.path(build_dir, "R0_exact_step1_sample_concordance.csv")
  )
  atomic_write_csv(
    env_versions,
    file.path(build_dir, "R0_exact_step1_environment.csv")
  )

  capture.output(
    sessionInfo(),
    file = file.path(build_dir, "R0_exact_step1_sessionInfo.txt")
  )

  gate_lines <- c(
    "R0_EXACT_TXIMPORT_PREP_PASS",
    paste0("timestamp=", format(Sys.time(), "%Y-%m-%d %H:%M:%S %z")),
    "project_root=D:/RV_project",
    "stage=Exact R0 Step 1",
    "implementation=v4_LOCAL_RUN",
    "DESeq_model_fit_executed=NO",
    paste0("h5_count=", length(h5_files)),
    paste0("tximport_genes=", nrow(recon)),
    paste0("tximport_samples=", ncol(recon)),
    paste0("global_count_pearson_r=", format(global_cor, digits = 12)),
    paste0("minimum_sample_pearson_r=", format(min_sample_cor, digits = 12)),
    paste0("relative_L1_difference=", format(relative_l1, scientific = TRUE, digits = 8)),
    paste0("author_filter_kept_genes=", kept_n),
    paste0("avgTxLength_present=", avg_present),
    "next_stage=Exact R0 Step 2 only after ChatGPT audit"
  )
  atomic_write_lines(
    gate_lines,
    file.path(build_dir, "R0_EXACT_TXIMPORT_PREP_PASS.txt")
  )

  log_line("Promoting complete build directory to final v4 authority directory...")
  if (!file.rename(build_dir, FINAL_DIR)) {
    stop(
      "All Step 1 objects were built, but final directory promotion failed. ",
      "Build directory retained for manual audit: ", build_dir
    )
  }

  # Cancel on.exit cleanup because build_dir no longer exists after promotion.
  log_line("============================================================")
  log_line("FINAL_GATE: R0_EXACT_TXIMPORT_PREP_PASS")
  log_line("tximport dimensions: ", nrow(recon), " genes x ", ncol(recon), " samples")
  log_line("global count Pearson r: ", format(global_cor, digits = 12))
  log_line("minimum sample Pearson r: ", format(min_sample_cor, digits = 12))
  log_line("relative L1 difference: ", format(relative_l1, scientific = TRUE, digits = 8))
  log_line("author filter kept genes: ", kept_n)
  log_line("avgTxLength present: ", avg_present)
  log_line("checkpoint: ", file.path(FINAL_DIR, "R0_prefit_dds.rds"))
  log_line("NO DESeq() model fit was executed.")
  log_line("STOP HERE. Return Step 1 outputs/log to ChatGPT for audit.")
  log_line("============================================================")

  invisible(TRUE)
}

tryCatch(
  run_step1(),
  error = function(e) {
    log_line("============================================================")
    log_line("FINAL_GATE: R0_EXACT_TXIMPORT_PREP_HOLD")
    log_line("ERROR: ", conditionMessage(e))
    log_line("No Step 2 is authorized.")
    log_line("Return this log to ChatGPT. Do not auto-rerun.")
    log_line("============================================================")

    if (length(AUDIT)) {
      hold_audit <- do.call(rbind, AUDIT)
      hold_path <- file.path(LOG_DIR, "R0_STEP1_v4_LOCAL_RUN_HOLD_audit.csv")
      try(
        utils::write.csv(hold_audit, hold_path, row.names = FALSE, na = ""),
        silent = TRUE
      )
    }
    quit(save = "no", status = 20L, runLast = FALSE)
  }
)

quit(save = "no", status = 0L, runLast = FALSE)
