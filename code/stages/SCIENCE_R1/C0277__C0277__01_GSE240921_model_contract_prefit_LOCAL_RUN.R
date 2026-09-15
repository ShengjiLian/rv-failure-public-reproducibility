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
# RV Project — R1 GSE240921 Step 1
# MODEL CONTRACT + GENE-ID MAPPING PREFLIGHT
#
# NO model fitting in this step.
#
# Frozen intended validation:
#   dataset      : GSE240921 human RV bulk RNA-seq
#   samples      : all 40 samples
#   primary model: ~ technical_batch + clinical_state
#   contrast     : DECOMPENSATED vs COMPENSATED
#   sensitivity  : ~ technical_batch + sex + clinical_state
#
# Replication family:
#   the 330 FINAL_FROZEN GSE345645 RVF-vs-pRV discoveries
#
# Primary replication rule (to be used only after later model fit):
#   - unique deterministic gene mapping
#   - GSE240921 baseMean >= 5
#   - default-fit betaConv == TRUE
#   - finite Wald p-value
#   - same unshrunk log2FC direction as R0
#   - BH-FDR < 0.05 in the FULL 330-candidate family,
#     with unassessable candidates padded as p=1
#
# Available-only BH may be reported as sensitivity, never as primary.
# ASHR will be effect-size/ranking only, never p/FDR authority.
#
# author_cluster_id is explicitly NOT a model covariate because it is a
# downstream/post-hoc transcriptomic subgroup, not a baseline confounder.
# ==============================================================================

options(stringsAsFactors=FALSE, warn=1)

ROOT <- normalizePath(getwd(), winslash="/", mustWork=TRUE)
if (!identical(ROOT,RV_PROJECT_ROOT)) stop("Expected D:/RV_project")

user_lib <- file.path(Sys.getenv("LOCALAPPDATA"),"R","win-library","4.6")
if (dir.exists(user_lib)) .libPaths(unique(c(user_lib,.libPaths())))

if (!requireNamespace("readxl",quietly=TRUE)) {
  stop("readxl required; no package installation is performed automatically.")
}

RES <- file.path(ROOT,"results","R1_GSE240921")
R0RES <- file.path(ROOT,"results","R0","v4_LOCAL_RUN")
LOGDIR <- file.path(ROOT,"logs")
dir.create(RES,recursive=TRUE,showWarnings=FALSE)
dir.create(LOGDIR,recursive=TRUE,showWarnings=FALSE)

STEP0_GATE <- file.path(RES,"R1_GSE240921_STEP0_SEMANTIC_REPAIR_PASS.txt")
MANIFEST <- file.path(RES,"R1_GSE240921_sample_manifest_semantic_repair.csv")
XLSX <- file.path(ROOT,"data","processed","GSE240921","GSE240921_processed-data-human.xlsx")
R0_SIG <- file.path(R0RES,"R0_FINAL_RVF_vs_pRV_FDR05.csv")
TX2GENE <- file.path(ROOT,"data","tximport","GSE345645","GSE345645_transcript_to_gene.csv.gz")

OUT_AUD <- file.path(RES,"R1_GSE240921_step1_model_contract_audit.csv")
OUT_MAP <- file.path(RES,"R1_GSE240921_R0_330_candidate_mapping.csv")
OUT_MAPSUM <- file.path(RES,"R1_GSE240921_R0_330_mapping_summary.csv")
OUT_DESIGN <- file.path(RES,"R1_GSE240921_design_matrix_audit.csv")
OUT_GENE <- file.path(RES,"R1_GSE240921_gene_id_diagnostic.csv")
OUT_CONTRACT <- file.path(RES,"R1_GSE240921_MODEL_CONTRACT_FROZEN.txt")
LOG <- file.path(LOGDIR,"R1_GSE240921_STEP1_MODEL_CONTRACT.log")

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

A <- list()
add <- function(item,expected,observed,status,notes="") {
  rr <- data.frame(
    item=as.character(item),expected=as.character(expected),
    observed=as.character(observed),status=as.character(status),
    notes=as.character(notes),stringsAsFactors=FALSE
  )
  A[[length(A)+1L]] <<- rr
  logline("[",status,"] ",item," | expected=",expected," | observed=",observed)
}

logline("============================================================")
logline("R1 GSE240921 Step 1 — model contract + gene-ID mapping preflight")
logline("NO MODEL FITTING.")
logline("============================================================")

must(file.exists(STEP0_GATE),"Missing Step0 semantic-repair PASS gate")
g0 <- readLines(STEP0_GATE,warn=FALSE)
must(length(g0)>0 && g0[1]=="R1_GSE240921_STEP0_SEMANTIC_REPAIR_PASS",
     "Unexpected Step0 gate")
must(file.exists(MANIFEST),"Missing repaired sample manifest")
must(file.exists(XLSX),"Missing processed workbook")
must(file.exists(R0_SIG),"Missing frozen R0 FDR05 table")

m <- read.csv(MANIFEST,stringsAsFactors=FALSE,check.names=FALSE)
must(nrow(m)==40L,"Manifest must contain 40 samples")
must(length(unique(m$count_matrix_column))==40L,"Manifest sample columns must be unique")

m$technical_batch <- factor(
  m$technical_batch,
  levels=c("BATCH1_PRAKASH_SINGLE_END","BATCH2_US_PAIRED_END")
)
m$clinical_state <- factor(
  m$clinical_state,
  levels=c("NORMAL_CONTROL","COMPENSATED","DECOMPENSATED")
)
m$sex <- factor(m$sex,levels=c("F","M"))

add("sample manifest rows","40",nrow(m),if(nrow(m)==40L) "PASS" else "FAIL")
add("clinical state counts","13/14/13",
    paste(table(m$clinical_state),collapse="/"),
    if(identical(as.integer(table(m$clinical_state)),c(13L,14L,13L))) "PASS" else "FAIL")
add("technical batch counts","15/25",
    paste(table(m$technical_batch),collapse="/"),
    if(identical(as.integer(table(m$technical_batch)),c(15L,25L))) "PASS" else "FAIL")
add("sex missingness","0",sum(is.na(m$sex)),
    if(sum(is.na(m$sex))==0L) "PASS" else "FAIL")

# --------------------------------------------------------------------------
# Design estimability
# --------------------------------------------------------------------------

X1 <- model.matrix(~ technical_batch + clinical_state,data=m)
X2 <- model.matrix(~ technical_batch + sex + clinical_state,data=m)

dtab <- data.frame(
  model=c(
    "PRIMARY: ~ technical_batch + clinical_state",
    "SENSITIVITY: ~ technical_batch + sex + clinical_state"
  ),
  rows=c(nrow(X1),nrow(X2)),
  columns=c(ncol(X1),ncol(X2)),
  rank=c(qr(X1)$rank,qr(X2)$rank),
  full_rank=c(qr(X1)$rank==ncol(X1),qr(X2)$rank==ncol(X2)),
  stringsAsFactors=FALSE
)
awrite(dtab,OUT_DESIGN)

add("primary design full rank","TRUE",dtab$full_rank[1],
    if(isTRUE(dtab$full_rank[1])) "PASS" else "FAIL")
add("sex-adjusted sensitivity design full rank","TRUE",dtab$full_rank[2],
    if(isTRUE(dtab$full_rank[2])) "PASS" else "FAIL")

# --------------------------------------------------------------------------
# Read workbook count matrix. No statistical model.
# --------------------------------------------------------------------------

cnt <- as.data.frame(
  readxl::read_excel(XLSX,sheet="count matrix",.name_repair="unique"),
  stringsAsFactors=FALSE,check.names=FALSE
)
must(nrow(cnt)==48738L && ncol(cnt)==41L,
     "Count matrix dimensions changed from 48,738 x 41")
must(setequal(names(cnt)[-1],m$count_matrix_column),
     "Count-matrix sample columns differ from repaired manifest")

gene_raw <- as.character(cnt[[1]])
gene_noversion <- sub("\\.[0-9]+$","",gene_raw)
ensg_fraction <- mean(grepl("^ENSG[0-9]+",gene_noversion))
symbol_like_fraction <- mean(grepl("^[A-Za-z][A-Za-z0-9._-]*$",gene_raw))

gene_diag <- data.frame(
  metric=c(
    "gene_column_name","gene_rows","gene_raw_unique",
    "gene_noVersion_unique","fraction_ENSG_like","fraction_symbol_like",
    "example_gene_1","example_gene_2","example_gene_3"
  ),
  value=c(
    names(cnt)[1],length(gene_raw),length(unique(gene_raw)),
    length(unique(gene_noversion)),ensg_fraction,symbol_like_fraction,
    head(gene_raw,3)
  ),
  stringsAsFactors=FALSE
)
awrite(gene_diag,OUT_GENE)

id_mode <- if(ensg_fraction>=0.90) {
  "ENSEMBL_GENE_ID"
} else {
  "DIRECT_GENE_LABEL"
}
add("gene identifier mode","deterministically classified",id_mode,"PASS")

# --------------------------------------------------------------------------
# Frozen R0 candidate family = exactly 330 unique discoveries.
# --------------------------------------------------------------------------

r0 <- read.csv(R0_SIG,stringsAsFactors=FALSE,check.names=FALSE)
must("gene_id" %in% names(r0),"R0 FDR05 file lacks gene_id")
must(nrow(r0)==330L && length(unique(r0$gene_id))==330L,
     "Frozen R0 discovery family must be exactly 330 unique genes")

r0_dir_col <- if("log2FoldChange" %in% names(r0)) {
  "log2FoldChange"
} else if("ashr_log2FoldChange" %in% names(r0)) {
  "ashr_log2FoldChange"
} else {
  stop("R0 FDR05 file lacks an effect-direction column")
}
r0_effect <- as.numeric(r0[[r0_dir_col]])
must(all(is.finite(r0_effect)) && all(r0_effect!=0),
     "R0 candidate effect directions must be finite and nonzero")

cand <- data.frame(
  r0_gene_id=as.character(r0$gene_id),
  r0_log2FC=r0_effect,
  r0_direction=ifelse(r0_effect>0,"UP_RVF_vs_pRV","DOWN_RVF_vs_pRV"),
  mapping_status=NA_character_,
  gse240921_gene_id=NA_character_,
  mapping_notes=NA_character_,
  stringsAsFactors=FALSE
)

# --------------------------------------------------------------------------
# Deterministic candidate mapping
# --------------------------------------------------------------------------

if(id_mode=="ENSEMBL_GENE_ID") {
  must(file.exists(TX2GENE),
       "Ensembl count IDs detected but frozen local GSE345645 tx2gene mapping is missing")
  tx <- read.csv(gzfile(TX2GENE),stringsAsFactors=FALSE,check.names=FALSE)

  gene_col_candidates <- c("ensembl_gene_id","gene_id","ensembl_gene_id_version")
  sym_col_candidates <- c("external_gene_name","gene_symbol","symbol")
  gc <- gene_col_candidates[gene_col_candidates %in% names(tx)]
  sc <- sym_col_candidates[sym_col_candidates %in% names(tx)]
  must(length(gc)>=1L && length(sc)>=1L,
       paste0("tx2gene lacks usable gene/symbol columns. columns=",paste(names(tx),collapse=";")))

  gcol <- gc[1]
  scol <- sc[1]
  tx_gene <- sub("\\.[0-9]+$","",as.character(tx[[gcol]]))
  tx_sym <- trimws(as.character(tx[[scol]]))
  ok <- !is.na(tx_gene) & nzchar(tx_gene) & !is.na(tx_sym) & nzchar(tx_sym)

  map_pairs <- unique(data.frame(
    ensembl_gene_id=tx_gene[ok],
    symbol=tx_sym[ok],
    stringsAsFactors=FALSE
  ))

  count_ens <- unique(gene_noversion)

  for(i in seq_len(nrow(cand))) {
    ids <- unique(map_pairs$ensembl_gene_id[
      map_pairs$symbol==cand$r0_gene_id[i] &
      map_pairs$ensembl_gene_id %in% count_ens
    ])
    if(length(ids)==1L) {
      raw_hits <- gene_raw[gene_noversion==ids]
      if(length(unique(raw_hits))==1L) {
        cand$mapping_status[i] <- "UNIQUE_MAPPED"
        cand$gse240921_gene_id[i] <- unique(raw_hits)
        cand$mapping_notes[i] <- paste0("via ",gcol,"->",scol)
      } else {
        cand$mapping_status[i] <- "AMBIGUOUS_MULTIPLE_COUNT_ROWS"
        cand$mapping_notes[i] <- paste(raw_hits,collapse=";")
      }
    } else if(length(ids)==0L) {
      cand$mapping_status[i] <- "NOT_MAPPED"
      cand$mapping_notes[i] <- "No frozen tx2gene symbol-to-count-ID match"
    } else {
      cand$mapping_status[i] <- "AMBIGUOUS_MULTIPLE_ENSEMBL_IDS"
      cand$mapping_notes[i] <- paste(ids,collapse=";")
    }
  }

  mapping_authority <- paste0("LOCAL_FROZEN_TX2GENE:",gcol,"->",scol)

} else {
  for(i in seq_len(nrow(cand))) {
    hits <- which(gene_raw==cand$r0_gene_id[i])
    if(length(hits)==1L) {
      cand$mapping_status[i] <- "UNIQUE_MAPPED"
      cand$gse240921_gene_id[i] <- gene_raw[hits]
      cand$mapping_notes[i] <- "direct exact gene-label match"
    } else if(length(hits)==0L) {
      cand$mapping_status[i] <- "NOT_MAPPED"
      cand$mapping_notes[i] <- "No exact gene-label match"
    } else {
      cand$mapping_status[i] <- "AMBIGUOUS_MULTIPLE_COUNT_ROWS"
      cand$mapping_notes[i] <- paste(gene_raw[hits],collapse=";")
    }
  }
  mapping_authority <- "DIRECT_EXACT_GENE_LABEL"
}

awrite(cand,OUT_MAP)

ms <- as.data.frame(table(cand$mapping_status),stringsAsFactors=FALSE)
names(ms) <- c("mapping_status","genes")
ms$percent_of_330 <- 100*ms$genes/330
awrite(ms,OUT_MAPSUM)

n_unique <- sum(cand$mapping_status=="UNIQUE_MAPPED")
n_ambig <- sum(grepl("^AMBIGUOUS",cand$mapping_status))
n_absent <- sum(cand$mapping_status=="NOT_MAPPED")

add("R0 frozen candidate family","330",nrow(cand),
    if(nrow(cand)==330L) "PASS" else "FAIL")
add("candidate unique-mapped","informational",n_unique,"PASS")
add("candidate ambiguous","informational",n_ambig,"PASS")
add("candidate not mapped","informational",n_absent,"PASS")

audit <- do.call(rbind,A)
awrite(audit,OUT_AUD)
must(all(audit$status=="PASS"),"Step1 contract audit contains FAIL rows")

# --------------------------------------------------------------------------
# Freeze model / replication contract. NO FIT.
# --------------------------------------------------------------------------

twrite(c(
  "R1_GSE240921_MODEL_CONTRACT_FROZEN",
  paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
  "dataset=GSE240921",
  "samples=ALL_40_HUMAN_RV",
  "normal_control=13",
  "compensated=14",
  "decompensated=13",
  "primary_model=~ technical_batch + clinical_state",
  "primary_model_full_rank=YES",
  "primary_contrast=DECOMPENSATED_vs_COMPENSATED",
  "sensitivity_model=~ technical_batch + sex + clinical_state",
  "sensitivity_model_full_rank=YES",
  "author_cluster_id_model_covariate=NO",
  "reason_author_cluster_excluded=POSTHOC_TRANSCRIPTOMIC_SUBGROUP",
  "primary_expression_assessability=baseMean_ge_5",
  "default_betaConv_required=TRUE",
  "primary_pvalue_authority=UNSHRUNKEN_WALD",
  "ashr_role=EFFECT_SIZE_AND_RANKING_ONLY",
  "R0_replication_family_size=330",
  paste0("gene_mapping_authority=",mapping_authority),
  paste0("R0_candidates_unique_mapped=",n_unique),
  paste0("R0_candidates_ambiguous=",n_ambig),
  paste0("R0_candidates_not_mapped=",n_absent),
  "primary_replication_FDR_family=FULL_330_PADDED",
  "unmapped_or_nonassessable_candidate_p_for_primary_FDR=1",
  "primary_replication_FDR_method=BH",
  "primary_replication_FDR_alpha=0.05",
  "primary_replication_direction_requirement=SAME_UNSHRUNKEN_LOG2FC_SIGN_AS_R0",
  "available_only_BH_role=SENSITIVITY_ONLY",
  "author_style_abs_log2FC_ge_0.585_role=SECONDARY_DESCRIPTIVE_ONLY",
  "model_fit_executed=NO",
  "differential_expression_executed=NO",
  "replication_results_peeked=NO",
  "next_stage=R1 Step 2 DESeq2 primary model fit only after ChatGPT audit"
),OUT_CONTRACT)

logline("Frozen candidate mapping: unique=",n_unique,
        "; ambiguous=",n_ambig,"; absent=",n_absent)
logline("FINAL_GATE: R1_GSE240921_MODEL_CONTRACT_FROZEN")
quit(save="no",status=0,runLast=FALSE)
