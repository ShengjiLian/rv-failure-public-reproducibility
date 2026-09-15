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
# RV Project — R3 Step 3F V1.1
# PROGRAM ANALYSIS TERMINAL FREEZE — FINAL COUNT ATTRIBUTE COMPARISON REPAIR
#
# V1.0 technical HOLD:
#   All scientific identity/class guards passed, but the final class-count
#   guard used identical(obs_counts, exp_counts). obs_counts carried names
#   from vapply() while exp_counts was unnamed, so identical() returned FALSE
#   despite equal integer values 5,2,4,0,5,0.
# V1.1 repair:
#   compare unname(obs_counts) with unname(exp_counts) only.
#   No scientific value, class, threshold, P, FDR, or GSEA result changes.
#
# READ-ONLY terminal closure of:
#   Step3D V1.1 deterministic Hallmark program execution
#   Step3E postgen exact-tie-order robustness validation
#
# NO GSEA rerun.
# NO model refit.
# NO pathway re-selection.
# NO p/FDR recomputation.
# NO class reassignment.
# ==============================================================================

options(stringsAsFactors=FALSE, warn=1)
ROOT <- normalizePath(getwd(),winslash="/",mustWork=TRUE)
if(!identical(tolower(ROOT),tolower(RV_PROJECT_ROOT)))
  stop("Expected D:/RV_project")

R3 <- file.path(ROOT,"results","R3_GSE249696")
LOGD <- file.path(ROOT,"logs")
dir.create(LOGD,recursive=TRUE,showWarnings=FALSE)

D_GATE <- file.path(R3,"R3_STEP3D_V1_1_DETERMINISTIC_PROGRAM_EXECUTION_PASS.txt")
D_R0 <- file.path(R3,"R3_STEP3D_V1_1_R0_HALLMARK_GSEA.csv")
D_R1 <- file.path(R3,"R3_STEP3D_V1_1_R1_HALLMARK_GSEA.csv")
D_ST <- file.path(R3,"R3_STEP3D_V1_1_R0_R1_STABLE_PROGRAMS.csv")
D_MAIN <- file.path(R3,"R3_STEP3D_V1_1_R3_MAIN_STABLE_PROGRAM_GSEA.csv")
D_SAME <- file.path(R3,"R3_STEP3D_V1_1_R3_SAME_SITE_STABLE_PROGRAM_GSEA.csv")
D_CLASS <- file.path(R3,"R3_STEP3D_V1_1_PROGRAM_CLASSIFICATION.csv")
D_SUM <- file.path(R3,"R3_STEP3D_V1_1_PROGRAM_CLASS_SUMMARY.csv")
D_AUD <- file.path(R3,"R3_STEP3D_V1_1_execution_audit.csv")
D_RANK <- file.path(R3,"R3_STEP3D_V1_1_rank_vector_audit.csv")

E_GATE <- file.path(R3,"R3_STEP3E_TIE_ORDER_ROBUSTNESS_PASS.txt")
E_AUD <- file.path(R3,"R3_STEP3E_primary_replay_audit.csv")
E_RUN <- file.path(R3,"R3_STEP3E_tie_sensitivity_runs.csv")
E_PROG <- file.path(R3,"R3_STEP3E_program_tie_robustness.csv")

OUT_AUD <- file.path(R3,"R3_STEP3F_V1_1_terminal_freeze_audit.csv")
OUT_MAN <- file.path(R3,"R3_STEP3F_V1_1_primary_artifact_manifest.csv")
OUT_ID <- file.path(R3,"R3_STEP3F_V1_1_stable_program_identity_class_freeze.csv")
OUT_PASS <- file.path(R3,"R3_STEP3F_V1_1_PROGRAM_ANALYSIS_TERMINAL_FROZEN.txt")
OUT_HOLD <- file.path(R3,"R3_STEP3F_V1_1_PROGRAM_ANALYSIS_TERMINAL_HOLD.txt")
LOG <- file.path(LOGD,"R3_STEP3F_V1_1_PROGRAM_ANALYSIS_TERMINAL_FREEZE.log")

# Immutable Step3F V1.0 technical-HOLD evidence.

if(file.exists(LOG)) {
  old <- file.path(LOGD,paste0(
    "R3_STEP3F_V1_1_PROGRAM_ANALYSIS_TERMINAL_FREEZE_",
    format(Sys.time(),"%Y%m%d_%H%M%S"),"_previous.log"))
  file.rename(LOG,old)
}

logline <- function(...) {
  z <- paste0(format(Sys.time(),"%Y-%m-%d %H:%M:%S")," | ",
              paste0(...,collapse=""))
  cat(z,"\n",sep="")
  cat(z,"\n",file=LOG,append=TRUE,sep="")
  flush.console()
}
replace_file <- function(tmp,dest) {
  if(file.exists(dest)) unlink(dest,force=TRUE)
  if(!file.rename(tmp,dest)) {
    unlink(tmp,force=TRUE); stop("Atomic replace failed: ",dest)
  }
}
awrite <- function(x,p) {
  t <- paste0(p,".tmp_",Sys.getpid())
  write.csv(x,t,row.names=FALSE,na="")
  replace_file(t,p)
}
twrite <- function(x,p) {
  t <- paste0(p,".tmp_",Sys.getpid())
  writeLines(x,t,useBytes=TRUE)
  replace_file(t,p)
}

A <- list()
add <- function(item,expected,observed,status,notes="") {
  A[[length(A)+1L]] <<- data.frame(
    item=as.character(item),
    expected=as.character(expected),
    observed=as.character(observed),
    status=as.character(status),
    notes=as.character(notes),
    stringsAsFactors=FALSE
  )
  logline("[",status,"] ",item,
          " | expected=",expected,
          " | observed=",observed,
          if(nzchar(notes))paste0(" | ",notes) else "")
}
flush_audit <- function() if(length(A)) awrite(do.call(rbind,A),OUT_AUD)

hold <- function(reason,code=281L) {
  flush_audit()
  twrite(c(
    "R3_STEP3F_V1_1_PROGRAM_ANALYSIS_TERMINAL_HOLD",
    paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
    paste0("reason=",reason),
    "GSEA_rerun=NO",
    "model_refit=NO",
    "pvalue_recomputation=NO",
    "FDR_recomputation=NO",
    "class_reassignment=NO",
    "automatic_rerun_allowed=NO"
  ),OUT_HOLD)
  quit(save="no",status=code,runLast=FALSE)
}

options(error=function() {
  msg <- geterrmessage()
  try(flush_audit(),silent=TRUE)
  try(twrite(c(
    "R3_STEP3F_V1_1_PROGRAM_ANALYSIS_TERMINAL_HOLD_RUNTIME_ERROR",
    paste0("error=",gsub("[\r\n]+"," | ",msg)),
    "automatic_rerun_allowed=NO"
  ),OUT_HOLD),silent=TRUE)
  q(save="no",status=282,runLast=FALSE)
})

sha256_file <- function(p) {
  if(!requireNamespace("digest",quietly=TRUE))
    stop("digest unavailable")
  digest::digest(file=p,algo="sha256",serialize=FALSE)
}
parse_kv <- function(p) {
  z <- readLines(p,warn=FALSE,encoding="UTF-8")
  z <- z[nzchar(trimws(z)) & grepl("=",z,fixed=TRUE)]
  out <- sub("^[^=]*=","",z)
  names(out) <- sub("=.*$","",z)
  out
}

logline("============================================================")
logline("R3 Step3F program-analysis terminal freeze")
logline("READ ONLY")
logline("============================================================")

all_inputs <- c(
  D_GATE,D_R0,D_R1,D_ST,D_MAIN,D_SAME,D_CLASS,D_SUM,D_AUD,D_RANK,
  E_GATE,E_AUD,E_RUN,E_PROG
)
for(p in all_inputs) {
  ok <- file.exists(p)
  add(paste0("file_exists:",basename(p)),
      "YES",if(ok)"YES" else "NO",if(ok)"PASS" else "FAIL")
}
if(any(!file.exists(all_inputs))) hold("MISSING_REQUIRED_STEP3D_OR_STEP3E_ARTIFACT",283L)


# Gate identities.
dg <- readLines(D_GATE,warn=FALSE,encoding="UTF-8")
eg <- readLines(E_GATE,warn=FALSE,encoding="UTF-8")
dok <- length(dg)>0L &&
  trimws(dg[1])=="R3_STEP3D_V1_1_DETERMINISTIC_PROGRAM_EXECUTION_PASS"
eok <- length(eg)>0L &&
  trimws(eg[1])=="R3_STEP3E_TIE_ORDER_ROBUSTNESS_PASS"
add("Step3D V1.1 gate identity",
    "R3_STEP3D_V1_1_DETERMINISTIC_PROGRAM_EXECUTION_PASS",
    if(length(dg))trimws(dg[1]) else "<EMPTY>",
    if(dok)"PASS" else "FAIL")
add("Step3E gate identity",
    "R3_STEP3E_TIE_ORDER_ROBUSTNESS_PASS",
    if(length(eg))trimws(eg[1]) else "<EMPTY>",
    if(eok)"PASS" else "FAIL")
if(!(dok&&eok)) hold("GATE_IDENTITY_DRIFT",284L)

# Step3E robustness invariants.
ekv <- parse_kv(E_GATE)
req <- c(
  primary_replay="EXACT",
  alternative_tie_orders="20",
  numeric_rank_jitter="NO",
  stable_family_exact_20_of_20="YES",
  primary16_classification_exact_20_of_20="YES",
  main_NES_sign_exact_20_of_20="YES",
  same_site_NES_sign_exact_20_of_20="YES",
  main_significance_exact_20_of_20="YES",
  tie_order_sensitivity_conclusion="CLEAN_ROBUST",
  upstream_model_refit="NO",
  pathway_collection_changed="NO"
)
for(k in names(req)) {
  obs <- if(k %in% names(ekv))unname(ekv[[k]]) else "<MISSING>"
  exp <- unname(req[[k]])
  add(paste0("Step3E invariant:",k),exp,obs,
      if(identical(obs,exp))"PASS" else "FAIL")
}
if(any(vapply(A,function(x)any(x$status=="FAIL"),logical(1))))
  hold("STEP3E_ROBUSTNESS_INVARIANT_DRIFT",285L)

# Replay audit must be all PASS.
ea <- read.csv(E_AUD,stringsAsFactors=FALSE,check.names=FALSE)
if(!all(c("item","status") %in% names(ea)))
  hold("STEP3E_AUDIT_SCHEMA_DRIFT",286L)
add("Step3E replay audit rows","29",nrow(ea),
    if(nrow(ea)==29L)"PASS" else "FAIL")
add("Step3E replay audit FAIL","0",sum(ea$status=="FAIL",na.rm=TRUE),
    if(sum(ea$status=="FAIL",na.rm=TRUE)==0L)"PASS" else "FAIL")
if(nrow(ea)!=29L || any(ea$status=="FAIL",na.rm=TRUE))
  hold("STEP3E_PRIMARY_REPLAY_NOT_CLEAN",287L)

# 20-run sensitivity must be exact.
er <- read.csv(E_RUN,stringsAsFactors=FALSE,check.names=FALSE)
need_er <- c("sensitivity_run","stable_n","stable_family_exact",
             "primary16_class_exact","class_changed_n",
             "main_NES_sign_changed_n","same_site_NES_sign_changed_n",
             "main_significance_changed_n")
if(length(setdiff(need_er,names(er)))) hold("STEP3E_RUN_SCHEMA_DRIFT",288L)
cond_run <- nrow(er)==20L &&
  all(er$stable_n==16L) &&
  all(as.logical(er$stable_family_exact)) &&
  all(as.logical(er$primary16_class_exact)) &&
  all(er$class_changed_n==0L) &&
  all(er$main_NES_sign_changed_n==0L) &&
  all(er$same_site_NES_sign_changed_n==0L) &&
  all(er$main_significance_changed_n==0L)
add("Step3E 20-run exact robustness","ALL_EXACT",
    if(cond_run)"ALL_EXACT" else "MISMATCH",
    if(cond_run)"PASS" else "FAIL")
if(!cond_run) hold("STEP3E_20_RUN_ROBUSTNESS_DRIFT",289L)

# Load primary classification and stable family.
st <- read.csv(D_ST,stringsAsFactors=FALSE,check.names=FALSE)
cl <- read.csv(D_CLASS,stringsAsFactors=FALSE,check.names=FALSE)
su <- read.csv(D_SUM,stringsAsFactors=FALSE,check.names=FALSE)
ep <- read.csv(E_PROG,stringsAsFactors=FALSE,check.names=FALSE)

add("Step3D stable programs","16",nrow(st),
    if(nrow(st)==16L)"PASS" else "FAIL")
add("Step3D classification rows","16",nrow(cl),
    if(nrow(cl)==16L)"PASS" else "FAIL")
add("Step3E per-program robustness rows","16",nrow(ep),
    if(nrow(ep)==16L)"PASS" else "FAIL")
if(nrow(st)!=16L || nrow(cl)!=16L || nrow(ep)!=16L)
  hold("PRIMARY_16_ROWCOUNT_DRIFT",290L)

expected <- data.frame(
  pathway=c(
    "HALLMARK_ADIPOGENESIS",
    "HALLMARK_ALLOGRAFT_REJECTION",
    "HALLMARK_ANGIOGENESIS",
    "HALLMARK_APICAL_JUNCTION",
    "HALLMARK_COAGULATION",
    "HALLMARK_EPITHELIAL_MESENCHYMAL_TRANSITION",
    "HALLMARK_ESTROGEN_RESPONSE_EARLY",
    "HALLMARK_FATTY_ACID_METABOLISM",
    "HALLMARK_IL2_STAT5_SIGNALING",
    "HALLMARK_IL6_JAK_STAT3_SIGNALING",
    "HALLMARK_INFLAMMATORY_RESPONSE",
    "HALLMARK_INTERFERON_ALPHA_RESPONSE",
    "HALLMARK_INTERFERON_GAMMA_RESPONSE",
    "HALLMARK_MYC_TARGETS_V1",
    "HALLMARK_OXIDATIVE_PHOSPHORYLATION",
    "HALLMARK_TNFA_SIGNALING_VIA_NFKB"
  ),
  program_class=c(
    "PROGRAM_SITE_CONFLICT",
    "PROGRAM_INDETERMINATE_NO_MAIN_SIGNAL",
    "PROGRAM_INDETERMINATE_NO_MAIN_SIGNAL",
    "PROGRAM_REVERSAL_SUPPORTED",
    "PROGRAM_INDETERMINATE_NO_MAIN_SIGNAL",
    "PROGRAM_INDETERMINATE_NO_MAIN_SIGNAL",
    "PROGRAM_REVERSAL_SUPPORTED",
    "PROGRAM_SITE_CONFLICT",
    "PROGRAM_REVERSAL_SUPPORTED",
    "PROGRAM_REVERSAL_SUPPORTED",
    "PROGRAM_INDETERMINATE_NO_MAIN_SIGNAL",
    "PROGRAM_MALADAPTIVE_NONREVERSAL_WORSENING_SUPPORTED",
    "PROGRAM_MALADAPTIVE_NONREVERSAL_WORSENING_SUPPORTED",
    "PROGRAM_SITE_CONFLICT",
    "PROGRAM_SITE_CONFLICT",
    "PROGRAM_REVERSAL_SUPPORTED"
  ),
  stringsAsFactors=FALSE
)

mi <- match(expected$pathway,cl$pathway)
identity_ok <- all(!is.na(mi)) &&
  nrow(cl)==16L &&
  setequal(as.character(cl$pathway),expected$pathway) &&
  identical(as.character(cl$program_class[mi]),expected$program_class)
add("exact stable-program identities/classes","EXACT_16",
    if(identity_ok)"EXACT_16" else "MISMATCH",
    if(identity_ok)"PASS" else "FAIL")
if(!identity_ok) hold("STABLE_PROGRAM_IDENTITY_OR_CLASS_DRIFT",291L)

# Cross-check Step3E robustness identities/classes.
mei <- match(expected$pathway,ep$pathway)
eprog_ok <- all(!is.na(mei)) &&
  all(ep$stable_in_20[mei]==20L) &&
  all(ep$class_matches_primary_20[mei]==20L) &&
  identical(as.character(ep$distinct_classes[mei]),expected$program_class)
add("Step3E per-program exact class robustness","16_X_20_EXACT",
    if(eprog_ok)"16_X_20_EXACT" else "MISMATCH",
    if(eprog_ok)"PASS" else "FAIL")
if(!eprog_ok) hold("PER_PROGRAM_ROBUSTNESS_DRIFT",292L)

# Freeze class counts.
class_levels <- c(
  "PROGRAM_REVERSAL_SUPPORTED",
  "PROGRAM_MALADAPTIVE_NONREVERSAL_WORSENING_SUPPORTED",
  "PROGRAM_SITE_CONFLICT",
  "PROGRAM_MAIN_ONLY_UNRESOLVED",
  "PROGRAM_INDETERMINATE_NO_MAIN_SIGNAL",
  "PROGRAM_UNASSESSABLE"
)
exp_counts <- c(5L,2L,4L,0L,5L,0L)
obs_counts <- vapply(class_levels,function(z)sum(cl$program_class==z),integer(1))
count_ok <- identical(unname(obs_counts),unname(exp_counts))
add("final program class count attribute-repair semantics",
    "COMPARE_INTEGER_VALUES_IGNORE_NAMES_ATTRIBUTE",
    "COMPARE_INTEGER_VALUES_IGNORE_NAMES_ATTRIBUTE",
    "PASS",
    "V1.1 repair only: vapply names are metadata and do not alter the six frozen class counts.")
add("final program class counts",
    paste(exp_counts,collapse=","),
    paste(obs_counts,collapse=","),
    if(count_ok)"PASS" else "FAIL",
    paste(class_levels,collapse=";"))
if(!count_ok) hold("FINAL_CLASS_COUNT_DRIFT",293L)

# Write exact identity/class freeze with primary numeric fields if present.
cols <- intersect(
  c("pathway","failure_direction","NES_R0","R0_BH_FDR","NES_R1","R1_BH_FDR",
    "main_NES","main_pvalue","main_BH_FDR","same_site_NES","same_site_pvalue",
    "same_site_BH_FDR","program_class","interpretation_guard"),
  names(cl)
)
id_freeze <- cl[match(expected$pathway,cl$pathway),cols,drop=FALSE]
awrite(id_freeze,OUT_ID)

# Byte/SHA manifest for immutable primary evidence.
manifest_files <- c(
  D_GATE,D_R0,D_R1,D_ST,D_MAIN,D_SAME,D_CLASS,D_SUM,D_AUD,D_RANK,
  E_GATE,E_AUD,E_RUN,E_PROG
)
man <- data.frame(
  artifact=basename(manifest_files),
  bytes=as.numeric(file.info(manifest_files)$size),
  sha256=vapply(manifest_files,sha256_file,character(1)),
  role=c(
    "STEP3D_PRIMARY_GATE","R0_GSEA","R1_GSEA","STABLE_PROGRAM_FAMILY",
    "R3_MAIN_GSEA","R3_SAME_SITE_GSEA","FINAL_CLASSIFICATION",
    "FINAL_CLASS_SUMMARY","STEP3D_EXECUTION_AUDIT","STEP3D_RANK_AUDIT",
    "STEP3E_ROBUSTNESS_GATE","STEP3E_PRIMARY_REPLAY_AUDIT",
    "STEP3E_20_TIE_ORDER_RUNS","STEP3E_PER_PROGRAM_ROBUSTNESS"
  ),
  stringsAsFactors=FALSE
)
awrite(man,OUT_MAN)
flush_audit()

twrite(c(
  "R3_STEP3F_V1_1_PROGRAM_ANALYSIS_TERMINAL_FROZEN",
  paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
  "Step3F_V1_0_status=TECHNICAL_HOLD",
  "Step3F_V1_0_hold_reason=NAMED_VS_UNNAMED_INTEGER_VECTOR_IDENTICAL_ATTRIBUTE_MISMATCH",
  "Step3F_V1_0_scientific_count_values=5,2,4,0,5,0",
  "Step3F_V1_1_repair_scope=FINAL_COUNT_ATTRIBUTE_COMPARISON_ONLY",
  "scientific_results_changed_by_V1_1=NO",
  "primary_execution=R3_STEP3D_V1_1_DETERMINISTIC_PROGRAM_EXECUTION_PASS",
  "postgen_validation=R3_STEP3E_TIE_ORDER_ROBUSTNESS_PASS",
  "program_analysis_status=FINAL_CLOSED",
  "primary_framework=FULL_RANKED_HALLMARK_GSEA",
  "Hallmark_collection=MSigDB_2026.1.Hs_HALLMARK_50",
  "R0_failure_programs=26",
  "R0_R1_stable_programs=16",
  "PROGRAM_REVERSAL_SUPPORTED=5",
  "PROGRAM_MALADAPTIVE_NONREVERSAL_WORSENING_SUPPORTED=2",
  "PROGRAM_SITE_CONFLICT=4",
  "PROGRAM_MAIN_ONLY_UNRESOLVED=0",
  "PROGRAM_INDETERMINATE_NO_MAIN_SIGNAL=5",
  "PROGRAM_UNASSESSABLE=0",
  "tie_order_primary_replay=EXACT",
  "tie_order_alternative_runs=20",
  "tie_order_stable_family_exact=20_OF_20",
  "tie_order_classification_exact=20_OF_20",
  "tie_order_main_NES_sign_exact=20_OF_20",
  "tie_order_same_site_NES_sign_exact=20_OF_20",
  "tie_order_main_significance_exact=20_OF_20",
  "tie_order_conclusion=CLEAN_ROBUST",
  "same_site_independent_validation=NO",
  "main_site_confound_complete=YES",
  "nonsignificant_main_program_called_persistent=NO",
  "irreversible_wording_allowed=NO",
  "complete_recovery_without_direct_post_vs_healthy_allowed=NO",
  "R2_can_redefine_primary_programs=NO",
  "GSE291508_can_redefine_primary_programs=NO",
  "GSEA_rerun_in_terminal_freeze=NO",
  "model_refit_in_terminal_freeze=NO",
  "pvalue_recomputation_in_terminal_freeze=NO",
  "FDR_recomputation_in_terminal_freeze=NO",
  "class_reassignment_in_terminal_freeze=NO",
  "next_stage=ChatGPT_INDEPENDENT_AUDIT_THEN_PROGRAM_INTERPRETATION_AND_LATER_LOCALIZATION_SUPPORT"
),OUT_PASS)

if(file.exists(OUT_HOLD)) unlink(OUT_HOLD,force=TRUE)
logline("FINAL_GATE: R3_STEP3F_V1_1_PROGRAM_ANALYSIS_TERMINAL_FROZEN")
quit(save="no",status=0,runLast=FALSE)
