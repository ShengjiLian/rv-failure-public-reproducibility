# ---- RV PUBLIC PRIMARY DAG GATE9J REWRITE V1.0 ----
# source_id=C0347
# rewrite_scope=TIMESTAMP_ONLY
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
# Gate9K V1.26 overlay: current Step1 status/audit semantic binding only.
# Historical whole-file SHA for run-bearing Step1 STATUS/AUDIT is replaced by
# exact current-run status semantics + exact 41-check Step1 audit identity.
# Stable method contract/mapping/design + all scientific source authorities
# remain historical exact-SHA. Scientific/statistical semantics unchanged.
# ==============================================================================
# RV Project — R4A Step2
# GSE249696 BASELINE CTEPH SEVERITY — DETERMINISTIC EXECUTION
#
# FIRST OUTCOME-BEARING R4A GATE.
# Executes ONLY the methods frozen in accepted R4A Step1 (RUN_ID 20260911_001948).
# No target/pathway discovery. No pairwise inferential testing. No retuning.
# Biological replicate = patient; universe = 71 baseline RV-free-wall patients.
# ==============================================================================

options(stringsAsFactors=FALSE, warn=1)
args <- commandArgs(trailingOnly=TRUE)
STAMP <- if(length(args)>=1 && nzchar(args[1])) args[1] else format(Sys.time(),"%Y%m%d_%H%M%S")

ROOT <- normalizePath(getwd(),winslash="/",mustWork=TRUE)
if(!identical(ROOT,RV_PROJECT_ROOT)) stop("Expected working directory D:/RV_project",call.=FALSE)

OUT <- file.path(ROOT,"results","R4A_CTEPH_SEVERITY_EXECUTION",STAMP)
dir.create(OUT,recursive=TRUE,showWarnings=FALSE)

STEP1 <- rv_resolve_stage_run(file.path(ROOT, "results", "R4A_CTEPH_SEVERITY_METHOD_CONTRACT"))
S1_STATUS   <- file.path(STEP1,"R4A_STEP1_STATUS.csv")
S1_CONTRACT <- file.path(STEP1,"R4A_STEP1_METHOD_CONTRACT.csv")
S1_PROGMAP  <- file.path(STEP1,"R4A_STEP1_PROGRAM_MAPPING_AUDIT.csv")
S1_GENEMAP  <- file.path(STEP1,"R4A_STEP1_PRIMARY25_MAPPING_AUDIT.csv")
S1_DESIGN   <- file.path(STEP1,"R4A_STEP1_DESIGN_BALANCE.csv")
S1_AUDIT    <- file.path(STEP1,"R4A_STEP1_METHOD_CONTRACT_AUDIT.csv")

STEP0_TARGETS <- rv_stage_file(
  file.path(ROOT,"results","R4A_CTEPH_SEVERITY_PREFLIGHT_V1_2"),
  "R4A_STEP0_TARGET_IDENTITY.csv"
)
MAT    <- file.path(ROOT,"data","processed","GSE249696","GSE249696_ext395_rnaseq.txt.gz")
SAMPLE <- file.path(ROOT,"results","R3_GSE249696","R3_GSE249696_sample_manifest.csv")
GMT    <- file.path(ROOT,"data","authority","MSigDB","h.all.v2026.1.Hs.symbols.gmt")

EXPECTED_SHA <- c(
  S1_CONTRACT   ="0f493c460c809a12fd8ed74ea0c4e95fb252b99ce6051f6ff3a9b0107ef79ed7",
  S1_PROGMAP    ="25c33b70b61ff8dea99c2c0d6791c38fc938c021a180f1f83b246b310e0b46fb",
  S1_GENEMAP    ="cd2361c3acfa47898d2d0b246d04589fcba4909c1f11e86a26470da9e60919df",
  S1_DESIGN     ="c2b2636f64e9365db3c498ff260675751eab599cae4bf1a22e396d8b5f02f57c",
  STEP0_TARGETS ="feede6c7b6ad2403795ff11a92143aad1de42131a900b1792b85300d67779872",
  MAT           ="2ac6465ed35a45a8b3b56c30df7e6a0b3dc9469bddd340ad36d92a0eae09a5f2",
  SAMPLE        ="27225258bc196313b527a3c5cdf1daa8356e0ffe0f6fe1091e214ce5fbea27d0",
  GMT           ="eecaf6dad908334ae885406ec72bdc0646d8917588ed7c219fac92fc5363f596"
)

if(!requireNamespace("digest",quietly=TRUE)) stop("R package 'digest' required",call.=FALSE)
sha256 <- function(p) digest::digest(file=p,algo="sha256",serialize=FALSE)

awrite <- function(x,p) {
  t <- paste0(p,".tmp_",Sys.getpid())
  write.csv(x,t,row.names=FALSE,na="",quote=TRUE)
  if(file.exists(p)) unlink(p,force=TRUE)
  if(!file.rename(t,p)) {unlink(t); stop("Atomic CSV write failed: ",p,call.=FALSE)}
}

AUD <- list()
check <- function(id,requirement,ok,observed="",critical=TRUE,notes="") {
  AUD[[length(AUD)+1L]] <<- data.frame(
    guard_id=as.character(id), requirement=as.character(requirement),
    observed=as.character(observed), status=if(isTRUE(ok)) "PASS" else "FAIL",
    critical=if(isTRUE(critical)) "YES" else "NO", notes=as.character(notes),
    stringsAsFactors=FALSE
  )
}

P <- list(S1_STATUS=S1_STATUS,S1_CONTRACT=S1_CONTRACT,S1_PROGMAP=S1_PROGMAP,
          S1_GENEMAP=S1_GENEMAP,S1_DESIGN=S1_DESIGN,S1_AUDIT=S1_AUDIT,
          STEP0_TARGETS=STEP0_TARGETS,MAT=MAT,SAMPLE=SAMPLE,GMT=GMT)

for(nm in names(P)) check(paste0("FILE_",nm),paste0(nm," exists"),file.exists(P[[nm]]),P[[nm]])

if(any(!vapply(P,file.exists,logical(1)))) {
  awrite(do.call(rbind,AUD),file.path(OUT,"R4A_STEP2_EXECUTION_AUDIT.csv"))
  awrite(data.frame(final_state="HOLD_R4A_STEP2_PREEXECUTION",run_id=STAMP,
                    hard_failures=1,outcome_execution_completed="NO",
                    stringsAsFactors=FALSE),
         file.path(OUT,"R4A_STEP2_STATUS.csv"))
  quit(save="no",status=81,runLast=FALSE)
}

for(nm in names(EXPECTED_SHA)) {
  got <- sha256(P[[nm]])
  check(paste0("SHA_",nm),paste0(nm," exact frozen SHA256"),
        identical(tolower(got),tolower(EXPECTED_SHA[[nm]])),got)
}

s1 <- read.csv(S1_STATUS,stringsAsFactors=FALSE,check.names=FALSE)

# Gate9K V1.26 current-run portability repair. Step1 STATUS and AUDIT are
# generated afresh by C0346 and legitimately carry the current RUN_ID/path
# context. Bind them semantically and structurally, fail-closed.
step1_run_id <- basename(STEP1)
step1_status_cols <- c(
  "final_state","run_id","hard_failures","severity_outcome_testing_executed",
  "program_scores_calculated","gene_severity_tests_executed","new_discovery_executed","next_stage"
)
step1_status_ok <- nrow(s1)==1L &&
  all(step1_status_cols %in% names(s1)) &&
  identical(as.character(s1$final_state[1]),"PASS_R4A_STEP1_METHOD_CONTRACT_READY_FOR_INDEPENDENT_AUDIT") &&
  identical(as.character(s1$run_id[1]),step1_run_id) &&
  identical(as.integer(s1$hard_failures[1]),0L) &&
  identical(as.character(s1$severity_outcome_testing_executed[1]),"NO") &&
  identical(as.character(s1$program_scores_calculated[1]),"NO") &&
  identical(as.character(s1$gene_severity_tests_executed[1]),"NO") &&
  identical(as.character(s1$new_discovery_executed[1]),"NO") &&
  identical(as.character(s1$next_stage[1]),"CHATGPT_INDEPENDENT_AUDIT_THEN_R4A_STEP2_DETERMINISTIC_SEVERITY_EXECUTION")
check("STEP1_CURRENT_STATUS_BINDING",
      "Current C0346 Step1 status is exact PASS and bound to resolved current RUN_ID",
      step1_status_ok,
      if(nrow(s1)) paste(s1$run_id[1],s1$final_state[1],s1$hard_failures[1],sep=" | ") else "NO_ROW")

s1a <- read.csv(S1_AUDIT,stringsAsFactors=FALSE,check.names=FALSE)
expected_step1_checks <- c(
  "FILE_STEP0_STATUS","FILE_STEP0_AUDIT","FILE_STEP0_BOUNDARY","FILE_STEP0_TARGETS",
  "FILE_MAT","FILE_SAMPLE","FILE_GMT","FILE_A05","FILE_A20",
  "SHA_STEP0_BOUNDARY","SHA_STEP0_TARGETS","SHA_MAT","SHA_SAMPLE","SHA_GMT","SHA_A05","SHA_A20",
  "STEP0_CURRENT_STATUS_BINDING","STEP0_CURRENT_AUDIT_EXACT","STEP0_PASS","STEP0_NO_OUTCOME",
  "BL71","BL71_UNIQUE","RVFW71","RISK_ORDER_COUNTS","SEX_COMPLETE","SEX_LEVELS",
  "MATRIX_META","MATRIX_ROWS","MATRIX_COLS","BL_COLUMNS","GMT50","PROG16","GENE25","PROG16_GMT",
  "TARGET_SYMBOL_UNIQUENESS","PROGRAM_COVERAGE80","PROGRAM_USABLE10","PRIMARY25_MAPPING","PRIMARY25_VARIANCE",
  "PROGRAM_DIRECTION","GENE_DIRECTION"
)
step1_audit_ok <- nrow(s1a)==length(expected_step1_checks) &&
  all(c("guard_id","status","critical") %in% names(s1a)) &&
  identical(as.character(s1a$guard_id),expected_step1_checks) &&
  identical(as.character(s1a$status),rep("PASS",length(expected_step1_checks))) &&
  identical(as.character(s1a$critical),rep("YES",length(expected_step1_checks)))
check("STEP1_CURRENT_AUDIT_EXACT",
      "Current C0346 Step1 audit has exact 41-check sequence, criticality and all PASS",
      step1_audit_ok,
      paste0("rows=",nrow(s1a),"; pass=",sum(s1a$status=="PASS",na.rm=TRUE),
             "; hard_fail=",sum(s1a$status=="FAIL" & s1a$critical=="YES",na.rm=TRUE)))
check("STEP1_PASS","Accepted Step1 is PASS with zero hard failures",
      nrow(s1)==1L &&
      identical(s1$final_state[1],"PASS_R4A_STEP1_METHOD_CONTRACT_READY_FOR_INDEPENDENT_AUDIT") &&
      as.integer(s1$hard_failures[1])==0L,
      if(nrow(s1)) paste(s1$final_state[1],s1$hard_failures[1],sep=" | ") else "NO_ROW")
check("STEP1_NO_OUTCOME","Step1 had no outcome-bearing analysis",
      nrow(s1)==1L &&
      identical(s1$severity_outcome_testing_executed[1],"NO") &&
      identical(s1$program_scores_calculated[1],"NO") &&
      identical(s1$gene_severity_tests_executed[1],"NO") &&
      identical(s1$new_discovery_executed[1],"NO"),
      if(nrow(s1)) paste(s1$severity_outcome_testing_executed[1],
                         s1$program_scores_calculated[1],
                         s1$gene_severity_tests_executed[1],
                         s1$new_discovery_executed[1],sep=" | ") else "NO_ROW")

ct <- read.csv(S1_CONTRACT,stringsAsFactors=FALSE,check.names=FALSE)
cv <- setNames(ct$value,ct$item)
must_contract <- c(
  biological_replicate="PATIENT",
  analysis_universe="71_BASELINE_PATIENTS",
  tissue="RV_FREE_WALL",
  risk_order="MODERATE<INTERMEDIATE<SEVERE",
  risk_numeric_coding="MODERATE=0;INTERMEDIATE=1;SEVERE=2",
  expression_transform="LOG2_NORMALIZED_COUNT_PLUS_1",
  gene_standardization="GENEWISE_Z_ACROSS_ALL_71_BASELINE_PATIENTS_USING_SAMPLE_SD",
  raw_program_score="MEAN_OF_USABLE_MEMBER_GENE_Z_SCORES_PER_PATIENT",
  primary_program_test="SPEARMAN_CORRELATION_FAILURE_ORIENTED_SCORE_VS_RISK_ORDINAL",
  primary_program_FDR="BH_ACROSS_PADDED_16_PROGRAM_FAMILY",
  primary_program_family_size="16",
  primary_support_rule="BH_FDR_LT_0.05_AND_RHO_GT_0",
  sex_adjusted_sensitivity="OLS_FAILURE_ORIENTED_SCORE_TILDE_RISK_ORDINAL_PLUS_SEX",
  sex_adjusted_role="SENSITIVITY_ONLY_CANNOT_RESCUE_PRIMARY",
  nonmonotonic_sensitivity="KRUSKAL_WALLIS_FAILURE_ORIENTED_SCORE_ACROSS_3_RISK_GROUPS",
  primary25_test="SPEARMAN_CORRELATION_FAILURE_ORIENTED_GENE_Z_VS_RISK_ORDINAL_TWO_SIDED",
  primary25_FDR="BH_ACROSS_PADDED_25_GENE_FAMILY",
  primary25_family_size="25",
  posthoc_pairwise_testing="NO_INFERENTIAL_PAIRWISE_TESTS",
  new_pathway_discovery="NO",
  new_gene_discovery="NO",
  threshold_retuning_after_results="NO",
  primary_rescue_by_sensitivity="NO"
)
for(k in names(must_contract)) {
  check(paste0("CONTRACT_",k),paste0(k," frozen exact"),
        !is.null(cv[[k]]) && identical(as.character(cv[[k]]),as.character(must_contract[[k]])),
        if(!is.null(cv[[k]])) cv[[k]] else "MISSING")
}

pre_audit <- do.call(rbind,AUD)
hard_pre <- sum(pre_audit$status=="FAIL" & pre_audit$critical=="YES")
if(hard_pre>0L) {
  awrite(pre_audit,file.path(OUT,"R4A_STEP2_EXECUTION_AUDIT.csv"))
  awrite(data.frame(final_state="HOLD_R4A_STEP2_PREEXECUTION",run_id=STAMP,
                    hard_failures=hard_pre,outcome_execution_completed="NO",
                    program_primary_executed="NO",sensitivity_executed="NO",
                    primary25_secondary_executed="NO",stringsAsFactors=FALSE),
         file.path(OUT,"R4A_STEP2_STATUS.csv"))
  quit(save="no",status=82,runLast=FALSE)
}

# ==============================================================================
# OUTCOME-BEARING EXECUTION STARTS HERE.
# ==============================================================================
sm <- read.csv(SAMPLE,stringsAsFactors=FALSE,check.names=FALSE)
bl <- sm[sm$timepoint=="BL",,drop=FALSE]
risk_levels <- c("MODERATE","INTERMEDIATE","SEVERE")
bl$risk_group <- factor(bl$esc_risk_group,levels=risk_levels,ordered=TRUE)
bl$risk_numeric <- match(as.character(bl$risk_group),risk_levels)-1L
bl$sex <- factor(bl$sex,levels=c("Female","Male"))
bl <- bl[order(bl$patient_number),,drop=FALSE]

check("EXEC_BL71","Execution universe remains 71 unique baseline patients",
      nrow(bl)==71L && length(unique(bl$patient_id))==71L,nrow(bl))
check("EXEC_RISK","Execution risk counts remain 30/23/18",
      identical(as.integer(table(factor(bl$risk_group,levels=risk_levels))),c(30L,23L,18L)),
      paste(as.integer(table(factor(bl$risk_group,levels=risk_levels))),collapse="/"))
check("EXEC_SEX","Sex remains complete Female/Male",all(!is.na(bl$sex)),paste(table(bl$sex),collapse="/"))
check("EXEC_SITE","All execution samples are RV free wall",all(bl$site_class=="RV_FREE_WALL"),
      sum(bl$site_class=="RV_FREE_WALL"))

mat <- read.delim(gzfile(MAT,"rt"),stringsAsFactors=FALSE,check.names=FALSE,
                  quote="",comment.char="")
symbols <- trimws(as.character(mat[["Ensembl gene"]]))
bl_cols <- bl$matrix_column
check("EXEC_COLUMNS","All 71 matrix columns are present uniquely",
      length(unique(bl_cols))==71L && all(bl_cols %in% names(mat)),
      paste0(sum(bl_cols %in% names(mat)),"/71"))

exec_guard <- do.call(rbind,AUD)
hard_exec_guard <- sum(exec_guard$status=="FAIL" & exec_guard$critical=="YES")
if(hard_exec_guard>0L) {
  awrite(exec_guard,file.path(OUT,"R4A_STEP2_EXECUTION_AUDIT.csv"))
  awrite(data.frame(final_state="HOLD_R4A_STEP2_EXECUTION_GUARD",run_id=STAMP,
                    hard_failures=hard_exec_guard,outcome_execution_completed="NO",
                    stringsAsFactors=FALSE),
         file.path(OUT,"R4A_STEP2_STATUS.csv"))
  quit(save="no",status=83,runLast=FALSE)
}

X <- as.matrix(mat[,bl_cols,drop=FALSE]); storage.mode(X) <- "double"
logX <- log2(X+1)
row_mu <- rowMeans(logX)
row_sd <- apply(logX,1,sd)
eligible <- apply(logX,1,function(v) all(is.finite(v))) & is.finite(row_sd) & row_sd>0
Z <- (logX-row_mu)/row_sd

gl <- readLines(GMT,warn=FALSE)
parts <- strsplit(gl,"\t",fixed=TRUE)
gmt_names <- vapply(parts,`[`,character(1),1L)
gmt_genes <- lapply(parts,function(x) unique(if(length(x)>=3L) x[3:length(x)] else character()))
names(gmt_genes) <- gmt_names

targets <- read.csv(STEP0_TARGETS,stringsAsFactors=FALSE,check.names=FALSE)
progs <- targets[targets$target_family=="STABLE_PROGRAM_16",,drop=FALSE]
genes <- targets[targets$target_family=="PRIMARY25_GENE",,drop=FALSE]
pmap <- read.csv(S1_PROGMAP,stringsAsFactors=FALSE,check.names=FALSE)

program_scores <- list(); program_primary <- list(); program_sens <- list()
program_kw <- list(); program_group <- list()

for(i in seq_len(nrow(progs))) {
  pid <- progs$target_id[i]; role <- progs$frozen_role[i]; fdir <- progs$failure_direction[i]
  members <- gmt_genes[[pid]]
  idx <- match(members,symbols)
  mapped <- !is.na(idx); idx2 <- idx[mapped]; members2 <- members[mapped]
  usable <- eligible[idx2]; idxu <- idx2[usable]
  assess <- nrow(pmap[pmap$pathway==pid & pmap$assessable,])==1L &&
            length(idxu)>=10L && length(idx2)/length(members)>=0.80

  if(assess) {
    raw <- colMeans(Z[idxu,,drop=FALSE])
    mult <- if(fdir=="UP_IN_FAILURE") 1 else if(fdir=="DOWN_IN_FAILURE") -1 else NA_real_
    oriented <- raw*mult
    ctst <- suppressWarnings(cor.test(oriented,bl$risk_numeric,method="spearman",
                                      exact=FALSE,alternative="two.sided"))
    rho <- unname(ctst$estimate); p_primary <- ctst$p.value

    fit <- lm(oriented ~ risk_numeric + sex,data=bl)
    co <- summary(fit)$coefficients
    beta <- co["risk_numeric","Estimate"]; se <- co["risk_numeric","Std. Error"]
    tval <- co["risk_numeric","t value"]; p_sex <- co["risk_numeric","Pr(>|t|)"]

    kw <- kruskal.test(oriented ~ risk_group,data=bl)
    p_kw <- kw$p.value; kw_stat <- unname(kw$statistic)

    for(j in seq_len(nrow(bl))) {
      program_scores[[length(program_scores)+1L]] <- data.frame(
        patient_id=bl$patient_id[j],patient_number=bl$patient_number[j],
        risk_group=as.character(bl$risk_group[j]),risk_numeric=bl$risk_numeric[j],
        sex=as.character(bl$sex[j]),pathway=pid,frozen_role=role,
        failure_direction=fdir,usable_gene_n=length(idxu),
        raw_program_score=raw[j],failure_oriented_program_score=oriented[j],
        stringsAsFactors=FALSE)
    }
    for(g in risk_levels) {
      v <- oriented[as.character(bl$risk_group)==g]
      program_group[[length(program_group)+1L]] <- data.frame(
        pathway=pid,frozen_role=role,risk_group=g,n=length(v),
        mean=mean(v),sd=sd(v),median=median(v),
        q25=unname(quantile(v,0.25,type=7)),q75=unname(quantile(v,0.75,type=7)),
        stringsAsFactors=FALSE)
    }
  } else {
    rho <- NA_real_; p_primary <- 1; beta <- NA_real_; se <- NA_real_
    tval <- NA_real_; p_sex <- 1; kw_stat <- NA_real_; p_kw <- 1
  }

  program_primary[[i]] <- data.frame(
    pathway=pid,frozen_role=role,failure_direction=fdir,assessable=assess,
    n=if(assess) nrow(bl) else 0L,usable_gene_n=if(assess) length(idxu) else 0L,
    spearman_rho=rho,p_value=p_primary,stringsAsFactors=FALSE)
  program_sens[[i]] <- data.frame(
    pathway=pid,frozen_role=role,assessable=assess,beta_risk=beta,se_risk=se,
    t_risk=tval,p_value=p_sex,stringsAsFactors=FALSE)
  program_kw[[i]] <- data.frame(
    pathway=pid,frozen_role=role,assessable=assess,kruskal_wallis_chisq=kw_stat,
    df=2L,p_value=p_kw,stringsAsFactors=FALSE)
}

program_primary <- do.call(rbind,program_primary)
program_primary$q_BH <- p.adjust(program_primary$p_value,method="BH",n=16L)
program_primary$severity_class <- ifelse(
  !program_primary$assessable,"UNASSESSABLE_PADDED",
  ifelse(program_primary$q_BH<0.05 & program_primary$spearman_rho>0,
         "SEVERITY_CONCORDANT_SUPPORT",
  ifelse(program_primary$q_BH<0.05 & program_primary$spearman_rho<0,
         "SEVERITY_OPPOSITE_ASSOCIATION","NO_FDR_SUPPORTED_ORDINAL_ASSOCIATION")))

program_sens <- do.call(rbind,program_sens)
program_sens$q_BH <- p.adjust(program_sens$p_value,method="BH",n=16L)
program_sens$direction <- ifelse(is.na(program_sens$beta_risk),"UNASSESSABLE",
                                ifelse(program_sens$beta_risk>0,"FAILURE_ORIENTED_POSITIVE",
                                ifelse(program_sens$beta_risk<0,"FAILURE_ORIENTED_NEGATIVE","ZERO")))
program_sens$sensitivity_role <- "SENSITIVITY_ONLY_CANNOT_RESCUE_PRIMARY"

program_kw <- do.call(rbind,program_kw)
program_kw$q_BH <- p.adjust(program_kw$p_value,method="BH",n=16L)
program_kw$sensitivity_role <- "SENSITIVITY_ONLY_NONMONOTONIC_GROUP_DIFFERENCE"

program_scores <- do.call(rbind,program_scores)
program_group <- do.call(rbind,program_group)

gene_scores <- list(); gene_res <- list()
for(i in seq_len(nrow(genes))) {
  g <- genes$target_id[i]; fdir <- genes$failure_direction[i]; idx <- which(symbols==g)
  assess <- length(idx)==1L && eligible[idx]
  if(assess) {
    z <- as.numeric(Z[idx,])
    mult <- if(fdir=="UP_RVF_vs_pRV") 1 else if(fdir=="DOWN_RVF_vs_pRV") -1 else NA_real_
    oriented <- z*mult
    ctst <- suppressWarnings(cor.test(oriented,bl$risk_numeric,method="spearman",
                                      exact=FALSE,alternative="two.sided"))
    rho <- unname(ctst$estimate); p <- ctst$p.value
    for(j in seq_len(nrow(bl))) {
      gene_scores[[length(gene_scores)+1L]] <- data.frame(
        patient_id=bl$patient_id[j],patient_number=bl$patient_number[j],
        risk_group=as.character(bl$risk_group[j]),risk_numeric=bl$risk_numeric[j],
        sex=as.character(bl$sex[j]),gene=g,failure_direction=fdir,
        gene_z=z[j],failure_oriented_gene_z=oriented[j],stringsAsFactors=FALSE)
    }
  } else {rho <- NA_real_; p <- 1}
  gene_res[[i]] <- data.frame(gene=g,failure_direction=fdir,assessable=assess,
                              n=if(assess) nrow(bl) else 0L,
                              spearman_rho=rho,p_value=p,stringsAsFactors=FALSE)
}
gene_res <- do.call(rbind,gene_res)
gene_res$q_BH <- p.adjust(gene_res$p_value,method="BH",n=25L)
gene_res$severity_class <- ifelse(
  !gene_res$assessable,"UNASSESSABLE_PADDED",
  ifelse(gene_res$q_BH<0.05 & gene_res$spearman_rho>0,
         "SEVERITY_CONCORDANT_SUPPORT",
  ifelse(gene_res$q_BH<0.05 & gene_res$spearman_rho<0,
         "SEVERITY_OPPOSITE_ASSOCIATION","NO_FDR_SUPPORTED_ORDINAL_ASSOCIATION")))
gene_scores <- do.call(rbind,gene_scores)

program_summary <- as.data.frame.matrix(table(
  factor(program_primary$frozen_role,
         levels=c("PROGRAM_REVERSAL_SUPPORTED",
                  "PROGRAM_MALADAPTIVE_NONREVERSAL_WORSENING_SUPPORTED",
                  "PROGRAM_SITE_CONFLICT",
                  "PROGRAM_INDETERMINATE_NO_MAIN_SIGNAL")),
  factor(program_primary$severity_class,
         levels=c("SEVERITY_CONCORDANT_SUPPORT","SEVERITY_OPPOSITE_ASSOCIATION",
                  "NO_FDR_SUPPORTED_ORDINAL_ASSOCIATION","UNASSESSABLE_PADDED"))))
program_summary$frozen_role <- rownames(program_summary); rownames(program_summary) <- NULL

overall_summary <- data.frame(
  family=c("STABLE_PROGRAM_16","PRIMARY25_GENE"),family_size=c(16L,25L),
  assessable=c(sum(program_primary$assessable),sum(gene_res$assessable)),
  severity_concordant_FDR_support=c(
    sum(program_primary$severity_class=="SEVERITY_CONCORDANT_SUPPORT"),
    sum(gene_res$severity_class=="SEVERITY_CONCORDANT_SUPPORT")),
  severity_opposite_FDR_association=c(
    sum(program_primary$severity_class=="SEVERITY_OPPOSITE_ASSOCIATION"),
    sum(gene_res$severity_class=="SEVERITY_OPPOSITE_ASSOCIATION")),
  FDR_nonsignificant=c(
    sum(program_primary$severity_class=="NO_FDR_SUPPORTED_ORDINAL_ASSOCIATION"),
    sum(gene_res$severity_class=="NO_FDR_SUPPORTED_ORDINAL_ASSOCIATION")),
  stringsAsFactors=FALSE)

awrite(program_primary,file.path(OUT,"R4A_STEP2_PROGRAM_PRIMARY_RESULTS.csv"))
awrite(program_sens,file.path(OUT,"R4A_STEP2_PROGRAM_SEX_ADJUSTED_SENSITIVITY.csv"))
awrite(program_kw,file.path(OUT,"R4A_STEP2_PROGRAM_KRUSKAL_SENSITIVITY.csv"))
awrite(program_scores,file.path(OUT,"R4A_STEP2_PROGRAM_PATIENT_SCORES.csv"))
awrite(program_group,file.path(OUT,"R4A_STEP2_PROGRAM_GROUP_SUMMARY.csv"))
awrite(program_summary,file.path(OUT,"R4A_STEP2_PROGRAM_ROLE_BY_SEVERITY_CLASS.csv"))
awrite(gene_res,file.path(OUT,"R4A_STEP2_PRIMARY25_SECONDARY_RESULTS.csv"))
awrite(gene_scores,file.path(OUT,"R4A_STEP2_PRIMARY25_PATIENT_SCORES.csv"))
awrite(overall_summary,file.path(OUT,"R4A_STEP2_FAMILY_SUMMARY.csv"))

short_name <- function(x) sub("^HALLMARK_","",x)

png(file.path(OUT,"R4A_STEP2_FigA_program_severity_rho.png"),width=1800,height=1400,res=180)
op <- par(mar=c(5,12,3,2)); o <- order(program_primary$spearman_rho,na.last=TRUE); y <- seq_along(o)
plot(program_primary$spearman_rho[o],y,pch=19,
     xlim=range(c(-0.6,0.6,program_primary$spearman_rho),na.rm=TRUE),
     yaxt="n",ylab="",xlab="Spearman rho: failure-oriented program score vs ordinal CTEPH severity",
     main="R4A baseline CTEPH severity validation — frozen 16 programs")
axis(2,at=y,labels=short_name(program_primary$pathway[o]),las=2,cex.axis=0.75); abline(v=0,lty=2)
sig <- which(program_primary$q_BH[o]<0.05)
if(length(sig)) points(program_primary$spearman_rho[o][sig],y[sig],pch=8,cex=1.2)
mtext("* = BH-FDR < 0.05; positive rho = more failure-like with increasing severity",
      side=1,line=3.2,cex=0.72)
par(op); dev.off()

gm <- reshape(program_group[,c("pathway","risk_group","mean")],
              idvar="pathway",timevar="risk_group",direction="wide")
row.names(gm) <- gm$pathway
M <- as.matrix(gm[,paste0("mean.",risk_levels),drop=FALSE]); colnames(M) <- risk_levels
png(file.path(OUT,"R4A_STEP2_FigB_program_group_mean_heatmap.png"),width=1200,height=1500,res=180)
op <- par(mar=c(7,12,3,5)); lim <- max(abs(M),na.rm=TRUE); if(!is.finite(lim)||lim==0) lim <- 1
pal <- colorRampPalette(c("navy","white","firebrick3"))(101)
image(x=seq_len(ncol(M)),y=seq_len(nrow(M)),z=t(M[nrow(M):1,,drop=FALSE]),
      col=pal,zlim=c(-lim,lim),axes=FALSE,xlab="",ylab="",
      main="Mean failure-oriented program score by baseline CTEPH severity")
axis(1,at=seq_len(ncol(M)),labels=colnames(M),las=2)
axis(2,at=seq_len(nrow(M)),labels=rev(short_name(row.names(M))),las=2,cex.axis=0.75)
mtext("Descriptive means; inferential authority = frozen Spearman/BH test",side=1,line=5.2,cex=0.72)
par(op); dev.off()

core_roles <- c("PROGRAM_REVERSAL_SUPPORTED","PROGRAM_MALADAPTIVE_NONREVERSAL_WORSENING_SUPPORTED")
core7 <- progs$target_id[progs$frozen_role %in% core_roles]
png(file.path(OUT,"R4A_STEP2_FigC_core7_patient_distributions.png"),width=2100,height=1800,res=180)
op <- par(mfrow=c(3,3),mar=c(5,4,3,1)); set.seed(20260911)
for(pid in core7) {
  d <- program_scores[program_scores$pathway==pid,,drop=FALSE]
  boxplot(failure_oriented_program_score ~ factor(risk_group,levels=risk_levels),
          data=d,outline=FALSE,xlab="",ylab="Failure-oriented score",
          main=short_name(pid),las=2,cex.axis=0.75,cex.main=0.85)
  stripchart(failure_oriented_program_score ~ factor(risk_group,levels=risk_levels),
             data=d,vertical=TRUE,method="jitter",add=TRUE,pch=16,cex=0.55)
}
plot.new(); text(0.5,0.62,"Core 7 frozen programs",cex=1.1)
text(0.5,0.48,"Patient = biological replicate",cex=0.9)
text(0.5,0.36,"No pairwise inferential tests",cex=0.9)
par(op); dev.off()

png(file.path(OUT,"R4A_STEP2_FigD_Primary25_severity_rho.png"),width=1700,height=1500,res=180)
op <- par(mar=c(5,8,3,2)); o <- order(gene_res$spearman_rho,na.last=TRUE); y <- seq_along(o)
plot(gene_res$spearman_rho[o],y,pch=19,
     xlim=range(c(-0.6,0.6,gene_res$spearman_rho),na.rm=TRUE),
     yaxt="n",ylab="",xlab="Spearman rho: failure-oriented gene z-score vs ordinal CTEPH severity",
     main="R4A Primary25 — secondary severity validation")
axis(2,at=y,labels=gene_res$gene[o],las=2,cex.axis=0.8); abline(v=0,lty=2)
sig <- which(gene_res$q_BH[o]<0.05)
if(length(sig)) points(gene_res$spearman_rho[o][sig],y[sig],pch=8,cex=1.2)
mtext("* = BH-FDR < 0.05; secondary family, n=25",side=1,line=3.2,cex=0.72)
par(op); dev.off()

check("OUT_PROGRAM16","Program primary result has exactly 16 rows",nrow(program_primary)==16L,nrow(program_primary))
check("OUT_PROGRAM16_ASSESS","All 16 frozen programs assessable",sum(program_primary$assessable)==16L,sum(program_primary$assessable))
check("OUT_PROGRAM_SCORES","Patient program-score table has 71x16 rows",nrow(program_scores)==71L*16L,nrow(program_scores))
check("OUT_GENE25","Primary25 result has exactly 25 rows",nrow(gene_res)==25L,nrow(gene_res))
check("OUT_GENE25_ASSESS","All 25 frozen genes assessable",sum(gene_res$assessable)==25L,sum(gene_res$assessable))
check("OUT_GENE_SCORES","Patient gene-score table has 71x25 rows",nrow(gene_scores)==71L*25L,nrow(gene_scores))
check("OUT_NO_PAIRWISE","No inferential pairwise output generated",TRUE,"YES")
check("OUT_NO_DISCOVERY","No new program/gene discovery generated",TRUE,"YES")

audit <- do.call(rbind,AUD)
hard_fail <- sum(audit$status=="FAIL" & audit$critical=="YES")
awrite(audit,file.path(OUT,"R4A_STEP2_EXECUTION_AUDIT.csv"))

inp <- do.call(rbind,lapply(names(P),function(nm) data.frame(
  input_id=nm,path=P[[nm]],bytes=file.info(P[[nm]])$size,sha256=sha256(P[[nm]]),
  stringsAsFactors=FALSE)))
awrite(inp,file.path(OUT,"R4A_STEP2_INPUT_SHA256.csv"))

state <- if(hard_fail==0L) "PASS_R4A_STEP2_DETERMINISTIC_EXECUTION_READY_FOR_INDEPENDENT_AUDIT" else "HOLD_R4A_STEP2_POSTEXECUTION_GUARD"
awrite(data.frame(
  final_state=state,run_id=STAMP,hard_failures=hard_fail,outcome_execution_completed="YES",
  program_primary_executed="YES",sex_adjusted_sensitivity_executed="YES",
  kruskal_sensitivity_executed="YES",primary25_secondary_executed="YES",
  new_discovery_executed="NO",pairwise_inferential_tests_executed="NO",
  threshold_retuning_executed="NO",primary_program_FDR_family_size=16L,
  primary25_secondary_FDR_family_size=25L,
  next_stage=if(hard_fail==0L) "CHATGPT_INDEPENDENT_AUDIT_THEN_R4A_STEP3_POSTGEN_VALIDATION_AND_CLOSURE" else "STOP_AND_REPAIR_WITHOUT_RETUNING_SCIENCE",
  stringsAsFactors=FALSE),file.path(OUT,"R4A_STEP2_STATUS.csv"))

cat("FINAL_STATE:",state,"\n")
cat("RUN_ID:",STAMP,"\n")
cat("HARD_FAILURES:",hard_fail,"\n")
cat("PROGRAM_FDR_SUPPORT:",sum(program_primary$severity_class=="SEVERITY_CONCORDANT_SUPPORT"),"/16\n")
cat("PROGRAM_FDR_OPPOSITE:",sum(program_primary$severity_class=="SEVERITY_OPPOSITE_ASSOCIATION"),"/16\n")
cat("PRIMARY25_FDR_SUPPORT:",sum(gene_res$severity_class=="SEVERITY_CONCORDANT_SUPPORT"),"/25\n")
quit(save="no",status=if(hard_fail==0L) 0 else 84,runLast=FALSE)
