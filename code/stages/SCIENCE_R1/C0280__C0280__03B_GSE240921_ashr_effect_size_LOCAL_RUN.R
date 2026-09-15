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
# RV Project — R1 GSE240921 Step 3B
# ASHR EFFECT-SIZE SENSITIVITY ONLY
#
# Primary replication is already frozen by Step 3A.
# This step MUST NOT change:
#   - Wald p-values
#   - primary 330-family BH FDR
#   - primary replicated set
#
# It only shrinks the direct coefficient:
#   clinical_state_DECOMPENSATED_vs_COMPENSATED
#
# Outputs are descriptive/ranking sensitivity only.
# ==============================================================================

options(stringsAsFactors=FALSE, warn=1)

ROOT <- normalizePath(getwd(), winslash="/", mustWork=TRUE)
if (!identical(ROOT,RV_PROJECT_ROOT)) stop("Expected D:/RV_project")

user_lib <- file.path(Sys.getenv("LOCALAPPDATA"),"R","win-library","4.6")
if (dir.exists(user_lib)) .libPaths(unique(c(user_lib,.libPaths())))

suppressPackageStartupMessages({
  library(DESeq2)
  library(ashr)
})

RES <- file.path(ROOT,"results","R1_GSE240921")
LOGDIR <- file.path(ROOT,"logs")
dir.create(LOGDIR,recursive=TRUE,showWarnings=FALSE)

STEP3A_GATE <- file.path(RES,"R1_GSE240921_STEP3A_PRIMARY_REPLICATION_PASS.txt")
FITTED <- file.path(RES,"R1_GSE240921_primary_fitted_dds.rds")
LEDGER <- file.path(RES,"R1_GSE240921_R0_330_primary_replication_ledger.csv")
PRIMARY_REP <- file.path(RES,"R1_GSE240921_R0_330_PRIMARY_REPLICATED.csv")

OUT_ALL <- file.path(RES,"R1_GSE240921_primary_ashr_all_genes.csv")
OUT_LEDGER <- file.path(RES,"R1_GSE240921_R0_330_ASHR_effect_size_ledger.csv")
OUT_REP <- file.path(RES,"R1_GSE240921_R0_330_PRIMARY_REPLICATED_with_ASHR.csv")
OUT_SUM <- file.path(RES,"R1_GSE240921_step3B_ashr_summary.csv")
OUT_GATE <- file.path(RES,"R1_GSE240921_STEP3B_ASHR_EFFECT_SIZE_PASS.txt")
LOG <- file.path(LOGDIR,"R1_GSE240921_STEP3B_ASHR.log")

if (file.exists(LOG)) {
  old <- file.path(LOGDIR,paste0(
    "R1_GSE240921_STEP3B_ASHR_",
    format(Sys.time(),"%Y%m%d_%H%M%S"),"_previous.log"))
  file.rename(LOG,old)
}

logline <- function(...) {
  z <- paste0(format(Sys.time(),"%Y-%m-%d %H:%M:%S")," | ",paste0(...,collapse=""))
  cat(z,"\n",sep="")
  cat(z,"\n",file=LOG,append=TRUE,sep="")
  flush.console()
}
must <- function(x,msg) if(!isTRUE(x)) stop(msg,call.=FALSE)
awrite <- function(x,p) {
  t <- paste0(p,".tmp_",Sys.getpid())
  write.csv(x,t,row.names=FALSE,na="")
  if(!file.rename(t,p)) {unlink(t); stop("Atomic CSV failed: ",p)}
}
twrite <- function(x,p) {
  t <- paste0(p,".tmp_",Sys.getpid())
  writeLines(x,t,useBytes=TRUE)
  if(!file.rename(t,p)) {unlink(t); stop("Atomic text failed: ",p)}
}

logline("============================================================")
logline("R1 GSE240921 Step 3B — ASHR effect-size sensitivity only")
logline("============================================================")

if (file.exists(OUT_GATE) && file.exists(OUT_LEDGER)) {
  logline("FINAL_GATE: R1_GSE240921_STEP3B_ASHR_ALREADY_PASS__NO_RERUN")
  quit(save="no",status=0,runLast=FALSE)
}

must(file.exists(STEP3A_GATE),"Missing Step3A PASS gate")
must(file.exists(FITTED),"Missing fitted DDS")
must(file.exists(LEDGER),"Missing Step3A 330 ledger")
must(file.exists(PRIMARY_REP),"Missing Step3A primary replicated file")

g <- readLines(STEP3A_GATE,warn=FALSE)
must(length(g)>0L && g[1]=="R1_GSE240921_STEP3A_PRIMARY_REPLICATION_PASS",
     "Unexpected Step3A gate")
must(any(g=="primary_replicated=25"),"Expected frozen primary_replicated=25")
must(any(g=="primary_assessable=256"),"Expected primary_assessable=256")

dds <- readRDS(FITTED)
must(inherits(dds,"DESeqDataSet"),"Invalid fitted DDS")
must(nrow(dds)==48738L && ncol(dds)==40L,"Fitted DDS dimensions changed")

coef_name <- "clinical_state_DECOMPENSATED_vs_COMPENSATED"
must(coef_name %in% DESeq2::resultsNames(dds),"Primary coefficient absent")

# Baseline unshrunk Wald result used only for identity checks.
unshr <- DESeq2::results(
  dds,
  name=coef_name,
  independentFiltering=FALSE
)
u <- as.data.frame(unshr)

logline("[INFO] Running ASHR shrinkage on frozen direct coefficient.")
shr <- DESeq2::lfcShrink(
  dds,
  coef=coef_name,
  type="ashr",
  res=unshr
)
s <- as.data.frame(shr)

must(nrow(s)==48738L && identical(rownames(s),rownames(dds)),
     "ASHR result row identity changed")

# ASHR must not alter p-values or adjusted p-values supplied by the frozen Wald result.
same_p <- isTRUE(all.equal(as.numeric(s$pvalue),as.numeric(u$pvalue),
                           tolerance=0,check.attributes=FALSE))
same_padj <- isTRUE(all.equal(as.numeric(s$padj),as.numeric(u$padj),
                              tolerance=0,check.attributes=FALSE))
must(same_p,"ASHR unexpectedly changed p-values")
must(same_padj,"ASHR unexpectedly changed DESeq2 padj values")

all_ashr <- data.frame(
  gse240921_gene_id=rownames(dds),
  unshrunk_log2FC=as.numeric(u$log2FoldChange),
  ashr_log2FC=as.numeric(s$log2FoldChange),
  ashr_lfcSE=as.numeric(s$lfcSE),
  pvalue=as.numeric(s$pvalue),
  padj=as.numeric(s$padj),
  stringsAsFactors=FALSE
)
awrite(all_ashr,OUT_ALL)

led <- read.csv(LEDGER,stringsAsFactors=FALSE,check.names=FALSE)
must(nrow(led)==330L,"Step3A ledger must have 330 rows")
must(sum(as.logical(led$primary_replicated))==25L,
     "Frozen primary replicated set changed before ASHR")

led$ashr_log2FC <- NA_real_
led$ashr_lfcSE <- NA_real_
led$ashr_finite <- FALSE
led$unshrunk_vs_ashr_sign_concordant <- NA

mapped <- which(led$mapping_status=="UNIQUE_MAPPED")
mi <- match(led$gse240921_gene_id[mapped],all_ashr$gse240921_gene_id)
must(all(!is.na(mi)),"Mapped candidate missing from ASHR table")

led$ashr_log2FC[mapped] <- all_ashr$ashr_log2FC[mi]
led$ashr_lfcSE[mapped] <- all_ashr$ashr_lfcSE[mi]
led$ashr_finite[mapped] <- is.finite(led$ashr_log2FC[mapped]) &
                           is.finite(led$ashr_lfcSE[mapped])
led$unshrunk_vs_ashr_sign_concordant[mapped] <- (
  sign(led$gse240921_log2FC[mapped]) ==
  sign(led$ashr_log2FC[mapped])
)

# Frozen primary result columns must remain byte-logically unchanged in memory.
must(sum(as.logical(led$primary_replicated))==25L,
     "ASHR step modified primary replicated flags")

rep_idx <- which(as.logical(led$primary_replicated))
must(length(rep_idx)==25L,"Expected 25 primary replicated genes")

rep_all_finite <- all(led$ashr_finite[rep_idx])
rep_sign_discord <- sum(
  !as.logical(led$unshrunk_vs_ashr_sign_concordant[rep_idx]),
  na.rm=TRUE
)

mapped_finite <- sum(led$ashr_finite[mapped])
mapped_sign_discord <- sum(
  !as.logical(led$unshrunk_vs_ashr_sign_concordant[mapped]),
  na.rm=TRUE
)

awrite(led,OUT_LEDGER)

rep <- led[rep_idx,,drop=FALSE]
rep <- rep[order(rep$primary_BH_FDR_330,-abs(rep$ashr_log2FC),rep$r0_gene_id),,drop=FALSE]
awrite(rep,OUT_REP)

summary <- data.frame(
  metric=c(
    "primary_replicated_frozen",
    "mapped_candidates",
    "mapped_candidates_ashr_finite",
    "mapped_unshrunk_vs_ashr_sign_discordant",
    "primary_replicated_ashr_finite",
    "primary_replicated_unshrunk_vs_ashr_sign_discordant",
    "pvalue_identity_preserved",
    "DESeq2_padj_identity_preserved",
    "primary_replicated_set_modified",
    "DESeq_model_refit",
    "sex_sensitivity_model_fit"
  ),
  value=c(
    25,
    length(mapped),
    mapped_finite,
    mapped_sign_discord,
    sum(led$ashr_finite[rep_idx]),
    rep_sign_discord,
    same_p,
    same_padj,
    "NO",
    "NO",
    "NO"
  ),
  stringsAsFactors=FALSE
)
awrite(summary,OUT_SUM)

twrite(c(
  "R1_GSE240921_STEP3B_ASHR_EFFECT_SIZE_PASS",
  paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
  "primary_replicated_set=FROZEN_25_UNCHANGED",
  "ashr_role=EFFECT_SIZE_AND_RANKING_ONLY",
  paste0("mapped_candidates_ashr_finite=",mapped_finite),
  paste0("mapped_sign_discordant=",mapped_sign_discord),
  paste0("primary_replicated_ashr_finite=",sum(led$ashr_finite[rep_idx])),
  paste0("primary_replicated_sign_discordant=",rep_sign_discord),
  paste0("pvalue_identity_preserved=",same_p),
  paste0("DESeq2_padj_identity_preserved=",same_padj),
  "DESeq_model_refit_executed=NO",
  "sex_sensitivity_model_executed=NO",
  "next_stage=R1 Step 3C sex-adjusted sensitivity after ChatGPT audit"
),OUT_GATE)

logline("Mapped ASHR finite=",mapped_finite,"/326")
logline("Mapped sign discordant=",mapped_sign_discord)
logline("Primary replicated ASHR finite=",sum(led$ashr_finite[rep_idx]),"/25")
logline("Primary replicated sign discordant=",rep_sign_discord)
logline("FINAL_GATE: R1_GSE240921_STEP3B_ASHR_EFFECT_SIZE_PASS")
quit(save="no",status=0,runLast=FALSE)
