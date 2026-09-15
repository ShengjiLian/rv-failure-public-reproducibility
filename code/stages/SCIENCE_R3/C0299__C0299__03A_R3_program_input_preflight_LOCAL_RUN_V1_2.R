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
# RV Project — R3 Step 3A V1.2
# PROGRAM-LEVEL INPUT / AUTHORITY PREFLIGHT — FIG5C LFC-HEADER TECHNICAL REPAIR
#
# REPAIR SCOPE
#   - V1.0 stopped cleanly because Fig5c gene-identity headers differ from Fig4/ED4.
#   - V1.1 resolved gene-identity header semantics but still assumed an oriented LFC header.
#   - V1.2 accepts the observed author Fig5c column name 'log2FoldChange' while
#     independently verifying contrast/orientation from the already-frozen Step1B gate.
#   - Scientific inputs, thresholds, contrasts, authorities and downstream boundaries are unchanged.
#
# PURPOSE
#   Read-only preflight before ANY program/pathway analysis.
#   This step:
#     1) re-verifies frozen upstream authorities without refitting any model;
#     2) inventories R0/R1 failure evidence suitable for later program analysis;
#     3) extracts the full published Fig5c author-statistics table (NO recomputation);
#     4) reuses the already frozen ED Fig4b same-site author-statistics table;
#     5) quantifies mapping coverage of the frozen R0 330 genes into R3 authorities;
#     6) freezes authority roles for the NEXT contract-adjudication gate.
#
# IT DOES NOT:
#   - fit DESeq2 / limma / edgeR;
#   - recompute any p-value or FDR;
#   - run GSEA / ORA / GSVA / fgsea / clusterProfiler;
#   - select pathways or gene sets;
#   - classify any molecular program as reversal/persistent/worsening;
#   - use GSE291508 healthy controls;
#   - use R2 genome-wide results to add genes/programs;
#   - alter R0/R1/R2/R3 Step0-Step2 frozen results.
# ==============================================================================

options(stringsAsFactors=FALSE, warn=1)

ROOT <- normalizePath(getwd(), winslash="/", mustWork=TRUE)
if(!identical(tolower(ROOT),tolower(RV_PROJECT_ROOT))) {
  stop("Expected working directory D:/RV_project; observed: ",ROOT)
}

if(!requireNamespace("readxl",quietly=TRUE)) {
  stop("Package 'readxl' is required. No package installation is performed automatically.")
}

R0RES <- file.path(ROOT,"results","R0","v4_LOCAL_RUN")
R1RES <- file.path(ROOT,"results","R1_GSE240921")
R3RES <- file.path(ROOT,"results","R3_GSE249696")
AUTH3 <- file.path(ROOT,"data","authority","GSE249696")
LOGD  <- file.path(ROOT,"logs")
dir.create(R3RES,recursive=TRUE,showWarnings=FALSE)
dir.create(LOGD,recursive=TRUE,showWarnings=FALSE)

# Frozen authorities only.
R0_GATE   <- file.path(R0RES,"R0_EXACT_R0_PRIMARY_RESULTS_FROZEN.txt")
R0_ASSESS <- file.path(R0RES,"R0_FINAL_RVF_vs_pRV_assessable_results.csv")
R0_SIG    <- file.path(R0RES,"R0_FINAL_RVF_vs_pRV_FDR05.csv")

R1_GATE   <- file.path(R1RES,"R1_GSE240921_R1_FINAL_FROZEN.txt")
R1_LEDGER <- file.path(R1RES,"R1_GSE240921_R0_330_primary_replication_ledger.csv")

R3_FIG5_GATE <- file.path(R3RES,"R3_STEP1B_FIG5_SOURCE_AUTHORITY_FROZEN.txt")
R3_FIG5_XLSX <- file.path(AUTH3,"44161_2025_672_MOESM7_ESM.xlsx")
R3_ED4_GATE  <- file.path(R3RES,"R3_STEP1D_FIG4_ED4_SOURCE_AUTHORITY_FROZEN.txt")
R3_ED4_ALL   <- file.path(R3RES,"R3_STEP1D_ED4b_same_site_author_stats_minimal.csv.gz")
R3_STEP2     <- file.path(R3RES,"R3_STEP2_CORE_GENE_CLASSIFICATION_PASS.txt")

OUT_AUD   <- file.path(R3RES,"R3_STEP3A_program_input_authority_audit.csv")
OUT_ROLES <- file.path(R3RES,"R3_STEP3A_program_authority_roles.csv")
OUT_MAIN  <- file.path(R3RES,"R3_STEP3A_FIG5c_author_stats_minimal.csv.gz")
OUT_MAP   <- file.path(R3RES,"R3_STEP3A_R0_330_R3_mapping_coverage.csv")
OUT_PASS  <- file.path(R3RES,"R3_STEP3A_PROGRAM_INPUT_PREFLIGHT_PASS.txt")
OUT_HOLD  <- file.path(R3RES,"R3_STEP3A_PROGRAM_INPUT_PREFLIGHT_HOLD.txt")
LOG       <- file.path(LOGD,"R3_STEP3A_PROGRAM_INPUT_PREFLIGHT.log")

if(file.exists(LOG)) {
  old <- file.path(
    LOGD,
    paste0("R3_STEP3A_PROGRAM_INPUT_PREFLIGHT_",
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

replace_file <- function(tmp,dest) {
  if(file.exists(dest)) unlink(dest,force=TRUE)
  if(!file.rename(tmp,dest)) {
    unlink(tmp,force=TRUE)
    stop("Atomic file replacement failed: ",dest)
  }
}
awrite <- function(x,p) {
  t <- paste0(p,".tmp_",Sys.getpid())
  write.csv(x,t,row.names=FALSE,na="")
  replace_file(t,p)
}
gzwrite <- function(x,p) {
  t <- paste0(p,".tmp_",Sys.getpid())
  con <- gzfile(t,"wt")
  write.csv(x,con,row.names=FALSE,na="")
  close(con)
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
          if(nzchar(notes)) paste0(" | ",notes) else "")
}
flush_audit <- function() {
  if(length(A)) awrite(do.call(rbind,A),OUT_AUD)
}

hold <- function(reason,code=201L) {
  flush_audit()
  twrite(c(
    "R3_STEP3A_PROGRAM_INPUT_PREFLIGHT_HOLD",
    paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
    paste0("reason=",reason),
    "statistical_model_fit=NO",
    "pvalue_recomputation=NO",
    "FDR_recomputation=NO",
    "GSEA_ORA_GSVA_executed=NO",
    "program_classification_executed=NO",
    "upstream_frozen_results_modified=NO",
    paste0("log=",LOG)
  ),OUT_HOLD)
  logline("FINAL_GATE: R3_STEP3A_PROGRAM_INPUT_PREFLIGHT_HOLD | ",reason)
  quit(save="no",status=code,runLast=FALSE)
}

options(error=function() {
  msg <- geterrmessage()
  try(logline("[UNHANDLED_R_ERROR] ",gsub("[\r\n]+"," | ",msg)),silent=TRUE)
  try(flush_audit(),silent=TRUE)
  try(twrite(c(
    "R3_STEP3A_PROGRAM_INPUT_PREFLIGHT_HOLD_RUNTIME_ERROR",
    paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
    paste0("error=",gsub("[\r\n]+"," | ",msg)),
    "statistical_model_fit=NO",
    "pvalue_recomputation=NO",
    "FDR_recomputation=NO",
    "GSEA_ORA_GSVA_executed=NO",
    "program_classification_executed=NO",
    "upstream_frozen_results_modified=NO"
  ),OUT_HOLD),silent=TRUE)
  q(save="no",status=202,runLast=FALSE)
})

logline("============================================================")
logline("R3 Step3A — PROGRAM INPUT / AUTHORITY PREFLIGHT")
logline("READ-ONLY SCIENTIFIC PREFLIGHT. NO enrichment / no program classification.")
logline("============================================================")

# --------------------------------------------------------------------------
# 1. Exact frozen-file presence
# --------------------------------------------------------------------------
needed <- c(R0_GATE,R0_ASSESS,R0_SIG,R1_GATE,R1_LEDGER,
            R3_FIG5_GATE,R3_FIG5_XLSX,R3_ED4_GATE,R3_ED4_ALL,R3_STEP2)
for(p in needed) {
  ok <- file.exists(p)
  add(paste0("file_exists:",basename(p)),"YES",if(ok)"YES" else "NO",
      if(ok)"PASS" else "FAIL")
}
if(any(!file.exists(needed))) hold("MISSING_FROZEN_INPUT",203L)

# --------------------------------------------------------------------------
# 2. Frozen gate identity
# --------------------------------------------------------------------------
first_nonempty <- function(p) {
  z <- readLines(p,warn=FALSE,encoding="UTF-8")
  z <- trimws(z)
  z <- z[nzchar(z)]
  if(length(z)) z[1] else ""
}
add("R0 gate identity","R0_EXACT_R0_PRIMARY_RESULTS_FROZEN",
    first_nonempty(R0_GATE),
    if(first_nonempty(R0_GATE)=="R0_EXACT_R0_PRIMARY_RESULTS_FROZEN")"PASS" else "FAIL")
add("R1 gate identity","R1_GSE240921_FINAL_FROZEN",
    first_nonempty(R1_GATE),
    if(first_nonempty(R1_GATE)=="R1_GSE240921_FINAL_FROZEN")"PASS" else "FAIL")
add("R3 Fig5 authority gate identity","R3_STEP1B_FIG5_SOURCE_AUTHORITY_FROZEN",
    first_nonempty(R3_FIG5_GATE),
    if(first_nonempty(R3_FIG5_GATE)=="R3_STEP1B_FIG5_SOURCE_AUTHORITY_FROZEN")"PASS" else "FAIL")
add("R3 ED4 authority gate identity","R3_STEP1D_FIG4_ED4_SOURCE_AUTHORITY_FROZEN",
    first_nonempty(R3_ED4_GATE),
    if(first_nonempty(R3_ED4_GATE)=="R3_STEP1D_FIG4_ED4_SOURCE_AUTHORITY_FROZEN")"PASS" else "FAIL")
add("R3 Step2 gate identity","R3_STEP2_CORE_GENE_CLASSIFICATION_PASS",
    first_nonempty(R3_STEP2),
    if(first_nonempty(R3_STEP2)=="R3_STEP2_CORE_GENE_CLASSIFICATION_PASS")"PASS" else "FAIL")
if(any(vapply(A,function(x) any(x$status=="FAIL"),logical(1)))) hold("FROZEN_GATE_IDENTITY_MISMATCH",204L)

# Step2 guards: exact accepted counts and wording protections.
step2 <- readLines(R3_STEP2,warn=FALSE,encoding="UTF-8")
for(kv in c(
  "REVERSAL_SUPPORTED=2",
  "MALADAPTIVE_NONREVERSAL_WORSENING_SUPPORTED=2",
  "SITE_CONFLICT=1",
  "MAIN_ONLY_UNRESOLVED=0",
  "INDETERMINATE_NO_MAIN_DEG=20",
  "UNASSESSABLE=0",
  "nonsignificance_interpreted_as_persistence=NO",
  "irreversible_wording_used=NO",
  "statistical_model_fit=NO",
  "pvalue_recomputation=NO",
  "FDR_recomputation=NO"
)) {
  ok <- kv %in% step2
  add(paste0("Step2 frozen invariant:",sub("=.*$","",kv)),kv,
      if(ok)kv else "<MISSING_OR_CHANGED>",if(ok)"PASS" else "FAIL")
}
if(any(vapply(A,function(x) any(x$status=="FAIL"),logical(1)))) hold("STEP2_FROZEN_INVARIANT_MISMATCH",205L)

# --------------------------------------------------------------------------
# 3. R0 / R1 frozen failure evidence
# --------------------------------------------------------------------------
r0a <- read.csv(R0_ASSESS,stringsAsFactors=FALSE,check.names=FALSE)
r0s <- read.csv(R0_SIG,stringsAsFactors=FALSE,check.names=FALSE)
r1  <- read.csv(R1_LEDGER,stringsAsFactors=FALSE,check.names=FALSE)

req_r0 <- c("gene_id","assessable","log2FoldChange","pvalue","padj",
            "ashr_log2FoldChange","primary_FDR_lt_0_05")
req_r1 <- c("r0_gene_id","r0_log2FC","r0_direction","mapping_status",
            "gse240921_log2FC","gse240921_pvalue","primary_assessability",
            "primary_p_for_BH330","primary_BH_FDR_330",
            "direction_concordant","primary_replicated")
miss0 <- setdiff(req_r0,names(r0a))
miss1 <- setdiff(req_r1,names(r1))
add("R0 assessable required columns","NONE",
    if(length(miss0))paste(miss0,collapse=";") else "NONE",
    if(!length(miss0))"PASS" else "FAIL")
add("R1 330-ledger required columns","NONE",
    if(length(miss1))paste(miss1,collapse=";") else "NONE",
    if(!length(miss1))"PASS" else "FAIL")
if(length(miss0)||length(miss1)) hold("R0_R1_SCHEMA_MISMATCH",206L)

add("R0 assessable rows","18621",nrow(r0a),if(nrow(r0a)==18621L)"PASS" else "FAIL")
add("R0 frozen DEG rows","330",nrow(r0s),if(nrow(r0s)==330L)"PASS" else "FAIL")
add("R0 DEG unique gene symbols","330",length(unique(r0s$gene_id)),
    if(length(unique(r0s$gene_id))==330L)"PASS" else "FAIL")
r0_up <- sum(r0s$log2FoldChange>0,na.rm=TRUE)
r0_dn <- sum(r0s$log2FoldChange<0,na.rm=TRUE)
add("R0 DEG unshrunk direction UP","314",r0_up,if(r0_up==314L)"PASS" else "FAIL")
add("R0 DEG unshrunk direction DOWN","16",r0_dn,if(r0_dn==16L)"PASS" else "FAIL")

add("R1 candidate-ledger rows","330",nrow(r1),if(nrow(r1)==330L)"PASS" else "FAIL")
r1_assess <- sum(r1$primary_assessability=="ASSESSABLE_WALD_FINITE",na.rm=TRUE)
r1_rep <- sum(as.logical(r1$primary_replicated),na.rm=TRUE)
add("R1 primary assessable","256",r1_assess,if(r1_assess==256L)"PASS" else "FAIL")
add("R1 strict replicated","25",r1_rep,if(r1_rep==25L)"PASS" else "FAIL")
set_ok <- identical(sort(as.character(r0s$gene_id)),sort(as.character(r1$r0_gene_id)))
add("R0 330 vs R1 330 exact gene set","YES",if(set_ok)"YES" else "NO",
    if(set_ok)"PASS" else "FAIL")

# R0 direction cross-check carried into R1 ledger; R0 authority remains UNSHRUNKEN.
m <- match(r1$r0_gene_id,r0s$gene_id)
cross_ok <- all(!is.na(m)) &&
            all(abs(r1$r0_log2FC - r0s$log2FoldChange[m]) <= 1e-12)
maxdiff <- if(all(!is.na(m))) max(abs(r1$r0_log2FC-r0s$log2FoldChange[m]),na.rm=TRUE) else Inf
add("R0 unshrunk LFC carried into R1 ledger","330/330 exact within 1e-12",
    paste0("mapped=",sum(!is.na(m)),"; max_abs_diff=",format(maxdiff,digits=16)),
    if(cross_ok)"PASS" else "FAIL")

if(any(vapply(A,function(x) any(x$status=="FAIL"),logical(1)))) hold("R0_R1_FROZEN_AUTHORITY_DRIFT",207L)

# --------------------------------------------------------------------------
# 4. Parse FULL published Fig5c author statistics; NO inference recomputation
#    V1.1 technical repair:
#    Fig5c does not use the same two gene-identity header labels as Fig4/ED4.
#    Therefore gene-symbol identity is resolved deterministically from the
#    already-frozen R1 Primary25 exact symbol set, BEFORE any program analysis.
#    This changes parsing only; no scientific threshold or statistic changes.
# --------------------------------------------------------------------------
sheets <- readxl::excel_sheets(R3_FIG5_XLSX)
add("Fig5c sheet present","YES",if("Fig 5c" %in% sheets)"YES" else "NO",
    if("Fig 5c" %in% sheets)"PASS" else "FAIL")
if(!("Fig 5c" %in% sheets)) hold("FIG5C_SHEET_MISSING",208L)

x <- suppressMessages(
  readxl::read_excel(R3_FIG5_XLSX,sheet="Fig 5c",col_names=TRUE,.name_repair="minimal")
)
names(x) <- trimws(names(x))

# Record the actual author headers so this parsing repair is fully auditable.
add("Fig5c source headers","REPORT_ONLY",
    paste(names(x),collapse=" | "),"INFO",
    "Author workbook headers recorded verbatim; no header renamed in source.")

# Numeric/statistical columns remain exact invariant labels.
exact_required <- c("baseMean","pvalue","padj")
miss <- setdiff(exact_required,names(x))
add("Fig5c invariant numeric columns","NONE",
    if(length(miss))paste(miss,collapse=";") else "NONE",
    if(!length(miss))"PASS" else "FAIL")
if(length(miss)) hold("FIG5C_NUMERIC_SCHEMA_MISMATCH",209L)

# Fig5c author workbook uses a generic effect column name: "log2FoldChange".
# Do NOT infer biological orientation from that bare header. Instead, verify the
# already-frozen Step1B authority text and then use the generic author effect column.
parse_kv <- function(path) {
  z <- readLines(path,warn=FALSE,encoding="UTF-8")
  z <- z[nzchar(trimws(z)) & grepl("=",z,fixed=TRUE)]
  out <- sub("^[^=]*=","",z)
  names(out) <- sub("=.*$","",z)
  out
}
fig5gate <- parse_kv(R3_FIG5_GATE)

contrast_ok <- "overall_contrast" %in% names(fig5gate) &&
               identical(unname(fig5gate[["overall_contrast"]]),
                         "B-postPEA_septum_vs_B-prePEA_RV")
orientation_ok <- "overall_orientation" %in% names(fig5gate) &&
                  identical(unname(fig5gate[["overall_orientation"]]),
                            "POST_MINUS_PRE")
design_ok <- "overall_anatomical_design" %in% names(fig5gate) &&
             identical(unname(fig5gate[["overall_anatomical_design"]]),
                       "POST_SEPTUM_MINUS_PRE_RV_FREE_WALL")
confound_ok <- "site_confound_complete" %in% names(fig5gate) &&
               identical(unname(fig5gate[["site_confound_complete"]]),"YES")

add("Fig5c frozen Step1B contrast",
    "B-postPEA_septum_vs_B-prePEA_RV",
    if("overall_contrast" %in% names(fig5gate))
      unname(fig5gate[["overall_contrast"]]) else "<MISSING>",
    if(contrast_ok)"PASS" else "FAIL")
add("Fig5c frozen Step1B orientation",
    "POST_MINUS_PRE",
    if("overall_orientation" %in% names(fig5gate))
      unname(fig5gate[["overall_orientation"]]) else "<MISSING>",
    if(orientation_ok)"PASS" else "FAIL")
add("Fig5c frozen Step1B anatomical design",
    "POST_SEPTUM_MINUS_PRE_RV_FREE_WALL",
    if("overall_anatomical_design" %in% names(fig5gate))
      unname(fig5gate[["overall_anatomical_design"]]) else "<MISSING>",
    if(design_ok)"PASS" else "FAIL")
add("Fig5c frozen Step1B site confound",
    "YES",
    if("site_confound_complete" %in% names(fig5gate))
      unname(fig5gate[["site_confound_complete"]]) else "<MISSING>",
    if(confound_ok)"PASS" else "FAIL")

if(!(contrast_ok && orientation_ok && design_ok && confound_ok)) {
  hold("FIG5C_FROZEN_ORIENTATION_AUTHORITY_MISMATCH",210L)
}

lfc_col <- "log2FoldChange"
lfc_hits <- names(x)[names(x)==lfc_col]
add("Fig5c author LFC value column",
    "log2FoldChange",
    if(length(lfc_hits)==1L) lfc_hits else paste(lfc_hits,collapse=";"),
    if(length(lfc_hits)==1L)"PASS" else "FAIL",
    "Biological orientation is supplied by frozen Step1B authority, not inferred from this generic header.")
if(length(lfc_hits)!=1L) hold("FIG5C_LFC_VALUE_COLUMN_UNRESOLVED",211L)

# Frozen Primary25 comes ONLY from the already accepted R1 ledger.
p25_frozen <- as.character(r1$r0_gene_id[as.logical(r1$primary_replicated)])
must(length(p25_frozen)==25L && length(unique(p25_frozen))==25L,
     "Frozen R1 Primary25 derivation failed unexpectedly")

# Resolve the author gene-symbol column by exact membership of all frozen P25.
# This is a representation/header repair, NOT a biological mapping expansion.
symbol_hits <- vapply(names(x),function(cc) {
  v <- trimws(as.character(x[[cc]]))
  length(intersect(unique(v[nzchar(v)]),p25_frozen))
},integer(1))

symbol_candidates <- names(symbol_hits)[symbol_hits==25L]
add("Fig5c gene-symbol column candidates by frozen Primary25 exact hits",
    "EXACTLY_ONE_COLUMN_WITH_25_OF_25",
    if(length(symbol_candidates)) paste(symbol_candidates,collapse=" | ") else "<NONE>",
    if(length(symbol_candidates)==1L)"PASS" else "FAIL",
    paste0("max_P25_hits=",max(symbol_hits,na.rm=TRUE)))
if(length(symbol_candidates)!=1L) {
  hold("FIG5C_GENE_SYMBOL_COLUMN_UNRESOLVED",212L)
}
gene_col <- symbol_candidates[1]

# Ensembl column is provenance-supporting, not needed to define symbol mapping.
# Detect it from values rather than assuming the Fig4 header spelling.
ensg_hits <- vapply(names(x),function(cc) {
  v <- trimws(as.character(x[[cc]]))
  sum(grepl("^ENSG[0-9]+(?:\\.[0-9]+)?$",v),na.rm=TRUE)
},integer(1))
ensg_candidates <- names(ensg_hits)[ensg_hits >= 1000L]
ens_col <- if(length(ensg_candidates)==1L) ensg_candidates[1] else NA_character_

add("Fig5c Ensembl-id column discovery","REPORT_ONLY",
    if(length(ensg_candidates)) {
      paste0(paste(ensg_candidates,collapse=" | "),
             "; counts=",
             paste(ensg_hits[ensg_candidates],collapse=" | "))
    } else {
      paste0("NONE_WITH_GE1000_EXACT_ENSG_VALUES; max=",max(ensg_hits,na.rm=TRUE))
    },
    "INFO",
    "Ensembl id is provenance-supporting only; gene-symbol column is the frozen mapping authority here.")

num <- function(v) suppressWarnings(as.numeric(v))
main <- data.frame(
  source_row=seq_len(nrow(x))+1L,
  ensid=if(!is.na(ens_col)) trimws(as.character(x[[ens_col]])) else NA_character_,
  gene=trimws(as.character(x[[gene_col]])),
  baseMean=num(x[["baseMean"]]),
  log2FoldChange=num(x[[lfc_col]]),
  pvalue=num(x[["pvalue"]]),
  padj=num(x[["padj"]]),
  stringsAsFactors=FALSE
)

keep <- nzchar(main$gene) | (!is.na(main$ensid) & nzchar(main$ensid))
main <- main[keep,,drop=FALSE]

# Re-verify that the full extraction contains the frozen 25 exactly once each.
p25_counts <- table(factor(main$gene,levels=p25_frozen))
p25_unique_ok <- all(p25_counts==1L)
add("Fig5c frozen Primary25 unique mapping after V1.1 extraction",
    "25/25_EXACTLY_ONCE",
    paste0("exactly_once=",sum(p25_counts==1L),
           "; absent=",sum(p25_counts==0L),
           "; duplicated=",sum(p25_counts>1L)),
    if(p25_unique_ok)"PASS" else "FAIL")
if(!p25_unique_ok) hold("FIG5C_PRIMARY25_MAPPING_DRIFT",213L)

main$author_DEG_by_published_rule <- (
  is.finite(main$baseMean) &
  is.finite(main$log2FoldChange) &
  is.finite(main$padj) &
  main$baseMean>=5 &
  abs(main$log2FoldChange)>=0.585 &
  main$padj<=0.05
)
main$direction <- ifelse(
  main$author_DEG_by_published_rule,
  ifelse(main$log2FoldChange>0,
         "UP_POST_SEPTUM_VS_PRE_RV",
         "DOWN_POST_SEPTUM_VS_PRE_RV"),
  "NOT_DEG_BY_PUBLISHED_RULE"
)

main_deg <- sum(main$author_DEG_by_published_rule,na.rm=TRUE)
main_up  <- sum(main$author_DEG_by_published_rule & main$log2FoldChange>0,na.rm=TRUE)
main_dn  <- sum(main$author_DEG_by_published_rule & main$log2FoldChange<0,na.rm=TRUE)
add("Fig5c published-rule DEG checksum","1492",main_deg,
    if(main_deg==1492L)"PASS" else "FAIL")
add("Fig5c DEG up checksum","891",main_up,if(main_up==891L)"PASS" else "FAIL")
add("Fig5c DEG down checksum","601",main_dn,if(main_dn==601L)"PASS" else "FAIL")
if(main_deg!=1492L || main_up!=891L || main_dn!=601L) {
  hold("FIG5C_AUTHOR_CHECKSUM_MISMATCH",214L)
}

gzwrite(main,OUT_MAIN)

# --------------------------------------------------------------------------
# 5. Frozen ED Fig4b same-site author statistics
# --------------------------------------------------------------------------
same <- read.csv(gzfile(R3_ED4_ALL),stringsAsFactors=FALSE,check.names=FALSE)
req_same <- c("gene","baseMean","log2FoldChange","pvalue","padj",
              "author_DEG_by_published_rule")
miss_same <- setdiff(req_same,names(same))
add("EDFig4b minimal-table required columns","NONE",
    if(length(miss_same))paste(miss_same,collapse=";") else "NONE",
    if(!length(miss_same))"PASS" else "FAIL")
if(length(miss_same)) hold("ED4B_SCHEMA_MISMATCH",212L)

same_deg <- sum(as.logical(same$author_DEG_by_published_rule),na.rm=TRUE)
add("EDFig4b published DEG checksum","21",same_deg,if(same_deg==21L)"PASS" else "FAIL")
if(same_deg!=21L) hold("ED4B_AUTHOR_CHECKSUM_MISMATCH",213L)

# --------------------------------------------------------------------------
# 6. Quantify R0-330 mapping coverage into both R3 authorities.
#    NO gene is dropped or classified here.
# --------------------------------------------------------------------------
genes <- as.character(r0s$gene_id)
main_gene <- trimws(as.character(main$gene))
same_gene <- trimws(as.character(same$gene))

map_rows <- lapply(genes,function(g) {
  im <- which(main_gene==g)
  is <- which(same_gene==g)
  data.frame(
    gene=g,
    frozen_R0_log2FC=r0s$log2FoldChange[match(g,r0s$gene_id)],
    frozen_R0_failure_direction=ifelse(
      r0s$log2FoldChange[match(g,r0s$gene_id)]>0,
      "UP_RVF_vs_pRV","DOWN_RVF_vs_pRV"
    ),
    R1_primary_assessability=r1$primary_assessability[match(g,r1$r0_gene_id)],
    R1_direction_concordant=r1$direction_concordant[match(g,r1$r0_gene_id)],
    R1_primary_replicated=r1$primary_replicated[match(g,r1$r0_gene_id)],
    Fig5c_match_n=length(im),
    Fig5c_mapping_status=if(length(im)==0L)"NOT_PRESENT" else
                           if(length(im)==1L)"UNIQUE" else paste0("AMBIGUOUS_N",length(im)),
    EDFig4b_match_n=length(is),
    EDFig4b_mapping_status=if(length(is)==0L)"NOT_PRESENT" else
                             if(length(is)==1L)"UNIQUE" else paste0("AMBIGUOUS_N",length(is)),
    stringsAsFactors=FALSE
  )
})
mapping <- do.call(rbind,map_rows)
awrite(mapping,OUT_MAP)

main_unique <- sum(mapping$Fig5c_mapping_status=="UNIQUE")
main_missing <- sum(mapping$Fig5c_mapping_status=="NOT_PRESENT")
main_ambig <- sum(grepl("^AMBIGUOUS",mapping$Fig5c_mapping_status))
same_unique <- sum(mapping$EDFig4b_mapping_status=="UNIQUE")
same_missing <- sum(mapping$EDFig4b_mapping_status=="NOT_PRESENT")
same_ambig <- sum(grepl("^AMBIGUOUS",mapping$EDFig4b_mapping_status))

add("R0-330 -> Fig5c mapping coverage","REPORT_ONLY",
    paste0("unique=",main_unique,"; missing=",main_missing,"; ambiguous=",main_ambig),
    "INFO","No dropping/classification in Step3A")
add("R0-330 -> ED4b mapping coverage","REPORT_ONLY",
    paste0("unique=",same_unique,"; missing=",same_missing,"; ambiguous=",same_ambig),
    "INFO","No dropping/classification in Step3A")

# Ambiguous symbols are not silently collapsed. They do not invalidate this
# discovery/preflight gate, but must be adjudicated before program execution.
mapping_status <- if(main_ambig==0L && same_ambig==0L) {
  "READY_FOR_CONTRACT_WITH_QUANTIFIED_MISSINGNESS"
} else {
  "CONTRACT_REQUIRES_AMBIGUOUS_SYMBOL_ADJUDICATION"
}

# --------------------------------------------------------------------------
# 7. Freeze authority roles ONLY — not the program statistical method
# --------------------------------------------------------------------------
roles <- data.frame(
  authority=c(
    "R0_GSE345645_ASSESSABLE_18621",
    "R0_GSE345645_FDR05_330",
    "R1_GSE240921_R0_330_LEDGER",
    "R3_GSE249696_FIG5C_N21_AUTHOR_STATS",
    "R3_GSE249694_EDFIG4B_N3_SAME_SITE_AUTHOR_STATS",
    "R2_GSE198618",
    "GSE291508_HEALTHY",
    "R3_STEP2_PRIMARY25"
  ),
  role=c(
    "FROZEN_FAILURE_STATISTICAL_UNIVERSE_AVAILABLE_FOR_LATER_PROGRAM_CONTRACT",
    "FROZEN_FAILURE_ASSOCIATED_GENE_SEED",
    "CROSS_COHORT_FAILURE_REPLICATION_EVIDENCE_WITHOUT_MODEL_RERUN",
    "PRIMARY_UNLOADING_AUTHOR_STATISTICS_COMPLETE_SITE_CONFOUND",
    "SAME_PATIENT_SAME_SITE_DIRECTIONAL_SENSITIVITY_NOT_INDEPENDENT_VALIDATION",
    "NOT_USED_TO_ADD_PROGRAMS_OR_GENES_IN_STEP3A; FUTURE_SUPPORT_REQUIRES_EXPLICIT_CONTRACT",
    "RESERVED_FOR_LATER_HEALTHY_REFERENCE_SUPPORT; NOT_USED_IN_STEP3A",
    "FROZEN_GENE_LEVEL_CONTEXT_ONLY; MUST_NOT_DEFINE_PROGRAMS_BY_RESULT"
  ),
  allowed_in_step3A=c("READ","READ","READ","READ_AND_EXTRACT","READ","NO","NO","READ"),
  inferential_recomputation=c("NO","NO","NO","NO","NO","NO","NO","NO"),
  stringsAsFactors=FALSE
)
awrite(roles,OUT_ROLES)

flush_audit()

twrite(c(
  "R3_STEP3A_PROGRAM_INPUT_PREFLIGHT_PASS",
  paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
  "upstream_status=R0_R1_R2_R3_STEP0_TO_STEP2_FROZEN_UNCHANGED",
  "R0_assessable=18621",
  "R0_failure_DEG=330",
  "R0_failure_direction_authority=UNSHRUNK_RVF_vs_pRV_LOG2FC",
  "R1_candidate_family=EXACT_R0_330",
  "R1_primary_assessable=256",
  "R1_primary_strict_replicated=25",
  "R3_main_authority=FIG5C_N21_POST_SEPTUM_MINUS_PRE_RV_AUTHOR_SOURCE_DATA",
  "R3_main_site_confound_complete=YES",
  "R3_Fig5c_DEG_checksum=1492",
  "R3_same_site_authority=EXTENDED_DATA_FIG4B_N3_POST_SEPTUM_MINUS_PRE_SEPTUM",
  "R3_same_site_independent_validation=NO",
  "R3_same_site_DEG_checksum=21",
  paste0("R0_330_to_Fig5c_unique=",main_unique),
  paste0("R0_330_to_Fig5c_missing=",main_missing),
  paste0("R0_330_to_Fig5c_ambiguous=",main_ambig),
  paste0("R0_330_to_EDFig4b_unique=",same_unique),
  paste0("R0_330_to_EDFig4b_missing=",same_missing),
  paste0("R0_330_to_EDFig4b_ambiguous=",same_ambig),
  paste0("mapping_readiness=",mapping_status),
  "gene_set_database_selected=NO",
  "program_definition_frozen=NO",
  "program_significance_rule_frozen=NO",
  "program_reversal_persistence_rule_frozen=NO",
  "GSEA_executed=NO",
  "ORA_executed=NO",
  "GSVA_executed=NO",
  "statistical_model_fit=NO",
  "pvalue_recomputation=NO",
  "FDR_recomputation=NO",
  "GSE291508_used=NO",
  "R2_used_to_add_genes_or_programs=NO",
  "upstream_frozen_results_modified=NO",
  "next_stage=ChatGPT independent audit then R3 Step3B PROGRAM_ANALYSIS_CONTRACT_FREEZE"
),OUT_PASS)

if(file.exists(OUT_HOLD)) unlink(OUT_HOLD,force=TRUE)
logline("FINAL_GATE: R3_STEP3A_PROGRAM_INPUT_PREFLIGHT_PASS")
quit(save="no",status=0,runLast=FALSE)
