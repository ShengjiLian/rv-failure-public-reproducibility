# ---- RV PUBLIC REPRODUCIBILITY PORTABILITY OVERLAY V1.0 ----
.RV_PROJECT_ROOT_ENV <- Sys.getenv('RV_PROJECT_ROOT', unset='')
RV_PROJECT_ROOT <- if (nzchar(.RV_PROJECT_ROOT_ENV)) {
  normalizePath(.RV_PROJECT_ROOT_ENV, winslash='/', mustWork=TRUE)
} else {
  normalizePath(getwd(), winslash='/', mustWork=TRUE)
}
# This overlay changes path binding only; scientific/statistical semantics remain historical authority.

source(file.path(RV_PROJECT_ROOT, 'code', 'lib', 'rv_runtime_helpers.R'))


# R3 Step4F V1.1
# DETERMINISTIC LOCALIZATION EXECUTION — SOURCE-SEMANTICS + SCOPE REPAIR
#
# Upstream authorities:
#   Step4D scientific contract = FROZEN
#   Step4D V1.3 deterministic implementation overlay = CLEAN_ACCEPTED / FINAL_FROZEN
#   Step4D V1.4 snRNA source-semantics overlay = CLEAN_ACCEPTED / FINAL_FROZEN
#   Step4E runtime + BROAD/FINE design-feasibility preflight = CLEAN_ACCEPTED
#
# This is the FIRST gate authorized to:
#   - read real expression values from the two frozen RDS objects
#   - aggregate patient×annotation pseudobulk
#   - execute frozen pairwise snRNA filterByExpr/TMM/voom/mroast
#   - execute frozen Xenium log2(1+CPM)/mroast
#   - run external fixed-family BH
#   - apply the frozen primary localization classification
#
# NON-NEGOTIABLE:
#   patient = biological replicate
#   no cell/nucleus pseudoreplication
#   no alias/case/fuzzy gene remapping
#   no program redefinition / leading-edge substitution
#   no FDR-family shrinkage
#   no P-value combination across modalities
#   no localization result may redefine the frozen Step3F program class
#   no package installation/repair in this gate
#   snRNA RNA/counts = deposited processed count-scale layer; fractional values allowed
#   no cell-level or pseudobulk rounding
#
# NOTE:
#   Every assessable registry row is ONE independent mroast() call.
#   set.seed(test_seed) is the immediately preceding RNG-setting statement.
#   Structurally/programmatically unassessable rows remain in the fixed family
#   with P_for_BH=1.

options(stringsAsFactors=FALSE, warn=1)

ROOT <- RV_PROJECT_ROOT
RES <- file.path(ROOT,"results","R3_GSE249696")
UPLOAD <- file.path(ROOT,"upload")
PROJECT_LIB <- file.path(RV_PROJECT_ROOT, "R_library/R-4.6")

STEP4E_RUN_ID <- basename(rv_resolve_stage_run(file.path(RES, "R3_STEP4E_runs")))
STEP4E_DIR <- file.path(RES,"R3_STEP4E_runs",STEP4E_RUN_ID)
STEP4D_V13_DIR <- rv_resolve_stage_run(file.path(RES, "R3_STEP4D_V1_3_runs"))
STEP4D_V14_DIR <- rv_resolve_stage_run(file.path(RES, "R3_STEP4D_V1_4_runs"))

SN_RDS <- file.path(RV_PROJECT_ROOT, "data/raw/GSE345646/GSE345646_snRV_ref.rds")
XE_RDS <- file.path(RV_PROJECT_ROOT, "data/raw/GSE345643/GSE345643_RV_Xenium_ambient_corrected_568651cells.rds")

P_STEP4E_STATUS <- file.path(STEP4E_DIR,"R3_STEP4E_STATUS.txt")
P_STEP4E_AUDIT <- file.path(STEP4E_DIR,"R3_STEP4E_audit.csv")
P_STEP4E_RUNTIME <- file.path(STEP4E_DIR,"R3_STEP4E_runtime_environment.csv")
P_STEP4E_PACKAGES <- file.path(STEP4E_DIR,"R3_STEP4E_package_versions.csv")
P_STEP4E_SMOKE <- file.path(STEP4E_DIR,"R3_STEP4E_synthetic_mroast_smoke.csv")
P_STEP4E_LAYER <- file.path(STEP4E_DIR,"R3_STEP4E_Assay5_sparse_layer_manifest.csv")
P_STEP4E_ROLE <- file.path(STEP4E_DIR,"R3_STEP4E_metadata_role_freeze.csv")
P_STEP4E_CROSS <- file.path(STEP4E_DIR,"R3_STEP4E_patient_crosswalk.csv")
P_STEP4E_COUNTS <- file.path(STEP4E_DIR,"R3_STEP4E_patient_group_annotation_cell_count_manifest.csv")
P_STEP4E_DESIGN <- file.path(STEP4E_DIR,"R3_STEP4E_design_feasibility.csv")
P_STEP4E_REGFEAS <- file.path(STEP4E_DIR,"R3_STEP4E_registry_design_feasibility.csv")
P_STEP4E_SOURCE <- file.path(STEP4E_DIR,"R3_STEP4E_SOURCE_SHA256_PREFLIGHT.csv")

P_REGISTRY <- file.path(STEP4D_V13_DIR,"R3_STEP4D_V1_3_DETERMINISTIC_TEST_REGISTRY.csv")
P_V13_SEM <- file.path(STEP4D_V13_DIR,"R3_STEP4D_V1_3_implementation_semantics.csv")
P_V13_GUARD <- file.path(STEP4D_V13_DIR,"R3_STEP4D_V1_3_STEP4F_FAIL_CLOSED_GUARDS.csv")
P_METHOD <- file.path(RES,"R3_STEP4D_localization_method_contract.csv")
P_TIER <- file.path(RES,"R3_STEP4D_program_modality_tier_contract.csv")
P_FDR <- file.path(RES,"R3_STEP4D_fixed_FDR_family_contract.csv")
P_CLASS <- file.path(RES,"R3_STEP4D_localization_classification_contract.csv")
P_LABELS <- file.path(RES,"R3_STEP4C_V1_2_frozen_annotation_labels.csv")
P_V14_STATUS <- file.path(STEP4D_V14_DIR,"R3_STEP4D_V1_4_STATUS.txt")
P_V14_AUDIT <- file.path(STEP4D_V14_DIR,"R3_STEP4D_V1_4_audit.csv")
P_V14_OVERLAY <- file.path(STEP4D_V14_DIR,"R3_STEP4D_V1_4_SNRNA_SOURCE_SEMANTICS_OVERLAY.csv")
P_V14_DELTA <- file.path(STEP4D_V14_DIR,"R3_STEP4D_V1_4_EFFECTIVE_METHOD_DELTA.csv")
P_V14_REPAIR <- file.path(STEP4D_V14_DIR,"R3_STEP4F_V1_1_IMPLEMENTATION_REPAIR_CONTRACT.csv")
P_V14_PRECEDENCE <- file.path(STEP4D_V14_DIR,"R3_STEP4D_V1_4_AUTHORITY_PRECEDENCE.txt")
P_V14_PUBLIC_ID <- file.path(STEP4D_V14_DIR,"R3_STEP4D_V1_4_ZENODO_PUBLIC_OBJECT_IDENTITY.csv")

# BAT-generated exact identity inputs.
P_PREHASH <- Sys.getenv("R3_STEP4F_V11_PREHASH",unset="")
P_GMT_DISCOVERY <- Sys.getenv("R3_STEP4F_V11_GMT_DISCOVERY",unset="")

if (!nzchar(P_PREHASH) || !nzchar(P_GMT_DISCOVERY)) {
  stop("Step4F V1.1 BAT identity preflight variables are missing; do not run this R script directly.",call.=FALSE)
}

args <- commandArgs(trailingOnly=TRUE)
RUN_ID <- if(length(args)>=1L && nzchar(args[1L])) args[1L] else format(Sys.time(),"%Y%m%d_%H%M%S")

RUNROOT <- file.path(RES,"R3_STEP4F_V1_1_runs")
RUNDIR <- file.path(RUNROOT,RUN_ID)
STAGING <- file.path(UPLOAD,"R3_STEP4F_V1_1_STAGING")
dir.create(RUNDIR,recursive=TRUE,showWarnings=FALSE)
dir.create(UPLOAD,recursive=TRUE,showWarnings=FALSE)
if(dir.exists(STAGING)) unlink(STAGING,recursive=TRUE,force=TRUE)
dir.create(STAGING,recursive=TRUE,showWarnings=FALSE)

P_STATUS <- file.path(RUNDIR,"R3_STEP4F_V1_1_STATUS.txt")
P_AUDIT <- file.path(RUNDIR,"R3_STEP4F_V1_1_audit.csv")
P_LOG <- file.path(RUNDIR,"R3_STEP4F_V1_1_PROGRESS.log")
P_MEMBERSHIP <- file.path(RUNDIR,"R3_STEP4F_V1_1_HALLMARK_MEMBERSHIP_1183.csv")
P_BLOCK_QC <- file.path(RUNDIR,"R3_STEP4F_V1_1_block_qc.csv")
P_PARTIAL <- file.path(RUNDIR,"R3_STEP4F_V1_1_PARTIAL_RESULTS_840.csv")
P_RESULTS <- file.path(RUNDIR,"R3_STEP4F_V1_1_LOCALIZATION_RESULTS_840.csv")
P_SN_PRIMARY <- file.path(RUNDIR,"R3_STEP4F_V1_1_PRIMARY_SNRNA_BROAD_84.csv")
P_XE_PRIMARY <- file.path(RUNDIR,"R3_STEP4F_V1_1_PRIMARY_XENIUM_BROAD_60.csv")
P_CROSSMODAL <- file.path(RUNDIR,"R3_STEP4F_V1_1_CROSS_MODAL_BROAD_60.csv")
P_FDR_AUDIT <- file.path(RUNDIR,"R3_STEP4F_V1_1_fixed_family_BH_audit.csv")
P_SUMMARY <- file.path(RUNDIR,"R3_STEP4F_V1_1_RESULT_COUNTS_PRE_INDEPENDENT_AUDIT.txt")
P_SESSION <- file.path(RUNDIR,"R3_STEP4F_V1_1_sessionInfo.txt")
P_BOUNDARY <- file.path(RUNDIR,"R3_STEP4F_V1_1_GATE_BOUNDARY.txt")

audit <- data.frame(check_id=character(),status=character(),detail=character(),stringsAsFactors=FALSE)
final_state <- "HOLD_STEP4F_V1_1_DETERMINISTIC_LOCALIZATION_EXECUTION"

logline <- function(...) {
  s <- paste0(format(Sys.time(),"%Y-%m-%d %H:%M:%S")," | ",paste0(...,collapse=""))
  cat(s,"\n",sep="")
  cat(s,"\n",file=P_LOG,append=TRUE,sep="")
  flush.console()
}

add_audit <- function(id,status,detail) {
  audit <<- rbind(audit,data.frame(check_id=id,status=status,detail=as.character(detail),stringsAsFactors=FALSE))
  logline("[",status,"] ",id," :: ",detail)
}
PASS <- function(id,detail) add_audit(id,"PASS",detail)
HOLD <- function(id,detail) {
  add_audit(id,"FAIL",detail)
  stop(paste0("HOLD: ",detail),call.=FALSE)
}

write_csv <- function(x,p) write.csv(x,p,row.names=FALSE,na="",fileEncoding="UTF-8")

copy_stage <- function(paths) {
  for(p in unique(paths[file.exists(paths)])) {
    ok <- file.copy(p,file.path(STAGING,basename(p)),overwrite=TRUE,copy.mode=TRUE,copy.date=TRUE)
    if(!isTRUE(ok)) stop(paste("Could not stage",p),call.=FALSE)
  }
}

finalize <- function() {
  try(write_csv(audit,P_AUDIT),silent=TRUE)
  try(writeLines(c(
    paste0("RUN_ID=",RUN_ID),
    paste0("FINAL_STATE=",final_state),
    "FIRST_REAL_LOCALIZATION_EXECUTION_GATE=YES",
    "STEP4D_SCIENTIFIC_CONTRACT=UNCHANGED",
    "STEP4D_V1_3_IMPLEMENTATION_OVERLAY=UNCHANGED",
    "STEP4D_V1_4_SNRNA_SOURCE_SEMANTICS=EFFECTIVE",
    "STEP4E_FEASIBILITY_AUTHORITY=UNCHANGED",
    paste0("REAL_LOCALIZATION_RESULTS_GENERATED=",ifelse(grepl("^PASS_",final_state),"YES","PARTIAL_OR_NONE")),
    "FROZEN_REGISTRY_ROWS=840",
    "FIXED_FDR_FAMILIES=8",
    "P_VALUE_COMBINATION_ACROSS_MODALITIES=NO",
    "STEP3F_PROGRAM_CLASS_REDEFINED=NO"
  ),P_STATUS,useBytes=TRUE),silent=TRUE)

  try(writeLines(c(
    "R3 STEP4F V1.1 GATE BOUNDARY",
    paste0("RUN_ID=",RUN_ID),
    "",
    "AUTHORIZED:",
    "- real patient×annotation pseudobulk",
    "- frozen snRNA pairwise filterByExpr/TMM/voom/mroast",
    "- frozen Xenium log2(1+CPM)/mroast",
    "- one independent mroast call per assessable frozen registry row",
    "- external BH within each fixed frozen family",
    "- frozen primary localization labels",
    "- frozen same-cohort broad cross-modal corroboration rule",
    "",
    "FORBIDDEN:",
    "- new genes/programs/annotations/thresholds",
    "- alias/case/fuzzy gene remapping",
    "- leading-edge replacement of full Hallmark sets",
    "- cell-level inferential replication",
    "- family shrinkage",
    "- combined cross-modal P values",
    "- Step3F program-class redefinition",
    "",
    "ALL RESULTS REMAIN PRELIMINARY UNTIL CHATGPT INDEPENDENT AUDIT."
  ),P_BOUNDARY,useBytes=TRUE),silent=TRUE)

  try(copy_stage(c(
    P_PREHASH,P_GMT_DISCOVERY,P_STATUS,P_AUDIT,P_LOG,P_BOUNDARY,
    P_MEMBERSHIP,P_BLOCK_QC,P_PARTIAL,P_RESULTS,P_SN_PRIMARY,
    P_XE_PRIMARY,P_CROSSMODAL,P_FDR_AUDIT,P_SUMMARY,P_SESSION,
    P_STEP4E_STATUS,P_STEP4E_AUDIT,P_STEP4E_RUNTIME,P_STEP4E_PACKAGES,
    P_STEP4E_SMOKE,P_STEP4E_ROLE,P_STEP4E_CROSS,P_STEP4E_DESIGN,
    P_STEP4E_REGFEAS,P_REGISTRY,P_V13_SEM,P_V13_GUARD,P_METHOD,
    P_TIER,P_FDR,P_CLASS,P_LABELS,
    P_V14_STATUS,P_V14_AUDIT,P_V14_OVERLAY,P_V14_DELTA,
    P_V14_REPAIR,P_V14_PRECEDENCE,P_V14_PUBLIC_ID
  )),silent=TRUE)
}
on.exit(finalize(),add=TRUE)

read_csv_req <- function(p,id) {
  if(!file.exists(p)) HOLD(id,paste("Missing:",p))
  if(file.info(p)$size<=0) HOLD(id,paste("Zero-byte:",p))
  x <- tryCatch(read.csv(p,check.names=FALSE,stringsAsFactors=FALSE),error=function(e)NULL)
  if(is.null(x)) HOLD(id,paste("Could not read:",p))
  x
}

require_cols <- function(x,cols,id) {
  m <- setdiff(cols,names(x))
  if(length(m)) HOLD(id,paste("Missing columns:",paste(m,collapse=", ")))
}

parse_ids <- function(x) {
  if(length(x)!=1L || is.na(x) || !nzchar(x)) return(character())
  z <- strsplit(as.character(x),"|",fixed=TRUE)[[1L]]
  z[nzchar(z)]
}

safe_sparse_values <- function(x,allow_negative=FALSE,label="matrix") {
  if(!inherits(x,"sparseMatrix")) HOLD("SPARSE_CLASS",paste(label,"is not sparseMatrix"))
  vals <- x@x
  if(length(vals) && any(!is.finite(vals))) HOLD("SOURCE_MATRIX_FINITE",paste(label,"has NA/NaN/Inf stored values"))
  if(!allow_negative && length(vals) && any(vals<0)) HOLD("SOURCE_MATRIX_NEGATIVE",paste(label,"has negative stored values"))
  invisible(TRUE)
}

parse_gmt <- function(path) {
  lines <- readLines(path,warn=FALSE,encoding="UTF-8")
  sets <- list()
  desc <- character()
  for(line in lines) {
    f <- strsplit(line,"\t",fixed=TRUE)[[1L]]
    if(length(f)<3L) HOLD("GMT_SCHEMA",paste("Malformed GMT line:",substr(line,1,120)))
    nm <- f[1L]
    if(nm %in% names(sets)) HOLD("GMT_DUPLICATE_SET",nm)
    genes <- f[3:length(f)]
    if(any(!nzchar(genes)) || anyDuplicated(genes)) HOLD("GMT_GENE_IDENTITY",paste("Empty/duplicate genes in",nm))
    sets[[nm]] <- genes
    desc[nm] <- f[2L]
  }
  list(sets=sets,description=desc)
}

aggregate_sparse_by_patient_label <- function(x,patient,annotation,patient_order,label_order) {
  if(length(patient)!=ncol(x) || length(annotation)!=ncol(x)) HOLD("AGG_METADATA_LENGTH","Metadata length != expression columns")
  combo_levels <- unlist(lapply(label_order,function(lab) paste(patient_order,lab,sep="||")),use.names=FALSE)
  if(anyDuplicated(combo_levels)) HOLD("AGG_COMBO_DUPLICATE","patient×label combo levels duplicated")
  key <- paste(patient,annotation,sep="||")
  j <- match(key,combo_levels)
  if(anyNA(j)) HOLD("AGG_COMBO_MATCH","At least one cell failed patient×label combo mapping")
  M <- Matrix::sparseMatrix(
    i=seq_along(j),j=j,x=1,
    dims=c(length(j),length(combo_levels))
  )
  pb <- x %*% M
  colnames(pb) <- combo_levels
  rownames(pb) <- rownames(x)
  if(anyDuplicated(colnames(pb)) || anyDuplicated(rownames(pb))) HOLD("AGG_DIMNAME_DUPLICATE","Pseudobulk names duplicated")
  pb
}

classification_primary <- function(row) {
  fam <- as.character(row$family_id)
  assess <- isTRUE(row$assessable)
  q <- as.numeric(row$BH_FDR)
  dir <- as.character(row$Direction)

  if(fam=="SN_BROAD_RVF_vs_pRV_PRIMARY") {
    if(!assess) return("SNRNA_CELLULAR_UNASSESSABLE")
    if(!is.finite(q)) HOLD("CLASSIFICATION_Q","Assessable snRNA primary row has nonfinite BH")
    if(q<0.05) {
      if(dir=="Up") return("SNRNA_CELLULAR_FAILURE_PROGRAM_LOCALIZATION_SUPPORTED")
      if(dir=="Down") return("SNRNA_CELLULAR_DIRECTION_CONFLICT")
      HOLD("CLASSIFICATION_DIRECTION",paste("Unexpected snRNA Direction:",dir))
    }
    return("SNRNA_CELLULAR_INDETERMINATE_NO_SIGNAL")
  }

  if(fam=="XE_BROAD_RVF_vs_pRV_PANEL_PRIMARY_SUPPORT") {
    if(!assess) return("XENIUM_PANEL_UNASSESSABLE")
    if(!is.finite(q)) HOLD("CLASSIFICATION_Q","Assessable Xenium primary row has nonfinite BH")
    if(q<0.05) {
      if(dir=="Up") return("XENIUM_PANEL_SPATIAL_CORROBORATION_SUPPORTED")
      if(dir=="Down") return("XENIUM_PANEL_DIRECTION_CONFLICT")
      HOLD("CLASSIFICATION_DIRECTION",paste("Unexpected Xenium Direction:",dir))
    }
    return("XENIUM_PANEL_INDETERMINATE_NO_SIGNAL")
  }

  ""
}

main <- function() {
  logline("============================================================")
  logline("R3 STEP4F V1.1 — DETERMINISTIC LOCALIZATION EXECUTION")
  logline("FIRST REAL LOCALIZATION RESULT GATE")
  logline("============================================================")

  # ---------------------------------------------------------------------
  # 1. Exact BAT prehash authority
  # ---------------------------------------------------------------------
  ph <- read_csv_req(P_PREHASH,"PREHASH_READ")
  require_cols(ph,c("role","path","exists","expected_sha256","actual_sha256","sha_match"),"PREHASH_COLUMNS")
  if(!all(tolower(as.character(ph$sha_match))=="true")) {
    HOLD("PREHASH_EXACT",paste("Source identity mismatch:",paste(ph$role[tolower(as.character(ph$sha_match))!="true"],collapse=" | ")))
  }
  PASS("PREHASH_EXACT",paste(nrow(ph),"/",nrow(ph),"source identities exact"))

  gd <- read_csv_req(P_GMT_DISCOVERY,"GMT_DISCOVERY_READ")
  require_cols(gd,c("path","bytes","sha256","exact_sha","selected"),"GMT_DISCOVERY_COLUMNS")
  sel <- gd[tolower(as.character(gd$selected))=="true",,drop=FALSE]
  if(nrow(sel)!=1L) HOLD("GMT_SELECTION",paste("Expected exactly one selected exact GMT; found",nrow(sel)))
  if(as.numeric(sel$bytes)!=48686) HOLD("GMT_BYTES",paste("Expected 48686; found",sel$bytes))
  if(tolower(as.character(sel$sha256))!="eecaf6dad908334ae885406ec72bdc0646d8917588ed7c219fac92fc5363f596") HOLD("GMT_SHA","Selected GMT SHA mismatch")
  GMT <- as.character(sel$path)
  PASS("GMT_IDENTITY",paste("Exact MSigDB 2026.1.Hs Hallmark GMT selected:",GMT))

  # ---------------------------------------------------------------------
  # 2. Step4E clean authority + frozen registry
  # ---------------------------------------------------------------------
  st4e <- readLines(P_STEP4E_STATUS,warn=FALSE,encoding="UTF-8")
  step4e_run_lines <- grep("^RUN_ID=",st4e,value=TRUE)
  step4e_required_status <- c(
    "FINAL_STATE=PASS_STEP4E_RUNTIME_AND_DESIGN_FEASIBILITY_PREFLIGHT_READY_FOR_INDEPENDENT_AUDIT",
    "REAL_PSEUDOBULK_EXPRESSION_GENERATED=NO",
    "REAL_MROAST_EXECUTED=NO",
    "LOCALIZATION_SCIENTIFIC_RESULT_PRODUCED=NO"
  )
  if(length(step4e_run_lines)!=1L ||
     !identical(sub("^RUN_ID=","",step4e_run_lines),STEP4E_RUN_ID) ||
     !all(step4e_required_status %in% st4e))
    HOLD("STEP4E_STATUS","Current cold-start Step4E RUN_ID/status sentinels mismatch")

  a4e <- read_csv_req(P_STEP4E_AUDIT,"STEP4E_AUDIT_READ")
  if(nrow(a4e)!=13L || any(a4e$status!="PASS")) HOLD("STEP4E_AUDIT","Expected exact 13/13 PASS Step4E audit")

  reg <- read_csv_req(P_REGISTRY,"REGISTRY_READ")
  require_cols(reg,c(
    "test_ordinal","test_key","test_seed","family_id","dataset","modality",
    "annotation_level","annotation_field","contrast_id","contrast_expression",
    "contrast_numerator","contrast_denominator","factor_levels","contrast_vector",
    "label","program","family_expected_size","primary_claim_role"
  ),"REGISTRY_COLUMNS")

  if(nrow(reg)!=840L ||
     length(unique(reg$test_key))!=840L ||
     !identical(as.integer(reg$test_ordinal),1:840) ||
     length(unique(reg$test_seed))!=840L ||
     !identical(as.integer(range(reg$test_seed)),c(20260911L,20261750L))) {
    HOLD("REGISTRY_CORE","840-test registry integrity failure")
  }

  regfeas <- read_csv_req(P_STEP4E_REGFEAS,"REGFEAS_READ")
  if(nrow(regfeas)!=840L || !identical(as.character(regfeas$test_key),as.character(reg$test_key))) {
    HOLD("REGFEAS_IDENTITY","Step4E registry-feasibility rows do not exactly align to frozen registry")
  }
  PASS("STEP4E_AND_REGISTRY","Step4E 13/13 PASS authority + exact frozen 840-test registry bound")

  # ---------------------------------------------------------------------
  # 2B. Step4D V1.4 source-semantics authority + implementation repair
  # ---------------------------------------------------------------------
  st14 <- readLines(P_V14_STATUS,warn=FALSE,encoding="UTF-8")
  v14_run_lines <- grep("^RUN_ID=",st14,value=TRUE)
  v14_required_status <- c(
    "FINAL_STATE=PASS_STEP4D_V1_4_SNRNA_SOURCE_SEMANTICS_OVERLAY_READY_FOR_INDEPENDENT_AUDIT",
    "PRECEDENCE_SCOPE=SNRNA_SOURCE_SEMANTICS_ONLY",
    "SNRNA_ROUNDING_ADDED=NO",
    "INTEGER_ONLY_GUARD_EFFECTIVE=NO",
    "SCIENTIFIC_LOCALIZATION_RESULT=NO"
  )
  if(length(v14_run_lines)!=1L ||
     !identical(sub("^RUN_ID=","",v14_run_lines),basename(STEP4D_V14_DIR)) ||
     !all(v14_required_status %in% st14))
    HOLD("STEP4D_V14_STATUS","Current cold-start Step4D V1.4 RUN_ID/status sentinels mismatch")

  a14 <- read_csv_req(P_V14_AUDIT,"STEP4D_V14_AUDIT_READ")
  if(nrow(a14)!=7L || any(a14$status!="PASS")) HOLD("STEP4D_V14_AUDIT","Expected exact 7/7 PASS Step4D V1.4 audit")

  ov14 <- read_csv_req(P_V14_OVERLAY,"STEP4D_V14_OVERLAY_READ")
  need_sem <- c(
    COUNT_INPUT_LAYER="RNA/counts",
    COUNT_INPUT_EFFECTIVE_SEMANTICS="DEPOSITED_PROCESSED_COUNT_SCALE",
    FRACTIONAL_VALUES_ALLOWED="TRUE",
    INTEGER_ONLY_GUARD="PROHIBITED_UNAUTHORIZED",
    CELL_LEVEL_ROUNDING="NONE",
    PSEUDOBULK_ROUNDING="NONE"
  )
  for(k in names(need_sem)) {
    z <- ov14$effective_value[ov14$key==k]
    if(length(z)!=1L || as.character(z)!=need_sem[[k]]) {
      HOLD("STEP4D_V14_SEMANTICS",paste(k,"expected",need_sem[[k]],"observed",paste(z,collapse="|")))
    }
  }

  rep14 <- read_csv_req(P_V14_REPAIR,"STEP4F_V11_REPAIR_READ")
  if(nrow(rep14)!=4L || !identical(as.character(rep14$repair_id),c("R01","R02","R03","R04")) ||
     any(as.logical(rep14$scientific_change))) {
    HOLD("STEP4F_V11_REPAIR_CONTRACT","V1.1 implementation repair contract mismatch")
  }

  pub14 <- read_csv_req(P_V14_PUBLIC_ID,"STEP4D_V14_PUBLIC_ID_READ")
  if(nrow(pub14)!=1L ||
     tolower(as.character(pub14$local_md5))!="b13511f74a7abbebecb40ddd0cc04f32" ||
     !isTRUE(as.logical(pub14$zenodo_md5_match))) {
    HOLD("STEP4D_V14_PUBLIC_ID","V1.4 public-object identity mismatch")
  }
  PASS("STEP4D_V14_AUTHORITY","Source semantics + no-rounding + fractional-count policy + V1.1 repair contract exact")

  # ---------------------------------------------------------------------
  # 3. Runtime: exact no-repair gate
  # ---------------------------------------------------------------------
  if(!identical(as.character(getRversion()),"4.6.1")) HOLD("R_VERSION",paste("Expected 4.6.1; observed",getRversion()))
  expected_lib <- normalizePath(PROJECT_LIB,winslash="/",mustWork=TRUE)
  if(tolower(normalizePath(.libPaths()[1L],winslash="/",mustWork=FALSE))!=tolower(expected_lib)) HOLD("PROJECT_LIBRARY","Project library is not first .libPaths()")
  req <- c("limma","edgeR","Matrix","SeuratObject")
  miss <- req[!vapply(req,requireNamespace,logical(1),quietly=TRUE)]
  if(length(miss)) HOLD("RUNTIME_PACKAGES",paste("Missing/unloadable:",paste(miss,collapse=", ")))
  expected_versions <- c(limma="3.68.4",edgeR="4.10.1",Matrix="1.7.5",SeuratObject="5.4.0")
  observed_versions <- vapply(names(expected_versions),function(p)as.character(packageVersion(p)),character(1))
  if(!identical(unname(observed_versions),unname(expected_versions))) {
    HOLD("RUNTIME_PACKAGE_VERSIONS",paste(paste(names(observed_versions),observed_versions,sep="="),collapse=" | "))
  }

  suppressPackageStartupMessages(library(SeuratObject))
  suppressPackageStartupMessages(library(Matrix))
  if("Seurat" %in% loadedNamespaces()) HOLD("FULL_SEURAT","Full Seurat namespace loaded unexpectedly")

  thread_vars <- c("OMP_NUM_THREADS","OPENBLAS_NUM_THREADS","MKL_NUM_THREADS","BLIS_NUM_THREADS")
  if(any(Sys.getenv(thread_vars)!="1")) HOLD("THREADS","Thread guard drift")
  RNGkind(kind="Mersenne-Twister",normal.kind="Inversion",sample.kind="Rejection")
  if(!identical(unname(RNGkind()),c("Mersenne-Twister","Inversion","Rejection"))) HOLD("RNGKIND","RNGkind drift")
  PASS("RUNTIME","R 4.6.1; limma 3.68.4; edgeR 4.10.1; Matrix 1.7.5; SeuratObject 5.4.0; thread/RNG exact")

  # ---------------------------------------------------------------------
  # 4. Exact full Hallmark membership for the 7 frozen programs
  # ---------------------------------------------------------------------
  tier <- read_csv_req(P_TIER,"TIER_READ")
  gmt <- parse_gmt(GMT)
  programs <- as.character(tier$pathway)
  if(length(programs)!=7L || anyDuplicated(programs)) HOLD("PROGRAMS","Tier contract does not contain exact 7 unique programs")
  if(!all(programs %in% names(gmt$sets))) HOLD("PROGRAMS_GMT","One or more frozen programs absent from exact GMT")

  membership_rows <- list()
  for(i in seq_along(programs)) {
    p <- programs[i]
    genes <- gmt$sets[[p]]
    expected_n <- as.integer(tier$frozen_module_genes[tier$pathway==p])
    if(length(genes)!=expected_n) HOLD("PROGRAM_GMT_SIZE",paste(p,"expected",expected_n,"found",length(genes)))
    membership_rows[[i]] <- data.frame(
      program_order=i,program=p,gene_order=seq_along(genes),gene_symbol=genes,
      stringsAsFactors=FALSE
    )
  }
  membership <- do.call(rbind,membership_rows)
  if(nrow(membership)!=1183L) HOLD("MEMBERSHIP_TOTAL",paste("Expected 1183; found",nrow(membership)))
  write_csv(membership,P_MEMBERSHIP)
  gene_sets <- setNames(lapply(programs,function(p) gmt$sets[[p]]),programs)
  PASS("HALLMARK_MEMBERSHIP","7 frozen full Hallmark sets exact; 1183 membership rows")

  # ---------------------------------------------------------------------
  # 5. Frozen metadata role / feasibility authorities
  # ---------------------------------------------------------------------
  role <- read_csv_req(P_STEP4E_ROLE,"ROLE_READ")
  design4e <- read_csv_req(P_STEP4E_DESIGN,"DESIGN_READ")
  count4e <- read_csv_req(P_STEP4E_COUNTS,"COUNT_READ")
  labels <- read_csv_req(P_LABELS,"LABELS_READ")

  get_role <- function(dataset,rr) {
    z <- role[role$dataset==dataset & role$role==rr,"canonical_metadata_column",drop=TRUE]
    if(length(z)!=1L) HOLD("ROLE_UNIQUE",paste(dataset,rr))
    as.character(z)
  }
  sn_group_col <- get_role("SNRNA","GROUP")
  sn_patient_col <- get_role("SNRNA","PATIENT")
  xe_group_col <- get_role("XENIUM","GROUP")
  xe_patient_col <- get_role("XENIUM","PATIENT")

  get_labels <- function(dataset,field,n) {
    z <- as.character(labels$label[labels$dataset==dataset & labels$field==field])
    if(length(z)!=n || anyDuplicated(z)) HOLD("LABEL_VECTOR",paste(dataset,field))
    z
  }
  sn_broad <- get_labels("GSE345646_snRNA","Names",12L)
  sn_fine <- get_labels("GSE345646_snRNA","Subnames_manual",34L)
  xe_broad <- get_labels("GSE345643_Xenium_ambient_corrected","cell_type_rctd_doublet",12L)
  xe_fine <- get_labels("GSE345643_Xenium_ambient_corrected","cell_type_seurat",34L)

  # result skeleton from exact frozen registry
  result <- reg
  result$step4e_patient_design_feasible <- as.logical(regfeas$patient_design_feasible)
  result$assessable <- FALSE
  result$unassessable_reason <- ""
  result$n_analysis_genes <- NA_integer_
  result$n_program_genes_in_test <- NA_integer_
  result$PValue_raw <- NA_real_
  result$Direction <- ""
  result$P_for_BH <- NA_real_
  result$BH_FDR <- NA_real_
  result$FDR_significant <- FALSE
  result$primary_localization_class <- ""
  result$execution_status <- "NOT_REACHED"

  # merge frozen upstream Step3F class, without allowing any redefinition
  mti <- match(result$program,tier$pathway)
  if(anyNA(mti)) HOLD("PROGRAM_TIER_JOIN","Registry program missing from tier contract")
  result$failure_direction <- as.character(tier$failure_direction[mti])
  result$Step3F_program_class <- as.character(tier$program_class[mti])

  # R03: explicit result schema exists on disk BEFORE any real expression test.
  # On technical HOLD, this prevents ambiguity with a registry-only "partial".
  write_csv(result,P_PARTIAL)
  PASS("V1_1_SCOPE_REPAIR","Single local result object initialized with full result schema; unauthorized integer guard absent")
  block_qc <- data.frame(
    modality=character(),annotation_level=character(),contrast_id=character(),label=character(),
    design_feasible=logical(),n_den=integer(),n_num=integer(),n_analysis_genes=integer(),
    zero_library=logical(),detail=character(),stringsAsFactors=FALSE
  )

  # ---------------------------------------------------------------------
  # Helper: verify metadata-derived count manifest against Step4E exact counts.
  # ---------------------------------------------------------------------
  verify_counts <- function(modality,ann_level,ann_field,patient,group,annotation,frozen_labels) {
    pats <- sort(unique(patient),method="radix")
    tb <- table(factor(patient,levels=pats),factor(annotation,levels=frozen_labels))
    obs <- expand.grid(patient_id=pats,label=frozen_labels,KEEP.OUT.ATTRS=FALSE,stringsAsFactors=FALSE)
    obs$cell_count <- mapply(function(p,l)as.integer(tb[p,l]),obs$patient_id,obs$label)
    gmap <- tapply(group,patient,function(z)unique(z))
    if(any(lengths(gmap)!=1L)) HOLD("PATIENT_GROUP_MAP","Patient maps to >1 group")
    obs$group <- as.character(gmap[obs$patient_id])
    obs$eligible_ge20 <- obs$cell_count>=20L

    ref <- count4e[count4e$modality==modality & count4e$annotation_level==ann_level & count4e$annotation_field==ann_field,
                   c("label","patient_id","group","cell_count","eligible_ge20")]
    ref$patient_id <- as.character(ref$patient_id)
    obs$patient_id <- as.character(obs$patient_id)

    keyo <- paste(obs$label,obs$patient_id,sep="|")
    keyr <- paste(ref$label,ref$patient_id,sep="|")
    mm <- match(keyo,keyr)
    if(anyNA(mm) || nrow(obs)!=nrow(ref)) HOLD("COUNT_MANIFEST_JOIN",paste(modality,ann_level))
    if(any(obs$group!=ref$group[mm]) ||
       any(obs$cell_count!=as.integer(ref$cell_count[mm])) ||
       any(obs$eligible_ge20!=as.logical(ref$eligible_ge20[mm]))) {
      HOLD("COUNT_MANIFEST_DRIFT",paste(modality,ann_level,"metadata counts differ from Step4E"))
    }
    invisible(TRUE)
  }

  # ---------------------------------------------------------------------
  # Helper: verify Step4E design row IDs against current metadata.
  # ---------------------------------------------------------------------
  design_row <- function(modality,ann_level,contrast,label) {
    z <- design4e[
      design4e$modality==modality &
      design4e$annotation_level==ann_level &
      design4e$contrast_id==contrast &
      design4e$label==label,,drop=FALSE]
    if(nrow(z)!=1L) HOLD("DESIGN_ROW",paste(modality,ann_level,contrast,label))
    z
  }

  validate_design_ids <- function(dr,patient,group,annotation,label) {
    num <- as.character(dr$contrast_numerator)
    den <- as.character(dr$contrast_denominator)
    cnt <- table(patient,annotation)
    eligible <- setNames(as.integer(cnt[,label]),rownames(cnt))>=20L
    gm <- tapply(group,patient,function(z)unique(z))
    pnum <- sort(names(gm)[vapply(gm,function(z)identical(as.character(z),num),logical(1)) & eligible[names(gm)]],method="radix")
    pden <- sort(names(gm)[vapply(gm,function(z)identical(as.character(z),den),logical(1)) & eligible[names(gm)]],method="radix")
    refnum <- parse_ids(dr$eligible_patient_ids_numerator)
    refden <- parse_ids(dr$eligible_patient_ids_denominator)
    if(!identical(pnum,refnum) || !identical(pden,refden)) {
      HOLD("DESIGN_ID_DRIFT",paste(dr$modality,dr$annotation_level,dr$contrast_id,dr$label))
    }
    list(num=pnum,den=pden,feasible=length(pnum)>=3L && length(pden)>=3L)
  }

  # ---------------------------------------------------------------------
  # Helper: one exact mroast call.
  # ---------------------------------------------------------------------
  call_mroast <- function(y,index,design,contrast,seed,trend_var) {
    set.seed(as.integer(seed))
    limma::mroast(
      y=y,
      index=list(FROZEN_PROGRAM=index),
      design=design,
      contrast=contrast,
      set.statistic="mean",
      nrot=9999,
      approx.zscore=TRUE,
      legacy=FALSE,
      adjust.method="none",
      midp=TRUE,
      sort="none",
      trend.var=trend_var
    )
  }

  # ---------------------------------------------------------------------
  # 6. snRNA execution
  # ---------------------------------------------------------------------
  logline("Loading snRNA frozen RDS...")
  sn_obj <- readRDS(SN_RDS)
  if(!inherits(sn_obj,"Seurat")) HOLD("SN_CLASS","snRNA object not Seurat")
  sn_meta <- sn_obj@meta.data
  sn_x <- SeuratObject::LayerData(sn_obj[["RNA"]],layer="counts")

  if(!identical(colnames(sn_x),rownames(sn_meta))) HOLD("SN_EXPR_META_ID","snRNA expression columns != metadata rows")
  if(anyDuplicated(colnames(sn_x)) || anyDuplicated(rownames(sn_x))) HOLD("SN_DUP_NAMES","snRNA gene/cell names duplicated")
  safe_sparse_values(sn_x,allow_negative=FALSE,label="snRNA RNA/counts")
  # Step4D V1.4: this deposited processed count-scale layer is expected to be fractional.
  # Integer-only rejection and any rounding are explicitly prohibited.
  if(!all(c(sn_group_col,sn_patient_col,"Names","Subnames_manual") %in% names(sn_meta))) HOLD("SN_META_FIELDS","snRNA frozen metadata fields missing")
  PASS("SNRNA_SOURCE_SEMANTICS","RNA/counts accepted as nonnegative finite deposited processed count-scale values; fractional values retained exactly; no rounding")

  sn_patient <- as.character(sn_meta[[sn_patient_col]])
  sn_group <- as.character(sn_meta[[sn_group_col]])
  if(anyNA(sn_patient)||anyNA(sn_group)) HOLD("SN_META_NA","snRNA patient/group NA")
  if(!setequal(unique(sn_group),c("NF","pRV","RVF"))) HOLD("SN_GROUPS","snRNA groups drift")

  verify_counts("SNRNA","BROAD","Names",sn_patient,sn_group,as.character(sn_meta$Names),sn_broad)
  verify_counts("SNRNA","FINE","Subnames_manual",sn_patient,sn_group,as.character(sn_meta$Subnames_manual),sn_fine)
  PASS("SNRNA_METADATA_COUNTS","snRNA metadata patient/group/annotation counts exact vs Step4E")

  sn_pat_order <- sort(unique(sn_patient),method="radix")

  sn_blocks <- unique(reg[reg$modality=="SNRNA",
    c("modality","annotation_level","annotation_field","contrast_id","contrast_expression",
      "contrast_numerator","contrast_denominator","factor_levels","contrast_vector","label")])

  block_counter <- 0L
  for(ann_level in c("BROAD","FINE")) {
    ann_field <- if(ann_level=="BROAD") "Names" else "Subnames_manual"
    lab_order <- if(ann_level=="BROAD") sn_broad else sn_fine
    ann_vec <- as.character(sn_meta[[ann_field]])

    logline("Building snRNA ",ann_level," patient×label sparse pseudobulk...")
    pb <- aggregate_sparse_by_patient_label(sn_x,sn_patient,ann_vec,sn_pat_order,lab_order)

    bsub <- sn_blocks[sn_blocks$annotation_level==ann_level,,drop=FALSE]
    for(ii in seq_len(nrow(bsub))) {
      b <- bsub[ii,,drop=FALSE]
      block_counter <- block_counter+1L
      logline("snRNA block ",block_counter,"/",nrow(sn_blocks)," :: ",ann_level," | ",b$contrast_id," | ",b$label)

      ridx <- which(
        result$modality=="SNRNA" &
        result$annotation_level==ann_level &
        result$contrast_id==b$contrast_id &
        result$label==b$label
      )
      if(length(ridx)!=7L) HOLD("SN_BLOCK_REGISTRY_N",paste(b$contrast_id,b$label,length(ridx)))

      dr <- design_row("SNRNA",ann_level,b$contrast_id,b$label)
      ids <- validate_design_ids(dr,sn_patient,sn_group,ann_vec,b$label)
      if(isTRUE(dr$patient_design_feasible)!=ids$feasible) HOLD("SN_STEP4E_FEAS_DRIFT",paste(b$contrast_id,b$label))

      if(!ids$feasible) {
        result$assessable[ridx] <- FALSE
        result$unassessable_reason[ridx] <- "PATIENT_DESIGN_UNASSESSABLE_STEP4E"
        result$P_for_BH[ridx] <- 1
        result$execution_status[ridx] <- "STRUCTURAL_UNASSESSABLE_NO_MROAST"
        block_qc <- rbind(block_qc,data.frame(
          modality="SNRNA",annotation_level=ann_level,contrast_id=b$contrast_id,label=b$label,
          design_feasible=FALSE,n_den=length(ids$den),n_num=length(ids$num),
          n_analysis_genes=NA_integer_,zero_library=NA,detail="Step4E patient-design unassessable",
          stringsAsFactors=FALSE))
        write_csv(result,P_PARTIAL)
        next
      }

      sample_ids <- c(ids$den,ids$num)
      combos <- paste(sample_ids,b$label,sep="||")
      if(any(!combos %in% colnames(pb))) HOLD("SN_PB_COLUMNS","Missing snRNA pseudobulk combo")
      pair_sp <- pb[,combos,drop=FALSE]
      colnames(pair_sp) <- sample_ids
      # Safe small densification only AFTER patient×label aggregation:
      # <=32,938 genes x <=11 patient samples. Full nuclei matrix is never densified.
      pair <- as.matrix(pair_sp)

      if(anyDuplicated(colnames(pair)) || anyDuplicated(rownames(pair))) HOLD("SN_PAIR_NAMES","snRNA pair names duplicated")
      if(any(!is.finite(pair)) || any(pair<0)) HOLD("SN_PAIR_VALUES","snRNA pseudobulk pair has nonfinite/negative values")
      lib <- colSums(pair)
      if(any(!is.finite(lib))) HOLD("SN_LIBRARY_FINITE","snRNA library nonfinite")
      if(any(lib<=0)) {
        result$assessable[ridx] <- FALSE
        result$unassessable_reason[ridx] <- "SNRNA_ZERO_PSEUDOBULK_LIBRARY"
        result$P_for_BH[ridx] <- 1
        result$execution_status[ridx] <- "BLOCK_UNASSESSABLE_NO_MROAST"
        block_qc <- rbind(block_qc,data.frame(
          modality="SNRNA",annotation_level=ann_level,contrast_id=b$contrast_id,label=b$label,
          design_feasible=TRUE,n_den=length(ids$den),n_num=length(ids$num),
          n_analysis_genes=NA_integer_,zero_library=TRUE,detail="At least one pseudobulk library <=0",
          stringsAsFactors=FALSE))
        write_csv(result,P_PARTIAL)
        next
      }

      lev <- strsplit(as.character(b$factor_levels),"|",fixed=TRUE)[[1L]]
      if(!identical(lev,c(as.character(b$contrast_denominator),as.character(b$contrast_numerator)))) HOLD("SN_FACTOR_LEVEL","Registry factor levels mismatch")
      group <- factor(c(rep(b$contrast_denominator,length(ids$den)),rep(b$contrast_numerator,length(ids$num))),levels=lev)
      design <- model.matrix(~0+group)
      colnames(design) <- levels(group)
      contrast <- setNames(c(-1,+1),c(as.character(b$contrast_denominator),as.character(b$contrast_numerator)))

      if(qr(design)$rank!=ncol(design) || !identical(names(contrast),colnames(design)) || any(!is.finite(contrast))) {
        result$assessable[ridx] <- FALSE
        result$unassessable_reason[ridx] <- "DESIGN_RANK_OR_CONTRAST_UNESTIMABLE"
        result$P_for_BH[ridx] <- 1
        result$execution_status[ridx] <- "BLOCK_UNASSESSABLE_NO_MROAST"
        write_csv(result,P_PARTIAL)
        next
      }

      y <- edgeR::DGEList(counts=pair,group=group)
      keep <- edgeR::filterByExpr(
        y,design=design,min.count=10,min.total.count=15,large.n=10,min.prop=0.7
      )
      nkeep <- sum(keep)
      if(nkeep<1L) {
        result$assessable[ridx] <- FALSE
        result$unassessable_reason[ridx] <- "SNRNA_FILTERBYEXPR_EMPTY_UNIVERSE"
        result$n_analysis_genes[ridx] <- 0L
        result$P_for_BH[ridx] <- 1
        result$execution_status[ridx] <- "BLOCK_UNASSESSABLE_NO_MROAST"
        write_csv(result,P_PARTIAL)
        next
      }

      y <- y[keep,,keep.lib.sizes=FALSE]
      y <- edgeR::calcNormFactors(y,method="TMM")
      v <- limma::voom(y,design=design,plot=FALSE)

      if(any(!is.finite(v$E))) HOLD("SN_VOOM_FINITE",paste(b$contrast_id,b$label,"voom E nonfinite"))
      if(anyDuplicated(rownames(v$E)) || anyDuplicated(colnames(v$E))) HOLD("SN_VOOM_NAMES","voom dimnames duplicated")

      result$n_analysis_genes[ridx] <- nrow(v$E)

      for(rr in ridx) {
        prog <- as.character(result$program[rr])
        genes <- gene_sets[[prog]]
        idx <- match(genes,rownames(v$E),nomatch=0L)
        idx <- idx[idx>0L]
        result$n_program_genes_in_test[rr] <- length(idx)

        if(length(idx)<10L) {
          result$assessable[rr] <- FALSE
          result$unassessable_reason[rr] <- "SNRNA_PROGRAM_INDEX_LT10_AFTER_FILTERBYEXPR"
          result$P_for_BH[rr] <- 1
          result$execution_status[rr] <- "PROGRAM_UNASSESSABLE_NO_MROAST"
          next
        }

        fit <- call_mroast(v,idx,design,contrast,result$test_seed[rr],FALSE)
        if(nrow(fit)!=1L || !all(c("Direction","PValue") %in% colnames(fit))) HOLD("SN_MROAST_SCHEMA",prog)
        pv <- as.numeric(fit$PValue[1L]); di <- as.character(fit$Direction[1L])
        if(!is.finite(pv)||pv<0||pv>1||!di %in% c("Up","Down")) HOLD("SN_MROAST_RESULT",paste(prog,pv,di))
        result$assessable[rr] <- TRUE
        result$PValue_raw[rr] <- pv
        result$Direction[rr] <- di
        result$P_for_BH[rr] <- pv
        result$execution_status[rr] <- "MROAST_EXECUTED"
      }

      block_qc <- rbind(block_qc,data.frame(
        modality="SNRNA",annotation_level=ann_level,contrast_id=b$contrast_id,label=b$label,
        design_feasible=TRUE,n_den=length(ids$den),n_num=length(ids$num),
        n_analysis_genes=nrow(v$E),zero_library=FALSE,
        detail=paste0("filterByExpr retained ",nrow(v$E)," genes"),
        stringsAsFactors=FALSE))
      write_csv(result,P_PARTIAL)
      write_csv(block_qc,P_BLOCK_QC)
    }
    rm(pb); gc(verbose=FALSE)
  }

  rm(sn_x,sn_meta,sn_obj); gc(verbose=FALSE)
  PASS("SNRNA_EXECUTION","All frozen snRNA blocks completed or deterministically marked unassessable")

  # ---------------------------------------------------------------------
  # 7. Xenium execution
  # ---------------------------------------------------------------------
  logline("Loading Xenium frozen RDS...")
  xe_obj <- readRDS(XE_RDS)
  if(!inherits(xe_obj,"Seurat")) HOLD("XE_CLASS","Xenium object not Seurat")
  xe_meta <- xe_obj@meta.data
  xe_x <- SeuratObject::LayerData(xe_obj[["Xenium"]],layer="counts")

  if(!identical(colnames(xe_x),rownames(xe_meta))) HOLD("XE_EXPR_META_ID","Xenium expression columns != metadata rows")
  if(anyDuplicated(colnames(xe_x)) || anyDuplicated(rownames(xe_x))) HOLD("XE_DUP_NAMES","Xenium gene/cell names duplicated")
  # Frozen global rule: ANY negative ambient-corrected value => whole Gate HOLD.
  safe_sparse_values(xe_x,allow_negative=FALSE,label="Xenium ambient-corrected counts")
  if(nrow(xe_x)!=477L) HOLD("XE_PANEL_N",paste("Expected 477 genes; found",nrow(xe_x)))
  if(!all(c(xe_group_col,xe_patient_col,"cell_type_rctd_doublet","cell_type_seurat") %in% names(xe_meta))) HOLD("XE_META_FIELDS","Xenium frozen metadata fields missing")

  xe_patient <- as.character(xe_meta[[xe_patient_col]])
  xe_group <- as.character(xe_meta[[xe_group_col]])
  if(anyNA(xe_patient)||anyNA(xe_group)) HOLD("XE_META_NA","Xenium patient/group NA")
  if(!setequal(unique(xe_group),c("NF","pRV","RVF"))) HOLD("XE_GROUPS","Xenium groups drift")

  verify_counts("XENIUM","BROAD","cell_type_rctd_doublet",xe_patient,xe_group,as.character(xe_meta$cell_type_rctd_doublet),xe_broad)
  verify_counts("XENIUM","FINE","cell_type_seurat",xe_patient,xe_group,as.character(xe_meta$cell_type_seurat),xe_fine)
  PASS("XENIUM_METADATA_COUNTS","Xenium metadata patient/group/annotation counts exact vs Step4E")

  xe_pat_order <- sort(unique(xe_patient),method="radix")
  xe_blocks <- unique(reg[reg$modality=="XENIUM",
    c("modality","annotation_level","annotation_field","contrast_id","contrast_expression",
      "contrast_numerator","contrast_denominator","factor_levels","contrast_vector","label")])

  xe_block_counter <- 0L
  for(ann_level in c("BROAD","FINE")) {
    ann_field <- if(ann_level=="BROAD") "cell_type_rctd_doublet" else "cell_type_seurat"
    lab_order <- if(ann_level=="BROAD") xe_broad else xe_fine
    ann_vec <- as.character(xe_meta[[ann_field]])

    logline("Building Xenium ",ann_level," patient×label sparse pseudobulk...")
    pb <- aggregate_sparse_by_patient_label(xe_x,xe_patient,ann_vec,xe_pat_order,lab_order)

    bsub <- xe_blocks[xe_blocks$annotation_level==ann_level,,drop=FALSE]
    for(ii in seq_len(nrow(bsub))) {
      b <- bsub[ii,,drop=FALSE]
      xe_block_counter <- xe_block_counter+1L
      logline("Xenium block ",xe_block_counter,"/",nrow(xe_blocks)," :: ",ann_level," | ",b$contrast_id," | ",b$label)

      ridx <- which(
        result$modality=="XENIUM" &
        result$annotation_level==ann_level &
        result$contrast_id==b$contrast_id &
        result$label==b$label
      )
      if(length(ridx)!=5L) HOLD("XE_BLOCK_REGISTRY_N",paste(b$contrast_id,b$label,length(ridx)))

      dr <- design_row("XENIUM",ann_level,b$contrast_id,b$label)
      ids <- validate_design_ids(dr,xe_patient,xe_group,ann_vec,b$label)
      if(isTRUE(dr$patient_design_feasible)!=ids$feasible) HOLD("XE_STEP4E_FEAS_DRIFT",paste(b$contrast_id,b$label))

      if(!ids$feasible) {
        result$assessable[ridx] <- FALSE
        result$unassessable_reason[ridx] <- "PATIENT_DESIGN_UNASSESSABLE_STEP4E"
        result$P_for_BH[ridx] <- 1
        result$execution_status[ridx] <- "STRUCTURAL_UNASSESSABLE_NO_MROAST"
        block_qc <- rbind(block_qc,data.frame(
          modality="XENIUM",annotation_level=ann_level,contrast_id=b$contrast_id,label=b$label,
          design_feasible=FALSE,n_den=length(ids$den),n_num=length(ids$num),
          n_analysis_genes=477L,zero_library=NA,detail="Step4E patient-design unassessable",
          stringsAsFactors=FALSE))
        write_csv(result,P_PARTIAL)
        next
      }

      sample_ids <- c(ids$den,ids$num)
      combos <- paste(sample_ids,b$label,sep="||")
      if(any(!combos %in% colnames(pb))) HOLD("XE_PB_COLUMNS","Missing Xenium pseudobulk combo")
      pair_sp <- pb[,combos,drop=FALSE]
      colnames(pair_sp) <- sample_ids
      pair <- as.matrix(pair_sp)  # 477 x <=7 only; full-cell matrix is NEVER densified.

      if(anyDuplicated(colnames(pair)) || anyDuplicated(rownames(pair))) HOLD("XE_PAIR_NAMES","Xenium pair names duplicated")
      if(any(!is.finite(pair))) HOLD("XE_PAIR_FINITE","Xenium pseudobulk pair nonfinite")
      if(any(pair<0)) HOLD("XE_PAIR_NEGATIVE","Xenium pseudobulk negative despite global guard")

      denom <- colSums(pair)
      if(any(!is.finite(denom))) HOLD("XE_DENOM_FINITE","Xenium denominator nonfinite")
      if(any(denom<=0)) {
        result$assessable[ridx] <- FALSE
        result$unassessable_reason[ridx] <- "XENIUM_477_GENE_PSEUDOBULK_DENOMINATOR_LE0"
        result$n_analysis_genes[ridx] <- 477L
        result$P_for_BH[ridx] <- 1
        result$execution_status[ridx] <- "BLOCK_UNASSESSABLE_NO_MROAST"
        block_qc <- rbind(block_qc,data.frame(
          modality="XENIUM",annotation_level=ann_level,contrast_id=b$contrast_id,label=b$label,
          design_feasible=TRUE,n_den=length(ids$den),n_num=length(ids$num),
          n_analysis_genes=477L,zero_library=TRUE,detail="477-gene denominator <=0",
          stringsAsFactors=FALSE))
        write_csv(result,P_PARTIAL)
        next
      }

      logcpm <- log2(1 + sweep(pair,2,denom,"/")*1e6)
      if(any(!is.finite(logcpm))) HOLD("XE_LOGCPM_FINITE","Xenium logCPM nonfinite")

      lev <- strsplit(as.character(b$factor_levels),"|",fixed=TRUE)[[1L]]
      if(!identical(lev,c(as.character(b$contrast_denominator),as.character(b$contrast_numerator)))) HOLD("XE_FACTOR_LEVEL","Registry factor levels mismatch")
      group <- factor(c(rep(b$contrast_denominator,length(ids$den)),rep(b$contrast_numerator,length(ids$num))),levels=lev)
      design <- model.matrix(~0+group)
      colnames(design) <- levels(group)
      contrast <- setNames(c(-1,+1),c(as.character(b$contrast_denominator),as.character(b$contrast_numerator)))

      if(qr(design)$rank!=ncol(design) || !identical(names(contrast),colnames(design)) || any(!is.finite(contrast))) {
        result$assessable[ridx] <- FALSE
        result$unassessable_reason[ridx] <- "DESIGN_RANK_OR_CONTRAST_UNESTIMABLE"
        result$n_analysis_genes[ridx] <- 477L
        result$P_for_BH[ridx] <- 1
        result$execution_status[ridx] <- "BLOCK_UNASSESSABLE_NO_MROAST"
        write_csv(result,P_PARTIAL)
        next
      }

      row_nonzero <- rowSums(pair)>0
      result$n_analysis_genes[ridx] <- 477L

      for(rr in ridx) {
        prog <- as.character(result$program[rr])
        genes <- gene_sets[[prog]]
        measured_idx <- match(genes,rownames(pair),nomatch=0L)
        measured_idx <- measured_idx[measured_idx>0L]
        idx <- measured_idx[row_nonzero[measured_idx]]
        result$n_program_genes_in_test[rr] <- length(idx)

        if(length(idx)<10L) {
          result$assessable[rr] <- FALSE
          result$unassessable_reason[rr] <- "XENIUM_MEASURED_AND_NONZERO_PROGRAM_INDEX_LT10"
          result$P_for_BH[rr] <- 1
          result$execution_status[rr] <- "PROGRAM_UNASSESSABLE_NO_MROAST"
          next
        }

        fit <- call_mroast(logcpm,idx,design,contrast,result$test_seed[rr],TRUE)
        if(nrow(fit)!=1L || !all(c("Direction","PValue") %in% colnames(fit))) HOLD("XE_MROAST_SCHEMA",prog)
        pv <- as.numeric(fit$PValue[1L]); di <- as.character(fit$Direction[1L])
        if(!is.finite(pv)||pv<0||pv>1||!di %in% c("Up","Down")) HOLD("XE_MROAST_RESULT",paste(prog,pv,di))
        result$assessable[rr] <- TRUE
        result$PValue_raw[rr] <- pv
        result$Direction[rr] <- di
        result$P_for_BH[rr] <- pv
        result$execution_status[rr] <- "MROAST_EXECUTED"
      }

      block_qc <- rbind(block_qc,data.frame(
        modality="XENIUM",annotation_level=ann_level,contrast_id=b$contrast_id,label=b$label,
        design_feasible=TRUE,n_den=length(ids$den),n_num=length(ids$num),
        n_analysis_genes=477L,zero_library=FALSE,
        detail="all 477 measured genes retained in mroast y; program index uses measured AND NONZERO_IN_TEST",
        stringsAsFactors=FALSE))
      write_csv(result,P_PARTIAL)
      write_csv(block_qc,P_BLOCK_QC)
    }
    rm(pb); gc(verbose=FALSE)
  }

  rm(xe_x,xe_meta,xe_obj); gc(verbose=FALSE)
  PASS("XENIUM_EXECUTION","All frozen Xenium blocks completed or deterministically marked unassessable")

  # ---------------------------------------------------------------------
  # 8. Completeness before external BH
  # ---------------------------------------------------------------------
  if(any(result$execution_status=="NOT_REACHED")) HOLD("EXECUTION_COMPLETENESS","At least one registry row NOT_REACHED")
  if(any(is.na(result$P_for_BH)) || any(!is.finite(result$P_for_BH)) ||
     any(result$P_for_BH<0 | result$P_for_BH>1)) {
    HOLD("P_FOR_BH_VALID","P_for_BH incomplete/nonfinite/out of range")
  }
  if(any(result$assessable & (is.na(result$PValue_raw) | !result$Direction %in% c("Up","Down")))) {
    HOLD("ASSESSABLE_RESULT_COMPLETENESS","Assessable row missing PValue/Direction")
  }
  if(any(!result$assessable & result$P_for_BH!=1)) HOLD("UNASSESSABLE_PADDING","Unassessable row not padded with P_for_BH=1")
  PASS("EXECUTION_COMPLETENESS","840/840 rows reached; assessable results valid; all unassessable P_for_BH=1")

  # ---------------------------------------------------------------------
  # 9. External fixed-family BH — exact full family size
  # ---------------------------------------------------------------------
  fdr_contract <- read_csv_req(P_FDR,"FDR_CONTRACT_READ")
  fam_order <- as.character(fdr_contract$family_id)
  fdr_rows <- list()

  for(i in seq_along(fam_order)) {
    fam <- fam_order[i]
    ix <- which(result$family_id==fam)
    expn <- as.integer(fdr_contract$max_family_tests[fdr_contract$family_id==fam])
    if(length(ix)!=expn) HOLD("FAMILY_SIZE",paste(fam,length(ix),expn))
    result$BH_FDR[ix] <- p.adjust(result$P_for_BH[ix],method="BH")
    result$FDR_significant[ix] <- result$assessable[ix] & result$BH_FDR[ix] < 0.05

    fdr_rows[[i]] <- data.frame(
      family_order=i,family_id=fam,expected_n=expn,observed_n=length(ix),
      n_assessable=sum(result$assessable[ix]),
      n_unassessable=sum(!result$assessable[ix]),
      n_FDR_lt_0_05=sum(result$FDR_significant[ix]),
      min_raw_P_if_assessable=if(any(result$assessable[ix]))min(result$PValue_raw[ix][result$assessable[ix]]) else NA_real_,
      min_BH=if(length(ix))min(result$BH_FDR[ix]) else NA_real_,
      adjustment="BH_EXTERNAL_ON_FULL_FROZEN_FAMILY",
      stringsAsFactors=FALSE
    )
  }
  fdr_audit <- do.call(rbind,fdr_rows)
  write_csv(fdr_audit,P_FDR_AUDIT)
  if(any(!is.finite(result$BH_FDR)) || any(result$BH_FDR<0 | result$BH_FDR>1)) HOLD("BH_VALID","BH result invalid")
  PASS("EXTERNAL_BH","8/8 exact frozen families adjusted externally without family shrinkage")

  # ---------------------------------------------------------------------
  # 10. Frozen primary localization classification
  # ---------------------------------------------------------------------
  result$primary_localization_class <- vapply(seq_len(nrow(result)),function(i)classification_primary(result[i,,drop=FALSE]),character(1))

  # Ensure no primary class leaked into contextual/fine families.
  primary_fams <- c("SN_BROAD_RVF_vs_pRV_PRIMARY","XE_BROAD_RVF_vs_pRV_PANEL_PRIMARY_SUPPORT")
  if(any(nzchar(result$primary_localization_class[!result$family_id %in% primary_fams]))) {
    HOLD("PRIMARY_CLASS_SCOPE","Primary localization class leaked outside primary broad families")
  }

  sn_primary <- result[result$family_id=="SN_BROAD_RVF_vs_pRV_PRIMARY",,drop=FALSE]
  xe_primary <- result[result$family_id=="XE_BROAD_RVF_vs_pRV_PANEL_PRIMARY_SUPPORT",,drop=FALSE]
  if(nrow(sn_primary)!=84L || nrow(xe_primary)!=60L) HOLD("PRIMARY_ROWS","Primary family row counts drift")
  write_csv(sn_primary,P_SN_PRIMARY)
  write_csv(xe_primary,P_XE_PRIMARY)

  # ---------------------------------------------------------------------
  # 11. Frozen broad same-cohort cross-modal rule — 12 labels x 5 XE programs
  # ---------------------------------------------------------------------
  xe_programs <- as.character(tier$pathway[as.logical(tier$Xenium_module_family_member)])
  cross_rows <- list()
  k <- 0L
  for(lab in sn_broad) {
    for(prog in xe_programs) {
      k <- k+1L
      s <- sn_primary[sn_primary$label==lab & sn_primary$program==prog,,drop=FALSE]
      x <- xe_primary[xe_primary$label==lab & xe_primary$program==prog,,drop=FALSE]
      if(nrow(s)!=1L || nrow(x)!=1L) HOLD("CROSSMODAL_JOIN",paste(lab,prog))

      s_sig <- isTRUE(s$assessable) && isTRUE(s$BH_FDR<0.05)
      x_sig <- isTRUE(x$assessable) && isTRUE(x$BH_FDR<0.05)
      claim <- ""
      if(identical(as.character(s$primary_localization_class),
                   "SNRNA_CELLULAR_FAILURE_PROGRAM_LOCALIZATION_SUPPORTED") &&
         identical(as.character(x$primary_localization_class),
                   "XENIUM_PANEL_SPATIAL_CORROBORATION_SUPPORTED")) {
        claim <- "CROSS_MODAL_BROAD_CORROBORATION_SAME_COHORT"
      } else if(s_sig && x_sig && as.character(s$Direction)!=as.character(x$Direction)) {
        claim <- "CROSS_MODAL_SIGNIFICANT_DIRECTION_CONFLICT"
      }

      cross_rows[[k]] <- data.frame(
        label=lab,program=prog,
        Step3F_program_class=as.character(s$Step3F_program_class),
        failure_direction=as.character(s$failure_direction),
        snRNA_assessable=s$assessable,
        snRNA_Direction=s$Direction,
        snRNA_BH_FDR=s$BH_FDR,
        snRNA_primary_class=s$primary_localization_class,
        Xenium_assessable=x$assessable,
        Xenium_Direction=x$Direction,
        Xenium_BH_FDR=x$BH_FDR,
        Xenium_primary_class=x$primary_localization_class,
        cross_modal_claim_triggered=nzchar(claim),
        cross_modal_frozen_label=claim,
        independent_validation=FALSE,
        combined_P_value=FALSE,
        stringsAsFactors=FALSE
      )
    }
  }
  cross <- do.call(rbind,cross_rows)
  if(nrow(cross)!=60L) HOLD("CROSSMODAL_N","Expected 60 broad cross-modal rows")
  write_csv(cross,P_CROSSMODAL)
  PASS("FROZEN_CLASSIFICATION","Primary snRNA/Xenium classifications + 60-row same-cohort broad cross-modal rule applied")

  # ---------------------------------------------------------------------
  # 12. Final result integrity and preliminary counts
  # ---------------------------------------------------------------------
  write_csv(block_qc,P_BLOCK_QC)
  write_csv(result,P_RESULTS)
  write_csv(result,P_PARTIAL)

  # Re-read exact row identity.
  rr <- read.csv(P_RESULTS,check.names=FALSE,stringsAsFactors=FALSE)
  if(nrow(rr)!=840L || !identical(as.character(rr$test_key),as.character(reg$test_key))) HOLD("RESULT_WRITEBACK","On-disk 840 result row identity drift")

  sn_class_counts <- sort(table(sn_primary$primary_localization_class),decreasing=TRUE)
  xe_class_counts <- sort(table(xe_primary$primary_localization_class),decreasing=TRUE)
  cross_count <- sum(cross$cross_modal_frozen_label=="CROSS_MODAL_BROAD_CORROBORATION_SAME_COHORT")
  cross_conf <- sum(cross$cross_modal_frozen_label=="CROSS_MODAL_SIGNIFICANT_DIRECTION_CONFLICT")

  writeLines(c(
    "R3 STEP4F V1.1 — PRE-INDEPENDENT-AUDIT RESULT COUNTS",
    paste0("RUN_ID=",RUN_ID),
    "STATUS=PRELIMINARY_UNTIL_CHATGPT_INDEPENDENT_AUDIT",
    "",
    paste0("registry_rows=",nrow(result)),
    paste0("assessable_rows=",sum(result$assessable)),
    paste0("unassessable_rows=",sum(!result$assessable)),
    paste0("mroast_executed_rows=",sum(result$execution_status=="MROAST_EXECUTED")),
    "",
    "SNRNA_PRIMARY_BROAD_CLASS_COUNTS:",
    paste(names(sn_class_counts),as.integer(sn_class_counts),sep="="),
    "",
    "XENIUM_PRIMARY_BROAD_CLASS_COUNTS:",
    paste(names(xe_class_counts),as.integer(xe_class_counts),sep="="),
    "",
    paste0("cross_modal_same_cohort_corroboration_rows=",cross_count),
    paste0("cross_modal_significant_direction_conflict_rows=",cross_conf),
    "",
    "NO SCIENTIFIC INTERPRETATION IS FINAL BEFORE INDEPENDENT AUDIT."
  ),P_SUMMARY,useBytes=TRUE)

  writeLines(capture.output(sessionInfo()),P_SESSION,useBytes=TRUE)

  PASS("RESULT_WRITEBACK","840-row result + 84 snRNA primary + 60 Xenium primary + 60 cross-modal outputs written")
  final_state <<- "PASS_STEP4F_V1_1_DETERMINISTIC_LOCALIZATION_EXECUTION_READY_FOR_INDEPENDENT_AUDIT"
  PASS("FINAL_GATE",final_state)
}

rc <- 0L
tryCatch(
  main(),
  error=function(e) {
    logline("ERROR/HOLD: ",conditionMessage(e))
    if(!grepl("^HOLD:",conditionMessage(e))) add_audit("UNEXPECTED_RUNTIME_ERROR","FAIL",conditionMessage(e))
    rc <<- 2L
  }
)

finalize()
logline("FINAL STATE: ",final_state)
logline("RUN DIR: ",RUNDIR)
logline("STAGING DIR: ",STAGING)
quit(save="no",status=rc)
