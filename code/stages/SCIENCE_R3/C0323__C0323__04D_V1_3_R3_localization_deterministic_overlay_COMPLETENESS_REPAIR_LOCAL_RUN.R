# ---- RV PUBLIC REPRODUCIBILITY PORTABILITY OVERLAY V1.0 ----
.RV_PROJECT_ROOT_ENV <- Sys.getenv('RV_PROJECT_ROOT', unset='')
RV_PROJECT_ROOT <- if (nzchar(.RV_PROJECT_ROOT_ENV)) {
  normalizePath(.RV_PROJECT_ROOT_ENV, winslash='/', mustWork=TRUE)
} else {
  normalizePath(getwd(), winslash='/', mustWork=TRUE)
}
# This overlay changes path binding only; scientific/statistical semantics remain historical authority.

source(file.path(RV_PROJECT_ROOT, 'code', 'lib', 'rv_runtime_helpers.R'))


# R3 Step4D V1.3
# DETERMINISTIC IMPLEMENTATION OVERLAY — COMPLETENESS REPAIR
#
# This is a PRE-RESULTS version-forward implementation overlay only.
# It MUST NOT modify the frozen Step4D scientific contract.
# It MUST NOT read either expression RDS or produce localization results.
#
# V1.3 closes the remaining implementation gaps after independent audit:
#   A. preserve the V1.2 exact frozen-source registry lineage;
#   B. restore the Step4F arithmetic fail-closed guards that V1.2 omitted;
#   C. define exactly what Xenium "MEASURED_AND_NONZERO ... IN_TEST" means;
#   D. define the exact test-specific Xenium mroast index;
#   E. keep the 840-row per-test RNG registry unchanged in scientific universe.

options(stringsAsFactors = FALSE, warn = 1)

ROOT <- RV_PROJECT_ROOT
RES <- file.path(ROOT, "results", "R3_GSE249696")
UPLOAD <- file.path(ROOT, "upload")
LOGROOT <- file.path(ROOT, "logs")

args <- commandArgs(trailingOnly = TRUE)
RUN_ID <- if (length(args) >= 1L && nzchar(args[1L])) args[1L] else format(Sys.time(), "%Y%m%d_%H%M%S")

RUNROOT <- file.path(RES, "R3_STEP4D_V1_3_runs")
RUNDIR <- file.path(RUNROOT, RUN_ID)
STAGING <- file.path(UPLOAD, "R3_STEP4D_V1_3_STAGING")

dir.create(RUNDIR, recursive = TRUE, showWarnings = FALSE)
dir.create(UPLOAD, recursive = TRUE, showWarnings = FALSE)
if (dir.exists(STAGING)) unlink(STAGING, recursive = TRUE, force = TRUE)
dir.create(STAGING, recursive = TRUE, showWarnings = FALSE)

# -------------------------------------------------------------------------
# Frozen authorities — exact filenames only
# -------------------------------------------------------------------------

P_LABELS <- file.path(RES, "R3_STEP4C_V1_2_frozen_annotation_labels.csv")
P_MASTER <- file.path(RES, "R3_STEP4D_LOCALIZATION_ANALYSIS_CONTRACT_FROZEN.txt")
P_AUDIT  <- file.path(RES, "R3_STEP4D_localization_analysis_contract_audit.csv")
P_METHOD <- file.path(RES, "R3_STEP4D_localization_method_contract.csv")
P_TIER   <- file.path(RES, "R3_STEP4D_program_modality_tier_contract.csv")
P_FDR    <- file.path(RES, "R3_STEP4D_fixed_FDR_family_contract.csv")
P_CLASS  <- file.path(RES, "R3_STEP4D_localization_classification_contract.csv")

FROZEN_SOURCES <- c(P_LABELS, P_MASTER, P_AUDIT, P_METHOD, P_TIER, P_FDR, P_CLASS)

# Expected bytes/SHA are documentation/provenance constants observed in the
# independently audited frozen source snapshots. SHA is rechecked by the final
# package SHA256SUMS file and by ChatGPT independent audit; this R gate itself
# remains package-light and verifies exact bytes + semantic sentinels.
EXPECTED_SOURCE_BYTES <- c(
  "R3_STEP4C_V1_2_frozen_annotation_labels.csv" = 11624,
  "R3_STEP4D_LOCALIZATION_ANALYSIS_CONTRACT_FROZEN.txt" = 2024,
  "R3_STEP4D_localization_analysis_contract_audit.csv" = 5179,
  "R3_STEP4D_localization_method_contract.csv" = 4456,
  "R3_STEP4D_program_modality_tier_contract.csv" = 1694,
  "R3_STEP4D_fixed_FDR_family_contract.csv" = 1274,
  "R3_STEP4D_localization_classification_contract.csv" = 1881
)

EXPECTED_SOURCE_SHA256 <- c(
  "R3_STEP4C_V1_2_frozen_annotation_labels.csv" =
    "c1cc2719cc44ce2b74e8fdd6844ba784adde7d6041bcfce593276f3120858fdf",
  "R3_STEP4D_LOCALIZATION_ANALYSIS_CONTRACT_FROZEN.txt" =
    "a34b560bd1cb72f0484b5e6c8d8696d88c400e1fa714a61b65db7abf43d7a735",
  "R3_STEP4D_localization_analysis_contract_audit.csv" =
    "39f4acf6d79e0e11a804ba3ff09e4e7a3610b85ed1d664f7950644cbdd0df10a",
  "R3_STEP4D_localization_method_contract.csv" =
    "5c2e10d55a4bc286a4a884e6da1e2a22476db3e6fc3c5f7eb9cb0ac656c32666",
  "R3_STEP4D_program_modality_tier_contract.csv" =
    "706ee69f9af7ab99cfb18137aeec3d4f3b4772ee003be038367a5da8c534a8c3",
  "R3_STEP4D_fixed_FDR_family_contract.csv" =
    "e4bcc6b5882a4bc0c31f419df03048210219324235a99e75833d238f1edb7661",
  "R3_STEP4D_localization_classification_contract.csv" =
    "132e2a2ce4f3ca2a1dfe5624dd339e6b63988bc445292fca7f90dee2081a5c66"
)

# -------------------------------------------------------------------------
# Output paths
# -------------------------------------------------------------------------

P_STATUS <- file.path(RUNDIR, "R3_STEP4D_V1_3_STATUS.txt")
P_IMPL_AUDIT <- file.path(RUNDIR, "R3_STEP4D_V1_3_implementation_audit.csv")
P_REG <- file.path(RUNDIR, "R3_STEP4D_V1_3_DETERMINISTIC_TEST_REGISTRY.csv")
P_SEM <- file.path(RUNDIR, "R3_STEP4D_V1_3_implementation_semantics.csv")
P_OVERLAY <- file.path(RUNDIR, "R3_STEP4D_V1_3_DETERMINISTIC_IMPLEMENTATION_OVERLAY_FROZEN.txt")
P_SOURCE_MAN <- file.path(RUNDIR, "R3_STEP4D_V1_3_frozen_source_manifest.csv")
P_REPAIR <- file.path(RUNDIR, "R3_STEP4D_V1_3_REPAIR_NOTE.txt")
P_GUARDS <- file.path(RUNDIR, "R3_STEP4D_V1_3_STEP4F_FAIL_CLOSED_GUARDS.csv")

final_state <- "HOLD_STEP4D_V1_3_COMPLETENESS_REPAIR"

audit <- data.frame(check_id=character(), status=character(), detail=character(),
                    stringsAsFactors=FALSE)

add <- function(id, status, detail) {
  audit <<- rbind(audit, data.frame(check_id=id, status=status, detail=as.character(detail),
                                    stringsAsFactors=FALSE))
  cat(sprintf("[%s] %s :: %s\n", status, id, detail))
}

PASS <- function(id, detail) add(id, "PASS", detail)

HOLD <- function(id, detail) {
  add(id, "FAIL", detail)
  stop(paste0("HOLD: ", detail), call.=FALSE)
}

write_csv <- function(x, p) {
  write.csv(x, p, row.names=FALSE, na="", fileEncoding="UTF-8")
}

copy_stage <- function(paths) {
  paths <- unique(paths[file.exists(paths)])
  for (p in paths) {
    ok <- file.copy(p, file.path(STAGING, basename(p)), overwrite=TRUE,
                    copy.mode=TRUE, copy.date=TRUE)
    if (!isTRUE(ok)) stop(paste("Could not stage", p), call.=FALSE)
  }
}

finalize <- function() {
  try(write_csv(audit, P_IMPL_AUDIT), silent=TRUE)
  try(writeLines(c(
    paste0("RUN_ID=", RUN_ID),
    paste0("FINAL_STATE=", final_state),
    "STEP4D_SCIENTIFIC_CONTRACT=UNCHANGED",
    "THIS_IS_NOT_A_SCIENTIFIC_REPAIR=TRUE",
    "V1_1_IMPLEMENTATION_OVERLAY=SUPERSEDED",
    "V1_2_IMPLEMENTATION_OVERLAY=SUPERSEDED_BY_V1_3_COMPLETENESS_REPAIR",
    "REAL_RDS_READ=NO",
    "REAL_EXPRESSION_VALUE_READ=NO",
    "PSEUDOBULK_EXECUTED=NO",
    "VOOM_EXECUTED=NO",
    "MROAST_EXECUTED=NO",
    "DISEASE_GROUP_TESTING_EXECUTED=NO",
    "LOCALIZATION_SCIENTIFIC_RESULT_PRODUCED=NO"
  ), P_STATUS, useBytes=TRUE), silent=TRUE)

  try(copy_stage(c(
    FROZEN_SOURCES, P_STATUS, P_IMPL_AUDIT, P_REG, P_SEM,
    P_OVERLAY, P_SOURCE_MAN, P_REPAIR, P_GUARDS
  )), silent=TRUE)
}
on.exit(finalize(), add=TRUE)

read_csv_req <- function(p, id) {
  if (!file.exists(p)) HOLD(id, paste("missing", p))
  if (file.info(p)$size <= 0) HOLD(id, paste("zero-byte", p))
  x <- tryCatch(read.csv(p, check.names=FALSE, stringsAsFactors=FALSE),
                error=function(e) NULL)
  if (is.null(x)) HOLD(id, paste("cannot read", p))
  x
}

require_cols <- function(x, cols, id) {
  m <- setdiff(cols, names(x))
  if (length(m)) HOLD(id, paste("missing columns:", paste(m, collapse=", ")))
}

labels_exact <- function(x, dataset, field, n_expected) {
  z <- x[x$dataset == dataset & x$field == field, "label", drop=TRUE]
  z <- as.character(z)
  if (length(z) != n_expected) HOLD(paste0("LABEL_N_",field),
                                     paste(field, "expected", n_expected, "found", length(z)))
  if (any(is.na(z)) || any(!nzchar(z))) HOLD(paste0("LABEL_EMPTY_",field), field)
  if (anyDuplicated(z)) HOLD(paste0("LABEL_DUP_",field), field)
  if (any(z != trimws(z))) HOLD(paste0("LABEL_WS_",field),
                                 paste(field, "has leading/trailing whitespace"))
  z
}

main <- function() {
  # -----------------------------------------------------------------------
  # 1. Exact frozen-source presence / bytes / Step4D 63/63
  # -----------------------------------------------------------------------
  miss <- FROZEN_SOURCES[!file.exists(FROZEN_SOURCES)]
  if (length(miss)) HOLD("SOURCE_EXISTENCE", paste(miss, collapse=" | "))

  for (p in FROZEN_SOURCES) {
    nm <- basename(p)
    obs <- as.numeric(file.info(p)$size)
    exp <- unname(EXPECTED_SOURCE_BYTES[nm])
    if (is.na(exp) || obs != exp) {
      HOLD("SOURCE_BYTES", paste(nm, "expected", exp, "found", obs))
    }
  }
  PASS("SOURCE_BYTES", "7/7 frozen source byte sizes exact")

  master <- paste(readLines(P_MASTER, warn=FALSE, encoding="UTF-8"), collapse="\n")
  sent <- c(
    "role=PRERESULT_LOCALIZATION_ANALYSIS_CONTRACT",
    "primary_contrast=RVF_MINUS_pRV",
    "inferential_replicate=PATIENT",
    "RDS_loaded=NO",
    "expression_values_used=NO",
    "pseudobulk_generated=NO",
    "mroast_executed=NO",
    "disease_group_testing_executed=NO"
  )
  bad <- sent[!vapply(sent, function(s) grepl(s, master, fixed=TRUE), logical(1))]
  if (length(bad)) HOLD("MASTER_SENTINELS", paste(bad, collapse=" | "))
  PASS("MASTER_SENTINELS", "pre-results Step4D master sentinels exact")

  d0 <- read_csv_req(P_AUDIT, "READ_STEP4D_AUDIT")
  require_cols(d0, c("status"), "STEP4D_AUDIT_COLUMNS")
  if (nrow(d0) != 63L || sum(d0$status=="PASS") != 63L || any(d0$status=="FAIL")) {
    HOLD("STEP4D_63_63", paste("rows", nrow(d0),
                               "PASS", sum(d0$status=="PASS"),
                               "FAIL", sum(d0$status=="FAIL")))
  }
  PASS("STEP4D_63_63", "original Step4D scientific contract audit remains 63/63 PASS")

  # -----------------------------------------------------------------------
  # 2. Load frozen contracts
  # -----------------------------------------------------------------------
  lab <- read_csv_req(P_LABELS, "READ_LABELS")
  met <- read_csv_req(P_METHOD, "READ_METHOD")
  tier <- read_csv_req(P_TIER, "READ_TIER")
  fdr <- read_csv_req(P_FDR, "READ_FDR")

  require_cols(lab, c("dataset","field","role","label"), "LABEL_COLS")
  require_cols(met, c("scope","parameter","frozen_value","rationale"), "METHOD_COLS")
  require_cols(tier, c("pathway","Xenium_module_family_member"), "TIER_COLS")
  require_cols(fdr, c("family_id","dataset","annotation_level","contrast",
                      "n_fixed_labels","n_fixed_programs","max_family_tests",
                      "unassessable_BH_input","adjustment","threshold",
                      "primary_claim_role"), "FDR_COLS")

  # Exact specific scientific authority wins over generic summary wording.
  xen_rule <- met[met$scope=="XENIUM" & met$parameter=="MODULE_ELIGIBILITY",
                  "frozen_value", drop=TRUE]
  XEN_RULE <- ">=10_MEASURED_AND_NONZERO_PROGRAM_GENES_IN_TEST"
  if (length(xen_rule)!=1L || !identical(as.character(xen_rule), XEN_RULE)) {
    HOLD("XENIUM_ELIGIBILITY_FROZEN", paste("observed:", paste(xen_rule, collapse=" | ")))
  }
  PASS("XENIUM_ELIGIBILITY_FROZEN", XEN_RULE)

  # -----------------------------------------------------------------------
  # 3. Exact source-order label/program vectors
  # -----------------------------------------------------------------------
  sn_broad <- labels_exact(lab, "GSE345646_snRNA", "Names", 12L)
  sn_fine  <- labels_exact(lab, "GSE345646_snRNA", "Subnames_manual", 34L)
  xe_broad <- labels_exact(lab, "GSE345643_Xenium_ambient_corrected",
                           "cell_type_rctd_doublet", 12L)
  xe_fine  <- labels_exact(lab, "GSE345643_Xenium_ambient_corrected",
                           "cell_type_seurat", 34L)

  if (!identical(sn_broad, xe_broad))
    HOLD("BROAD_CROSS_MODAL", "12 broad labels/order are not exact cross-modal match")
  PASS("LABEL_ORDER", "SN broad 12 / fine 34 / XE broad 12 / fine 34 exact frozen row order")

  sn_prog <- as.character(tier$pathway)
  xe_flag <- as.logical(tier$Xenium_module_family_member)
  if (length(sn_prog)!=7L || anyDuplicated(sn_prog))
    HOLD("SN_PROGRAMS", "expected 7 unique frozen programs")
  if (any(is.na(xe_flag))) HOLD("XE_PROGRAM_PARSE", "NA in Xenium_module_family_member")
  xe_prog <- as.character(tier$pathway[xe_flag])
  if (length(xe_prog)!=5L || anyDuplicated(xe_prog))
    HOLD("XE_PROGRAMS", "expected 5 unique frozen Xenium module programs")
  PASS("PROGRAM_ORDER", "exact frozen tier row order; snRNA=7; Xenium module family=5")

  # -----------------------------------------------------------------------
  # 4. Exact frozen family IDs/order/sizes
  # -----------------------------------------------------------------------
  FAMILY_IDS <- c(
    "SN_BROAD_RVF_vs_pRV_PRIMARY",
    "SN_BROAD_pRV_vs_NF_CONTEXT",
    "SN_BROAD_RVF_vs_NF_CONTEXT",
    "SN_FINE_RVF_vs_pRV_SECONDARY",
    "XE_BROAD_RVF_vs_pRV_PANEL_PRIMARY_SUPPORT",
    "XE_BROAD_pRV_vs_NF_PANEL_CONTEXT",
    "XE_BROAD_RVF_vs_NF_PANEL_CONTEXT",
    "XE_FINE_RVF_vs_pRV_PANEL_SECONDARY"
  )
  FAMILY_N <- c(84L,84L,84L,238L,60L,60L,60L,170L)

  if (nrow(fdr)!=8L) HOLD("FDR_N", paste("expected 8 found", nrow(fdr)))
  if (!identical(as.character(fdr$family_id), FAMILY_IDS))
    HOLD("FDR_IDS", paste(fdr$family_id, collapse=" | "))
  if (!identical(as.integer(fdr$max_family_tests), FAMILY_N))
    HOLD("FDR_SIZES", paste(fdr$max_family_tests, collapse=","))
  if (any(as.character(fdr$unassessable_BH_input)!="P_EQUALS_1"))
    HOLD("FDR_PADDING", "not all P_EQUALS_1")
  if (any(as.character(fdr$adjustment)!="BH"))
    HOLD("FDR_BH", "not all BH")
  if (any(as.numeric(fdr$threshold)!=0.05))
    HOLD("FDR_ALPHA", "not all 0.05")
  PASS("FDR_SOURCE", "8 exact frozen families; sizes 84/84/84/238 + 60/60/60/170")

  # -----------------------------------------------------------------------
  # 5. Reconstruct deterministic 840-row registry from frozen sources only
  # -----------------------------------------------------------------------
  cm <- list(
    RVF_MINUS_pRV=list(expr="RVF - pRV",num="RVF",den="pRV",
                       levels="pRV|RVF",vec="pRV=-1;RVF=+1"),
    pRV_MINUS_NF=list(expr="pRV - NF",num="pRV",den="NF",
                      levels="NF|pRV",vec="NF=-1;pRV=+1"),
    RVF_MINUS_NF=list(expr="RVF - NF",num="RVF",den="NF",
                      levels="NF|RVF",vec="NF=-1;RVF=+1")
  )

  family_components <- function(row) {
    ds <- as.character(row$dataset)
    lev <- as.character(row$annotation_level)
    con <- as.character(row$contrast)

    if (ds=="GSE345646_snRNA") {
      modality <- "SNRNA"; programs <- sn_prog
      if (lev=="BROAD_12") {
        annlevel <- "BROAD"; field <- "Names"; labs <- sn_broad
      } else if (lev=="FINE_34") {
        annlevel <- "FINE"; field <- "Subnames_manual"; labs <- sn_fine
      } else HOLD("SN_ANN_LEVEL", lev)
    } else if (ds=="GSE345643_Xenium_ambient_corrected") {
      modality <- "XENIUM"; programs <- xe_prog
      if (lev=="BROAD_12") {
        annlevel <- "BROAD"; field <- "cell_type_rctd_doublet"; labs <- xe_broad
      } else if (lev=="FINE_34") {
        annlevel <- "FINE"; field <- "cell_type_seurat"; labs <- xe_fine
      } else HOLD("XE_ANN_LEVEL", lev)
    } else HOLD("FDR_DATASET", ds)

    if (!con %in% names(cm)) HOLD("CONTRAST_ID", con)
    list(modality=modality, annlevel=annlevel, field=field,
         labs=labs, programs=programs, con=con, source_level=lev)
  }

  parts <- vector("list", 8L)
  for (i in 1:8) {
    row <- fdr[i,,drop=FALSE]
    q <- family_components(row)
    if (length(q$labs)!=as.integer(row$n_fixed_labels)) HOLD("FAM_LABEL_N", row$family_id)
    if (length(q$programs)!=as.integer(row$n_fixed_programs)) HOLD("FAM_PROG_N", row$family_id)
    if (length(q$labs)*length(q$programs)!=as.integer(row$max_family_tests))
      HOLD("FAM_ARITH", row$family_id)

    cc <- cm[[q$con]]
    rr <- do.call(rbind, lapply(seq_along(q$labs), function(j) {
      data.frame(
        source_family_order=i,
        family_id=as.character(row$family_id),
        dataset=as.character(row$dataset),
        modality=q$modality,
        annotation_level=q$annlevel,
        source_annotation_level=q$source_level,
        annotation_field=q$field,
        contrast_id=q$con,
        contrast_expression=cc$expr,
        contrast_numerator=cc$num,
        contrast_denominator=cc$den,
        factor_levels=cc$levels,
        contrast_vector=cc$vec,
        label_order_within_field=j,
        label=q$labs[j],
        program_order_within_modality=seq_along(q$programs),
        program=q$programs,
        family_expected_size=as.integer(row$max_family_tests),
        unassessable_BH_input=as.character(row$unassessable_BH_input),
        adjustment=as.character(row$adjustment),
        threshold=as.numeric(row$threshold),
        primary_claim_role=as.character(row$primary_claim_role),
        stringsAsFactors=FALSE
      )
    }))
    parts[[i]] <- rr
  }
  reg <- do.call(rbind, parts)

  MASTER_SEED <- 20260910L
  reg$test_ordinal <- seq_len(nrow(reg))
  reg$test_seed <- MASTER_SEED + reg$test_ordinal
  reg$test_key <- paste(reg$modality, reg$annotation_level, reg$contrast_id,
                        reg$label, reg$program, sep="|")

  reg <- reg[,c(
    "test_ordinal","test_key","test_seed",
    "source_family_order","family_id","dataset","modality",
    "annotation_level","source_annotation_level","annotation_field",
    "contrast_id","contrast_expression","contrast_numerator",
    "contrast_denominator","factor_levels","contrast_vector",
    "label_order_within_field","label","program_order_within_modality",
    "program","family_expected_size","unassessable_BH_input",
    "adjustment","threshold","primary_claim_role"
  )]

  if (nrow(reg)!=840L) HOLD("REG_N", nrow(reg))
  if (length(unique(reg$test_key))!=840L) HOLD("REG_KEY", "not 840 unique")
  if (!identical(reg$test_ordinal, 1:840)) HOLD("REG_ORDINAL", "not 1:840")
  if (length(unique(reg$test_seed))!=840L) HOLD("REG_SEED_UNIQUE", "not 840 unique")
  if (!identical(as.integer(range(reg$test_seed)), c(20260911L,20261750L)))
    HOLD("REG_SEED_RANGE", paste(range(reg$test_seed), collapse=".."))
  if (!identical(unique(as.character(reg$family_id)), FAMILY_IDS))
    HOLD("REG_FAMILY_ORDER", "drift")
  obsN <- as.integer(table(factor(reg$family_id, levels=FAMILY_IDS)))
  if (!identical(obsN, FAMILY_N)) HOLD("REG_FAMILY_N", paste(obsN, collapse=","))
  PASS("REGISTRY_CORE", "840 rows; 840 unique key/ordinal/seed; exact 8 frozen family order/sizes")

  # Explicit exact label-order rechecks.
  z1 <- unique(reg$label[reg$family_id=="SN_BROAD_RVF_vs_pRV_PRIMARY"])
  z2 <- unique(reg$label[reg$family_id=="SN_FINE_RVF_vs_pRV_SECONDARY"])
  z3 <- unique(reg$label[reg$family_id=="XE_BROAD_RVF_vs_pRV_PANEL_PRIMARY_SUPPORT"])
  z4 <- unique(reg$label[reg$family_id=="XE_FINE_RVF_vs_pRV_PANEL_SECONDARY"])
  if (!identical(z1,sn_broad) || !identical(z2,sn_fine) ||
      !identical(z3,xe_broad) || !identical(z4,xe_fine))
    HOLD("REG_LABEL_ORDER", "registry label order != frozen source order")
  PASS("REG_LABEL_ORDER", "all four annotation vectors preserve frozen source row order")

  # -----------------------------------------------------------------------
  # 6. V1.3 exact implementation semantics / missing guard closure
  # -----------------------------------------------------------------------

  NONZERO_DEF <- paste0(
    "For a Xenium registry row, after forming the pairwise eligible patient×annotation ",
    "pseudobulk corrected-count matrix and BEFORE CPM/log2(1+CPM), a measured program ",
    "gene is NONZERO_IN_TEST iff its sum across ALL eligible pseudobulk samples in that ",
    "two-group test is strictly >0. Because ANY negative corrected input is a whole-Gate ",
    "HOLD, this is equivalent to at least one eligible pseudobulk sample having value >0."
  )

  XE_INDEX_DEF <- paste0(
    "Xenium mroast index for a registry row = exact frozen Hallmark symbols ∩ exact 477 ",
    "measured panel symbols ∩ NONZERO_IN_TEST genes. Module-level row is assessable only ",
    "when this exact index has >=10 genes. The mroast y matrix still contains ALL 477 ",
    "measured panel genes; index restriction does not crop the y universe."
  )

  SN_INDEX_DEF <- paste0(
    "snRNA mroast index for a registry row = exact frozen Hallmark symbols ∩ the complete ",
    "pairwise filterByExpr-retained gene universe. Row is assessable only when index size >=10. ",
    "The voom/mroast y universe contains ALL pairwise retained genes."
  )

  sem <- data.frame(
    scope=c(
      "GLOBAL_RNG","GLOBAL_RNG","GLOBAL_RNG","GLOBAL_RNG",
      "REGISTRY","REGISTRY","REGISTRY","REGISTRY",
      "PAIRWISE_DESIGN","PAIRWISE_DESIGN","PAIRWISE_DESIGN",
      "FILTER_BY_EXPR",
      "MROAST","MROAST","MROAST","MROAST","MROAST","MROAST","MROAST",
      "SNRNA_GENE_UNIVERSE","SNRNA_PROGRAM_INDEX",
      "XENIUM_GENE_UNIVERSE","XENIUM_CPM","XENIUM_NONZERO_DEFINITION",
      "XENIUM_PROGRAM_INDEX","XENIUM_MODULE_ELIGIBILITY",
      "GENE_IDENTITY","EXPRESSION_IDENTITY",
      "FDR","FDR"
    ),
    key=c(
      "RNGkind.kind","RNGkind.normal.kind","RNGkind.sample.kind","master_seed",
      "row_count","ordinal_range","seed_rule","mroast_call_cardinality",
      "model_scope","design","contrast",
      "filtering",
      "set.statistic","nrot","midp","adjust.method","sort","approx.zscore","legacy",
      "mroast_y","index",
      "mroast_y","denominator","nonzero_in_test",
      "index","module_threshold",
      "gene_matching","cell_sample_alignment",
      "external_adjustment","unassessable_padding"
    ),
    value=c(
      "Mersenne-Twister","Inversion","Rejection","20260910",
      "840","1..840","test_seed=master_seed+test_ordinal",
      "ONE assessable registry row = ONE independent mroast() call; set.seed(test_seed) immediately before call",
      "Each contrast independently subsets only its two eligible disease groups",
      "group=factor(... frozen pairwise levels); design=model.matrix(~0+group); colnames(design)=levels(group)",
      "Explicit named contrast vector from registry; no implicit reference level",
      "snRNA only: filterByExpr(y,design=design,min.count=10,min.total.count=15,large.n=10,min.prop=0.7) within the same pairwise pseudobulk universe; never substitute group=",
      "mean","9999","TRUE","none","none","TRUE","FALSE",
      "ALL pairwise filterByExpr-retained genes",SN_INDEX_DEF,
      "ALL 477 measured panel genes", "sum across all 477 genes for each patient×annotation pseudobulk; must be >0",
      NONZERO_DEF, XE_INDEX_DEF, XEN_RULE,
      "Exact frozen gene-symbol match only; no alias/case/fuzzy/duplicate-collapse/outcome-driven remapping",
      "Step4E/4F must require exact expression-column vs metadata-row identity and unique cell/sample IDs; no silent reorder",
      "External BH exactly once within each frozen family using raw directional mroast PValue",
      "Every structurally/programmatically unassessable frozen registry row remains present with P_for_BH=1"
    ),
    stringsAsFactors=FALSE
  )
  write_csv(sem, P_SEM)

  guards <- data.frame(
    guard_id=c(
      "G01_DESIGN_FULL_RANK",
      "G02_CONTRAST_ESTIMABLE",
      "G03_ANALYSIS_SAMPLE_NAMES_UNIQUE",
      "G04_ANALYSIS_GENE_NAMES_UNIQUE",
      "G05_ANALYSIS_MATRIX_FINITE",
      "G06_SNRNA_PROGRAM_INDEX_GE10",
      "G07_XENIUM_NO_NEGATIVE_INPUT",
      "G08_XENIUM_477_DENOMINATOR_GT0",
      "G09_XENIUM_PROGRAM_INDEX_GE10",
      "G10_EXACT_GENE_SYMBOL_MATCH",
      "G11_EXPRESSION_METADATA_IDENTITY",
      "G12_NO_FULL_DENSE_SNRNA_MATRIX"
    ),
    check_semantics=c(
      "qr(design)$rank == ncol(design)",
      "contrast vector is finite, length ncol(design), names exactly match colnames(design); with full-rank design the frozen contrast is estimable",
      "anyDuplicated(colnames(test_matrix)) == 0",
      "anyDuplicated(rownames(test_matrix)) == 0",
      "No NA/NaN/Inf in the actual analysis matrix; sparse matrices checked without whole-matrix densification",
      "length(exact_Hallmark_intersect_filterByExpr_retained) >= 10",
      "ANY negative value in frozen ambient-corrected Xenium input => WHOLE GATE HOLD",
      "For every included Xenium patient×annotation pseudobulk, sum across all 477 measured genes > 0; do not silently drop a zero-denominator sample to rescue a test",
      "length(exact_Hallmark_intersect_477_intersect_NONZERO_IN_TEST) >= 10",
      "Exact frozen symbol matching only; no alias/case/fuzzy/outcome-driven repair",
      "identical(colnames(expression_layer), rownames(meta.data)); duplicated cell/sample names forbidden; mismatch => WHOLE GATE HOLD",
      "Full snRNA counts/data must never be converted with full as.matrix(); use Assay5 layer-safe sparse access"
    ),
    failure_scope=c(
      "ROW_OR_TEST_BLOCK_UNASSESSABLE",
      "ROW_OR_TEST_BLOCK_UNASSESSABLE",
      "WHOLE_GATE_HOLD_IF_INPUT_IDENTITY_ERROR",
      "WHOLE_GATE_HOLD_IF_INPUT_IDENTITY_ERROR",
      "WHOLE_GATE_HOLD_IF_SOURCE_MATRIX_NONFINITE; otherwise affected test block unassessable only if deterministically caused by a zero denominator",
      "ROW_UNASSESSABLE_P_FOR_BH_1",
      "WHOLE_GATE_HOLD",
      "AFFECTED_TEST_BLOCK_UNASSESSABLE_P_FOR_BH_1",
      "ROW_UNASSESSABLE_P_FOR_BH_1",
      "WHOLE_GATE_HOLD_IF_SOURCE_IDENTITY_AMBIGUOUS",
      "WHOLE_GATE_HOLD",
      "WHOLE_GATE_HOLD"
    ),
    rescue_prohibited=rep("YES",12),
    stringsAsFactors=FALSE
  )
  write_csv(guards, P_GUARDS)

  PASS("NONZERO_SEMANTICS",
       "Xenium NONZERO_IN_TEST and exact test-specific program index are now explicitly frozen")
  PASS("FAIL_CLOSED_GUARDS",
       "12 Step4E/4F arithmetic/identity/sparse guards explicitly frozen; no algorithm-switch rescue")

  # -----------------------------------------------------------------------
  # 7. Human-readable overlay and repair note
  # -----------------------------------------------------------------------
  note <- c(
    "R3 STEP4D V1.3 — IMPLEMENTATION COMPLETENESS REPAIR NOTE",
    paste0("RUN_ID=",RUN_ID),
    "",
    "SCIENTIFIC CONTRACT CHANGE=NO",
    "REAL RDS READ=NO",
    "REAL EXPRESSION READ=NO",
    "PSEUDOBULK=NO",
    "VOOM=NO",
    "MROAST=NO",
    "SCIENTIFIC RESULTS=NO",
    "",
    "V1.1: independent audit HOLD; superseded.",
    "V1.2: repaired V1.1 family IDs, label order, and exact frozen Xenium eligibility wording;",
    "      independent audit then found implementation-completeness gaps only.",
    "V1.3: preserves the same 840-test scientific universe and exact frozen source order, while",
    "      restoring arithmetic fail-closed guards and defining NONZERO_IN_TEST/index semantics.",
    "",
    "V1.3 IS NOT A SCIENTIFIC REPAIR."
  )
  writeLines(note, P_REPAIR, useBytes=TRUE)

  overlay <- c(
    "R3 STEP4D V1.3 — DETERMINISTIC IMPLEMENTATION OVERLAY",
    paste0("RUN_ID=",RUN_ID),
    "",
    "STATUS=PASS_STEP4D_V1_3_DETERMINISTIC_IMPLEMENTATION_OVERLAY_READY_FOR_INDEPENDENT_AUDIT",
    "STEP4D_SCIENTIFIC_CONTRACT=UNCHANGED",
    "THIS_IS_NOT_A_SCIENTIFIC_REPAIR=TRUE",
    "",
    "NO_REAL_RESULTS_BOUNDARY:",
    "REAL_RDS_READ=NO",
    "REAL_EXPRESSION_VALUE_READ=NO",
    "PSEUDOBULK_EXECUTED=NO",
    "VOOM_EXECUTED=NO",
    "MROAST_EXECUTED=NO",
    "DISEASE_GROUP_TESTING_EXECUTED=NO",
    "LOCALIZATION_SCIENTIFIC_RESULT_PRODUCED=NO",
    "",
    "REGISTRY:",
    "840 rows exactly; source order = frozen FDR family order -> frozen annotation row order -> frozen program tier row order.",
    "test_ordinal=1..840",
    "RNGkind=Mersenne-Twister / Inversion / Rejection",
    "master_seed=20260910",
    "test_seed=master_seed+test_ordinal",
    "seed range=20260911..20261750",
    "ONE assessable registry row = ONE independent mroast() call",
    "set.seed(test_seed) immediately before that call",
    "",
    "PAIRWISE:",
    "Each contrast subsets only its two groups.",
    "design=model.matrix(~0+group), explicit frozen factor levels and explicit named contrast.",
    "snRNA filterByExpr receives design=design in the same pairwise pseudobulk universe.",
    "",
    "MROAST:",
    "set.statistic=mean; nrot=9999; midp=TRUE; adjust.method=none; sort=none;",
    "approx.zscore=TRUE; legacy=FALSE; snRNA trend.var=FALSE; Xenium trend.var=TRUE.",
    "Read raw directional PValue + Direction only; external frozen-family BH is authority.",
    "",
    "SNRNA INDEX:",
    SN_INDEX_DEF,
    "",
    "XENIUM NONZERO_IN_TEST:",
    NONZERO_DEF,
    "",
    "XENIUM INDEX:",
    XE_INDEX_DEF,
    "",
    "XENIUM FROZEN ELIGIBILITY:",
    XEN_RULE,
    "",
    "FAIL-CLOSED:",
    "Design full-rank and contrast-estimability guards.",
    "Unique sample/gene names and finite analysis matrix guards.",
    "snRNA exact retained-program index >=10.",
    "Xenium any negative corrected input => whole Gate HOLD.",
    "Xenium each included 477-gene pseudobulk denominator >0.",
    "Xenium exact measured-and-NONZERO_IN_TEST program index >=10.",
    "Exact gene-symbol matching only.",
    "Expression colnames vs metadata rownames exact identity; no silent reorder.",
    "No full dense as.matrix() of snRNA Assay5 layers.",
    "No temporary alternate algorithm/threshold/remapping rescue.",
    "",
    "NEXT AFTER INDEPENDENT CLEAN AUDIT:",
    "R3 Step4E runtime + BROAD/FINE design-feasibility preflight.",
    "Step4E remains ZERO real localization program results."
  )
  writeLines(overlay, P_OVERLAY, useBytes=TRUE)

  # -----------------------------------------------------------------------
  # 8. Write/re-read registry
  # -----------------------------------------------------------------------
  write_csv(reg, P_REG)
  rr <- read.csv(P_REG, check.names=FALSE, stringsAsFactors=FALSE)
  if (nrow(rr)!=840L ||
      length(unique(rr$test_key))!=840L ||
      length(unique(rr$test_ordinal))!=840L ||
      length(unique(rr$test_seed))!=840L ||
      !identical(unique(as.character(rr$family_id)), FAMILY_IDS)) {
    HOLD("REG_WRITEBACK", "on-disk registry recheck failed")
  }
  PASS("REG_WRITEBACK", "on-disk registry 840-row identity/family-order recheck PASS")

  # -----------------------------------------------------------------------
  # 9. Frozen source manifest
  # -----------------------------------------------------------------------
  man <- data.frame(
    basename=basename(FROZEN_SOURCES),
    source_path=normalizePath(FROZEN_SOURCES, winslash="/", mustWork=TRUE),
    bytes=as.numeric(file.info(FROZEN_SOURCES)$size),
    expected_sha256=unname(EXPECTED_SOURCE_SHA256[basename(FROZEN_SOURCES)]),
    stringsAsFactors=FALSE
  )
  if (any(is.na(man$expected_sha256)) || any(nchar(man$expected_sha256)!=64))
    HOLD("SOURCE_SHA_MANIFEST", "expected SHA constants incomplete")
  write_csv(man, P_SOURCE_MAN)
  PASS("SOURCE_SHA_MANIFEST", "7 expected frozen-source SHA256 values recorded for independent package audit")

  copy_stage(c(FROZEN_SOURCES, P_REG, P_SEM, P_GUARDS, P_OVERLAY,
               P_SOURCE_MAN, P_REPAIR))

  final_state <<- "PASS_STEP4D_V1_3_DETERMINISTIC_IMPLEMENTATION_OVERLAY_READY_FOR_INDEPENDENT_AUDIT"
  PASS("FINAL_GATE", final_state)
}

rc <- 0L
tryCatch(
  main(),
  error=function(e) {
    cat("\nERROR/HOLD:\n",conditionMessage(e),"\n",sep="")
    if (!grepl("^HOLD:",conditionMessage(e)))
      add("UNEXPECTED_RUNTIME_ERROR","FAIL",conditionMessage(e))
    rc <<- 2L
  }
)

finalize()

cat("\nFINAL STATE: ",final_state,"\n",sep="")
cat("RUN DIR: ",RUNDIR,"\n",sep="")
cat("STAGING DIR: ",STAGING,"\n",sep="")
quit(save="no", status=rc)
