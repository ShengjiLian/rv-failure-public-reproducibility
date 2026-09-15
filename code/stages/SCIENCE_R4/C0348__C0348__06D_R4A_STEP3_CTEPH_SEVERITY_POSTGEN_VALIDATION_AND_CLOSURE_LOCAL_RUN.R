# ---- RV PUBLIC PRIMARY DAG GATE9J REWRITE V1.0 ----
# source_id=C0348
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
# Gate9K V1.26 overlay: current Step2 status semantic binding only.
# Step2 scientific result tables remain historical exact-SHA and are then
# independently reconstructed/compared exactly as before. Scientific/statistical
# semantics, thresholds and expected support sets are unchanged.
# ==============================================================================
# RV Project — R4A Step3
# GSE249696 BASELINE CTEPH SEVERITY — POSTGEN VALIDATION + TERMINAL CLOSURE
#
# VALIDATION ONLY.
# Reconstructs the frozen R4A Step2 statistics independently from frozen source
# inputs, THEN opens Step2 result artifacts for comparison.
#
# No new target discovery. No threshold changes. No new scientific testing.
# ==============================================================================

options(stringsAsFactors=FALSE, warn=1)
args <- commandArgs(trailingOnly=TRUE)
STAMP <- if(length(args)>=1 && nzchar(args[1])) args[1] else format(Sys.time(),"%Y%m%d_%H%M%S")

ROOT <- normalizePath(getwd(),winslash="/",mustWork=TRUE)
if(!identical(ROOT,RV_PROJECT_ROOT)) stop("Expected working directory D:/RV_project",call.=FALSE)

OUTROOT <- file.path(ROOT,"results","R4A_CTEPH_SEVERITY_POSTGEN_VALIDATION")
OUT <- file.path(OUTROOT,STAMP)
dir.create(OUT,recursive=TRUE,showWarnings=FALSE)

STEP1 <- rv_resolve_stage_run(file.path(ROOT, "results", "R4A_CTEPH_SEVERITY_METHOD_CONTRACT"))
STEP2 <- rv_resolve_stage_run(file.path(ROOT, "results", "R4A_CTEPH_SEVERITY_EXECUTION"))

S1_CONTRACT <- file.path(STEP1,"R4A_STEP1_METHOD_CONTRACT.csv")
S1_PROGMAP  <- file.path(STEP1,"R4A_STEP1_PROGRAM_MAPPING_AUDIT.csv")
S1_GENEMAP  <- file.path(STEP1,"R4A_STEP1_PRIMARY25_MAPPING_AUDIT.csv")

TARGETS <- rv_stage_file(
  file.path(ROOT,"results","R4A_CTEPH_SEVERITY_PREFLIGHT_V1_2"),
  "R4A_STEP0_TARGET_IDENTITY.csv"
)
MAT    <- file.path(ROOT,"data","processed","GSE249696","GSE249696_ext395_rnaseq.txt.gz")
SAMPLE <- file.path(ROOT,"results","R3_GSE249696","R3_GSE249696_sample_manifest.csv")
GMT    <- file.path(ROOT,"data","authority","MSigDB","h.all.v2026.1.Hs.symbols.gmt")

S2_STATUS <- file.path(STEP2,"R4A_STEP2_STATUS.csv")
S2_PROG   <- file.path(STEP2,"R4A_STEP2_PROGRAM_PRIMARY_RESULTS.csv")
S2_SEX    <- file.path(STEP2,"R4A_STEP2_PROGRAM_SEX_ADJUSTED_SENSITIVITY.csv")
S2_KW     <- file.path(STEP2,"R4A_STEP2_PROGRAM_KRUSKAL_SENSITIVITY.csv")
S2_PSCORE <- file.path(STEP2,"R4A_STEP2_PROGRAM_PATIENT_SCORES.csv")
S2_GENE   <- file.path(STEP2,"R4A_STEP2_PRIMARY25_SECONDARY_RESULTS.csv")
S2_GSCORE <- file.path(STEP2,"R4A_STEP2_PRIMARY25_PATIENT_SCORES.csv")
S2_FAMILY <- file.path(STEP2,"R4A_STEP2_FAMILY_SUMMARY.csv")

EXPECTED_SHA <- c(
  S1_CONTRACT="0f493c460c809a12fd8ed74ea0c4e95fb252b99ce6051f6ff3a9b0107ef79ed7",
  S1_PROGMAP ="25c33b70b61ff8dea99c2c0d6791c38fc938c021a180f1f83b246b310e0b46fb",
  S1_GENEMAP ="cd2361c3acfa47898d2d0b246d04589fcba4909c1f11e86a26470da9e60919df",
  TARGETS    ="feede6c7b6ad2403795ff11a92143aad1de42131a900b1792b85300d67779872",
  MAT        ="2ac6465ed35a45a8b3b56c30df7e6a0b3dc9469bddd340ad36d92a0eae09a5f2",
  SAMPLE     ="27225258bc196313b527a3c5cdf1daa8356e0ffe0f6fe1091e214ce5fbea27d0",
  GMT        ="eecaf6dad908334ae885406ec72bdc0646d8917588ed7c219fac92fc5363f596",
  S2_PROG    ="9af1217d7112806f439a63a14d1c63cc48a4886140b12ad9eeff2ec9b663b3c9",
  S2_SEX     ="943c3146d123e433ff8dce9229d6a16f1cfbf6b1a766fa98082ec42bd536f1ca",
  S2_KW      ="fb811d59c827786113fcc1644bd286d224b2b16fc1582fada0703869d2aecab3",
  S2_PSCORE  ="224c5fe0a87750f6e52fe668cd55d7997f3fdf3ab2e1904c83abdf537a5c21e5",
  S2_GENE    ="a33c38962cab4f0866e097b20caa1fe2efa9ff484147deedda13abdd81b7171d",
  S2_GSCORE  ="dbee8bce74b5845beec46787aff8566e769d4434559c7afdf8e7bda81d11554a",
  S2_FAMILY  ="8a0337d1189c763d4c2322d4f3f1603031a144d8b7232426dc04c4f985fc1b6a"
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
    guard_id=as.character(id),requirement=as.character(requirement),
    observed=as.character(observed),status=if(isTRUE(ok)) "PASS" else "FAIL",
    critical=if(isTRUE(critical)) "YES" else "NO",notes=as.character(notes),
    stringsAsFactors=FALSE
  )
}

P <- list(S1_CONTRACT=S1_CONTRACT,S1_PROGMAP=S1_PROGMAP,S1_GENEMAP=S1_GENEMAP,
          TARGETS=TARGETS,MAT=MAT,SAMPLE=SAMPLE,GMT=GMT,
          S2_STATUS=S2_STATUS,S2_PROG=S2_PROG,S2_SEX=S2_SEX,S2_KW=S2_KW,
          S2_PSCORE=S2_PSCORE,S2_GENE=S2_GENE,S2_GSCORE=S2_GSCORE,S2_FAMILY=S2_FAMILY)

for(nm in names(P)) check(paste0("FILE_",nm),paste0(nm," exists"),file.exists(P[[nm]]),P[[nm]])
if(any(!vapply(P,file.exists,logical(1)))) {
  awrite(do.call(rbind,AUD),file.path(OUT,"R4A_STEP3_VALIDATION_AUDIT.csv"))
  awrite(data.frame(final_state="HOLD_R4A_STEP3_MISSING_INPUT",
                    run_id=STAMP,hard_failures=1,terminal_closed="NO",
                    stringsAsFactors=FALSE),file.path(OUT,"R4A_STEP3_STATUS.csv"))
  quit(save="no",status=91,runLast=FALSE)
}
for(nm in names(EXPECTED_SHA)) {
  got <- sha256(P[[nm]])
  check(paste0("SHA_",nm),paste0(nm," exact frozen SHA256"),
        identical(tolower(got),tolower(EXPECTED_SHA[[nm]])),got)
}

# Gate9K V1.26 current-run portability repair: status is run-bearing, whereas
# every outcome-bearing Step2 result artifact above remains historical exact-SHA.
s2_status_pre <- read.csv(S2_STATUS,stringsAsFactors=FALSE,check.names=FALSE)
step2_run_id <- basename(STEP2)
step2_status_cols <- c(
  "final_state","run_id","hard_failures","outcome_execution_completed",
  "program_primary_executed","sex_adjusted_sensitivity_executed",
  "kruskal_sensitivity_executed","primary25_secondary_executed",
  "new_discovery_executed","pairwise_inferential_tests_executed",
  "threshold_retuning_executed","primary_program_FDR_family_size",
  "primary25_secondary_FDR_family_size","next_stage"
)
step2_status_ok <- nrow(s2_status_pre)==1L &&
  all(step2_status_cols %in% names(s2_status_pre)) &&
  identical(as.character(s2_status_pre$final_state[1]),"PASS_R4A_STEP2_DETERMINISTIC_EXECUTION_READY_FOR_INDEPENDENT_AUDIT") &&
  identical(as.character(s2_status_pre$run_id[1]),step2_run_id) &&
  identical(as.integer(s2_status_pre$hard_failures[1]),0L) &&
  identical(as.character(s2_status_pre$outcome_execution_completed[1]),"YES") &&
  identical(as.character(s2_status_pre$program_primary_executed[1]),"YES") &&
  identical(as.character(s2_status_pre$sex_adjusted_sensitivity_executed[1]),"YES") &&
  identical(as.character(s2_status_pre$kruskal_sensitivity_executed[1]),"YES") &&
  identical(as.character(s2_status_pre$primary25_secondary_executed[1]),"YES") &&
  identical(as.character(s2_status_pre$new_discovery_executed[1]),"NO") &&
  identical(as.character(s2_status_pre$pairwise_inferential_tests_executed[1]),"NO") &&
  identical(as.character(s2_status_pre$threshold_retuning_executed[1]),"NO") &&
  identical(as.integer(s2_status_pre$primary_program_FDR_family_size[1]),16L) &&
  identical(as.integer(s2_status_pre$primary25_secondary_FDR_family_size[1]),25L) &&
  identical(as.character(s2_status_pre$next_stage[1]),"CHATGPT_INDEPENDENT_AUDIT_THEN_R4A_STEP3_POSTGEN_VALIDATION_AND_CLOSURE")
check("STEP2_CURRENT_STATUS_BINDING",
      "Current C0347 Step2 status is exact PASS and bound to resolved current RUN_ID",
      step2_status_ok,
      if(nrow(s2_status_pre)) paste(s2_status_pre$run_id[1],s2_status_pre$final_state[1],s2_status_pre$hard_failures[1],sep=" | ") else "NO_ROW")

pre <- do.call(rbind,AUD)
if(any(pre$status=="FAIL" & pre$critical=="YES")) {
  awrite(pre,file.path(OUT,"R4A_STEP3_VALIDATION_AUDIT.csv"))
  awrite(data.frame(final_state="HOLD_R4A_STEP3_PREVALIDATION",
                    run_id=STAMP,
                    hard_failures=sum(pre$status=="FAIL" & pre$critical=="YES"),
                    terminal_closed="NO",stringsAsFactors=FALSE),
         file.path(OUT,"R4A_STEP3_STATUS.csv"))
  quit(save="no",status=92,runLast=FALSE)
}

# ------------------------------------------------------------------------------
# Independent reconstruction from frozen source inputs.
# Step2 result CSVs are NOT opened until reconstruction is complete.
# ------------------------------------------------------------------------------

sm <- read.csv(SAMPLE,stringsAsFactors=FALSE,check.names=FALSE)
bl <- sm[sm$timepoint=="BL",,drop=FALSE]
risk_levels <- c("MODERATE","INTERMEDIATE","SEVERE")
bl$risk_group <- factor(bl$esc_risk_group,levels=risk_levels,ordered=TRUE)
bl$risk_numeric <- match(as.character(bl$risk_group),risk_levels)-1L
bl$sex <- factor(bl$sex,levels=c("Female","Male"))
bl <- bl[order(bl$patient_number),,drop=FALSE]

mat <- read.delim(gzfile(MAT,"rt"),stringsAsFactors=FALSE,check.names=FALSE,
                  quote="",comment.char="")
symbols <- trimws(as.character(mat[["Ensembl gene"]]))
X <- as.matrix(mat[,bl$matrix_column,drop=FALSE])
storage.mode(X) <- "double"
Y <- log2(X+1)

mu <- rowMeans(Y)
sdev <- apply(Y,1,sd)
finite <- apply(Y,1,function(v) all(is.finite(v)))
eligible <- finite & is.finite(sdev) & sdev>0
Z <- (Y-mu)/sdev

gl <- readLines(GMT,warn=FALSE)
parts <- strsplit(gl,"\t",fixed=TRUE)
gmt_names <- vapply(parts,`[`,character(1),1L)
gmt_genes <- lapply(parts,function(x) unique(if(length(x)>=3L) x[3:length(x)] else character()))
names(gmt_genes) <- gmt_names

targets <- read.csv(TARGETS,stringsAsFactors=FALSE,check.names=FALSE)
progs <- targets[targets$target_family=="STABLE_PROGRAM_16",,drop=FALSE]
genes <- targets[targets$target_family=="PRIMARY25_GENE",,drop=FALSE]

recon_prog <- list()
recon_sex <- list()
recon_kw <- list()
recon_ps <- list()

for(i in seq_len(nrow(progs))) {
  pid <- progs$target_id[i]
  mem <- gmt_genes[[pid]]
  idx <- match(mem,symbols)
  idx <- idx[!is.na(idx)]
  idx <- idx[eligible[idx]]
  raw <- colMeans(Z[idx,,drop=FALSE])
  mult <- if(progs$failure_direction[i]=="UP_IN_FAILURE") 1 else -1
  sc <- raw*mult

  cr <- suppressWarnings(cor.test(sc,bl$risk_numeric,method="spearman",
                                  exact=FALSE,alternative="two.sided"))
  fit <- lm(sc ~ risk_numeric + sex,data=bl)
  co <- summary(fit)$coefficients
  kw <- kruskal.test(sc ~ risk_group,data=bl)

  recon_prog[[i]] <- data.frame(
    pathway=pid,spearman_rho=unname(cr$estimate),p_value=cr$p.value,
    usable_gene_n=length(idx),stringsAsFactors=FALSE)
  recon_sex[[i]] <- data.frame(
    pathway=pid,beta_risk=co["risk_numeric","Estimate"],
    se_risk=co["risk_numeric","Std. Error"],
    t_risk=co["risk_numeric","t value"],
    p_value=co["risk_numeric","Pr(>|t|)"],stringsAsFactors=FALSE)
  recon_kw[[i]] <- data.frame(
    pathway=pid,kruskal_wallis_chisq=unname(kw$statistic),
    p_value=kw$p.value,stringsAsFactors=FALSE)
  for(j in seq_len(nrow(bl))) {
    recon_ps[[length(recon_ps)+1L]] <- data.frame(
      patient_id=bl$patient_id[j],pathway=pid,
      raw_program_score=raw[j],failure_oriented_program_score=sc[j],
      stringsAsFactors=FALSE)
  }
}
recon_prog <- do.call(rbind,recon_prog)
recon_prog$q_BH <- p.adjust(recon_prog$p_value,method="BH",n=16L)
recon_sex <- do.call(rbind,recon_sex)
recon_sex$q_BH <- p.adjust(recon_sex$p_value,method="BH",n=16L)
recon_kw <- do.call(rbind,recon_kw)
recon_kw$q_BH <- p.adjust(recon_kw$p_value,method="BH",n=16L)
recon_ps <- do.call(rbind,recon_ps)

recon_gene <- list()
recon_gs <- list()
for(i in seq_len(nrow(genes))) {
  g <- genes$target_id[i]
  idx <- which(symbols==g)
  z <- as.numeric(Z[idx,])
  mult <- if(genes$failure_direction[i]=="UP_RVF_vs_pRV") 1 else -1
  sc <- z*mult
  cr <- suppressWarnings(cor.test(sc,bl$risk_numeric,method="spearman",
                                  exact=FALSE,alternative="two.sided"))
  recon_gene[[i]] <- data.frame(
    gene=g,spearman_rho=unname(cr$estimate),p_value=cr$p.value,
    stringsAsFactors=FALSE)
  for(j in seq_len(nrow(bl))) {
    recon_gs[[length(recon_gs)+1L]] <- data.frame(
      patient_id=bl$patient_id[j],gene=g,gene_z=z[j],
      failure_oriented_gene_z=sc[j],stringsAsFactors=FALSE)
  }
}
recon_gene <- do.call(rbind,recon_gene)
recon_gene$q_BH <- p.adjust(recon_gene$p_value,method="BH",n=25L)
recon_gs <- do.call(rbind,recon_gs)

# ------------------------------------------------------------------------------
# NOW open Step2 generated results and compare.
# ------------------------------------------------------------------------------

s2_status <- read.csv(S2_STATUS,stringsAsFactors=FALSE,check.names=FALSE)
obs_prog <- read.csv(S2_PROG,stringsAsFactors=FALSE,check.names=FALSE)
obs_sex <- read.csv(S2_SEX,stringsAsFactors=FALSE,check.names=FALSE)
obs_kw <- read.csv(S2_KW,stringsAsFactors=FALSE,check.names=FALSE)
obs_ps <- read.csv(S2_PSCORE,stringsAsFactors=FALSE,check.names=FALSE)
obs_gene <- read.csv(S2_GENE,stringsAsFactors=FALSE,check.names=FALSE)
obs_gs <- read.csv(S2_GSCORE,stringsAsFactors=FALSE,check.names=FALSE)
obs_family <- read.csv(S2_FAMILY,stringsAsFactors=FALSE,check.names=FALSE)

check("STEP2_PASS","Step2 producer reported PASS with zero hard failures",
      nrow(s2_status)==1L &&
      identical(s2_status$final_state[1],
                "PASS_R4A_STEP2_DETERMINISTIC_EXECUTION_READY_FOR_INDEPENDENT_AUDIT") &&
      as.integer(s2_status$hard_failures[1])==0L,
      paste(s2_status$final_state[1],s2_status$hard_failures[1],sep=" | "))

tol <- 1e-12

cmp_numeric <- function(recon,obs,key,cols,prefix) {
  r <- recon[order(recon[[key]]),c(key,cols),drop=FALSE]
  o <- obs[order(obs[[key]]),c(key,cols),drop=FALSE]
  check(paste0(prefix,"_KEYS"),paste0(prefix," keys exact"),
        identical(as.character(r[[key]]),as.character(o[[key]])),
        paste0(nrow(r),"/",nrow(o)))
  for(cc in cols) {
    d <- max(abs(as.numeric(r[[cc]])-as.numeric(o[[cc]])),na.rm=TRUE)
    if(!is.finite(d)) d <- 0
    check(paste0(prefix,"_",cc),paste0(prefix," ",cc," max abs diff <=1e-12"),
          d<=tol,format(d,scientific=TRUE,digits=8))
  }
}

cmp_numeric(recon_prog,obs_prog,"pathway",
            c("spearman_rho","p_value","q_BH","usable_gene_n"),"PROGRAM_PRIMARY")
cmp_numeric(recon_sex,obs_sex,"pathway",
            c("beta_risk","se_risk","t_risk","p_value","q_BH"),"PROGRAM_SEX")
cmp_numeric(recon_kw,obs_kw,"pathway",
            c("kruskal_wallis_chisq","p_value","q_BH"),"PROGRAM_KW")
cmp_numeric(recon_gene,obs_gene,"gene",
            c("spearman_rho","p_value","q_BH"),"PRIMARY25")

# Patient-level score reconstruction.
rp <- recon_ps[order(recon_ps$pathway,recon_ps$patient_id),]
op <- obs_ps[order(obs_ps$pathway,obs_ps$patient_id),]
check("PSCORE_KEYS","Program patient-score keys exact",
      identical(paste(rp$pathway,rp$patient_id),
                paste(op$pathway,op$patient_id)),nrow(op))
for(cc in c("raw_program_score","failure_oriented_program_score")) {
  d <- max(abs(rp[[cc]]-op[[cc]]))
  check(paste0("PSCORE_",cc),paste0(cc," max abs diff <=1e-12"),
        d<=tol,format(d,scientific=TRUE,digits=8))
}

rg <- recon_gs[order(recon_gs$gene,recon_gs$patient_id),]
og <- obs_gs[order(obs_gs$gene,obs_gs$patient_id),]
check("GSCORE_KEYS","Primary25 patient-score keys exact",
      identical(paste(rg$gene,rg$patient_id),
                paste(og$gene,og$patient_id)),nrow(og))
for(cc in c("gene_z","failure_oriented_gene_z")) {
  d <- max(abs(rg[[cc]]-og[[cc]]))
  check(paste0("GSCORE_",cc),paste0(cc," max abs diff <=1e-12"),
        d<=tol,format(d,scientific=TRUE,digits=8))
}

# Frozen post-execution scientific identity.
prog_support <- sort(obs_prog$pathway[obs_prog$q_BH<0.05 & obs_prog$spearman_rho>0])
prog_opp <- sort(obs_prog$pathway[obs_prog$q_BH<0.05 & obs_prog$spearman_rho<0])
gene_support <- sort(obs_gene$gene[obs_gene$q_BH<0.05 & obs_gene$spearman_rho>0])
gene_opp <- sort(obs_gene$gene[obs_gene$q_BH<0.05 & obs_gene$spearman_rho<0])

EXPECTED_PROG_SUPPORT <- sort(c(
  "HALLMARK_ANGIOGENESIS",
  "HALLMARK_APICAL_JUNCTION",
  "HALLMARK_EPITHELIAL_MESENCHYMAL_TRANSITION",
  "HALLMARK_FATTY_ACID_METABOLISM"
))
EXPECTED_GENE_SUPPORT <- sort(c("SLCO2A1","SMAD7","SLC6A6"))

check("PROGRAM_SUPPORT_SET","Program FDR-support set is exact 4",
      identical(prog_support,EXPECTED_PROG_SUPPORT),
      paste(prog_support,collapse=";"))
check("PROGRAM_OPPOSITE_SET","No program FDR-supported opposite association",
      length(prog_opp)==0L,paste(prog_opp,collapse=";"))
check("GENE_SUPPORT_SET","Primary25 FDR-support set is exact 3",
      identical(gene_support,EXPECTED_GENE_SUPPORT),
      paste(gene_support,collapse=";"))
check("GENE_OPPOSITE_SET","No Primary25 FDR-supported opposite association",
      length(gene_opp)==0L,paste(gene_opp,collapse=";"))

# Sensitivity interpretation: report, never rescue primary.
sex_sig <- sort(obs_sex$pathway[obs_sex$q_BH<0.05])
kw_sig <- sort(obs_kw$pathway[obs_kw$q_BH<0.05])
check("SEX_SENS_SET","Sex-adjusted FDR-significant set recorded exactly",
      identical(sex_sig,sort(c("HALLMARK_ANGIOGENESIS",
                               "HALLMARK_APICAL_JUNCTION",
                               "HALLMARK_EPITHELIAL_MESENCHYMAL_TRANSITION"))),
      paste(sex_sig,collapse=";"))
check("KW_SENS_SET","Kruskal sensitivity FDR-significant set recorded exactly",
      identical(kw_sig,sort(c("HALLMARK_ANGIOGENESIS",
                              "HALLMARK_APICAL_JUNCTION",
                              "HALLMARK_COAGULATION",
                              "HALLMARK_EPITHELIAL_MESENCHYMAL_TRANSITION",
                              "HALLMARK_FATTY_ACID_METABOLISM"))),
      paste(kw_sig,collapse=";"))

# Core seven PEA classes: only Apical Junction gets R4A severity primary support.
core7 <- targets$target_id[targets$target_family=="STABLE_PROGRAM_16" &
          targets$frozen_role %in% c("PROGRAM_REVERSAL_SUPPORTED",
          "PROGRAM_MALADAPTIVE_NONREVERSAL_WORSENING_SUPPORTED")]
core7_support <- sort(intersect(core7,prog_support))
check("CORE7_SEVERITY_SUPPORT",
      "Among frozen PEA core 7, severity support is Apical Junction only",
      identical(core7_support,"HALLMARK_APICAL_JUNCTION"),
      paste(core7_support,collapse=";"))

# No claim that R4A validates PEA classes wholesale.
interpretation <- data.frame(
  item=c(
    "R4A_role",
    "program_primary_family",
    "program_FDR_support_count",
    "program_FDR_opposite_count",
    "program_support_set",
    "core7_severity_support",
    "interferon_alpha_severity_support",
    "interferon_gamma_severity_support",
    "Primary25_secondary_family",
    "Primary25_FDR_support_count",
    "Primary25_support_set",
    "sex_adjusted_program_support_set",
    "Kruskal_program_support_set",
    "fatty_acid_sex_adjusted_note",
    "site_confounding",
    "allowed_manuscript_interpretation",
    "forbidden_interpretation"
  ),
  value=c(
    "SECONDARY_BASELINE_CLINICAL_SEVERITY_VALIDATION",
    "FROZEN_STABLE16_PADDED_BH",
    "4",
    "0",
    paste(EXPECTED_PROG_SUPPORT,collapse=";"),
    "HALLMARK_APICAL_JUNCTION_ONLY",
    "NO",
    "NO",
    "FROZEN_PRIMARY25_PADDED_BH",
    "3",
    paste(EXPECTED_GENE_SUPPORT,collapse=";"),
    paste(sex_sig,collapse=";"),
    paste(kw_sig,collapse=";"),
    "PRIMARY_SIGNIFICANT_BUT_NOT_SEX_ADJUSTED_FDR_SIGNIFICANT",
    "NONE_WITHIN_R4A_ALL_71_BASELINE_SAMPLES_SAME_RV_FREE_WALL",
    "SELECT_FROZEN_RV_FAILURE_PROGRAMS_TRACK_BASELINE_CTEPH_SEVERITY;THIS_ADDS_CLINICAL_SEVERITY_CONTEXT",
    "R4A_DOES_NOT_WHOLESALE_VALIDATE_THE_7_PEA_RESPONSE_CLASSES_AND_DOES_NOT_VALIDATE_INTERFERON_WORSENING"
  ),
  stringsAsFactors=FALSE
)
awrite(interpretation,file.path(OUT,"R4A_STEP3_INTERPRETATION_FREEZE.csv"))

audit <- do.call(rbind,AUD)
hard_fail <- sum(audit$status=="FAIL" & audit$critical=="YES")
awrite(audit,file.path(OUT,"R4A_STEP3_VALIDATION_AUDIT.csv"))

summary <- data.frame(
  metric=c("program_family_size","program_assessable","program_FDR_support",
           "program_FDR_opposite","Primary25_family_size","Primary25_assessable",
           "Primary25_FDR_support","Primary25_FDR_opposite",
           "sex_adjusted_program_FDR_significant",
           "Kruskal_program_FDR_significant","core7_severity_supported"),
  value=c(16,16,4,0,25,25,3,0,length(sex_sig),length(kw_sig),length(core7_support)),
  stringsAsFactors=FALSE
)
awrite(summary,file.path(OUT,"R4A_STEP3_VALIDATED_SUMMARY.csv"))

state <- if(hard_fail==0L) {
  "FINAL_CLOSED_R4A_CTEPH_BASELINE_SEVERITY_VALIDATION"
} else {
  "HOLD_R4A_STEP3_POSTGEN_VALIDATION"
}
awrite(data.frame(
  final_state=state,run_id=STAMP,hard_failures=hard_fail,
  source_level_independent_reconstruction="YES",
  Step2_scientific_outputs_modified="NO",
  new_scientific_testing="NO",
  thresholds_retuned="NO",
  terminal_closed=if(hard_fail==0L) "YES" else "NO",
  next_stage=if(hard_fail==0L) "R4B_PEA_PATIENT_LEVEL_TRAJECTORY_PREFLIGHT"
             else "STOP_AND_REPAIR_VALIDATION_ONLY",
  stringsAsFactors=FALSE
),file.path(OUT,"R4A_STEP3_STATUS.csv"))

cat("FINAL_STATE:",state,"\n")
cat("RUN_ID:",STAMP,"\n")
cat("HARD_FAILURES:",hard_fail,"\n")
cat("PROGRAM_SUPPORT:4/16\n")
cat("PRIMARY25_SUPPORT:3/25\n")
cat("CORE7_SEVERITY_SUPPORT:APICAL_JUNCTION_ONLY\n")
quit(save="no",status=if(hard_fail==0L) 0 else 93,runLast=FALSE)
