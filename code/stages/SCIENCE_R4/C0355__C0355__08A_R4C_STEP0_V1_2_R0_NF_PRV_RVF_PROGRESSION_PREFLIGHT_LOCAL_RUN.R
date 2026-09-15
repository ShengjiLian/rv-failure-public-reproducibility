# ---- RV PUBLIC PRIMARY DAG GATE9J REWRITE V1.0 ----
# source_id=C0355
# rewrite_scope=TIMESTAMP_ONLY
# Historical Gate9F source remains immutable provenance.
# This public copy removes only run-history/machine-generation dependencies;
# frozen scientific/statistical semantics, thresholds and accepted outputs are unchanged.
# ----------------------------------------------------
# Gate9K V1.30 repair: current R4B terminal STATUS semantic binding only; science unchanged.
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
# RV Project — R4C Step0
# R0 NF -> pRV -> RVF PATIENT-LEVEL PROGRAM PROGRESSION — PREFLIGHT ONLY
#
# NO program score.
# NO NF/pRV/RVF group mean/median comparison.
# NO trend classification.
# NO inferential test.
# NO new program/gene discovery.
# NO DESeq2 refit.
#
# Purpose:
#   Bind the exact frozen R0 fitted DDS, exact 142-sample map, frozen R0 primary
#   summary, stable16 program identities/directions, and exact Hallmark GMT
#   BEFORE any patient-level progression score is calculated.
#
# Scientific boundary:
#   R0 contributed directly to discovery of the frozen stable16 programs.
#   Therefore R4C is DESCRIPTIVE PROGRESSION CHARACTERIZATION, not independent
#   validation. It must not generate circular confirmatory significance claims.
# ==============================================================================

options(stringsAsFactors=FALSE, warn=1)
args <- commandArgs(trailingOnly=TRUE)
STAMP <- if(length(args)>=1 && nzchar(args[1])) args[1] else format(Sys.time(),"%Y%m%d_%H%M%S")

ROOT <- normalizePath(getwd(),winslash="/",mustWork=TRUE)
if(!identical(ROOT,RV_PROJECT_ROOT)) stop("Expected working directory D:/RV_project",call.=FALSE)

OUTROOT <- file.path(ROOT,"results","R4C_R0_NF_PRV_RVF_PROGRESSION_PREFLIGHT_V1_2")
OUT <- file.path(OUTROOT,STAMP)
dir.create(OUT,recursive=TRUE,showWarnings=FALSE)

# Orchestration-only guard: R4B must already be terminal closed.
R4B_STATUS <- rv_stage_file(
  file.path(ROOT,"results","R4B_PEA_PATIENT_TRAJECTORY_POSTGEN_VALIDATION"),
  "R4B_STEP3_STATUS.csv"
)

R0_DIR <- file.path(ROOT,"results","R0","v4_LOCAL_RUN")
DDS <- file.path(R0_DIR,"R0_fitted_dds.rds")
SAMPLE_MAP <- file.path(R0_DIR,"R0_exact_step1_sample_map.csv")
R0_SUMMARY <- file.path(R0_DIR,"R0_FINAL_RVF_vs_pRV_summary.csv")

A20 <- file.path(
  ROOT,"results","R3_GSE249696",
  "R3_STEP3F_V1_1_stable_program_identity_class_freeze.csv"
)
GMT <- file.path(
  ROOT,"data","authority","MSigDB",
  "h.all.v2026.1.Hs.symbols.gmt"
)

EXPECTED_EXACT_SHA <- c(
  R4B_STATUS="3f61a19e433cd28b0907a421d0c012a7d54c6a788c9413583a166e6fa1a1ae3c",
  DDS="cfe6b796af4cc12b8663217835f0fdc7fd9053e2180b298773f3b3bbe0e12845",
  SAMPLE_MAP="e4f51929b8d8a928690b8b90969d9e3ecb0349b9f47408e4828b32d6a3b7a175",
  R0_SUMMARY="0e58f122b0fba4832e3d00b1697b196978793ba716b95b8c01e1964f811b4355",
  A20="49cd4da614f699f1c35d91e61d1bc59e2add6483c71aa23947fdab49a6a60068",
  GMT="eecaf6dad908334ae885406ec72bdc0646d8917588ed7c219fac92fc5363f596"
)

# V1.1 technical repair:
# R0 was originally executed with packages under the normal Windows user library,
# whereas later R4 modules also use the project library. Make both visible
# deterministically before namespace checks; this changes no scientific method.
project_lib <- file.path(ROOT,"R_library","R-4.6")
windows_user_lib <- file.path(Sys.getenv("LOCALAPPDATA"),"R","win-library","4.6")
lib_candidates <- c(project_lib,windows_user_lib)
lib_candidates <- lib_candidates[dir.exists(lib_candidates)]
.libPaths(unique(c(lib_candidates,.libPaths())))

boot_rows <- data.frame(
  component=c("project_library","windows_user_library","digest","DESeq2"),
  observed=c(
    project_lib,
    windows_user_lib,
    if(requireNamespace("digest",quietly=TRUE)) as.character(utils::packageVersion("digest")) else "NOT_AVAILABLE",
    if(requireNamespace("DESeq2",quietly=TRUE)) as.character(utils::packageVersion("DESeq2")) else "NOT_AVAILABLE"
  ),
  status=c(
    if(dir.exists(project_lib)) "AVAILABLE" else "ABSENT_NONCRITICAL",
    if(dir.exists(windows_user_lib)) "AVAILABLE" else "ABSENT_NONCRITICAL",
    if(requireNamespace("digest",quietly=TRUE)) "PASS" else "FAIL",
    if(requireNamespace("DESeq2",quietly=TRUE)) "PASS" else "FAIL"
  ),
  stringsAsFactors=FALSE
)
write.csv(boot_rows,file.path(OUT,"R4C_STEP0_BOOT_ENVIRONMENT.csv"),row.names=FALSE,na="")

if(!requireNamespace("digest",quietly=TRUE) || !requireNamespace("DESeq2",quietly=TRUE)) {
  write.csv(data.frame(
    final_state="HOLD_R4C_STEP0_BOOT_ENVIRONMENT",
    run_id=STAMP,
    hard_failures=1,
    program_scores_calculated="NO",
    group_progression_compared="NO",
    progression_classes_assigned="NO",
    inferential_tests_executed="NO",
    DESeq2_refit_executed="NO",
    error="Required R namespace unavailable after project + Windows-user library fallback",
    stringsAsFactors=FALSE
  ),file.path(OUT,"R4C_STEP0_STATUS.csv"),row.names=FALSE,na="")
  quit(save="no",status=140,runLast=FALSE)
}
sha256 <- function(p) digest::digest(file=p,algo="sha256",serialize=FALSE)

# Gate9L Full94 V1.6:
# R0_fitted_dds.rds is a serialized intermediate.  Preserve the historical
# whole-file SHA as provenance, but bind fresh Full94 runs to the exact current
# R0 producer semantics plus the existing full DDS semantic audit below.
# No current-run DDS SHA is promoted to frozen authority.
r0_dds_current_run_authority <- function(path) {
  gate <- file.path(R0_DIR,"R0_EXACT_MODEL_FIT_HOLD.txt")
  if(!file.exists(path) || !file.exists(gate)) {
    return(list(ok=FALSE,detail="DDS or current R0 fit gate missing"))
  }
  g <- readLines(gate,warn=FALSE)
  getv <- function(k) {
    z <- grep(paste0("^",k,"="),g,value=TRUE)
    if(length(z)!=1L) return("")
    sub(paste0("^",k,"="),"",z[1L])
  }
  current_sha <- tolower(sha256(path))
  ok <- length(g)>=1L &&
    identical(g[1L],"R0_EXACT_MODEL_FIT_HOLD_BETA_CONVERGENCE") &&
    identical(getv("implementation"),"v4_LOCAL_RUN") &&
    identical(getv("DESeq_executed"),"YES") &&
    identical(getv("DESeq_rerun_authorized"),"NO") &&
    identical(getv("fitted_genes"),"19428") &&
    identical(getv("samples"),"142") &&
    identical(getv("beta_converged"),"18621") &&
    identical(getv("beta_nonconverged"),"807") &&
    identical(getv("betaConv_NA"),"0") &&
    identical(getv("fitted_checkpoint"),"results/R0/v4_LOCAL_RUN/R0_fitted_dds.rds") &&
    grepl("^[0-9a-f]{64}$",current_sha) &&
    is.finite(file.info(path)$size) && file.info(path)$size>0
  list(
    ok=ok,
    detail=paste0(
      "current_sha256=",current_sha,
      "; current_bytes=",file.info(path)$size,
      "; producer_gate=",if(length(g)) g[1L] else "EMPTY",
      "; betaConv=",getv("beta_converged"),"/",getv("beta_nonconverged"),"/",getv("betaConv_NA")
    )
  )
}



# Gate9L Full94 V1.4: A31 is a scientific-stable sample map with one
# run-root-bearing representation field (h5_path).  Normalize only that prefix
# back to the frozen canonical path and require exact historical SHA256.
r0_sample_map_path_normalized <- function(path) {
  if(!file.exists(path)) return(list(ok=FALSE,detail="sample map missing"))
  raw <- readBin(path,"raw",n=file.info(path)$size)
  txt <- rawToChar(raw)
  current_prefix <- paste0(
    normalizePath(file.path(ROOT,"data","tximport","GSE345645","h5"),
                  winslash="/",mustWork=TRUE),"/"
  )
  historical_prefix <- "D:/RV_project/data/tximport/GSE345645/h5/"
  m <- gregexpr(current_prefix,txt,fixed=TRUE)[[1L]]
  n_hit <- if(length(m)==1L && identical(as.integer(m[1L]),-1L)) 0L else length(m)
  norm_txt <- gsub(current_prefix,historical_prefix,txt,fixed=TRUE)
  norm_raw <- charToRaw(norm_txt)
  tf <- tempfile(pattern="g9l_v14_a31_",fileext=".csv")
  con <- file(tf,open="wb")
  on.exit({try(close(con),silent=TRUE);unlink(tf,force=TRUE)},add=TRUE)
  writeBin(norm_raw,con)
  close(con)
  norm_sha <- tolower(sha256(tf))
  ok <- n_hit==142L &&
        length(norm_raw)==15511L &&
        identical(norm_sha,"e4f51929b8d8a928690b8b90969d9e3ecb0349b9f47408e4828b32d6a3b7a175")
  list(ok=ok,
       detail=paste0("hits=",n_hit,
                     "; current_bytes=",length(raw),
                     "; normalized_bytes=",length(norm_raw),
                     "; normalized_sha256=",norm_sha))
}

awrite <- function(x,p) {
  t <- paste0(p,".tmp_",Sys.getpid())
  write.csv(x,t,row.names=FALSE,na="",quote=TRUE)
  if(file.exists(p)) unlink(p,force=TRUE)
  if(!file.rename(t,p)) {
    unlink(t)
    stop("Atomic CSV write failed: ",p,call.=FALSE)
  }
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
  R4B_STATUS=R4B_STATUS,
  DDS=DDS,
  SAMPLE_MAP=SAMPLE_MAP,
  R0_SUMMARY=R0_SUMMARY,
  A20=A20,
  GMT=GMT
)

for(nm in names(P)) {
  check(paste0("FILE_",nm),paste0(nm," exists"),file.exists(P[[nm]]),P[[nm]])
}

if(any(!vapply(P,file.exists,logical(1)))) {
  awrite(do.call(rbind,AUD),file.path(OUT,"R4C_STEP0_PREFLIGHT_AUDIT.csv"))
  awrite(data.frame(
    final_state="HOLD_R4C_STEP0_MISSING_INPUT",
    run_id=STAMP,
    hard_failures=1,
    program_scores_calculated="NO",
    group_progression_compared="NO",
    progression_classes_assigned="NO",
    inferential_tests_executed="NO",
    DESeq2_refit_executed="NO",
    stringsAsFactors=FALSE
  ),file.path(OUT,"R4C_STEP0_STATUS.csv"))
  quit(save="no",status=141,runLast=FALSE)
}

# Stable scientific inputs remain historical exact-SHA. R4B terminal STATUS is
# run-bearing, so bind it to the uniquely resolved current run and exact terminal semantics.
for(nm in names(EXPECTED_EXACT_SHA)) {
  got <- sha256(P[[nm]])
  if(identical(nm,"R4B_STATUS")) {
    r4b_pre <- read.csv(R4B_STATUS,stringsAsFactors=FALSE,check.names=FALSE)
    r4b_run_id <- basename(dirname(R4B_STATUS))
    need <- c("final_state","run_id","hard_failures","source_level_independent_reconstruction",
              "Step2_scientific_outputs_modified","new_scientific_testing","inferential_tests_executed",
              "multiple_testing_FDR_executed","responder_subgroups_defined","thresholds_retuned",
              "terminal_closed","next_stage")
    ok <- nrow(r4b_pre)==1L && all(need %in% names(r4b_pre)) &&
      identical(as.character(r4b_pre$final_state[1]),"FINAL_CLOSED_R4B_PEA_PATIENT_LEVEL_TRAJECTORY_CHARACTERIZATION") &&
      identical(as.character(r4b_pre$run_id[1]),r4b_run_id) &&
      identical(as.integer(r4b_pre$hard_failures[1]),0L) &&
      identical(as.character(r4b_pre$source_level_independent_reconstruction[1]),"YES") &&
      identical(as.character(r4b_pre$Step2_scientific_outputs_modified[1]),"NO") &&
      identical(as.character(r4b_pre$new_scientific_testing[1]),"NO") &&
      identical(as.character(r4b_pre$inferential_tests_executed[1]),"NO") &&
      identical(as.character(r4b_pre$multiple_testing_FDR_executed[1]),"NO") &&
      identical(as.character(r4b_pre$responder_subgroups_defined[1]),"NO") &&
      identical(as.character(r4b_pre$thresholds_retuned[1]),"NO") &&
      identical(as.character(r4b_pre$terminal_closed[1]),"YES") &&
      identical(as.character(r4b_pre$next_stage[1]),"R4C_R0_NF_PRV_RVF_PROGRESSION_PREFLIGHT")
    check(paste0("SHA_",nm),"R4B_STATUS exact current-run terminal semantic binding",ok,
          if(nrow(r4b_pre)) paste(r4b_pre$run_id[1],r4b_pre$final_state[1],r4b_pre$hard_failures[1],sep=" | ") else "NO_ROW")
  } else if(identical(nm,"DDS")) {
    dds_auth <- r0_dds_current_run_authority(P[[nm]])
    check(
      "SHA_DDS",
      "DDS current-run producer/semantic authority; historical serialized SHA retained as provenance",
      isTRUE(dds_auth$ok),
      paste0(dds_auth$detail,"; historical_sha256=",EXPECTED_EXACT_SHA[[nm]]),
      notes="No fresh DDS SHA is frozen. The same audit still requires exact DDS class/dim/sample/category/design/normalization/avgTxLength/betaConv semantics; downstream R4C outcome tables remain historical exact-SHA guarded."
    )
  } else if(identical(nm,"SAMPLE_MAP")) {
    sm_auth <- r0_sample_map_path_normalized(P[[nm]])
    check(
      "SHA_SAMPLE_MAP",
      "SAMPLE_MAP frozen authority exact after h5_path-only run-root normalization",
      isTRUE(sm_auth$ok),
      paste0("raw_sha256=",got,"; ",sm_auth$detail),
      notes="Scientific/sample/H5-byte content unchanged; only h5_path representation is normalized."
    )
  } else {
    check(
      paste0("SHA_",nm),
      paste0(nm," exact frozen SHA256"),
      identical(tolower(got),tolower(EXPECTED_EXACT_SHA[[nm]])),
      got
    )
  }
}

r4b <- read.csv(R4B_STATUS,stringsAsFactors=FALSE,check.names=FALSE)
check(
  "R4B_CLOSED",
  "R4B terminal closure complete before R4C starts",
  nrow(r4b)==1L &&
    identical(
      r4b$final_state[1],
      "FINAL_CLOSED_R4B_PEA_PATIENT_LEVEL_TRAJECTORY_CHARACTERIZATION"
    ) &&
    identical(r4b$terminal_closed[1],"YES") &&
    as.integer(r4b$hard_failures[1])==0L,
  if(nrow(r4b)) paste(
    r4b$final_state[1],r4b$terminal_closed[1],r4b$hard_failures[1],
    sep=" | "
  ) else "NO_ROW"
)

# --------------------------------------------------------------------------
# R0 sample authority.
# --------------------------------------------------------------------------
sm <- read.csv(SAMPLE_MAP,stringsAsFactors=FALSE,check.names=FALSE)
required_sm <- c("sample_id","disease_group")
check(
  "SAMPLE_SCHEMA",
  "R0 exact sample map contains sample_id and disease_group",
  all(required_sm %in% names(sm)),
  paste(setdiff(required_sm,names(sm)),collapse=";")
)

if(all(required_sm %in% names(sm))) {
  sm$sample_id <- trimws(as.character(sm$sample_id))
  sm$disease_group <- trimws(as.character(sm$disease_group))
  check("SAMPLE_N142","R0 exact sample map has 142 rows",nrow(sm)==142L,nrow(sm))
  check(
    "SAMPLE_ID_UNIQUE",
    "R0 exact sample IDs are complete and unique",
    !anyNA(sm$sample_id) &&
      !any(sm$sample_id=="") &&
      !anyDuplicated(sm$sample_id) &&
      length(unique(sm$sample_id))==142L,
    length(unique(sm$sample_id))
  )
  grp <- table(factor(sm$disease_group,levels=c("NF","pRV","RVF")))
  check(
    "GROUP_COUNTS",
    "R0 groups are NF=29 / pRV=78 / RVF=35",
    identical(as.integer(grp),c(29L,78L,35L)),
    paste0("NF=",grp["NF"],";pRV=",grp["pRV"],";RVF=",grp["RVF"])
  )
  check(
    "GROUP_LEVELS",
    "Only NF/pRV/RVF disease groups are present",
    setequal(unique(sm$disease_group),c("NF","pRV","RVF")),
    paste(sort(unique(sm$disease_group)),collapse=";")
  )
}

# --------------------------------------------------------------------------
# Frozen R0 primary summary authority.
# --------------------------------------------------------------------------
rs <- read.csv(R0_SUMMARY,stringsAsFactors=FALSE,check.names=FALSE)
check(
  "R0_SUMMARY_SCHEMA",
  "R0 frozen summary contains metric/value",
  all(c("metric","value") %in% names(rs)),
  paste(names(rs),collapse=";")
)
if(all(c("metric","value") %in% names(rs))) {
  rv <- setNames(as.character(rs$value),rs$metric)
  expected_summary <- c(
    filtered_genes_total="19428",
    primary_assessable_genes="18621",
    primary_nonassessable_beta_nonconverged="807",
    primary_FDR_lt_0_05="330",
    primary_FDR_lt_0_05_up="314",
    primary_FDR_lt_0_05_down="16",
    maxit1000_used_as_primary="0",
    new_statistical_computation_in_step3D="0"
  )
  for(k in names(expected_summary)) {
    check(
      paste0("R0_SUMMARY_",k),
      paste0("Frozen R0 summary ",k," exact"),
      !is.null(rv[[k]]) &&
        identical(as.character(rv[[k]]),as.character(expected_summary[[k]])),
      if(!is.null(rv[[k]])) rv[[k]] else "MISSING"
    )
  }
}

# --------------------------------------------------------------------------
# Frozen fitted DDS inspection only.
# NO normalized-count extraction and NO progression scoring in Step0.
# --------------------------------------------------------------------------
dds_error <- NULL
dds <- tryCatch(
  readRDS(DDS),
  error=function(e) {
    dds_error <<- conditionMessage(e)
    NULL
  }
)
if(is.null(dds)) {
  write.csv(data.frame(
    component="R0_fitted_dds.rds",
    path=DDS,
    error=if(is.null(dds_error)) "UNKNOWN_READRDS_FAILURE" else dds_error,
    stringsAsFactors=FALSE
  ),file.path(OUT,"R4C_STEP0_DDS_READ_ERROR.csv"),row.names=FALSE,na="")
  write.csv(data.frame(
    final_state="HOLD_R4C_STEP0_DDS_READ",
    run_id=STAMP,
    hard_failures=1,
    program_scores_calculated="NO",
    group_progression_compared="NO",
    progression_classes_assigned="NO",
    inferential_tests_executed="NO",
    DESeq2_refit_executed="NO",
    error=if(is.null(dds_error)) "UNKNOWN_READRDS_FAILURE" else dds_error,
    stringsAsFactors=FALSE
  ),file.path(OUT,"R4C_STEP0_STATUS.csv"),row.names=FALSE,na="")
  quit(save="no",status=143,runLast=FALSE)
}
check(
  "DDS_CLASS",
  "R0 fitted object is a DESeqDataSet",
  inherits(dds,"DESeqDataSet"),
  paste(class(dds),collapse=";")
)

if(inherits(dds,"DESeqDataSet")) {
  check(
    "DDS_DIM",
    "Frozen R0 fitted DDS is 19,428 genes x 142 samples",
    identical(as.integer(dim(dds)),c(19428L,142L)),
    paste(dim(dds),collapse="x")
  )
  check(
    "DDS_GENE_UNIQUE",
    "DDS gene row names are complete and unique",
    !is.null(rownames(dds)) &&
      !anyNA(rownames(dds)) &&
      !any(rownames(dds)=="") &&
      !anyDuplicated(rownames(dds)),
    paste0("unique=",length(unique(rownames(dds))))
  )
  check(
    "DDS_SAMPLE_UNIQUE",
    "DDS column names are complete and unique",
    !is.null(colnames(dds)) &&
      !anyNA(colnames(dds)) &&
      !any(colnames(dds)=="") &&
      !anyDuplicated(colnames(dds)),
    paste0("unique=",length(unique(colnames(dds))))
  )
  check(
    "DDS_SAMPLE_SET",
    "DDS sample set exactly equals R0 exact sample map",
    all(required_sm %in% names(sm)) &&
      setequal(colnames(dds),sm$sample_id),
    paste0(
      "DDS_only=",length(setdiff(colnames(dds),sm$sample_id)),
      ";map_only=",length(setdiff(sm$sample_id,colnames(dds)))
    )
  )
  cd <- as.data.frame(SummarizedExperiment::colData(dds))
  check(
    "DDS_CATEGORY",
    "DDS colData contains category",
    "category" %in% names(cd),
    paste(names(cd),collapse=";")
  )
  if("category" %in% names(cd)) {
    dgrp <- as.character(cd$category)
    names(dgrp) <- rownames(cd)
    mapped_grp <- sm$disease_group[match(colnames(dds),sm$sample_id)]
    check(
      "DDS_CATEGORY_MATCH",
      "DDS category exactly matches frozen sample-map disease_group",
      identical(unname(dgrp[colnames(dds)]),unname(mapped_grp)),
      paste0("matched=",sum(dgrp[colnames(dds)]==mapped_grp),"/142")
    )
  }
  design_txt <- paste(deparse(DESeq2::design(dds)),collapse="")
  expected_design <- "~category + SV1 + SV2 + SV3 + SV4 + SV5 + SV6 + SV7 + SV8 + SV9 + SV10 + SV11 + SV12 + SV13 + SV14 + SV15 + SV16 + SV17 + SV18 + SV19 + SV20 + SV21"
  check(
    "DDS_DESIGN",
    "Frozen DDS retains exact author-model design",
    identical(gsub("\\s+","",design_txt),gsub("\\s+","",expected_design)),
    design_txt
  )
  # V1.2 technical repair:
  # tximport + avgTxLength DESeq2 objects may carry normalization in a
  # gene-by-sample normalizationFactors matrix rather than a sample-only
  # sizeFactors vector. Both are legal DESeq2 states; the frozen object must
  # have at least one complete positive normalization authority.
  sf <- DESeq2::sizeFactors(dds)
  nf <- DESeq2::normalizationFactors(dds)

  sf_ok <- length(sf)==142L && all(is.finite(sf) & sf>0)
  nf_ok <- !is.null(nf) &&
           identical(as.integer(dim(nf)),c(19428L,142L)) &&
           all(is.finite(nf)) && all(nf>0)

  check(
    "DDS_NORMALIZATION_AUTHORITY",
    "Frozen DDS has a complete positive DESeq2 normalization authority",
    sf_ok || nf_ok,
    paste0(
      "sizeFactors_n=",length(sf),
      ";normalizationFactors=",
      if(is.null(nf)) "NULL" else paste(dim(nf),collapse="x"),
      ";sf_ok=",sf_ok,
      ";nf_ok=",nf_ok
    ),
    notes="V1.2 repair: tximport+avgTxLength may store gene-by-sample normalizationFactors instead of sample-only sizeFactors"
  )

  check(
    "DDS_NORMALIZATION_MODE",
    "Frozen normalization mode is explicitly identified before Step1",
    sf_ok || nf_ok,
    if(nf_ok) "GENE_BY_SAMPLE_NORMALIZATION_FACTORS"
    else if(sf_ok) "SAMPLE_SIZE_FACTORS"
    else "NO_VALID_NORMALIZATION_AUTHORITY"
  )

  avg_present_filtered <- "avgTxLength" %in% SummarizedExperiment::assayNames(dds)
  avg_ok_filtered <- FALSE
  if(avg_present_filtered) {
    av <- SummarizedExperiment::assay(dds,"avgTxLength")
    avg_ok_filtered <- identical(as.integer(dim(av)),c(19428L,142L)) &&
                       all(is.finite(av)) && all(av>0)
  }
  check(
    "DDS_AVGTXLENGTH",
    "Frozen filtered DDS retains finite positive avgTxLength 19,428 x 142",
    avg_present_filtered && avg_ok_filtered,
    if(avg_present_filtered) paste(dim(SummarizedExperiment::assay(dds,"avgTxLength")),collapse="x")
    else "ABSENT"
  )

  # betaConv confirms this is the fitted frozen object, without refitting.
  bc <- S4Vectors::mcols(dds)$betaConv
  check(
    "DDS_BETACONV",
    "Frozen fitted DDS retains 18,621 converged / 807 nonconverged genes",
    length(bc)==19428L &&
      sum(bc %in% TRUE,na.rm=TRUE)==18621L &&
      sum(bc %in% FALSE,na.rm=TRUE)==807L &&
      sum(is.na(bc))==0L,
    paste0(
      "TRUE=",sum(bc %in% TRUE,na.rm=TRUE),
      ";FALSE=",sum(bc %in% FALSE,na.rm=TRUE),
      ";NA=",sum(is.na(bc))
    )
  )
}

# --------------------------------------------------------------------------
# Stable16 + Hallmark mapping identity.
# No expression scores are computed.
# --------------------------------------------------------------------------
a20 <- read.csv(A20,stringsAsFactors=FALSE,check.names=FALSE)
check(
  "A20_SCHEMA",
  "Frozen stable-program table contains required columns",
  all(c("pathway","failure_direction","program_class") %in% names(a20)),
  paste(setdiff(c("pathway","failure_direction","program_class"),names(a20)),
        collapse=";")
)
check(
  "STABLE16",
  "Frozen target family is exactly 16 programs",
  nrow(a20)==16L && length(unique(a20$pathway))==16L,
  nrow(a20)
)
check(
  "FAILURE_DIRECTION",
  "Every stable16 program has frozen UP/DOWN failure direction",
  all(a20$failure_direction %in% c("UP_IN_FAILURE","DOWN_IN_FAILURE")),
  paste(sort(unique(a20$failure_direction)),collapse=";")
)

gl <- readLines(GMT,warn=FALSE)
parts <- strsplit(gl,"\t",fixed=TRUE)
gmt_names <- vapply(parts,`[`,character(1),1L)
gmt_genes <- lapply(
  parts,
  function(x) unique(if(length(x)>=3L) x[3:length(x)] else character())
)
names(gmt_genes) <- gmt_names

check("GMT50","Exact Hallmark GMT contains 50 sets",length(gmt_genes)==50L,length(gmt_genes))
check(
  "STABLE16_GMT",
  "All stable16 programs are present in exact GMT",
  all(a20$pathway %in% names(gmt_genes)),
  paste(setdiff(a20$pathway,names(gmt_genes)),collapse=";")
)

dds_genes <- rownames(dds)
gene_tab <- table(dds_genes)
all_target_symbols <- unique(unlist(gmt_genes[a20$pathway],use.names=FALSE))
dup_targets <- names(gene_tab)[names(gene_tab) %in% all_target_symbols & as.integer(gene_tab)>1L]
check(
  "TARGET_SYMBOL_UNIQUENESS",
  "Every stable16 member symbol maps to at most one DDS row",
  length(dup_targets)==0L,
  paste(dup_targets,collapse=";")
)

map_rows <- list()
for(pid in a20$pathway) {
  members <- gmt_genes[[pid]]
  mapped <- members %in% dds_genes
  map_rows[[length(map_rows)+1L]] <- data.frame(
    pathway=pid,
    failure_direction=a20$failure_direction[match(pid,a20$pathway)],
    program_class=a20$program_class[match(pid,a20$pathway)],
    gmt_member_n=length(members),
    exact_symbol_mapped_n=sum(mapped),
    mapped_fraction=sum(mapped)/length(members),
    unmapped_symbols=paste(members[!mapped],collapse=";"),
    mapping_rule="TRIMMED_EXACT_HGNC_SYMBOL_TO_FROZEN_FILTERED_DDS_ROWNAME",
    duplicate_policy="FAIL_IF_STABLE16_MEMBER_SYMBOL_MAPS_TO_MULTIPLE_DDS_ROWS",
    stringsAsFactors=FALSE
  )
}
map_audit <- do.call(rbind,map_rows)
check(
  "STABLE16_MAPPING80",
  "Every stable16 program has >=80% exact-symbol mapping to frozen DDS",
  all(map_audit$mapped_fraction>=0.80),
  paste0("min=",format(min(map_audit$mapped_fraction),digits=6))
)
awrite(map_audit,file.path(OUT,"R4C_STEP0_PROGRAM_MAPPING_AUDIT.csv"))

# --------------------------------------------------------------------------
# Record source identities. R0 object hashes are frozen HERE only as observed
# preflight identities; Step1 must bind these exact values after independent audit.
# --------------------------------------------------------------------------
input_rows <- do.call(rbind,lapply(names(P),function(nm) data.frame(
  input_id=nm,
  path=P[[nm]],
  bytes=file.info(P[[nm]])$size,
  sha256=sha256(P[[nm]]),
  prior_exact_sha_guard=if(identical(nm,"SAMPLE_MAP")) "YES_PATH_NORMALIZED_H5_PATH_ONLY" else if(identical(nm,"DDS")) "CURRENT_RUN_SEMANTIC_DDS_CHAIN_HIST_SHA_PROVENANCE" else if(nm %in% names(EXPECTED_EXACT_SHA)) "YES" else "NO_PREVIOUS_R4C_BINDING",
  stringsAsFactors=FALSE
)))
awrite(input_rows,file.path(OUT,"R4C_STEP0_INPUT_SHA256.csv"))

sf_final <- DESeq2::sizeFactors(dds)
nf_final <- DESeq2::normalizationFactors(dds)
normalization_mode <- if(!is.null(nf_final) &&
                         identical(as.integer(dim(nf_final)),c(19428L,142L)) &&
                         all(is.finite(nf_final)) && all(nf_final>0)) {
  "GENE_BY_SAMPLE_NORMALIZATION_FACTORS"
} else if(length(sf_final)==142L &&
          all(is.finite(sf_final) & sf_final>0)) {
  "SAMPLE_SIZE_FACTORS"
} else {
  "INVALID"
}

sample_summary <- data.frame(
  metric=c(
    "samples_total","NF","pRV","RVF","dds_genes","dds_samples",
    "normalization_mode","normalization_factor_rows","normalization_factor_cols",
    "size_factor_n","stable_programs","Hallmark_sets"
  ),
  value=c(
    nrow(sm),
    sum(sm$disease_group=="NF"),
    sum(sm$disease_group=="pRV"),
    sum(sm$disease_group=="RVF"),
    nrow(dds),ncol(dds),
    normalization_mode,
    if(is.null(nf_final)) 0L else nrow(nf_final),
    if(is.null(nf_final)) 0L else ncol(nf_final),
    length(sf_final),
    nrow(a20),length(gmt_genes)
  ),
  stringsAsFactors=FALSE
)
awrite(sample_summary,file.path(OUT,"R4C_STEP0_R0_STRUCTURE_SUMMARY.csv"))

boundary <- data.frame(
  item=c(
    "module",
    "analysis_role",
    "cohort",
    "biological_replicate",
    "sample_n",
    "NF_n",
    "pRV_n",
    "RVF_n",
    "target_family",
    "target_n",
    "R0_used_in_target_discovery",
    "independent_validation_allowed",
    "expression_authority",
    "normalization_authority_candidate_for_step1",
    "DESeq2_refit_allowed",
    "program_scores_calculated",
    "NF_pRV_RVF_group_values_compared",
    "progression_classes_assigned",
    "inferential_tests_executed",
    "new_program_discovery",
    "new_gene_discovery",
    "threshold_retuning",
    "next_stage"
  ),
  value=c(
    "R4C_R0_NF_PRV_RVF_PROGRESSION",
    "DESCRIPTIVE_WITHIN_R0_PROGRESSION_CHARACTERIZATION",
    "GSE345645_ADULT_RV_BULK",
    "PATIENT",
    "142",
    "29",
    "78",
    "35",
    "FROZEN_R0_R1_STABLE16",
    "16",
    "YES",
    "NO",
    "FROZEN_R0_FITTED_DDS_READ_ONLY",
    "DESEQ2_COUNTS_NORMALIZED_TRUE_FROM_FROZEN_FITTED_DDS_USING_FROZEN_NORMALIZATION_AUTHORITY_NO_REFIT",
    "NO",
    "NO",
    "NO",
    "NO",
    "NO",
    "NO",
    "NO",
    "NO",
    "R4C_STEP1_PROGRESSION_METHOD_CONTRACT_AFTER_INDEPENDENT_AUDIT"
  ),
  stringsAsFactors=FALSE
)
awrite(boundary,file.path(OUT,"R4C_STEP0_CONTRACT_BOUNDARY.csv"))

audit <- do.call(rbind,AUD)
hard_fail <- sum(audit$status=="FAIL" & audit$critical=="YES")
awrite(audit,file.path(OUT,"R4C_STEP0_PREFLIGHT_AUDIT.csv"))

state <- if(hard_fail==0L) {
  "PASS_R4C_STEP0_PREFLIGHT_READY_FOR_INDEPENDENT_AUDIT"
} else {
  "HOLD_R4C_STEP0_PREFLIGHT"
}

awrite(data.frame(
  final_state=state,
  run_id=STAMP,
  hard_failures=hard_fail,
  program_scores_calculated="NO",
  group_progression_compared="NO",
  progression_classes_assigned="NO",
  inferential_tests_executed="NO",
  DESeq2_refit_executed="NO",
  new_program_discovery="NO",
  thresholds_retuned="NO",
  next_stage=if(hard_fail==0L)
    "CHATGPT_INDEPENDENT_AUDIT_THEN_R4C_STEP1_PROGRESSION_METHOD_CONTRACT"
  else "STOP_AND_REPAIR_PREFLIGHT_ONLY",
  stringsAsFactors=FALSE
),file.path(OUT,"R4C_STEP0_STATUS.csv"))

cat("FINAL_STATE:",state,"\n")
cat("RUN_ID:",STAMP,"\n")
cat("HARD_FAILURES:",hard_fail,"\n")
cat("R0_SAMPLES:",nrow(sm),"\n")
cat("GROUPS:NF=",sum(sm$disease_group=="NF"),
    ";pRV=",sum(sm$disease_group=="pRV"),
    ";RVF=",sum(sm$disease_group=="RVF"),"\n",sep="")
cat("STABLE16:",nrow(a20),"\n")
cat("PROGRAM_SCORES_CALCULATED:NO\n")
cat("PROGRESSION_COMPARED:NO\n")
cat("INFERENTIAL_TESTS_EXECUTED:NO\n")
cat("DESEQ2_REFIT:NO\n")
quit(save="no",status=if(hard_fail==0L) 0 else 142,runLast=FALSE)
