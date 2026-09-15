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
# RV Project — R3 Step 1A
# NATURE FIG.5 SOURCE-DATA AUTHORITY DISCOVERY
#
# Purpose:
#   Determine whether the already-downloaded Nature Source Data Fig.5 workbook
#   contains the author-derived gene-level DESeq2 results for the exact published
#   n=21 contrast:
#
#       B-postPEA_septum  vs  B-prePEA_RV
#
#   If yes, this author-published raw-count-derived contrast can be used as the
#   statistical authority for the MAIN n=21 comparison, avoiding the invalid
#   practice of feeding GEO DESeq-normalized counts back into DESeq2.
#
# This is DISCOVERY / EXTRACTION ONLY:
#   - no DESeq2
#   - no limma
#   - no p.adjust
#   - no candidate classification
#   - no recovery/persistence calls
#
# It scans the workbook, identifies table-like regions, searches the exact
# frozen Primary25 gene symbols, and emits auditable candidate rows/contexts.
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

XLSX <- file.path(AUTH,"44161_2025_672_MOESM7_ESM.xlsx")

OUT_INV <- file.path(RES,"R3_STEP1A_FIG5_sheet_inventory.csv")
OUT_TABLES <- file.path(RES,"R3_STEP1A_FIG5_candidate_table_regions.csv")
OUT_HITS <- file.path(RES,"R3_STEP1A_FIG5_PRIMARY25_cell_hits.csv")
OUT_CONTEXT <- file.path(RES,"R3_STEP1A_FIG5_PRIMARY25_context_rows.csv")
OUT_AUD <- file.path(RES,"R3_STEP1A_FIG5_authority_discovery_audit.csv")
PASS <- file.path(RES,"R3_STEP1A_FIG5_SOURCE_AUTHORITY_DISCOVERY_PASS.txt")
HOLD <- file.path(RES,"R3_STEP1A_FIG5_SOURCE_AUTHORITY_DISCOVERY_HOLD.txt")
LOG <- file.path(LOGD,"R3_STEP1A_FIG5_SOURCE_AUTHORITY_DISCOVERY.log")

PRIMARY25 <- c(
  "LIPG","COMP","ALOX5","SPP1","GRIN2B","SLCO2A1","SP140","DNAH7",
  "JAK3","CSMD1","BIN2","VDR","IL21R","GMIP","SMAD7","ABCC3","KYNU",
  "PLSCR1","CP","SLC6A6","STXBP2","MYO1F","MPC2","CD163","CD72"
)

if(file.exists(LOG)) {
  old <- file.path(
    LOGD,
    paste0("R3_STEP1A_FIG5_SOURCE_AUTHORITY_DISCOVERY_",
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
    item=as.character(item), expected=as.character(expected),
    observed=as.character(observed), status=as.character(status),
    notes=as.character(notes), stringsAsFactors=FALSE
  )
  logline("[",status,"] ",item," | expected=",expected,
          " | observed=",observed)
}

logline("============================================================")
logline("R3 Step1A — Nature Fig.5 source-data authority discovery")
logline("NO statistical recomputation.")
logline("============================================================")

# Make unexpected R errors auditable in the same log. This does not change any
# scientific or statistical logic.
options(error=function() {
  msg <- geterrmessage()
  try(logline("[UNHANDLED_R_ERROR] ",gsub("[\r\n]+"," | ",msg)),silent=TRUE)
  try(twrite(c(
    "R3_STEP1A_FIG5_SOURCE_AUTHORITY_DISCOVERY_HOLD_RUNTIME_ERROR",
    paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
    paste0("error=",gsub("[\r\n]+"," | ",msg)),
    "statistical_recomputation=NO",
    "model_fit_executed=NO",
    "candidate_classification_executed=NO"
  ),HOLD),silent=TRUE)
  q(save="no",status=113,runLast=FALSE)
})

if(!file.exists(XLSX)) {
  twrite(c(
    "R3_STEP1A_FIG5_SOURCE_AUTHORITY_DISCOVERY_HOLD_MISSING_XLSX",
    paste0("required_file=",XLSX),
    "model_fit_executed=NO",
    "statistical_recomputation=NO"
  ),HOLD)
  logline("FINAL_GATE: R3_STEP1A_HOLD_MISSING_XLSX")
  quit(save="no",status=111,runLast=FALSE)
}

if(!requireNamespace("readxl",quietly=TRUE)) {
  stop("readxl package unavailable")
}

sheets <- readxl::excel_sheets(XLSX)
add("Fig5 workbook readable","YES","YES","PASS")
add("Fig5 sheet count",">=1",length(sheets),
    if(length(sheets)>=1L) "PASS" else "FAIL")

inventory <- list()
regions <- list()
hits <- list()
contexts <- list()

# Helper: safely read every cell as text without assuming headers.
read_sheet_text <- function(path,sh) {
  x <- suppressMessages(
    readxl::read_excel(
      path,sheet=sh,col_names=FALSE,.name_repair="minimal"
    )
  )
  if(!nrow(x) || !ncol(x)) return(matrix(character(),0,0))
  m <- as.matrix(data.frame(lapply(x,as.character),
                            check.names=FALSE,stringsAsFactors=FALSE))
  m[is.na(m)] <- ""
  m
}

# Header keyword families used only for discovery.
gene_kw <- c("gene","genes","gene symbol","symbol","external gene name",
             "ensembl gene","ensembl gene id","gene_name","geneid")
lfc_kw <- c("log2foldchange","log2fc","log2(fc)","log2 fold change",
            "log2 foldchange","logfc","fold change")
padj_kw <- c("padj","adjusted p","adjusted p value","adjusted p-value",
             "fdr","q value","qvalue")
p_kw <- c("pvalue","p value","p-value","p_val","pval")
base_kw <- c("basemean","base mean","mean normalized count",
             "mean normalized counts","average count")

for(si in seq_along(sheets)) {
  sh <- sheets[si]
  logline("[INFO] Reading sheet: ",sh)
  m <- read_sheet_text(XLSX,sh)

  if(!length(m)) {
    inventory[[length(inventory)+1L]] <- data.frame(
      sheet=sh,n_rows=0,n_cols=0,nonempty_cells=0,
      contains_prePEA_RV=FALSE,contains_postPEA_septum=FALSE,
      contains_n21=FALSE,PRIMARY25_unique_hits=0,
      stringsAsFactors=FALSE
    )
    next
  }

  nonempty <- sum(nzchar(trimws(m)))
  flat <- as.character(m)
  flat_low <- tolower(flat)

  has_pre <- any(grepl("prepea",flat_low) & grepl("rv",flat_low))
  has_post <- any(grepl("postpea",flat_low) & grepl("sept",flat_low))
  has_n21 <- any(grepl("n\\s*=\\s*21|n\\s*21",flat_low,perl=TRUE))

  # Exact Primary25 cell hits.
  sheet_genes <- character()
  for(g in PRIMARY25) {
    # Exact symbol boundary. Avoid CP matching words containing cp.
    pat <- paste0("(?i)(^|[^A-Za-z0-9])",g,"([^A-Za-z0-9]|$)")
    # grepl() on a matrix drops its dimensions. Rebuild a logical matrix
    # explicitly before which(..., arr.ind=TRUE), otherwise nrow(loc) can be
    # NULL and the script aborts before writing any audit output.
    mask <- matrix(
      grepl(pat, as.character(m), perl=TRUE),
      nrow=nrow(m), ncol=ncol(m)
    )
    loc <- which(mask,arr.ind=TRUE)
    if(nrow(loc) > 0L) {
      sheet_genes <- c(sheet_genes,g)
      for(k in seq_len(nrow(loc))) {
        rr <- loc[k,1]; cc <- loc[k,2]
        hits[[length(hits)+1L]] <- data.frame(
          gene=g,sheet=sh,row=rr,col=cc,
          cell_text=m[rr,cc],
          stringsAsFactors=FALSE
        )

        # Emit the entire nearby row (+/- 2 rows), preserving columns as a
        # pipe-delimited audit string.  This is discovery, not parsing results.
        lo <- max(1L,rr-2L); hi <- min(nrow(m),rr+2L)
        for(r0 in lo:hi) {
          vals <- m[r0,,drop=TRUE]
          keep <- nzchar(trimws(vals))
          contexts[[length(contexts)+1L]] <- data.frame(
            gene=g,sheet=sh,hit_row=rr,context_row=r0,
            row_text=paste(vals[keep],collapse=" | "),
            stringsAsFactors=FALSE
          )
        }
      }
    }
  }

  inventory[[length(inventory)+1L]] <- data.frame(
    sheet=sh,n_rows=nrow(m),n_cols=ncol(m),nonempty_cells=nonempty,
    contains_prePEA_RV=has_pre,
    contains_postPEA_septum=has_post,
    contains_n21=has_n21,
    PRIMARY25_unique_hits=length(unique(sheet_genes)),
    stringsAsFactors=FALSE
  )

  # Scan rows for possible table headers.
  mcanon <- apply(m,c(1,2),canon)
  maxscan <- min(nrow(m),500L)

  for(rr in seq_len(maxscan)) {
    row_raw <- m[rr,,drop=TRUE]
    row_can <- mcanon[rr,,drop=TRUE]
    nz <- which(nzchar(row_can))
    if(!length(nz)) next

    iskw <- function(kws) {
      kwc <- canon(kws)
      which(row_can %in% kwc)
    }

    gcol <- iskw(gene_kw)
    lcol <- iskw(lfc_kw)
    acol <- iskw(padj_kw)
    pcol <- iskw(p_kw)
    bcol <- iskw(base_kw)

    # Also allow substring matching for verbose headers.
    if(!length(gcol)) {
      gcol <- which(grepl("gene|symbol|ensembl",row_can))
    }
    if(!length(lcol)) {
      lcol <- which(grepl("log2.*fold|log2fc|logfc",row_can))
    }
    if(!length(acol)) {
      acol <- which(grepl("padj|adjustedp|fdr|qvalue",row_can))
    }
    if(!length(pcol)) {
      pcol <- which(grepl("^pvalue$|^pval$|^p$",row_can))
    }
    if(!length(bcol)) {
      bcol <- which(grepl("basemean|averagecount|meannormal",row_can))
    }

    if(length(gcol) && length(lcol) && (length(acol) || length(pcol))) {
      regions[[length(regions)+1L]] <- data.frame(
        sheet=sh,
        header_row=rr,
        gene_col=paste(gcol,collapse=";"),
        lfc_col=paste(lcol,collapse=";"),
        padj_col=paste(acol,collapse=";"),
        p_col=paste(pcol,collapse=";"),
        baseMean_col=paste(bcol,collapse=";"),
        header_text=paste(row_raw[nz],collapse=" | "),
        sheet_contains_prePEA_RV=has_pre,
        sheet_contains_postPEA_septum=has_post,
        sheet_contains_n21=has_n21,
        stringsAsFactors=FALSE
      )
    }
  }
}

inv <- do.call(rbind,inventory)
reg <- if(length(regions)) do.call(rbind,regions) else data.frame(
  sheet=character(),header_row=integer(),gene_col=character(),
  lfc_col=character(),padj_col=character(),p_col=character(),
  baseMean_col=character(),header_text=character(),
  sheet_contains_prePEA_RV=logical(),
  sheet_contains_postPEA_septum=logical(),
  sheet_contains_n21=logical()
)
hitdf <- if(length(hits)) do.call(rbind,hits) else data.frame(
  gene=character(),sheet=character(),row=integer(),col=integer(),
  cell_text=character()
)
ctxdf <- if(length(contexts)) unique(do.call(rbind,contexts)) else data.frame(
  gene=character(),sheet=character(),hit_row=integer(),
  context_row=integer(),row_text=character()
)

awrite(inv,OUT_INV)
awrite(reg,OUT_TABLES)
awrite(hitdf,OUT_HITS)
awrite(ctxdf,OUT_CONTEXT)

n_unique_genes <- length(unique(hitdf$gene))
n_regions <- nrow(reg)
candidate_sheets <- unique(reg$sheet[
  reg$sheet_contains_prePEA_RV & reg$sheet_contains_postPEA_septum
])

# The workbook may encode comparison identity in nearby text but not exactly
# within the same sheet.  Therefore this gate is allowed to PASS_DISCOVERY
# when:
#   - workbook is readable,
#   - at least one table-like gene/LFC/P region exists,
#   - at least 20/25 frozen genes are found somewhere in the workbook.
#
# Actual contrast-row extraction is deliberately deferred until ChatGPT audits
# these outputs and identifies the exact sheet/header semantics.
add("table-like gene/LFC/P regions",">=1",n_regions,
    if(n_regions>=1L) "PASS" else "HOLD")
add("Primary25 symbols found in Fig5 workbook",">=20",
    n_unique_genes,
    if(n_unique_genes>=20L) "PASS" else "HOLD")
add("candidate overall-contrast sheets","discovery only",
    if(length(candidate_sheets))
      paste(candidate_sheets,collapse=";") else "NONE_EXPLICIT",
    "INFO",
    "Exact sheet semantics require ChatGPT audit before extraction")

audit <- do.call(rbind,A)
awrite(audit,OUT_AUD)

hard_fail <- sum(audit$status=="FAIL")
holds <- sum(audit$status=="HOLD")

if(hard_fail>0L || holds>0L) {
  twrite(c(
    "R3_STEP1A_FIG5_SOURCE_AUTHORITY_DISCOVERY_HOLD",
    paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
    paste0("hard_failures=",hard_fail),
    paste0("hold_items=",holds),
    paste0("sheet_count=",length(sheets)),
    paste0("table_regions=",n_regions),
    paste0("Primary25_unique_genes_found=",n_unique_genes),
    "statistical_recomputation=NO",
    "model_fit_executed=NO",
    "candidate_classification_executed=NO",
    "next_action=Send Step1A outputs and log to ChatGPT."
  ),HOLD)
  logline("FINAL_GATE: R3_STEP1A_FIG5_SOURCE_AUTHORITY_DISCOVERY_HOLD")
  quit(save="no",status=112,runLast=FALSE)
}

twrite(c(
  "R3_STEP1A_FIG5_SOURCE_AUTHORITY_DISCOVERY_PASS",
  paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
  "authority_file=44161_2025_672_MOESM7_ESM.xlsx",
  paste0("sheet_count=",length(sheets)),
  paste0("table_like_regions=",n_regions),
  paste0("Primary25_unique_genes_found=",n_unique_genes),
  paste0("candidate_overall_contrast_sheets=",
         if(length(candidate_sheets))
           paste(candidate_sheets,collapse=";") else "NONE_EXPLICIT"),
  "main_published_contrast=B-postPEA_septum_vs_B-prePEA_RV_n21",
  "main_contrast_original_method=DESeq2_FROM_RAW_COUNT_MATRIX",
  "statistical_recomputation=NO",
  "model_fit_executed=NO",
  "candidate_classification_executed=NO",
  "recovery_persistence_rule_frozen=NO",
  "next_stage=ChatGPT audit exact Fig5 table semantics then freeze R3 analysis contract"
),PASS)

logline("FINAL_GATE: R3_STEP1A_FIG5_SOURCE_AUTHORITY_DISCOVERY_PASS")
quit(save="no",status=0,runLast=FALSE)
