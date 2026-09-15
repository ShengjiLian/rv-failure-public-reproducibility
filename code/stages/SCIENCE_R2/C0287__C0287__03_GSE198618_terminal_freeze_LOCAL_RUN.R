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
# RV Project — R2 GSE198618 Step 3
# TERMINAL AUDIT + FINAL FREEZE
#
# This step performs NO statistical recomputation.
# It only verifies the already accepted Step1/Step2 artifacts and freezes
# the supporting-replication interpretation.
#
# No lmFit(), eBayes(), topTable(), p.adjust(), DESeq2, or edgeR fitting.
# ==============================================================================

options(stringsAsFactors=FALSE, warn=1)

ROOT <- normalizePath(getwd(), winslash="/", mustWork=TRUE)
if(!identical(ROOT,RV_PROJECT_ROOT)) stop("Expected D:/RV_project")

RES <- file.path(ROOT,"results","R2_GSE198618")
LOGDIR <- file.path(ROOT,"logs")
dir.create(LOGDIR,recursive=TRUE,showWarnings=FALSE)

CONTRACT <- file.path(RES,"R2_GSE198618_MODEL_CONTRACT_FROZEN.txt")
STEP2 <- file.path(RES,"R2_GSE198618_STEP2_LIMMA_SUPPORT_PASS.txt")
SUMMARY_IN <- file.path(RES,"R2_GSE198618_STEP2_LIMMA_FIT_SUMMARY.csv")
SUPPORT_IN <- file.path(RES,"R2_GSE198618_PRIMARY25_SUPPORT_RESULTS.csv")
STRICT_IN <- file.path(RES,"R2_GSE198618_PRIMARY25_STRICT_SUPPORT.csv")

FINAL_SUMMARY <- file.path(RES,"R2_GSE198618_FINAL_SUMMARY.csv")
FINAL18 <- file.path(RES,"R2_GSE198618_FINAL_SUPPORTING18.csv")
FINAL_OTHER <- file.path(RES,"R2_GSE198618_FINAL_NONSTRICT_OR_UNASSESSABLE.csv")
FINAL_GATE <- file.path(RES,"R2_GSE198618_R2_FINAL_FROZEN.txt")
LOG <- file.path(LOGDIR,"R2_GSE198618_STEP3_TERMINAL_FREEZE.log")

if(file.exists(LOG)) {
  old <- file.path(
    LOGDIR,
    paste0("R2_GSE198618_STEP3_TERMINAL_FREEZE_",
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
must <- function(x,msg) if(!isTRUE(x)) stop(msg,call.=FALSE)

awrite <- function(x,p) {
  t <- paste0(p,".tmp_",Sys.getpid())
  write.csv(x,t,row.names=FALSE,na="")
  if(file.exists(p)) unlink(p,force=TRUE)
  if(!file.rename(t,p)) {unlink(t); stop("Atomic CSV failed: ",p)}
}
twrite <- function(x,p) {
  t <- paste0(p,".tmp_",Sys.getpid())
  writeLines(x,t,useBytes=TRUE)
  if(file.exists(p)) unlink(p,force=TRUE)
  if(!file.rename(t,p)) {unlink(t); stop("Atomic text failed: ",p)}
}

logline("============================================================")
logline("R2 GSE198618 Step 3 — terminal audit and final freeze")
logline("NO statistical recomputation.")
logline("============================================================")

for(p in c(CONTRACT,STEP2,SUMMARY_IN,SUPPORT_IN,STRICT_IN)) {
  must(file.exists(p),paste0("Missing required input: ",p))
}

ct <- readLines(CONTRACT,warn=FALSE)
g2 <- readLines(STEP2,warn=FALSE)
sm <- read.csv(SUMMARY_IN,stringsAsFactors=FALSE,check.names=FALSE)
su <- read.csv(SUPPORT_IN,stringsAsFactors=FALSE,check.names=FALSE)
st <- read.csv(STRICT_IN,stringsAsFactors=FALSE,check.names=FALSE)

must(ct[1]=="R2_GSE198618_MODEL_CONTRACT_FROZEN","Wrong Step1 contract gate")
must(g2[1]=="R2_GSE198618_STEP2_LIMMA_SUPPORT_PASS","Wrong Step2 gate")
must(any(g2=="status=PASS_READY_FOR_CHATGPT_AUDIT"),"Step2 is not audit-ready")

# Frozen interpretive constraints.
for(z in c(
  "role=SUPPORTING_PAH_REPLICATION",
  "patient_overlap_with_GSE240921=UNKNOWN",
  "full_independence_claim_allowed=NO",
  "supporting_candidate_family=GSE240921_FINAL_PRIMARY25",
  "supporting_candidate_family_size=25",
  "support_FDR_family=FULL_25_PADDED",
  "support_FDR_method=BH",
  "support_FDR_alpha=0.05",
  "new_genes_can_be_added_to_PRIMARY25=NO"
)) {
  must(any(ct==z),paste0("Contract mismatch: ",z))
}

must(nrow(su)==25L,"Support ledger must contain exactly 25 genes")
must(length(unique(su$r0_gene_id))==25L,"Support ledger gene IDs not unique")
must(nrow(st)==18L,"Strict-support table must contain exactly 18 genes")
must(length(unique(st$r0_gene_id))==18L,"Strict-support genes not unique")

assess <- su$support_assessability=="ASSESSABLE_LIMMA_FINITE"
strict <- as.logical(su$strict_support)
nominal <- as.logical(su$nominal_directional_support)
direction <- as.logical(su$direction_concordant)

must(sum(assess)==20L,"Expected 20 expression-assessable genes")
must(sum(direction & assess)==20L,"Expected 20/20 direction concordance")
must(sum(nominal)==18L,"Expected 18 nominal directional supports")
must(sum(strict)==18L,"Expected 18 strict supports")
must(sum(su$support_assessability=="UNMAPPED_PAD_P1")==1L,
     "Expected 1 unmapped padded gene")
must(sum(su$support_assessability=="LOW_EXPRESSION_PAD_P1")==4L,
     "Expected 4 low-expression padded genes")
must(all(su$added_to_PRIMARY25=="NO"),"PRIMARY25 was modified")

# Verify strict table is an exact projection of the accepted ledger.
strict_ids <- sort(as.character(su$r0_gene_id[strict]))
st_ids <- sort(as.character(st$r0_gene_id))
must(identical(strict_ids,st_ids),
     "Strict-support table does not exactly match support ledger")

# Verify stored strict criteria without recalculating any P/FDR.
must(all(is.finite(su$r2_pvalue_raw[assess])),
     "Assessable rows contain nonfinite stored p-values")
must(all(is.finite(su$r2_BH_FDR_25[assess])),
     "Assessable rows contain nonfinite stored BH FDR")
must(all(su$r2_BH_FDR_25[strict] < 0.05),
     "A strict-support row has stored FDR >= 0.05")
must(all(direction[strict]),
     "A strict-support row is direction-discordant")

# Exact accepted sets.
expected_strict <- sort(c(
  "COMP","ALOX5","SPP1","SLCO2A1","SP140","JAK3","BIN2","VDR",
  "IL21R","GMIP","SMAD7","PLSCR1","CP","SLC6A6","STXBP2","MYO1F",
  "MPC2","CD163"
))
must(identical(strict_ids,expected_strict),
     "Strict-support gene set differs from accepted Step2 audit")

expected_non_strict_assess <- sort(c("ABCC3","KYNU"))
observed_non_strict_assess <- sort(as.character(
  su$r0_gene_id[assess & !strict]
))
must(identical(observed_non_strict_assess,expected_non_strict_assess),
     "Assessable non-strict set differs from accepted Step2 audit")

expected_unassess <- sort(c("LIPG","GRIN2B","DNAH7","CSMD1","CD72"))
observed_unassess <- sort(as.character(su$r0_gene_id[!assess]))
must(identical(observed_unassess,expected_unassess),
     "Unassessable set differs from accepted Step2 audit")

# Produce terminal derived outputs only.
final18 <- su[strict,,drop=FALSE]
final18$terminal_status <- "R2_SUPPORTING_STRICT_FROZEN"

other <- su[!strict,,drop=FALSE]
other$terminal_status <- ifelse(
  other$support_assessability=="ASSESSABLE_LIMMA_FINITE",
  "ASSESSABLE_DIRECTION_CONCORDANT_NOT_FDR_SUPPORTED",
  "UNASSESSABLE_PER_FROZEN_RULE"
)

summary_out <- data.frame(
  metric=c(
    "dataset",
    "role",
    "patient_overlap_with_GSE240921",
    "full_independence_claim_allowed",
    "PRIMARY25_family",
    "PRIMARY25_expression_assessable",
    "PRIMARY25_direction_concordant_among_assessable",
    "PRIMARY25_strict_support",
    "PRIMARY25_assessable_non_strict",
    "PRIMARY25_unassessable",
    "strict_support_gene_list",
    "assessable_non_strict_gene_list",
    "unassessable_gene_list",
    "PRIMARY25_modified",
    "terminal_statistical_recomputation",
    "R2_status"
  ),
  value=c(
    "GSE198618",
    "SUPPORTING_PAH_REPLICATION",
    "UNKNOWN",
    "NO",
    "25",
    "20",
    "20",
    "18",
    "2",
    "5",
    paste(expected_strict,collapse=";"),
    paste(expected_non_strict_assess,collapse=";"),
    paste(expected_unassess,collapse=";"),
    "NO",
    "NO",
    "FINAL_FROZEN"
  ),
  stringsAsFactors=FALSE
)

awrite(summary_out,FINAL_SUMMARY)
awrite(final18,FINAL18)
awrite(other,FINAL_OTHER)

twrite(c(
  "R2_GSE198618_FINAL_FROZEN",
  paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
  "dataset=GSE198618",
  "role=SUPPORTING_PAH_REPLICATION",
  "patient_overlap_with_GSE240921=UNKNOWN",
  "full_independence_claim_allowed=NO",
  "input=AUTHOR_SUPPLIED_EDGE_R_CPM_NORMALIZED_NONINTEGER",
  "transform=log2_CPM_plus_1",
  "analysis_engine=limma",
  "model=~ clinical_state",
  "reference=COMPENSATED",
  "contrast=DECOMPENSATED_vs_COMPENSATED",
  "empirical_bayes=eBayes_trend_TRUE",
  "supporting_candidate_family=GSE240921_FINAL_PRIMARY25",
  "supporting_candidate_family_size=25",
  "PRIMARY25_expression_assessable=20",
  "PRIMARY25_direction_concordant=20",
  "PRIMARY25_strict_support=18",
  "PRIMARY25_assessable_non_strict=2",
  "PRIMARY25_unassessable=5",
  paste0("strict_support_genes=",paste(expected_strict,collapse=";")),
  "assessable_non_strict_genes=ABCC3;KYNU",
  "unassessable_genes=CD72;CSMD1;DNAH7;GRIN2B;LIPG",
  "strict_R2_label=SUPPORTING_STRICT_SUPPORT_NOT_INDEPENDENT_REPLICATION",
  "new_genes_can_be_added_to_PRIMARY25=NO",
  "PRIMARY25_modified=NO",
  "terminal_statistical_recomputation=NO",
  "status=FINAL_FROZEN",
  "next_stage=GSE249696_CTEPH_UNLOADING_PREFLIGHT"
),FINAL_GATE)

logline("[PASS] Exact PRIMARY25 family: 25")
logline("[PASS] Assessable: 20")
logline("[PASS] Direction concordant: 20/20")
logline("[PASS] Strict supporting evidence: 18/25")
logline("[PASS] Assessable but non-strict: ABCC3, KYNU")
logline("[PASS] Unassessable: LIPG, GRIN2B, DNAH7, CSMD1, CD72")
logline("FINAL_GATE: R2_GSE198618_FINAL_FROZEN")
quit(save="no",status=0,runLast=FALSE)
