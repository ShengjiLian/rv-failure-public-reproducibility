# Gate9K V1.32 repair: current R4C Step2 run-record binding; science unchanged.
# Outcome-bearing Step2 tables remain exact-SHA and source-level reconstruction remains mandatory.
# ---- RV PUBLIC PRIMARY DAG GATE9J REWRITE V1.0 ----
# source_id=C0360
# rewrite_scope=TIMESTAMP_ONLY
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
# RV Project — R4C Step3
# R0 NF -> pRV -> RVF PROGRAM PROGRESSION
# SOURCE-LEVEL POSTGEN VALIDATION + TERMINAL CLOSURE
#
# VALIDATION ONLY.
# Reconstructs R4C Step2 from frozen source objects BEFORE opening Step2
# scientific output tables, then compares exact identities and numeric values.
#
# NO new scientific testing.
# NO p values or FDR.
# NO DESeq2 refit.
# NO new program/gene discovery.
# NO threshold retuning.
#
# Scientific boundary:
#   R0 contributed to discovery of stable16. R4C therefore remains descriptive
#   within-R0 cross-sectional characterization, not independent validation.
#   The patient-level mean-z module-score trajectory does not redefine or
#   override the frozen full-ranked GSEA failure-program identity/direction.
# ==============================================================================

options(stringsAsFactors=FALSE, warn=1)
args <- commandArgs(trailingOnly=TRUE)
STAMP <- if(length(args)>=1 && nzchar(args[1])) args[1] else format(Sys.time(),"%Y%m%d_%H%M%S")

ROOT <- normalizePath(getwd(),winslash="/",mustWork=TRUE)
if(!identical(ROOT,RV_PROJECT_ROOT)) stop("Expected working directory D:/RV_project",call.=FALSE)

OUTROOT <- file.path(ROOT,"results","R4C_R0_NF_PRV_RVF_PROGRESSION_POSTGEN_VALIDATION")
OUT <- file.path(OUTROOT,STAMP)
dir.create(OUT,recursive=TRUE,showWarnings=FALSE)

write_fail_status <- function(state,error_message="") {
  write.csv(data.frame(
    final_state=state,
    run_id=STAMP,
    hard_failures=1,
    source_level_independent_reconstruction="NO",
    Step2_scientific_outputs_modified="NO",
    new_scientific_testing="NO",
    inferential_tests_executed="NO",
    multiple_testing_FDR_executed="NO",
    DESeq2_refit_executed="NO",
    thresholds_retuned="NO",
    terminal_closed="NO",
    error=as.character(error_message),
    stringsAsFactors=FALSE
  ),file.path(OUT,"R4C_STEP3_STATUS.csv"),row.names=FALSE,na="")
}

options(error=function() {
  msg <- geterrmessage()
  try(write.csv(data.frame(
    phase="UNHANDLED_ERROR",error=msg,stringsAsFactors=FALSE
  ),file.path(OUT,"R4C_STEP3_UNHANDLED_ERROR.csv"),row.names=FALSE,na=""),silent=TRUE)
  try(write_fail_status("HOLD_R4C_STEP3_UNHANDLED_ERROR",msg),silent=TRUE)
  quit(save="no",status=179,runLast=FALSE)
})

project_lib <- file.path(ROOT,"R_library","R-4.6")
windows_user_lib <- file.path(Sys.getenv("LOCALAPPDATA"),"R","win-library","4.6")
libs <- c(project_lib,windows_user_lib)
libs <- libs[dir.exists(libs)]
.libPaths(unique(c(libs,.libPaths())))

if(!requireNamespace("digest",quietly=TRUE)) {
  write_fail_status("HOLD_R4C_STEP3_BOOT_ENVIRONMENT","digest unavailable")
  quit(save="no",status=170,runLast=FALSE)
}
if(!requireNamespace("DESeq2",quietly=TRUE)) {
  write_fail_status("HOLD_R4C_STEP3_BOOT_ENVIRONMENT","DESeq2 unavailable")
  quit(save="no",status=170,runLast=FALSE)
}

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

# Accepted frozen method contract.
STEP1 <- rv_resolve_stage_run(
  file.path(ROOT,"results","R4C_R0_NF_PRV_RVF_PROGRESSION_METHOD_CONTRACT_V1_2")
)
S1_CONTRACT <- file.path(STEP1,"R4C_STEP1_PROGRESSION_METHOD_CONTRACT.csv")
S1_TAXONOMY <- file.path(STEP1,"R4C_STEP1_PROGRESSION_CLASS_TAXONOMY.csv")
S1_DISPLAY  <- file.path(STEP1,"R4C_STEP1_DISPLAY_ORDER_CONTRACT.csv")
S1_ELIG     <- file.path(STEP1,"R4C_STEP1_PROGRAM_ELIGIBILITY_AUDIT.csv")

# Frozen source authorities.
R0_DIR <- file.path(ROOT,"results","R0","v4_LOCAL_RUN")
DDS <- file.path(R0_DIR,"R0_fitted_dds.rds")
SAMPLE_MAP <- file.path(R0_DIR,"R0_exact_step1_sample_map.csv")
A20 <- file.path(
  ROOT,"results","R3_GSE249696",
  "R3_STEP3F_V1_1_stable_program_identity_class_freeze.csv"
)
GMT <- file.path(
  ROOT,"data","authority","MSigDB",
  "h.all.v2026.1.Hs.symbols.gmt"
)

# Accepted Step2 producer to validate, not use for reconstruction.
STEP2 <- rv_resolve_stage_run(
  file.path(ROOT,"results","R4C_R0_NF_PRV_RVF_PROGRESSION_EXECUTION")
)
S2_STATUS  <- file.path(STEP2,"R4C_STEP2_STATUS.csv")
S2_SCORES  <- file.path(STEP2,"R4C_STEP2_PATIENT_PROGRAM_SCORES.csv")
S2_GROUP   <- file.path(STEP2,"R4C_STEP2_PROGRAM_GROUP_SUMMARY.csv")
S2_PROG    <- file.path(STEP2,"R4C_STEP2_PROGRAM_PROGRESSION_CLASSIFICATION.csv")
S2_CLASS   <- file.path(STEP2,"R4C_STEP2_PROGRESSION_CLASS_SUMMARY.csv")
S2_CROSS   <- file.path(STEP2,"R4C_STEP2_STEP3F_BY_PROGRESSION_CROSSTAB.csv")
S2_OVERALL <- file.path(STEP2,"R4C_STEP2_OVERALL_SUMMARY.csv")
S2_AUDIT   <- file.path(STEP2,"R4C_STEP2_EXECUTION_AUDIT.csv")
S2_INPUT   <- file.path(STEP2,"R4C_STEP2_INPUT_SHA256.csv")

EXPECTED_SHA <- c(
  S1_CONTRACT="cd58a45e98b5fda568bdba372e81d4f8f956453ccde56df190fa6671ba49f616",
  S1_TAXONOMY="5274da64485e2bad44044774bb008faa45d05355f4f0a847fa1a11818cf45ee0",
  S1_DISPLAY ="00db46b2621a9ae47045eb9da5792046d879239f53fd7dda70258133d87167f0",
  S1_ELIG    ="646ea9573370993767d226271ea9042dfda34ad69f69d101b43d63888d090091",
  DDS        ="cfe6b796af4cc12b8663217835f0fdc7fd9053e2180b298773f3b3bbe0e12845",
  SAMPLE_MAP ="e4f51929b8d8a928690b8b90969d9e3ecb0349b9f47408e4828b32d6a3b7a175",
  A20        ="49cd4da614f699f1c35d91e61d1bc59e2add6483c71aa23947fdab49a6a60068",
  GMT        ="eecaf6dad908334ae885406ec72bdc0646d8917588ed7c219fac92fc5363f596",
  S2_STATUS  ="e3803da3e8ffaec031b52ddd40fdffe3e7bdb273d6c1139cc72365f5b4ee3514",
  S2_SCORES  ="6e385af53346b7a5ef8f016eb560b272af480b72c2db60f11928543f64021226",
  S2_GROUP   ="46c7a1702ad19515c65f546b161d3291307809e17276027f869678c0b48bb4bc",
  S2_PROG    ="753f7e736f67b29fb0d8b87b657d245b6acc1b48b2499cdacdab3affac7030f5",
  S2_CLASS   ="d177b5f301754e0bf6fce4e601ddc1c4cb06571326c2f6919485c538d4a14ee7",
  S2_CROSS   ="73fbd59b5ea5873449e735a4f9241350763d88f340b6ad387e27badc2c232fbe",
  S2_OVERALL ="d9e874393d3b58b80f84945a7fb12b1b981ede0087110a13aa2d46718f601729",
  S2_AUDIT   ="4e71be8b80bac62d5f253da46912f185c15a6c5ef048b423aa7c84d30d6dbddf",
  S2_INPUT   ="55223133c96782b3d7d47213ee2e2f5bd170ac5f8bea79b40805ea1add7fed13"
)

P <- list(
  S1_CONTRACT=S1_CONTRACT,S1_TAXONOMY=S1_TAXONOMY,
  S1_DISPLAY=S1_DISPLAY,S1_ELIG=S1_ELIG,
  DDS=DDS,SAMPLE_MAP=SAMPLE_MAP,A20=A20,GMT=GMT,
  S2_STATUS=S2_STATUS,S2_SCORES=S2_SCORES,S2_GROUP=S2_GROUP,
  S2_PROG=S2_PROG,S2_CLASS=S2_CLASS,S2_CROSS=S2_CROSS,
  S2_OVERALL=S2_OVERALL,S2_AUDIT=S2_AUDIT,S2_INPUT=S2_INPUT
)

for(nm in names(P)) {
  check(paste0("FILE_",nm),paste0(nm," exists"),file.exists(P[[nm]]),P[[nm]])
}
if(any(!vapply(P,file.exists,logical(1)))) {
  awrite(do.call(rbind,AUD),file.path(OUT,"R4C_STEP3_VALIDATION_AUDIT.csv"))
  write_fail_status("HOLD_R4C_STEP3_MISSING_INPUT","One or more frozen inputs missing")
  quit(save="no",status=171,runLast=FALSE)
}

# Gate9K V1.32: Step2 STATUS/AUDIT/INPUT are current-run records.
# All outcome-bearing Step2 tables remain historical exact-SHA and are independently reconstructed below.
for(nm in names(EXPECTED_SHA)) {
  got <- sha256(P[[nm]])
  if(identical(nm,"S2_STATUS")) {
    s2_pre <- read.csv(S2_STATUS,stringsAsFactors=FALSE,check.names=FALSE)
    s2_run_id <- basename(STEP2)
    need <- c("final_state","run_id","hard_failures","progression_execution_completed",
              "program_scores_calculated","group_progression_compared","progression_classes_assigned",
              "inferential_tests_executed","multiple_testing_FDR_executed",
              "pairwise_inferential_tests_executed","DESeq2_refit_executed",
              "new_program_discovery","thresholds_retuned","independent_validation_claim_allowed","next_stage")
    ok <- nrow(s2_pre)==1L && all(need %in% names(s2_pre)) &&
      identical(as.character(s2_pre$final_state[1]),"PASS_R4C_STEP2_DETERMINISTIC_PROGRESSION_EXECUTION_READY_FOR_INDEPENDENT_AUDIT") &&
      identical(as.character(s2_pre$run_id[1]),s2_run_id) &&
      identical(as.integer(s2_pre$hard_failures[1]),0L) &&
      identical(as.character(s2_pre$progression_execution_completed[1]),"YES") &&
      identical(as.character(s2_pre$program_scores_calculated[1]),"YES") &&
      identical(as.character(s2_pre$group_progression_compared[1]),"YES_DESCRIPTIVE_MEDIANS_ONLY") &&
      identical(as.character(s2_pre$progression_classes_assigned[1]),"YES_FROZEN_SIGN_TAXONOMY") &&
      identical(as.character(s2_pre$inferential_tests_executed[1]),"NO") &&
      identical(as.character(s2_pre$multiple_testing_FDR_executed[1]),"NO") &&
      identical(as.character(s2_pre$pairwise_inferential_tests_executed[1]),"NO") &&
      identical(as.character(s2_pre$DESeq2_refit_executed[1]),"NO") &&
      identical(as.character(s2_pre$new_program_discovery[1]),"NO") &&
      identical(as.character(s2_pre$thresholds_retuned[1]),"NO") &&
      identical(as.character(s2_pre$independent_validation_claim_allowed[1]),"NO") &&
      identical(as.character(s2_pre$next_stage[1]),"CHATGPT_INDEPENDENT_AUDIT_THEN_R4C_STEP3_SOURCE_LEVEL_POSTGEN_VALIDATION_AND_CLOSURE")
    check("SHA_S2_STATUS","S2_STATUS exact current-run deterministic-execution semantics",ok,
          if(nrow(s2_pre)) paste(s2_pre$run_id[1],s2_pre$final_state[1],s2_pre$hard_failures[1],sep=" | ") else "NO_ROW")
  } else if(identical(nm,"S2_AUDIT")) {
    a2 <- read.csv(S2_AUDIT,stringsAsFactors=FALSE,check.names=FALSE)
    expected_ids <- c(
      "FILE_S1_STATUS",
      "FILE_S1_CONTRACT",
      "FILE_S1_TAXONOMY",
      "FILE_S1_DISPLAY",
      "FILE_S1_ELIG",
      "FILE_S1_AUDIT",
      "FILE_S1_INPUT",
      "FILE_DDS",
      "FILE_SAMPLE_MAP",
      "FILE_A20",
      "FILE_GMT",
      "SHA_S1_STATUS",
      "SHA_S1_CONTRACT",
      "SHA_S1_TAXONOMY",
      "SHA_S1_DISPLAY",
      "SHA_S1_ELIG",
      "SHA_S1_AUDIT",
      "SHA_S1_INPUT",
      "SHA_DDS",
      "SHA_SAMPLE_MAP",
      "SHA_A20",
      "SHA_GMT",
      "STEP1_PASS",
      "STEP1_NO_OUTCOME",
      "CONTRACT_module_role",
      "CONTRACT_sample_universe",
      "CONTRACT_group_order",
      "CONTRACT_group_sizes",
      "CONTRACT_R0_used_in_target_discovery",
      "CONTRACT_independent_validation_allowed",
      "CONTRACT_target_n",
      "CONTRACT_normalization_authority",
      "CONTRACT_DESeq2_refit_allowed",
      "CONTRACT_expression_transform",
      "CONTRACT_gene_standardization",
      "CONTRACT_raw_program_score",
      "CONTRACT_failure_oriented_program_score",
      "CONTRACT_group_location_primary",
      "CONTRACT_transition_1",
      "CONTRACT_transition_2",
      "CONTRACT_total_transition",
      "CONTRACT_zero_tolerance",
      "CONTRACT_progression_class_rule",
      "CONTRACT_inferential_group_test",
      "CONTRACT_trend_pvalue",
      "CONTRACT_multiple_testing_FDR",
      "CONTRACT_pairwise_tests",
      "CONTRACT_new_program_discovery",
      "CONTRACT_new_gene_discovery",
      "CONTRACT_threshold_retuning_after_results",
      "ELIG16",
      "DISPLAY16",
      "TAXONOMY9",
      "DDS_DIM",
      "SAMPLE142",
      "GROUP_COUNTS",
      "SAMPLE_SET",
      "NORM_DIM",
      "NORM_FINITE_NONNEG",
      "TARGET_1",
      "USABLE_1",
      "TARGET_2",
      "USABLE_2",
      "TARGET_3",
      "USABLE_3",
      "TARGET_4",
      "USABLE_4",
      "TARGET_5",
      "USABLE_5",
      "TARGET_6",
      "USABLE_6",
      "TARGET_7",
      "USABLE_7",
      "TARGET_8",
      "USABLE_8",
      "TARGET_9",
      "USABLE_9",
      "TARGET_10",
      "USABLE_10",
      "TARGET_11",
      "USABLE_11",
      "TARGET_12",
      "USABLE_12",
      "TARGET_13",
      "USABLE_13",
      "TARGET_14",
      "USABLE_14",
      "TARGET_15",
      "USABLE_15",
      "TARGET_16",
      "USABLE_16",
      "OUT_SCORES",
      "OUT_SCORE_KEYS",
      "OUT_GROUP48",
      "OUT_PROG16",
      "OUT_CLASS_ALLOWED",
      "OUT_NO_P",
      "OUT_NO_FDR",
      "OUT_NO_PAIRWISE",
      "OUT_NO_REFIT",
      "OUT_NO_DISCOVERY"
    )
    ok <- nrow(a2)==length(expected_ids) &&
      all(c("guard_id","status","critical") %in% names(a2)) &&
      identical(as.character(a2$guard_id),expected_ids) &&
      all(as.character(a2$status)=="PASS") &&
      all(as.character(a2$critical)=="YES")
    check("SHA_S2_AUDIT","S2_AUDIT exact 101-check current-run all-PASS identity",ok,
          paste0("rows=",nrow(a2),";pass=",sum(as.character(a2$status)=="PASS")))
  } else if(identical(nm,"S2_INPUT")) {
    i2 <- read.csv(S2_INPUT,stringsAsFactors=FALSE,check.names=FALSE)
    ids <- c("S1_STATUS","S1_CONTRACT","S1_TAXONOMY","S1_DISPLAY","S1_ELIG","S1_AUDIT","S1_INPUT","DDS","SAMPLE_MAP","A20","GMT")
    schema_ok <- all(c("input_id","path","bytes","sha256") %in% names(i2))
    rows_ok <- nrow(i2)==length(ids) && schema_ok && identical(as.character(i2$input_id),ids)
    self_ok <- FALSE
    if(rows_ok) {
      self_ok <- all(vapply(seq_len(nrow(i2)),function(ii) {
        pth <- as.character(i2$path[ii])
        file.exists(pth) &&
          identical(as.numeric(file.info(pth)$size),as.numeric(i2$bytes[ii])) &&
          identical(tolower(sha256(pth)),tolower(as.character(i2$sha256[ii])))
      },logical(1)))
    }
    check("SHA_S2_INPUT","S2_INPUT exact eleven-row current source-identity ledger",rows_ok && self_ok,
          paste0("rows=",nrow(i2),";self_exact=",self_ok))
  } else if(identical(nm,"DDS")) {
    i2_dds <- read.csv(S2_INPUT,stringsAsFactors=FALSE,check.names=FALSE)
    r2_dds <- i2_dds[as.character(i2_dds$input_id)=="DDS",,drop=FALSE]
    a2_dds <- read.csv(S2_AUDIT,stringsAsFactors=FALSE,check.names=FALSE)
    a2_dds <- a2_dds[as.character(a2_dds$guard_id)=="SHA_DDS",,drop=FALSE]
    ok <- nrow(r2_dds)==1L &&
      nrow(a2_dds)==1L &&
      identical(as.character(a2_dds$status[1]),"PASS") &&
      identical(as.character(a2_dds$critical[1]),"YES") &&
      grepl("current-run chain-of-custody",as.character(a2_dds$requirement[1]),fixed=TRUE) &&
      identical(tolower(as.character(r2_dds$sha256[1])),tolower(got)) &&
      identical(as.numeric(r2_dds$bytes[1]),as.numeric(file.info(DDS)$size))
    check(
      "SHA_DDS",
      "DDS current-run chain-of-custody from accepted Step2 deterministic-execution authority",
      ok,
      paste0("current_sha256=",got,"; step2_sha256=",if(nrow(r2_dds)) r2_dds$sha256[1] else "MISSING",
             "; historical_sha256=",EXPECTED_SHA[[nm]]),
      notes="All six outcome-bearing Step2 tables remain historical exact-SHA below and source-level reconstruction remains mandatory."
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

pre <- do.call(rbind,AUD)
hard_pre <- sum(pre$status=="FAIL" & pre$critical=="YES")
if(hard_pre>0L) {
  awrite(pre,file.path(OUT,"R4C_STEP3_VALIDATION_AUDIT.csv"))
  write_fail_status("HOLD_R4C_STEP3_PREVALIDATION","Frozen-input SHA/file guard failure")
  quit(save="no",status=172,runLast=FALSE)
}

# ==============================================================================
# SOURCE-LEVEL RECONSTRUCTION
# IMPORTANT: no Step2 scientific CSV is opened before this block completes.
# ==============================================================================

ct <- read.csv(S1_CONTRACT,stringsAsFactors=FALSE,check.names=FALSE)
cv <- setNames(as.character(ct$value),ct$item)
tax <- read.csv(S1_TAXONOMY,stringsAsFactors=FALSE,check.names=FALSE)
disp <- read.csv(S1_DISPLAY,stringsAsFactors=FALSE,check.names=FALSE)
elig <- read.csv(S1_ELIG,stringsAsFactors=FALSE,check.names=FALSE)

check("CONTRACT_ROLE","R4C remains descriptive within-R0",
      identical(cv[["module_role"]],"DESCRIPTIVE_WITHIN_R0_PROGRESSION_CHARACTERIZATION"),
      cv[["module_role"]])
check("CONTRACT_NO_INDEPENDENT","Independent validation remains forbidden",
      identical(cv[["independent_validation_allowed"]],"NO"),
      cv[["independent_validation_allowed"]])
check("CONTRACT_NO_INFERENCE","Inference/FDR remain forbidden",
      identical(cv[["inferential_group_test"]],"NONE_DESCRIPTIVE_MODULE") &&
      identical(cv[["trend_pvalue"]],"NO") &&
      identical(cv[["multiple_testing_FDR"]],"NONE") &&
      identical(cv[["pairwise_tests"]],"NO"),
      paste(cv[["inferential_group_test"]],cv[["trend_pvalue"]],
            cv[["multiple_testing_FDR"]],cv[["pairwise_tests"]],sep=" | "))

dds <- readRDS(DDS)
check("DDS_DIM","Source DDS is 19,428 x 142",
      inherits(dds,"DESeqDataSet") &&
      identical(as.integer(dim(dds)),c(19428L,142L)),
      paste(dim(dds),collapse="x"))

sm <- read.csv(SAMPLE_MAP,stringsAsFactors=FALSE,check.names=FALSE)
sm$sample_id <- trimws(as.character(sm$sample_id))
sm$disease_group <- trimws(as.character(sm$disease_group))
grp_levels <- c("NF","pRV","RVF")
sm$group_factor <- factor(sm$disease_group,levels=grp_levels,ordered=TRUE)
sm <- sm[order(sm$group_factor,sm$sample_id),,drop=FALSE]

check("SAMPLE142","Source sample map has 142 unique patients",
      nrow(sm)==142L && !anyDuplicated(sm$sample_id),nrow(sm))
grp <- table(factor(sm$disease_group,levels=grp_levels))
check("GROUP_COUNTS","Source groups remain 29/78/35",
      identical(as.integer(grp),c(29L,78L,35L)),
      paste(as.integer(grp),collapse="/"))
check("SAMPLE_SET","DDS and sample-map sets exact",
      setequal(colnames(dds),sm$sample_id),
      paste0("DDS_only=",length(setdiff(colnames(dds),sm$sample_id)),
             ";map_only=",length(setdiff(sm$sample_id,colnames(dds)))))

NORM <- DESeq2::counts(dds,normalized=TRUE)
NORM <- NORM[,sm$sample_id,drop=FALSE]
check("NORM_DIM","Normalized expression is 19,428 x 142",
      identical(as.integer(dim(NORM)),c(19428L,142L)),
      paste(dim(NORM),collapse="x"))
check("NORM_FINITE","Normalized expression finite/nonnegative",
      all(is.finite(NORM)) && all(NORM>=0),
      paste0("negative=",sum(NORM<0,na.rm=TRUE)))

LOG <- log2(NORM+1)
mu <- rowMeans(LOG)
sdev <- apply(LOG,1,sd)
finite142 <- apply(LOG,1,function(v) all(is.finite(v)))
eligible142 <- finite142 & is.finite(sdev) & sdev>0
Z <- (LOG-mu)/sdev

a20 <- read.csv(A20,stringsAsFactors=FALSE,check.names=FALSE)
gl <- readLines(GMT,warn=FALSE)
parts <- strsplit(gl,"\t",fixed=TRUE)
gmt_names <- vapply(parts,`[`,character(1),1L)
gmt_genes <- lapply(
  parts,function(x) unique(if(length(x)>=3L) x[3:length(x)] else character())
)
names(gmt_genes) <- gmt_names
genes <- rownames(dds)
tol <- 1e-12

classify_progression <- function(d1,d2,tol=1e-12) {
  s1 <- if(d1>tol) 1L else if(d1< -tol) -1L else 0L
  s2 <- if(d2>tol) 1L else if(d2< -tol) -1L else 0L
  if(s1== 1L && s2== 1L) return("MONOTONIC_FAILURE_PROGRESSIVE")
  if(s1==-1L && s2== 1L) return("COMPENSATION_THEN_FAILURE_SWITCH")
  if(s1== 1L && s2==-1L) return("BIPHASIC_EARLY_FAILURELIKE_THEN_REVERSE")
  if(s1==-1L && s2==-1L) return("MONOTONIC_OPPOSITE_TO_FAILURE_DIRECTION")
  if(s1== 0L && s2== 1L) return("LATE_FAILURE_TRANSITION")
  if(s1== 1L && s2== 0L) return("EARLY_FAILURELIKE_SHIFT_THEN_PLATEAU")
  if(s1==-1L && s2== 0L) return("EARLY_OPPOSITE_SHIFT_THEN_PLATEAU")
  if(s1== 0L && s2==-1L) return("LATE_OPPOSITE_SHIFT")
  if(s1== 0L && s2== 0L) return("FLAT_WITHIN_TOLERANCE")
  stop("Unexpected sign pattern",call.=FALSE)
}

score_rows <- list()
group_rows <- list()
prog_rows <- list()

for(i in seq_len(nrow(disp))) {
  pid <- disp$pathway[i]
  erow <- elig[elig$pathway==pid,,drop=FALSE]
  arow <- a20[a20$pathway==pid,,drop=FALSE]
  check(paste0("TARGET_",i),
        paste0(pid," exact frozen identity"),
        nrow(erow)==1L && nrow(arow)==1L && isTRUE(erow$assessable[1]),
        paste0("elig=",nrow(erow),";a20=",nrow(arow)))

  members <- gmt_genes[[pid]]
  idx <- match(members,genes)
  idx <- idx[!is.na(idx)]
  idx <- idx[eligible142[idx]]
  check(paste0("USABLE_",i),
        paste0(pid," usable genes exact Step1"),
        length(idx)==as.integer(erow$usable_gene_n[1]),
        paste0(length(idx),"/",erow$usable_gene_n[1]))

  raw_score <- colMeans(Z[idx,,drop=FALSE])
  fail_mult <- if(arow$failure_direction[1]=="UP_IN_FAILURE") 1 else
               if(arow$failure_direction[1]=="DOWN_IN_FAILURE") -1 else NA_real_
  if(!is.finite(fail_mult)) stop("Unexpected failure direction for ",pid,call.=FALSE)
  failure_score <- raw_score*fail_mult

  for(j in seq_len(nrow(sm))) {
    score_rows[[length(score_rows)+1L]] <- data.frame(
      sample_id=sm$sample_id[j],
      disease_group=sm$disease_group[j],
      pathway=pid,
      display_order=disp$display_order[i],
      failure_direction=arow$failure_direction[1],
      Step3F_program_class=arow$program_class[1],
      usable_gene_n=length(idx),
      raw_program_score=raw_score[j],
      failure_oriented_program_score=failure_score[j],
      stringsAsFactors=FALSE
    )
  }

  med <- setNames(numeric(3),grp_levels)
  for(g in grp_levels) {
    v <- failure_score[sm$disease_group==g]
    med[g] <- median(v)
    group_rows[[length(group_rows)+1L]] <- data.frame(
      pathway=pid,
      display_order=disp$display_order[i],
      failure_direction=arow$failure_direction[1],
      Step3F_program_class=arow$program_class[1],
      disease_group=g,
      n=length(v),
      mean=mean(v),
      sd=sd(v),
      median=median(v),
      q25=unname(quantile(v,0.25,type=7)),
      q75=unname(quantile(v,0.75,type=7)),
      min=min(v),
      max=max(v),
      stringsAsFactors=FALSE
    )
  }

  d1 <- med["pRV"]-med["NF"]
  d2 <- med["RVF"]-med["pRV"]
  dtotal <- med["RVF"]-med["NF"]
  pclass <- classify_progression(d1,d2,tol)
  dominant <- if(abs(abs(d1)-abs(d2))<=tol) "TIE_WITHIN_1E-12" else
              if(abs(d1)>abs(d2)) "NF_TO_pRV" else "pRV_TO_RVF"

  prog_rows[[i]] <- data.frame(
    pathway=pid,
    display_order=disp$display_order[i],
    failure_direction=arow$failure_direction[1],
    Step3F_program_class=arow$program_class[1],
    NF_median=unname(med["NF"]),
    pRV_median=unname(med["pRV"]),
    RVF_median=unname(med["RVF"]),
    D1_pRV_minus_NF=unname(d1),
    D2_RVF_minus_pRV=unname(d2),
    Dtotal_RVF_minus_NF=unname(dtotal),
    progression_class=pclass,
    dominant_transition=dominant,
    total_failure_oriented_direction=
      if(dtotal>tol) "RVF_MORE_FAILURE_ORIENTED_THAN_NF"
      else if(dtotal< -tol) "RVF_LESS_FAILURE_ORIENTED_THAN_NF"
      else "RVF_APPROX_NF_WITHIN_1E-12",
    inferential_p_value=NA_real_,
    interpretation_role="DESCRIPTIVE_WITHIN_R0_NOT_INDEPENDENT_VALIDATION",
    stringsAsFactors=FALSE
  )
}

recon_scores <- do.call(rbind,score_rows)
recon_group <- do.call(rbind,group_rows)
recon_prog <- do.call(rbind,prog_rows)

recon_class <- merge(
  tax[,c("priority","progression_class","interpretation"),drop=FALSE],
  as.data.frame(table(
    factor(recon_prog$progression_class,levels=tax$progression_class)
  ),stringsAsFactors=FALSE),
  by.x="progression_class",by.y="Var1",all.x=TRUE,sort=FALSE
)
names(recon_class)[names(recon_class)=="Freq"] <- "program_n"
recon_class <- recon_class[order(recon_class$priority),,drop=FALSE]

role_levels <- c(
  "PROGRAM_REVERSAL_SUPPORTED",
  "PROGRAM_MALADAPTIVE_NONREVERSAL_WORSENING_SUPPORTED",
  "PROGRAM_SITE_CONFLICT",
  "PROGRAM_INDETERMINATE_NO_MAIN_SIGNAL"
)
recon_cross <- as.data.frame(
  table(
    factor(recon_prog$Step3F_program_class,levels=role_levels),
    factor(recon_prog$progression_class,levels=tax$progression_class)
  ),
  stringsAsFactors=FALSE
)
names(recon_cross) <- c("Step3F_program_class","R4C_progression_class","program_n")
recon_cross <- recon_cross[recon_cross$program_n>0,,drop=FALSE]

recon_overall <- data.frame(
  metric=c(
    "patients","NF_n","pRV_n","RVF_n","programs","patient_program_scores",
    "group_summary_rows","monotonic_failure_progressive_n",
    "compensation_then_failure_switch_n",
    "biphasic_early_failurelike_then_reverse_n",
    "monotonic_opposite_to_failure_direction_n",
    "RVF_more_failure_oriented_than_NF_n",
    "RVF_less_failure_oriented_than_NF_n",
    "inferential_tests","multiple_testing_FDR","independent_validation"
  ),
  value=c(
    142,29,78,35,16,nrow(recon_scores),nrow(recon_group),
    sum(recon_prog$progression_class=="MONOTONIC_FAILURE_PROGRESSIVE"),
    sum(recon_prog$progression_class=="COMPENSATION_THEN_FAILURE_SWITCH"),
    sum(recon_prog$progression_class=="BIPHASIC_EARLY_FAILURELIKE_THEN_REVERSE"),
    sum(recon_prog$progression_class=="MONOTONIC_OPPOSITE_TO_FAILURE_DIRECTION"),
    sum(recon_prog$Dtotal_RVF_minus_NF>tol),
    sum(recon_prog$Dtotal_RVF_minus_NF< -tol),
    "NONE","NONE","NO"
  ),
  stringsAsFactors=FALSE
)

check("RECON_SCORES_N","Source reconstruction yields 2272 scores",
      nrow(recon_scores)==2272L,nrow(recon_scores))
check("RECON_GROUP_N","Source reconstruction yields 48 group summaries",
      nrow(recon_group)==48L,nrow(recon_group))
check("RECON_PROG_N","Source reconstruction yields 16 program classifications",
      nrow(recon_prog)==16L,nrow(recon_prog))

# ==============================================================================
# ONLY NOW OPEN STEP2 SCIENTIFIC OUTPUT TABLES AND COMPARE.
# ==============================================================================

obs_status <- read.csv(S2_STATUS,stringsAsFactors=FALSE,check.names=FALSE)
obs_scores <- read.csv(S2_SCORES,stringsAsFactors=FALSE,check.names=FALSE)
obs_group <- read.csv(S2_GROUP,stringsAsFactors=FALSE,check.names=FALSE)
obs_prog <- read.csv(S2_PROG,stringsAsFactors=FALSE,check.names=FALSE)
obs_class <- read.csv(S2_CLASS,stringsAsFactors=FALSE,check.names=FALSE)
obs_cross <- read.csv(S2_CROSS,stringsAsFactors=FALSE,check.names=FALSE)
obs_overall <- read.csv(S2_OVERALL,stringsAsFactors=FALSE,check.names=FALSE)

check("STEP2_PASS","Step2 producer PASS with zero hard failures",
      nrow(obs_status)==1L &&
      identical(obs_status$final_state[1],
        "PASS_R4C_STEP2_DETERMINISTIC_PROGRESSION_EXECUTION_READY_FOR_INDEPENDENT_AUDIT") &&
      as.integer(obs_status$hard_failures[1])==0L,
      paste(obs_status$final_state[1],obs_status$hard_failures[1],sep=" | "))
check("STEP2_NO_INFERENCE","Step2 recorded no inference/FDR/refit",
      identical(obs_status$inferential_tests_executed[1],"NO") &&
      identical(obs_status$multiple_testing_FDR_executed[1],"NO") &&
      identical(obs_status$pairwise_inferential_tests_executed[1],"NO") &&
      identical(obs_status$DESeq2_refit_executed[1],"NO"),
      paste(obs_status$inferential_tests_executed[1],
            obs_status$multiple_testing_FDR_executed[1],
            obs_status$pairwise_inferential_tests_executed[1],
            obs_status$DESeq2_refit_executed[1],sep=" | "))

tolnum <- 1e-12

# Patient-program scores.
rs <- recon_scores[order(recon_scores$pathway,recon_scores$sample_id),,drop=FALSE]
os <- obs_scores[order(obs_scores$pathway,obs_scores$sample_id),,drop=FALSE]
check("SCORE_KEYS","2272 score keys exact",
      identical(paste(rs$pathway,rs$sample_id,sep="||"),
                paste(os$pathway,os$sample_id,sep="||")),
      nrow(os))
for(cc in c("raw_program_score","failure_oriented_program_score")) {
  d <- max(abs(as.numeric(rs[[cc]])-as.numeric(os[[cc]])))
  check(paste0("SCORE_",cc),paste0(cc," max abs diff <=1e-12"),
        d<=tolnum,format(d,scientific=TRUE,digits=10))
}
check("SCORE_METADATA","Score metadata exact",
      identical(as.character(rs$disease_group),as.character(os$disease_group)) &&
      identical(as.integer(rs$display_order),as.integer(os$display_order)) &&
      identical(as.character(rs$failure_direction),as.character(os$failure_direction)) &&
      identical(as.character(rs$Step3F_program_class),as.character(os$Step3F_program_class)) &&
      identical(as.integer(rs$usable_gene_n),as.integer(os$usable_gene_n)),
      "2272 rows")

# Group summaries.
rg <- recon_group[order(recon_group$pathway,recon_group$disease_group),,drop=FALSE]
og <- obs_group[order(obs_group$pathway,obs_group$disease_group),,drop=FALSE]
check("GROUP_KEYS","48 group-summary keys exact",
      identical(paste(rg$pathway,rg$disease_group,sep="||"),
                paste(og$pathway,og$disease_group,sep="||")),
      nrow(og))
for(cc in c("n","mean","sd","median","q25","q75","min","max")) {
  d <- max(abs(as.numeric(rg[[cc]])-as.numeric(og[[cc]])))
  check(paste0("GROUP_",cc),paste0(cc," max abs diff <=1e-12"),
        d<=tolnum,format(d,scientific=TRUE,digits=10))
}

# Progression classification.
rp <- recon_prog[order(recon_prog$pathway),,drop=FALSE]
op <- obs_prog[order(obs_prog$pathway),,drop=FALSE]
check("PROG_KEYS","16 progression keys exact",
      identical(rp$pathway,op$pathway),nrow(op))
for(cc in c(
  "NF_median","pRV_median","RVF_median",
  "D1_pRV_minus_NF","D2_RVF_minus_pRV","Dtotal_RVF_minus_NF"
)) {
  d <- max(abs(as.numeric(rp[[cc]])-as.numeric(op[[cc]])))
  check(paste0("PROG_",cc),paste0(cc," max abs diff <=1e-12"),
        d<=tolnum,format(d,scientific=TRUE,digits=10))
}
check("PROG_CLASS","All 16 progression classes exact",
      identical(as.character(rp$progression_class),as.character(op$progression_class)),
      paste(table(op$progression_class),collapse=";"))
check("PROG_DOMINANT","All 16 dominant-transition labels exact",
      identical(as.character(rp$dominant_transition),as.character(op$dominant_transition)),
      paste(table(op$dominant_transition),collapse=";"))
check("PROG_TOTAL_DIRECTION","All 16 total-direction labels exact",
      identical(as.character(rp$total_failure_oriented_direction),
                as.character(op$total_failure_oriented_direction)),
      paste(table(op$total_failure_oriented_direction),collapse=";"))
check("PROG_NO_P","All inferential_p_value entries are NA",
      all(is.na(op$inferential_p_value)),paste0(sum(is.na(op$inferential_p_value)),"/16"))

# Class summary exact.
rc <- recon_class[order(recon_class$priority),,drop=FALSE]
oc <- obs_class[order(obs_class$priority),,drop=FALSE]
check("CLASS_KEYS","9 taxonomy rows exact",
      identical(as.character(rc$progression_class),
                as.character(oc$progression_class)),nrow(oc))
check("CLASS_COUNTS","All 9 taxonomy class counts exact",
      identical(as.integer(rc$program_n),as.integer(oc$program_n)),
      paste(paste(oc$progression_class,oc$program_n,sep="="),collapse=";"))

# Step3F x R4C crosstab exact.
rcr <- recon_cross[order(recon_cross$Step3F_program_class,
                         recon_cross$R4C_progression_class),,drop=FALSE]
ocr <- obs_cross[order(obs_cross$Step3F_program_class,
                       obs_cross$R4C_progression_class),,drop=FALSE]
check("CROSS_KEYS","Step3F x progression crosstab keys exact",
      identical(paste(rcr$Step3F_program_class,rcr$R4C_progression_class,sep="||"),
                paste(ocr$Step3F_program_class,ocr$R4C_progression_class,sep="||")),
      nrow(ocr))
check("CROSS_COUNTS","Step3F x progression counts exact",
      identical(as.integer(rcr$program_n),as.integer(ocr$program_n)),
      paste(ocr$program_n,collapse=";"))

# Overall summary exact as strings.
ro <- recon_overall
oo <- obs_overall
check("OVERALL_METRICS","Overall summary metric identities exact",
      identical(as.character(ro$metric),as.character(oo$metric)),nrow(oo))
check("OVERALL_VALUES","Overall summary values exact",
      identical(as.character(ro$value),as.character(oo$value)),
      paste(oo$value,collapse=";"))

# ------------------------------------------------------------------------------
# Independently audited headline identities — frozen after Step2 review.
# ------------------------------------------------------------------------------

EXPECTED_CLASS <- c(
  HALLMARK_ADIPOGENESIS="MONOTONIC_FAILURE_PROGRESSIVE",
  HALLMARK_ALLOGRAFT_REJECTION="COMPENSATION_THEN_FAILURE_SWITCH",
  HALLMARK_ANGIOGENESIS="MONOTONIC_FAILURE_PROGRESSIVE",
  HALLMARK_APICAL_JUNCTION="MONOTONIC_OPPOSITE_TO_FAILURE_DIRECTION",
  HALLMARK_COAGULATION="MONOTONIC_OPPOSITE_TO_FAILURE_DIRECTION",
  HALLMARK_EPITHELIAL_MESENCHYMAL_TRANSITION="MONOTONIC_FAILURE_PROGRESSIVE",
  HALLMARK_ESTROGEN_RESPONSE_EARLY="MONOTONIC_OPPOSITE_TO_FAILURE_DIRECTION",
  HALLMARK_FATTY_ACID_METABOLISM="MONOTONIC_FAILURE_PROGRESSIVE",
  HALLMARK_IL2_STAT5_SIGNALING="MONOTONIC_OPPOSITE_TO_FAILURE_DIRECTION",
  HALLMARK_IL6_JAK_STAT3_SIGNALING="COMPENSATION_THEN_FAILURE_SWITCH",
  HALLMARK_INFLAMMATORY_RESPONSE="COMPENSATION_THEN_FAILURE_SWITCH",
  HALLMARK_INTERFERON_ALPHA_RESPONSE="BIPHASIC_EARLY_FAILURELIKE_THEN_REVERSE",
  HALLMARK_INTERFERON_GAMMA_RESPONSE="MONOTONIC_OPPOSITE_TO_FAILURE_DIRECTION",
  HALLMARK_MYC_TARGETS_V1="MONOTONIC_FAILURE_PROGRESSIVE",
  HALLMARK_OXIDATIVE_PHOSPHORYLATION="MONOTONIC_FAILURE_PROGRESSIVE",
  HALLMARK_TNFA_SIGNALING_VIA_NFKB="COMPENSATION_THEN_FAILURE_SWITCH"
)

obs_class_by_path <- setNames(op$progression_class,op$pathway)
check("EXPECTED_CLASS16","All 16 independently audited class identities exact",
      identical(as.character(obs_class_by_path[names(EXPECTED_CLASS)]),
                as.character(EXPECTED_CLASS)),
      paste(paste(names(EXPECTED_CLASS),
                  obs_class_by_path[names(EXPECTED_CLASS)],sep="="),collapse=";"))

check("HEADLINE_COUNTS",
      "Frozen class counts are 6 progressive / 4 switch / 5 opposite / 1 biphasic",
      sum(op$progression_class=="MONOTONIC_FAILURE_PROGRESSIVE")==6L &&
      sum(op$progression_class=="COMPENSATION_THEN_FAILURE_SWITCH")==4L &&
      sum(op$progression_class=="MONOTONIC_OPPOSITE_TO_FAILURE_DIRECTION")==5L &&
      sum(op$progression_class=="BIPHASIC_EARLY_FAILURELIKE_THEN_REVERSE")==1L,
      paste(table(op$progression_class),collapse=";"))

check("TOTAL_DIRECTION_7_9",
      "RVF-vs-NF patient-level module median direction is 7 more-failure-like / 9 less-failure-like",
      sum(op$Dtotal_RVF_minus_NF>tol)==7L &&
      sum(op$Dtotal_RVF_minus_NF< -tol)==9L,
      paste0(sum(op$Dtotal_RVF_minus_NF>tol),"/",
             sum(op$Dtotal_RVF_minus_NF< -tol)))

check("DOMINANT_9_7",
      "Dominant absolute median transition is NF->pRV for 9 and pRV->RVF for 7",
      sum(op$dominant_transition=="NF_TO_pRV")==9L &&
      sum(op$dominant_transition=="pRV_TO_RVF")==7L,
      paste0(sum(op$dominant_transition=="NF_TO_pRV"),"/",
             sum(op$dominant_transition=="pRV_TO_RVF")))

# Important non-overclaiming interpretation freeze.
interpretation <- data.frame(
  item=c(
    "R4C_role",
    "patient_n",
    "program_n",
    "monotonic_failure_progressive_n",
    "compensation_then_failure_switch_n",
    "monotonic_opposite_to_failure_direction_n",
    "biphasic_early_failurelike_then_reverse_n",
    "RVF_more_failure_oriented_than_NF_n",
    "RVF_less_failure_oriented_than_NF_n",
    "dominant_NF_to_pRV_n",
    "dominant_pRV_to_RVF_n",
    "R0_used_in_stable16_discovery",
    "independent_validation",
    "cross_sectional_not_longitudinal",
    "module_score_vs_GSEA_authority",
    "allowed_manuscript_interpretation",
    "forbidden_interpretation"
  ),
  value=c(
    "DESCRIPTIVE_WITHIN_R0_CROSS_SECTIONAL_PROGRESSION_CHARACTERIZATION",
    "142","16","6","4","5","1","7","9","9","7",
    "YES","NO","YES",
    "R4C_SIMPLE_PATIENT_LEVEL_MEAN_Z_MODULE_SCORES_DO_NOT_REDEFINE_FROZEN_FULL_RANKED_GSEA_FAILURE_PROGRAM_IDENTITY_OR_DIRECTION",
    "FROZEN_STABLE_RV_FAILURE_PROGRAMS_SHOW_HETEROGENEOUS_CROSS_SECTIONAL_NF_PRV_RVF_PATIENT_LEVEL_MODULE_SCORE_PATTERNS_WITH_DISTINCT_EARLY_AND_LATE_TRANSITION_PROFILES",
    "NO_INDEPENDENT_VALIDATION;NO_TEMPORAL_WITHIN_PATIENT_PROGRESSION;NO_SIGNIFICANCE_LANGUAGE;NO_RECLASSIFICATION_OF_FROZEN_GSEA_PROGRAMS_FROM_R4C_SCORE_PATTERN"
  ),
  stringsAsFactors=FALSE
)
awrite(interpretation,file.path(OUT,"R4C_STEP3_INTERPRETATION_FREEZE.csv"))

validated_summary <- data.frame(
  metric=c(
    "patients","programs","patient_program_scores","group_summary_rows",
    "monotonic_failure_progressive","compensation_then_failure_switch",
    "monotonic_opposite_to_failure_direction",
    "biphasic_early_failurelike_then_reverse",
    "RVF_more_failure_oriented_than_NF",
    "RVF_less_failure_oriented_than_NF",
    "dominant_NF_to_pRV","dominant_pRV_to_RVF"
  ),
  value=c(142,16,2272,48,6,4,5,1,7,9,9,7),
  stringsAsFactors=FALSE
)
awrite(validated_summary,file.path(OUT,"R4C_STEP3_VALIDATED_SUMMARY.csv"))

audit <- do.call(rbind,AUD)
hard_fail <- sum(audit$status=="FAIL" & audit$critical=="YES")
awrite(audit,file.path(OUT,"R4C_STEP3_VALIDATION_AUDIT.csv"))

input_rows <- do.call(rbind,lapply(names(P),function(nm) data.frame(
  input_id=nm,path=P[[nm]],bytes=file.info(P[[nm]])$size,
  sha256=sha256(P[[nm]]),stringsAsFactors=FALSE
)))
awrite(input_rows,file.path(OUT,"R4C_STEP3_INPUT_SHA256.csv"))

state <- if(hard_fail==0L) {
  "FINAL_CLOSED_R4C_R0_NF_PRV_RVF_PROGRESSION_CHARACTERIZATION"
} else {
  "HOLD_R4C_STEP3_POSTGEN_VALIDATION"
}

awrite(data.frame(
  final_state=state,
  run_id=STAMP,
  hard_failures=hard_fail,
  source_level_independent_reconstruction="YES",
  Step2_scientific_outputs_modified="NO",
  new_scientific_testing="NO",
  inferential_tests_executed="NO",
  multiple_testing_FDR_executed="NO",
  DESeq2_refit_executed="NO",
  new_program_discovery="NO",
  thresholds_retuned="NO",
  frozen_GSEA_program_identity_modified="NO",
  terminal_closed=if(hard_fail==0L) "YES" else "NO",
  next_stage=if(hard_fail==0L)
    "R4_ABC_COMPLETE_THEN_GLOBAL_PAPER_SYNTHESIS_AND_DISPLAY_REINTEGRATION"
  else "STOP_AND_REPAIR_VALIDATION_ONLY",
  stringsAsFactors=FALSE
),file.path(OUT,"R4C_STEP3_STATUS.csv"))

cat("FINAL_STATE:",state,"\n")
cat("RUN_ID:",STAMP,"\n")
cat("HARD_FAILURES:",hard_fail,"\n")
cat("SOURCE_LEVEL_RECONSTRUCTION:YES\n")
cat("CLASS_COUNTS:PROGRESSIVE=6;SWITCH=4;OPPOSITE=5;BIPHASIC=1\n")
cat("TOTAL_DIRECTION:RVF_MORE=7;RVF_LESS=9\n")
cat("DOMINANT_TRANSITION:NF_TO_pRV=9;pRV_TO_RVF=7\n")
cat("NEW_SCIENTIFIC_TESTING:NO\n")
quit(save="no",status=if(hard_fail==0L) 0 else 173,runLast=FALSE)
