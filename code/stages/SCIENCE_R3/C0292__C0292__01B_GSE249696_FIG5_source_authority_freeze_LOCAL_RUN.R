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
# RV Project — R3 Step 1B
# NATURE FIG.5 SOURCE-DATA PANEL ADJUDICATION + AUTHOR STAT EXTRACTION
#
# Uses the already-downloaded Nature Fig.5 source-data workbook:
#   44161_2025_672_MOESM7_ESM.xlsx
#
# Published Fig.5 panel semantics:
#   Fig 5c: B-postPEA_septum vs B-prePEA_RV, n=21 paired patients
#   Fig 5d: moderate-risk subgroup, n=9
#   Fig 5e: intermediate-risk subgroup, n=8
#   Fig 5f: severe-risk subgroup, n=4
#
# Published DEG rule:
#   baseMean >= 5
#   abs(log2FoldChange) >= 0.585
#   padj <= 0.05
#
# Published counts used ONLY as an authority checksum:
#   Fig5c overall:      1492 = 891 up + 601 down
#   Fig5d moderate:     1082 = 615 up + 467 down
#   Fig5e intermediate:  701 = 306 up + 395 down
#   Fig5f severe:       1026 = 520 up + 506 down
#
# This step DOES NOT refit or recompute inferential statistics.
# It only:
#   1) reads author-provided DESeq2 result columns from Nature source data
#   2) applies the published display/DEG rule as a checksum
#   3) freezes panel-to-contrast semantics if counts match exactly
#   4) extracts the frozen Primary25 author statistics
#   5) writes a minimal all-gene Fig5c authority table for later program analysis
#
# NO DESeq2 / limma / edgeR / p.adjust.
# NO recovery/persistence classification.
# ==============================================================================

options(stringsAsFactors=FALSE, warn=1)

ROOT <- normalizePath(getwd(), winslash="/", mustWork=TRUE)
if(!identical(ROOT,RV_PROJECT_ROOT)) stop("Expected D:/RV_project")

AUTH <- file.path(ROOT,"data","authority","GSE249696")
RES  <- file.path(ROOT,"results","R3_GSE249696")
LOGD <- file.path(ROOT,"logs")
dir.create(RES,recursive=TRUE,showWarnings=FALSE)
dir.create(LOGD,recursive=TRUE,showWarnings=FALSE)

XLSX <- file.path(AUTH,"44161_2025_672_MOESM7_ESM.xlsx")

OUT_AUD <- file.path(RES,"R3_STEP1B_FIG5_panel_mapping_audit.csv")
OUT_P25 <- file.path(RES,"R3_STEP1B_PRIMARY25_author_unloading_stats.csv")
OUT_P25_ALL <- file.path(RES,"R3_STEP1B_PRIMARY25_all_FIG5_panels.csv")
OUT_ALL <- file.path(RES,"R3_STEP1B_FIG5c_author_overall_stats_minimal.csv.gz")
PASS <- file.path(RES,"R3_STEP1B_FIG5_SOURCE_AUTHORITY_FROZEN.txt")
HOLD <- file.path(RES,"R3_STEP1B_FIG5_SOURCE_AUTHORITY_HOLD.txt")
LOG <- file.path(LOGD,"R3_STEP1B_FIG5_SOURCE_AUTHORITY.log")

PRIMARY25 <- c(
  "LIPG","COMP","ALOX5","SPP1","GRIN2B","SLCO2A1","SP140","DNAH7",
  "JAK3","CSMD1","BIN2","VDR","IL21R","GMIP","SMAD7","ABCC3","KYNU",
  "PLSCR1","CP","SLC6A6","STXBP2","MYO1F","MPC2","CD163","CD72"
)

panel_contract <- data.frame(
  sheet=c("Fig 5c","Fig 5d","Fig 5e","Fig 5f"),
  contrast=c(
    "B-postPEA_septum_vs_B-prePEA_RV",
    "B-postPEAm_septum_vs_B-prePEAm_RV",
    "B-postPEAi_septum_vs_B-prePEAi_RV",
    "B-postPEAs_septum_vs_B-prePEAs_RV"
  ),
  n_pairs=c(21L,9L,8L,4L),
  risk_group=c("ALL","MODERATE","INTERMEDIATE","SEVERE"),
  expected_DEG=c(1492L,1082L,701L,1026L),
  expected_up=c(891L,615L,306L,520L),
  expected_down=c(601L,467L,395L,506L),
  stringsAsFactors=FALSE
)

if(file.exists(LOG)) {
  old <- file.path(
    LOGD,
    paste0("R3_STEP1B_FIG5_SOURCE_AUTHORITY_",
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
  on.exit(try(close(con),silent=TRUE),add=TRUE)
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
logline("R3 Step1B — Fig5 source authority adjudication/extraction")
logline("NO inferential-statistic recomputation.")
logline("============================================================")

if(!file.exists(XLSX)) {
  twrite(c(
    "R3_STEP1B_FIG5_SOURCE_AUTHORITY_HOLD_MISSING_XLSX",
    paste0("required_file=",XLSX),
    "statistical_recomputation=NO"
  ),HOLD)
  quit(save="no",status=121,runLast=FALSE)
}

if(!requireNamespace("readxl",quietly=TRUE)) stop("readxl unavailable")

sheets <- readxl::excel_sheets(XLSX)
missing_sheets <- setdiff(panel_contract$sheet,sheets)
if(length(missing_sheets)) {
  twrite(c(
    "R3_STEP1B_FIG5_SOURCE_AUTHORITY_HOLD",
    paste0("missing_sheets=",paste(missing_sheets,collapse=";")),
    "statistical_recomputation=NO"
  ),HOLD)
  quit(save="no",status=122,runLast=FALSE)
}

# Normalize a source-data table to exact minimal author columns.
read_author_table <- function(sh) {
  x <- suppressMessages(
    readxl::read_excel(XLSX,sheet=sh,col_names=TRUE,.name_repair="minimal")
  )
  names(x) <- trimws(names(x))

  # Exact expected headers from the source workbook.
  required <- c("ensid","Ensembl.gene","baseMean","log2FoldChange","pvalue","padj")
  miss <- setdiff(required,names(x))
  if(length(miss)) {
    stop("Missing required columns in ",sh,": ",paste(miss,collapse=","))
  }

  y <- data.frame(
    ensid=as.character(x[["ensid"]]),
    gene=as.character(x[["Ensembl.gene"]]),
    baseMean=suppressWarnings(as.numeric(x[["baseMean"]])),
    log2FoldChange=suppressWarnings(as.numeric(x[["log2FoldChange"]])),
    pvalue=suppressWarnings(as.numeric(x[["pvalue"]])),
    padj=suppressWarnings(as.numeric(x[["padj"]])),
    stringsAsFactors=FALSE
  )
  y
}

tables <- list()
audit <- list()

for(i in seq_len(nrow(panel_contract))) {
  pc <- panel_contract[i,]
  sh <- pc$sheet
  logline("[INFO] Reading author table: ",sh)
  y <- read_author_table(sh)
  tables[[sh]] <- y

  finite_core <- is.finite(y$baseMean) & is.finite(y$log2FoldChange) &
                 is.finite(y$padj)
  isdeg <- finite_core &
           y$baseMean >= 5 &
           abs(y$log2FoldChange) >= 0.585 &
           y$padj <= 0.05
  up <- isdeg & y$log2FoldChange > 0
  down <- isdeg & y$log2FoldChange < 0

  obs_deg <- sum(isdeg,na.rm=TRUE)
  obs_up <- sum(up,na.rm=TRUE)
  obs_down <- sum(down,na.rm=TRUE)

  status <- if(
    obs_deg==pc$expected_DEG &&
    obs_up==pc$expected_up &&
    obs_down==pc$expected_down
  ) "PASS" else "FAIL"

  audit[[i]] <- data.frame(
    sheet=sh,
    contrast=pc$contrast,
    n_pairs=pc$n_pairs,
    risk_group=pc$risk_group,
    source_rows=nrow(y),
    expected_DEG=pc$expected_DEG,
    observed_DEG=obs_deg,
    expected_up=pc$expected_up,
    observed_up=obs_up,
    expected_down=pc$expected_down,
    observed_down=obs_down,
    checksum_status=status,
    stringsAsFactors=FALSE
  )

  logline("[",status,"] ",sh,
          " | DEG ",obs_deg,"/",pc$expected_DEG,
          " | up ",obs_up,"/",pc$expected_up,
          " | down ",obs_down,"/",pc$expected_down)
}

aud <- do.call(rbind,audit)
awrite(aud,OUT_AUD)

if(any(aud$checksum_status!="PASS")) {
  twrite(c(
    "R3_STEP1B_FIG5_SOURCE_AUTHORITY_HOLD",
    paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
    "reason=PUBLISHED_DEG_COUNT_CHECKSUM_MISMATCH",
    paste0("failed_sheets=",
           paste(aud$sheet[aud$checksum_status!="PASS"],collapse=";")),
    "statistical_recomputation=NO",
    "recovery_persistence_classification=NO",
    "next_action=Return audit/log to ChatGPT."
  ),HOLD)
  logline("FINAL_GATE: R3_STEP1B_FIG5_SOURCE_AUTHORITY_HOLD")
  quit(save="no",status=123,runLast=FALSE)
}

# --------------------------------------------------------------------------
# Freeze overall Fig5c author source as the main n=21 statistical authority.
# --------------------------------------------------------------------------

overall <- tables[["Fig 5c"]]
overall$author_DEG_by_published_rule <- (
  is.finite(overall$baseMean) &
  is.finite(overall$log2FoldChange) &
  is.finite(overall$padj) &
  overall$baseMean >= 5 &
  abs(overall$log2FoldChange) >= 0.585 &
  overall$padj <= 0.05
)
overall$author_DEG_direction <- ifelse(
  overall$author_DEG_by_published_rule,
  ifelse(overall$log2FoldChange>0,"UP_POST_VS_PRE","DOWN_POST_VS_PRE"),
  "NOT_DEG_BY_PUBLISHED_RULE"
)
gzwrite(overall,OUT_ALL)

# Primary25 extraction from exact gene-symbol column.
extract_p25 <- function(y,sh,contrast,risk_group,n_pairs) {
  out <- lapply(PRIMARY25,function(g) {
    z <- y[!is.na(y$gene) & y$gene==g,,drop=FALSE]
    if(nrow(z)==0L) {
      data.frame(
        gene=g,sheet=sh,contrast=contrast,risk_group=risk_group,
        n_pairs=n_pairs,mapping_status="NOT_MAPPED",
        ensid=NA_character_,baseMean=NA_real_,log2FoldChange=NA_real_,
        pvalue=NA_real_,padj=NA_real_,
        author_DEG_by_published_rule=FALSE,
        author_DEG_direction=NA_character_,
        stringsAsFactors=FALSE
      )
    } else if(nrow(z)>1L) {
      data.frame(
        gene=g,sheet=sh,contrast=contrast,risk_group=risk_group,
        n_pairs=n_pairs,mapping_status=paste0("AMBIGUOUS_N",nrow(z)),
        ensid=NA_character_,baseMean=NA_real_,log2FoldChange=NA_real_,
        pvalue=NA_real_,padj=NA_real_,
        author_DEG_by_published_rule=FALSE,
        author_DEG_direction=NA_character_,
        stringsAsFactors=FALSE
      )
    } else {
      deg <- is.finite(z$baseMean) && is.finite(z$log2FoldChange) &&
             is.finite(z$padj) && z$baseMean>=5 &&
             abs(z$log2FoldChange)>=0.585 && z$padj<=0.05
      data.frame(
        gene=g,sheet=sh,contrast=contrast,risk_group=risk_group,
        n_pairs=n_pairs,mapping_status="UNIQUE",
        ensid=z$ensid,baseMean=z$baseMean,
        log2FoldChange=z$log2FoldChange,pvalue=z$pvalue,padj=z$padj,
        author_DEG_by_published_rule=deg,
        author_DEG_direction=if(deg)
          ifelse(z$log2FoldChange>0,"UP_POST_VS_PRE","DOWN_POST_VS_PRE")
          else "NOT_DEG_BY_PUBLISHED_RULE",
        stringsAsFactors=FALSE
      )
    }
  })
  do.call(rbind,out)
}

pall <- list()
for(i in seq_len(nrow(panel_contract))) {
  pc <- panel_contract[i,]
  pall[[i]] <- extract_p25(
    tables[[pc$sheet]],pc$sheet,pc$contrast,pc$risk_group,pc$n_pairs
  )
}
p25_all <- do.call(rbind,pall)
awrite(p25_all,OUT_P25_ALL)

p25 <- p25_all[p25_all$sheet=="Fig 5c",,drop=FALSE]
awrite(p25,OUT_P25)

unique_n <- sum(p25$mapping_status=="UNIQUE")
ambig_n <- sum(grepl("^AMBIGUOUS",p25$mapping_status))
unmapped_n <- sum(p25$mapping_status=="NOT_MAPPED")

if(unique_n!=25L || ambig_n!=0L || unmapped_n!=0L) {
  twrite(c(
    "R3_STEP1B_FIG5_SOURCE_AUTHORITY_HOLD",
    paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
    "reason=PRIMARY25_MAPPING_NOT_EXACT",
    paste0("unique=",unique_n),
    paste0("ambiguous=",ambig_n),
    paste0("unmapped=",unmapped_n),
    "statistical_recomputation=NO",
    "recovery_persistence_classification=NO"
  ),HOLD)
  logline("FINAL_GATE: R3_STEP1B_FIG5_SOURCE_AUTHORITY_HOLD")
  quit(save="no",status=124,runLast=FALSE)
}

twrite(c(
  "R3_STEP1B_FIG5_SOURCE_AUTHORITY_FROZEN",
  paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
  "authority_file=44161_2025_672_MOESM7_ESM.xlsx",
  "overall_authority_sheet=Fig 5c",
  "overall_contrast=B-postPEA_septum_vs_B-prePEA_RV",
  "overall_n_pairs=21",
  "overall_orientation=POST_MINUS_PRE",
  "overall_anatomical_design=POST_SEPTUM_MINUS_PRE_RV_FREE_WALL",
  "site_confound_complete=YES",
  "moderate_sheet=Fig 5d",
  "moderate_n_pairs=9",
  "intermediate_sheet=Fig 5e",
  "intermediate_n_pairs=8",
  "severe_sheet=Fig 5f",
  "severe_n_pairs=4",
  "published_DEG_rule=baseMean>=5_AND_abs_log2FC>=0.585_AND_padj<=0.05",
  "Fig5c_DEG=1492",
  "Fig5c_up=891",
  "Fig5c_down=601",
  "Fig5d_DEG=1082",
  "Fig5e_DEG=701",
  "Fig5f_DEG=1026",
  "Primary25_unique_mapped=25",
  "main_author_stats_source=RAW_COUNT_DERIVED_DESEQ2_RESULTS_AS_PUBLISHED_IN_NATURE_SOURCE_DATA",
  "local_processed_normalized_matrix_used_for_DESeq2=NO",
  "inferential_statistical_recomputation=NO",
  "recovery_persistence_classification=NO",
  "next_stage=ChatGPT audit then same-site/control author-source authority acquisition and final R3 recovery-persistence contract"
),PASS)

logline("FINAL_GATE: R3_STEP1B_FIG5_SOURCE_AUTHORITY_FROZEN")
quit(save="no",status=0,runLast=FALSE)
