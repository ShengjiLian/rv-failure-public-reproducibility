# Gate9K V1.32 repair: current R4C Step0 run-record binding; science unchanged.
# Historical run-bearing STATUS/AUDIT/INPUT whole-file SHA guards are replaced by
# exact current-run semantics, complete audit identity, and source-ledger self-identity.
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
# RV Project — R4C Step1
# R0 NF -> pRV -> RVF PROGRAM PROGRESSION — METHOD CONTRACT FREEZE V1.2 SYNTAX REPAIR
#
# CONTRACT-ONLY GATE.
# NO NF/pRV/RVF group comparison.
# NO progression classification.
# NO inferential P value or FDR.
# NO DESeq2 refit.
# NO new program/gene discovery.
#
# Accepted upstream:
#   R4C Step0 V1.2 RUN_ID = 20260911_010028
#
# R4C is descriptive within-R0 progression characterization.
# R0 contributed to discovery of the frozen stable16 target family, therefore
# R4C is NOT independent validation and must not create circular significance
# claims.
# ==============================================================================

options(stringsAsFactors=FALSE, warn=1)
args <- commandArgs(trailingOnly=TRUE)
STAMP <- if(length(args)>=1 && nzchar(args[1])) args[1] else format(Sys.time(),"%Y%m%d_%H%M%S")

ROOT <- normalizePath(getwd(),winslash="/",mustWork=TRUE)
if(!identical(ROOT,RV_PROJECT_ROOT)) stop("Expected working directory D:/RV_project",call.=FALSE)

# V1.1 technical repair:
# Create the reviewable output directory BEFORE any package/object operation.
OUTROOT <- file.path(ROOT,"results","R4C_R0_NF_PRV_RVF_PROGRESSION_METHOD_CONTRACT_V1_2")
OUT <- file.path(OUTROOT,STAMP)
dir.create(OUT,recursive=TRUE,showWarnings=FALSE)

write_boot_status <- function(state, error_message="") {
  write.csv(data.frame(
    final_state=state,
    run_id=STAMP,
    hard_failures=1,
    normalized_expression_extracted="NO",
    program_scores_calculated="NO",
    group_progression_compared="NO",
    progression_classes_assigned="NO",
    inferential_tests_executed="NO",
    DESeq2_refit_executed="NO",
    new_program_discovery="NO",
    thresholds_retuned="NO",
    error=as.character(error_message),
    stringsAsFactors=FALSE
  ),file.path(OUT,"R4C_STEP1_STATUS.csv"),row.names=FALSE,na="")
}

# Any otherwise-unhandled error after OUT creation must leave reviewable CSV evidence.
options(error=function() {
  msg <- geterrmessage()
  try(write.csv(data.frame(
    phase="UNHANDLED_ERROR",
    error=msg,
    stringsAsFactors=FALSE
  ),file.path(OUT,"R4C_STEP1_UNHANDLED_ERROR.csv"),row.names=FALSE,na=""),silent=TRUE)
  try(write_boot_status("HOLD_R4C_STEP1_UNHANDLED_ERROR",msg),silent=TRUE)
  quit(save="no",status=159,runLast=FALSE)
})

# Make both established project/user libraries visible.
project_lib <- file.path(ROOT,"R_library","R-4.6")
windows_user_lib <- file.path(Sys.getenv("LOCALAPPDATA"),"R","win-library","4.6")
lib_candidates <- c(project_lib,windows_user_lib)
lib_candidates <- lib_candidates[dir.exists(lib_candidates)]
.libPaths(unique(c(lib_candidates,.libPaths())))

digest_ok <- requireNamespace("digest",quietly=TRUE)
deseq_ok <- requireNamespace("DESeq2",quietly=TRUE)

write.csv(data.frame(
  component=c("project_library","windows_user_library","digest","DESeq2"),
  observed=c(
    project_lib,
    windows_user_lib,
    if(digest_ok) as.character(utils::packageVersion("digest")) else "NOT_AVAILABLE",
    if(deseq_ok) as.character(utils::packageVersion("DESeq2")) else "NOT_AVAILABLE"
  ),
  status=c(
    if(dir.exists(project_lib)) "AVAILABLE" else "ABSENT_NONCRITICAL",
    if(dir.exists(windows_user_lib)) "AVAILABLE" else "ABSENT_NONCRITICAL",
    if(digest_ok) "PASS" else "FAIL",
    if(deseq_ok) "PASS" else "FAIL"
  ),
  stringsAsFactors=FALSE
),file.path(OUT,"R4C_STEP1_BOOT_ENVIRONMENT.csv"),row.names=FALSE,na="")

if(!digest_ok || !deseq_ok) {
  msg <- paste0("digest_ok=",digest_ok,";DESeq2_ok=",deseq_ok)
  write_boot_status("HOLD_R4C_STEP1_BOOT_ENVIRONMENT",msg)
  quit(save="no",status=150,runLast=FALSE)
}

STEP0 <- rv_resolve_stage_run(file.path(ROOT, "results", "R4C_R0_NF_PRV_RVF_PROGRESSION_PREFLIGHT_V1_2"))
S0_STATUS   <- file.path(STEP0,"R4C_STEP0_STATUS.csv")
S0_BOUNDARY <- file.path(STEP0,"R4C_STEP0_CONTRACT_BOUNDARY.csv")
S0_MAP      <- file.path(STEP0,"R4C_STEP0_PROGRAM_MAPPING_AUDIT.csv")
S0_STRUCT   <- file.path(STEP0,"R4C_STEP0_R0_STRUCTURE_SUMMARY.csv")
S0_AUDIT    <- file.path(STEP0,"R4C_STEP0_PREFLIGHT_AUDIT.csv")
S0_INPUT    <- file.path(STEP0,"R4C_STEP0_INPUT_SHA256.csv")

R0_DIR <- file.path(ROOT,"results","R0","v4_LOCAL_RUN")
DDS <- file.path(R0_DIR,"R0_fitted_dds.rds")
SAMPLE_MAP <- file.path(R0_DIR,"R0_exact_step1_sample_map.csv")
A20 <- file.path(ROOT,"results","R3_GSE249696",
                 "R3_STEP3F_V1_1_stable_program_identity_class_freeze.csv")
GMT <- file.path(ROOT,"data","authority","MSigDB","h.all.v2026.1.Hs.symbols.gmt")

EXPECTED_SHA <- c(
  S0_STATUS   ="559d4138fce3530b1d2b397e9757a846c290201aaa598b893e0aba7cf771dd24",
  S0_BOUNDARY ="bffa405f5d648b622aefd3ae5b12e0252521981b6dd47c60e6c164a8263325fc",
  S0_MAP      ="419efdfc24199aca6911c52a2ff6a4b32e6f0faceea02f49e2a06d5543a8285e",
  S0_STRUCT   ="11f91610c4ef96126feff22dd58dec6bcde5b75a9632efbd038c0bf886f19176",
  S0_AUDIT    ="a6bdbc8a891dac04d2a7771b18e281da1762941c1914098dafebe57474327cd0",
  S0_INPUT    ="16df8cf41edda87477bfcf5ce5f871613d35a994a5cc25bae8fa16f9acfc472e",
  DDS         ="cfe6b796af4cc12b8663217835f0fdc7fd9053e2180b298773f3b3bbe0e12845",
  SAMPLE_MAP  ="e4f51929b8d8a928690b8b90969d9e3ecb0349b9f47408e4828b32d6a3b7a175",
  A20         ="49cd4da614f699f1c35d91e61d1bc59e2add6483c71aa23947fdab49a6a60068",
  GMT         ="eecaf6dad908334ae885406ec72bdc0646d8917588ed7c219fac92fc5363f596"
)

sha256 <- function(p) digest::digest(file=p,algo="sha256",serialize=FALSE)



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
  S0_STATUS=S0_STATUS,S0_BOUNDARY=S0_BOUNDARY,S0_MAP=S0_MAP,
  S0_STRUCT=S0_STRUCT,S0_AUDIT=S0_AUDIT,S0_INPUT=S0_INPUT,
  DDS=DDS,SAMPLE_MAP=SAMPLE_MAP,A20=A20,GMT=GMT
)

for(nm in names(P)) {
  check(paste0("FILE_",nm),paste0(nm," exists"),file.exists(P[[nm]]),P[[nm]])
}
if(any(!vapply(P,file.exists,logical(1)))) {
  awrite(do.call(rbind,AUD),file.path(OUT,"R4C_STEP1_METHOD_CONTRACT_AUDIT.csv"))
  awrite(data.frame(
    final_state="HOLD_R4C_STEP1_MISSING_INPUT",run_id=STAMP,hard_failures=1,
    normalized_expression_extracted="NO",
    program_scores_calculated="NO",
    group_progression_compared="NO",
    progression_classes_assigned="NO",
    inferential_tests_executed="NO",
    stringsAsFactors=FALSE
  ),file.path(OUT,"R4C_STEP1_STATUS.csv"))
  quit(save="no",status=151,runLast=FALSE)
}

# Gate9K V1.32: S0_STATUS/S0_AUDIT/S0_INPUT are current-run records.
# Validate their complete current semantics/identity instead of historical whole-file SHA.
for(nm in names(EXPECTED_SHA)) {
  got <- sha256(P[[nm]])
  if(identical(nm,"S0_STATUS")) {
    s0_pre <- read.csv(S0_STATUS,stringsAsFactors=FALSE,check.names=FALSE)
    s0_run_id <- basename(STEP0)
    need <- c("final_state","run_id","hard_failures","program_scores_calculated",
              "group_progression_compared","progression_classes_assigned",
              "inferential_tests_executed","DESeq2_refit_executed",
              "new_program_discovery","thresholds_retuned","next_stage")
    ok <- nrow(s0_pre)==1L && all(need %in% names(s0_pre)) &&
      identical(as.character(s0_pre$final_state[1]),"PASS_R4C_STEP0_PREFLIGHT_READY_FOR_INDEPENDENT_AUDIT") &&
      identical(as.character(s0_pre$run_id[1]),s0_run_id) &&
      identical(as.integer(s0_pre$hard_failures[1]),0L) &&
      identical(as.character(s0_pre$program_scores_calculated[1]),"NO") &&
      identical(as.character(s0_pre$group_progression_compared[1]),"NO") &&
      identical(as.character(s0_pre$progression_classes_assigned[1]),"NO") &&
      identical(as.character(s0_pre$inferential_tests_executed[1]),"NO") &&
      identical(as.character(s0_pre$DESeq2_refit_executed[1]),"NO") &&
      identical(as.character(s0_pre$new_program_discovery[1]),"NO") &&
      identical(as.character(s0_pre$thresholds_retuned[1]),"NO") &&
      identical(as.character(s0_pre$next_stage[1]),"CHATGPT_INDEPENDENT_AUDIT_THEN_R4C_STEP1_PROGRESSION_METHOD_CONTRACT")
    check("SHA_S0_STATUS","S0_STATUS exact current-run preflight semantics",ok,
          if(nrow(s0_pre)) paste(s0_pre$run_id[1],s0_pre$final_state[1],s0_pre$hard_failures[1],sep=" | ") else "NO_ROW")
  } else if(identical(nm,"S0_AUDIT")) {
    a0 <- read.csv(S0_AUDIT,stringsAsFactors=FALSE,check.names=FALSE)
    expected_ids <- c(
      "FILE_R4B_STATUS",
      "FILE_DDS",
      "FILE_SAMPLE_MAP",
      "FILE_R0_SUMMARY",
      "FILE_A20",
      "FILE_GMT",
      "SHA_R4B_STATUS",
      "SHA_DDS",
      "SHA_SAMPLE_MAP",
      "SHA_R0_SUMMARY",
      "SHA_A20",
      "SHA_GMT",
      "R4B_CLOSED",
      "SAMPLE_SCHEMA",
      "SAMPLE_N142",
      "SAMPLE_ID_UNIQUE",
      "GROUP_COUNTS",
      "GROUP_LEVELS",
      "R0_SUMMARY_SCHEMA",
      "R0_SUMMARY_filtered_genes_total",
      "R0_SUMMARY_primary_assessable_genes",
      "R0_SUMMARY_primary_nonassessable_beta_nonconverged",
      "R0_SUMMARY_primary_FDR_lt_0_05",
      "R0_SUMMARY_primary_FDR_lt_0_05_up",
      "R0_SUMMARY_primary_FDR_lt_0_05_down",
      "R0_SUMMARY_maxit1000_used_as_primary",
      "R0_SUMMARY_new_statistical_computation_in_step3D",
      "DDS_CLASS",
      "DDS_DIM",
      "DDS_GENE_UNIQUE",
      "DDS_SAMPLE_UNIQUE",
      "DDS_SAMPLE_SET",
      "DDS_CATEGORY",
      "DDS_CATEGORY_MATCH",
      "DDS_DESIGN",
      "DDS_NORMALIZATION_AUTHORITY",
      "DDS_NORMALIZATION_MODE",
      "DDS_AVGTXLENGTH",
      "DDS_BETACONV",
      "A20_SCHEMA",
      "STABLE16",
      "FAILURE_DIRECTION",
      "GMT50",
      "STABLE16_GMT",
      "TARGET_SYMBOL_UNIQUENESS",
      "STABLE16_MAPPING80"
    )
    ok <- nrow(a0)==length(expected_ids) &&
      all(c("guard_id","status","critical") %in% names(a0)) &&
      identical(as.character(a0$guard_id),expected_ids) &&
      all(as.character(a0$status)=="PASS") &&
      all(as.character(a0$critical)=="YES")
    check("SHA_S0_AUDIT","S0_AUDIT exact 46-check current-run all-PASS identity",ok,
          paste0("rows=",nrow(a0),";pass=",sum(as.character(a0$status)=="PASS")))
  } else if(identical(nm,"S0_INPUT")) {
    i0 <- read.csv(S0_INPUT,stringsAsFactors=FALSE,check.names=FALSE)
    ids <- c("R4B_STATUS","DDS","SAMPLE_MAP","R0_SUMMARY","A20","GMT")
    schema_ok <- all(c("input_id","path","bytes","sha256","prior_exact_sha_guard") %in% names(i0))
    rows_ok <- nrow(i0)==length(ids) && schema_ok && identical(as.character(i0$input_id),ids)
    self_ok <- FALSE
    if(rows_ok) {
      self_ok <- all(vapply(seq_len(nrow(i0)),function(ii) {
        pth <- as.character(i0$path[ii])
        file.exists(pth) &&
          identical(as.numeric(file.info(pth)$size),as.numeric(i0$bytes[ii])) &&
          identical(tolower(sha256(pth)),tolower(as.character(i0$sha256[ii]))) &&
          (
            (identical(as.character(i0$input_id[ii]),"SAMPLE_MAP") &&
             identical(as.character(i0$prior_exact_sha_guard[ii]),"YES_PATH_NORMALIZED_H5_PATH_ONLY")) ||
            (identical(as.character(i0$input_id[ii]),"DDS") &&
             identical(as.character(i0$prior_exact_sha_guard[ii]),"CURRENT_RUN_SEMANTIC_DDS_CHAIN_HIST_SHA_PROVENANCE")) ||
            (!as.character(i0$input_id[ii]) %in% c("SAMPLE_MAP","DDS") &&
             identical(as.character(i0$prior_exact_sha_guard[ii]),"YES"))
          )
      },logical(1)))
    }
    check("SHA_S0_INPUT","S0_INPUT exact six-row current source-identity ledger",rows_ok && self_ok,
          paste0("rows=",nrow(i0),";self_exact=",self_ok))
  } else if(identical(nm,"DDS")) {
    i0_dds <- read.csv(S0_INPUT,stringsAsFactors=FALSE,check.names=FALSE)
    r0_dds <- i0_dds[as.character(i0_dds$input_id)=="DDS",,drop=FALSE]
    a0_dds <- read.csv(S0_AUDIT,stringsAsFactors=FALSE,check.names=FALSE)
    a0_dds <- a0_dds[as.character(a0_dds$guard_id)=="SHA_DDS",,drop=FALSE]
    ok <- nrow(r0_dds)==1L &&
      nrow(a0_dds)==1L &&
      identical(as.character(a0_dds$status[1]),"PASS") &&
      identical(as.character(a0_dds$critical[1]),"YES") &&
      grepl("current-run producer/semantic authority",as.character(a0_dds$requirement[1]),fixed=TRUE) &&
      identical(tolower(as.character(r0_dds$sha256[1])),tolower(got)) &&
      identical(as.numeric(r0_dds$bytes[1]),as.numeric(file.info(DDS)$size)) &&
      identical(as.character(r0_dds$prior_exact_sha_guard[1]),"CURRENT_RUN_SEMANTIC_DDS_CHAIN_HIST_SHA_PROVENANCE")
    check(
      "SHA_DDS",
      "DDS current-run chain-of-custody from accepted Step0 semantic authority",
      ok,
      paste0("current_sha256=",got,"; step0_sha256=",if(nrow(r0_dds)) r0_dds$sha256[1] else "MISSING",
             "; historical_sha256=",EXPECTED_SHA[[nm]]),
      notes="Historical DDS SHA remains provenance only; Step0 semantic DDS guards are required PASS and current DDS bytes/SHA must be the exact same current-run object."
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
      identical(tolower(got),tolower(EXPECTED_SHA[[nm]])),
      got
    )
  }
}

s0 <- read.csv(S0_STATUS,stringsAsFactors=FALSE,check.names=FALSE)
check(
  "STEP0_PASS",
  "Accepted R4C Step0 V1.2 is PASS with zero hard failures",
  nrow(s0)==1L &&
    identical(s0$final_state[1],"PASS_R4C_STEP0_PREFLIGHT_READY_FOR_INDEPENDENT_AUDIT") &&
    as.integer(s0$hard_failures[1])==0L,
  if(nrow(s0)) paste(s0$final_state[1],s0$hard_failures[1],sep=" | ") else "NO_ROW"
)
check(
  "STEP0_NO_OUTCOME",
  "Step0 had no progression scoring/comparison/classification/inference",
  nrow(s0)==1L &&
    identical(s0$program_scores_calculated[1],"NO") &&
    identical(s0$group_progression_compared[1],"NO") &&
    identical(s0$progression_classes_assigned[1],"NO") &&
    identical(s0$inferential_tests_executed[1],"NO") &&
    identical(s0$DESeq2_refit_executed[1],"NO"),
  if(nrow(s0)) paste(
    s0$program_scores_calculated[1],
    s0$group_progression_compared[1],
    s0$progression_classes_assigned[1],
    s0$inferential_tests_executed[1],
    s0$DESeq2_refit_executed[1],
    sep=" | "
  ) else "NO_ROW"
)

# --------------------------------------------------------------------------
# Pre-outcome eligibility audit.
# Extract normalized expression across all 142 samples, but DO NOT use group
# labels or calculate any program/group score in this Step1 contract gate.
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
  ),file.path(OUT,"R4C_STEP1_DDS_READ_ERROR.csv"),row.names=FALSE,na="")
  write_boot_status(
    "HOLD_R4C_STEP1_DDS_READ",
    if(is.null(dds_error)) "UNKNOWN_READRDS_FAILURE" else dds_error
  )
  quit(save="no",status=153,runLast=FALSE)
}
check("DDS_CLASS","Frozen R0 object is DESeqDataSet",inherits(dds,"DESeqDataSet"),
      paste(class(dds),collapse=";"))
check("DDS_DIM","Frozen DDS remains 19,428 x 142",
      inherits(dds,"DESeqDataSet") && identical(as.integer(dim(dds)),c(19428L,142L)),
      paste(dim(dds),collapse="x"))

sm <- read.csv(SAMPLE_MAP,stringsAsFactors=FALSE,check.names=FALSE)
sm$sample_id <- trimws(as.character(sm$sample_id))
sm$disease_group <- trimws(as.character(sm$disease_group))
check("SAMPLE142","Sample map remains 142 unique patients",
      nrow(sm)==142L && !anyDuplicated(sm$sample_id),nrow(sm))
grp <- table(factor(sm$disease_group,levels=c("NF","pRV","RVF")))
check("GROUP_COUNTS","Frozen group counts remain 29/78/35",
      identical(as.integer(grp),c(29L,78L,35L)),
      paste(as.integer(grp),collapse="/"))
check("SAMPLE_SET","DDS sample set equals exact sample map",
      setequal(colnames(dds),sm$sample_id),
      paste0("DDS_only=",length(setdiff(colnames(dds),sm$sample_id)),
             ";map_only=",length(setdiff(sm$sample_id,colnames(dds))))
)

sf <- DESeq2::sizeFactors(dds)
nf <- DESeq2::normalizationFactors(dds)
sf_ok <- length(sf)==142L && all(is.finite(sf) & sf>0)
nf_ok <- !is.null(nf) &&
         identical(as.integer(dim(nf)),c(19428L,142L)) &&
         all(is.finite(nf)) && all(nf>0)
check("NORMALIZATION_AUTHORITY",
      "Frozen DDS retains a valid complete DESeq2 normalization authority",
      sf_ok || nf_ok,
      paste0("sf_n=",length(sf),";nf=",
             if(is.null(nf)) "NULL" else paste(dim(nf),collapse="x")))
check("NORMALIZATION_MODE",
      "Observed frozen R0 normalization mode remains gene-by-sample normalizationFactors",
      nf_ok && length(sf)==0L,
      paste0("sf_n=",length(sf),";nf_ok=",nf_ok))

# This is the only expression extraction in Step1. It is used solely to freeze
# pre-outcome finite/nonzero-variance member-gene eligibility across pooled 142.
norm_error <- NULL
NORM <- tryCatch(
  DESeq2::counts(dds,normalized=TRUE),
  error=function(e) {
    norm_error <<- conditionMessage(e)
    NULL
  }
)
if(is.null(NORM)) {
  write.csv(data.frame(
    component="DESeq2_counts_normalized_TRUE",
    error=if(is.null(norm_error)) "UNKNOWN_NORMALIZED_COUNTS_FAILURE" else norm_error,
    sizeFactors_n=length(DESeq2::sizeFactors(dds)),
    normalizationFactors_dim=if(is.null(DESeq2::normalizationFactors(dds))) "NULL"
                             else paste(dim(DESeq2::normalizationFactors(dds)),collapse="x"),
    stringsAsFactors=FALSE
  ),file.path(OUT,"R4C_STEP1_NORMALIZED_COUNTS_ERROR.csv"),row.names=FALSE,na="")
  write_boot_status(
    "HOLD_R4C_STEP1_NORMALIZED_COUNTS_EXTRACTION",
    if(is.null(norm_error)) "UNKNOWN_NORMALIZED_COUNTS_FAILURE" else norm_error
  )
  quit(save="no",status=154,runLast=FALSE)
}
check("NORM_DIM","Normalized expression is 19,428 x 142",
      identical(as.integer(dim(NORM)),c(19428L,142L)),
      paste(dim(NORM),collapse="x"))
check("NORM_FINITE_NONNEG","Normalized expression is finite and nonnegative",
      all(is.finite(NORM)) && all(NORM>=0),
      paste0("finite=",sum(is.finite(NORM)),"/",length(NORM),
             ";negative=",sum(NORM<0,na.rm=TRUE)))

LOG <- log2(NORM+1)
sd142 <- apply(LOG,1,sd)
finite142 <- apply(LOG,1,function(v) all(is.finite(v)))
eligible142 <- finite142 & is.finite(sd142) & sd142>0

a20 <- read.csv(A20,stringsAsFactors=FALSE,check.names=FALSE)
gl <- readLines(GMT,warn=FALSE)
parts <- strsplit(gl,"\t",fixed=TRUE)
gmt_names <- vapply(parts,`[`,character(1),1L)
gmt_genes <- lapply(parts,function(x)
  unique(if(length(x)>=3L) x[3:length(x)] else character()))
names(gmt_genes) <- gmt_names

genes <- rownames(dds)
gtab <- table(genes)
all_target_symbols <- unique(unlist(gmt_genes[a20$pathway],use.names=FALSE))
dup_target <- names(gtab)[names(gtab) %in% all_target_symbols & as.integer(gtab)>1L]
check("TARGET_UNIQUE","Frozen stable16 member symbols map to at most one DDS row",
      length(dup_target)==0L,paste(dup_target,collapse=";"))

elig_rows <- list()
for(i in seq_len(nrow(a20))) {
  pid <- a20$pathway[i]
  members <- gmt_genes[[pid]]
  idx <- match(members,genes)
  mapped <- !is.na(idx)
  idx2 <- idx[mapped]
  usable <- if(length(idx2)) eligible142[idx2] else logical()
  elig_rows[[i]] <- data.frame(
    pathway=pid,
    failure_direction=a20$failure_direction[i],
    program_class=a20$program_class[i],
    gmt_member_n=length(members),
    exact_symbol_mapped_n=sum(mapped),
    mapped_fraction=sum(mapped)/length(members),
    finite_142_n=sum(if(length(idx2)) finite142[idx2] else logical()),
    zero_or_nonfinite_sd_142_n=sum(if(length(idx2)) !eligible142[idx2] else logical()),
    usable_gene_n=sum(usable),
    assessable=(sum(mapped)/length(members)>=0.80 && sum(usable)>=10L),
    mapping_rule="TRIMMED_EXACT_HGNC_SYMBOL_TO_FROZEN_FILTERED_DDS_ROWNAME",
    gene_eligibility="FINITE_LOG2_NORMALIZED_PLUS1_IN_ALL_142_AND_SAMPLE_SD_GT_0_BEFORE_GROUP_USE",
    duplicate_policy="FAIL_IF_STABLE16_MEMBER_SYMBOL_MAPS_TO_MULTIPLE_DDS_ROWS",
    stringsAsFactors=FALSE
  )
}
elig <- do.call(rbind,elig_rows)
check("ELIG16","All 16 frozen programs pass pre-outcome eligibility",
      nrow(elig)==16L && all(elig$assessable),paste0(sum(elig$assessable),"/16"))
check("USABLE10","All 16 programs retain >=10 usable genes",
      all(elig$usable_gene_n>=10L),paste0("min=",min(elig$usable_gene_n)))
awrite(elig,file.path(OUT,"R4C_STEP1_PROGRAM_ELIGIBILITY_AUDIT.csv"))

# --------------------------------------------------------------------------
# Freeze progression method before any disease-group comparison.
# --------------------------------------------------------------------------
contract <- data.frame(
  item=c(
    "module_role",
    "cohort",
    "biological_replicate",
    "sample_universe",
    "group_order",
    "group_sizes",
    "R0_used_in_target_discovery",
    "independent_validation_allowed",
    "target_family",
    "target_n",
    "expression_authority",
    "normalization_authority",
    "DESeq2_refit_allowed",
    "expression_transform",
    "symbol_mapping",
    "target_duplicate_policy",
    "preoutcome_gene_eligibility",
    "program_min_mapping_fraction",
    "program_min_usable_genes",
    "gene_standardization",
    "raw_program_score",
    "failure_oriented_program_score",
    "group_location_primary",
    "group_dispersion_display",
    "transition_1",
    "transition_2",
    "total_transition",
    "zero_tolerance",
    "progression_class_rule",
    "class_monotonic_failure_progressive",
    "class_compensation_then_failure_switch",
    "class_early_failurelike_then_reverse",
    "class_monotonic_opposite",
    "class_late_failure_transition",
    "class_early_failurelike_then_plateau",
    "class_early_opposite_then_plateau",
    "class_late_opposite_shift",
    "class_flat",
    "dominant_transition_rule",
    "patient_level_scores_output",
    "group_summary_output",
    "inferential_group_test",
    "trend_pvalue",
    "multiple_testing_FDR",
    "pairwise_tests",
    "new_program_discovery",
    "new_gene_discovery",
    "threshold_retuning_after_results",
    "allowed_claim",
    "forbidden_claim",
    "normalized_expression_extracted_in_step1",
    "program_scores_calculated_in_step1",
    "group_progression_compared_in_step1",
    "progression_classes_assigned_in_step1",
    "inferential_tests_executed_in_step1",
    "next_stage"
  ),
  value=c(
    "DESCRIPTIVE_WITHIN_R0_PROGRESSION_CHARACTERIZATION",
    "GSE345645_ADULT_RV_BULK",
    "PATIENT",
    "142_PATIENTS",
    "NF<pRV<RVF",
    "NF=29;pRV=78;RVF=35",
    "YES",
    "NO",
    "FROZEN_R0_R1_STABLE16",
    "16",
    "FROZEN_R0_FITTED_DDS",
    "DESEQ2_COUNTS_NORMALIZED_TRUE_USING_FROZEN_GENE_BY_SAMPLE_NORMALIZATION_FACTORS",
    "NO",
    "LOG2_NORMALIZED_COUNT_PLUS_1",
    "TRIMMED_EXACT_HGNC_SYMBOL_TO_FROZEN_FILTERED_DDS_ROWNAME",
    "FAIL_IF_STABLE16_MEMBER_SYMBOL_MAPS_TO_MULTIPLE_DDS_ROWS",
    "FINITE_LOG2_NORMALIZED_PLUS1_IN_ALL_142_AND_SAMPLE_SD_GT_0_BEFORE_GROUP_USE",
    "0.80",
    "10",
    "GENEWISE_Z_ACROSS_POOLED_142_PATIENTS_USING_SAMPLE_SD",
    "MEAN_OF_USABLE_MEMBER_GENE_Z_SCORES_PER_PATIENT",
    "RAW_SCORE_X_PLUS1_IF_UP_IN_FAILURE_ELSE_MINUS1_IF_DOWN_IN_FAILURE",
    "MEDIAN_FAILURE_ORIENTED_PROGRAM_SCORE_PER_GROUP",
    "N_MEAN_SD_MEDIAN_Q25_Q75_MIN_MAX",
    "MEDIAN_pRV_MINUS_MEDIAN_NF",
    "MEDIAN_RVF_MINUS_MEDIAN_pRV",
    "MEDIAN_RVF_MINUS_MEDIAN_NF",
    "1e-12",
    "SIGN_PATTERN_OF_TRANSITION1_AND_TRANSITION2_USING_FIXED_TOLERANCE",
    "D1_GT_TOL_AND_D2_GT_TOL",
    "D1_LT_MINUS_TOL_AND_D2_GT_TOL",
    "D1_GT_TOL_AND_D2_LT_MINUS_TOL",
    "D1_LT_MINUS_TOL_AND_D2_LT_MINUS_TOL",
    "ABS_D1_LE_TOL_AND_D2_GT_TOL",
    "D1_GT_TOL_AND_ABS_D2_LE_TOL",
    "D1_LT_MINUS_TOL_AND_ABS_D2_LE_TOL",
    "ABS_D1_LE_TOL_AND_D2_LT_MINUS_TOL",
    "ABS_D1_LE_TOL_AND_ABS_D2_LE_TOL",
    "LARGER_ABSOLUTE_MEDIAN_TRANSITION;TIE_IF_ABS_D1_EQUALS_ABS_D2_WITHIN_1E-12",
    "YES_ALL_142_X_16_FIXED_SAMPLE_ORDER",
    "YES_16_X_3_FIXED_GROUP_ORDER",
    "NONE_DESCRIPTIVE_MODULE",
    "NO",
    "NONE",
    "NO",
    "NO",
    "NO",
    "NO",
    "FROZEN_RV_FAILURE_PROGRAMS_SHOW_DISTINCT_CROSS_SECTIONAL_NF_TO_PRV_TO_RVF_SCORE_PATTERNS_WITHIN_R0",
    "NOT_INDEPENDENT_VALIDATION;NO_CAUSAL_PROGRESSION_CLAIM;NO_SIGNIFICANCE_LANGUAGE_FROM_R4C;NO_TEMPORAL_WITHIN_PATIENT_INTERPRETATION",
    "YES_PREOUTCOME_ELIGIBILITY_ONLY",
    "NO",
    "NO",
    "NO",
    "NO",
    "R4C_STEP2_DETERMINISTIC_PROGRESSION_EXECUTION_AFTER_INDEPENDENT_AUDIT"
  ),
  stringsAsFactors=FALSE
)
awrite(contract,file.path(OUT,"R4C_STEP1_PROGRESSION_METHOD_CONTRACT.csv"))

taxonomy <- data.frame(
  priority=1:9,
  progression_class=c(
    "MONOTONIC_FAILURE_PROGRESSIVE",
    "COMPENSATION_THEN_FAILURE_SWITCH",
    "BIPHASIC_EARLY_FAILURELIKE_THEN_REVERSE",
    "MONOTONIC_OPPOSITE_TO_FAILURE_DIRECTION",
    "LATE_FAILURE_TRANSITION",
    "EARLY_FAILURELIKE_SHIFT_THEN_PLATEAU",
    "EARLY_OPPOSITE_SHIFT_THEN_PLATEAU",
    "LATE_OPPOSITE_SHIFT",
    "FLAT_WITHIN_TOLERANCE"
  ),
  d1_condition=c(
    ">tol","<-tol",">tol","<-tol","abs<=tol",">tol","<-tol","abs<=tol","abs<=tol"
  ),
  d2_condition=c(
    ">tol",">tol","<-tol","<-tol",">tol","abs<=tol","abs<=tol","<-tol","abs<=tol"
  ),
  interpretation=c(
    "failure-oriented score rises from NF to pRV and again from pRV to RVF",
    "score first falls in pRV then rises in RVF; compensation-to-failure switch pattern",
    "score rises in pRV then falls in RVF; biphasic non-monotonic pattern",
    "score falls across both transitions; opposite to frozen failure direction",
    "little NF-to-pRV shift, followed by higher RVF score",
    "higher pRV score followed by little additional RVF shift",
    "lower pRV score followed by little additional RVF shift",
    "little NF-to-pRV shift, followed by lower RVF score",
    "both median transitions within fixed numerical tolerance"
  ),
  stringsAsFactors=FALSE
)
awrite(taxonomy,file.path(OUT,"R4C_STEP1_PROGRESSION_CLASS_TAXONOMY.csv"))

# Fixed display order: frozen stable16 table order, group order NF/pRV/RVF.
display <- data.frame(
  pathway=a20$pathway,
  display_order=seq_len(nrow(a20)),
  failure_direction=a20$failure_direction,
  Step3F_program_class=a20$program_class,
  group_order="NF|pRV|RVF",
  patient_order_within_group="ASCENDING_SAMPLE_ID",
  outcome_based_reordering="NO",
  stringsAsFactors=FALSE
)
awrite(display,file.path(OUT,"R4C_STEP1_DISPLAY_ORDER_CONTRACT.csv"))

audit <- do.call(rbind,AUD)
hard_fail <- sum(audit$status=="FAIL" & audit$critical=="YES")
awrite(audit,file.path(OUT,"R4C_STEP1_METHOD_CONTRACT_AUDIT.csv"))

inp <- do.call(rbind,lapply(names(P),function(nm) data.frame(
  input_id=nm,path=P[[nm]],bytes=file.info(P[[nm]])$size,
  sha256=sha256(P[[nm]]),stringsAsFactors=FALSE
)))
awrite(inp,file.path(OUT,"R4C_STEP1_INPUT_SHA256.csv"))

state <- if(hard_fail==0L) {
  "PASS_R4C_STEP1_PROGRESSION_METHOD_CONTRACT_READY_FOR_INDEPENDENT_AUDIT"
} else {
  "HOLD_R4C_STEP1_PROGRESSION_METHOD_CONTRACT"
}

awrite(data.frame(
  final_state=state,
  run_id=STAMP,
  hard_failures=hard_fail,
  normalized_expression_extracted="YES_PREOUTCOME_ELIGIBILITY_ONLY",
  program_scores_calculated="NO",
  group_progression_compared="NO",
  progression_classes_assigned="NO",
  inferential_tests_executed="NO",
  DESeq2_refit_executed="NO",
  new_program_discovery="NO",
  thresholds_retuned="NO",
  next_stage=if(hard_fail==0L)
    "CHATGPT_INDEPENDENT_AUDIT_THEN_R4C_STEP2_DETERMINISTIC_PROGRESSION_EXECUTION"
  else "STOP_AND_REPAIR_METHOD_CONTRACT_ONLY",
  stringsAsFactors=FALSE
),file.path(OUT,"R4C_STEP1_STATUS.csv"))

cat("FINAL_STATE:",state,"\n")
cat("RUN_ID:",STAMP,"\n")
cat("HARD_FAILURES:",hard_fail,"\n")
cat("PROGRAMS_ASSESSABLE:",sum(elig$assessable),"/16\n")
cat("NORMALIZED_EXPRESSION_EXTRACTED:YES_PREOUTCOME_ELIGIBILITY_ONLY\n")
cat("PROGRAM_SCORES_CALCULATED:NO\n")
cat("GROUP_PROGRESSION_COMPARED:NO\n")
cat("PROGRESSION_CLASSES_ASSIGNED:NO\n")
cat("INFERENTIAL_TESTS_EXECUTED:NO\n")
quit(save="no",status=if(hard_fail==0L) 0 else 152,runLast=FALSE)
