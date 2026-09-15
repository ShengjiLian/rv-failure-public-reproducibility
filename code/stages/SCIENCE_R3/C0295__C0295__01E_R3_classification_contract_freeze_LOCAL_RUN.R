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
# RV Project — R3 Step 1E (robust repair)
# CLASSIFICATION CONTRACT FREEZE — CONTRACT ONLY
#
# Repair scope:
#   - no scientific rule changes
#   - no gene classification
#   - no statistical recomputation
#   - replaces brittle stop()-only preconditions with explicit auditable checks
#   - logs every frozen-input check before freezing the contract
# ==============================================================================

options(stringsAsFactors=FALSE, warn=1)

ROOT <- normalizePath(getwd(), winslash="/", mustWork=TRUE)

RES <- file.path(ROOT,"results","R3_GSE249696")
LOGD <- file.path(ROOT,"logs")
dir.create(RES,recursive=TRUE,showWarnings=FALSE)
dir.create(LOGD,recursive=TRUE,showWarnings=FALSE)

F1B <- file.path(RES,"R3_STEP1B_FIG5_SOURCE_AUTHORITY_FROZEN.txt")
P1B <- file.path(RES,"R3_STEP1B_PRIMARY25_author_unloading_stats.csv")
F1D <- file.path(RES,"R3_STEP1D_FIG4_ED4_SOURCE_AUTHORITY_FROZEN.txt")
P1D <- file.path(RES,"R3_STEP1D_PRIMARY25_FIG4_ED4_author_stats.csv")

OUT_AUD <- file.path(RES,"R3_STEP1E_contract_input_audit.csv")
OUT_RULES <- file.path(RES,"R3_STEP1E_core_gene_classification_rules.csv")
OUT_AUTH <- file.path(RES,"R3_STEP1E_authority_roles.csv")
OUT_TXT <- file.path(RES,"R3_STEP1E_CLASSIFICATION_CONTRACT_FROZEN.txt")
HOLD <- file.path(RES,"R3_STEP1E_CLASSIFICATION_CONTRACT_HOLD.txt")
LOG <- file.path(LOGD,"R3_STEP1E_CLASSIFICATION_CONTRACT.log")

PRIMARY25 <- c(
  "LIPG","COMP","ALOX5","SPP1","GRIN2B","SLCO2A1","SP140","DNAH7",
  "JAK3","CSMD1","BIN2","VDR","IL21R","GMIP","SMAD7","ABCC3","KYNU",
  "PLSCR1","CP","SLC6A6","STXBP2","MYO1F","MPC2","CD163","CD72"
)

if(file.exists(LOG)) {
  old <- file.path(
    LOGD,
    paste0("R3_STEP1E_CLASSIFICATION_CONTRACT_",
           format(Sys.time(),"%Y%m%d_%H%M%S"),"_previous.log")
  )
  file.rename(LOG,old)
}

logline <- function(...) {
  z <- paste0(format(Sys.time(),"%Y-%m-%d %H:%M:%S")," | ",
              paste0(...,collapse=""))
  cat(z,"\n",sep="")
  cat(z,"\n",file=LOG,append=TRUE,sep="")
  flush.console()
}
awrite <- function(x,p) {
  t <- paste0(p,".tmp_",Sys.getpid())
  write.csv(x,t,row.names=FALSE,na="")
  if(file.exists(p)) unlink(p,force=TRUE)
  if(!file.rename(t,p)) { unlink(t); stop("Atomic CSV failed: ",p) }
}
twrite <- function(x,p) {
  t <- paste0(p,".tmp_",Sys.getpid())
  writeLines(x,t,useBytes=TRUE)
  if(file.exists(p)) unlink(p,force=TRUE)
  if(!file.rename(t,p)) { unlink(t); stop("Atomic text failed: ",p) }
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
          if(nzchar(notes)) paste0(" | ",notes) else "")
}

freeze_hold <- function(reason, code=152L) {
  aud <- if(length(A)) do.call(rbind,A) else data.frame()
  if(nrow(aud)) awrite(aud,OUT_AUD)
  twrite(c(
    "R3_STEP1E_CLASSIFICATION_CONTRACT_HOLD",
    paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
    paste0("reason=",reason),
    "scientific_contract_changed=NO",
    "classification_executed=NO",
    "inferential_statistical_recomputation=NO",
    paste0("log=",LOG)
  ),HOLD)
  logline("FINAL_GATE: R3_STEP1E_CLASSIFICATION_CONTRACT_HOLD | ",reason)
  quit(save="no",status=code,runLast=FALSE)
}

logline("============================================================")
logline("R3 Step1E — classification contract freeze (robust repair)")
logline("CONTRACT ONLY. NO gene classification.")
logline("============================================================")

# Catch any unexpected runtime error and preserve the error message.
options(error=function() {
  msg <- geterrmessage()
  try(logline("[UNHANDLED_R_ERROR] ",gsub("[\r\n]+"," | ",msg)),silent=TRUE)
  try(twrite(c(
    "R3_STEP1E_CLASSIFICATION_CONTRACT_HOLD_RUNTIME_ERROR",
    paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
    paste0("error=",gsub("[\r\n]+"," | ",msg)),
    "classification_executed=NO",
    "inferential_statistical_recomputation=NO"
  ),HOLD),silent=TRUE)
  q(save="no",status=153,runLast=FALSE)
})

add("project_root",RV_PROJECT_ROOT,ROOT,
    if(identical(tolower(ROOT),tolower(RV_PROJECT_ROOT))) "PASS" else "FAIL")

files_needed <- c(F1B,P1B,F1D,P1D)
for(p in files_needed) {
  add(paste0("file_exists:",basename(p)),"YES",
      if(file.exists(p)) "YES" else "NO",
      if(file.exists(p)) "PASS" else "FAIL")
}

if(any(vapply(A,function(x) any(x$status=="FAIL"),logical(1))))
  freeze_hold("MISSING_OR_WRONG_ROOT",154L)

# Parse frozen text contracts as exact key=value records.
parse_kv <- function(path) {
  z <- readLines(path,warn=FALSE,encoding="UTF-8")
  z <- z[nzchar(trimws(z))]
  kv <- z[grepl("=",z,fixed=TRUE)]
  keys <- sub("=.*$","",kv)
  vals <- sub("^[^=]*=","",kv)
  out <- vals
  names(out) <- keys
  out
}

kv1b <- parse_kv(F1B)
kv1d <- parse_kv(F1D)

check_kv <- function(kv,key,expected,label) {
  obs <- if(key %in% names(kv)) unname(kv[[key]]) else "<MISSING_KEY>"
  add(label,expected,obs,if(identical(obs,expected)) "PASS" else "FAIL")
}

check_kv(kv1b,"overall_n_pairs","21","Step1B overall_n_pairs")
check_kv(kv1b,"site_confound_complete","YES","Step1B site confound")
check_kv(kv1b,"Primary25_unique_mapped","25","Step1B Primary25 mapping")
check_kv(kv1d,"EDFig4b_same_anatomical_site","YES","Step1D same-site authority")
check_kv(kv1d,"EDFig4b_same_patients_n","3","Step1D same-site n")
check_kv(kv1d,"EDFig4b_independent_validation","NO","Step1D independence role")
check_kv(kv1d,"EDFig4b_DEG","21","Step1D same-site DEG checksum")

# Read and audit source tables with explicit schema checks.
p1b <- read.csv(P1B,stringsAsFactors=FALSE,check.names=FALSE)
p1d <- read.csv(P1D,stringsAsFactors=FALSE,check.names=FALSE)

req1b <- c("gene","sheet","contrast","mapping_status",
           "baseMean","log2FoldChange","pvalue","padj",
           "author_DEG_by_published_rule")
req1d <- c("gene","workbook","sheet","contrast","mapping_status",
           "baseMean","log2FoldChange","pvalue","padj",
           "author_DEG_by_published_rule")

miss1b <- setdiff(req1b,names(p1b))
miss1d <- setdiff(req1d,names(p1d))

add("Step1B required columns","NONE",
    if(length(miss1b)) paste(miss1b,collapse=";") else "NONE",
    if(length(miss1b)==0L) "PASS" else "FAIL")
add("Step1D required columns","NONE",
    if(length(miss1d)) paste(miss1d,collapse=";") else "NONE",
    if(length(miss1d)==0L) "PASS" else "FAIL")

if(length(miss1b) || length(miss1d))
  freeze_hold("INPUT_SCHEMA_MISMATCH",155L)

p1b$gene <- trimws(as.character(p1b$gene))
p1d$gene <- trimws(as.character(p1d$gene))
p1d$sheet <- trimws(as.character(p1d$sheet))

add("Step1B row count","25",nrow(p1b),
    if(nrow(p1b)==25L) "PASS" else "FAIL")
add("Step1B exact Primary25 set","YES",
    if(setequal(p1b$gene,PRIMARY25)) "YES" else "NO",
    if(setequal(p1b$gene,PRIMARY25)) "PASS" else "FAIL",
    paste0("unique_genes=",length(unique(p1b$gene))))

for(sh in c("Fig 4c","Fig 4e","Fig 4f","Extended Data Fig 4b")) {
  z <- p1d[p1d$sheet==sh,,drop=FALSE]
  ok_rows <- nrow(z)==25L
  ok_set <- ok_rows && setequal(z$gene,PRIMARY25)
  add(paste0("Step1D ",sh," rows"),"25",nrow(z),
      if(ok_rows) "PASS" else "FAIL")
  add(paste0("Step1D ",sh," exact Primary25 set"),"YES",
      if(ok_set) "YES" else "NO",
      if(ok_set) "PASS" else "FAIL",
      paste0("unique_genes=",length(unique(z$gene))))
}

aud_now <- do.call(rbind,A)
if(any(aud_now$status=="FAIL"))
  freeze_hold("FROZEN_INPUT_PRECONDITION_FAIL",156L)

# --------------------------------------------------------------------------
# Scientific classification contract — unchanged from the prior Step1E.
# --------------------------------------------------------------------------

roles <- data.frame(
  authority=c(
    "R0_RVF_vs_pRV",
    "R3_Fig5c_n21",
    "R3_EDFig4b_n3",
    "R3_Fig4c",
    "R3_Fig4e",
    "R3_Fig4f"
  ),
  role=c(
    "FAILURE_DIRECTION_AUTHORITY",
    "MAIN_UNLOADING_ASSOCIATED_CHANGE_WITH_COMPLETE_SITE_CONFOUND",
    "SAME_PATIENT_SAME_SITE_DIRECTIONAL_SENSITIVITY",
    "BASELINE_DISEASE_CONTEXT_CONTROL_SEPTUM_MINUS_PRE_SEPTUM",
    "ANATOMICAL_SITE_DIAGNOSTIC_PRE_RV_MINUS_PRE_SEPTUM",
    "SMALL_N_MIXED_SITE_COMPATIBILITY_CHECK"
  ),
  required_for_primary_class=c("YES","YES","YES","NO","NO","NO"),
  inferential_weight=c(
    "PRIMARY_FROZEN",
    "PRIMARY_BUT_SITE_CONFOUNDED",
    "DIRECTIONAL_SENSITIVITY_N3",
    "CONTEXT_ONLY",
    "DIAGNOSTIC_ONLY",
    "DIAGNOSTIC_ONLY"
  ),
  stringsAsFactors=FALSE
)

rules <- data.frame(
  class=c(
    "REVERSAL_SUPPORTED",
    "MALADAPTIVE_NONREVERSAL_WORSENING_SUPPORTED",
    "SITE_CONFLICT",
    "MAIN_ONLY_UNRESOLVED",
    "INDETERMINATE_NO_MAIN_DEG",
    "UNASSESSABLE"
  ),
  main_n21_requirement=c(
    "AUTHOR_DEG_TRUE_AND_DIRECTION_OPPOSITE_FAILURE",
    "AUTHOR_DEG_TRUE_AND_DIRECTION_SAME_AS_FAILURE",
    "AUTHOR_DEG_TRUE",
    "AUTHOR_DEG_TRUE",
    "AUTHOR_DEG_FALSE",
    "REQUIRED_AUTHORITY_MISSING_OR_NONFINITE"
  ),
  same_site_n3_requirement=c(
    "FINITE_DIRECTION_OPPOSITE_FAILURE",
    "FINITE_DIRECTION_SAME_AS_FAILURE",
    "FINITE_DIRECTION_DISAGREES_WITH_MAIN",
    "MISSING_OR_NONFINITE",
    "NOT_USED_TO_UPGRADE_NULL_MAIN_RESULT",
    "NOT_ASSESSABLE"
  ),
  interpretation=c(
    "Directionally triangulated reversal after unloading; not proof of complete recovery.",
    "Continued movement in the failure direction after unloading with same-site support; not irreversible.",
    "Main mixed-site result conflicts with same-site sensitivity; no recovery/persistence label.",
    "Main mixed-site signal lacks same-site adjudication; no recovery/persistence label.",
    "No significant main unloading-associated change; absence of change is NOT evidence of persistence.",
    "Insufficient frozen source authority for classification."
  ),
  stringsAsFactors=FALSE
)

awrite(do.call(rbind,A),OUT_AUD)
awrite(roles,OUT_AUTH)
awrite(rules,OUT_RULES)

twrite(c(
  "R3_STEP1E_CLASSIFICATION_CONTRACT_FROZEN",
  paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
  "universe=FROZEN_PRIMARY25",
  "failure_direction_source=FROZEN_R0_RVF_vs_pRV_UNSHRUNK_LFC",
  "main_authority=FIG5C_N21_POST_SEPTUM_MINUS_PRE_RV",
  "main_site_confound_complete=YES",
  "main_DEG_rule=baseMean>=5_AND_abs_log2FC>=0.585_AND_padj<=0.05",
  "same_site_authority=EXTENDED_DATA_FIG4B_N3_POST_SEPTUM_MINUS_PRE_SEPTUM",
  "same_site_independent_validation=NO",
  "same_site_FDR_significance=SUPPORT_STRENGTH_ONLY_NOT_REQUIRED_FOR_PRIMARY_DIRECTIONAL_TRIANGULATION",
  "baseline_context=FIG4C_CONTROL_SEPTUM_MINUS_PRE_SEPTUM_CONTEXT_ONLY",
  "anatomical_site_diagnostic=FIG4E_PRE_RV_MINUS_PRE_SEPTUM",
  "small_n_mixed_site_check=FIG4F_POST_SEPTUM_MINUS_PRE_RV",
  "primary_REVERSAL_SUPPORTED=main_DEG_opposite_failure_AND_same_site_direction_opposite_failure",
  "primary_MALADAPTIVE_NONREVERSAL_WORSENING_SUPPORTED=main_DEG_same_failure_AND_same_site_direction_same_failure",
  "primary_SITE_CONFLICT=main_DEG_AND_same_site_direction_disagrees_with_main",
  "primary_MAIN_ONLY_UNRESOLVED=main_DEG_AND_same_site_unavailable",
  "primary_INDETERMINATE_NO_MAIN_DEG=main_not_DEG",
  "nonsignificance_implies_persistence=NO",
  "irreversible_wording_allowed=NO",
  "recovered_wording_without_direct_healthy_post_comparator=NO",
  "direct_post_vs_control_inferential_contrast_frozen=NO",
  "algebraic_post_vs_control_LFC_used_for_primary_classification=NO",
  "classification_executed=NO",
  "scientific_contract_changed_vs_initial_step1E=NO",
  "next_stage=R3 Step2 execute frozen core-gene classification, then program-level persistence/reversal analysis"
),OUT_TXT)

logline("FINAL_GATE: R3_STEP1E_CLASSIFICATION_CONTRACT_FROZEN")
quit(save="no",status=0,runLast=FALSE)
