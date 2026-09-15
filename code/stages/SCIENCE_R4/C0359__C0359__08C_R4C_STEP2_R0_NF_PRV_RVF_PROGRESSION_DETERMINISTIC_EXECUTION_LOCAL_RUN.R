# Gate9K V1.32 repair: current R4C Step1 run-record binding; science unchanged.
# Stable method contract/taxonomy/display/eligibility remain historical exact-SHA.
# ---- RV PUBLIC PRIMARY DAG GATE9J REWRITE V1.0 ----
# source_id=C0359
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
# RV Project — R4C Step2
# R0 NF -> pRV -> RVF PROGRAM PROGRESSION — DETERMINISTIC EXECUTION
#
# FIRST outcome-bearing R4C gate.
# Executes ONLY descriptive rules frozen in R4C Step1 V1.2
# accepted RUN_ID = 20260911_011411.
#
# NO inferential P value.
# NO FDR.
# NO pairwise inferential testing.
# NO DESeq2 refit.
# NO new pathway/gene discovery.
# NO threshold retuning.
#
# Scientific boundary:
#   R0 contributed to discovery of the stable16 target family.
#   R4C is descriptive within-R0 cross-sectional progression characterization,
#   NOT independent validation and NOT longitudinal within-patient progression.
# ==============================================================================

options(stringsAsFactors=FALSE, warn=1)
args <- commandArgs(trailingOnly=TRUE)
STAMP <- if(length(args)>=1 && nzchar(args[1])) args[1] else format(Sys.time(),"%Y%m%d_%H%M%S")

ROOT <- normalizePath(getwd(),winslash="/",mustWork=TRUE)
if(!identical(ROOT,RV_PROJECT_ROOT)) stop("Expected working directory D:/RV_project",call.=FALSE)

OUTROOT <- file.path(ROOT,"results","R4C_R0_NF_PRV_RVF_PROGRESSION_EXECUTION")
OUT <- file.path(OUTROOT,STAMP)
dir.create(OUT,recursive=TRUE,showWarnings=FALSE)

write_fail_status <- function(state, error_message="") {
  write.csv(data.frame(
    final_state=state,
    run_id=STAMP,
    hard_failures=1,
    progression_execution_completed="NO",
    program_scores_calculated="NO",
    group_progression_compared="NO",
    progression_classes_assigned="NO",
    inferential_tests_executed="NO",
    multiple_testing_FDR_executed="NO",
    DESeq2_refit_executed="NO",
    new_program_discovery="NO",
    thresholds_retuned="NO",
    error=as.character(error_message),
    stringsAsFactors=FALSE
  ),file.path(OUT,"R4C_STEP2_STATUS.csv"),row.names=FALSE,na="")
}

options(error=function() {
  msg <- geterrmessage()
  try(write.csv(data.frame(
    phase="UNHANDLED_ERROR",error=msg,stringsAsFactors=FALSE
  ),file.path(OUT,"R4C_STEP2_UNHANDLED_ERROR.csv"),row.names=FALSE,na=""),silent=TRUE)
  try(write_fail_status("HOLD_R4C_STEP2_UNHANDLED_ERROR",msg),silent=TRUE)
  quit(save="no",status=169,runLast=FALSE)
})

project_lib <- file.path(ROOT,"R_library","R-4.6")
windows_user_lib <- file.path(Sys.getenv("LOCALAPPDATA"),"R","win-library","4.6")
libs <- c(project_lib,windows_user_lib)
libs <- libs[dir.exists(libs)]
.libPaths(unique(c(libs,.libPaths())))

if(!requireNamespace("digest",quietly=TRUE)) {
  write_fail_status("HOLD_R4C_STEP2_BOOT_ENVIRONMENT","digest unavailable")
  quit(save="no",status=160,runLast=FALSE)
}
if(!requireNamespace("DESeq2",quietly=TRUE)) {
  write_fail_status("HOLD_R4C_STEP2_BOOT_ENVIRONMENT","DESeq2 unavailable")
  quit(save="no",status=160,runLast=FALSE)
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

STEP1 <- rv_resolve_stage_run(
  file.path(ROOT,"results","R4C_R0_NF_PRV_RVF_PROGRESSION_METHOD_CONTRACT_V1_2")
)

S1_STATUS   <- file.path(STEP1,"R4C_STEP1_STATUS.csv")
S1_CONTRACT <- file.path(STEP1,"R4C_STEP1_PROGRESSION_METHOD_CONTRACT.csv")
S1_TAXONOMY <- file.path(STEP1,"R4C_STEP1_PROGRESSION_CLASS_TAXONOMY.csv")
S1_DISPLAY  <- file.path(STEP1,"R4C_STEP1_DISPLAY_ORDER_CONTRACT.csv")
S1_ELIG     <- file.path(STEP1,"R4C_STEP1_PROGRAM_ELIGIBILITY_AUDIT.csv")
S1_AUDIT    <- file.path(STEP1,"R4C_STEP1_METHOD_CONTRACT_AUDIT.csv")
S1_INPUT    <- file.path(STEP1,"R4C_STEP1_INPUT_SHA256.csv")

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

EXPECTED_SHA <- c(
  S1_STATUS   ="c80331d8acbe23a421dc7e21d390cce29adb4df079804f672bd6ea2558f15fce",
  S1_CONTRACT ="cd58a45e98b5fda568bdba372e81d4f8f956453ccde56df190fa6671ba49f616",
  S1_TAXONOMY ="5274da64485e2bad44044774bb008faa45d05355f4f0a847fa1a11818cf45ee0",
  S1_DISPLAY  ="00db46b2621a9ae47045eb9da5792046d879239f53fd7dda70258133d87167f0",
  S1_ELIG     ="646ea9573370993767d226271ea9042dfda34ad69f69d101b43d63888d090091",
  S1_AUDIT    ="c27c5b499f58769e59c61684bfe00185d1d8eedf8f87690b720cd3d08ac7d81f",
  S1_INPUT    ="02e00a9967daa7a9854c4e8afd077ed281b7aac90efe556fe422bdb7f357f429",
  DDS         ="cfe6b796af4cc12b8663217835f0fdc7fd9053e2180b298773f3b3bbe0e12845",
  SAMPLE_MAP  ="e4f51929b8d8a928690b8b90969d9e3ecb0349b9f47408e4828b32d6a3b7a175",
  A20         ="49cd4da614f699f1c35d91e61d1bc59e2add6483c71aa23947fdab49a6a60068",
  GMT         ="eecaf6dad908334ae885406ec72bdc0646d8917588ed7c219fac92fc5363f596"
)

P <- list(
  S1_STATUS=S1_STATUS,S1_CONTRACT=S1_CONTRACT,S1_TAXONOMY=S1_TAXONOMY,
  S1_DISPLAY=S1_DISPLAY,S1_ELIG=S1_ELIG,S1_AUDIT=S1_AUDIT,S1_INPUT=S1_INPUT,
  DDS=DDS,SAMPLE_MAP=SAMPLE_MAP,A20=A20,GMT=GMT
)

for(nm in names(P)) {
  check(paste0("FILE_",nm),paste0(nm," exists"),file.exists(P[[nm]]),P[[nm]])
}
if(any(!vapply(P,file.exists,logical(1)))) {
  awrite(do.call(rbind,AUD),file.path(OUT,"R4C_STEP2_EXECUTION_AUDIT.csv"))
  write_fail_status("HOLD_R4C_STEP2_MISSING_INPUT","One or more frozen inputs missing")
  quit(save="no",status=161,runLast=FALSE)
}

# Gate9K V1.32: S1_STATUS/S1_AUDIT/S1_INPUT are current-run records.
# Stable method/scientific artifacts remain historical exact-SHA.
for(nm in names(EXPECTED_SHA)) {
  got <- sha256(P[[nm]])
  if(identical(nm,"S1_STATUS")) {
    s1_pre <- read.csv(S1_STATUS,stringsAsFactors=FALSE,check.names=FALSE)
    s1_run_id <- basename(STEP1)
    need <- c("final_state","run_id","hard_failures","normalized_expression_extracted",
              "program_scores_calculated","group_progression_compared",
              "progression_classes_assigned","inferential_tests_executed",
              "DESeq2_refit_executed","new_program_discovery","thresholds_retuned","next_stage")
    ok <- nrow(s1_pre)==1L && all(need %in% names(s1_pre)) &&
      identical(as.character(s1_pre$final_state[1]),"PASS_R4C_STEP1_PROGRESSION_METHOD_CONTRACT_READY_FOR_INDEPENDENT_AUDIT") &&
      identical(as.character(s1_pre$run_id[1]),s1_run_id) &&
      identical(as.integer(s1_pre$hard_failures[1]),0L) &&
      identical(as.character(s1_pre$normalized_expression_extracted[1]),"YES_PREOUTCOME_ELIGIBILITY_ONLY") &&
      identical(as.character(s1_pre$program_scores_calculated[1]),"NO") &&
      identical(as.character(s1_pre$group_progression_compared[1]),"NO") &&
      identical(as.character(s1_pre$progression_classes_assigned[1]),"NO") &&
      identical(as.character(s1_pre$inferential_tests_executed[1]),"NO") &&
      identical(as.character(s1_pre$DESeq2_refit_executed[1]),"NO") &&
      identical(as.character(s1_pre$new_program_discovery[1]),"NO") &&
      identical(as.character(s1_pre$thresholds_retuned[1]),"NO") &&
      identical(as.character(s1_pre$next_stage[1]),"CHATGPT_INDEPENDENT_AUDIT_THEN_R4C_STEP2_DETERMINISTIC_PROGRESSION_EXECUTION")
    check("SHA_S1_STATUS","S1_STATUS exact current-run method-contract semantics",ok,
          if(nrow(s1_pre)) paste(s1_pre$run_id[1],s1_pre$final_state[1],s1_pre$hard_failures[1],sep=" | ") else "NO_ROW")
  } else if(identical(nm,"S1_AUDIT")) {
    a1 <- read.csv(S1_AUDIT,stringsAsFactors=FALSE,check.names=FALSE)
    expected_ids <- c(
      "FILE_S0_STATUS",
      "FILE_S0_BOUNDARY",
      "FILE_S0_MAP",
      "FILE_S0_STRUCT",
      "FILE_S0_AUDIT",
      "FILE_S0_INPUT",
      "FILE_DDS",
      "FILE_SAMPLE_MAP",
      "FILE_A20",
      "FILE_GMT",
      "SHA_S0_STATUS",
      "SHA_S0_BOUNDARY",
      "SHA_S0_MAP",
      "SHA_S0_STRUCT",
      "SHA_S0_AUDIT",
      "SHA_S0_INPUT",
      "SHA_DDS",
      "SHA_SAMPLE_MAP",
      "SHA_A20",
      "SHA_GMT",
      "STEP0_PASS",
      "STEP0_NO_OUTCOME",
      "DDS_CLASS",
      "DDS_DIM",
      "SAMPLE142",
      "GROUP_COUNTS",
      "SAMPLE_SET",
      "NORMALIZATION_AUTHORITY",
      "NORMALIZATION_MODE",
      "NORM_DIM",
      "NORM_FINITE_NONNEG",
      "TARGET_UNIQUE",
      "ELIG16",
      "USABLE10"
    )
    ok <- nrow(a1)==length(expected_ids) &&
      all(c("guard_id","status","critical") %in% names(a1)) &&
      identical(as.character(a1$guard_id),expected_ids) &&
      all(as.character(a1$status)=="PASS") &&
      all(as.character(a1$critical)=="YES")
    check("SHA_S1_AUDIT","S1_AUDIT exact 34-check current-run all-PASS identity",ok,
          paste0("rows=",nrow(a1),";pass=",sum(as.character(a1$status)=="PASS")))
  } else if(identical(nm,"S1_INPUT")) {
    i1 <- read.csv(S1_INPUT,stringsAsFactors=FALSE,check.names=FALSE)
    ids <- c("S0_STATUS","S0_BOUNDARY","S0_MAP","S0_STRUCT","S0_AUDIT","S0_INPUT","DDS","SAMPLE_MAP","A20","GMT")
    schema_ok <- all(c("input_id","path","bytes","sha256") %in% names(i1))
    rows_ok <- nrow(i1)==length(ids) && schema_ok && identical(as.character(i1$input_id),ids)
    self_ok <- FALSE
    if(rows_ok) {
      self_ok <- all(vapply(seq_len(nrow(i1)),function(ii) {
        pth <- as.character(i1$path[ii])
        file.exists(pth) &&
          identical(as.numeric(file.info(pth)$size),as.numeric(i1$bytes[ii])) &&
          identical(tolower(sha256(pth)),tolower(as.character(i1$sha256[ii])))
      },logical(1)))
    }
    check("SHA_S1_INPUT","S1_INPUT exact ten-row current source-identity ledger",rows_ok && self_ok,
          paste0("rows=",nrow(i1),";self_exact=",self_ok))
  } else if(identical(nm,"DDS")) {
    i1_dds <- read.csv(S1_INPUT,stringsAsFactors=FALSE,check.names=FALSE)
    r1_dds <- i1_dds[as.character(i1_dds$input_id)=="DDS",,drop=FALSE]
    a1_dds <- read.csv(S1_AUDIT,stringsAsFactors=FALSE,check.names=FALSE)
    a1_dds <- a1_dds[as.character(a1_dds$guard_id)=="SHA_DDS",,drop=FALSE]
    ok <- nrow(r1_dds)==1L &&
      nrow(a1_dds)==1L &&
      identical(as.character(a1_dds$status[1]),"PASS") &&
      identical(as.character(a1_dds$critical[1]),"YES") &&
      grepl("current-run chain-of-custody",as.character(a1_dds$requirement[1]),fixed=TRUE) &&
      identical(tolower(as.character(r1_dds$sha256[1])),tolower(got)) &&
      identical(as.numeric(r1_dds$bytes[1]),as.numeric(file.info(DDS)$size))
    check(
      "SHA_DDS",
      "DDS current-run chain-of-custody from accepted Step1 method-contract authority",
      ok,
      paste0("current_sha256=",got,"; step1_sha256=",if(nrow(r1_dds)) r1_dds$sha256[1] else "MISSING",
             "; historical_sha256=",EXPECTED_SHA[[nm]]),
      notes="No historical DDS byte equality is waived for scientific outputs: Step2 remains deterministic and Step3/downstream figures require the frozen historical outcome-table SHAs."
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

s1 <- read.csv(S1_STATUS,stringsAsFactors=FALSE,check.names=FALSE)
check(
  "STEP1_PASS",
  "Accepted R4C Step1 V1.2 is PASS with zero hard failures",
  nrow(s1)==1L &&
    identical(
      s1$final_state[1],
      "PASS_R4C_STEP1_PROGRESSION_METHOD_CONTRACT_READY_FOR_INDEPENDENT_AUDIT"
    ) &&
    as.integer(s1$hard_failures[1])==0L,
  if(nrow(s1)) paste(s1$final_state[1],s1$hard_failures[1],sep=" | ") else "NO_ROW"
)
check(
  "STEP1_NO_OUTCOME",
  "Step1 did not calculate program scores or compare progression groups",
  nrow(s1)==1L &&
    identical(s1$program_scores_calculated[1],"NO") &&
    identical(s1$group_progression_compared[1],"NO") &&
    identical(s1$progression_classes_assigned[1],"NO") &&
    identical(s1$inferential_tests_executed[1],"NO") &&
    identical(s1$DESeq2_refit_executed[1],"NO"),
  if(nrow(s1)) paste(
    s1$program_scores_calculated[1],
    s1$group_progression_compared[1],
    s1$progression_classes_assigned[1],
    s1$inferential_tests_executed[1],
    s1$DESeq2_refit_executed[1],sep=" | "
  ) else "NO_ROW"
)

ct <- read.csv(S1_CONTRACT,stringsAsFactors=FALSE,check.names=FALSE)
cv <- setNames(as.character(ct$value),ct$item)

must_contract <- c(
  module_role="DESCRIPTIVE_WITHIN_R0_PROGRESSION_CHARACTERIZATION",
  sample_universe="142_PATIENTS",
  group_order="NF<pRV<RVF",
  group_sizes="NF=29;pRV=78;RVF=35",
  R0_used_in_target_discovery="YES",
  independent_validation_allowed="NO",
  target_n="16",
  normalization_authority="DESEQ2_COUNTS_NORMALIZED_TRUE_USING_FROZEN_GENE_BY_SAMPLE_NORMALIZATION_FACTORS",
  DESeq2_refit_allowed="NO",
  expression_transform="LOG2_NORMALIZED_COUNT_PLUS_1",
  gene_standardization="GENEWISE_Z_ACROSS_POOLED_142_PATIENTS_USING_SAMPLE_SD",
  raw_program_score="MEAN_OF_USABLE_MEMBER_GENE_Z_SCORES_PER_PATIENT",
  failure_oriented_program_score="RAW_SCORE_X_PLUS1_IF_UP_IN_FAILURE_ELSE_MINUS1_IF_DOWN_IN_FAILURE",
  group_location_primary="MEDIAN_FAILURE_ORIENTED_PROGRAM_SCORE_PER_GROUP",
  transition_1="MEDIAN_pRV_MINUS_MEDIAN_NF",
  transition_2="MEDIAN_RVF_MINUS_MEDIAN_pRV",
  total_transition="MEDIAN_RVF_MINUS_MEDIAN_NF",
  zero_tolerance="1e-12",
  progression_class_rule="SIGN_PATTERN_OF_TRANSITION1_AND_TRANSITION2_USING_FIXED_TOLERANCE",
  inferential_group_test="NONE_DESCRIPTIVE_MODULE",
  trend_pvalue="NO",
  multiple_testing_FDR="NONE",
  pairwise_tests="NO",
  new_program_discovery="NO",
  new_gene_discovery="NO",
  threshold_retuning_after_results="NO"
)

for(k in names(must_contract)) {
  check(
    paste0("CONTRACT_",k),
    paste0(k," frozen exact"),
    !is.null(cv[[k]]) && identical(cv[[k]],must_contract[[k]]),
    if(!is.null(cv[[k]])) cv[[k]] else "MISSING"
  )
}

elig <- read.csv(S1_ELIG,stringsAsFactors=FALSE,check.names=FALSE)
disp <- read.csv(S1_DISPLAY,stringsAsFactors=FALSE,check.names=FALSE)
tax <- read.csv(S1_TAXONOMY,stringsAsFactors=FALSE,check.names=FALSE)

check(
  "ELIG16",
  "All 16 frozen programs are pre-outcome assessable",
  nrow(elig)==16L && all(elig$assessable),
  paste0(sum(elig$assessable),"/16")
)
check(
  "DISPLAY16",
  "Display contract contains exactly 16 unique frozen pathways",
  nrow(disp)==16L && length(unique(disp$pathway))==16L,
  nrow(disp)
)
check(
  "TAXONOMY9",
  "Progression taxonomy contains exactly 9 frozen classes",
  nrow(tax)==9L && length(unique(tax$progression_class))==9L,
  nrow(tax)
)

pre_audit <- do.call(rbind,AUD)
hard_pre <- sum(pre_audit$status=="FAIL" & pre_audit$critical=="YES")
if(hard_pre>0L) {
  awrite(pre_audit,file.path(OUT,"R4C_STEP2_EXECUTION_AUDIT.csv"))
  write_fail_status("HOLD_R4C_STEP2_PREEXECUTION","Frozen-input/contract guard failure")
  quit(save="no",status=162,runLast=FALSE)
}

# ==============================================================================
# OUTCOME-BEARING DESCRIPTIVE EXECUTION STARTS HERE.
# ==============================================================================

dds <- readRDS(DDS)
check(
  "DDS_DIM",
  "Frozen DDS remains 19,428 genes x 142 samples",
  inherits(dds,"DESeqDataSet") &&
    identical(as.integer(dim(dds)),c(19428L,142L)),
  paste(dim(dds),collapse="x")
)

sm <- read.csv(SAMPLE_MAP,stringsAsFactors=FALSE,check.names=FALSE)
sm$sample_id <- trimws(as.character(sm$sample_id))
sm$disease_group <- trimws(as.character(sm$disease_group))
grp_levels <- c("NF","pRV","RVF")

check(
  "SAMPLE142",
  "Execution universe is 142 unique patients",
  nrow(sm)==142L && !anyDuplicated(sm$sample_id),
  nrow(sm)
)
grp <- table(factor(sm$disease_group,levels=grp_levels))
check(
  "GROUP_COUNTS",
  "Execution group counts remain 29/78/35",
  identical(as.integer(grp),c(29L,78L,35L)),
  paste(as.integer(grp),collapse="/")
)
check(
  "SAMPLE_SET",
  "DDS samples equal frozen exact sample map",
  setequal(colnames(dds),sm$sample_id),
  paste0(
    "DDS_only=",length(setdiff(colnames(dds),sm$sample_id)),
    ";map_only=",length(setdiff(sm$sample_id,colnames(dds)))
  )
)

# Fixed execution/display order: group NF,pRV,RVF then ascending sample_id.
sm$group_factor <- factor(sm$disease_group,levels=grp_levels,ordered=TRUE)
sm <- sm[order(sm$group_factor,sm$sample_id),,drop=FALSE]

NORM <- DESeq2::counts(dds,normalized=TRUE)
NORM <- NORM[,sm$sample_id,drop=FALSE]
check(
  "NORM_DIM",
  "Normalized expression is 19,428 x 142",
  identical(as.integer(dim(NORM)),c(19428L,142L)),
  paste(dim(NORM),collapse="x")
)
check(
  "NORM_FINITE_NONNEG",
  "Normalized expression is finite and nonnegative",
  all(is.finite(NORM)) && all(NORM>=0),
  paste0("negative=",sum(NORM<0,na.rm=TRUE))
)

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
  parts,
  function(x) unique(if(length(x)>=3L) x[3:length(x)] else character())
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
  stop("Unexpected progression sign pattern",call.=FALSE)
}

score_rows <- list()
group_rows <- list()
prog_rows <- list()

for(i in seq_len(nrow(disp))) {
  pid <- disp$pathway[i]
  erow <- elig[elig$pathway==pid,,drop=FALSE]
  arow <- a20[a20$pathway==pid,,drop=FALSE]

  check(
    paste0("TARGET_",i),
    paste0(pid," has one frozen identity/eligibility row"),
    nrow(erow)==1L && nrow(arow)==1L && isTRUE(erow$assessable[1]),
    paste0("elig=",nrow(erow),";a20=",nrow(arow))
  )

  members <- gmt_genes[[pid]]
  idx <- match(members,genes)
  idx <- idx[!is.na(idx)]
  idx <- idx[eligible142[idx]]

  check(
    paste0("USABLE_",i),
    paste0(pid," usable member count matches frozen Step1 eligibility"),
    length(idx)==as.integer(erow$usable_gene_n[1]),
    paste0(length(idx),"/",erow$usable_gene_n[1])
  )

  raw_score <- colMeans(Z[idx,,drop=FALSE])
  fail_mult <- if(arow$failure_direction[1]=="UP_IN_FAILURE") 1 else
               if(arow$failure_direction[1]=="DOWN_IN_FAILURE") -1 else NA_real_
  if(!is.finite(fail_mult)) stop("Unexpected failure direction: ",pid,call.=FALSE)
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

  med <- numeric(3)
  names(med) <- grp_levels

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

  absdiff <- abs(abs(d1)-abs(d2))
  dominant <- if(absdiff<=tol) "TIE_WITHIN_1E-12" else
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

scores <- do.call(rbind,score_rows)
group_summary <- do.call(rbind,group_rows)
progression <- do.call(rbind,prog_rows)

# Fixed class summary, retaining all nine pre-frozen taxonomy categories.
class_summary <- merge(
  tax[,c("priority","progression_class","interpretation"),drop=FALSE],
  as.data.frame(table(
    factor(progression$progression_class,levels=tax$progression_class)
  ),stringsAsFactors=FALSE),
  by.x="progression_class",by.y="Var1",all.x=TRUE,sort=FALSE
)
names(class_summary)[names(class_summary)=="Freq"] <- "program_n"
class_summary <- class_summary[order(class_summary$priority),,drop=FALSE]

# Cross-tab to frozen Step3F PEA class, descriptive only.
role_levels <- c(
  "PROGRAM_REVERSAL_SUPPORTED",
  "PROGRAM_MALADAPTIVE_NONREVERSAL_WORSENING_SUPPORTED",
  "PROGRAM_SITE_CONFLICT",
  "PROGRAM_INDETERMINATE_NO_MAIN_SIGNAL"
)
cross <- as.data.frame(
  table(
    factor(progression$Step3F_program_class,levels=role_levels),
    factor(progression$progression_class,levels=tax$progression_class)
  ),
  stringsAsFactors=FALSE
)
names(cross) <- c("Step3F_program_class","R4C_progression_class","program_n")
cross <- cross[cross$program_n>0,,drop=FALSE]

overall <- data.frame(
  metric=c(
    "patients",
    "NF_n",
    "pRV_n",
    "RVF_n",
    "programs",
    "patient_program_scores",
    "group_summary_rows",
    "monotonic_failure_progressive_n",
    "compensation_then_failure_switch_n",
    "biphasic_early_failurelike_then_reverse_n",
    "monotonic_opposite_to_failure_direction_n",
    "RVF_more_failure_oriented_than_NF_n",
    "RVF_less_failure_oriented_than_NF_n",
    "inferential_tests",
    "multiple_testing_FDR",
    "independent_validation"
  ),
  value=c(
    142,29,78,35,16,nrow(scores),nrow(group_summary),
    sum(progression$progression_class=="MONOTONIC_FAILURE_PROGRESSIVE"),
    sum(progression$progression_class=="COMPENSATION_THEN_FAILURE_SWITCH"),
    sum(progression$progression_class=="BIPHASIC_EARLY_FAILURELIKE_THEN_REVERSE"),
    sum(progression$progression_class=="MONOTONIC_OPPOSITE_TO_FAILURE_DIRECTION"),
    sum(progression$Dtotal_RVF_minus_NF>tol),
    sum(progression$Dtotal_RVF_minus_NF< -tol),
    "NONE","NONE","NO"
  ),
  stringsAsFactors=FALSE
)

awrite(scores,file.path(OUT,"R4C_STEP2_PATIENT_PROGRAM_SCORES.csv"))
awrite(group_summary,file.path(OUT,"R4C_STEP2_PROGRAM_GROUP_SUMMARY.csv"))
awrite(progression,file.path(OUT,"R4C_STEP2_PROGRAM_PROGRESSION_CLASSIFICATION.csv"))
awrite(class_summary,file.path(OUT,"R4C_STEP2_PROGRESSION_CLASS_SUMMARY.csv"))
awrite(cross,file.path(OUT,"R4C_STEP2_STEP3F_BY_PROGRESSION_CROSSTAB.csv"))
awrite(overall,file.path(OUT,"R4C_STEP2_OVERALL_SUMMARY.csv"))

# ------------------------------------------------------------------------------
# Deterministic draft figures — numerical CSVs above remain authority.
# No inferential markers or p values.
# ------------------------------------------------------------------------------

short_name <- function(x) sub("^HALLMARK_","",x)

# Fig A: 16 x 3 group-median heatmap.
gm <- reshape(
  group_summary[,c("pathway","disease_group","median")],
  idvar="pathway",timevar="disease_group",direction="wide"
)
gm <- gm[match(disp$pathway,gm$pathway),,drop=FALSE]
M <- as.matrix(gm[,paste0("median.",grp_levels),drop=FALSE])
rownames(M) <- short_name(gm$pathway)
colnames(M) <- grp_levels
lim <- max(abs(M),na.rm=TRUE)
if(!is.finite(lim) || lim==0) lim <- 1

png(
  file.path(OUT,"R4C_STEP2_FigA_group_median_heatmap.png"),
  width=1450,height=1700,res=180
)
op <- par(mar=c(6,13,3,4))
image(
  x=seq_len(ncol(M)),y=seq_len(nrow(M)),
  z=t(M[nrow(M):1,,drop=FALSE]),
  axes=FALSE,xlab="",ylab="",zlim=c(-lim,lim),
  main="R0 cross-sectional failure-oriented program medians"
)
axis(1,at=seq_len(ncol(M)),labels=colnames(M))
axis(2,at=seq_len(nrow(M)),labels=rev(rownames(M)),las=2,cex.axis=0.72)
mtext(
  "NF → pRV → RVF are cross-sectional groups; descriptive only",
  side=1,line=3.8,cex=0.75
)
par(op)
dev.off()

# Fig B: D1 vs D2 transition map.
png(
  file.path(OUT,"R4C_STEP2_FigB_transition_map.png"),
  width=1500,height=1350,res=180
)
op <- par(mar=c(5,5,3,2))
plot(
  progression$D1_pRV_minus_NF,progression$D2_RVF_minus_pRV,
  pch=19,
  xlab="D1: median(pRV) - median(NF)",
  ylab="D2: median(RVF) - median(pRV)",
  main="Frozen stable16 cross-sectional transition map"
)
abline(h=0,v=0,lty=2)
text(
  progression$D1_pRV_minus_NF,progression$D2_RVF_minus_pRV,
  labels=short_name(progression$pathway),pos=3,cex=0.58
)
mtext(
  "Positive axis direction = more failure-oriented; no inferential testing",
  side=1,line=3.2,cex=0.72
)
par(op)
dev.off()

# Fig C: group distributions for all 16, fixed display order.
png(
  file.path(OUT,"R4C_STEP2_FigC_program_group_distributions.png"),
  width=2600,height=2400,res=180
)
op <- par(mfrow=c(4,4),mar=c(4.5,4,2.5,1))
for(pid in disp$pathway) {
  d <- scores[scores$pathway==pid,,drop=FALSE]
  d$disease_group <- factor(d$disease_group,levels=grp_levels)
  boxplot(
    failure_oriented_program_score ~ disease_group,
    data=d,outline=FALSE,
    xlab="",ylab="Failure-oriented score",
    main=short_name(pid),cex.main=0.72,cex.axis=0.75
  )
}
par(op)
dev.off()

# Fig D: Dtotal ranked in fixed scientific direction.
png(
  file.path(OUT,"R4C_STEP2_FigD_total_failure_oriented_shift.png"),
  width=1700,height=1400,res=180
)
op <- par(mar=c(5,12,3,2))
oo <- order(progression$Dtotal_RVF_minus_NF)
yy <- seq_along(oo)
plot(
  progression$Dtotal_RVF_minus_NF[oo],yy,pch=19,
  yaxt="n",ylab="",
  xlab="Median(RVF) - Median(NF), failure-oriented score",
  main="Total cross-sectional NF-to-RVF shift"
)
axis(
  2,at=yy,
  labels=short_name(progression$pathway[oo]),
  las=2,cex.axis=0.75
)
abline(v=0,lty=2)
mtext(
  "Descriptive within R0; not independent validation",
  side=1,line=3.2,cex=0.75
)
par(op)
dev.off()

# Output guards.
check(
  "OUT_SCORES",
  "Patient-program score table has 142 x 16 rows",
  nrow(scores)==142L*16L,
  nrow(scores)
)
check(
  "OUT_SCORE_KEYS",
  "Patient-program keys are unique",
  !anyDuplicated(paste(scores$sample_id,scores$pathway,sep="||")),
  length(unique(paste(scores$sample_id,scores$pathway,sep="||")))
)
check(
  "OUT_GROUP48",
  "Group summary has 16 x 3 rows",
  nrow(group_summary)==16L*3L,
  nrow(group_summary)
)
check(
  "OUT_PROG16",
  "Progression classification has exactly 16 rows",
  nrow(progression)==16L,
  nrow(progression)
)
check(
  "OUT_CLASS_ALLOWED",
  "Every assigned progression class is in frozen Step1 taxonomy",
  all(progression$progression_class %in% tax$progression_class),
  paste(sort(unique(progression$progression_class)),collapse=";")
)
check(
  "OUT_NO_P",
  "Progression output contains no inferential p values",
  all(is.na(progression$inferential_p_value)),
  paste0(sum(is.na(progression$inferential_p_value)),"/16")
)
check("OUT_NO_FDR","No FDR calculation executed",TRUE,"YES")
check("OUT_NO_PAIRWISE","No pairwise inferential testing executed",TRUE,"YES")
check("OUT_NO_REFIT","No DESeq2 refit executed",TRUE,"YES")
check("OUT_NO_DISCOVERY","No new target discovery executed",TRUE,"YES")

audit <- do.call(rbind,AUD)
hard_fail <- sum(audit$status=="FAIL" & audit$critical=="YES")
awrite(audit,file.path(OUT,"R4C_STEP2_EXECUTION_AUDIT.csv"))

inp <- do.call(rbind,lapply(names(P),function(nm) data.frame(
  input_id=nm,
  path=P[[nm]],
  bytes=file.info(P[[nm]])$size,
  sha256=sha256(P[[nm]]),
  stringsAsFactors=FALSE
)))
awrite(inp,file.path(OUT,"R4C_STEP2_INPUT_SHA256.csv"))

state <- if(hard_fail==0L) {
  "PASS_R4C_STEP2_DETERMINISTIC_PROGRESSION_EXECUTION_READY_FOR_INDEPENDENT_AUDIT"
} else {
  "HOLD_R4C_STEP2_POSTEXECUTION_GUARD"
}

awrite(data.frame(
  final_state=state,
  run_id=STAMP,
  hard_failures=hard_fail,
  progression_execution_completed="YES",
  program_scores_calculated="YES",
  group_progression_compared="YES_DESCRIPTIVE_MEDIANS_ONLY",
  progression_classes_assigned="YES_FROZEN_SIGN_TAXONOMY",
  inferential_tests_executed="NO",
  multiple_testing_FDR_executed="NO",
  pairwise_inferential_tests_executed="NO",
  DESeq2_refit_executed="NO",
  new_program_discovery="NO",
  thresholds_retuned="NO",
  independent_validation_claim_allowed="NO",
  next_stage=if(hard_fail==0L)
    "CHATGPT_INDEPENDENT_AUDIT_THEN_R4C_STEP3_SOURCE_LEVEL_POSTGEN_VALIDATION_AND_CLOSURE"
  else "STOP_AND_REPAIR_WITHOUT_RETUNING_SCIENCE",
  stringsAsFactors=FALSE
),file.path(OUT,"R4C_STEP2_STATUS.csv"))

cat("FINAL_STATE:",state,"\n")
cat("RUN_ID:",STAMP,"\n")
cat("HARD_FAILURES:",hard_fail,"\n")
cat("PATIENTS:142\n")
cat("PROGRAMS:16\n")
cat("PATIENT_PROGRAM_SCORES:",nrow(scores),"\n")
cat("INFERENTIAL_TESTS_EXECUTED:NO\n")
cat("FDR_EXECUTED:NO\n")
cat("DESEQ2_REFIT:NO\n")
quit(save="no",status=if(hard_fail==0L) 0 else 163,runLast=FALSE)
