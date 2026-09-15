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
# RV Project — R3 Step 4A
# LOCALIZATION TARGET CONTRACT + HALLMARK MEMBERSHIP FREEZE
#
# PURPOSE
#   Freeze, BEFORE looking at snRNA/Xenium localization results, exactly which
#   terminal-frozen programs are eligible for downstream localization support
#   and exactly which genes define each module.
#
# PRIMARY LOCALIZATION TARGET RULE
#   Include ONLY terminal-frozen supported trajectory classes:
#     PROGRAM_REVERSAL_SUPPORTED
#     PROGRAM_MALADAPTIVE_NONREVERSAL_WORSENING_SUPPORTED
#
#   This yields 7 primary programs (5 reversal + 2 worsening).
#
# CONTEXT-ONLY PROGRAMS
#   PROGRAM_SITE_CONFLICT
#   PROGRAM_INDETERMINATE_NO_MAIN_SIGNAL
#   They remain visible in the 16-program ledger but cannot define the primary
#   localization claim.
#
# GENE-SET RULE
#   Primary downstream module membership = FULL OFFICIAL HALLMARK MEMBERSHIP
#   from the exact Step3C-frozen MSigDB GMT.
#
#   Step3D leading-edge genes are retained ONLY as result-derived context and
#   annotation. They do NOT redefine, trim, rescue, or expand the primary
#   localization module.
#
# NO snRNA analysis.
# NO Xenium analysis.
# NO model fitting.
# NO GSEA rerun.
# NO program reclassification.
# ==============================================================================

options(stringsAsFactors=FALSE, warn=1)
ROOT <- normalizePath(getwd(),winslash="/",mustWork=TRUE)
if(!identical(tolower(ROOT),tolower(RV_PROJECT_ROOT)))
  stop("Expected D:/RV_project")

R3 <- file.path(ROOT,"results","R3_GSE249696")
AUTH <- file.path(ROOT,"data","authority","MSigDB")
LOGD <- file.path(ROOT,"logs")
dir.create(LOGD,recursive=TRUE,showWarnings=FALSE)

F_GATE <- file.path(R3,"R3_STEP3F_V1_1_PROGRAM_ANALYSIS_TERMINAL_FROZEN.txt")
F_ID <- file.path(R3,"R3_STEP3F_V1_1_stable_program_identity_class_freeze.csv")

D_R0 <- file.path(R3,"R3_STEP3D_V1_1_R0_HALLMARK_GSEA.csv")
D_R1 <- file.path(R3,"R3_STEP3D_V1_1_R1_HALLMARK_GSEA.csv")
D_MAIN <- file.path(R3,"R3_STEP3D_V1_1_R3_MAIN_STABLE_PROGRAM_GSEA.csv")
D_SAME <- file.path(R3,"R3_STEP3D_V1_1_R3_SAME_SITE_STABLE_PROGRAM_GSEA.csv")

GMT <- file.path(AUTH,"h.all.v2026.1.Hs.symbols.gmt")

OUT_AUD <- file.path(R3,"R3_STEP4A_localization_target_audit.csv")
OUT_PROG <- file.path(R3,"R3_STEP4A_localization_program_contract.csv")
OUT_MEM <- file.path(R3,"R3_STEP4A_localization_HALLMARK_membership.csv")
OUT_GENE <- file.path(R3,"R3_STEP4A_supported_program_gene_manifest.csv")
OUT_PASS <- file.path(R3,"R3_STEP4A_LOCALIZATION_TARGETS_FROZEN.txt")
OUT_HOLD <- file.path(R3,"R3_STEP4A_LOCALIZATION_TARGETS_HOLD.txt")
LOG <- file.path(LOGD,"R3_STEP4A_LOCALIZATION_TARGET_FREEZE.log")

if(file.exists(LOG)) {
  old <- file.path(LOGD,paste0(
    "R3_STEP4A_LOCALIZATION_TARGET_FREEZE_",
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
    unlink(tmp,force=TRUE); stop("Atomic replace failed: ",dest)
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
          if(nzchar(notes))paste0(" | ",notes) else "")
}
flush_audit <- function() if(length(A)) awrite(do.call(rbind,A),OUT_AUD)

hold <- function(reason,code=301L) {
  flush_audit()
  twrite(c(
    "R3_STEP4A_LOCALIZATION_TARGETS_HOLD",
    paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
    paste0("reason=",reason),
    "snRNA_analysis_executed=NO",
    "Xenium_analysis_executed=NO",
    "GSEA_rerun=NO",
    "program_reclassification=NO",
    "automatic_rerun_allowed=NO"
  ),OUT_HOLD)
  quit(save="no",status=code,runLast=FALSE)
}
options(error=function() {
  msg <- geterrmessage()
  try(flush_audit(),silent=TRUE)
  try(twrite(c(
    "R3_STEP4A_LOCALIZATION_TARGETS_HOLD_RUNTIME_ERROR",
    paste0("error=",gsub("[\r\n]+"," | ",msg)),
    "automatic_rerun_allowed=NO"
  ),OUT_HOLD),silent=TRUE)
  q(save="no",status=302,runLast=FALSE)
})

parse_kv <- function(p) {
  z <- readLines(p,warn=FALSE,encoding="UTF-8")
  z <- z[nzchar(trimws(z)) & grepl("=",z,fixed=TRUE)]
  out <- sub("^[^=]*=","",z)
  names(out) <- sub("=.*$","",z)
  out
}
read_gmt <- function(p) {
  z <- readLines(p,warn=FALSE,encoding="UTF-8")
  sp <- strsplit(z,"\t",fixed=TRUE)
  nm <- vapply(sp,`[`,character(1),1)
  gs <- lapply(sp,function(x)unique(x[-c(1,2)]))
  names(gs) <- nm
  gs
}
split_le <- function(x) {
  if(is.na(x) || !nzchar(x)) character()
  else unique(strsplit(x,";",fixed=TRUE)[[1]])
}
read_le <- function(p,label) {
  d <- read.csv(p,stringsAsFactors=FALSE,check.names=FALSE)
  if(!all(c("pathway","leadingEdge") %in% names(d)))
    hold(paste0(label,"_LEADING_EDGE_SCHEMA_DRIFT"),303L)
  d$pathway <- as.character(d$pathway)
  d
}
le_has <- function(df,pathway,gene) {
  i <- match(pathway,df$pathway)
  if(is.na(i)) return(FALSE)
  gene %in% split_le(df$leadingEdge[i])
}

logline("============================================================")
logline("R3 Step4A localization-target contract freeze")
logline("No localization data are opened by this script.")
logline("============================================================")

needed <- c(F_GATE,F_ID,D_R0,D_R1,D_MAIN,D_SAME,GMT)
for(p in needed) {
  ok <- file.exists(p)
  add(paste0("file_exists:",basename(p)),
      "YES",if(ok)"YES" else "NO",if(ok)"PASS" else "FAIL")
}
if(any(!file.exists(needed))) hold("MISSING_FROZEN_INPUT",304L)

fkv <- parse_kv(F_GATE)
must <- c(
  program_analysis_status="FINAL_CLOSED",
  R0_R1_stable_programs="16",
  PROGRAM_REVERSAL_SUPPORTED="5",
  PROGRAM_MALADAPTIVE_NONREVERSAL_WORSENING_SUPPORTED="2",
  PROGRAM_SITE_CONFLICT="4",
  PROGRAM_INDETERMINATE_NO_MAIN_SIGNAL="5",
  tie_order_conclusion="CLEAN_ROBUST",
  same_site_independent_validation="NO",
  main_site_confound_complete="YES",
  GSEA_rerun_in_terminal_freeze="NO",
  class_reassignment_in_terminal_freeze="NO"
)
for(k in names(must)) {
  obs <- if(k %in% names(fkv))unname(fkv[[k]]) else "<MISSING>"
  exp <- unname(must[[k]])
  add(paste0("Step3F invariant:",k),exp,obs,
      if(identical(obs,exp))"PASS" else "FAIL")
}
if(any(vapply(A,function(x)any(x$status=="FAIL"),logical(1))))
  hold("STEP3F_TERMINAL_FREEZE_INVARIANT_DRIFT",305L)

id <- read.csv(F_ID,stringsAsFactors=FALSE,check.names=FALSE)
if(!all(c("pathway","program_class","failure_direction") %in% names(id)))
  hold("STEP3F_IDENTITY_SCHEMA_DRIFT",306L)
if(nrow(id)!=16L || anyDuplicated(id$pathway))
  hold("STEP3F_IDENTITY_ROWCOUNT_OR_DUPLICATE_DRIFT",307L)

supported_classes <- c(
  "PROGRAM_REVERSAL_SUPPORTED",
  "PROGRAM_MALADAPTIVE_NONREVERSAL_WORSENING_SUPPORTED"
)
id$primary_localization_target <- id$program_class %in% supported_classes
id$localization_role <- ifelse(
  id$program_class=="PROGRAM_REVERSAL_SUPPORTED",
  "PRIMARY_LOCALIZATION_TARGET_REVERSAL",
  ifelse(
    id$program_class=="PROGRAM_MALADAPTIVE_NONREVERSAL_WORSENING_SUPPORTED",
    "PRIMARY_LOCALIZATION_TARGET_WORSENING",
    ifelse(
      id$program_class=="PROGRAM_SITE_CONFLICT",
      "CONTEXT_ONLY_SITE_CONFLICT",
      "CONTEXT_ONLY_INDETERMINATE"
    )
  )
)

add("primary localization programs","7",sum(id$primary_localization_target),
    if(sum(id$primary_localization_target)==7L)"PASS" else "FAIL",
    "Rule fixed from terminal-frozen class only: 5 reversal + 2 worsening.")
if(sum(id$primary_localization_target)!=7L)
  hold("PRIMARY_LOCALIZATION_TARGET_COUNT_DRIFT",308L)

expected_primary <- c(
  "HALLMARK_APICAL_JUNCTION",
  "HALLMARK_ESTROGEN_RESPONSE_EARLY",
  "HALLMARK_IL2_STAT5_SIGNALING",
  "HALLMARK_IL6_JAK_STAT3_SIGNALING",
  "HALLMARK_INTERFERON_ALPHA_RESPONSE",
  "HALLMARK_INTERFERON_GAMMA_RESPONSE",
  "HALLMARK_TNFA_SIGNALING_VIA_NFKB"
)
obs_primary <- sort(id$pathway[id$primary_localization_target])
id_ok <- identical(obs_primary,sort(expected_primary))
add("primary localization program identities","EXACT_7",
    if(id_ok)"EXACT_7" else paste(obs_primary,collapse=";"),
    if(id_ok)"PASS" else "FAIL")
if(!id_ok) hold("PRIMARY_LOCALIZATION_TARGET_IDENTITY_DRIFT",309L)

# Parse exact frozen Hallmark source.
gmt <- read_gmt(GMT)
gmt_sha <- if(requireNamespace("digest",quietly=TRUE))
  digest::digest(file=GMT,algo="sha256",serialize=FALSE) else NA_character_
gmt_ok <- length(gmt)==50L &&
  identical(gmt_sha,
    "eecaf6dad908334ae885406ec72bdc0646d8917588ed7c219fac92fc5363f596")
add("Hallmark set count","50",length(gmt),
    if(length(gmt)==50L)"PASS" else "FAIL")
add("Hallmark GMT SHA256",
    "eecaf6dad908334ae885406ec72bdc0646d8917588ed7c219fac92fc5363f596",
    gmt_sha,if(isTRUE(gmt_ok))"PASS" else "FAIL")
if(!isTRUE(gmt_ok)) hold("HALLMARK_SOURCE_IDENTITY_DRIFT",310L)

if(any(!id$pathway %in% names(gmt)))
  hold("TERMINAL_PROGRAM_MISSING_FROM_GMT",311L)

# Leading edges are context only.
r0 <- read_le(D_R0,"R0")
r1 <- read_le(D_R1,"R1")
rm <- read_le(D_MAIN,"R3_MAIN")
rs <- read_le(D_SAME,"R3_SAME")

# One row per program in frozen 16-program universe.
prog_cols <- intersect(
  c("pathway","failure_direction","NES_R0","R0_BH_FDR","NES_R1","R1_BH_FDR",
    "main_NES","main_BH_FDR","same_site_NES","same_site_BH_FDR","program_class"),
  names(id)
)
prog <- id[,prog_cols,drop=FALSE]
prog$primary_localization_target <- id$primary_localization_target
prog$localization_role <- id$localization_role
prog$primary_module_definition <- "FULL_OFFICIAL_HALLMARK_MEMBERSHIP"
prog$leading_edge_role <- "RESULT_DERIVED_CONTEXT_ONLY_NOT_PRIMARY_MODULE"
prog$snRNA_role <- ifelse(
  prog$primary_localization_target,
  "FUTURE_CELLTYPE_LOCALIZATION_SUPPORT",
  "NOT_PRIMARY_LOCALIZATION_TARGET"
)
prog$Xenium_role <- ifelse(
  prog$primary_localization_target,
  "FUTURE_SPATIAL_LOCALIZATION_SUPPORT_IF_PANEL_COVERAGE_ASSESSABLE",
  "NOT_PRIMARY_LOCALIZATION_TARGET"
)
prog$can_redefine_Step3F_class <- "NO"
awrite(prog,OUT_PROG)

# Full Hallmark membership for all 16 stable programs.
rows <- list()
k <- 0L
for(i in seq_len(nrow(id))) {
  h <- id$pathway[i]
  genes <- gmt[[h]]
  if(anyDuplicated(genes))
    hold(paste0("WITHIN_SET_DUPLICATE:",h),312L)

  for(g in genes) {
    k <- k+1L
    rows[[k]] <- data.frame(
      pathway=h,
      gene_symbol=g,
      program_class=id$program_class[i],
      primary_localization_target=id$primary_localization_target[i],
      localization_role=id$localization_role[i],
      official_Hallmark_member=TRUE,
      R0_leading_edge=le_has(r0,h,g),
      R1_leading_edge=le_has(r1,h,g),
      cross_etiology_R0_R1_leading_edge=
        le_has(r0,h,g) && le_has(r1,h,g),
      R3_main_leading_edge=le_has(rm,h,g),
      R3_same_site_leading_edge=le_has(rs,h,g),
      leading_edge_role="CONTEXT_ONLY_NOT_MODULE_MEMBERSHIP_AUTHORITY",
      stringsAsFactors=FALSE
    )
  }
}
mem <- do.call(rbind,rows)
mem <- mem[order(mem$pathway,mem$gene_symbol),,drop=FALSE]
awrite(mem,OUT_MEM)

# Primary 7-program gene manifest: still FULL Hallmark membership.
gene <- mem[mem$primary_localization_target,
            c("pathway","gene_symbol","program_class",
              "official_Hallmark_member","R0_leading_edge","R1_leading_edge",
              "cross_etiology_R0_R1_leading_edge",
              "R3_main_leading_edge","R3_same_site_leading_edge"),
            drop=FALSE]
gene$primary_module_member <- TRUE
gene$selection_rule <- "FULL_OFFICIAL_HALLMARK_MEMBERSHIP_OF_7_TERMINAL_SUPPORTED_PROGRAMS"
awrite(gene,OUT_GENE)

# Guards against accidental result-derived trimming.
n_expected <- sum(vapply(id$pathway,function(h)length(gmt[[h]]),integer(1)))
n_primary_expected <- sum(vapply(
  id$pathway[id$primary_localization_target],
  function(h)length(gmt[[h]]),integer(1)
))
add("all-16 membership rows",n_expected,nrow(mem),
    if(nrow(mem)==n_expected)"PASS" else "FAIL")
add("primary-7 membership rows",n_primary_expected,nrow(gene),
    if(nrow(gene)==n_primary_expected)"PASS" else "FAIL")
add("primary module membership derived from leading edge","NO","NO","PASS")
add("snRNA data opened","NO","NO","PASS")
add("Xenium data opened","NO","NO","PASS")
add("program class recomputed","NO","NO","PASS")

if(nrow(mem)!=n_expected || nrow(gene)!=n_primary_expected)
  hold("MEMBERSHIP_ACCOUNTING_DRIFT",313L)

flush_audit()

twrite(c(
  "R3_STEP4A_LOCALIZATION_TARGETS_FROZEN",
  paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
  "upstream_program_analysis=R3_STEP3F_V1_1_PROGRAM_ANALYSIS_TERMINAL_FROZEN",
  "upstream_program_analysis_status=FINAL_CLOSED",
  "stable_program_universe=16",
  "primary_localization_programs=7",
  "primary_localization_rule=TERMINAL_SUPPORTED_TRAJECTORY_CLASSES_ONLY",
  "primary_reversal_programs=5",
  "primary_worsening_programs=2",
  "site_conflict_programs_primary_localization=NO",
  "indeterminate_programs_primary_localization=NO",
  "primary_module_definition=FULL_OFFICIAL_HALLMARK_MEMBERSHIP",
  "Hallmark_source=MSigDB_2026.1.Hs_HALLMARK_50",
  "Hallmark_GMT_SHA256=eecaf6dad908334ae885406ec72bdc0646d8917588ed7c219fac92fc5363f596",
  paste0("primary_module_membership_rows=",nrow(gene)),
  "leading_edge_role=RESULT_DERIVED_CONTEXT_ONLY_NOT_MODULE_MEMBERSHIP_AUTHORITY",
  "snRNA_analysis_executed=NO",
  "Xenium_analysis_executed=NO",
  "GSEA_rerun=NO",
  "program_reclassification=NO",
  "can_downstream_localization_redefine_Step3F_class=NO",
  "next_stage=ChatGPT_INDEPENDENT_AUDIT_THEN_STEP4B_SNRNA_XENIUM_INPUT_PREFLIGHT"
),OUT_PASS)

if(file.exists(OUT_HOLD)) unlink(OUT_HOLD,force=TRUE)
logline("FINAL_GATE: R3_STEP4A_LOCALIZATION_TARGETS_FROZEN")
quit(save="no",status=0,runLast=FALSE)
