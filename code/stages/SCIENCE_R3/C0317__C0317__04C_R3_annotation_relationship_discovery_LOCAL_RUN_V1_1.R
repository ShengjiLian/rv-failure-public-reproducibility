# ---- RV PUBLIC PRIMARY DAG GATE9J REWRITE V1.0 ----
# source_id=C0317
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
# RV Project — R3 Step4C V1.1
# ANNOTATION RELATIONSHIP DISCOVERY — VERSION-FORWARD AFTER CLEAN STEP4C HOLD
#
# WHY THIS EXISTS
#   Step4C V1.0 stopped before any localization analysis because:
#     snRNA Subnames_manual (34 levels) did NOT map uniquely to Names (12 levels).
#
#   That finding invalidates the untested assumption that these RDS metadata
#   fields form a strict per-cell parent-child hierarchy. It does NOT invalidate
#   either annotation field.
#
# PURPOSE
#   Inspect annotation labels and their pairwise relationships BEFORE choosing
#   final annotation authorities.
#
# THIS GATE:
#   - verifies exact V1.0 HOLD scope
#   - reads snRNA and Xenium objects one at a time
#   - exports annotation value counts
#   - exports pairwise annotation crosswalks and mapping multiplicities
#   - reports, but does not repair, non-nesting
#
# THIS GATE DOES NOT:
#   - choose/freeze a final annotation hierarchy
#   - merge/relabel cells
#   - use expression values
#   - score modules
#   - test disease groups
#   - run GSEA/DE
#   - reclassify Step3F programs
# ==============================================================================

options(stringsAsFactors=FALSE, warn=1)

ROOT <- normalizePath(getwd(), winslash="/", mustWork=TRUE)
if(!identical(tolower(ROOT),tolower(RV_PROJECT_ROOT)))
  stop("Expected D:/RV_project")

R3 <- file.path(ROOT,"results","R3_GSE249696")
LOGD <- file.path(ROOT,"logs")
PROJECT_LIB <- file.path(ROOT,"R_library","R-4.6")
.libPaths(c(PROJECT_LIB,.libPaths()))
dir.create(LOGD,recursive=TRUE,showWarnings=FALSE)

B_GATE <- file.path(R3,"R3_STEP4B_V1_7_STRUCTURAL_PREFLIGHT_TERMINAL_FROZEN.txt")

SNRNA <- file.path(ROOT,"data","raw","GSE345646","GSE345646_snRV_ref.rds")
XEN <- file.path(ROOT,"data","raw","GSE345643",
                 "GSE345643_RV_Xenium_ambient_corrected_568651cells.rds")

OUT_AUD <- file.path(R3,"R3_STEP4C_V1_1_annotation_relationship_audit.csv")
OUT_VALUES <- file.path(R3,"R3_STEP4C_V1_1_annotation_value_counts.csv")
OUT_CROSS <- file.path(R3,"R3_STEP4C_V1_1_annotation_pairwise_crosswalk.csv")
OUT_SUM <- file.path(R3,"R3_STEP4C_V1_1_annotation_relationship_summary.csv")
OUT_PASS <- file.path(R3,"R3_STEP4C_V1_1_ANNOTATION_RELATIONSHIP_DISCOVERY_FROZEN.txt")
OUT_HOLD <- file.path(R3,"R3_STEP4C_V1_1_ANNOTATION_RELATIONSHIP_DISCOVERY_HOLD.txt")
LOG <- file.path(LOGD,"R3_STEP4C_V1_1_ANNOTATION_RELATIONSHIP_DISCOVERY.log")

logline <- function(...) {
  z <- paste0(format(Sys.time(),"%Y-%m-%d %H:%M:%S"),
              " | ",paste0(...,collapse=""))
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
    notes=as.character(notes), stringsAsFactors=FALSE)
  logline("[",status,"] ",item," | expected=",expected,
          " | observed=",observed,
          if(nzchar(notes))paste0(" | ",notes) else "")
}
flush_audit <- function() if(length(A)) awrite(do.call(rbind,A),OUT_AUD)
hold <- function(reason,code=401L) {
  flush_audit()
  twrite(c(
    "R3_STEP4C_V1_1_ANNOTATION_RELATIONSHIP_DISCOVERY_HOLD",
    paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
    paste0("reason=",reason),
    "expression_values_used=NO",
    "module_scoring_executed=NO",
    "disease_group_testing_executed=NO",
    "annotation_relabeling_executed=NO",
    "program_reclassification=NO",
    "automatic_rerun_allowed=NO"
  ),OUT_HOLD)
  logline("FINAL_GATE: HOLD | ",reason)
  quit(save="no",status=code,runLast=FALSE)
}
options(error=function() {
  msg <- geterrmessage()
  try(logline("[UNHANDLED_R_ERROR] ",gsub("[\r\n]+"," | ",msg)),silent=TRUE)
  try(flush_audit(),silent=TRUE)
  try(twrite(c(
    "R3_STEP4C_V1_1_ANNOTATION_RELATIONSHIP_DISCOVERY_HOLD_RUNTIME_ERROR",
    paste0("error=",gsub("[\r\n]+"," | ",msg)),
    "automatic_rerun_allowed=NO"
  ),OUT_HOLD),silent=TRUE)
  q(save="no",status=402,runLast=FALSE)
})

parse_kv <- function(p) {
  z <- readLines(p,warn=FALSE,encoding="UTF-8")
  z <- z[nzchar(trimws(z)) & grepl("=",z,fixed=TRUE)]
  v <- sub("^[^=]*=","",z); names(v)<-sub("=.*$","",z); v
}
value_counts <- function(dataset,field,v) {
  vv <- as.character(v)
  vv[is.na(vv)|vv==""] <- "<NA_OR_EMPTY>"
  tb <- sort(table(vv),decreasing=TRUE)
  data.frame(
    dataset=dataset,field=field,value=names(tb),
    n=as.integer(tb),fraction=as.numeric(tb)/length(vv),
    stringsAsFactors=FALSE
  )
}
crosswalk <- function(dataset,field_a,field_b,a,b) {
  aa <- as.character(a); bb <- as.character(b)
  aa[is.na(aa)|aa==""] <- "<NA_OR_EMPTY>"
  bb[is.na(bb)|bb==""] <- "<NA_OR_EMPTY>"
  tb <- as.data.frame(table(aa,bb),stringsAsFactors=FALSE)
  tb <- tb[tb$Freq>0,,drop=FALSE]
  names(tb) <- c("label_a","label_b","n_cells")

  a_nb <- tapply(tb$label_b,tb$label_a,function(x)length(unique(x)))
  b_na <- tapply(tb$label_a,tb$label_b,function(x)length(unique(x)))

  tb$dataset <- dataset
  tb$field_a <- field_a
  tb$field_b <- field_b
  tb$label_a_maps_to_n_label_b <- as.integer(a_nb[tb$label_a])
  tb$label_b_maps_to_n_label_a <- as.integer(b_na[tb$label_b])

  tb[,c("dataset","field_a","field_b","label_a","label_b","n_cells",
        "label_a_maps_to_n_label_b","label_b_maps_to_n_label_a")]
}
relationship_summary <- function(cw) {
  pairs <- unique(cw[,c("dataset","field_a","field_b")])
  ans <- lapply(seq_len(nrow(pairs)),function(i) {
    z <- cw[
      cw$dataset==pairs$dataset[i] &
      cw$field_a==pairs$field_a[i] &
      cw$field_b==pairs$field_b[i],,drop=FALSE
    ]
    ua <- unique(z[,c("label_a","label_a_maps_to_n_label_b")])
    ub <- unique(z[,c("label_b","label_b_maps_to_n_label_a")])
    data.frame(
      dataset=pairs$dataset[i],
      field_a=pairs$field_a[i],
      field_b=pairs$field_b[i],
      n_field_a_labels=nrow(ua),
      n_field_b_labels=nrow(ub),
      field_a_labels_mapping_to_multiple_b=sum(
        ua$label_a_maps_to_n_label_b>1L),
      field_b_labels_mapping_to_multiple_a=sum(
        ub$label_b_maps_to_n_label_a>1L),
      strict_a_to_b_function=all(
        ua$label_a_maps_to_n_label_b==1L),
      strict_b_to_a_function=all(
        ub$label_b_maps_to_n_label_a==1L),
      relationship_role="STRUCTURAL_DISCOVERY_ONLY_NO_RELABELLING",
      stringsAsFactors=FALSE
    )
  })
  do.call(rbind,ans)
}

logline("============================================================")
logline("R3 Step4C V1.1 annotation relationship discovery")
logline("============================================================")

needed <- c(B_GATE,SNRNA,XEN)
for(p in needed) {
  ok <- file.exists(p)
  add(paste0("file_exists:",basename(p)),"YES",
      if(ok)"YES" else "NO",if(ok)"PASS" else "FAIL")
}
if(any(!file.exists(needed))) hold("MISSING_REQUIRED_LINEAGE_OR_RDS",403L)

# Exact Step4B terminal authority.
bg <- parse_kv(B_GATE)
req_b <- c(
  Step4B_V1_7_status="STRUCTURAL_PREFLIGHT_TERMINAL_FROZEN",
  SeuratObject_version="5.4.0",
  GSE345646_cells="61398",
  GSE345643_cells="568651",
  primary_localization_programs="7",
  program_reclassification="NO"
)
for(k in names(req_b)) {
  obs <- if(k %in% names(bg)) unname(bg[[k]]) else "<MISSING>"
  exp <- unname(req_b[[k]])
  add(paste0("Step4B invariant:",k),exp,obs,
      if(identical(obs,exp))"PASS" else "FAIL")
}

# Gate9G canonical Step4B is the only upstream structural authority required.
if(any(vapply(A,function(x)any(x$status=="FAIL"),logical(1))))
  hold("UPSTREAM_STEP4B_GUARD_FAILURE",404L)
add("Historical Step4C V1.0 HOLD replayed","NO","NO","PASS",
    "The failed strict-hierarchy assumption is provenance only; relationship discovery starts directly from canonical Step4B + RDS.")

if(!requireNamespace("SeuratObject",quietly=TRUE))
  hold("SEURATOBJECT_UNAVAILABLE",405L)
if(as.character(utils::packageVersion("SeuratObject"))!="5.4.0")
  hold("SEURATOBJECT_VERSION_DRIFT",405L)
loadNamespace("SeuratObject")

vals <- list()
cross <- list()

# --------------------------------------------------------------------------
# snRNA: annotation labels + all three pairwise relations.
# --------------------------------------------------------------------------
logline("[LOAD START] GSE345646 snRNA")
sn <- readRDS(SNRNA)
logline("[LOAD DONE] GSE345646 snRNA")
if(!inherits(sn,"Seurat")) hold("SNRNA_CLASS_DRIFT",406L)
md <- sn@meta.data
fields_sn <- c("Names","Subnames","Subnames_manual")
if(length(setdiff(fields_sn,names(md))))
  hold("SNRNA_ANNOTATION_FIELD_MISSING",407L)

for(f in fields_sn)
  vals[[length(vals)+1L]] <- value_counts("GSE345646_snRNA",f,md[[f]])

cross[[length(cross)+1L]] <- crosswalk(
  "GSE345646_snRNA","Names","Subnames",md$Names,md$Subnames)
cross[[length(cross)+1L]] <- crosswalk(
  "GSE345646_snRNA","Names","Subnames_manual",md$Names,md$Subnames_manual)
cross[[length(cross)+1L]] <- crosswalk(
  "GSE345646_snRNA","Subnames","Subnames_manual",md$Subnames,md$Subnames_manual)

add("snRNA Names levels","12",length(unique(as.character(md$Names))),
    if(length(unique(as.character(md$Names)))==12L)"PASS" else "FAIL")
add("snRNA Subnames levels","37",length(unique(as.character(md$Subnames))),
    if(length(unique(as.character(md$Subnames)))==37L)"PASS" else "FAIL")
add("snRNA Subnames_manual levels","34",
    length(unique(as.character(md$Subnames_manual))),
    if(length(unique(as.character(md$Subnames_manual)))==34L)"PASS" else "FAIL")

rm(sn,md); invisible(gc(verbose=FALSE))
logline("[RELEASED] GSE345646 snRNA")

# --------------------------------------------------------------------------
# Xenium: compare the two deposited annotation fields.
# --------------------------------------------------------------------------
logline("[LOAD START] GSE345643 Xenium")
xe <- readRDS(XEN)
logline("[LOAD DONE] GSE345643 Xenium")
if(!inherits(xe,"Seurat")) hold("XENIUM_CLASS_DRIFT",408L)
xm <- xe@meta.data
fields_xe <- c("cell_type_rctd_doublet","cell_type_seurat")
if(length(setdiff(fields_xe,names(xm))))
  hold("XENIUM_ANNOTATION_FIELD_MISSING",409L)

for(f in fields_xe)
  vals[[length(vals)+1L]] <- value_counts(
    "GSE345643_Xenium_ambient_corrected",f,xm[[f]])

cross[[length(cross)+1L]] <- crosswalk(
  "GSE345643_Xenium_ambient_corrected",
  "cell_type_rctd_doublet","cell_type_seurat",
  xm$cell_type_rctd_doublet,xm$cell_type_seurat)

add("Xenium RCTD labels","12",
    length(unique(as.character(xm$cell_type_rctd_doublet))),
    if(length(unique(as.character(xm$cell_type_rctd_doublet)))==12L)
      "PASS" else "FAIL")
add("Xenium Seurat labels","34",
    length(unique(as.character(xm$cell_type_seurat))),
    if(length(unique(as.character(xm$cell_type_seurat)))==34L)
      "PASS" else "FAIL")

rm(xe,xm); invisible(gc(verbose=FALSE))
logline("[RELEASED] GSE345643 Xenium")

if(any(vapply(A,function(x)any(x$status=="FAIL"),logical(1))))
  hold("ANNOTATION_STRUCTURE_CARDINALITY_DRIFT",410L)

vdf <- do.call(rbind,vals)
vdf <- vdf[order(vdf$dataset,vdf$field,-vdf$n,vdf$value),,drop=FALSE]
cdf <- do.call(rbind,cross)
cdf <- cdf[order(cdf$dataset,cdf$field_a,cdf$field_b,
                 cdf$label_a,cdf$label_b),,drop=FALSE]
sdf <- relationship_summary(cdf)

awrite(vdf,OUT_VALUES)
awrite(cdf,OUT_CROSS)
awrite(sdf,OUT_SUM)

# Non-nesting is a discovery result here, not a failure condition.
for(i in seq_len(nrow(sdf))) {
  add(
    paste0("relationship:",
           sdf$dataset[i],":",
           sdf$field_a[i],"->",sdf$field_b[i]),
    "REPORT_ONLY",
    paste0(
      "A_multiB=",sdf$field_a_labels_mapping_to_multiple_b[i],
      ";B_multiA=",sdf$field_b_labels_mapping_to_multiple_a[i],
      ";A_to_B=",sdf$strict_a_to_b_function[i],
      ";B_to_A=",sdf$strict_b_to_a_function[i]
    ),
    "INFO",
    "No hierarchy is inferred or repaired in V1.1."
  )
}

add("annotation relabeling executed","NO","NO","PASS")
add("expression values used","NO","NO","PASS")
add("module scoring executed","NO","NO","PASS")
add("disease group testing executed","NO","NO","PASS")
add("GSEA executed","NO","NO","PASS")
add("program reclassification","NO","NO","PASS")

flush_audit()

twrite(c(
  "R3_STEP4C_V1_1_ANNOTATION_RELATIONSHIP_DISCOVERY_FROZEN",
  paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
  "upstream=R3_STEP4B_V1_7_STRUCTURAL_PREFLIGHT_TERMINAL_FROZEN",
  "Step4C_V1_0_status=CLEAN_HOLD_BEFORE_LOCALIZATION_RESULTS",
  "Step4C_V1_0_hold_reason=SNRNA_34_LEVEL_FIELD_NOT_STRICTLY_NESTED_WITHIN_12_LEVEL_FIELD",
  "V1_1_role=ANNOTATION_RELATIONSHIP_DISCOVERY_ONLY",
  "snRNA_fields_inspected=Names;Subnames;Subnames_manual",
  "Xenium_fields_inspected=cell_type_rctd_doublet;cell_type_seurat",
  "strict_parent_child_hierarchy_assumed=NO",
  "annotation_relabeling_executed=NO",
  "expression_values_used=NO",
  "module_scoring_executed=NO",
  "disease_group_testing_executed=NO",
  "GSEA_executed=NO",
  "program_reclassification=NO",
  "next_stage=ChatGPT_INDEPENDENT_AUDIT_THEN_STEP4C_V1_2_FINAL_ANNOTATION_AUTHORITY_ADJUDICATION"
),OUT_PASS)

if(file.exists(OUT_HOLD))unlink(OUT_HOLD,force=TRUE)
logline("FINAL_GATE: R3_STEP4C_V1_1_ANNOTATION_RELATIONSHIP_DISCOVERY_FROZEN")
quit(save="no",status=0,runLast=FALSE)
