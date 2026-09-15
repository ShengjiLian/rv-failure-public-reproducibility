# ---- RV PUBLIC PRIMARY DAG GATE9J REWRITE V1.0 ----
# source_id=C0304
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
# RV Project — R3 Step 3D V1.1
# DETERMINISTIC PROGRAM-LEVEL GSEA EXECUTION — R1 MAPPING REPLAY REPAIR
#
# V1.0 technical HOLD:
#   - stopped BEFORE any GSEA call during R1 rank construction;
#   - Step3C had frozen R1 rank-symbol universe = 27,222;
#   - V1.0 Step3D accidentally imposed a stricter GLOBAL symbol-uniqueness
#     filter across the whole tx2gene table and retained only 25,161 rows;
#   - V1.1 replays the exact accepted Step3C mapping algorithm.
#   - No scientific threshold, pathway family, rank statistic, or classifier changes.
#
# Upstream frozen authorities:
#   Step3B V1.1 program-analysis contract
#   Step3C Hallmark + fgsea source/environment identity
#
# EXECUTION ORDER IS FIXED:
#   1. Construct deterministic frozen rank vectors.
#   2. R0: GSEA across all 50 Hallmarks.
#   3. R1: GSEA across all 50 Hallmarks.
#   4. Freeze R0/R1 stable-program family BEFORE touching R3 program results.
#   5. R3 main: GSEA only within that stable family.
#   6. R3 same-site: GSEA only within that same stable family.
#   7. Classify programs using the Step3B V1.1 frozen rules.
#
# No upstream model refit.
# No pathway addition/removal after R3 results.
# No Reactome/GO/KEGG.
# Nonsignificant main programs are never called persistent.
# "irreversible" is prohibited.
# ==============================================================================

options(stringsAsFactors=FALSE, warn=1)

ROOT <- normalizePath(getwd(), winslash="/", mustWork=TRUE)
if(!identical(tolower(ROOT),tolower(RV_PROJECT_ROOT))) {
  stop("Expected D:/RV_project; observed: ",ROOT)
}

R0 <- file.path(ROOT,"results","R0","v4_LOCAL_RUN")
R1 <- file.path(ROOT,"results","R1_GSE240921")
R3 <- file.path(ROOT,"results","R3_GSE249696")
AUTH <- file.path(ROOT,"data","authority","MSigDB")
TXDIR <- file.path(ROOT,"data","tximport","GSE345645")
LOGD <- file.path(ROOT,"logs")
dir.create(LOGD,recursive=TRUE,showWarnings=FALSE)

B11_GATE <- file.path(R3,"R3_STEP3B_V1_1_PROGRAM_ANALYSIS_CONTRACT_FROZEN.txt")
B11_METHOD <- file.path(R3,"R3_STEP3B_V1_1_program_method_contract.csv")
B11_CLASS <- file.path(R3,"R3_STEP3B_V1_1_program_classification_rules.csv")
C_GATE <- file.path(R3,"R3_STEP3C_HALLMARK_FGSEA_SOURCE_IDENTITY_FROZEN.txt")
C_MAP <- file.path(R3,"R3_STEP3C_HALLMARK_mapping_coverage.csv")
C_ENV <- file.path(R3,"R3_STEP3C_environment_versions.csv")

GMT <- file.path(AUTH,"h.all.v2026.1.Hs.symbols.gmt")
R0_FULL <- file.path(R0,"R0_FINAL_RVF_vs_pRV_assessable_results.csv")
R1_FULL <- file.path(R1,"R1_GSE240921_primary_Wald_all_genes.csv")
TX2GENE <- file.path(TXDIR,"GSE345645_transcript_to_gene.csv.gz")
R3_MAIN <- file.path(R3,"R3_STEP3A_FIG5c_author_stats_minimal.csv.gz")
R3_SAME <- file.path(R3,"R3_STEP1D_ED4b_same_site_author_stats_minimal.csv.gz")

OUT_AUD <- file.path(R3,"R3_STEP3D_V1_1_execution_audit.csv")
OUT_RANK <- file.path(R3,"R3_STEP3D_V1_1_rank_vector_audit.csv")
OUT_R0 <- file.path(R3,"R3_STEP3D_V1_1_R0_HALLMARK_GSEA.csv")
OUT_R1 <- file.path(R3,"R3_STEP3D_V1_1_R1_HALLMARK_GSEA.csv")
OUT_STABLE <- file.path(R3,"R3_STEP3D_V1_1_R0_R1_STABLE_PROGRAMS.csv")
OUT_MAIN <- file.path(R3,"R3_STEP3D_V1_1_R3_MAIN_STABLE_PROGRAM_GSEA.csv")
OUT_SAME <- file.path(R3,"R3_STEP3D_V1_1_R3_SAME_SITE_STABLE_PROGRAM_GSEA.csv")
OUT_CLASS <- file.path(R3,"R3_STEP3D_V1_1_PROGRAM_CLASSIFICATION.csv")
OUT_SUM <- file.path(R3,"R3_STEP3D_V1_1_PROGRAM_CLASS_SUMMARY.csv")
OUT_PASS <- file.path(R3,"R3_STEP3D_V1_1_DETERMINISTIC_PROGRAM_EXECUTION_PASS.txt")
OUT_HOLD <- file.path(R3,"R3_STEP3D_V1_1_DETERMINISTIC_PROGRAM_EXECUTION_HOLD.txt")
LOG <- file.path(LOGD,"R3_STEP3D_V1_1_DETERMINISTIC_PROGRAM_EXECUTION.log")

if(file.exists(LOG)) {
  old <- file.path(LOGD,paste0(
    "R3_STEP3D_V1_1_DETERMINISTIC_PROGRAM_EXECUTION_",
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
    unlink(tmp,force=TRUE)
    stop("Atomic replacement failed: ",dest)
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
    item=as.character(item), expected=as.character(expected),
    observed=as.character(observed), status=as.character(status),
    notes=as.character(notes), stringsAsFactors=FALSE
  )
  logline("[",status,"] ",item,
          " | expected=",expected," | observed=",observed,
          if(nzchar(notes)) paste0(" | ",notes) else "")
}
flush_audit <- function() if(length(A)) awrite(do.call(rbind,A),OUT_AUD)

hold <- function(reason,code=241L) {
  flush_audit()
  twrite(c(
    "R3_STEP3D_V1_1_DETERMINISTIC_PROGRAM_EXECUTION_HOLD",
    paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
    paste0("reason=",reason),
    "upstream_model_refit=NO",
    "upstream_frozen_results_modified=NO",
    "pathway_collection_changed=NO",
    "automatic_rerun_allowed=NO",
    paste0("log=",LOG)
  ),OUT_HOLD)
  logline("FINAL_GATE: HOLD | ",reason)
  quit(save="no",status=code,runLast=FALSE)
}

options(error=function() {
  msg <- geterrmessage()
  try(logline("[UNHANDLED_R_ERROR] ",gsub("[\r\n]+"," | ",msg)),silent=TRUE)
  try(flush_audit(),silent=TRUE)
  try(twrite(c(
    "R3_STEP3D_V1_1_DETERMINISTIC_PROGRAM_EXECUTION_HOLD_RUNTIME_ERROR",
    paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
    paste0("error=",gsub("[\r\n]+"," | ",msg)),
    "automatic_rerun_allowed=NO",
    "upstream_model_refit=NO"
  ),OUT_HOLD),silent=TRUE)
  q(save="no",status=242,runLast=FALSE)
})

parse_kv <- function(p) {
  z <- readLines(p,warn=FALSE,encoding="UTF-8")
  z <- z[nzchar(trimws(z)) & grepl("=",z,fixed=TRUE)]
  out <- sub("^[^=]*=","",z)
  names(out) <- sub("=.*$","",z)
  out
}
sha256_file <- function(p) {
  if(!requireNamespace("digest",quietly=TRUE))
    stop("digest is required and must already be installed from Step3C.")
  digest::digest(file=p,algo="sha256",serialize=FALSE)
}
read_gmt <- function(p) {
  z <- readLines(p,warn=FALSE,encoding="UTF-8")
  spl <- strsplit(z,"\t",fixed=TRUE)
  nm <- vapply(spl,`[`,character(1),1)
  pathways <- lapply(spl,function(x) unique(x[-c(1,2)]))
  names(pathways) <- nm
  pathways
}
flatten_le <- function(x) {
  if(is.null(x) || length(x)==0L) return("")
  paste(as.character(x),collapse=";")
}
normalize_fgsea <- function(x, family_size_expected, label) {
  x <- as.data.frame(x,stringsAsFactors=FALSE)
  if(!"pathway" %in% names(x)) stop(label,": fgsea result lacks pathway")
  x$pathway <- as.character(x$pathway)
  if(nrow(x)!=family_size_expected || length(unique(x$pathway))!=family_size_expected)
    stop(label,": fgsea result family-size mismatch")
  if(any(!is.finite(x$NES)) || any(!is.finite(x$pval)))
    stop(label,": nonfinite NES/pval")
  x$BH_FDR_frozen_family <- p.adjust(x$pval,method="BH")
  if("leadingEdge" %in% names(x))
    x$leadingEdge <- vapply(x$leadingEdge,flatten_le,character(1))
  x[order(x$pathway),,drop=FALSE]
}

# Deterministic input order within exact rank ties:
# primary rank descending; secondary |log2FC| descending; tertiary symbol ascending.
# Rank numeric values are NOT jittered or altered.
make_rank <- function(gene,score,lfc,label,expected_n) {
  gene <- trimws(as.character(gene))
  score <- suppressWarnings(as.numeric(score))
  lfc <- suppressWarnings(as.numeric(lfc))
  ok <- !is.na(gene) & nzchar(gene) & is.finite(score) & is.finite(lfc)
  d <- data.frame(gene=gene[ok],score=score[ok],lfc=lfc[ok],
                  stringsAsFactors=FALSE)
  if(nrow(d)!=expected_n)
    stop(label,": expected ",expected_n," finite unique-symbol rows; got ",nrow(d))
  if(anyDuplicated(d$gene))
    stop(label,": duplicate gene symbols remain after frozen mapping")
  d <- d[order(-d$score,-abs(d$lfc),d$gene),,drop=FALSE]
  v <- d$score
  names(v) <- d$gene
  tie_tab <- table(v)
  list(
    stats=v,
    n=nrow(d),
    tie_groups=sum(tie_tab>1L),
    tied_genes=sum(tie_tab[tie_tab>1L]),
    zeros=sum(v==0),
    min=min(v),
    max=max(v)
  )
}

signed_z <- function(p,lfc) {
  p <- suppressWarnings(as.numeric(p))
  lfc <- suppressWarnings(as.numeric(lfc))
  ok <- is.finite(p) & p>=0 & p<=1 & is.finite(lfc) & lfc!=0
  out <- rep(NA_real_,length(p))
  pp <- pmax(p[ok],1e-300)
  # Numerically stable upper-tail form; avoids 1 - tiny_p rounding to exactly 1.
  z <- stats::qnorm(pp/2,lower.tail=FALSE)
  out[ok] <- sign(lfc[ok])*z
  out
}

run_fgsea <- function(pathways,stats,label) {
  set.seed(20260910)
  warns <- character()
  res <- withCallingHandlers(
    fgsea::fgseaMultilevel(
      pathways=pathways,
      stats=stats,
      minSize=10,
      maxSize=500,
      eps=0,
      scoreType="std",
      gseaParam=1,
      nproc=1
    ),
    warning=function(w) {
      warns <<- c(warns,conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  add(paste0(label," warnings"),"REPORT_ONLY",
      if(length(warns))paste(unique(warns),collapse=" || ") else "NONE",
      "INFO")
  res
}

logline("============================================================")
logline("R3 Step3D V1.1 deterministic program execution — exact Step3C R1 mapping replay")
logline("============================================================")

# --------------------------------------------------------------------------
# 0. Frozen input / environment guards
# --------------------------------------------------------------------------
needed <- c(B11_GATE,B11_METHOD,B11_CLASS,C_GATE,C_MAP,C_ENV,GMT,
            R0_FULL,R1_FULL,TX2GENE,R3_MAIN,R3_SAME)
for(p in needed) {
  ok <- file.exists(p)
  add(paste0("file_exists:",basename(p)),"YES",if(ok)"YES" else "NO",
      if(ok)"PASS" else "FAIL")
}
if(any(!file.exists(needed))) hold("MISSING_FROZEN_INPUT",243L)

# Public cold start executes the accepted V1.1 algorithm directly.
add("Historical Step3D V1.0 technical-HOLD replayed","NO","NO","PASS",
    "V1.0 pre-error audit and zero-result absence checks remain provenance only.")

b <- readLines(B11_GATE,warn=FALSE,encoding="UTF-8")
c <- parse_kv(C_GATE)
add("Step3B V1.1 gate identity",
    "R3_STEP3B_V1_1_PROGRAM_ANALYSIS_CONTRACT_FROZEN",
    trimws(b[1]),
    if(trimws(b[1])=="R3_STEP3B_V1_1_PROGRAM_ANALYSIS_CONTRACT_FROZEN")"PASS" else "FAIL")
add("Step3C gate identity",
    "R3_STEP3C_HALLMARK_FGSEA_SOURCE_IDENTITY_FROZEN",
    trimws(readLines(C_GATE,warn=FALSE,encoding="UTF-8")[1]),
    if(trimws(readLines(C_GATE,warn=FALSE,encoding="UTF-8")[1])==
       "R3_STEP3C_HALLMARK_FGSEA_SOURCE_IDENTITY_FROZEN")"PASS" else "FAIL")

must_kv <- c(
  MSigDB_version="2026.1.Hs",
  Hallmark_sets="50",
  fgsea_version="1.38.0",
  R_version="4.6.1",
  fgsea_algorithm="fgseaMultilevel",
  minSize="10",maxSize="500",eps="0",seed="20260910",nproc="1",
  R0_rank_symbols="18621",
  R1_rank_symbols="27222",
  R3_main_rank_symbols="33129",
  R3_same_site_rank_symbols="21695",
  R0_eligible_Hallmarks="50",
  R1_eligible_Hallmarks="50",
  R3_main_eligible_Hallmarks="50",
  R3_same_site_eligible_Hallmarks="50",
  GSEA_executed="NO",
  program_selection_executed="NO",
  program_classification_executed="NO"
)
for(k in names(must_kv)) {
  obs <- if(k %in% names(c))unname(c[[k]]) else "<MISSING>"
  exp <- unname(must_kv[[k]])
  add(paste0("Step3C invariant:",k),exp,obs,
      if(identical(obs,exp))"PASS" else "FAIL")
}
if(any(vapply(A,function(x) any(x$status=="FAIL"),logical(1))))
  hold("UPSTREAM_CONTRACT_OR_SOURCE_DRIFT",244L)

if(!requireNamespace("fgsea",quietly=TRUE))
  hold("FGSEA_NOT_INSTALLED_AFTER_STEP3C",245L)
if(as.character(utils::packageVersion("fgsea"))!="1.38.0")
  hold("FGSEA_VERSION_DRIFT",246L)
if(!requireNamespace("digest",quietly=TRUE))
  hold("DIGEST_NOT_INSTALLED_AFTER_STEP3C",247L)

gmt_sha <- sha256_file(GMT)
gmt_bytes <- file.info(GMT)$size
add("Hallmark GMT bytes","48686",gmt_bytes,if(gmt_bytes==48686)"PASS" else "FAIL")
add("Hallmark GMT SHA256",
    "eecaf6dad908334ae885406ec72bdc0646d8917588ed7c219fac92fc5363f596",
    gmt_sha,
    if(gmt_sha=="eecaf6dad908334ae885406ec72bdc0646d8917588ed7c219fac92fc5363f596")
      "PASS" else "FAIL")
if(gmt_bytes!=48686 ||
   gmt_sha!="eecaf6dad908334ae885406ec72bdc0646d8917588ed7c219fac92fc5363f596")
  hold("HALLMARK_GMT_IDENTITY_DRIFT",248L)

pathways <- read_gmt(GMT)
if(length(pathways)!=50L || length(unique(names(pathways)))!=50L)
  hold("HALLMARK_COLLECTION_STRUCTURE_DRIFT",249L)

# --------------------------------------------------------------------------
# 1. Construct four frozen rank vectors
# --------------------------------------------------------------------------
r0 <- read.csv(R0_FULL,stringsAsFactors=FALSE,check.names=FALSE)
need0 <- c("gene_id","stat","log2FoldChange")
if(length(setdiff(need0,names(r0)))) hold("R0_SCHEMA_DRIFT",250L)
rk0 <- make_rank(r0$gene_id,r0$stat,r0$log2FoldChange,"R0",18621L)

r1 <- read.csv(R1_FULL,stringsAsFactors=FALSE,check.names=FALSE)
need1 <- c("gse240921_gene_id","stat","log2FoldChange")
if(length(setdiff(need1,names(r1)))) hold("R1_SCHEMA_DRIFT",251L)

tx <- read.csv(gzfile(TX2GENE),stringsAsFactors=FALSE,check.names=FALSE)

# EXACT REPLAY OF ACCEPTED STEP3C R1 MAPPING:
# 1) choose the first usable frozen tx2gene Ensembl and symbol columns;
# 2) retain Ensembl IDs mapping to exactly one unique symbol;
# 3) map R1 Ensembl IDs;
# 4) among finite-stat R1 rows, retain symbols represented by exactly one R1 row.
# Crucially, DO NOT require a symbol to occur only once across the entire tx2gene
# universe. That extra global filter was the sole V1.0 Step3D implementation drift.
gc <- c("ensembl_gene_id","gene_id","ensembl_gene_id_version")
sc <- c("external_gene_name","gene_symbol","symbol")
gc <- gc[gc %in% names(tx)]
sc <- sc[sc %in% names(tx)]
if(length(gc)<1L || length(sc)<1L)
  hold("TX2GENE_MAPPING_SCHEMA_FAILURE",252L)

tx_ens <- sub("\\.[0-9]+$","",trimws(as.character(tx[[gc[1]]])))
tx_sym <- trimws(as.character(tx[[sc[1]]]))
oktx <- !is.na(tx_ens) & nzchar(tx_ens) &
        !is.na(tx_sym) & nzchar(tx_sym)
pairs <- unique(data.frame(
  ens=tx_ens[oktx],
  sym=tx_sym[oktx],
  stringsAsFactors=FALSE
))

ens_nsym <- tapply(pairs$sym,pairs$ens,function(x)length(unique(x)))
good_ens <- names(ens_nsym)[ens_nsym==1L]
one <- pairs[pairs$ens %in% good_ens,,drop=FALSE]
one <- one[!duplicated(one$ens),,drop=FALSE]

r1_ens <- sub("\\.[0-9]+$","",trimws(as.character(r1$gse240921_gene_id)))
mi <- match(r1_ens,one$ens)
r1_sym <- one$sym[mi]
r1_stat <- suppressWarnings(as.numeric(r1$stat))
r1_lfc <- suppressWarnings(as.numeric(r1$log2FoldChange))

candidate <- data.frame(
  row=seq_len(nrow(r1)),
  ens=r1_ens,
  gene=r1_sym,
  stat=r1_stat,
  log2FoldChange=r1_lfc,
  stringsAsFactors=FALSE
)
candidate <- candidate[
  !is.na(candidate$gene) & nzchar(candidate$gene) &
  is.finite(candidate$stat),
  ,drop=FALSE
]

sym_nrows <- table(candidate$gene)
unique_syms <- names(sym_nrows)[sym_nrows==1L]
r1u <- candidate[candidate$gene %in% unique_syms,,drop=FALSE]

add("R1 Step3C mapping replay rows","27222",nrow(r1u),
    if(nrow(r1u)==27222L)"PASS" else "FAIL",
    "Exact Step3C algorithm: unique symbol among finite-stat R1 rows; no global tx2gene symbol-uniqueness filter.")
if(nrow(r1u)!=27222L)
  hold("R1_STEP3C_MAPPING_REPLAY_COUNT_DRIFT",253L)

if(anyDuplicated(r1u$gene))
  hold("R1_SYMBOL_DUPLICATE_AFTER_STEP3C_REPLAY",253L)

if(any(!is.finite(r1u$log2FoldChange)))
  hold("R1_NONFINITE_LFC_WITH_FINITE_WALD_STAT",253L)

rk1 <- make_rank(
  r1u$gene,
  r1u$stat,
  r1u$log2FoldChange,
  "R1",
  27222L
)

add("R1 V1.0 erroneous retained rows","25161","25161","INFO",
    "Historical technical-HOLD observation only; not used as a scientific input.")
add("R1 mapping repair changes rank statistic","NO","NO","PASS",
    "Only representation filtering is repaired; Wald stat values are unchanged.")

rm <- read.csv(gzfile(R3_MAIN),stringsAsFactors=FALSE,check.names=FALSE)
rs <- read.csv(gzfile(R3_SAME),stringsAsFactors=FALSE,check.names=FALSE)
for(z in list(MAIN=rm,SAME=rs)) {
  if(length(setdiff(c("gene","log2FoldChange","pvalue"),names(z))))
    hold("R3_AUTHOR_SCHEMA_DRIFT",254L)
}

make_r3_unique <- function(d,label,expected_n) {
  gene <- trimws(as.character(d$gene))
  lfc <- suppressWarnings(as.numeric(d$log2FoldChange))
  p <- suppressWarnings(as.numeric(d$pvalue))
  z <- signed_z(p,lfc)
  core <- data.frame(gene=gene,score=z,lfc=lfc,stringsAsFactors=FALSE)
  core <- core[!is.na(core$gene) & nzchar(core$gene) &
               is.finite(core$score) & is.finite(core$lfc),,drop=FALSE]
  cnt <- table(core$gene)
  core <- core[cnt[core$gene]==1L,,drop=FALSE]
  if(nrow(core)!=expected_n)
    stop(label,": expected ",expected_n," finite unique symbols; got ",nrow(core))
  make_rank(core$gene,core$score,core$lfc,label,expected_n)
}
rkm <- make_r3_unique(rm,"R3_MAIN",33129L)
rks <- make_r3_unique(rs,"R3_SAME",21695L)

rank_audit <- data.frame(
  dataset=c("R0","R1","R3_MAIN","R3_SAME_SITE"),
  rank_n=c(rk0$n,rk1$n,rkm$n,rks$n),
  tie_groups=c(rk0$tie_groups,rk1$tie_groups,rkm$tie_groups,rks$tie_groups),
  tied_genes=c(rk0$tied_genes,rk1$tied_genes,rkm$tied_genes,rks$tied_genes),
  zero_rank_genes=c(rk0$zeros,rk1$zeros,rkm$zeros,rks$zeros),
  min_rank=c(rk0$min,rk1$min,rkm$min,rks$min),
  max_rank=c(rk0$max,rk1$max,rkm$max,rks$max),
  tie_policy="NUMERIC_RANK_UNCHANGED; INPUT_ORDER_WITHIN_TIES=ABS_LFC_DESC_THEN_SYMBOL_ASC",
  stringsAsFactors=FALSE
)
awrite(rank_audit,OUT_RANK)

# Verify exact Hallmark overlap counts against Step3C frozen mapping.
cov <- read.csv(C_MAP,stringsAsFactors=FALSE,check.names=FALSE)
if(nrow(cov)!=50L || anyDuplicated(cov$hallmark))
  hold("STEP3C_COVERAGE_TABLE_DRIFT",255L)
overlap_now <- function(pw,stats) length(intersect(pw,names(stats)))
for(i in seq_len(nrow(cov))) {
  h <- cov$hallmark[i]
  obs <- c(
    overlap_now(pathways[[h]],rk0$stats),
    overlap_now(pathways[[h]],rk1$stats),
    overlap_now(pathways[[h]],rkm$stats),
    overlap_now(pathways[[h]],rks$stats)
  )
  exp <- as.integer(c(cov$R0_overlap[i],cov$R1_overlap[i],
                      cov$R3_main_overlap[i],cov$R3_same_site_overlap[i]))
  if(!identical(obs,exp))
    hold(paste0("HALLMARK_MAPPING_COVERAGE_DRIFT:",h),256L)
}
add("50-Hallmark overlap replay vs Step3C","50/50 exact","50/50 exact","PASS")

# --------------------------------------------------------------------------
# 2. R0 GSEA — all frozen Hallmarks
# --------------------------------------------------------------------------
logline("[EXECUTE] R0 Hallmark GSEA: fixed family n=50")
g0 <- normalize_fgsea(
  run_fgsea(pathways,rk0$stats,"R0_fgsea"),50L,"R0")
g0$failure_program <- is.finite(g0$BH_FDR_frozen_family) &
                      g0$BH_FDR_frozen_family < 0.05
g0$failure_direction <- ifelse(g0$NES>0,"UP_IN_FAILURE","DOWN_IN_FAILURE")
awrite(g0,OUT_R0)

# --------------------------------------------------------------------------
# 3. R1 GSEA — all same 50 Hallmarks
# --------------------------------------------------------------------------
logline("[EXECUTE] R1 Hallmark GSEA: fixed family n=50")
g1 <- normalize_fgsea(
  run_fgsea(pathways,rk1$stats,"R1_fgsea"),50L,"R1")
awrite(g1,OUT_R1)

# --------------------------------------------------------------------------
# 4. Freeze R0/R1 stable family BEFORE any R3 program analysis
# --------------------------------------------------------------------------
j <- merge(
  g0[,c("pathway","NES","pval","BH_FDR_frozen_family","failure_program",
         "failure_direction")],
  g1[,c("pathway","NES","pval","BH_FDR_frozen_family")],
  by="pathway",suffixes=c("_R0","_R1"),sort=TRUE
)
names(j)[names(j)=="BH_FDR_frozen_family_R0"] <- "R0_BH_FDR"
names(j)[names(j)=="BH_FDR_frozen_family_R1"] <- "R1_BH_FDR"
j$R1_same_NES_sign_as_R0 <- sign(j$NES_R1)==sign(j$NES_R0)
j$stable_program <- j$failure_program &
                    is.finite(j$R1_BH_FDR) & j$R1_BH_FDR<0.05 &
                    j$R1_same_NES_sign_as_R0
stable <- j[j$stable_program,,drop=FALSE]
stable <- stable[order(stable$pathway),,drop=FALSE]
awrite(stable,OUT_STABLE)

stable_n <- nrow(stable)
add("R0/R1 stable program family","SCIENTIFIC_RESULT",stable_n,"INFO",
    "This family is frozen to disk before any R3 program GSEA is executed.")
logline("[FREEZE BEFORE R3] stable program n=",stable_n)

if(stable_n==0L) {
  empty <- data.frame(pathway=character(),stringsAsFactors=FALSE)
  awrite(empty,OUT_MAIN); awrite(empty,OUT_SAME)
  class_out <- data.frame(
    pathway=character(),program_class=character(),
    stringsAsFactors=FALSE)
  awrite(class_out,OUT_CLASS)
  sum_out <- data.frame(
    class="NO_STABLE_FAILURE_PROGRAMS",
    n=0L,stringsAsFactors=FALSE)
  awrite(sum_out,OUT_SUM)
  flush_audit()
  twrite(c(
    "R3_STEP3D_V1_1_DETERMINISTIC_PROGRAM_EXECUTION_PASS",
    paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
    "scientific_outcome=NO_R0_R1_STABLE_HALLMARK_PROGRAMS",
    "R0_Hallmarks_tested=50",
    "R1_Hallmarks_tested=50",
    "stable_programs=0",
    "R3_program_GSEA_executed=NO_NO_STABLE_FAMILY",
    "program_classification_rows=0",
    "upstream_model_refit=NO",
    "upstream_frozen_results_modified=NO",
    "pathway_shopping=NO"
  ),OUT_PASS)
  if(file.exists(OUT_HOLD)) unlink(OUT_HOLD,force=TRUE)
  logline("FINAL_GATE: PASS_NO_STABLE_PROGRAMS")
  quit(save="no",status=0,runLast=FALSE)
}

stable_paths <- pathways[stable$pathway]
if(length(stable_paths)!=stable_n)
  hold("STABLE_PATHWAY_SUBSET_RESOLUTION_FAILED",257L)

# --------------------------------------------------------------------------
# 5. R3 main GSEA — stable family only
# --------------------------------------------------------------------------
logline("[EXECUTE] R3 MAIN stable-program GSEA: family n=",stable_n)
gm <- normalize_fgsea(
  run_fgsea(stable_paths,rkm$stats,"R3_MAIN_fgsea"),
  stable_n,"R3_MAIN")
awrite(gm,OUT_MAIN)

# --------------------------------------------------------------------------
# 6. R3 same-site GSEA — exact same stable family only
# --------------------------------------------------------------------------
logline("[EXECUTE] R3 SAME-SITE stable-program GSEA: family n=",stable_n)
gs <- normalize_fgsea(
  run_fgsea(stable_paths,rks$stats,"R3_SAME_fgsea"),
  stable_n,"R3_SAME")
awrite(gs,OUT_SAME)

# --------------------------------------------------------------------------
# 7. Frozen classification
# --------------------------------------------------------------------------
cl <- stable[,c("pathway","NES_R0","R0_BH_FDR","NES_R1","R1_BH_FDR",
                "failure_direction"),drop=FALSE]
mm <- match(cl$pathway,gm$pathway)
ss <- match(cl$pathway,gs$pathway)
if(any(is.na(mm))) hold("R3_MAIN_STABLE_PROGRAM_MISSING",258L)

cl$main_NES <- gm$NES[mm]
cl$main_pvalue <- gm$pval[mm]
cl$main_BH_FDR <- gm$BH_FDR_frozen_family[mm]
cl$main_size <- gm$size[mm]
cl$main_leadingEdge <- gm$leadingEdge[mm]

cl$same_site_assessable <- !is.na(ss)
cl$same_site_NES <- ifelse(!is.na(ss),gs$NES[ss],NA_real_)
cl$same_site_pvalue <- ifelse(!is.na(ss),gs$pval[ss],NA_real_)
cl$same_site_BH_FDR <- ifelse(!is.na(ss),gs$BH_FDR_frozen_family[ss],NA_real_)
cl$same_site_size <- ifelse(!is.na(ss),gs$size[ss],NA_real_)
cl$same_site_leadingEdge <- ifelse(!is.na(ss),gs$leadingEdge[ss],NA_character_)

failure_sign <- ifelse(cl$failure_direction=="UP_IN_FAILURE",1,-1)
cl$main_relation <- ifelse(
  sign(cl$main_NES)==-failure_sign,"REVERSAL","WORSENING")
cl$same_site_relation <- ifelse(
  cl$same_site_assessable,
  ifelse(sign(cl$same_site_NES)==-failure_sign,"REVERSAL","WORSENING"),
  "UNAVAILABLE"
)
cl$main_significant <- is.finite(cl$main_BH_FDR) & cl$main_BH_FDR<0.05
cl$same_site_significant_strength <- cl$same_site_assessable &
                                     is.finite(cl$same_site_BH_FDR) &
                                     cl$same_site_BH_FDR<0.05

cl$program_class <- "PROGRAM_INDETERMINATE_NO_MAIN_SIGNAL"
for(i in seq_len(nrow(cl))) {
  if(!is.finite(cl$main_NES[i]) || !is.finite(cl$main_BH_FDR[i])) {
    cl$program_class[i] <- "PROGRAM_UNASSESSABLE"
  } else if(!cl$main_significant[i]) {
    cl$program_class[i] <- "PROGRAM_INDETERMINATE_NO_MAIN_SIGNAL"
  } else if(!cl$same_site_assessable[i] || !is.finite(cl$same_site_NES[i])) {
    cl$program_class[i] <- "PROGRAM_MAIN_ONLY_UNRESOLVED"
  } else if(cl$main_relation[i] != cl$same_site_relation[i]) {
    cl$program_class[i] <- "PROGRAM_SITE_CONFLICT"
  } else if(cl$main_relation[i]=="REVERSAL") {
    cl$program_class[i] <- "PROGRAM_REVERSAL_SUPPORTED"
  } else if(cl$main_relation[i]=="WORSENING") {
    cl$program_class[i] <- "PROGRAM_MALADAPTIVE_NONREVERSAL_WORSENING_SUPPORTED"
  } else {
    hold(paste0("UNEXPECTED_CLASSIFICATION_STATE:",cl$pathway[i]),259L)
  }
}
cl$interpretation_guard <-
  "NO_IRREVERSIBLE; NO_PERSISTENCE_FROM_MAIN_NONSIGNIFICANCE; MAIN_SITE_CONFOUNDED; SAME_SITE_NOT_INDEPENDENT_VALIDATION"
awrite(cl,OUT_CLASS)

levels_out <- c(
  "PROGRAM_REVERSAL_SUPPORTED",
  "PROGRAM_MALADAPTIVE_NONREVERSAL_WORSENING_SUPPORTED",
  "PROGRAM_SITE_CONFLICT",
  "PROGRAM_MAIN_ONLY_UNRESOLVED",
  "PROGRAM_INDETERMINATE_NO_MAIN_SIGNAL",
  "PROGRAM_UNASSESSABLE"
)
sum_out <- data.frame(
  class=levels_out,
  n=vapply(levels_out,function(z)sum(cl$program_class==z),integer(1)),
  stringsAsFactors=FALSE
)
awrite(sum_out,OUT_SUM)

add("classification rows","stable_program_n",nrow(cl),
    if(nrow(cl)==stable_n)"PASS" else "FAIL")
add("classification count sum","stable_program_n",sum(sum_out$n),
    if(sum(sum_out$n)==stable_n)"PASS" else "FAIL")
if(nrow(cl)!=stable_n || sum(sum_out$n)!=stable_n)
  hold("CLASSIFICATION_ACCOUNTING_MISMATCH",260L)

flush_audit()

twrite(c(
  "R3_STEP3D_V1_1_DETERMINISTIC_PROGRAM_EXECUTION_PASS",
  paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
  "V1_0_status=TECHNICAL_HOLD_BEFORE_ANY_GSEA",
  "V1_0_hold_reason=R1_MAPPING_IMPLEMENTATION_DRIFT_GLOBAL_TX2GENE_SYMBOL_UNIQUENESS",
  "V1_0_scientific_results_generated=NO",
  "V1_1_repair_scope=R1_MAPPING_REPLAY_ONLY",
  "R1_Step3C_mapping_replayed_exactly=YES",
  "upstream_contract=R3_STEP3B_V1_1_PROGRAM_ANALYSIS_CONTRACT_FROZEN",
  "source_identity=R3_STEP3C_HALLMARK_FGSEA_SOURCE_IDENTITY_FROZEN",
  "Hallmark_sets=50",
  "fgsea_version=1.38.0",
  "algorithm=fgseaMultilevel",
  "minSize=10",
  "maxSize=500",
  "eps=0",
  "scoreType=std",
  "gseaParam=1",
  "seed_reset_before_each_call=20260910",
  "nproc=1",
  "rank_tie_numeric_jitter=NO",
  "rank_tie_input_order=ABS_LFC_DESC_THEN_SYMBOL_ASC",
  "R0_family_FDR=BH_ACROSS_50",
  "R1_family_FDR=BH_ACROSS_50",
  paste0("R0_failure_programs=",sum(g0$failure_program)),
  paste0("R0_R1_stable_programs=",stable_n),
  paste0("R3_main_family_FDR=BH_ACROSS_",stable_n),
  paste0("R3_same_site_family_FDR=BH_ACROSS_",stable_n),
  paste0("PROGRAM_REVERSAL_SUPPORTED=",
         sum(cl$program_class=="PROGRAM_REVERSAL_SUPPORTED")),
  paste0("PROGRAM_MALADAPTIVE_NONREVERSAL_WORSENING_SUPPORTED=",
         sum(cl$program_class=="PROGRAM_MALADAPTIVE_NONREVERSAL_WORSENING_SUPPORTED")),
  paste0("PROGRAM_SITE_CONFLICT=",
         sum(cl$program_class=="PROGRAM_SITE_CONFLICT")),
  paste0("PROGRAM_MAIN_ONLY_UNRESOLVED=",
         sum(cl$program_class=="PROGRAM_MAIN_ONLY_UNRESOLVED")),
  paste0("PROGRAM_INDETERMINATE_NO_MAIN_SIGNAL=",
         sum(cl$program_class=="PROGRAM_INDETERMINATE_NO_MAIN_SIGNAL")),
  paste0("PROGRAM_UNASSESSABLE=",
         sum(cl$program_class=="PROGRAM_UNASSESSABLE")),
  "same_site_FDR_used_as_direction_gate=NO",
  "nonsignificant_main_program_called_persistent=NO",
  "irreversible_wording_used=NO",
  "complete_recovery_wording_used=NO",
  "upstream_model_refit=NO",
  "upstream_frozen_results_modified=NO",
  "pathway_collection_changed_after_R3_results=NO",
  "next_stage=ChatGPT_INDEPENDENT_AUDIT_OF_STEP3D_V1_1_RESULTS"
),OUT_PASS)

if(file.exists(OUT_HOLD)) unlink(OUT_HOLD,force=TRUE)
logline("FINAL_GATE: R3_STEP3D_V1_1_DETERMINISTIC_PROGRAM_EXECUTION_PASS")
quit(save="no",status=0,runLast=FALSE)
