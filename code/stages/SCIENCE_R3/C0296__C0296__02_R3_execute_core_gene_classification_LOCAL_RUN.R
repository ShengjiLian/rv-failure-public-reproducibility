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
# RV Project — R3 Step 2
# EXECUTE FROZEN PRIMARY25 REVERSAL / NONREVERSAL CLASSIFICATION
#
# Requires frozen Step1E contract.
#
# This step does NOT fit any statistical model and does NOT recompute P/FDR.
# It only joins already-frozen author/R0 authorities and applies the frozen
# classification logic exactly.
# ==============================================================================

options(stringsAsFactors=FALSE, warn=1)

ROOT <- normalizePath(getwd(), winslash="/", mustWork=TRUE)
if(!identical(tolower(ROOT),tolower(RV_PROJECT_ROOT))) stop("Expected D:/RV_project")

RES   <- file.path(ROOT,"results","R3_GSE249696")
R0RES <- file.path(ROOT,"results","R0","v4_LOCAL_RUN")
R1RES <- file.path(ROOT,"results","R1_GSE240921")
LOGD  <- file.path(ROOT,"logs")
dir.create(RES,recursive=TRUE,showWarnings=FALSE)
dir.create(LOGD,recursive=TRUE,showWarnings=FALSE)

CONTRACT <- file.path(RES,"R3_STEP1E_CLASSIFICATION_CONTRACT_FROZEN.txt")
RULES    <- file.path(RES,"R3_STEP1E_core_gene_classification_rules.csv")
R0SIG    <- file.path(R0RES,"R0_FINAL_RVF_vs_pRV_FDR05.csv")
R1P25    <- file.path(R1RES,"R1_GSE240921_FINAL_PRIMARY25.csv")
MAIN21   <- file.path(RES,"R3_STEP1B_PRIMARY25_author_unloading_stats.csv")
FIG4ALL  <- file.path(RES,"R3_STEP1D_PRIMARY25_FIG4_ED4_author_stats.csv")

OUT_AUD <- file.path(RES,"R3_STEP2_authority_consistency_audit.csv")
OUT <- file.path(RES,"R3_STEP2_PRIMARY25_classification.csv")
OUT_SUM <- file.path(RES,"R3_STEP2_PRIMARY25_class_summary.csv")
PASS <- file.path(RES,"R3_STEP2_CORE_GENE_CLASSIFICATION_PASS.txt")
HOLD <- file.path(RES,"R3_STEP2_CORE_GENE_CLASSIFICATION_HOLD.txt")
LOG <- file.path(LOGD,"R3_STEP2_CORE_GENE_CLASSIFICATION.log")

PRIMARY25 <- c(
  "LIPG","COMP","ALOX5","SPP1","GRIN2B","SLCO2A1","SP140","DNAH7",
  "JAK3","CSMD1","BIN2","VDR","IL21R","GMIP","SMAD7","ABCC3","KYNU",
  "PLSCR1","CP","SLC6A6","STXBP2","MYO1F","MPC2","CD163","CD72"
)

if(file.exists(LOG)) {
  old <- file.path(LOGD,paste0(
    "R3_STEP2_CORE_GENE_CLASSIFICATION_",
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
awrite <- function(x,p) {
  t <- paste0(p,".tmp_",Sys.getpid())
  write.csv(x,t,row.names=FALSE,na="")
  if(file.exists(p)) unlink(p,force=TRUE)
  if(!file.rename(t,p)) { unlink(t); stop("Atomic CSV failed: ",p) }
}
twrite <- function(x,p) {
  t <- paste0(p,".tmp_",Sys.getpid())
  writeLines(x,t,useBytes=TRUE)
  if(file.exists(p)) unlink(p,force=TRUE)
  if(!file.rename(t,p)) { unlink(t); stop("Atomic text failed: ",p) }
}

A <- list()
add <- function(item,expected,observed,status,notes="") {
  A[[length(A)+1L]] <<- data.frame(
    item=as.character(item),expected=as.character(expected),
    observed=as.character(observed),status=as.character(status),
    notes=as.character(notes),stringsAsFactors=FALSE
  )
  logline("[",status,"] ",item," | expected=",expected,
          " | observed=",observed,
          if(nzchar(notes)) paste0(" | ",notes) else "")
}

finish_hold <- function(reason,code=162L) {
  if(length(A)) awrite(do.call(rbind,A),OUT_AUD)
  twrite(c(
    "R3_STEP2_CORE_GENE_CLASSIFICATION_HOLD",
    paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
    paste0("reason=",reason),
    "statistical_model_fit=NO",
    "pvalue_recomputation=NO",
    "FDR_recomputation=NO"
  ),HOLD)
  logline("FINAL_GATE: R3_STEP2_CORE_GENE_CLASSIFICATION_HOLD | ",reason)
  quit(save="no",status=code,runLast=FALSE)
}

logline("============================================================")
logline("R3 Step2 — execute frozen Primary25 classification")
logline("NO statistical model fit / NO P/FDR recomputation.")
logline("============================================================")

options(error=function() {
  msg <- geterrmessage()
  try(logline("[UNHANDLED_R_ERROR] ",gsub("[\r\n]+"," | ",msg)),silent=TRUE)
  try(twrite(c(
    "R3_STEP2_CORE_GENE_CLASSIFICATION_HOLD_RUNTIME_ERROR",
    paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
    paste0("error=",gsub("[\r\n]+"," | ",msg)),
    "statistical_model_fit=NO",
    "FDR_recomputation=NO"
  ),HOLD),silent=TRUE)
  q(save="no",status=163,runLast=FALSE)
})

for(p in c(CONTRACT,RULES,R0SIG,R1P25,MAIN21,FIG4ALL)) {
  add(paste0("file_exists:",basename(p)),"YES",
      if(file.exists(p)) "YES" else "NO",
      if(file.exists(p)) "PASS" else "FAIL")
}
if(any(vapply(A,function(z) any(z$status=="FAIL"),logical(1))))
  finish_hold("MISSING_REQUIRED_FROZEN_INPUT",164L)

ct <- readLines(CONTRACT,warn=FALSE)
need_contract <- c(
  "universe=FROZEN_PRIMARY25",
  "failure_direction_source=FROZEN_R0_RVF_vs_pRV_UNSHRUNK_LFC",
  "main_authority=FIG5C_N21_POST_SEPTUM_MINUS_PRE_RV",
  "main_site_confound_complete=YES",
  "same_site_authority=EXTENDED_DATA_FIG4B_N3_POST_SEPTUM_MINUS_PRE_SEPTUM",
  "same_site_independent_validation=NO",
  "nonsignificance_implies_persistence=NO",
  "irreversible_wording_allowed=NO",
  "classification_executed=NO"
)
for(x in need_contract) {
  ok <- any(ct==x)
  add(paste0("contract:",sub("=.*$","",x)),x,
      if(ok) x else "<MISSING_OR_CHANGED>",
      if(ok) "PASS" else "FAIL")
}
if(any(do.call(rbind,A)$status=="FAIL"))
  finish_hold("STEP1E_CONTRACT_MISMATCH",165L)

rules <- read.csv(RULES,stringsAsFactors=FALSE,check.names=FALSE)
expected_classes <- c(
  "REVERSAL_SUPPORTED",
  "MALADAPTIVE_NONREVERSAL_WORSENING_SUPPORTED",
  "SITE_CONFLICT","MAIN_ONLY_UNRESOLVED",
  "INDETERMINATE_NO_MAIN_DEG","UNASSESSABLE"
)
add("Step1E rule classes","exact 6-class frozen set",
    paste(sort(as.character(rules$class)),collapse=";"),
    if(setequal(as.character(rules$class),expected_classes) &&
       nrow(rules)==6L) "PASS" else "FAIL")
if(any(do.call(rbind,A)$status=="FAIL"))
  finish_hold("STEP1E_RULE_TABLE_MISMATCH",166L)

r0 <- read.csv(R0SIG,stringsAsFactors=FALSE,check.names=FALSE)
r1 <- read.csv(R1P25,stringsAsFactors=FALSE,check.names=FALSE)
m21 <- read.csv(MAIN21,stringsAsFactors=FALSE,check.names=FALSE)
f4 <- read.csv(FIG4ALL,stringsAsFactors=FALSE,check.names=FALSE)

# -------------------------- frozen R0/R1 carrier ---------------------------
req0 <- c("gene_id","log2FoldChange","primary_FDR_lt_0_05")
req1 <- c("r0_gene_id","r0_log2FC","primary_replicated")
reqm <- c("gene","mapping_status","baseMean","log2FoldChange",
          "pvalue","padj","author_DEG_by_published_rule")
reqf <- c("gene","sheet","mapping_status","baseMean","log2FoldChange",
          "pvalue","padj","author_DEG_by_published_rule")

for(z in list(
  list("R0",req0,names(r0)),
  list("R1P25",req1,names(r1)),
  list("MAIN21",reqm,names(m21)),
  list("FIG4",reqf,names(f4))
)) {
  miss <- setdiff(z[[2]],z[[3]])
  add(paste0(z[[1]]," required columns"),"NONE",
      if(length(miss)) paste(miss,collapse=";") else "NONE",
      if(length(miss)==0L) "PASS" else "FAIL")
}
if(any(do.call(rbind,A)$status=="FAIL"))
  finish_hold("INPUT_SCHEMA_MISMATCH",167L)

r0$gene_id <- trimws(as.character(r0$gene_id))
r1$r0_gene_id <- trimws(as.character(r1$r0_gene_id))
m21$gene <- trimws(as.character(m21$gene))
f4$gene <- trimws(as.character(f4$gene))
f4$sheet <- trimws(as.character(f4$sheet))

add("R0 frozen FDR family rows","330",nrow(r0),
    if(nrow(r0)==330L && length(unique(r0$gene_id))==330L) "PASS" else "FAIL")
add("R1 final Primary25 rows","25",nrow(r1),
    if(nrow(r1)==25L && setequal(r1$r0_gene_id,PRIMARY25)) "PASS" else "FAIL")
add("R1 Primary25 all primary_replicated","YES",
    if(nrow(r1)==25L && all(as.logical(r1$primary_replicated))) "YES" else "NO",
    if(nrow(r1)==25L && all(as.logical(r1$primary_replicated))) "PASS" else "FAIL")
add("Main21 exact Primary25","YES",
    if(nrow(m21)==25L && setequal(m21$gene,PRIMARY25)) "YES" else "NO",
    if(nrow(m21)==25L && setequal(m21$gene,PRIMARY25)) "PASS" else "FAIL")

ed <- f4[f4$sheet=="Extended Data Fig 4b",,drop=FALSE]
f4c <- f4[f4$sheet=="Fig 4c",,drop=FALSE]
f4e <- f4[f4$sheet=="Fig 4e",,drop=FALSE]
f4f <- f4[f4$sheet=="Fig 4f",,drop=FALSE]

for(pair in list(c("EDFig4b",nrow(ed),setequal(ed$gene,PRIMARY25)),
                 c("Fig4c",nrow(f4c),setequal(f4c$gene,PRIMARY25)),
                 c("Fig4e",nrow(f4e),setequal(f4e$gene,PRIMARY25)),
                 c("Fig4f",nrow(f4f),setequal(f4f$gene,PRIMARY25)))) {
  nm <- pair[[1]]
  nr <- as.integer(pair[[2]])
  okset <- as.logical(pair[[3]])
  add(paste0(nm," exact Primary25"),"25 rows + exact set",
      paste0(nr," rows; set=",okset),
      if(nr==25L && okset) "PASS" else "FAIL")
}

if(any(do.call(rbind,A)$status=="FAIL"))
  finish_hold("FROZEN_FAMILY_IDENTITY_FAIL",168L)

# Cross-check the R1 carrier of the R0 direction against the actual frozen R0
# FDR05 table. This prevents any indirect direction drift.
mi0 <- match(r1$r0_gene_id,r0$gene_id)
r1_eff <- as.numeric(r1$r0_log2FC)
r0_eff <- as.numeric(r0$log2FoldChange[mi0])
cross_ok <- all(!is.na(mi0)) &&
            all(is.finite(r1_eff)) && all(r1_eff!=0) &&
            all(is.finite(r0_eff)) && all(r0_eff!=0) &&
            isTRUE(all.equal(r1_eff,r0_eff,tolerance=1e-12,
                             check.attributes=FALSE))

add("R0 direction/effect cross-check for Primary25","25/25 exact within 1e-12",
    paste0("mapped=",sum(!is.na(mi0)),
           "; max_abs_diff=",
           if(all(!is.na(mi0))) format(max(abs(r1_eff-r0_eff)),digits=6) else "NA"),
    if(cross_ok) "PASS" else "FAIL")
if(!cross_ok) finish_hold("R0_R1_FAILURE_DIRECTION_DRIFT",169L)

# ------------------------------ align rows ---------------------------------
ord <- match(PRIMARY25,r1$r0_gene_id)
r1 <- r1[ord,,drop=FALSE]
m21 <- m21[match(PRIMARY25,m21$gene),,drop=FALSE]
ed <- ed[match(PRIMARY25,ed$gene),,drop=FALSE]
f4c <- f4c[match(PRIMARY25,f4c$gene),,drop=FALSE]
f4e <- f4e[match(PRIMARY25,f4e$gene),,drop=FALSE]
f4f <- f4f[match(PRIMARY25,f4f$gene),,drop=FALSE]

failure_lfc <- as.numeric(r1$r0_log2FC)
failure_sign <- sign(failure_lfc)

main_lfc <- as.numeric(m21$log2FoldChange)
main_deg <- as.logical(m21$author_DEG_by_published_rule)
main_available <- m21$mapping_status=="UNIQUE" & is.finite(main_lfc)

same_lfc <- as.numeric(ed$log2FoldChange)
same_deg <- as.logical(ed$author_DEG_by_published_rule)
same_available <- ed$mapping_status=="UNIQUE" &
                  is.finite(same_lfc) & same_lfc!=0

class <- rep(NA_character_,25)
main_relation <- rep(NA_character_,25)
same_relation <- rep(NA_character_,25)
same_support <- rep(NA_character_,25)

for(i in seq_len(25L)) {
  if(!is.finite(failure_lfc[i]) || failure_lfc[i]==0 || !main_available[i]) {
    class[i] <- "UNASSESSABLE"
    next
  }

  if(!isTRUE(main_deg[i])) {
    class[i] <- "INDETERMINATE_NO_MAIN_DEG"
    main_relation[i] <- if(main_lfc[i]==0) "ZERO" else
      if(sign(main_lfc[i])==failure_sign[i]) "SAME_AS_FAILURE" else "OPPOSITE_FAILURE"
    if(same_available[i]) {
      same_relation[i] <- if(sign(same_lfc[i])==failure_sign[i])
        "SAME_AS_FAILURE" else "OPPOSITE_FAILURE"
      same_support[i] <- if(isTRUE(same_deg[i]))
        "SAME_SITE_FDR_DEG_SUPPORT" else "SAME_SITE_DIRECTION_ONLY_N3"
    } else {
      same_support[i] <- "SAME_SITE_UNAVAILABLE"
    }
    next
  }

  main_relation[i] <- if(sign(main_lfc[i])==failure_sign[i])
    "SAME_AS_FAILURE" else "OPPOSITE_FAILURE"

  if(!same_available[i]) {
    class[i] <- "MAIN_ONLY_UNRESOLVED"
    same_support[i] <- "SAME_SITE_UNAVAILABLE"
    next
  }

  same_relation[i] <- if(sign(same_lfc[i])==failure_sign[i])
    "SAME_AS_FAILURE" else "OPPOSITE_FAILURE"
  same_support[i] <- if(isTRUE(same_deg[i]))
    "SAME_SITE_FDR_DEG_SUPPORT" else "SAME_SITE_DIRECTION_ONLY_N3"

  if(main_relation[i] != same_relation[i]) {
    class[i] <- "SITE_CONFLICT"
  } else if(main_relation[i]=="OPPOSITE_FAILURE") {
    class[i] <- "REVERSAL_SUPPORTED"
  } else if(main_relation[i]=="SAME_AS_FAILURE") {
    class[i] <- "MALADAPTIVE_NONREVERSAL_WORSENING_SUPPORTED"
  } else {
    class[i] <- "UNASSESSABLE"
  }
}

allowed <- expected_classes
if(any(is.na(class)) || any(!class %in% allowed))
  finish_hold("UNRECOGNIZED_CLASS_STATE",170L)

# ------------------------ context / diagnostics only -----------------------
context_relation <- function(lfc,avail,fail_sign,contrast_is_control_minus_pre=FALSE) {
  out <- rep("UNAVAILABLE",length(lfc))
  ok <- avail & is.finite(lfc) & lfc!=0
  if(contrast_is_control_minus_pre) {
    # failure-up corresponds to PRE > CONTROL, hence CONTROL-PRE is negative.
    target <- -fail_sign
    out[ok] <- ifelse(sign(lfc[ok])==target[ok],
                      "BASELINE_DISEASE_CONTEXT_CONCORDANT",
                      "BASELINE_DISEASE_CONTEXT_DISCORDANT")
  } else {
    out[ok] <- ifelse(sign(lfc[ok])>0,"POSITIVE","NEGATIVE")
  }
  out
}

c_lfc <- as.numeric(f4c$log2FoldChange)
c_av <- f4c$mapping_status=="UNIQUE" & is.finite(c_lfc)
c_rel <- context_relation(c_lfc,c_av,failure_sign,TRUE)

e_lfc <- as.numeric(f4e$log2FoldChange)
e_av <- f4e$mapping_status=="UNIQUE" & is.finite(e_lfc)

f_lfc <- as.numeric(f4f$log2FoldChange)
f_av <- f4f$mapping_status=="UNIQUE" & is.finite(f_lfc)
f_main_compat <- rep("UNAVAILABLE",25)
both <- f_av & main_available & main_lfc!=0 & f_lfc!=0
f_main_compat[both] <- ifelse(sign(f_lfc[both])==sign(main_lfc[both]),
                              "DIRECTION_COMPATIBLE_WITH_MAIN21",
                              "DIRECTION_DISCORDANT_WITH_MAIN21")

out <- data.frame(
  gene=PRIMARY25,
  frozen_R0_RVF_vs_pRV_log2FC=failure_lfc,
  frozen_failure_direction=ifelse(failure_lfc>0,"UP_RVF_vs_pRV","DOWN_RVF_vs_pRV"),

  main21_mapping_status=m21$mapping_status,
  main21_baseMean=as.numeric(m21$baseMean),
  main21_log2FC_POSTseptum_minus_PRE_RV=main_lfc,
  main21_pvalue=as.numeric(m21$pvalue),
  main21_padj=as.numeric(m21$padj),
  main21_author_DEG=main_deg,
  main21_relation_to_failure=main_relation,

  sameSite_n3_mapping_status=ed$mapping_status,
  sameSite_n3_baseMean=as.numeric(ed$baseMean),
  sameSite_n3_log2FC_POSTseptum_minus_PREseptum=same_lfc,
  sameSite_n3_pvalue=as.numeric(ed$pvalue),
  sameSite_n3_padj=as.numeric(ed$padj),
  sameSite_n3_author_DEG=same_deg,
  sameSite_n3_relation_to_failure=same_relation,
  sameSite_support_tier=same_support,

  final_class=class,

  Fig4c_ControlSeptum_minus_PreSeptum_log2FC=c_lfc,
  Fig4c_baseline_context_relation=c_rel,
  Fig4c_author_DEG=as.logical(f4c$author_DEG_by_published_rule),

  Fig4e_PreRV_minus_PreSeptum_log2FC=e_lfc,
  Fig4e_anatomical_site_author_DEG=as.logical(f4e$author_DEG_by_published_rule),

  Fig4f_n3_PostSeptum_minus_PreRV_log2FC=f_lfc,
  Fig4f_main21_direction_compatibility=f_main_compat,
  Fig4f_author_DEG=as.logical(f4f$author_DEG_by_published_rule),

  interpretation_guard="NO_IRREVERSIBLE; NO_PERSISTENCE_FROM_NONSIGNIFICANCE; MAIN21_SITE_CONFOUNDED",
  stringsAsFactors=FALSE
)

# Preserve exact Primary25 order.
stopifnot(identical(out$gene,PRIMARY25))
awrite(out,OUT)

tab <- table(factor(out$final_class,levels=expected_classes))
sumdf <- data.frame(
  final_class=expected_classes,
  n=as.integer(tab),
  stringsAsFactors=FALSE
)
awrite(sumdf,OUT_SUM)

add("classified rows","25",nrow(out),
    if(nrow(out)==25L) "PASS" else "FAIL")
add("classification missing","0",sum(is.na(out$final_class)),
    if(sum(is.na(out$final_class))==0L) "PASS" else "FAIL")
add("class counts total","25",sum(sumdf$n),
    if(sum(sumdf$n)==25L) "PASS" else "FAIL")
add("main21 author DEG count in Primary25","observed/report only",
    sum(out$main21_author_DEG,na.rm=TRUE),"INFO")
add("same-site author DEG count in Primary25","observed/report only",
    sum(out$sameSite_n3_author_DEG,na.rm=TRUE),"INFO")

awrite(do.call(rbind,A),OUT_AUD)

count_line <- function(cl) {
  paste0(cl,"=",sum(out$final_class==cl))
}

twrite(c(
  "R3_STEP2_CORE_GENE_CLASSIFICATION_PASS",
  paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
  "universe=FROZEN_PRIMARY25",
  "classification_contract=R3_STEP1E_CLASSIFICATION_CONTRACT_FROZEN",
  "failure_direction=R0_RVF_vs_pRV_UNSHRUNK_LFC_CROSSCHECKED_AGAINST_R1_FINAL_PRIMARY25",
  "main_authority=FIG5C_N21_POST_SEPTUM_MINUS_PRE_RV",
  "main_site_confound_complete=YES",
  "same_site_sensitivity=EXTENDED_DATA_FIG4B_N3_POST_SEPTUM_MINUS_PRE_SEPTUM",
  "same_site_independent_validation=NO",
  count_line("REVERSAL_SUPPORTED"),
  count_line("MALADAPTIVE_NONREVERSAL_WORSENING_SUPPORTED"),
  count_line("SITE_CONFLICT"),
  count_line("MAIN_ONLY_UNRESOLVED"),
  count_line("INDETERMINATE_NO_MAIN_DEG"),
  count_line("UNASSESSABLE"),
  paste0("main21_author_DEG_in_Primary25=",sum(out$main21_author_DEG,na.rm=TRUE)),
  paste0("sameSite_n3_author_DEG_in_Primary25=",sum(out$sameSite_n3_author_DEG,na.rm=TRUE)),
  "nonsignificance_interpreted_as_persistence=NO",
  "irreversible_wording_used=NO",
  "statistical_model_fit=NO",
  "pvalue_recomputation=NO",
  "FDR_recomputation=NO",
  "classification_executed=YES",
  "next_stage=ChatGPT audit then program-level persistence/reversal analysis design"
),PASS)

logline("FINAL_GATE: R3_STEP2_CORE_GENE_CLASSIFICATION_PASS")
quit(save="no",status=0,runLast=FALSE)
