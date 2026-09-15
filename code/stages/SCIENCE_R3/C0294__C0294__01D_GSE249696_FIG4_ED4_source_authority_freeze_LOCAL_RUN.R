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
# RV Project — R3 Step 1D
# FIG.4 + EXTENDED DATA FIG.4 AUTHOR-SOURCE AUTHORITY FREEZE
#
# Inputs already downloaded:
#   44161_2025_672_MOESM6_ESM.xlsx   (Source Data Fig.4)
#   44161_2025_672_MOESM12_ESM.xlsx  (Source Data Extended Data Fig.4)
#
# Exact panel semantics discovered in Step1C:
#
# Fig 4c:
#   Control_septum / B-prePEA_septum
#   published DEG count = 3323
#
# Fig 4e:
#   B-prePEA_RV / B-prePEA_septum
#   published DEG count = 404
#
# Fig 4f:
#   B-postPEA_septum / B-prePEA_RV
#   published DEG count = 205
#
# Extended Data Fig 4b:
#   B-postPEA_septum / B-prePEA_septum
#   SAME-SITE septum PRE -> POST comparison, same 3 patients
#   published DEG count = 21
#
# Published DEG rule:
#   baseMean >= 5
#   abs(log2FoldChange) >= 0.585
#   padj <= 0.05
#
# Mapping note frozen from the AUTHOR SOURCE TABLE:
#   Fig 4f contains 20/25 Primary25 genes.
#   Missing exactly: LIPG, GRIN2B, CSMD1, IL21R, STXBP2.
#   This is a source-table membership fact, not a statistical failure.
#
# This step:
#   - reads AUTHOR-PUBLISHED DESeq2 results
#   - checks exact panel orientation from the log2FC column header
#   - reproduces the published DEG counts as a checksum
#   - extracts Primary25 author statistics
#   - freezes source authority
#
# It DOES NOT:
#   - refit DESeq2/limma/edgeR
#   - recompute p-values/FDR
#   - classify recovered/persistent/indeterminate
# ==============================================================================

options(stringsAsFactors=FALSE, warn=1)

ROOT <- normalizePath(getwd(), winslash="/", mustWork=TRUE)
if(!identical(ROOT,RV_PROJECT_ROOT)) stop("Expected D:/RV_project")

AUTH <- file.path(ROOT,"data","authority","GSE249696")
RES  <- file.path(ROOT,"results","R3_GSE249696")
LOGD <- file.path(ROOT,"logs")
dir.create(RES,recursive=TRUE,showWarnings=FALSE)
dir.create(LOGD,recursive=TRUE,showWarnings=FALSE)

FIG4 <- file.path(AUTH,"44161_2025_672_MOESM6_ESM.xlsx")
ED4  <- file.path(AUTH,"44161_2025_672_MOESM12_ESM.xlsx")

OUT_AUD <- file.path(RES,"R3_STEP1D_FIG4_ED4_authority_audit.csv")
OUT_P25 <- file.path(RES,"R3_STEP1D_PRIMARY25_FIG4_ED4_author_stats.csv")
OUT_ALL_ED4 <- file.path(RES,"R3_STEP1D_ED4b_same_site_author_stats_minimal.csv.gz")
PASS <- file.path(RES,"R3_STEP1D_FIG4_ED4_SOURCE_AUTHORITY_FROZEN.txt")
HOLD <- file.path(RES,"R3_STEP1D_FIG4_ED4_SOURCE_AUTHORITY_HOLD.txt")
LOG <- file.path(LOGD,"R3_STEP1D_FIG4_ED4_SOURCE_AUTHORITY.log")

PRIMARY25 <- c(
  "LIPG","COMP","ALOX5","SPP1","GRIN2B","SLCO2A1","SP140","DNAH7",
  "JAK3","CSMD1","BIN2","VDR","IL21R","GMIP","SMAD7","ABCC3","KYNU",
  "PLSCR1","CP","SLC6A6","STXBP2","MYO1F","MPC2","CD163","CD72"
)

contract <- data.frame(
  workbook=c("FIG4","FIG4","FIG4","EXTENDED_DATA_FIG4"),
  sheet=c("Fig 4c","Fig 4e","Fig 4f","Extended Data Fig 4b"),
  contrast=c(
    "Control_septum_vs_B-prePEA_septum",
    "B-prePEA_RV_vs_B-prePEA_septum",
    "B-postPEA_septum_vs_B-prePEA_RV",
    "B-postPEA_septum_vs_B-prePEA_septum"
  ),
  lfc_header_expected=c(
    "log2FoldChange Control_septum/B-prePEA_septum",
    "log2FoldChange B-prePEA_RV/B-prePEA_septum",
    "log2FoldChange B-postPEA_septum/B-prePEA_RV",
    "log2FoldChange B-postPEA_septum/B-prePEA_septum"
  ),
  n_case_reference=c("3_vs_10","3_same_patients","3_same_patients","3_same_patients"),
  expected_DEG=c(3323L,404L,205L,21L),
  expected_unique_P25=c(25L,23L,20L,23L),
  expected_missing_P25=c(
    "",
    "LIPG;CSMD1",
    "LIPG;GRIN2B;CSMD1;IL21R;STXBP2",
    "LIPG;CSMD1"
  ),
  stringsAsFactors=FALSE
)

if(file.exists(LOG)) {
  old <- file.path(
    LOGD,
    paste0("R3_STEP1D_FIG4_ED4_SOURCE_AUTHORITY_",
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
gzwrite <- function(x,p) {
  t <- paste0(p,".tmp_",Sys.getpid())
  con <- gzfile(t,"wt")
  write.csv(x,con,row.names=FALSE,na="")
  close(con)
  if(file.exists(p)) unlink(p,force=TRUE)
  if(!file.rename(t,p)) {unlink(t); stop("Atomic GZ CSV failed: ",p)}
}
twrite <- function(x,p) {
  t <- paste0(p,".tmp_",Sys.getpid())
  writeLines(x,t,useBytes=TRUE)
  if(file.exists(p)) unlink(p,force=TRUE)
  if(!file.rename(t,p)) {unlink(t); stop("Atomic text failed: ",p)}
}

logline("============================================================")
logline("R3 Step1D — Fig4/ED4 source authority freeze")
logline("NO inferential-statistic recomputation.")
logline("============================================================")

missing <- c(FIG4,ED4)[!file.exists(c(FIG4,ED4))]
if(length(missing)) {
  twrite(c(
    "R3_STEP1D_FIG4_ED4_SOURCE_AUTHORITY_HOLD_MISSING_FILES",
    paste0("missing=",paste(missing,collapse=";")),
    "inferential_statistical_recomputation=NO",
    "candidate_classification=NO"
  ),HOLD)
  quit(save="no",status=141,runLast=FALSE)
}

if(!requireNamespace("readxl",quietly=TRUE)) stop("readxl unavailable")

options(error=function() {
  msg <- geterrmessage()
  try(logline("[UNHANDLED_R_ERROR] ",gsub("[\r\n]+"," | ",msg)),silent=TRUE)
  try(twrite(c(
    "R3_STEP1D_FIG4_ED4_SOURCE_AUTHORITY_HOLD_RUNTIME_ERROR",
    paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
    paste0("error=",gsub("[\r\n]+"," | ",msg)),
    "inferential_statistical_recomputation=NO"
  ),HOLD),silent=TRUE)
  q(save="no",status=144,runLast=FALSE)
})

get_book <- function(label) {
  if(label=="FIG4") FIG4 else ED4
}

read_author_table <- function(path,sh) {
  x <- suppressMessages(
    readxl::read_excel(path,sheet=sh,col_names=TRUE,.name_repair="minimal")
  )
  names(x) <- trimws(names(x))

  # Required invariant columns.
  exact_required <- c("Ensembl gene id","Ensembl gene","baseMean","pvalue","padj")
  miss <- setdiff(exact_required,names(x))
  if(length(miss)) {
    stop("Missing required columns in ",sh,": ",paste(miss,collapse=","))
  }

  lfc_col <- grep("^log2FoldChange",names(x),value=TRUE)
  if(length(lfc_col)!=1L) {
    stop("Expected exactly one log2FoldChange column in ",sh,
         "; observed=",paste(lfc_col,collapse=" | "))
  }

  bmA <- grep("^baseMeanA",names(x),value=TRUE)
  bmB <- grep("^baseMeanB",names(x),value=TRUE)

  y <- data.frame(
    ensid=as.character(x[["Ensembl gene id"]]),
    gene=as.character(x[["Ensembl gene"]]),
    baseMean=suppressWarnings(as.numeric(x[["baseMean"]])),
    baseMeanA=if(length(bmA)==1L)
      suppressWarnings(as.numeric(x[[bmA]])) else NA_real_,
    baseMeanB=if(length(bmB)==1L)
      suppressWarnings(as.numeric(x[[bmB]])) else NA_real_,
    log2FoldChange=suppressWarnings(as.numeric(x[[lfc_col]])),
    pvalue=suppressWarnings(as.numeric(x[["pvalue"]])),
    padj=suppressWarnings(as.numeric(x[["padj"]])),
    stringsAsFactors=FALSE
  )

  attr(y,"lfc_header") <- lfc_col
  attr(y,"baseMeanA_header") <- if(length(bmA)==1L) bmA else NA_character_
  attr(y,"baseMeanB_header") <- if(length(bmB)==1L) bmB else NA_character_
  y
}

tables <- list()
audit <- list()
p25_all <- list()

for(i in seq_len(nrow(contract))) {
  cc <- contract[i,]
  path <- get_book(cc$workbook)
  sh <- cc$sheet

  logline("[INFO] Reading ",cc$workbook," / ",sh)
  y <- read_author_table(path,sh)
  tables[[paste(cc$workbook,sh,sep="::")]] <- y

  lfc_header <- attr(y,"lfc_header")
  orient_ok <- identical(lfc_header,cc$lfc_header_expected)

  finite_core <- is.finite(y$baseMean) &
                 is.finite(y$log2FoldChange) &
                 is.finite(y$padj)

  isdeg <- finite_core &
           y$baseMean >= 5 &
           abs(y$log2FoldChange) >= 0.585 &
           y$padj <= 0.05

  obs_deg <- sum(isdeg,na.rm=TRUE)

  # Primary25 mapping audit.
  rows <- lapply(PRIMARY25,function(g) {
    z <- y[!is.na(y$gene) & y$gene==g,,drop=FALSE]
    if(nrow(z)==0L) {
      data.frame(
        gene=g,workbook=cc$workbook,sheet=sh,contrast=cc$contrast,
        mapping_status="NOT_PRESENT_IN_AUTHOR_SOURCE_TABLE",
        ensid=NA_character_,baseMean=NA_real_,baseMeanA=NA_real_,
        baseMeanB=NA_real_,log2FoldChange=NA_real_,
        pvalue=NA_real_,padj=NA_real_,
        author_DEG_by_published_rule=FALSE,
        stringsAsFactors=FALSE
      )
    } else if(nrow(z)>1L) {
      data.frame(
        gene=g,workbook=cc$workbook,sheet=sh,contrast=cc$contrast,
        mapping_status=paste0("AMBIGUOUS_N",nrow(z)),
        ensid=NA_character_,baseMean=NA_real_,baseMeanA=NA_real_,
        baseMeanB=NA_real_,log2FoldChange=NA_real_,
        pvalue=NA_real_,padj=NA_real_,
        author_DEG_by_published_rule=FALSE,
        stringsAsFactors=FALSE
      )
    } else {
      deg <- is.finite(z$baseMean) &&
             is.finite(z$log2FoldChange) &&
             is.finite(z$padj) &&
             z$baseMean>=5 &&
             abs(z$log2FoldChange)>=0.585 &&
             z$padj<=0.05
      data.frame(
        gene=g,workbook=cc$workbook,sheet=sh,contrast=cc$contrast,
        mapping_status="UNIQUE",
        ensid=z$ensid,baseMean=z$baseMean,baseMeanA=z$baseMeanA,
        baseMeanB=z$baseMeanB,log2FoldChange=z$log2FoldChange,
        pvalue=z$pvalue,padj=z$padj,
        author_DEG_by_published_rule=deg,
        stringsAsFactors=FALSE
      )
    }
  })
  p <- do.call(rbind,rows)
  p25_all[[i]] <- p

  unique_n <- sum(p$mapping_status=="UNIQUE")
  missing_genes <- p$gene[
    p$mapping_status=="NOT_PRESENT_IN_AUTHOR_SOURCE_TABLE"
  ]
  ambig_n <- sum(grepl("^AMBIGUOUS",p$mapping_status))

  expected_missing <- if(
    is.na(cc$expected_missing_P25) || !nzchar(cc$expected_missing_P25)
  ) character() else strsplit(cc$expected_missing_P25,";",fixed=TRUE)[[1]]

  mapping_ok <- (
    unique_n==cc$expected_unique_P25 &&
    ambig_n==0L &&
    identical(sort(missing_genes),sort(expected_missing))
  )

  checksum_ok <- obs_deg==cc$expected_DEG

  status <- if(orient_ok && checksum_ok && mapping_ok) "PASS" else "FAIL"

  audit[[i]] <- data.frame(
    workbook=cc$workbook,
    sheet=sh,
    contrast=cc$contrast,
    lfc_header_expected=cc$lfc_header_expected,
    lfc_header_observed=lfc_header,
    orientation_status=if(orient_ok) "PASS" else "FAIL",
    source_rows=nrow(y),
    expected_DEG=cc$expected_DEG,
    observed_DEG=obs_deg,
    DEG_checksum_status=if(checksum_ok) "PASS" else "FAIL",
    expected_unique_P25=cc$expected_unique_P25,
    observed_unique_P25=unique_n,
    expected_missing_P25=paste(expected_missing,collapse=";"),
    observed_missing_P25=paste(missing_genes,collapse=";"),
    ambiguous_P25=ambig_n,
    mapping_status=if(mapping_ok) "PASS" else "FAIL",
    final_status=status,
    stringsAsFactors=FALSE
  )

  logline("[",status,"] ",sh,
          " | orientation=",if(orient_ok) "PASS" else "FAIL",
          " | DEG=",obs_deg,"/",cc$expected_DEG,
          " | P25 unique=",unique_n)
}

aud <- do.call(rbind,audit)
p25 <- do.call(rbind,p25_all)
awrite(aud,OUT_AUD)
awrite(p25,OUT_P25)

if(any(aud$final_status!="PASS")) {
  twrite(c(
    "R3_STEP1D_FIG4_ED4_SOURCE_AUTHORITY_HOLD",
    paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
    paste0("failed_panels=",
           paste(aud$sheet[aud$final_status!="PASS"],collapse=";")),
    "inferential_statistical_recomputation=NO",
    "recovery_persistence_classification=NO",
    "next_action=Return Step1D audit/log to ChatGPT."
  ),HOLD)
  logline("FINAL_GATE: R3_STEP1D_FIG4_ED4_SOURCE_AUTHORITY_HOLD")
  quit(save="no",status=142,runLast=FALSE)
}

# Write the complete same-site n=3 author table for later sensitivity logic.
same <- tables[["EXTENDED_DATA_FIG4::Extended Data Fig 4b"]]
same$author_DEG_by_published_rule <- (
  is.finite(same$baseMean) &
  is.finite(same$log2FoldChange) &
  is.finite(same$padj) &
  same$baseMean >= 5 &
  abs(same$log2FoldChange) >= 0.585 &
  same$padj <= 0.05
)
same$author_change_direction <- ifelse(
  same$author_DEG_by_published_rule,
  ifelse(same$log2FoldChange>0,
         "UP_POST_SEPTUM_VS_PRE_SEPTUM",
         "DOWN_POST_SEPTUM_VS_PRE_SEPTUM"),
  "NOT_DEG_BY_PUBLISHED_RULE"
)
gzwrite(same,OUT_ALL_ED4)

twrite(c(
  "R3_STEP1D_FIG4_ED4_SOURCE_AUTHORITY_FROZEN",
  paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
  "Fig4_authority_file=44161_2025_672_MOESM6_ESM.xlsx",
  "ExtendedDataFig4_authority_file=44161_2025_672_MOESM12_ESM.xlsx",
  "published_DEG_rule=baseMean>=5_AND_abs_log2FC>=0.585_AND_padj<=0.05",
  "Fig4c_contrast=Control_septum_vs_B-prePEA_septum",
  "Fig4c_orientation=CONTROL_SEPTUM_MINUS_PREPEA_SEPTUM",
  "Fig4c_DEG=3323",
  "Fig4e_contrast=B-prePEA_RV_vs_B-prePEA_septum",
  "Fig4e_orientation=PREPEA_RV_MINUS_PREPEA_SEPTUM",
  "Fig4e_DEG=404",
  "Fig4f_contrast=B-postPEA_septum_vs_B-prePEA_RV",
  "Fig4f_orientation=POSTPEA_SEPTUM_MINUS_PREPEA_RV",
  "Fig4f_DEG=205",
  "EDFig4b_contrast=B-postPEA_septum_vs_B-prePEA_septum",
  "EDFig4b_orientation=POSTPEA_SEPTUM_MINUS_PREPEA_SEPTUM",
  "EDFig4b_same_anatomical_site=YES",
  "EDFig4b_same_patients_n=3",
  "EDFig4b_independent_validation=NO",
  "EDFig4b_DEG=21",
  "EDFig4b_Primary25_unique_present=23",
  "EDFig4b_Primary25_not_present=LIPG;CSMD1",
  "author_stats_source=RAW_COUNT_DERIVED_DESEQ2_RESULTS_AS_PUBLISHED_IN_NATURE_SOURCE_DATA",
  "local_processed_normalized_matrix_used_for_DESeq2=NO",
  "inferential_statistical_recomputation=NO",
  "recovery_persistence_classification=NO",
  "next_stage=ChatGPT audit then final R3 recovery/reversal/persistence classification contract"
),PASS)

logline("FINAL_GATE: R3_STEP1D_FIG4_ED4_SOURCE_AUTHORITY_FROZEN")
quit(save="no",status=0,runLast=FALSE)
