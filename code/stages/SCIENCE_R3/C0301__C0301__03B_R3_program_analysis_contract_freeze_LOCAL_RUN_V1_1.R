# ---- RV PUBLIC PRIMARY DAG GATE9J REWRITE V1.0 ----
# source_id=C0301
# rewrite_scope=HISTORY_CHAIN_ONLY
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
# RV Project — R3 Step 3B V1.1
# PROGRAM ANALYSIS CONTRACT REPAIR
#
# INDEPENDENT-AUDIT REPAIR OF V1.0 BEFORE ANY PROGRAM RESULT EXISTS.
#
# V1.0 mechanical execution: PASS.
# V1.0 scientific independent audit: HOLD_METHOD_PSEUDOREPLICATION.
#
# Defect:
#   V1.0 proposed exact binomial/sign tests treating genes within a pathway as
#   independent Bernoulli observations. Genes within a biological program are
#   correlated and cannot serve as independent replicate units for pathway-level
#   inferential P/FDR.
#
# V1.1 repair:
#   - no upstream model is refit;
#   - no R0/R1/R2/R3 frozen result is modified;
#   - no program result is computed;
#   - primary program analysis becomes full-ranked Hallmark GSEA;
#   - R0 and R1 use already-existing frozen genome-wide Wald statistics;
#   - R3 uses author-published Fig5c / ED Fig4b gene-level statistics;
#   - exact Hallmark source + software/version identity is deferred to Step3C
#     and MUST be frozen before execution.
# ==============================================================================

options(stringsAsFactors=FALSE, warn=1)

ROOT <- normalizePath(getwd(),winslash="/",mustWork=TRUE)
if(!identical(tolower(ROOT),tolower(RV_PROJECT_ROOT))) {
  stop("Expected D:/RV_project; observed: ",ROOT)
}

R0 <- file.path(ROOT,"results","R0","v4_LOCAL_RUN")
R1 <- file.path(ROOT,"results","R1_GSE240921")
R3 <- file.path(ROOT,"results","R3_GSE249696")
LOGD <- file.path(ROOT,"logs")
dir.create(LOGD,recursive=TRUE,showWarnings=FALSE)


R0_FULL <- file.path(R0,"R0_FINAL_RVF_vs_pRV_assessable_results.csv")
R1_FULL <- file.path(R1,"R1_GSE240921_primary_Wald_all_genes.csv")
R1_GATE <- file.path(R1,"R1_GSE240921_STEP3A_PRIMARY_REPLICATION_PASS.txt")
TX2GENE <- file.path(ROOT,"data","tximport","GSE345645","GSE345645_transcript_to_gene.csv.gz")

R3A_PASS <- file.path(R3,"R3_STEP3A_PROGRAM_INPUT_PREFLIGHT_PASS.txt")
R3_MAIN  <- file.path(R3,"R3_STEP3A_FIG5c_author_stats_minimal.csv.gz")
R3_SAME  <- file.path(R3,"R3_STEP1D_ED4b_same_site_author_stats_minimal.csv.gz")

OUT_AUDIT <- file.path(R3,"R3_STEP3B_V1_1_contract_repair_audit.csv")
OUT_METHOD <- file.path(R3,"R3_STEP3B_V1_1_program_method_contract.csv")
OUT_CLASS <- file.path(R3,"R3_STEP3B_V1_1_program_classification_rules.csv")
OUT_AUTH <- file.path(R3,"R3_STEP3B_V1_1_program_authority_roles.csv")
OUT_PASS <- file.path(R3,"R3_STEP3B_V1_1_PROGRAM_ANALYSIS_CONTRACT_FROZEN.txt")
OUT_HOLD <- file.path(R3,"R3_STEP3B_V1_1_PROGRAM_ANALYSIS_CONTRACT_HOLD.txt")
LOG <- file.path(LOGD,"R3_STEP3B_V1_1_PROGRAM_ANALYSIS_CONTRACT.log")

if(file.exists(LOG)) {
  old <- file.path(LOGD,paste0(
    "R3_STEP3B_V1_1_PROGRAM_ANALYSIS_CONTRACT_",
    format(Sys.time(),"%Y%m%d_%H%M%S"),"_previous.log"))
  file.rename(LOG,old)
}

logline <- function(...) {
  z <- paste0(format(Sys.time(),"%Y-%m-%d %H:%M:%S")," | ",
              paste0(...,collapse=""))
  cat(z,"\n",sep="")
  cat(z,"\n",file=LOG,append=TRUE,sep="")
}
replace_file <- function(tmp,dest) {
  if(file.exists(dest)) unlink(dest,force=TRUE)
  if(!file.rename(tmp,dest)) {
    unlink(tmp,force=TRUE)
    stop("Atomic replace failed: ",dest)
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
    item=as.character(item),expected=as.character(expected),
    observed=as.character(observed),status=as.character(status),
    notes=as.character(notes),stringsAsFactors=FALSE
  )
  logline("[",status,"] ",item," | expected=",expected,
          " | observed=",observed,
          if(nzchar(notes)) paste0(" | ",notes) else "")
}
flush <- function() if(length(A)) awrite(do.call(rbind,A),OUT_AUDIT)

hold <- function(reason,code=231L) {
  flush()
  twrite(c(
    "R3_STEP3B_V1_1_PROGRAM_ANALYSIS_CONTRACT_HOLD",
    paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
    paste0("reason=",reason),
    "program_results_seen=NO",
    "GSEA_executed=NO",
    "ORA_executed=NO",
    "program_classification_executed=NO",
    "upstream_model_refit=NO",
    "upstream_frozen_results_modified=NO"
  ),OUT_HOLD)
  quit(save="no",status=code,runLast=FALSE)
}

options(error=function() {
  msg <- geterrmessage()
  try(flush(),silent=TRUE)
  try(twrite(c(
    "R3_STEP3B_V1_1_PROGRAM_ANALYSIS_CONTRACT_HOLD_RUNTIME_ERROR",
    paste0("error=",gsub("[\r\n]+"," | ",msg)),
    "program_results_seen=NO",
    "GSEA_executed=NO",
    "upstream_model_refit=NO"
  ),OUT_HOLD),silent=TRUE)
  q(save="no",status=232,runLast=FALSE)
})

logline("============================================================")
logline("R3 Step3B V1.1 — independent-audit program-contract repair")
logline("NO PROGRAM RESULT EXECUTION.")
logline("============================================================")

needed <- c(
  R0_FULL,R1_FULL,R1_GATE,TX2GENE,R3A_PASS,R3_MAIN,R3_SAME
)
for(p in needed) {
  ok <- file.exists(p)
  add(paste0("file_exists:",basename(p)),"YES",
      if(ok)"YES" else "NO",if(ok)"PASS" else "FAIL")
}
if(any(!file.exists(needed))) hold("MISSING_REQUIRED_FROZEN_INPUT",233L)

# Public cold start begins directly from the independently accepted V1.1 method.
add("Historical rejected Step3B V1.0 replayed",
    "NO","NO","PASS",
    "V1.0 pseudoreplication method remains provenance only; it is not a generation input.")

# Verify full ranked statistical authorities needed by repaired contract.
r0 <- read.csv(R0_FULL,stringsAsFactors=FALSE,check.names=FALSE)
r1 <- read.csv(R1_FULL,stringsAsFactors=FALSE,check.names=FALSE)
m  <- read.csv(gzfile(R3_MAIN),stringsAsFactors=FALSE,check.names=FALSE)
s  <- read.csv(gzfile(R3_SAME),stringsAsFactors=FALSE,check.names=FALSE)

need0 <- c("gene_id","stat","log2FoldChange","pvalue","padj")
need1 <- c("gse240921_gene_id","stat","log2FoldChange","pvalue")
needm <- c("gene","log2FoldChange","pvalue")
needs <- c("gene","log2FoldChange","pvalue")

for(z in list(
  c("R0",setdiff(need0,names(r0))),
  c("R1",setdiff(need1,names(r1))),
  c("R3_MAIN",setdiff(needm,names(m))),
  c("R3_SAME",setdiff(needs,names(s)))
)) {
  label <- z[1]; miss <- z[-1]
  add(paste0(label," rank-input schema"),"NONE",
      if(length(miss))paste(miss,collapse=";") else "NONE",
      if(!length(miss))"PASS" else "FAIL")
}
if(any(vapply(A,function(x) any(x$status=="FAIL"),logical(1))))
  hold("FULL_RANK_AUTHORITY_SCHEMA_MISMATCH",235L)

add("R0 full ranked authority rows","18621",nrow(r0),
    if(nrow(r0)==18621L)"PASS" else "FAIL")
add("R1 full Wald authority rows","48738",nrow(r1),
    if(nrow(r1)==48738L)"PASS" else "FAIL")
if(nrow(r0)!=18621L || nrow(r1)!=48738L)
  hold("FULL_RANK_AUTHORITY_ROWCOUNT_DRIFT",236L)

# --------------------------------------------------------------------------
# V1.1 repaired scientific contract
# --------------------------------------------------------------------------
method <- data.frame(
  section=c(
    "GENE_SET_SOURCE","GENE_SET_SOURCE","GENE_SET_SOURCE",
    "R0_FAILURE_PROGRAM","R0_FAILURE_PROGRAM","R0_FAILURE_PROGRAM","R0_FAILURE_PROGRAM",
    "R1_CROSS_ETIOLOGY_STABILITY","R1_CROSS_ETIOLOGY_STABILITY",
    "R1_CROSS_ETIOLOGY_STABILITY","R1_CROSS_ETIOLOGY_STABILITY",
    "R3_MAIN_UNLOADING","R3_MAIN_UNLOADING","R3_MAIN_UNLOADING",
    "R3_MAIN_UNLOADING","R3_MAIN_UNLOADING",
    "R3_SAME_SITE","R3_SAME_SITE","R3_SAME_SITE",
    "MAPPING","MAPPING","MULTIPLE_TESTING","MISSINGNESS",
    "WORDING","WORDING","WORDING","FUTURE_SUPPORT"
  ),
  field=c(
    "primary_collection","exact_release_policy","other_collections_primary",
    "rank_universe","rank_metric","program_test","failure_program_rule",
    "rank_universe","rank_metric","program_test","stable_program_rule",
    "authority","rank_metric","tested_program_family","program_test","main_signal_rule",
    "authority","program_test","support_rule",
    "R1_gene_mapping","duplicate_symbol_policy","FDR_policy","unassessable_policy",
    "nonsignificance_as_persistence","irreversible","complete_recovery_without_healthy",
    "R2_GSE291508_roles"
  ),
  frozen_value=c(
    "MSigDB_HALLMARK_HUMAN_H_ONLY",
    "STEP3C_FREEZE_EXACT_RELEASE_SOURCE_FILE_SHA256_MSIGDB_VERSION_AND_FGSEA_VERSION_BEFORE_EXECUTION",
    "NO_REACTOME_GO_KEGG_IN_PRIMARY_ANALYSIS",
    "R0_GSE345645_18621_ASSESSABLE_GENES",
    "FROZEN_DESEQ2_WALD_STAT_RVF_vs_pRV",
    "PRERANKED_FGSEA_MULTILEVEL_MIN10_MAX500_EPS0_SEED20260910_NPROC1",
    "R0_HALLMARK_BH_FDR_LT_0_05; FAILURE_DIRECTION_EQUALS_SIGN_OF_NES",
    "R1_GSE240921_FULL_PRIMARY_WALD_ALL_GENES_NO_REFIT",
    "FROZEN_DESEQ2_WALD_STAT_DECOMPENSATED_vs_COMPENSATED",
    "PRERANKED_FGSEA_MULTILEVEL_SAME_FROZEN_HALLMARK_SET",
    "R0_FDR_LT_0_05_AND_R1_FDR_LT_0_05_AND_SAME_NES_SIGN",
    "FIG5C_N21_AUTHOR_STATS_COMPLETE_SITE_CONFOUND",
    "SIGN_LOG2FC_TIMES_QNORM_TWO_SIDED_P_WITH_FIXED_P_FLOOR_1E_300",
    "ONLY_R0_R1_STABLE_PROGRAMS_FROZEN_BEFORE_R3_RESULTS",
    "PRERANKED_FGSEA_MULTILEVEL_SAME_HALLMARK_MEMBERSHIP",
    "R3_MAIN_BH_FDR_LT_0_05; DIRECTION_BY_NES_SIGN_RELATIVE_TO_FAILURE_DIRECTION",
    "EXTENDED_DATA_FIG4B_N3_SAME_PATIENT_SAME_SEPTUM_PRE_TO_POST",
    "PRERANKED_FGSEA_MULTILEVEL_FOR_DIRECTION_AND_SUPPORT_STRENGTH",
    "NES_DIRECTION_REQUIRED_FOR_SUPPORTED_REVERSAL_OR_WORSENING; SAME_SITE_FDR_SUPPORT_STRENGTH_ONLY",
    "FROZEN_TX2GENE_ENSEMBL_TO_GENE_SYMBOL",
    "ONLY_UNIQUE_ENSEMBL_TO_SYMBOL_MAPPINGS; AMBIGUOUS_SYMBOLS_EXCLUDED_WITH_AUDIT; NO_OUTCOME_BASED_COLLAPSE",
    "BH_WITHIN_R0_ALL_ELIGIBLE_HALLMARKS; R1_ALL_ELIGIBLE_HALLMARKS; R3_MAIN_STABLE_PROGRAMS; R3_SAME_SITE_STABLE_PROGRAMS",
    "PROGRAM_UNASSESSABLE_IF_GSEA_OVERLAP_LT_10_OR_RANK_INPUT_UNAVAILABLE; NEVER_PAD_GENE_VOTES",
    "NO",
    "PROHIBITED",
    "NO",
    "R2_POST_PRIMARY_SUPPORT_ONLY; GSE291508_LATER_HEALTHY_REFERENCE_ONLY"
  ),
  rationale=c(
    "Compact prespecified program collection.",
    "Prevents source/version drift and stochastic-runtime ambiguity.",
    "Prevents pathway shopping.",
    "Uses full frozen R0 statistical universe instead of threshold-selected gene votes.",
    "Uses the direct frozen inferential statistic.",
    "Rank-based coordinated program test; does not treat pathway genes as independent replicate units.",
    "Program direction is defined from transcriptome-wide enrichment.",
    "R1 full Wald output already exists from the frozen model; no model reopening.",
    "Same inferential-statistic type as R0.",
    "Cross-etiology program stability is evaluated transcriptome-wide.",
    "Requires significance and direction consistency in both etiologies.",
    "Preserves primary author unloading authority and explicit site confounding.",
    "R3 source lacks Wald stat; fixed deterministic signed-z-equivalent ranking from author P and LFC.",
    "Prevents R3 outcome from defining which programs are tested.",
    "Same program framework across cohorts.",
    "Main nonsignificance remains indeterminate.",
    "Same-site sensitivity addresses site confounding and is not independent replication.",
    "Same-site significance is low-power at n=3; NES direction is triangulation, FDR is strength only.",
    "Mirrors gene-level Step1E logic without gene pseudo-replication.",
    "Uses already frozen mapping authority.",
    "Avoids selecting the strongest Ensembl row by outcome.",
    "Keeps inferential families explicit and prespecified.",
    "Insufficient mapping is missingness, not negative evidence.",
    "Never call main nonsignificance persistent.",
    "No irreversibility claim.",
    "No complete-recovery claim without direct post-vs-healthy inference.",
    "Support sources cannot redefine the primary program set."
  ),
  stringsAsFactors=FALSE
)

classes <- data.frame(
  class=c(
    "PROGRAM_REVERSAL_SUPPORTED",
    "PROGRAM_MALADAPTIVE_NONREVERSAL_WORSENING_SUPPORTED",
    "PROGRAM_SITE_CONFLICT",
    "PROGRAM_MAIN_ONLY_UNRESOLVED",
    "PROGRAM_INDETERMINATE_NO_MAIN_SIGNAL",
    "PROGRAM_UNASSESSABLE"
  ),
  frozen_rule=c(
    "stable_program AND main_FDR_lt_0_05 AND sign(main_NES)==-failure_direction AND same_site_assessable AND sign(same_site_NES)==-failure_direction",
    "stable_program AND main_FDR_lt_0_05 AND sign(main_NES)==failure_direction AND same_site_assessable AND sign(same_site_NES)==failure_direction",
    "stable_program AND main_FDR_lt_0_05 AND same_site_assessable AND sign(same_site_NES)!=sign(main_NES)",
    "stable_program AND main_FDR_lt_0_05 AND same_site_unassessable",
    "stable_program AND main_assessable AND main_FDR_ge_0_05",
    "stable_program AND main_GSEA_overlap_lt_10_or_rank_input_unavailable"
  ),
  allowed_interpretation=c(
    "Coordinated failure-program reversal after unloading is supported by same-site directional triangulation.",
    "Persistent maladaptive/nonreversal worsening after unloading is supported; irreversible is prohibited.",
    "Main mixed-site and same-site program directions conflict; anatomical-site sensitivity is material.",
    "Main unloading program signal exists but same-site triangulation is unavailable.",
    "No primary unloading program call; must not be described as persistent or recovered.",
    "Required program-level unloading information is insufficient."
  ),
  stringsAsFactors=FALSE
)

auth <- data.frame(
  authority=c(
    "R0_GSE345645_18621_WALD",
    "R0_GSE345645_FDR05_330",
    "R1_GSE240921_FULL_WALD_48738",
    "R1_GSE240921_330_LEDGER_PRIMARY25",
    "R3_FIG5C_N21_AUTHOR_STATS",
    "R3_EDFIG4B_N3_SAME_SITE",
    "R3_STEP2_PRIMARY25",
    "R2_GSE198618",
    "GSE291508_HEALTHY",
    "FIG4E_SITE_DIAGNOSTIC"
  ),
  role=c(
    "PRIMARY_R0_PROGRAM_DISCOVERY_FULL_RANK",
    "GENE_LEVEL_DISCOVERY_CONTEXT_ONLY_NOT_PROGRAM_SEED",
    "PRIMARY_CROSS_ETIOLOGY_PROGRAM_STABILITY_FULL_RANK_NO_REFIT",
    "FROZEN_GENE_LEVEL_REPLICATION_CONTEXT_ONLY",
    "PRIMARY_UNLOADING_PROGRAM_SIGNAL_COMPLETE_SITE_CONFOUND",
    "REQUIRED_DIRECTIONAL_SITE_TRIANGULATION_NOT_INDEPENDENT_VALIDATION",
    "GENE_LEVEL_CONTEXT_ONLY_NOT_PROGRAM_DEFINITION",
    "POST_PRIMARY_SUPPORT_ONLY_CANNOT_ADD_OR_REDEFINE_PROGRAMS",
    "POST_PRIMARY_HEALTHY_REFERENCE_ONLY",
    "OPTIONAL_POST_PRIMARY_SITE_DIAGNOSTIC_CANNOT_CHANGE_CLASS"
  ),
  allowed_to_define_primary_program=c(
    "YES","NO","YES","NO","YES","YES","NO","NO","NO","NO"
  ),
  stringsAsFactors=FALSE
)

awrite(method,OUT_METHOD)
awrite(classes,OUT_CLASS)
awrite(auth,OUT_AUTH)
flush()

twrite(c(
  "R3_STEP3B_V1_1_PROGRAM_ANALYSIS_CONTRACT_FROZEN",
  paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
  "V1_0_execution_status=MECHANICAL_PASS",
  "V1_0_independent_scientific_audit=HOLD_METHOD_PSEUDOREPLICATION",
  "V1_0_effective_scientific_contract=NO",
  "V1_0_outputs_preserved_immutable=YES",
  "program_results_seen_before_repair=NO",
  "repair_scope=PROGRAM_LEVEL_METHOD_ONLY",
  "upstream_R0_R1_R2_R3_frozen_science_changed=NO",
  "primary_collection=MSigDB_HALLMARK_HUMAN_H_ONLY",
  "program_framework=FULL_RANKED_GSEA_NOT_GENE_VOTE_BINOMIAL",
  "R0_rank=DESEQ2_WALD_STAT_RVF_vs_pRV_18621",
  "R0_failure_program=HALLMARK_BH_FDR_LT_0_05",
  "R0_failure_direction=SIGN_OF_R0_NES",
  "R1_rank=FULL_PRIMARY_WALD_DECOMPENSATED_vs_COMPENSATED_NO_REFIT",
  "R1_stable_program=R0_FDR_LT_0_05_AND_R1_FDR_LT_0_05_AND_SAME_NES_SIGN",
  "R3_main_authority=FIG5C_N21_AUTHOR_STATS_COMPLETE_SITE_CONFOUND",
  "R3_main_rank=SIGNED_Z_EQUIVALENT_FROM_AUTHOR_PVALUE_AND_LOG2FC_FIXED_P_FLOOR_1E_300",
  "R3_main_test_family=ONLY_STABLE_PROGRAMS_FROZEN_BEFORE_R3_RESULTS",
  "R3_same_site_authority=EDFIG4B_N3_SAME_PATIENT_SAME_SEPTUM",
  "R3_same_site_FDR_role=SUPPORT_STRENGTH_ONLY",
  "nonsignificant_main_program_called_persistent=NO",
  "irreversible_wording_allowed=NO",
  "complete_recovery_without_direct_post_vs_healthy_allowed=NO",
  "GSEA_executed=NO",
  "program_classification_executed=NO",
  "next_stage=ChatGPT_INDEPENDENT_AUDIT_THEN_STEP3C_HALLMARK_AND_FGSEA_SOURCE_VERSION_IDENTITY_FREEZE"
),OUT_PASS)

if(file.exists(OUT_HOLD)) unlink(OUT_HOLD,force=TRUE)
logline("FINAL_GATE: R3_STEP3B_V1_1_PROGRAM_ANALYSIS_CONTRACT_FROZEN")
quit(save="no",status=0,runLast=FALSE)
