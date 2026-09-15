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
# RV Project — R3 Step 1C
# NATURE FIG.4 + EXTENDED DATA FIG.4 SOURCE-AUTHORITY DISCOVERY
#
# Purpose:
#   Inspect the two official Nature source-data workbooks that are most relevant
#   to anatomical-site adjudication and same-site unloading sensitivity:
#
#   Source Data Fig.4
#     - B-prePEA_septum vs Control_septum (n=3 vs n=10)
#     - B-prePEA_septum vs B-prePEA_RV (same 3 patients)
#     - B-prePEA_RV vs B-postPEA_septum (same 3 patients)
#
#   Source Data Extended Data Fig.4
#     - B-prePEA_septum vs B-postPEA_septum (same 3 patients; SAME SITE)
#
# Published checksum facts:
#   - Fig4 pre-septum vs control-septum: 3323 DEGs
#   - Fig4 pre-septum vs pre-RV:         404 DEGs
#   - Fig4 pre-RV vs post-septum:        205 DEGs
#   - Extended Data Fig4 same-site pre vs post septum: 21 DEGs
#
# This step is DISCOVERY ONLY:
#   - reads workbook structures
#   - finds table-like gene/LFC/P/padj regions
#   - locates exact frozen Primary25 symbols
#   - emits nearby row contexts for audit
#
# NO DESeq2 / limma / edgeR / p.adjust.
# NO candidate classification.
# NO recovery/persistence calls.
# ==============================================================================

options(stringsAsFactors=FALSE, warn=1)

ROOT <- normalizePath(getwd(), winslash="/", mustWork=TRUE)
if(!identical(ROOT,RV_PROJECT_ROOT)) stop("Expected D:/RV_project")

AUTH <- file.path(ROOT,"data","authority","GSE249696")
RES  <- file.path(ROOT,"results","R3_GSE249696")
LOGD <- file.path(ROOT,"logs")
dir.create(AUTH,recursive=TRUE,showWarnings=FALSE)
dir.create(RES,recursive=TRUE,showWarnings=FALSE)
dir.create(LOGD,recursive=TRUE,showWarnings=FALSE)

FIG4 <- file.path(AUTH,"44161_2025_672_MOESM6_ESM.xlsx")
ED4  <- file.path(AUTH,"44161_2025_672_MOESM12_ESM.xlsx")

OUT_INV <- file.path(RES,"R3_STEP1C_FIG4_ED4_sheet_inventory.csv")
OUT_REG <- file.path(RES,"R3_STEP1C_FIG4_ED4_candidate_table_regions.csv")
OUT_HIT <- file.path(RES,"R3_STEP1C_FIG4_ED4_PRIMARY25_cell_hits.csv")
OUT_CTX <- file.path(RES,"R3_STEP1C_FIG4_ED4_PRIMARY25_context_rows.csv")
OUT_AUD <- file.path(RES,"R3_STEP1C_FIG4_ED4_authority_discovery_audit.csv")
PASS <- file.path(RES,"R3_STEP1C_FIG4_ED4_SOURCE_DISCOVERY_PASS.txt")
HOLD <- file.path(RES,"R3_STEP1C_FIG4_ED4_SOURCE_DISCOVERY_HOLD.txt")
LOG <- file.path(LOGD,"R3_STEP1C_FIG4_ED4_SOURCE_DISCOVERY.log")

PRIMARY25 <- c(
  "LIPG","COMP","ALOX5","SPP1","GRIN2B","SLCO2A1","SP140","DNAH7",
  "JAK3","CSMD1","BIN2","VDR","IL21R","GMIP","SMAD7","ABCC3","KYNU",
  "PLSCR1","CP","SLC6A6","STXBP2","MYO1F","MPC2","CD163","CD72"
)

if(file.exists(LOG)) {
  old <- file.path(
    LOGD,
    paste0("R3_STEP1C_FIG4_ED4_SOURCE_DISCOVERY_",
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
  if(!file.rename(t,p)) {unlink(t); stop("Atomic CSV failed: ",p)}
}
twrite <- function(x,p) {
  t <- paste0(p,".tmp_",Sys.getpid())
  writeLines(x,t,useBytes=TRUE)
  if(file.exists(p)) unlink(p,force=TRUE)
  if(!file.rename(t,p)) {unlink(t); stop("Atomic text failed: ",p)}
}
canon <- function(x) gsub("[^a-z0-9]+","",tolower(as.character(x)))

A <- list()
add <- function(item,expected,observed,status,notes="") {
  A[[length(A)+1L]] <<- data.frame(
    item=as.character(item),expected=as.character(expected),
    observed=as.character(observed),status=as.character(status),
    notes=as.character(notes),stringsAsFactors=FALSE
  )
  logline("[",status,"] ",item," | expected=",expected,
          " | observed=",observed)
}

logline("============================================================")
logline("R3 Step1C — Fig4 + Extended Data Fig4 source discovery")
logline("NO inferential-statistic recomputation.")
logline("============================================================")

missing <- c(FIG4,ED4)[!file.exists(c(FIG4,ED4))]
if(length(missing)) {
  twrite(c(
    "R3_STEP1C_FIG4_ED4_SOURCE_DISCOVERY_HOLD_MISSING_FILES",
    paste0("missing=",paste(missing,collapse=";")),
    paste0("Fig4_destination=",FIG4),
    paste0("ExtendedDataFig4_destination=",ED4),
    "statistical_recomputation=NO",
    "candidate_classification=NO"
  ),HOLD)
  logline("FINAL_GATE: R3_STEP1C_HOLD_MISSING_FILES")
  quit(save="no",status=131,runLast=FALSE)
}

if(!requireNamespace("readxl",quietly=TRUE)) stop("readxl unavailable")

options(error=function() {
  msg <- geterrmessage()
  try(logline("[UNHANDLED_R_ERROR] ",gsub("[\r\n]+"," | ",msg)),silent=TRUE)
  try(twrite(c(
    "R3_STEP1C_FIG4_ED4_SOURCE_DISCOVERY_HOLD_RUNTIME_ERROR",
    paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
    paste0("error=",gsub("[\r\n]+"," | ",msg)),
    "statistical_recomputation=NO"
  ),HOLD),silent=TRUE)
  q(save="no",status=133,runLast=FALSE)
})

books <- data.frame(
  workbook=c("FIG4","EXTENDED_DATA_FIG4"),
  path=c(FIG4,ED4),
  stringsAsFactors=FALSE
)

gene_kw <- c("gene","genes","gene symbol","symbol","external gene name",
             "ensembl gene","ensembl gene id","gene_name","geneid","ensid")
lfc_kw <- c("log2foldchange","log2fc","log2(fc)","log2 fold change",
            "log2 foldchange","logfc","fold change")
padj_kw <- c("padj","adjusted p","adjusted p value","adjusted p-value",
             "fdr","q value","qvalue")
p_kw <- c("pvalue","p value","p-value","p_val","pval")

inventory <- list()
regions <- list()
hits <- list()
contexts <- list()

read_sheet_text <- function(path,sh) {
  x <- suppressMessages(
    readxl::read_excel(path,sheet=sh,col_names=FALSE,.name_repair="minimal")
  )
  if(!nrow(x) || !ncol(x)) return(matrix(character(),0,0))
  m <- as.matrix(data.frame(lapply(x,as.character),
                            check.names=FALSE,stringsAsFactors=FALSE))
  m[is.na(m)] <- ""
  m
}

for(bi in seq_len(nrow(books))) {
  wb <- books$workbook[bi]
  path <- books$path[bi]
  sheets <- readxl::excel_sheets(path)

  add(paste0(wb," workbook readable"),"YES","YES","PASS")
  add(paste0(wb," sheet count"),">=1",length(sheets),
      if(length(sheets)>=1L) "PASS" else "FAIL")

  for(sh in sheets) {
    logline("[INFO] Reading ",wb," / ",sh)
    m <- read_sheet_text(path,sh)

    if(!length(m)) {
      inventory[[length(inventory)+1L]] <- data.frame(
        workbook=wb,sheet=sh,n_rows=0,n_cols=0,nonempty_cells=0,
        PRIMARY25_unique_hits=0,
        contains_pre_septum=FALSE,contains_post_septum=FALSE,
        contains_control_septum=FALSE,contains_pre_RV=FALSE,
        stringsAsFactors=FALSE
      )
      next
    }

    flat <- tolower(as.character(m))
    has_pre_sep <- any(grepl("prepea",flat) & grepl("sept",flat))
    has_post_sep <- any(grepl("postpea",flat) & grepl("sept",flat))
    has_ctrl_sep <- any(grepl("control",flat) & grepl("sept",flat))
    has_pre_rv <- any(grepl("prepea",flat) & grepl("rv",flat))

    sheet_genes <- character()
    for(g in PRIMARY25) {
      pat <- paste0("(?i)(^|[^A-Za-z0-9])",g,"([^A-Za-z0-9]|$)")
      mask <- matrix(
        grepl(pat,as.character(m),perl=TRUE),
        nrow=nrow(m),ncol=ncol(m)
      )
      loc <- which(mask,arr.ind=TRUE)
      if(nrow(loc)>0L) {
        sheet_genes <- c(sheet_genes,g)
        for(k in seq_len(nrow(loc))) {
          rr <- loc[k,1]; cc <- loc[k,2]
          hits[[length(hits)+1L]] <- data.frame(
            workbook=wb,gene=g,sheet=sh,row=rr,col=cc,
            cell_text=m[rr,cc],stringsAsFactors=FALSE
          )
          lo <- max(1L,rr-2L); hi <- min(nrow(m),rr+2L)
          for(r0 in lo:hi) {
            vals <- m[r0,,drop=TRUE]
            keep <- nzchar(trimws(vals))
            contexts[[length(contexts)+1L]] <- data.frame(
              workbook=wb,gene=g,sheet=sh,hit_row=rr,context_row=r0,
              row_text=paste(vals[keep],collapse=" | "),
              stringsAsFactors=FALSE
            )
          }
        }
      }
    }

    inventory[[length(inventory)+1L]] <- data.frame(
      workbook=wb,sheet=sh,n_rows=nrow(m),n_cols=ncol(m),
      nonempty_cells=sum(nzchar(trimws(m))),
      PRIMARY25_unique_hits=length(unique(sheet_genes)),
      contains_pre_septum=has_pre_sep,
      contains_post_septum=has_post_sep,
      contains_control_septum=has_ctrl_sep,
      contains_pre_RV=has_pre_rv,
      stringsAsFactors=FALSE
    )

    # Candidate table-header discovery.
    maxscan <- min(nrow(m),500L)
    for(rr in seq_len(maxscan)) {
      raw <- m[rr,,drop=TRUE]
      can <- canon(raw)
      nz <- which(nzchar(can))
      if(!length(nz)) next

      kwmatch <- function(kws) which(can %in% canon(kws))
      gcol <- kwmatch(gene_kw)
      lcol <- kwmatch(lfc_kw)
      acol <- kwmatch(padj_kw)
      pcol <- kwmatch(p_kw)

      if(!length(gcol)) gcol <- which(grepl("gene|symbol|ensembl|ensid",can))
      if(!length(lcol)) lcol <- which(grepl("log2.*fold|log2fc|logfc",can))
      if(!length(acol)) acol <- which(grepl("padj|adjustedp|fdr|qvalue",can))
      if(!length(pcol)) pcol <- which(grepl("^pvalue$|^pval$|^p$",can))

      if(length(gcol) && length(lcol) && (length(acol) || length(pcol))) {
        regions[[length(regions)+1L]] <- data.frame(
          workbook=wb,sheet=sh,header_row=rr,
          gene_col=paste(gcol,collapse=";"),
          lfc_col=paste(lcol,collapse=";"),
          padj_col=paste(acol,collapse=";"),
          p_col=paste(pcol,collapse=";"),
          header_text=paste(raw[nz],collapse=" | "),
          stringsAsFactors=FALSE
        )
      }
    }
  }
}

inv <- do.call(rbind,inventory)
reg <- if(length(regions)) do.call(rbind,regions) else data.frame(
  workbook=character(),sheet=character(),header_row=integer(),
  gene_col=character(),lfc_col=character(),padj_col=character(),
  p_col=character(),header_text=character()
)
hitdf <- if(length(hits)) do.call(rbind,hits) else data.frame(
  workbook=character(),gene=character(),sheet=character(),
  row=integer(),col=integer(),cell_text=character()
)
ctxdf <- if(length(contexts)) unique(do.call(rbind,contexts)) else data.frame(
  workbook=character(),gene=character(),sheet=character(),
  hit_row=integer(),context_row=integer(),row_text=character()
)

awrite(inv,OUT_INV)
awrite(reg,OUT_REG)
awrite(hitdf,OUT_HIT)
awrite(ctxdf,OUT_CTX)

fig4_regions <- sum(reg$workbook=="FIG4")
ed4_regions <- sum(reg$workbook=="EXTENDED_DATA_FIG4")
fig4_genes <- length(unique(hitdf$gene[hitdf$workbook=="FIG4"]))
ed4_genes <- length(unique(hitdf$gene[hitdf$workbook=="EXTENDED_DATA_FIG4"]))

add("Fig4 table-like gene/LFC/P regions",">=3",fig4_regions,
    if(fig4_regions>=3L) "PASS" else "HOLD")
add("Extended Data Fig4 table-like gene/LFC/P regions",">=1",ed4_regions,
    if(ed4_regions>=1L) "PASS" else "HOLD")
add("Primary25 symbols found in Fig4",">=20",fig4_genes,
    if(fig4_genes>=20L) "PASS" else "HOLD")
add("Primary25 symbols found in Extended Data Fig4",">=20",ed4_genes,
    if(ed4_genes>=20L) "PASS" else "HOLD")

aud <- do.call(rbind,A)
awrite(aud,OUT_AUD)

fails <- sum(aud$status=="FAIL")
holds <- sum(aud$status=="HOLD")

if(fails>0L || holds>0L) {
  twrite(c(
    "R3_STEP1C_FIG4_ED4_SOURCE_DISCOVERY_HOLD",
    paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
    paste0("hard_failures=",fails),
    paste0("hold_items=",holds),
    paste0("Fig4_table_regions=",fig4_regions),
    paste0("ED4_table_regions=",ed4_regions),
    paste0("Fig4_Primary25_unique=",fig4_genes),
    paste0("ED4_Primary25_unique=",ed4_genes),
    "statistical_recomputation=NO",
    "candidate_classification=NO",
    "next_action=Send Step1C outputs/log to ChatGPT."
  ),HOLD)
  logline("FINAL_GATE: R3_STEP1C_FIG4_ED4_SOURCE_DISCOVERY_HOLD")
  quit(save="no",status=132,runLast=FALSE)
}

twrite(c(
  "R3_STEP1C_FIG4_ED4_SOURCE_DISCOVERY_PASS",
  paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
  "Fig4_authority_file=44161_2025_672_MOESM6_ESM.xlsx",
  "ExtendedDataFig4_authority_file=44161_2025_672_MOESM12_ESM.xlsx",
  paste0("Fig4_table_regions=",fig4_regions),
  paste0("ExtendedDataFig4_table_regions=",ed4_regions),
  paste0("Fig4_Primary25_unique_genes=",fig4_genes),
  paste0("ExtendedDataFig4_Primary25_unique_genes=",ed4_genes),
  "published_Fig4_preSeptum_vs_ControlSeptum_DEG=3323",
  "published_Fig4_preSeptum_vs_preRV_DEG=404",
  "published_Fig4_preRV_vs_postSeptum_DEG=205",
  "published_EDFig4_preSeptum_vs_postSeptum_DEG=21",
  "same_site_unloading_sensitivity_n=3",
  "same_site_unloading_sensitivity_independent_validation=NO",
  "statistical_recomputation=NO",
  "candidate_classification=NO",
  "recovery_persistence_rule_frozen=NO",
  "next_stage=ChatGPT audit exact source-table semantics then author-stat extraction/checksum"
),PASS)

logline("FINAL_GATE: R3_STEP1C_FIG4_ED4_SOURCE_DISCOVERY_PASS")
quit(save="no",status=0,runLast=FALSE)
