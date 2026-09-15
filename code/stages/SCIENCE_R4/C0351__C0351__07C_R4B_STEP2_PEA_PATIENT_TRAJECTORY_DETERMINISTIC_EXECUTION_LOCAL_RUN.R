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
# RV Project — R4B Step2
# Gate9K V1.28 portability repair: current Step1 STATUS/AUDIT semantic binding only; science unchanged.
# PEA PATIENT-LEVEL PROGRAM TRAJECTORY — DETERMINISTIC EXECUTION
#
# FIRST outcome-bearing R4B gate.
# Executes ONLY the descriptive rules frozen in R4B Step1 RUN_ID 20260911_004000.
#
# NO inferential P values.
# NO FDR.
# NO paired test.
# NO binomial concordance test.
# NO responder/non-responder subgrouping.
# NO outcome-based patient reordering.
# NO new program/gene discovery.
#
# Scientific boundary:
#   Same 21 paired GSE249696 patients contributed to Step3F classification.
#   R4B therefore characterizes patient-level heterogeneity/directional consistency
#   and is NOT independent validation.
#   PRE = RV free wall; POST = interventricular septum for all 21 patients, so
#   every trajectory remains completely confounded by anatomical sampling site.
# ==============================================================================

options(stringsAsFactors=FALSE, warn=1)
args <- commandArgs(trailingOnly=TRUE)
STAMP <- if(length(args)>=1 && nzchar(args[1])) args[1] else format(Sys.time(),"%Y%m%d_%H%M%S")

ROOT <- normalizePath(getwd(),winslash="/",mustWork=TRUE)
if(!identical(ROOT,RV_PROJECT_ROOT)) stop("Expected working directory D:/RV_project",call.=FALSE)

OUTROOT <- file.path(ROOT,"results","R4B_PEA_PATIENT_TRAJECTORY_EXECUTION")
OUT <- file.path(OUTROOT,STAMP)
dir.create(OUT,recursive=TRUE,showWarnings=FALSE)

STEP1 <- rv_resolve_stage_run(file.path(ROOT, "results", "R4B_PEA_PATIENT_TRAJECTORY_METHOD_CONTRACT"))
S1_STATUS   <- file.path(STEP1,"R4B_STEP1_STATUS.csv")
S1_CONTRACT <- file.path(STEP1,"R4B_STEP1_TRAJECTORY_METHOD_CONTRACT.csv")
S1_CORE     <- file.path(STEP1,"R4B_STEP1_CORE7_DIRECTION_CONTRACT.csv")
S1_ELIG     <- file.path(STEP1,"R4B_STEP1_PROGRAM_ELIGIBILITY_AUDIT.csv")
S1_AUDIT    <- file.path(STEP1,"R4B_STEP1_METHOD_CONTRACT_AUDIT.csv")

STEP0 <- rv_resolve_stage_run(file.path(ROOT, "results", "R4B_PEA_PATIENT_TRAJECTORY_PREFLIGHT"))
S0_PAIRS <- file.path(STEP0,"R4B_STEP0_PAIR_UNIVERSE.csv")

MAT <- file.path(ROOT,"data","processed","GSE249696","GSE249696_ext395_rnaseq.txt.gz")
GMT <- file.path(ROOT,"data","authority","MSigDB","h.all.v2026.1.Hs.symbols.gmt")

EXPECTED_SHA <- c(
  S1_STATUS   ="5f5fc36eb793e5b2a164fc8113789eb957b98135f6130635859061afc7a47731",
  S1_CONTRACT ="bca6bf28b04c8ce35a41acceaf9f2e5aded339ea104229d7a7318be2fa95414d",
  S1_CORE     ="c3df8e3b87b1d16e7d7c50fbc3f19afbbc4b5936798aeecc9a7cd1fb162739b0",
  S1_ELIG     ="1e466dc56634d05b629b69f22382970323be2dd9f564a5e466ac05c61085b7a6",
  S1_AUDIT    ="8eae80ad51fab02d8208385544ec9a58c8fc959851bbd53cc6d848c1d0da916d",
  S0_PAIRS    ="9ba3899cb48ca6baad62ba34c49dcb54a1593a9dbf70dc233e3c47822e31df57",
  MAT         ="2ac6465ed35a45a8b3b56c30df7e6a0b3dc9469bddd340ad36d92a0eae09a5f2",
  GMT         ="eecaf6dad908334ae885406ec72bdc0646d8917588ed7c219fac92fc5363f596"
)

if(!requireNamespace("digest",quietly=TRUE)) {
  stop("R package 'digest' is required for SHA256 verification",call.=FALSE)
}
sha256 <- function(p) digest::digest(file=p,algo="sha256",serialize=FALSE)

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
  S1_STATUS=S1_STATUS,S1_CONTRACT=S1_CONTRACT,S1_CORE=S1_CORE,
  S1_ELIG=S1_ELIG,S1_AUDIT=S1_AUDIT,S0_PAIRS=S0_PAIRS,MAT=MAT,GMT=GMT
)
for(nm in names(P)) {
  check(paste0("FILE_",nm),paste0(nm," exists"),file.exists(P[[nm]]),P[[nm]])
}
if(any(!vapply(P,file.exists,logical(1)))) {
  awrite(do.call(rbind,AUD),file.path(OUT,"R4B_STEP2_EXECUTION_AUDIT.csv"))
  awrite(data.frame(
    final_state="HOLD_R4B_STEP2_MISSING_INPUT",
    run_id=STAMP,hard_failures=1,
    trajectory_execution_completed="NO",
    inferential_tests_executed="NO",
    stringsAsFactors=FALSE
  ),file.path(OUT,"R4B_STEP2_STATUS.csv"))
  quit(save="no",status=121,runLast=FALSE)
}

for(nm in names(EXPECTED_SHA)) {
  got <- sha256(P[[nm]])
  if(identical(nm,"S1_STATUS")) {
    s1_pre <- read.csv(S1_STATUS,stringsAsFactors=FALSE,check.names=FALSE)
    s1_run_id <- basename(STEP1)
    need <- c("final_state","run_id","hard_failures","patient_program_scores_calculated",
              "pre_post_deltas_calculated","expected_direction_concordance_calculated",
              "program_delta_correlations_calculated","inferential_tests_executed",
              "responder_subgroups_defined","new_program_discovery","thresholds_retuned","next_stage")
    ok <- nrow(s1_pre)==1L && all(need %in% names(s1_pre)) &&
      identical(as.character(s1_pre$final_state[1]),"PASS_R4B_STEP1_TRAJECTORY_METHOD_CONTRACT_READY_FOR_INDEPENDENT_AUDIT") &&
      identical(as.character(s1_pre$run_id[1]),s1_run_id) &&
      identical(as.integer(s1_pre$hard_failures[1]),0L) &&
      identical(as.character(s1_pre$patient_program_scores_calculated[1]),"NO") &&
      identical(as.character(s1_pre$pre_post_deltas_calculated[1]),"NO") &&
      identical(as.character(s1_pre$expected_direction_concordance_calculated[1]),"NO") &&
      identical(as.character(s1_pre$program_delta_correlations_calculated[1]),"NO") &&
      identical(as.character(s1_pre$inferential_tests_executed[1]),"NO") &&
      identical(as.character(s1_pre$responder_subgroups_defined[1]),"NO") &&
      identical(as.character(s1_pre$new_program_discovery[1]),"NO") &&
      identical(as.character(s1_pre$thresholds_retuned[1]),"NO") &&
      identical(as.character(s1_pre$next_stage[1]),"CHATGPT_INDEPENDENT_AUDIT_THEN_R4B_STEP2_DETERMINISTIC_PATIENT_TRAJECTORY_EXECUTION")
    check(paste0("SHA_",nm),"S1_STATUS exact current-run semantic binding",ok,
          if(nrow(s1_pre)) paste(s1_pre$run_id[1],s1_pre$final_state[1],s1_pre$hard_failures[1],sep=" | ") else "NO_ROW")
  } else if(identical(nm,"S1_AUDIT")) {
    s1_audit_pre <- read.csv(S1_AUDIT,stringsAsFactors=FALSE,check.names=FALSE)
    expected_ids <- c("FILE_S0_STATUS","FILE_S0_BOUNDARY","FILE_S0_CORE7","FILE_S0_PAIRS","FILE_S0_MAP","FILE_S0_AUDIT","FILE_MAT","FILE_GMT","SHA_S0_STATUS","SHA_S0_BOUNDARY","SHA_S0_CORE7","SHA_S0_PAIRS","SHA_S0_MAP","SHA_S0_AUDIT","SHA_MAT","SHA_GMT","STEP0_PASS","STEP0_NO_TRAJECTORY","PAIR21","PAIR42","SITE21","CORE7","CORE_CLASS_COUNTS","MAP7","MAP80","MATRIX_ROWS","MATRIX_COLS","GENE_SYMBOL_COLUMN","PAIR_COLUMNS_PRESENT","GMT50","CORE7_GMT","CORE_TARGET_UNIQUE","CORE7_ASSESSABLE","CORE7_USABLE10")
    ok <- nrow(s1_audit_pre)==length(expected_ids) &&
      identical(as.character(s1_audit_pre$guard_id),expected_ids) &&
      all(as.character(s1_audit_pre$critical)=="YES") &&
      all(as.character(s1_audit_pre$status)=="PASS")
    check(paste0("SHA_",nm),"S1_AUDIT exact 34-check current-run all-PASS identity",ok,
          paste0("rows=",nrow(s1_audit_pre),";pass=",sum(s1_audit_pre$status=="PASS")))
  } else {
    check(paste0("SHA_",nm),paste0(nm," exact frozen SHA256"),
          identical(tolower(got),tolower(EXPECTED_SHA[[nm]])),got)
  }
}

s1 <- read.csv(S1_STATUS,stringsAsFactors=FALSE,check.names=FALSE)
check("STEP1_PASS","Accepted R4B Step1 is PASS with zero hard failures",
      nrow(s1)==1L &&
      identical(s1$final_state[1],
                "PASS_R4B_STEP1_TRAJECTORY_METHOD_CONTRACT_READY_FOR_INDEPENDENT_AUDIT") &&
      as.integer(s1$hard_failures[1])==0L,
      if(nrow(s1)) paste(s1$final_state[1],s1$hard_failures[1],sep=" | ") else "NO_ROW")
check("STEP1_NO_OUTCOME","Step1 had no trajectory/outcome-bearing analysis",
      nrow(s1)==1L &&
      identical(s1$patient_program_scores_calculated[1],"NO") &&
      identical(s1$pre_post_deltas_calculated[1],"NO") &&
      identical(s1$expected_direction_concordance_calculated[1],"NO") &&
      identical(s1$program_delta_correlations_calculated[1],"NO") &&
      identical(s1$inferential_tests_executed[1],"NO"),
      if(nrow(s1)) paste(
        s1$patient_program_scores_calculated[1],
        s1$pre_post_deltas_calculated[1],
        s1$expected_direction_concordance_calculated[1],
        s1$program_delta_correlations_calculated[1],
        s1$inferential_tests_executed[1],sep=" | ") else "NO_ROW")

ct <- read.csv(S1_CONTRACT,stringsAsFactors=FALSE,check.names=FALSE)
cv <- setNames(ct$value,ct$item)

must_contract <- c(
  module_role="DESCRIPTIVE_PATIENT_LEVEL_HETEROGENEITY_CHARACTERIZATION",
  pair_universe="21_MATCHED_PRE_POST_PATIENTS",
  site_confounding="YES_COMPLETE_21_OF_21",
  independent_validation_allowed="NO",
  trajectory_target_n="7",
  expression_transform="LOG2_NORMALIZED_COUNT_PLUS_1",
  gene_standardization="GENEWISE_Z_ACROSS_POOLED_42_PRE_POST_SAMPLES_USING_SAMPLE_SD",
  raw_program_score="MEAN_OF_USABLE_MEMBER_GENE_Z_SCORES_PER_SAMPLE",
  failure_oriented_program_score="RAW_SCORE_X_PLUS1_IF_UP_IN_FAILURE_ELSE_MINUS1_IF_DOWN_IN_FAILURE",
  pair_delta="FAILURE_ORIENTED_POST_MINUS_PRE",
  expected_delta_reversal="NEGATIVE",
  expected_delta_worsening="POSITIVE",
  class_aligned_delta="PAIR_DELTA_X_MINUS1_FOR_REVERSAL_ELSE_PLUS1_FOR_WORSENING;POSITIVE_MEANS_CLASS_CONCORDANT",
  zero_delta_tolerance="1e-12",
  program_expected_direction_fraction="EXPECTED_COUNT_DIVIDED_BY_21_NO_NONZERO_DENOMINATOR_SELECTION",
  responder_subgroup_definition="NONE_NO_POSTHOC_RESPONDER_NONRESPONDER_CLASSIFICATION",
  program_delta_correlation="SPEARMAN_CORRELATION_MATRIX_OF_CLASS_ALIGNED_PROGRAM_DELTAS_ACROSS_21_PATIENTS",
  program_delta_correlation_pvalues="NO",
  paired_inferential_test="NO",
  binomial_concordance_test="NO",
  multiple_testing_FDR="NONE_DESCRIPTIVE_MODULE",
  patient_display_order="ASCENDING_PATIENT_NUMBER",
  outcome_based_patient_reordering="NO",
  new_program_discovery="NO",
  new_gene_discovery="NO",
  threshold_retuning_after_results="NO"
)
for(k in names(must_contract)) {
  check(paste0("CONTRACT_",k),paste0(k," frozen exact"),
        !is.null(cv[[k]]) && identical(as.character(cv[[k]]),as.character(must_contract[[k]])),
        if(!is.null(cv[[k]])) cv[[k]] else "MISSING")
}

pairs <- read.csv(S0_PAIRS,stringsAsFactors=FALSE,check.names=FALSE)
core  <- read.csv(S1_CORE,stringsAsFactors=FALSE,check.names=FALSE)
elig  <- read.csv(S1_ELIG,stringsAsFactors=FALSE,check.names=FALSE)

check("PAIR21","Execution universe remains 21 unique patients",
      nrow(pairs)==21L && length(unique(pairs$patient_id))==21L,nrow(pairs))
check("PAIR42","Execution universe remains 42 unique biological samples",
      length(unique(c(pairs$BL_matrix_column,pairs$FU_matrix_column)))==42L,
      length(unique(c(pairs$BL_matrix_column,pairs$FU_matrix_column))))
check("SITE21","All 21 pairs remain RV free wall -> interventricular septum",
      all(pairs$BL_site=="RV_FREE_WALL" &
          pairs$FU_site=="INTERVENTRICULAR_SEPTUM" &
          as.logical(pairs$site_changed)),
      paste0(sum(pairs$BL_site=="RV_FREE_WALL" &
                 pairs$FU_site=="INTERVENTRICULAR_SEPTUM" &
                 as.logical(pairs$site_changed)),"/21"))
check("CORE7","Core7 direction contract contains exactly 7 programs",
      nrow(core)==7L && length(unique(core$pathway))==7L,nrow(core))
check("ELIG7","All seven programs were pre-outcome assessable",
      nrow(elig)==7L && all(elig$assessable),
      paste0(sum(elig$assessable),"/7"))

# Fail closed before any PRE/POST score is calculated.
pre_audit <- do.call(rbind,AUD)
hard_pre <- sum(pre_audit$status=="FAIL" & pre_audit$critical=="YES")
if(hard_pre>0L) {
  awrite(pre_audit,file.path(OUT,"R4B_STEP2_EXECUTION_AUDIT.csv"))
  awrite(data.frame(
    final_state="HOLD_R4B_STEP2_PREEXECUTION",
    run_id=STAMP,hard_failures=hard_pre,
    trajectory_execution_completed="NO",
    inferential_tests_executed="NO",
    stringsAsFactors=FALSE
  ),file.path(OUT,"R4B_STEP2_STATUS.csv"))
  quit(save="no",status=122,runLast=FALSE)
}

# ==============================================================================
# OUTCOME-BEARING DESCRIPTIVE EXECUTION STARTS HERE.
# ==============================================================================

mat <- read.delim(gzfile(MAT,"rt"),stringsAsFactors=FALSE,check.names=FALSE,
                  quote="",comment.char="")
symbols <- trimws(as.character(mat[["Ensembl gene"]]))

# Fixed sample order: PRE 21 followed by POST 21, patients already ascending.
sample_cols <- c(pairs$BL_matrix_column,pairs$FU_matrix_column)
check("MATRIX42_PRESENT","All 42 frozen sample columns present uniquely",
      length(sample_cols)==42L && length(unique(sample_cols))==42L &&
      all(sample_cols %in% names(mat)),
      paste0(sum(sample_cols %in% names(mat)),"/42"))

X <- as.matrix(mat[,sample_cols,drop=FALSE])
storage.mode(X) <- "double"
Y <- log2(X+1)

row_mu <- rowMeans(Y)
row_sd <- apply(Y,1,sd)
finite42 <- apply(Y,1,function(v) all(is.finite(v)))
eligible42 <- finite42 & is.finite(row_sd) & row_sd>0
Z <- (Y-row_mu)/row_sd

gl <- readLines(GMT,warn=FALSE)
parts <- strsplit(gl,"\t",fixed=TRUE)
gmt_names <- vapply(parts,`[`,character(1),1L)
gmt_genes <- lapply(parts,function(x)
  unique(if(length(x)>=3L) x[3:length(x)] else character()))
names(gmt_genes) <- gmt_names

# Reconstruct exactly seven program sample scores.
score_rows <- list()
delta_rows <- list()
summary_rows <- list()
tol <- 1e-12

for(i in seq_len(nrow(core))) {
  pid <- core$pathway[i]
  members <- gmt_genes[[pid]]
  idx <- match(members,symbols)
  idx <- idx[!is.na(idx)]
  idx <- idx[eligible42[idx]]

  check(paste0("USABLE_",i),
        paste0(pid," usable genes match pre-outcome frozen eligibility"),
        length(idx)==elig$usable_gene_n[match(pid,elig$pathway)],
        paste0(length(idx),"/",elig$usable_gene_n[match(pid,elig$pathway)]))

  raw <- colMeans(Z[idx,,drop=FALSE])
  fail_mult <- if(core$failure_direction[i]=="UP_IN_FAILURE") 1 else
               if(core$failure_direction[i]=="DOWN_IN_FAILURE") -1 else NA_real_
  if(!is.finite(fail_mult)) stop("Unexpected failure direction for ",pid,call.=FALSE)

  fo <- raw*fail_mult
  pre_raw <- raw[seq_len(21)]
  post_raw <- raw[21+seq_len(21)]
  pre_fo <- fo[seq_len(21)]
  post_fo <- fo[21+seq_len(21)]

  delta <- post_fo-pre_fo
  align_mult <- core$class_alignment_multiplier[i]
  class_delta <- delta*align_mult

  expected <- class_delta > tol
  unexpected <- class_delta < -tol
  tie <- abs(class_delta)<=tol

  for(j in seq_len(21)) {
    score_rows[[length(score_rows)+1L]] <- data.frame(
      patient_id=pairs$patient_id[j],
      patient_number=as.integer(sub("^Pat-","",pairs$patient_id[j])),
      baseline_risk=pairs$baseline_risk[j],
      sex=pairs$sex[j],
      pathway=pid,
      program_class=core$program_class[i],
      failure_direction=core$failure_direction[i],
      timepoint="PRE",
      tissue="RV_FREE_WALL",
      matrix_column=pairs$BL_matrix_column[j],
      usable_gene_n=length(idx),
      raw_program_score=pre_raw[j],
      failure_oriented_program_score=pre_fo[j],
      stringsAsFactors=FALSE
    )
    score_rows[[length(score_rows)+1L]] <- data.frame(
      patient_id=pairs$patient_id[j],
      patient_number=as.integer(sub("^Pat-","",pairs$patient_id[j])),
      baseline_risk=pairs$baseline_risk[j],
      sex=pairs$sex[j],
      pathway=pid,
      program_class=core$program_class[i],
      failure_direction=core$failure_direction[i],
      timepoint="POST",
      tissue="INTERVENTRICULAR_SEPTUM",
      matrix_column=pairs$FU_matrix_column[j],
      usable_gene_n=length(idx),
      raw_program_score=post_raw[j],
      failure_oriented_program_score=post_fo[j],
      stringsAsFactors=FALSE
    )

    delta_rows[[length(delta_rows)+1L]] <- data.frame(
      patient_id=pairs$patient_id[j],
      patient_number=as.integer(sub("^Pat-","",pairs$patient_id[j])),
      baseline_risk=pairs$baseline_risk[j],
      sex=pairs$sex[j],
      pathway=pid,
      program_class=core$program_class[i],
      failure_direction=core$failure_direction[i],
      class_alignment_multiplier=align_mult,
      PRE_raw_program_score=pre_raw[j],
      POST_raw_program_score=post_raw[j],
      PRE_failure_oriented_score=pre_fo[j],
      POST_failure_oriented_score=post_fo[j],
      failure_oriented_delta_POST_minus_PRE=delta[j],
      class_aligned_delta=class_delta[j],
      trajectory_direction=if(expected[j]) "CLASS_CONCORDANT" else
                           if(unexpected[j]) "CLASS_DISCORDANT" else "TIE_WITHIN_1E-12",
      stringsAsFactors=FALSE
    )
  }

  summary_rows[[i]] <- data.frame(
    pathway=pid,
    program_class=core$program_class[i],
    failure_direction=core$failure_direction[i],
    expected_failure_oriented_delta=if(core$program_class[i]=="PROGRAM_REVERSAL_SUPPORTED")
      "NEGATIVE" else "POSITIVE",
    n_patients=21L,
    expected_direction_n=sum(expected),
    expected_direction_fraction=sum(expected)/21,
    discordant_direction_n=sum(unexpected),
    tie_n=sum(tie),
    failure_oriented_delta_mean=mean(delta),
    failure_oriented_delta_sd=sd(delta),
    failure_oriented_delta_median=median(delta),
    failure_oriented_delta_q25=unname(quantile(delta,0.25,type=7)),
    failure_oriented_delta_q75=unname(quantile(delta,0.75,type=7)),
    failure_oriented_delta_min=min(delta),
    failure_oriented_delta_max=max(delta),
    class_aligned_delta_mean=mean(class_delta),
    class_aligned_delta_sd=sd(class_delta),
    class_aligned_delta_median=median(class_delta),
    class_aligned_delta_q25=unname(quantile(class_delta,0.25,type=7)),
    class_aligned_delta_q75=unname(quantile(class_delta,0.75,type=7)),
    class_aligned_delta_min=min(class_delta),
    class_aligned_delta_max=max(class_delta),
    inferential_p_value=NA_real_,
    interpretation_role="DESCRIPTIVE_ONLY_NOT_INDEPENDENT_VALIDATION",
    stringsAsFactors=FALSE
  )
}

scores <- do.call(rbind,score_rows)
deltas <- do.call(rbind,delta_rows)
program_summary <- do.call(rbind,summary_rows)

# Patient-level concordance counts, fixed patient-number order.
patient_rows <- list()
for(j in seq_len(nrow(pairs))) {
  z <- deltas[deltas$patient_id==pairs$patient_id[j],,drop=FALSE]
  rev <- z$program_class=="PROGRAM_REVERSAL_SUPPORTED"
  wor <- z$program_class=="PROGRAM_MALADAPTIVE_NONREVERSAL_WORSENING_SUPPORTED"
  patient_rows[[j]] <- data.frame(
    patient_id=pairs$patient_id[j],
    patient_number=as.integer(sub("^Pat-","",pairs$patient_id[j])),
    baseline_risk=pairs$baseline_risk[j],
    sex=pairs$sex[j],
    core7_concordant_n=sum(z$class_aligned_delta>tol),
    core7_discordant_n=sum(z$class_aligned_delta< -tol),
    core7_tie_n=sum(abs(z$class_aligned_delta)<=tol),
    reversal5_concordant_n=sum(z$class_aligned_delta[rev]>tol),
    reversal5_discordant_n=sum(z$class_aligned_delta[rev]< -tol),
    worsening2_concordant_n=sum(z$class_aligned_delta[wor]>tol),
    worsening2_discordant_n=sum(z$class_aligned_delta[wor]< -tol),
    responder_subgroup="NOT_DEFINED_BY_CONTRACT",
    stringsAsFactors=FALSE
  )
}
patient_summary <- do.call(rbind,patient_rows)
patient_summary <- patient_summary[order(patient_summary$patient_number),,drop=FALSE]

# 7x7 Spearman correlation matrix of class-aligned deltas, no p values.
wide <- reshape(
  deltas[,c("patient_id","pathway","class_aligned_delta")],
  idvar="patient_id",timevar="pathway",direction="wide"
)
wide <- wide[match(pairs$patient_id,wide$patient_id),,drop=FALSE]
delta_cols <- paste0("class_aligned_delta.",core$pathway)
C <- cor(wide[,delta_cols,drop=FALSE],method="spearman",use="pairwise.complete.obs")
rownames(C) <- core$pathway
colnames(C) <- core$pathway

cor_rows <- list()
k <- 0L
for(a in seq_len(nrow(C))) {
  for(b in seq_len(ncol(C))) {
    k <- k+1L
    cor_rows[[k]] <- data.frame(
      pathway_1=rownames(C)[a],
      pathway_2=colnames(C)[b],
      spearman_rho=unname(C[a,b]),
      n_patients=21L,
      p_value=NA_real_,
      interpretation_role="DESCRIPTIVE_CORRELATION_NO_INFERENCE",
      stringsAsFactors=FALSE
    )
  }
}
cor_long <- do.call(rbind,cor_rows)

# Compact headline summaries; descriptive only.
role_summary <- data.frame(
  program_class=c("PROGRAM_REVERSAL_SUPPORTED",
                  "PROGRAM_MALADAPTIVE_NONREVERSAL_WORSENING_SUPPORTED"),
  program_n=c(5L,2L),
  patient_program_opportunities=c(21L*5L,21L*2L),
  class_concordant_n=c(
    sum(deltas$class_aligned_delta[deltas$program_class=="PROGRAM_REVERSAL_SUPPORTED"]>tol),
    sum(deltas$class_aligned_delta[deltas$program_class=="PROGRAM_MALADAPTIVE_NONREVERSAL_WORSENING_SUPPORTED"]>tol)
  ),
  class_discordant_n=c(
    sum(deltas$class_aligned_delta[deltas$program_class=="PROGRAM_REVERSAL_SUPPORTED"]< -tol),
    sum(deltas$class_aligned_delta[deltas$program_class=="PROGRAM_MALADAPTIVE_NONREVERSAL_WORSENING_SUPPORTED"]< -tol)
  ),
  stringsAsFactors=FALSE
)
role_summary$class_concordant_fraction <- role_summary$class_concordant_n /
                                          role_summary$patient_program_opportunities

overall <- data.frame(
  metric=c(
    "patients","programs","patient_program_pairs",
    "reversal_programs","worsening_programs",
    "total_class_concordant_patient_program_pairs",
    "total_class_discordant_patient_program_pairs",
    "patients_with_7_of_7_concordant",
    "patients_with_at_least_6_of_7_concordant",
    "patients_with_at_least_5_of_7_concordant",
    "patients_with_both_worsening_programs_concordant",
    "patients_with_all_5_reversal_programs_concordant",
    "inferential_tests",
    "FDR",
    "independent_validation",
    "site_confounding"
  ),
  value=c(
    21,7,147,5,2,
    sum(deltas$class_aligned_delta>tol),
    sum(deltas$class_aligned_delta< -tol),
    sum(patient_summary$core7_concordant_n==7L),
    sum(patient_summary$core7_concordant_n>=6L),
    sum(patient_summary$core7_concordant_n>=5L),
    sum(patient_summary$worsening2_concordant_n==2L),
    sum(patient_summary$reversal5_concordant_n==5L),
    "NONE",
    "NONE",
    "NO",
    "YES_COMPLETE_PRE_RV_FREE_WALL_POST_SEPTUM"
  ),
  stringsAsFactors=FALSE
)

# Write numerical authorities.
awrite(scores,file.path(OUT,"R4B_STEP2_PATIENT_PROGRAM_SCORES.csv"))
awrite(deltas,file.path(OUT,"R4B_STEP2_PATIENT_PROGRAM_DELTAS.csv"))
awrite(program_summary,file.path(OUT,"R4B_STEP2_PROGRAM_DIRECTIONAL_SUMMARY.csv"))
awrite(patient_summary,file.path(OUT,"R4B_STEP2_PATIENT_CONCORDANCE_SUMMARY.csv"))
awrite(cor_long,file.path(OUT,"R4B_STEP2_CLASS_ALIGNED_DELTA_CORRELATION.csv"))
awrite(role_summary,file.path(OUT,"R4B_STEP2_CLASS_DIRECTIONAL_SUMMARY.csv"))
awrite(overall,file.path(OUT,"R4B_STEP2_OVERALL_SUMMARY.csv"))

# ------------------------------------------------------------------------------
# Deterministic draft figures. Tables above are numerical authority.
# ------------------------------------------------------------------------------

short_name <- function(x) sub("^HALLMARK_","",x)

# Fig A: patient PRE->POST trajectories for all seven programs.
png(file.path(OUT,"R4B_STEP2_FigA_patient_PRE_POST_trajectories.png"),
    width=2200,height=1900,res=180)
op <- par(mfrow=c(3,3),mar=c(4.5,4.5,3,1))
for(pid in core$pathway) {
  d <- scores[scores$pathway==pid,,drop=FALSE]
  pre <- d$failure_oriented_program_score[d$timepoint=="PRE"]
  post <- d$failure_oriented_program_score[d$timepoint=="POST"]
  pids_pre <- d$patient_id[d$timepoint=="PRE"]
  pids_post <- d$patient_id[d$timepoint=="POST"]
  pre <- pre[match(pairs$patient_id,pids_pre)]
  post <- post[match(pairs$patient_id,pids_post)]
  ylim <- range(c(pre,post),finite=TRUE)
  plot(c(1,2),range(ylim),type="n",xaxt="n",xlab="",ylab="Failure-oriented program score",
       main=short_name(pid),xlim=c(0.8,2.2))
  axis(1,at=c(1,2),labels=c("PRE\nRV free wall","POST\nseptum"))
  for(j in seq_len(21)) lines(c(1,2),c(pre[j],post[j]),lwd=1)
  points(rep(1,21),pre,pch=16,cex=0.45)
  points(rep(2,21),post,pch=16,cex=0.45)
}
plot.new()
text(0.5,0.66,"R4B patient-level PEA trajectories",cex=1.05)
text(0.5,0.50,"n=21 paired patients",cex=0.9)
text(0.5,0.38,"PRE RV free wall → POST septum",cex=0.9)
text(0.5,0.26,"complete sampling-site confounding",cex=0.9)
plot.new()
par(op); dev.off()

# Fig B: expected-direction fractions, fixed core7 order.
png(file.path(OUT,"R4B_STEP2_FigB_expected_direction_fraction.png"),
    width=1700,height=1150,res=180)
op <- par(mar=c(5,12,3,2))
ps <- program_summary
y <- seq_len(nrow(ps))
plot(ps$expected_direction_fraction,y,pch=19,xlim=c(0,1),
     yaxt="n",xlab="Fraction of 21 patients changing in frozen class-concordant direction",
     ylab="",main="Directional consistency across individual PEA trajectories")
axis(2,at=y,labels=short_name(ps$pathway),las=2,cex.axis=0.78)
abline(v=0.5,lty=2)
text(ps$expected_direction_fraction,y,
     labels=paste0(ps$expected_direction_n,"/21"),pos=4,cex=0.78,xpd=NA)
mtext("Descriptive only; no binomial test or FDR",side=1,line=3.2,cex=0.75)
par(op); dev.off()

# Fig C: 21x7 class-aligned delta heatmap, fixed patient-number order.
D <- reshape(
  deltas[,c("patient_id","pathway","class_aligned_delta")],
  idvar="patient_id",timevar="pathway",direction="wide"
)
D <- D[match(pairs$patient_id,D$patient_id),,drop=FALSE]
M <- as.matrix(D[,paste0("class_aligned_delta.",core$pathway),drop=FALSE])
rownames(M) <- D$patient_id
colnames(M) <- short_name(core$pathway)
lim <- max(abs(M),na.rm=TRUE)
if(!is.finite(lim) || lim==0) lim <- 1
png(file.path(OUT,"R4B_STEP2_FigC_patient_program_delta_heatmap.png"),
    width=1900,height=1500,res=180)
op <- par(mar=c(12,7,3,4))
pal <- colorRampPalette(c("navy","white","firebrick3"))(101)
image(x=seq_len(ncol(M)),y=seq_len(nrow(M)),
      z=t(M[nrow(M):1,,drop=FALSE]),axes=FALSE,
      xlab="",ylab="",col=pal,zlim=c(-lim,lim),
      main="Class-aligned patient-level program deltas")
axis(1,at=seq_len(ncol(M)),labels=colnames(M),las=2,cex.axis=0.72)
axis(2,at=seq_len(nrow(M)),labels=rev(rownames(M)),las=2,cex.axis=0.72)
mtext("Positive = concordant with frozen Step3F class; patients fixed by patient number",
      side=1,line=10.2,cex=0.72)
par(op); dev.off()

# Fig D: descriptive Spearman correlation of class-aligned deltas.
png(file.path(OUT,"R4B_STEP2_FigD_class_aligned_delta_correlation.png"),
    width=1500,height=1400,res=180)
op <- par(mar=c(11,11,3,3))
limc <- 1
pal <- colorRampPalette(c("navy","white","firebrick3"))(101)
image(x=seq_len(ncol(C)),y=seq_len(nrow(C)),
      z=t(C[nrow(C):1,,drop=FALSE]),axes=FALSE,xlab="",ylab="",
      col=pal,zlim=c(-limc,limc),
      main="Spearman correlation of class-aligned program deltas")
axis(1,at=seq_len(ncol(C)),labels=short_name(colnames(C)),las=2,cex.axis=0.68)
axis(2,at=seq_len(nrow(C)),labels=rev(short_name(rownames(C))),las=2,cex.axis=0.68)
for(a in seq_len(nrow(C))) for(b in seq_len(ncol(C))) {
  text(b,nrow(C)-a+1,sprintf("%.2f",C[a,b]),cex=0.58)
}
mtext("Descriptive correlation only; no correlation P values",
      side=1,line=9.4,cex=0.72)
par(op); dev.off()

# Fig E: patient-level concordance counts, patient-number order.
png(file.path(OUT,"R4B_STEP2_FigE_patient_concordance_counts.png"),
    width=1850,height=1050,res=180)
op <- par(mar=c(7,5,3,2))
x <- seq_len(nrow(patient_summary))
plot(x,patient_summary$core7_concordant_n,type="b",pch=16,ylim=c(0,7),
     xaxt="n",xlab="",ylab="Class-concordant programs (of 7)",
     main="Within-patient directional consistency across the frozen core7")
axis(1,at=x,labels=patient_summary$patient_id,las=2,cex.axis=0.72)
abline(h=c(5,6,7),lty=3)
mtext("Patients fixed by ascending patient number; no responder subgroup is defined",
      side=1,line=5.2,cex=0.72)
par(op); dev.off()

# Output guards.
check("OUT_SCORES","Patient program score table has 21x7x2 rows",
      nrow(scores)==21L*7L*2L,nrow(scores))
check("OUT_DELTAS","Patient program delta table has 21x7 rows",
      nrow(deltas)==21L*7L,nrow(deltas))
check("OUT_PROGRAM7","Program directional summary has 7 rows",
      nrow(program_summary)==7L,nrow(program_summary))
check("OUT_PATIENT21","Patient concordance summary has 21 rows",
      nrow(patient_summary)==21L,nrow(patient_summary))
check("OUT_COR49","Delta correlation table has 7x7 rows",
      nrow(cor_long)==49L,nrow(cor_long))
check("OUT_PATIENT_ORDER","Patient output order is ascending patient number",
      identical(patient_summary$patient_number,sort(patient_summary$patient_number)),
      paste(patient_summary$patient_number,collapse=";"))
check("OUT_NO_PAIRED_TEST","No paired inferential test executed",TRUE,"YES")
check("OUT_NO_BINOMIAL_TEST","No binomial concordance test executed",TRUE,"YES")
check("OUT_NO_FDR","No multiple-testing FDR executed",TRUE,"YES")
check("OUT_NO_RESPONDER","No responder/non-responder subgroup defined",
      all(patient_summary$responder_subgroup=="NOT_DEFINED_BY_CONTRACT"),"YES")
check("OUT_NO_DISCOVERY","No new target discovery executed",TRUE,"YES")
check("OUT_SITE_CONFOUND","Complete PRE/POST site confounding retained in outputs",
      all(deltas$program_class %in% core$program_class) &&
      all(pairs$BL_site=="RV_FREE_WALL") &&
      all(pairs$FU_site=="INTERVENTRICULAR_SEPTUM"),
      "21/21")

audit <- do.call(rbind,AUD)
hard_fail <- sum(audit$status=="FAIL" & audit$critical=="YES")
awrite(audit,file.path(OUT,"R4B_STEP2_EXECUTION_AUDIT.csv"))

inp <- do.call(rbind,lapply(names(P),function(nm) data.frame(
  input_id=nm,path=P[[nm]],bytes=file.info(P[[nm]])$size,
  sha256=sha256(P[[nm]]),stringsAsFactors=FALSE
)))
awrite(inp,file.path(OUT,"R4B_STEP2_INPUT_SHA256.csv"))

state <- if(hard_fail==0L) {
  "PASS_R4B_STEP2_DETERMINISTIC_PATIENT_TRAJECTORY_EXECUTION_READY_FOR_INDEPENDENT_AUDIT"
} else {
  "HOLD_R4B_STEP2_POSTEXECUTION_GUARD"
}

awrite(data.frame(
  final_state=state,
  run_id=STAMP,
  hard_failures=hard_fail,
  trajectory_execution_completed="YES",
  patient_program_scores_calculated="YES",
  pre_post_deltas_calculated="YES",
  expected_direction_concordance_calculated="YES",
  program_delta_correlations_calculated="YES_DESCRIPTIVE_NO_PVALUES",
  paired_inferential_tests_executed="NO",
  binomial_concordance_tests_executed="NO",
  multiple_testing_FDR_executed="NO",
  responder_subgroups_defined="NO",
  new_program_discovery="NO",
  thresholds_retuned="NO",
  independent_validation_claim_allowed="NO",
  site_confounding="YES_COMPLETE_21_OF_21",
  next_stage=if(hard_fail==0L)
    "CHATGPT_INDEPENDENT_AUDIT_THEN_R4B_STEP3_SOURCE_LEVEL_POSTGEN_VALIDATION_AND_CLOSURE"
  else "STOP_AND_REPAIR_WITHOUT_RETUNING_SCIENCE",
  stringsAsFactors=FALSE
),file.path(OUT,"R4B_STEP2_STATUS.csv"))

cat("FINAL_STATE:",state,"\n")
cat("RUN_ID:",STAMP,"\n")
cat("HARD_FAILURES:",hard_fail,"\n")
cat("PATIENTS:21\n")
cat("PROGRAMS:7\n")
cat("PATIENT_PROGRAM_DELTAS:147\n")
cat("INFERENTIAL_TESTS_EXECUTED:NO\n")
cat("FDR_EXECUTED:NO\n")
cat("SITE_CONFOUNDING:YES_COMPLETE_21_OF_21\n")
quit(save="no",status=if(hard_fail==0L) 0 else 123,runLast=FALSE)
