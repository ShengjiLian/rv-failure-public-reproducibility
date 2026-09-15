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
# RV Project — R3 Step3C
# HALLMARK SOURCE + FGSEA ENVIRONMENT IDENTITY FREEZE
#
# PRE-EXECUTION ONLY.
# No GSEA result is calculated.
# No enrichment score/NES/P/FDR is calculated.
# No program is selected or classified.
#
# Frozen upstream authority:
#   R3_STEP3B_V1_1_PROGRAM_ANALYSIS_CONTRACT_FROZEN
#
# Exact external source fixed BEFORE any program result:
#   Human MSigDB v2026.1.Hs
#   Hallmark H collection, HGNC gene-symbol GMT
#   h.all.v2026.1.Hs.symbols.gmt
#
# Official versioned source:
#   https://data.broadinstitute.org/gsea-msigdb/msigdb/release/2026.1.Hs/
#
# Software:
#   R 4.6.x local environment
#   fgsea 1.38.0 (Bioconductor 3.23 / R 4.6)
#
# If fgsea is absent, this gate installs ONLY required R package dependencies.
# It does NOT reinstall R and does NOT execute GSEA.
# ==============================================================================

options(stringsAsFactors=FALSE,warn=1)

ROOT <- normalizePath(getwd(),winslash="/",mustWork=TRUE)
if(!identical(tolower(ROOT),tolower(RV_PROJECT_ROOT))) {
  stop("Expected D:/RV_project; observed: ",ROOT)
}

user_lib <- file.path(Sys.getenv("LOCALAPPDATA"),"R","win-library","4.6")
if(dir.exists(user_lib)) .libPaths(unique(c(user_lib,.libPaths())))

R0 <- file.path(ROOT,"results","R0","v4_LOCAL_RUN")
R1 <- file.path(ROOT,"results","R1_GSE240921")
R3 <- file.path(ROOT,"results","R3_GSE249696")
AUTH <- file.path(ROOT,"data","authority","MSigDB")
LOGD <- file.path(ROOT,"logs")
dir.create(AUTH,recursive=TRUE,showWarnings=FALSE)
dir.create(LOGD,recursive=TRUE,showWarnings=FALSE)

STEP3B <- file.path(R3,"R3_STEP3B_V1_1_PROGRAM_ANALYSIS_CONTRACT_FROZEN.txt")
METHOD <- file.path(R3,"R3_STEP3B_V1_1_program_method_contract.csv")
CLASS  <- file.path(R3,"R3_STEP3B_V1_1_program_classification_rules.csv")
AUTHROLES <- file.path(R3,"R3_STEP3B_V1_1_program_authority_roles.csv")

R0_FULL <- file.path(R0,"R0_FINAL_RVF_vs_pRV_assessable_results.csv")
R1_FULL <- file.path(R1,"R1_GSE240921_primary_Wald_all_genes.csv")
TX2GENE <- file.path(ROOT,"data","tximport","GSE345645",
                    "GSE345645_transcript_to_gene.csv.gz")
R3_MAIN <- file.path(R3,"R3_STEP3A_FIG5c_author_stats_minimal.csv.gz")
R3_SAME <- file.path(R3,"R3_STEP1D_ED4b_same_site_author_stats_minimal.csv.gz")

MSIGDB_VERSION <- "2026.1.Hs"
GMT_NAME <- "h.all.v2026.1.Hs.symbols.gmt"
GMT_URL <- paste0(
  "https://data.broadinstitute.org/gsea-msigdb/msigdb/release/",
  MSIGDB_VERSION,"/",GMT_NAME
)
GMT <- file.path(AUTH,GMT_NAME)
GMT_TMP <- paste0(GMT,".download_tmp")

EXPECTED_HALLMARK_SETS <- 50L
EXPECTED_FGSEA_VERSION <- "1.38.0"

OUT_AUD <- file.path(R3,"R3_STEP3C_source_environment_audit.csv")
OUT_MAN <- file.path(R3,"R3_STEP3C_HALLMARK_collection_manifest.csv")
OUT_COV <- file.path(R3,"R3_STEP3C_HALLMARK_mapping_coverage.csv")
OUT_ENV <- file.path(R3,"R3_STEP3C_environment_versions.csv")
OUT_PASS <- file.path(R3,"R3_STEP3C_HALLMARK_FGSEA_SOURCE_IDENTITY_FROZEN.txt")
OUT_HOLD <- file.path(R3,"R3_STEP3C_HALLMARK_FGSEA_SOURCE_IDENTITY_HOLD.txt")
LOG <- file.path(LOGD,"R3_STEP3C_HALLMARK_FGSEA_SOURCE_IDENTITY.log")

if(file.exists(LOG)) {
  old <- file.path(LOGD,paste0(
    "R3_STEP3C_HALLMARK_FGSEA_SOURCE_IDENTITY_",
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
    item=as.character(item),expected=as.character(expected),
    observed=as.character(observed),status=as.character(status),
    notes=as.character(notes),stringsAsFactors=FALSE
  )
  logline("[",status,"] ",item,
          " | expected=",expected,
          " | observed=",observed,
          if(nzchar(notes)) paste0(" | ",notes) else "")
}
flush_audit <- function() {
  if(length(A)) awrite(do.call(rbind,A),OUT_AUD)
}
hold <- function(reason,code=241L) {
  flush_audit()
  twrite(c(
    "R3_STEP3C_HALLMARK_FGSEA_SOURCE_IDENTITY_HOLD",
    paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
    paste0("reason=",reason),
    paste0("official_GMT_URL=",GMT_URL),
    paste0("expected_local_GMT=",GMT),
    "GSEA_executed=NO",
    "NES_calculated=NO",
    "program_selection_executed=NO",
    "program_classification_executed=NO",
    "upstream_frozen_results_modified=NO"
  ),OUT_HOLD)
  logline("FINAL_GATE: HOLD | ",reason)
  quit(save="no",status=code,runLast=FALSE)
}
options(error=function() {
  msg <- geterrmessage()
  try(logline("[UNHANDLED_R_ERROR] ",gsub("[\r\n]+"," | ",msg)),silent=TRUE)
  try(flush_audit(),silent=TRUE)
  try(twrite(c(
    "R3_STEP3C_HALLMARK_FGSEA_SOURCE_IDENTITY_HOLD_RUNTIME_ERROR",
    paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
    paste0("error=",gsub("[\r\n]+"," | ",msg)),
    "GSEA_executed=NO",
    "program_classification_executed=NO"
  ),OUT_HOLD),silent=TRUE)
  q(save="no",status=242,runLast=FALSE)
})

logline("============================================================")
logline("R3 Step3C — HALLMARK + fgsea SOURCE/ENVIRONMENT IDENTITY FREEZE")
logline("NO GSEA EXECUTION.")
logline("============================================================")

# --------------------------------------------------------------------------
# 1. Upstream frozen contract and input existence
# --------------------------------------------------------------------------
needed <- c(STEP3B,METHOD,CLASS,AUTHROLES,R0_FULL,R1_FULL,TX2GENE,R3_MAIN,R3_SAME)
for(p in needed) {
  ok <- file.exists(p)
  add(paste0("file_exists:",basename(p)),"YES",if(ok)"YES" else "NO",
      if(ok)"PASS" else "FAIL")
}
if(any(!file.exists(needed))) hold("MISSING_FROZEN_INPUT",243L)

b <- readLines(STEP3B,warn=FALSE,encoding="UTF-8")
b <- trimws(b); b <- b[nzchar(b)]
gate_ok <- length(b)>0 && identical(
  b[1],"R3_STEP3B_V1_1_PROGRAM_ANALYSIS_CONTRACT_FROZEN")
add("Step3B V1.1 gate identity",
    "R3_STEP3B_V1_1_PROGRAM_ANALYSIS_CONTRACT_FROZEN",
    if(length(b))b[1] else "<EMPTY>",
    if(gate_ok)"PASS" else "FAIL")
if(!gate_ok) hold("STEP3B_V1_1_GATE_MISMATCH",244L)

required_lines <- c(
  "V1_0_effective_scientific_contract=NO",
  "program_results_seen_before_repair=NO",
  "upstream_R0_R1_R2_R3_frozen_science_changed=NO",
  "primary_collection=MSigDB_HALLMARK_HUMAN_H_ONLY",
  "program_framework=FULL_RANKED_GSEA_NOT_GENE_VOTE_BINOMIAL",
  "GSEA_executed=NO",
  "program_classification_executed=NO"
)
for(x in required_lines) {
  ok <- x %in% b
  add(paste0("Step3B invariant:",sub("=.*$","",x)),
      x,if(ok)x else "<MISSING_OR_CHANGED>",if(ok)"PASS" else "FAIL")
}
if(any(vapply(A,function(x) any(x$status=="FAIL"),logical(1))))
  hold("STEP3B_V1_1_INVARIANT_MISMATCH",245L)

# --------------------------------------------------------------------------
# 2. Freeze R / Bioconductor / fgsea environment BEFORE GSEA
# --------------------------------------------------------------------------
rver <- paste(R.version$major,R.version$minor,sep=".")
r46 <- startsWith(rver,"4.6.")
add("R major.minor environment","4.6.x",rver,if(r46)"PASS" else "FAIL",
    "Existing R is used; this gate never reinstalls R.")
if(!r46) hold("R_VERSION_NOT_4_6_X",246L)

install_actions <- character()

if(!requireNamespace("digest",quietly=TRUE)) {
  logline("[INFO] digest is unavailable; run environment/bootstrap_R46.R before this scientific stage.")
}
if(!requireNamespace("digest",quietly=TRUE))
  hold("DIGEST_PACKAGE_UNAVAILABLE",247L)

if(!requireNamespace("BiocManager",quietly=TRUE)) {
  logline("[INFO] BiocManager is unavailable; run environment/bootstrap_R46.R before this scientific stage.")
}
if(!requireNamespace("BiocManager",quietly=TRUE))
  hold("BIOCMANAGER_UNAVAILABLE",248L)

biocver <- as.character(BiocManager::version())
add("Bioconductor version expected for R4.6","3.23",biocver,
    if(identical(biocver,"3.23"))"PASS" else "FAIL")
if(!identical(biocver,"3.23"))
  hold("BIOCONDUCTOR_VERSION_NOT_3_23",249L)

fgsea_before <- if(requireNamespace("fgsea",quietly=TRUE))
  as.character(utils::packageVersion("fgsea")) else "<NOT_INSTALLED>"

if(!identical(fgsea_before,EXPECTED_FGSEA_VERSION)) {
  logline("[INFO] Exact fgsea version is unavailable; run environment/bootstrap_R46.R before this scientific stage.")
}
if(!requireNamespace("fgsea",quietly=TRUE))
  hold("FGSEA_INSTALL_UNAVAILABLE",250L)

fgsea_ver <- as.character(utils::packageVersion("fgsea"))
add("fgsea exact version",EXPECTED_FGSEA_VERSION,fgsea_ver,
    if(identical(fgsea_ver,EXPECTED_FGSEA_VERSION))"PASS" else "FAIL")
if(!identical(fgsea_ver,EXPECTED_FGSEA_VERSION))
  hold("FGSEA_VERSION_NOT_EXACT_1_38_0",251L)

# We deliberately DO NOT call fgsea/fgseaMultilevel here.

# --------------------------------------------------------------------------
# 3. Acquire exact official versioned Hallmark GMT
# --------------------------------------------------------------------------
if(!file.exists(GMT)) {
  if(file.exists(GMT_TMP)) unlink(GMT_TMP,force=TRUE)
  logline("[INFO] Downloading exact official Hallmark GMT: ",GMT_URL)
  ok <- tryCatch({
    suppressWarnings(utils::download.file(
      GMT_URL,GMT_TMP,mode="wb",quiet=TRUE,method="libcurl"))
    file.exists(GMT_TMP) && file.info(GMT_TMP)$size>0
  },error=function(e) {
    logline("[DOWNLOAD_ERROR] ",conditionMessage(e))
    FALSE
  })
  if(!ok) {
    if(file.exists(GMT_TMP)) unlink(GMT_TMP,force=TRUE)
    hold("OFFICIAL_HALLMARK_GMT_DOWNLOAD_FAILED__MANUAL_DOWNLOAD_TO_EXPECTED_PATH_ALLOWED",252L)
  }
  replace_file(GMT_TMP,GMT)
}

gmt_bytes <- as.numeric(file.info(GMT)$size)
gmt_sha <- digest::digest(file=GMT,algo="sha256",serialize=FALSE)
add("MSigDB version","2026.1.Hs",MSIGDB_VERSION,"PASS")
add("Hallmark GMT filename",GMT_NAME,basename(GMT),
    if(identical(basename(GMT),GMT_NAME))"PASS" else "FAIL")
add("Hallmark GMT nonempty bytes",">0",gmt_bytes,
    if(is.finite(gmt_bytes)&&gmt_bytes>0)"PASS" else "FAIL")
add("Hallmark GMT SHA256 length","64",nchar(gmt_sha),
    if(nchar(gmt_sha)==64L)"PASS" else "FAIL")
if(any(vapply(A,function(x) any(x$status=="FAIL"),logical(1))))
  hold("HALLMARK_GMT_IDENTITY_FAILURE",253L)

# --------------------------------------------------------------------------
# 4. Parse Hallmark collection WITHOUT enrichment calculation
# --------------------------------------------------------------------------
ln <- readLines(GMT,warn=FALSE,encoding="UTF-8")
ln <- ln[nzchar(trimws(ln))]
parts <- strsplit(ln,"\t",fixed=TRUE)
valid <- vapply(parts,length,integer(1))>=3L
add("GMT records structurally valid","50/50",
    paste0(sum(valid),"/",length(parts)),
    if(length(parts)==EXPECTED_HALLMARK_SETS && all(valid))"PASS" else "FAIL")
if(length(parts)!=EXPECTED_HALLMARK_SETS || !all(valid))
  hold("HALLMARK_GMT_STRUCTURE_MISMATCH",254L)

set_names <- vapply(parts,`[`,character(1),1)
descriptions <- vapply(parts,`[`,character(1),2)
genesets <- lapply(parts,function(z) {
  g <- trimws(z[-c(1,2)])
  g[nzchar(g)]
})
names(genesets) <- set_names

add("Hallmark set count","50",length(genesets),
    if(length(genesets)==50L)"PASS" else "FAIL")
add("Hallmark set names unique","50",length(unique(set_names)),
    if(length(unique(set_names))==50L)"PASS" else "FAIL")
add("Hallmark naming prefix","ALL_HALLMARK_",
    if(all(startsWith(set_names,"HALLMARK_")))"ALL_HALLMARK_" else "VIOLATION",
    if(all(startsWith(set_names,"HALLMARK_")))"PASS" else "FAIL")

dup_within <- vapply(genesets,function(g) length(g)-length(unique(g)),integer(1))
add("Within-set duplicate memberships","0",sum(dup_within),
    if(sum(dup_within)==0L)"PASS" else "FAIL")
if(any(vapply(A,function(x) any(x$status=="FAIL"),logical(1))))
  hold("HALLMARK_COLLECTION_CONTENT_STRUCTURE_FAILURE",255L)

manifest <- data.frame(
  hallmark=set_names,
  description=descriptions,
  source_members=vapply(genesets,length,integer(1)),
  unique_members=vapply(genesets,function(g)length(unique(g)),integer(1)),
  stringsAsFactors=FALSE
)
awrite(manifest,OUT_MAN)

# --------------------------------------------------------------------------
# 5. Non-outcome mapping/rank availability preflight
# --------------------------------------------------------------------------
r0 <- read.csv(R0_FULL,stringsAsFactors=FALSE,check.names=FALSE)
r1 <- read.csv(R1_FULL,stringsAsFactors=FALSE,check.names=FALSE)
main <- read.csv(gzfile(R3_MAIN),stringsAsFactors=FALSE,check.names=FALSE)
same <- read.csv(gzfile(R3_SAME),stringsAsFactors=FALSE,check.names=FALSE)
tx <- read.csv(gzfile(TX2GENE),stringsAsFactors=FALSE,check.names=FALSE)

need0 <- c("gene_id","stat")
need1 <- c("gse240921_gene_id","stat")
need3 <- c("gene","log2FoldChange","pvalue")
for(z in list(
  c("R0",setdiff(need0,names(r0))),
  c("R1",setdiff(need1,names(r1))),
  c("R3_MAIN",setdiff(need3,names(main))),
  c("R3_SAME",setdiff(need3,names(same)))
)) {
  lab <- z[1]; miss <- z[-1]
  add(paste0(lab," execution schema"),"NONE",
      if(length(miss))paste(miss,collapse=";") else "NONE",
      if(!length(miss))"PASS" else "FAIL")
}
if(any(vapply(A,function(x) any(x$status=="FAIL"),logical(1))))
  hold("RANK_INPUT_SCHEMA_FAILURE",256L)

# R0: symbols must be unique for deterministic preranking.
r0_sym <- trimws(as.character(r0$gene_id))
r0_stat <- suppressWarnings(as.numeric(r0$stat))
r0_ok <- nzchar(r0_sym) & is.finite(r0_stat)
r0_unique <- !duplicated(r0_sym) & !duplicated(r0_sym,fromLast=TRUE)
r0_rank_syms <- unique(r0_sym[r0_ok & r0_unique])
add("R0 finite unique-symbol rank genes","REPORT_ONLY",
    length(r0_rank_syms),"INFO")

# R1 deterministic one-to-one Ensembl -> symbol mapping using frozen tx2gene.
gc <- c("ensembl_gene_id","gene_id","ensembl_gene_id_version")
sc <- c("external_gene_name","gene_symbol","symbol")
gc <- gc[gc %in% names(tx)]
sc <- sc[sc %in% names(tx)]
add("tx2gene usable Ensembl column",">=1",length(gc),
    if(length(gc)>=1L)"PASS" else "FAIL")
add("tx2gene usable symbol column",">=1",length(sc),
    if(length(sc)>=1L)"PASS" else "FAIL")
if(length(gc)<1L || length(sc)<1L)
  hold("TX2GENE_MAPPING_SCHEMA_FAILURE",257L)

tx_ens <- sub("\\.[0-9]+$","",trimws(as.character(tx[[gc[1]]])))
tx_sym <- trimws(as.character(tx[[sc[1]]]))
oktx <- nzchar(tx_ens) & nzchar(tx_sym)
pairs <- unique(data.frame(ens=tx_ens[oktx],sym=tx_sym[oktx],
                           stringsAsFactors=FALSE))

# Require one symbol per Ensembl.
ens_nsym <- tapply(pairs$sym,pairs$ens,function(x)length(unique(x)))
good_ens <- names(ens_nsym)[ens_nsym==1L]
one <- pairs[pairs$ens %in% good_ens,,drop=FALSE]
one <- one[!duplicated(one$ens),,drop=FALSE]

r1_ens <- sub("\\.[0-9]+$","",trimws(as.character(r1$gse240921_gene_id)))
mi <- match(r1_ens,one$ens)
r1_sym <- one$sym[mi]
r1_stat <- suppressWarnings(as.numeric(r1$stat))
candidate <- data.frame(
  row=seq_len(nrow(r1)),
  ens=r1_ens,
  sym=r1_sym,
  stat=r1_stat,
  stringsAsFactors=FALSE
)
candidate <- candidate[
  !is.na(candidate$sym) & nzchar(candidate$sym) & is.finite(candidate$stat),
  ,drop=FALSE
]
sym_nrows <- table(candidate$sym)
unique_syms <- names(sym_nrows)[sym_nrows==1L]
candidate <- candidate[candidate$sym %in% unique_syms,,drop=FALSE]
r1_rank_syms <- unique(candidate$sym)

add("R1 finite one-to-one unique-symbol rank genes","REPORT_ONLY",
    length(r1_rank_syms),"INFO",
    "No strongest-row/outcome-based duplicate collapse permitted.")

main_sym <- trimws(as.character(main$gene))
main_ok <- nzchar(main_sym) &
           is.finite(suppressWarnings(as.numeric(main$log2FoldChange))) &
           is.finite(suppressWarnings(as.numeric(main$pvalue)))
main_unique <- !duplicated(main_sym) & !duplicated(main_sym,fromLast=TRUE)
main_rank_syms <- unique(main_sym[main_ok & main_unique])

same_sym <- trimws(as.character(same$gene))
same_ok <- nzchar(same_sym) &
           is.finite(suppressWarnings(as.numeric(same$log2FoldChange))) &
           is.finite(suppressWarnings(as.numeric(same$pvalue)))
same_unique <- !duplicated(same_sym) & !duplicated(same_sym,fromLast=TRUE)
same_rank_syms <- unique(same_sym[same_ok & same_unique])

add("R3 main finite unique-symbol rank genes","REPORT_ONLY",
    length(main_rank_syms),"INFO")
add("R3 same-site finite unique-symbol rank genes","REPORT_ONLY",
    length(same_rank_syms),"INFO")

coverage <- do.call(rbind,lapply(set_names,function(h) {
  g <- unique(genesets[[h]])
  data.frame(
    hallmark=h,
    source_members=length(g),
    R0_overlap=sum(g %in% r0_rank_syms),
    R1_overlap=sum(g %in% r1_rank_syms),
    R3_main_overlap=sum(g %in% main_rank_syms),
    R3_same_site_overlap=sum(g %in% same_rank_syms),
    R0_eligible=sum(g %in% r0_rank_syms)>=10L && sum(g %in% r0_rank_syms)<=500L,
    R1_eligible=sum(g %in% r1_rank_syms)>=10L && sum(g %in% r1_rank_syms)<=500L,
    R3_main_eligible=sum(g %in% main_rank_syms)>=10L && sum(g %in% main_rank_syms)<=500L,
    R3_same_site_eligible=sum(g %in% same_rank_syms)>=10L && sum(g %in% same_rank_syms)<=500L,
    stringsAsFactors=FALSE
  )
}))
awrite(coverage,OUT_COV)

add("R0 eligible Hallmarks before outcomes","REPORT_ONLY",
    sum(coverage$R0_eligible),"INFO")
add("R1 eligible Hallmarks before outcomes","REPORT_ONLY",
    sum(coverage$R1_eligible),"INFO")
add("R3 main eligible Hallmarks before outcomes","REPORT_ONLY",
    sum(coverage$R3_main_eligible),"INFO")
add("R3 same-site eligible Hallmarks before outcomes","REPORT_ONLY",
    sum(coverage$R3_same_site_eligible),"INFO")

# --------------------------------------------------------------------------
# 6. Environment identity output
# --------------------------------------------------------------------------
env <- data.frame(
  item=c(
    "R.version.string",
    "R.major_minor",
    "Bioconductor.version",
    "fgsea.version",
    "digest.version",
    "BiocParallel.version",
    "data.table.version",
    "MSigDB.version",
    "Hallmark.GMT.filename",
    "Hallmark.GMT.bytes",
    "Hallmark.GMT.SHA256",
    "Hallmark.GMT.URL",
    "package_install_actions"
  ),
  value=c(
    R.version.string,
    rver,
    biocver,
    fgsea_ver,
    as.character(utils::packageVersion("digest")),
    if(requireNamespace("BiocParallel",quietly=TRUE))
      as.character(utils::packageVersion("BiocParallel")) else "<NOT_INSTALLED>",
    if(requireNamespace("data.table",quietly=TRUE))
      as.character(utils::packageVersion("data.table")) else "<NOT_INSTALLED>",
    MSIGDB_VERSION,
    GMT_NAME,
    as.character(gmt_bytes),
    gmt_sha,
    GMT_URL,
    if(length(install_actions))paste(unique(install_actions),collapse=";") else "NONE"
  ),
  stringsAsFactors=FALSE
)
awrite(env,OUT_ENV)
flush_audit()

twrite(c(
  "R3_STEP3C_HALLMARK_FGSEA_SOURCE_IDENTITY_FROZEN",
  paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
  "upstream_contract=R3_STEP3B_V1_1_PROGRAM_ANALYSIS_CONTRACT_FROZEN",
  "program_results_seen=NO",
  paste0("MSigDB_version=",MSIGDB_VERSION),
  "MSigDB_species=Homo_sapiens",
  "MSigDB_collection=H_HALLMARK",
  "MSigDB_identifier_namespace=HUMAN_GENE_SYMBOL",
  paste0("Hallmark_GMT_filename=",GMT_NAME),
  paste0("Hallmark_GMT_bytes=",gmt_bytes),
  paste0("Hallmark_GMT_SHA256=",gmt_sha),
  paste0("Hallmark_GMT_URL=",GMT_URL),
  paste0("Hallmark_sets=",length(genesets)),
  paste0("fgsea_version=",fgsea_ver),
  paste0("Bioconductor_version=",biocver),
  paste0("R_version=",rver),
  "fgsea_algorithm=fgseaMultilevel",
  "minSize=10",
  "maxSize=500",
  "eps=0",
  "seed=20260910",
  "nproc=1",
  "R3_same_site_rank_metric=SAME_SIGNED_Z_EQUIVALENT_FROM_AUTHOR_PVALUE_AND_LOG2FC_AS_R3_MAIN",
  "duplicate_symbol_policy=ONE_TO_ONE_MAPPING_ONLY_NO_OUTCOME_BASED_COLLAPSE",
  paste0("R0_rank_symbols=",length(r0_rank_syms)),
  paste0("R1_rank_symbols=",length(r1_rank_syms)),
  paste0("R3_main_rank_symbols=",length(main_rank_syms)),
  paste0("R3_same_site_rank_symbols=",length(same_rank_syms)),
  paste0("R0_eligible_Hallmarks=",sum(coverage$R0_eligible)),
  paste0("R1_eligible_Hallmarks=",sum(coverage$R1_eligible)),
  paste0("R3_main_eligible_Hallmarks=",sum(coverage$R3_main_eligible)),
  paste0("R3_same_site_eligible_Hallmarks=",sum(coverage$R3_same_site_eligible)),
  "GSEA_executed=NO",
  "NES_calculated=NO",
  "program_selection_executed=NO",
  "program_classification_executed=NO",
  "upstream_frozen_results_modified=NO",
  "next_stage=ChatGPT_INDEPENDENT_AUDIT_THEN_R3_STEP3D_DETERMINISTIC_PROGRAM_EXECUTION"
),OUT_PASS)

if(file.exists(OUT_HOLD)) unlink(OUT_HOLD,force=TRUE)
logline("FINAL_GATE: R3_STEP3C_HALLMARK_FGSEA_SOURCE_IDENTITY_FROZEN")
quit(save="no",status=0,runLast=FALSE)
