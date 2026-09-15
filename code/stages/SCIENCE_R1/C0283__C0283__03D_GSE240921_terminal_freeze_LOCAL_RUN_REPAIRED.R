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
# RV Project — R1 GSE240921 Step 3D
# TERMINAL AUDIT + FINAL FREEZE
#
# NO model fit.
# NO Wald re-extraction.
# NO BH/FDR recomputation.
# NO threshold changes.
#
# This step only:
#   1) binds the already accepted Step3A/3B/3C authorities,
#   2) explains the one sex-sensitivity nonfinite Wald p-value if possible,
#   3) creates final publication-facing R1 authority tables,
#   4) freezes GSE240921 R1.
# ==============================================================================

options(stringsAsFactors=FALSE, warn=1)

ROOT <- normalizePath(getwd(), winslash="/", mustWork=TRUE)
if (!identical(ROOT,RV_PROJECT_ROOT)) stop("Expected D:/RV_project")

user_lib <- file.path(Sys.getenv("LOCALAPPDATA"),"R","win-library","4.6")
if (dir.exists(user_lib)) .libPaths(unique(c(user_lib,.libPaths())))

suppressPackageStartupMessages(library(DESeq2))

RES <- file.path(ROOT,"results","R1_GSE240921")
LOGDIR <- file.path(ROOT,"logs")
dir.create(LOGDIR,recursive=TRUE,showWarnings=FALSE)

G3A <- file.path(RES,"R1_GSE240921_STEP3A_PRIMARY_REPLICATION_PASS.txt")
G3B <- file.path(RES,"R1_GSE240921_STEP3B_ASHR_EFFECT_SIZE_PASS.txt")
G3C <- file.path(RES,"R1_GSE240921_STEP3C_SEX_SENSITIVITY_PASS.txt")

PRIMARY_LEDGER <- file.path(RES,"R1_GSE240921_R0_330_primary_replication_ledger.csv")
ASHR_LEDGER <- file.path(RES,"R1_GSE240921_R0_330_ASHR_effect_size_ledger.csv")
SENS_LEDGER <- file.path(RES,"R1_GSE240921_R0_330_sex_sensitivity_ledger.csv")
SENS_DDS <- file.path(RES,"R1_GSE240921_sex_sensitivity_fitted_dds.rds")

OUT_FINAL25 <- file.path(RES,"R1_GSE240921_FINAL_PRIMARY25.csv")
OUT_SUM <- file.path(RES,"R1_GSE240921_TERMINAL_SUMMARY.csv")
OUT_SENS_ONLY <- file.path(RES,"R1_GSE240921_SENSITIVITY_ONLY_STRICT.csv")
OUT_DIAG <- file.path(RES,"R1_GSE240921_SENSITIVITY_NONFINITE_DIAGNOSTIC.csv")
OUT_GATE <- file.path(RES,"R1_GSE240921_R1_FINAL_FROZEN.txt")
LOG <- file.path(LOGDIR,"R1_GSE240921_STEP3D_TERMINAL_FREEZE.log")

if (file.exists(LOG)) {
  old <- file.path(
    LOGDIR,
    paste0("R1_GSE240921_STEP3D_TERMINAL_FREEZE_",
           format(Sys.time(),"%Y%m%d_%H%M%S"),"_previous.log")
  )
  file.rename(LOG,old)
}

logline <- function(...) {
  z <- paste0(format(Sys.time(),"%Y-%m-%d %H:%M:%S")," | ",paste0(...,collapse=""))
  cat(z,"\n",sep="")
  cat(z,"\n",file=LOG,append=TRUE,sep="")
  flush.console()
}
must <- function(x,msg) if(!isTRUE(x)) stop(msg,call.=FALSE)
replace_file <- function(tmp,dest) {
  if(file.exists(dest)) {
    bak <- paste0(dest,".previous")
    if(file.exists(bak)) unlink(bak,force=TRUE)
    okbak <- file.rename(dest,bak)
    if(!okbak) {
      unlink(dest,force=TRUE)
    }
  }
  ok <- file.rename(tmp,dest)
  if(!ok) {
    unlink(tmp,force=TRUE)
    stop("Terminal derived-output replacement failed: ",dest)
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

options(error=function() {
  msg <- geterrmessage()
  z <- paste0(format(Sys.time(),"%Y-%m-%d %H:%M:%S"),
              " | [FATAL] ",gsub("[\\r\\n]+"," ",msg))
  cat(z,"\n",file=LOG,append=TRUE,sep="")
  tb <- capture.output(traceback(20))
  if(length(tb)) cat(paste0(tb,collapse="\n"),"\n",file=LOG,append=TRUE,sep="")
  quit(save="no",status=1,runLast=FALSE)
})

logline("============================================================")
logline("R1 GSE240921 Step 3D — terminal audit and final freeze")
logline("NO statistical recomputation.")
logline("============================================================")

if (file.exists(OUT_GATE) && file.exists(OUT_FINAL25) && file.exists(OUT_SUM)) {
  logline("FINAL_GATE: R1_GSE240921_R1_ALREADY_FINAL_FROZEN__NO_RERUN")
  quit(save="no",status=0,runLast=FALSE)
}

for(p in c(G3A,G3B,G3C,PRIMARY_LEDGER,ASHR_LEDGER,SENS_LEDGER,SENS_DDS)) {
  must(file.exists(p),paste0("Missing required terminal input: ",p))
}

g3a <- readLines(G3A,warn=FALSE)
g3b <- readLines(G3B,warn=FALSE)
g3c <- readLines(G3C,warn=FALSE)

must(g3a[1]=="R1_GSE240921_STEP3A_PRIMARY_REPLICATION_PASS",
     "Unexpected Step3A authority")
must(g3b[1]=="R1_GSE240921_STEP3B_ASHR_EFFECT_SIZE_PASS",
     "Unexpected Step3B authority")
must(g3c[1]=="R1_GSE240921_STEP3C_SEX_SENSITIVITY_PASS",
     "Unexpected Step3C authority")

# Exact accepted gate invariants.
must(any(g3a=="primary_assessable=256"),"Step3A assessable count changed")
must(any(g3a=="primary_replicated=25"),"Step3A primary result changed")
must(any(g3b=="primary_replicated_set=FROZEN_25_UNCHANGED"),
     "Step3B primary freeze changed")
must(any(g3b=="mapped_sign_discordant=0"),
     "Step3B ASHR direction stability changed")
must(any(g3b=="primary_replicated_sign_discordant=0"),
     "Step3B primary ASHR direction stability changed")
must(any(g3c=="primary_result=FROZEN_25_UNCHANGED"),
     "Step3C primary freeze changed")
must(any(g3c=="sensitivity_assessable=255"),
     "Step3C sensitivity assessable count changed")
must(any(g3c=="sensitivity_strict_replicated=23"),
     "Step3C sensitivity strict count changed")
must(any(g3c=="PRIMARY25_same_sign=25"),
     "Step3C primary25 sign stability changed")
must(any(g3c=="PRIMARY25_nominal_p_lt_0.05=24"),
     "Step3C primary25 nominal support changed")
must(any(g3c=="PRIMARY25_strict_FDR_support=22"),
     "Step3C primary25 strict support changed")

pri <- read.csv(PRIMARY_LEDGER,stringsAsFactors=FALSE,check.names=FALSE)
ash <- read.csv(ASHR_LEDGER,stringsAsFactors=FALSE,check.names=FALSE)
sen <- read.csv(SENS_LEDGER,stringsAsFactors=FALSE,check.names=FALSE)

must(nrow(pri)==330L && nrow(ash)==330L && nrow(sen)==330L,
     "One or more candidate ledgers are not exactly 330 rows")
must(identical(pri$r0_gene_id,ash$r0_gene_id) &&
     identical(pri$r0_gene_id,sen$r0_gene_id),
     "Candidate ledgers differ in gene identity/order")

p25_idx <- which(as.logical(pri$primary_replicated))
must(length(p25_idx)==25L,"Primary replicated set is not 25")

# Verify primary columns carried unchanged into later ledgers.
core_cols <- c(
  "r0_gene_id","r0_log2FC","r0_direction","mapping_status",
  "gse240921_gene_id","gse240921_baseMean","gse240921_log2FC",
  "gse240921_lfcSE","gse240921_stat","gse240921_pvalue",
  "primary_assessability","primary_p_for_BH330","primary_BH_FDR_330",
  "direction_concordant","primary_replicated"
)

for(cc in core_cols) {
  must(cc %in% names(pri) && cc %in% names(ash) && cc %in% names(sen),
       paste0("Missing frozen core column: ",cc))
  a <- pri[[cc]]
  b <- ash[[cc]]
  c <- sen[[cc]]
  if(is.numeric(a)) {
    must(isTRUE(all.equal(a,b,tolerance=0,check.attributes=FALSE)) &&
         isTRUE(all.equal(a,c,tolerance=0,check.attributes=FALSE)),
         paste0("Frozen numeric primary column changed: ",cc))
  } else {
    must(identical(as.character(a),as.character(b)) &&
         identical(as.character(a),as.character(c)),
         paste0("Frozen primary column changed: ",cc))
  }
}

# --------------------------------------------------------------------------
# Sex-sensitivity nonfinite p diagnostic.
# No inference is changed.
# --------------------------------------------------------------------------

nonfinite <- which(
  sen$primary_assessability=="ASSESSABLE_WALD_FINITE" &
  sen$sensitivity_status=="SENS_WALD_P_NONFINITE_PAD_P1"
)
must(length(nonfinite)==1L,
     "Expected exactly one sensitivity nonfinite p among primary-assessable genes")

sdds <- readRDS(SENS_DDS)
must(inherits(sdds,"DESeqDataSet"),"Invalid sensitivity fitted DDS")
must(nrow(sdds)==48738L && ncol(sdds)==40L,"Sensitivity DDS dimensions changed")

smc <- as.data.frame(S4Vectors::mcols(sdds))
must("maxCooks" %in% names(smc),
     "Sensitivity fitted DDS lacks maxCooks diagnostic")

gene <- sen$gse240921_gene_id[nonfinite]
ri <- match(gene,rownames(sdds))
must(!is.na(ri),"Nonfinite sensitivity gene missing from sensitivity DDS")

n <- ncol(sdds)
p <- ncol(model.matrix(design(sdds),data=as.data.frame(colData(sdds))))
cook_cut <- stats::qf(0.99,p,n-p)
max_cook <- as.numeric(smc$maxCooks[ri])

cook_class <- if(
  is.finite(max_cook) && is.finite(cook_cut) && max_cook > cook_cut
) {
  "DESEQ2_COOKS_OUTLIER_FILTER_SUPPORTED"
} else {
  "NONFINITE_P_NOT_EXPLAINED_BY_MAXCOOKS_CUTOFF"
}

diag <- data.frame(
  r0_gene_id=sen$r0_gene_id[nonfinite],
  gse240921_gene_id=gene,
  primary_log2FC=sen$gse240921_log2FC[nonfinite],
  primary_pvalue=sen$gse240921_pvalue[nonfinite],
  primary_BH_FDR_330=sen$primary_BH_FDR_330[nonfinite],
  sensitivity_log2FC=sen$sensitivity_log2FC[nonfinite],
  sensitivity_stat=sen$sensitivity_stat[nonfinite],
  sensitivity_pvalue=sen$sensitivity_pvalue[nonfinite],
  sensitivity_status=sen$sensitivity_status[nonfinite],
  maxCooks=max_cook,
  default_Cooks_cutoff=cook_cut,
  diagnostic_class=cook_class,
  inferential_action="KEEP_PAD_P1_PER_FROZEN_SENSITIVITY_RULE",
  stringsAsFactors=FALSE
)
awrite(diag,OUT_DIAG)

# Terminal freeze fails closed only if the nonfinite p remains unexplained.
must(cook_class=="DESEQ2_COOKS_OUTLIER_FILTER_SUPPORTED",
     paste0(
       "Sensitivity nonfinite p remains unexplained by maxCooks. ",
       "Do not terminal-freeze; inspect diagnostic."
     ))

# --------------------------------------------------------------------------
# Final publication-facing 25-gene authority table.
# --------------------------------------------------------------------------

final25 <- sen[p25_idx,,drop=FALSE]

# Reconstruct the three Primary25 sensitivity-support flags directly from
# the already-frozen sensitivity ledger. Step3C wrote these flags only to
# its dedicated PRIMARY25 table, not to the 330-row sensitivity ledger.
# This is deterministic terminal bookkeeping, NOT statistical recomputation.
final25$primary25_sensitivity_same_sign <- (
  is.finite(final25$gse240921_log2FC) &
  is.finite(final25$sensitivity_log2FC) &
  sign(final25$gse240921_log2FC) ==
    sign(final25$sensitivity_log2FC)
)
final25$primary25_sensitivity_nominal_p_lt_0_05 <- (
  is.finite(final25$sensitivity_pvalue) &
  final25$sensitivity_pvalue < 0.05
)
final25$primary25_sensitivity_strict_FDR_support <-
  as.logical(final25$sensitivity_strict_replicated)

must(sum(final25$primary25_sensitivity_same_sign)==25L,
     "Reconstructed Primary25 same-sign count differs from Step3C gate")
must(sum(final25$primary25_sensitivity_nominal_p_lt_0_05)==24L,
     "Reconstructed Primary25 nominal-support count differs from Step3C gate")
must(sum(final25$primary25_sensitivity_strict_FDR_support)==22L,
     "Reconstructed Primary25 strict-support count differs from Step3C gate")

# Pull ASHR effect columns from accepted Step3B ledger.
am <- match(final25$r0_gene_id,ash$r0_gene_id)
must(all(!is.na(am)),"Primary25 missing from ASHR ledger")

final25$ashr_log2FC <- ash$ashr_log2FC[am]
final25$ashr_lfcSE <- ash$ashr_lfcSE[am]
final25$ashr_finite <- as.logical(ash$ashr_finite[am])
final25$unshrunk_vs_ashr_sign_concordant <-
  as.logical(ash$unshrunk_vs_ashr_sign_concordant[am])

final25$terminal_primary_status <- "PRIMARY_STRICT_REPLICATED"
final25$terminal_sex_sensitivity_status <- ifelse(
  final25$sensitivity_status=="SENS_WALD_P_NONFINITE_PAD_P1",
  "SENSITIVITY_NONASSESSABLE_COOKS_PAD_P1",
  ifelse(
    as.logical(final25$sensitivity_strict_replicated),
    "SENSITIVITY_STRICT_SUPPORTED",
    ifelse(
      is.finite(final25$sensitivity_pvalue) &
      final25$sensitivity_pvalue<0.05 &
      as.logical(final25$primary25_sensitivity_same_sign),
      "SENSITIVITY_DIRECTION_PLUS_NOMINAL_ONLY",
      "SENSITIVITY_DIRECTION_ONLY"
    )
  )
)

final25 <- final25[order(
  final25$primary_BH_FDR_330,
  -abs(final25$ashr_log2FC),
  final25$r0_gene_id
),,drop=FALSE]
awrite(final25,OUT_FINAL25)

# Sensitivity-only strict genes are informative only and cannot enter primary25.
sens_only <- sen[
  as.logical(sen$sensitivity_strict_replicated) &
  !as.logical(sen$primary_replicated),
  ,
  drop=FALSE
]
if(nrow(sens_only)>0L) {
  sens_only <- sens_only[order(
    sens_only$sensitivity_BH_FDR_330,
    -abs(sens_only$sensitivity_log2FC),
    sens_only$r0_gene_id
  ),,drop=FALSE]
}
awrite(sens_only,OUT_SENS_ONLY)

# Key support classes among frozen primary25.
n_sens_strict25 <- sum(as.logical(final25$sensitivity_strict_replicated))
n_nominal25 <- sum(
  is.finite(final25$sensitivity_pvalue) &
  final25$sensitivity_pvalue<0.05 &
  as.logical(final25$primary25_sensitivity_same_sign)
)
n_cooks25 <- sum(
  final25$terminal_sex_sensitivity_status==
    "SENSITIVITY_NONASSESSABLE_COOKS_PAD_P1"
)
n_nominal_only25 <- sum(
  final25$terminal_sex_sensitivity_status==
    "SENSITIVITY_DIRECTION_PLUS_NOMINAL_ONLY"
)
n_direction_only25 <- sum(
  final25$terminal_sex_sensitivity_status==
    "SENSITIVITY_DIRECTION_ONLY"
)

must(n_sens_strict25==22L,"Expected 22/25 strict sex-sensitivity support")
must(n_nominal25==24L,"Expected 24/25 nominal sex-sensitivity support")
must(n_cooks25==1L,"Expected one primary25 Cook-filtered sensitivity gene")
must(n_nominal_only25==2L,"Expected two primary25 nominal-only sensitivity genes")
must(n_direction_only25==0L,"Unexpected primary25 direction-only sensitivity gene")
must(nrow(sens_only)==1L,
     "Expected exactly one sensitivity-only strict gene outside primary25")

summary <- data.frame(
  metric=c(
    "dataset",
    "primary_contrast",
    "primary_model",
    "primary_candidate_family",
    "primary_assessable",
    "primary_strict_replicated",
    "ashr_mapped_sign_discordant",
    "ashr_primary25_sign_discordant",
    "sex_sensitivity_model",
    "sex_sensitivity_assessable_of_primary256",
    "sex_sensitivity_strict_replicated_full330",
    "PRIMARY25_same_sign_in_sex_sensitivity",
    "PRIMARY25_nominal_support_in_sex_sensitivity",
    "PRIMARY25_strict_FDR_support_in_sex_sensitivity",
    "PRIMARY25_Cooks_filtered_in_sex_sensitivity",
    "PRIMARY25_nominal_only_in_sex_sensitivity",
    "sensitivity_only_strict_not_added_to_primary",
    "primary25_status_modified",
    "statistical_recomputation_in_terminal_step",
    "R1_status"
  ),
  value=c(
    "GSE240921",
    "DECOMPENSATED_vs_COMPENSATED",
    "~ technical_batch + clinical_state",
    330,
    256,
    25,
    0,
    0,
    "~ technical_batch + sex + clinical_state",
    255,
    23,
    25,
    24,
    22,
    1,
    2,
    nrow(sens_only),
    "NO",
    "NO",
    "FINAL_FROZEN"
  ),
  stringsAsFactors=FALSE
)
awrite(summary,OUT_SUM)

twrite(c(
  "R1_GSE240921_FINAL_FROZEN",
  paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
  "dataset=GSE240921",
  "role=CROSS_COHORT_PAH_VALIDATION",
  "human_RV_samples=40",
  "normal_control=13",
  "compensated=14",
  "decompensated=13",
  "primary_model=~ technical_batch + clinical_state",
  "primary_contrast=DECOMPENSATED_vs_COMPENSATED",
  "primary_candidate_family=R0_FROZEN_330",
  "primary_assessable=256",
  "primary_FDR=BH_FULL_330_PADDED",
  "primary_alpha=0.05",
  "primary_direction_requirement=SAME_UNSHRUNKEN_SIGN_AS_R0",
  "PRIMARY_STRICT_REPLICATED=25",
  "ashr_role=EFFECT_SIZE_AND_RANKING_ONLY",
  "ashr_mapped_sign_discordant=0",
  "ashr_primary25_sign_discordant=0",
  "sex_sensitivity_model=~ technical_batch + sex + clinical_state",
  "sex_sensitivity_assessable=255",
  "sex_sensitivity_strict_replicated_full330=23",
  "PRIMARY25_same_sign_sex_sensitivity=25",
  "PRIMARY25_nominal_support_sex_sensitivity=24",
  "PRIMARY25_strict_FDR_support_sex_sensitivity=22",
  paste0("sex_sensitivity_nonfinite_gene=",diag$r0_gene_id[1]),
  paste0("sex_sensitivity_nonfinite_diagnostic=",cook_class),
  "sex_sensitivity_nonfinite_action=PAD_P1_NO_RESCUE",
  "PRIMARY25_nominal_only_sex_sensitivity=2",
  paste0("sensitivity_only_strict_genes=",nrow(sens_only)),
  "sensitivity_only_genes_added_to_primary=NO",
  "primary25_modified_by_sensitivity=NO",
  "terminal_statistical_recomputation=NO",
  "status=FINAL_FROZEN",
  "next_stage=GSE198618 supporting PAH replication preflight; patient overlap remains UNKNOWN"
),OUT_GATE)

logline("PRIMARY25 frozen=25")
logline("Sex sensitivity: 22 strict + 2 nominal-only + 1 Cook-filtered, all 25 same sign")
logline("Sensitivity-only strict outside primary25=",nrow(sens_only)," (not added)")
logline("Nonfinite sensitivity gene=",diag$r0_gene_id[1],
        "; class=",cook_class)
logline("FINAL_GATE: R1_GSE240921_FINAL_FROZEN")
quit(save="no",status=0,runLast=FALSE)
