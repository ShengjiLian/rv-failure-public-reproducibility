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
# RV Project — R4B Step3
# Gate9K V1.28 portability repair: current Step2 STATUS/AUDIT semantic binding only; outcome tables remain exact; science unchanged.
# PEA PATIENT-LEVEL PROGRAM TRAJECTORY — POSTGEN VALIDATION + TERMINAL CLOSURE
#
# VALIDATION ONLY.
# Reconstructs R4B Step2 descriptive trajectories directly from frozen source
# inputs BEFORE opening Step2 output tables.
#
# No new scientific test. No p values. No FDR. No threshold changes.
# ==============================================================================

options(stringsAsFactors=FALSE, warn=1)
args <- commandArgs(trailingOnly=TRUE)
STAMP <- if(length(args)>=1 && nzchar(args[1])) args[1] else format(Sys.time(),"%Y%m%d_%H%M%S")

ROOT <- normalizePath(getwd(),winslash="/",mustWork=TRUE)
if(!identical(ROOT,RV_PROJECT_ROOT)) stop("Expected working directory D:/RV_project",call.=FALSE)

OUTROOT <- file.path(ROOT,"results","R4B_PEA_PATIENT_TRAJECTORY_POSTGEN_VALIDATION")
OUT <- file.path(OUTROOT,STAMP)
dir.create(OUT,recursive=TRUE,showWarnings=FALSE)

STEP1 <- rv_resolve_stage_run(file.path(ROOT, "results", "R4B_PEA_PATIENT_TRAJECTORY_METHOD_CONTRACT"))
STEP2 <- rv_resolve_stage_run(file.path(ROOT, "results", "R4B_PEA_PATIENT_TRAJECTORY_EXECUTION"))
STEP0 <- rv_resolve_stage_run(file.path(ROOT, "results", "R4B_PEA_PATIENT_TRAJECTORY_PREFLIGHT"))

S1_CONTRACT <- file.path(STEP1,"R4B_STEP1_TRAJECTORY_METHOD_CONTRACT.csv")
S1_CORE     <- file.path(STEP1,"R4B_STEP1_CORE7_DIRECTION_CONTRACT.csv")
S1_ELIG     <- file.path(STEP1,"R4B_STEP1_PROGRAM_ELIGIBILITY_AUDIT.csv")
S0_PAIRS    <- file.path(STEP0,"R4B_STEP0_PAIR_UNIVERSE.csv")
MAT         <- file.path(ROOT,"data","processed","GSE249696","GSE249696_ext395_rnaseq.txt.gz")
GMT         <- file.path(ROOT,"data","authority","MSigDB","h.all.v2026.1.Hs.symbols.gmt")

S2_STATUS   <- file.path(STEP2,"R4B_STEP2_STATUS.csv")
S2_SCORES   <- file.path(STEP2,"R4B_STEP2_PATIENT_PROGRAM_SCORES.csv")
S2_DELTAS   <- file.path(STEP2,"R4B_STEP2_PATIENT_PROGRAM_DELTAS.csv")
S2_PROG     <- file.path(STEP2,"R4B_STEP2_PROGRAM_DIRECTIONAL_SUMMARY.csv")
S2_PAT      <- file.path(STEP2,"R4B_STEP2_PATIENT_CONCORDANCE_SUMMARY.csv")
S2_COR      <- file.path(STEP2,"R4B_STEP2_CLASS_ALIGNED_DELTA_CORRELATION.csv")
S2_CLASS    <- file.path(STEP2,"R4B_STEP2_CLASS_DIRECTIONAL_SUMMARY.csv")
S2_OVERALL  <- file.path(STEP2,"R4B_STEP2_OVERALL_SUMMARY.csv")
S2_AUDIT    <- file.path(STEP2,"R4B_STEP2_EXECUTION_AUDIT.csv")

EXPECTED_SHA <- c(
  S1_CONTRACT="bca6bf28b04c8ce35a41acceaf9f2e5aded339ea104229d7a7318be2fa95414d",
  S1_CORE    ="c3df8e3b87b1d16e7d7c50fbc3f19afbbc4b5936798aeecc9a7cd1fb162739b0",
  S1_ELIG    ="1e466dc56634d05b629b69f22382970323be2dd9f564a5e466ac05c61085b7a6",
  S0_PAIRS   ="9ba3899cb48ca6baad62ba34c49dcb54a1593a9dbf70dc233e3c47822e31df57",
  MAT        ="2ac6465ed35a45a8b3b56c30df7e6a0b3dc9469bddd340ad36d92a0eae09a5f2",
  GMT        ="eecaf6dad908334ae885406ec72bdc0646d8917588ed7c219fac92fc5363f596",
  S2_STATUS  ="e159cbaa2e7e78d935a8c00a867a106339c7681780ec48d113ace5bc70b16a9f",
  S2_SCORES  ="69dd7407363ee4f75e2cff8d7a0805fea1af80de781130cea0214bfbb86b427d",
  S2_DELTAS  ="585be596436d2dd0ba197d82981448ea8bdb89a3836c3f2d0aca5a4af3cf6971",
  S2_PROG    ="f3c544885981c12b234ea091be6b811d3c9a74a4ade5cec2667fe6aa4e8a6a18",
  S2_PAT     ="ad22ae7372d848a68c4d3ae48a75dbf7c19f80a219a19d0a2e9a18b481ae515e",
  S2_COR     ="8fe970b32b7379d2f9fedef35a56eb2033e6258d3174fe2674a2f9b59b0f4836",
  S2_CLASS   ="e6291efb84e7b214f7d38945d505ca37e7b4f499dd8342994d6e7b04cc4b8071",
  S2_OVERALL ="3115f64907b37d6aebdc8a4098c2a4ff2bb201f409aaa0d51d5101f51563aa51",
  S2_AUDIT   ="9c57d6e0013b22481d1e68783c5fefac88675136cc7f7c75fb657e26d954564e"
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

P <- list(S1_CONTRACT=S1_CONTRACT,S1_CORE=S1_CORE,S1_ELIG=S1_ELIG,
          S0_PAIRS=S0_PAIRS,MAT=MAT,GMT=GMT,S2_STATUS=S2_STATUS,
          S2_SCORES=S2_SCORES,S2_DELTAS=S2_DELTAS,S2_PROG=S2_PROG,
          S2_PAT=S2_PAT,S2_COR=S2_COR,S2_CLASS=S2_CLASS,
          S2_OVERALL=S2_OVERALL,S2_AUDIT=S2_AUDIT)

for(nm in names(P)) check(paste0("FILE_",nm),paste0(nm," exists"),file.exists(P[[nm]]),P[[nm]])
if(any(!vapply(P,file.exists,logical(1)))) {
  awrite(do.call(rbind,AUD),file.path(OUT,"R4B_STEP3_VALIDATION_AUDIT.csv"))
  awrite(data.frame(final_state="HOLD_R4B_STEP3_MISSING_INPUT",run_id=STAMP,
                    hard_failures=1,terminal_closed="NO",stringsAsFactors=FALSE),
         file.path(OUT,"R4B_STEP3_STATUS.csv"))
  quit(save="no",status=131,runLast=FALSE)
}

for(nm in names(EXPECTED_SHA)) {
  got <- sha256(P[[nm]])
  if(identical(nm,"S2_STATUS")) {
    s2_pre <- read.csv(S2_STATUS,stringsAsFactors=FALSE,check.names=FALSE)
    s2_run_id <- basename(STEP2)
    need <- c("final_state","run_id","hard_failures","trajectory_execution_completed",
              "patient_program_scores_calculated","pre_post_deltas_calculated",
              "expected_direction_concordance_calculated","program_delta_correlations_calculated",
              "paired_inferential_tests_executed","binomial_concordance_tests_executed",
              "multiple_testing_FDR_executed","responder_subgroups_defined","new_program_discovery",
              "thresholds_retuned","independent_validation_claim_allowed","site_confounding","next_stage")
    ok <- nrow(s2_pre)==1L && all(need %in% names(s2_pre)) &&
      identical(as.character(s2_pre$final_state[1]),"PASS_R4B_STEP2_DETERMINISTIC_PATIENT_TRAJECTORY_EXECUTION_READY_FOR_INDEPENDENT_AUDIT") &&
      identical(as.character(s2_pre$run_id[1]),s2_run_id) &&
      identical(as.integer(s2_pre$hard_failures[1]),0L) &&
      identical(as.character(s2_pre$trajectory_execution_completed[1]),"YES") &&
      identical(as.character(s2_pre$patient_program_scores_calculated[1]),"YES") &&
      identical(as.character(s2_pre$pre_post_deltas_calculated[1]),"YES") &&
      identical(as.character(s2_pre$expected_direction_concordance_calculated[1]),"YES") &&
      identical(as.character(s2_pre$program_delta_correlations_calculated[1]),"YES_DESCRIPTIVE_NO_PVALUES") &&
      identical(as.character(s2_pre$paired_inferential_tests_executed[1]),"NO") &&
      identical(as.character(s2_pre$binomial_concordance_tests_executed[1]),"NO") &&
      identical(as.character(s2_pre$multiple_testing_FDR_executed[1]),"NO") &&
      identical(as.character(s2_pre$responder_subgroups_defined[1]),"NO") &&
      identical(as.character(s2_pre$new_program_discovery[1]),"NO") &&
      identical(as.character(s2_pre$thresholds_retuned[1]),"NO") &&
      identical(as.character(s2_pre$independent_validation_claim_allowed[1]),"NO") &&
      identical(as.character(s2_pre$site_confounding[1]),"YES_COMPLETE_21_OF_21") &&
      identical(as.character(s2_pre$next_stage[1]),"CHATGPT_INDEPENDENT_AUDIT_THEN_R4B_STEP3_SOURCE_LEVEL_POSTGEN_VALIDATION_AND_CLOSURE")
    check(paste0("SHA_",nm),"S2_STATUS exact current-run semantic binding",ok,
          if(nrow(s2_pre)) paste(s2_pre$run_id[1],s2_pre$final_state[1],s2_pre$hard_failures[1],sep=" | ") else "NO_ROW")
  } else if(identical(nm,"S2_AUDIT")) {
    s2_audit_pre <- read.csv(S2_AUDIT,stringsAsFactors=FALSE,check.names=FALSE)
    expected_ids <- c("FILE_S1_STATUS","FILE_S1_CONTRACT","FILE_S1_CORE","FILE_S1_ELIG","FILE_S1_AUDIT","FILE_S0_PAIRS","FILE_MAT","FILE_GMT","SHA_S1_STATUS","SHA_S1_CONTRACT","SHA_S1_CORE","SHA_S1_ELIG","SHA_S1_AUDIT","SHA_S0_PAIRS","SHA_MAT","SHA_GMT","STEP1_PASS","STEP1_NO_OUTCOME","CONTRACT_module_role","CONTRACT_pair_universe","CONTRACT_site_confounding","CONTRACT_independent_validation_allowed","CONTRACT_trajectory_target_n","CONTRACT_expression_transform","CONTRACT_gene_standardization","CONTRACT_raw_program_score","CONTRACT_failure_oriented_program_score","CONTRACT_pair_delta","CONTRACT_expected_delta_reversal","CONTRACT_expected_delta_worsening","CONTRACT_class_aligned_delta","CONTRACT_zero_delta_tolerance","CONTRACT_program_expected_direction_fraction","CONTRACT_responder_subgroup_definition","CONTRACT_program_delta_correlation","CONTRACT_program_delta_correlation_pvalues","CONTRACT_paired_inferential_test","CONTRACT_binomial_concordance_test","CONTRACT_multiple_testing_FDR","CONTRACT_patient_display_order","CONTRACT_outcome_based_patient_reordering","CONTRACT_new_program_discovery","CONTRACT_new_gene_discovery","CONTRACT_threshold_retuning_after_results","PAIR21","PAIR42","SITE21","CORE7","ELIG7","MATRIX42_PRESENT","USABLE_1","USABLE_2","USABLE_3","USABLE_4","USABLE_5","USABLE_6","USABLE_7","OUT_SCORES","OUT_DELTAS","OUT_PROGRAM7","OUT_PATIENT21","OUT_COR49","OUT_PATIENT_ORDER","OUT_NO_PAIRED_TEST","OUT_NO_BINOMIAL_TEST","OUT_NO_FDR","OUT_NO_RESPONDER","OUT_NO_DISCOVERY","OUT_SITE_CONFOUND")
    ok <- nrow(s2_audit_pre)==length(expected_ids) &&
      identical(as.character(s2_audit_pre$guard_id),expected_ids) &&
      all(as.character(s2_audit_pre$critical)=="YES") &&
      all(as.character(s2_audit_pre$status)=="PASS")
    check(paste0("SHA_",nm),"S2_AUDIT exact 69-check current-run all-PASS identity",ok,
          paste0("rows=",nrow(s2_audit_pre),";pass=",sum(s2_audit_pre$status=="PASS")))
  } else {
    check(paste0("SHA_",nm),paste0(nm," exact frozen SHA256"),
          identical(tolower(got),tolower(EXPECTED_SHA[[nm]])),got)
  }
}

pre <- do.call(rbind,AUD)
if(any(pre$status=="FAIL" & pre$critical=="YES")) {
  awrite(pre,file.path(OUT,"R4B_STEP3_VALIDATION_AUDIT.csv"))
  awrite(data.frame(final_state="HOLD_R4B_STEP3_PREVALIDATION",run_id=STAMP,
                    hard_failures=sum(pre$status=="FAIL" & pre$critical=="YES"),
                    terminal_closed="NO",stringsAsFactors=FALSE),
         file.path(OUT,"R4B_STEP3_STATUS.csv"))
  quit(save="no",status=132,runLast=FALSE)
}

# ------------------------------------------------------------------------------
# Independent reconstruction from frozen source inputs.
# Step2 result tables are NOT opened until reconstruction is complete.
# ------------------------------------------------------------------------------

pairs <- read.csv(S0_PAIRS,stringsAsFactors=FALSE,check.names=FALSE)
core  <- read.csv(S1_CORE,stringsAsFactors=FALSE,check.names=FALSE)
elig  <- read.csv(S1_ELIG,stringsAsFactors=FALSE,check.names=FALSE)

mat <- read.delim(gzfile(MAT,"rt"),stringsAsFactors=FALSE,check.names=FALSE,
                  quote="",comment.char="")
symbols <- trimws(as.character(mat[["Ensembl gene"]]))

sample_cols <- c(pairs$BL_matrix_column,pairs$FU_matrix_column)
X <- as.matrix(mat[,sample_cols,drop=FALSE])
storage.mode(X) <- "double"
Y <- log2(X+1)
mu <- rowMeans(Y)
sdev <- apply(Y,1,sd)
finite42 <- apply(Y,1,function(v) all(is.finite(v)))
eligible42 <- finite42 & is.finite(sdev) & sdev>0
Z <- (Y-mu)/sdev

gl <- readLines(GMT,warn=FALSE)
parts <- strsplit(gl,"\t",fixed=TRUE)
gmt_names <- vapply(parts,`[`,character(1),1L)
gmt_genes <- lapply(parts,function(x) unique(if(length(x)>=3L) x[3:length(x)] else character()))
names(gmt_genes) <- gmt_names

tol <- 1e-12
score_rows <- list()
delta_rows <- list()
summary_rows <- list()

for(i in seq_len(nrow(core))) {
  pid <- core$pathway[i]
  members <- gmt_genes[[pid]]
  idx <- match(members,symbols)
  idx <- idx[!is.na(idx)]
  idx <- idx[eligible42[idx]]

  raw <- colMeans(Z[idx,,drop=FALSE])
  fail_mult <- if(core$failure_direction[i]=="UP_IN_FAILURE") 1 else -1
  fo <- raw*fail_mult
  pre_raw <- raw[seq_len(21)]
  post_raw <- raw[21+seq_len(21)]
  pre_fo <- fo[seq_len(21)]
  post_fo <- fo[21+seq_len(21)]
  delta <- post_fo-pre_fo
  align_mult <- core$class_alignment_multiplier[i]
  class_delta <- delta*align_mult
  expected <- class_delta>tol
  discordant <- class_delta< -tol
  tie <- abs(class_delta)<=tol

  for(j in seq_len(21)) {
    score_rows[[length(score_rows)+1L]] <- data.frame(
      patient_id=pairs$patient_id[j],
      pathway=pid,timepoint="PRE",
      raw_program_score=pre_raw[j],
      failure_oriented_program_score=pre_fo[j],
      stringsAsFactors=FALSE
    )
    score_rows[[length(score_rows)+1L]] <- data.frame(
      patient_id=pairs$patient_id[j],
      pathway=pid,timepoint="POST",
      raw_program_score=post_raw[j],
      failure_oriented_program_score=post_fo[j],
      stringsAsFactors=FALSE
    )
    delta_rows[[length(delta_rows)+1L]] <- data.frame(
      patient_id=pairs$patient_id[j],
      pathway=pid,
      failure_oriented_delta_POST_minus_PRE=delta[j],
      class_aligned_delta=class_delta[j],
      trajectory_direction=if(expected[j]) "CLASS_CONCORDANT" else
                           if(discordant[j]) "CLASS_DISCORDANT" else "TIE_WITHIN_1E-12",
      stringsAsFactors=FALSE
    )
  }

  summary_rows[[i]] <- data.frame(
    pathway=pid,
    expected_direction_n=sum(expected),
    expected_direction_fraction=sum(expected)/21,
    discordant_direction_n=sum(discordant),
    tie_n=sum(tie),
    failure_oriented_delta_mean=mean(delta),
    failure_oriented_delta_sd=sd(delta),
    failure_oriented_delta_median=median(delta),
    failure_oriented_delta_q25=unname(quantile(delta,0.25,type=7)),
    failure_oriented_delta_q75=unname(quantile(delta,0.75,type=7)),
    failure_oriented_delta_min=min(delta),
    failure_oriented_delta_max=max(delta),
    class_aligned_delta_mean=mean(class_delta),
    class_aligned_delta_sd=sd(class_delta),
    class_aligned_delta_median=median(class_delta),
    class_aligned_delta_q25=unname(quantile(class_delta,0.25,type=7)),
    class_aligned_delta_q75=unname(quantile(class_delta,0.75,type=7)),
    class_aligned_delta_min=min(class_delta),
    class_aligned_delta_max=max(class_delta),
    stringsAsFactors=FALSE
  )
}

recon_scores <- do.call(rbind,score_rows)
recon_deltas <- do.call(rbind,delta_rows)
recon_prog <- do.call(rbind,summary_rows)

patient_rows <- list()
for(j in seq_len(nrow(pairs))) {
  z <- recon_deltas[recon_deltas$patient_id==pairs$patient_id[j],,drop=FALSE]
  cc <- core$program_class[match(z$pathway,core$pathway)]
  rev <- cc=="PROGRAM_REVERSAL_SUPPORTED"
  wor <- cc=="PROGRAM_MALADAPTIVE_NONREVERSAL_WORSENING_SUPPORTED"
  patient_rows[[j]] <- data.frame(
    patient_id=pairs$patient_id[j],
    core7_concordant_n=sum(z$class_aligned_delta>tol),
    core7_discordant_n=sum(z$class_aligned_delta< -tol),
    core7_tie_n=sum(abs(z$class_aligned_delta)<=tol),
    reversal5_concordant_n=sum(z$class_aligned_delta[rev]>tol),
    reversal5_discordant_n=sum(z$class_aligned_delta[rev]< -tol),
    worsening2_concordant_n=sum(z$class_aligned_delta[wor]>tol),
    worsening2_discordant_n=sum(z$class_aligned_delta[wor]< -tol),
    stringsAsFactors=FALSE
  )
}
recon_pat <- do.call(rbind,patient_rows)

wide <- reshape(recon_deltas[,c("patient_id","pathway","class_aligned_delta")],
                idvar="patient_id",timevar="pathway",direction="wide")
wide <- wide[match(pairs$patient_id,wide$patient_id),,drop=FALSE]
dcols <- paste0("class_aligned_delta.",core$pathway)
C <- cor(wide[,dcols,drop=FALSE],method="spearman",use="pairwise.complete.obs")
rownames(C) <- core$pathway
colnames(C) <- core$pathway
cor_rows <- list(); k <- 0L
for(a in seq_len(nrow(C))) for(b in seq_len(ncol(C))) {
  k <- k+1L
  cor_rows[[k]] <- data.frame(pathway_1=rownames(C)[a],pathway_2=colnames(C)[b],
                              spearman_rho=unname(C[a,b]),stringsAsFactors=FALSE)
}
recon_cor <- do.call(rbind,cor_rows)

# ------------------------------------------------------------------------------
# NOW open Step2 outputs and compare.
# ------------------------------------------------------------------------------

s2_status <- read.csv(S2_STATUS,stringsAsFactors=FALSE,check.names=FALSE)
obs_scores <- read.csv(S2_SCORES,stringsAsFactors=FALSE,check.names=FALSE)
obs_deltas <- read.csv(S2_DELTAS,stringsAsFactors=FALSE,check.names=FALSE)
obs_prog <- read.csv(S2_PROG,stringsAsFactors=FALSE,check.names=FALSE)
obs_pat <- read.csv(S2_PAT,stringsAsFactors=FALSE,check.names=FALSE)
obs_cor <- read.csv(S2_COR,stringsAsFactors=FALSE,check.names=FALSE)
obs_class <- read.csv(S2_CLASS,stringsAsFactors=FALSE,check.names=FALSE)
obs_overall <- read.csv(S2_OVERALL,stringsAsFactors=FALSE,check.names=FALSE)

check("STEP2_PASS","Step2 producer reported PASS with zero hard failures",
      nrow(s2_status)==1L &&
      identical(s2_status$final_state[1],
      "PASS_R4B_STEP2_DETERMINISTIC_PATIENT_TRAJECTORY_EXECUTION_READY_FOR_INDEPENDENT_AUDIT") &&
      as.integer(s2_status$hard_failures[1])==0L,
      paste(s2_status$final_state[1],s2_status$hard_failures[1],sep=" | "))

tolnum <- 1e-12

# Scores.
rs <- recon_scores[order(recon_scores$pathway,recon_scores$patient_id,recon_scores$timepoint),]
os <- obs_scores[order(obs_scores$pathway,obs_scores$patient_id,obs_scores$timepoint),]
check("SCORE_KEYS","Score keys exact",
      identical(paste(rs$pathway,rs$patient_id,rs$timepoint),
                paste(os$pathway,os$patient_id,os$timepoint)),nrow(os))
for(cc in c("raw_program_score","failure_oriented_program_score")) {
  d <- max(abs(rs[[cc]]-os[[cc]]))
  check(paste0("SCORE_",cc),paste0(cc," max abs diff <=1e-12"),
        d<=tolnum,format(d,scientific=TRUE,digits=8))
}

# Deltas.
rd <- recon_deltas[order(recon_deltas$pathway,recon_deltas$patient_id),]
od <- obs_deltas[order(obs_deltas$pathway,obs_deltas$patient_id),]
check("DELTA_KEYS","Delta keys exact",
      identical(paste(rd$pathway,rd$patient_id),paste(od$pathway,od$patient_id)),nrow(od))
for(cc in c("failure_oriented_delta_POST_minus_PRE","class_aligned_delta")) {
  d <- max(abs(rd[[cc]]-od[[cc]]))
  check(paste0("DELTA_",cc),paste0(cc," max abs diff <=1e-12"),
        d<=tolnum,format(d,scientific=TRUE,digits=8))
}
check("DELTA_DIRECTION","Trajectory direction labels exact",
      identical(rd$trajectory_direction,od$trajectory_direction),
      paste(table(od$trajectory_direction),collapse=";"))

# Program summaries.
rp <- recon_prog[order(recon_prog$pathway),]
op <- obs_prog[order(obs_prog$pathway),]
check("PROG_KEYS","Program summary keys exact",
      identical(rp$pathway,op$pathway),nrow(op))
numcols <- c("expected_direction_n","expected_direction_fraction","discordant_direction_n","tie_n",
             "failure_oriented_delta_mean","failure_oriented_delta_sd",
             "failure_oriented_delta_median","failure_oriented_delta_q25",
             "failure_oriented_delta_q75","failure_oriented_delta_min",
             "failure_oriented_delta_max","class_aligned_delta_mean",
             "class_aligned_delta_sd","class_aligned_delta_median",
             "class_aligned_delta_q25","class_aligned_delta_q75",
             "class_aligned_delta_min","class_aligned_delta_max")
for(cc in numcols) {
  d <- max(abs(as.numeric(rp[[cc]])-as.numeric(op[[cc]])))
  check(paste0("PROG_",cc),paste0(cc," max abs diff <=1e-12"),
        d<=tolnum,format(d,scientific=TRUE,digits=8))
}

# Patient summaries.
rpat <- recon_pat[order(as.integer(sub("^Pat-","",recon_pat$patient_id))),]
opat <- obs_pat[order(obs_pat$patient_number),]
check("PAT_KEYS","Patient summary keys exact",identical(rpat$patient_id,opat$patient_id),nrow(opat))
for(cc in c("core7_concordant_n","core7_discordant_n","core7_tie_n",
            "reversal5_concordant_n","reversal5_discordant_n",
            "worsening2_concordant_n","worsening2_discordant_n")) {
  check(paste0("PAT_",cc),paste0(cc," exact"),
        identical(as.integer(rpat[[cc]]),as.integer(opat[[cc]])),
        paste(opat[[cc]],collapse=";"))
}

# Correlations.
rc <- recon_cor[order(recon_cor$pathway_1,recon_cor$pathway_2),]
oc <- obs_cor[order(obs_cor$pathway_1,obs_cor$pathway_2),]
check("COR_KEYS","7x7 correlation keys exact",
      identical(paste(rc$pathway_1,rc$pathway_2),paste(oc$pathway_1,oc$pathway_2)),nrow(oc))
dcor <- max(abs(rc$spearman_rho-oc$spearman_rho))
check("COR_VALUES","Spearman correlation matrix max abs diff <=1e-12",
      dcor<=tolnum,format(dcor,scientific=TRUE,digits=8))
check("COR_NO_P","Correlation output contains no inferential p values",
      all(is.na(obs_cor$p_value)),paste0(sum(is.na(obs_cor$p_value)),"/",nrow(obs_cor)))

# Frozen descriptive headline identity.
exp_counts <- setNames(obs_prog$expected_direction_n,obs_prog$pathway)
expected_program_counts <- c(
  HALLMARK_INTERFERON_ALPHA_RESPONSE=19L,
  HALLMARK_INTERFERON_GAMMA_RESPONSE=16L,
  HALLMARK_APICAL_JUNCTION=10L,
  HALLMARK_ESTROGEN_RESPONSE_EARLY=19L,
  HALLMARK_IL2_STAT5_SIGNALING=17L,
  HALLMARK_IL6_JAK_STAT3_SIGNALING=14L,
  HALLMARK_TNFA_SIGNALING_VIA_NFKB=17L
)
check("PROGRAM_DIRECTION_COUNTS","Seven program concordant-patient counts exact",
      identical(as.integer(exp_counts[names(expected_program_counts)]),
                as.integer(expected_program_counts)),
      paste(paste(names(expected_program_counts),
                  exp_counts[names(expected_program_counts)],sep="="),collapse=";"))

check("OVERALL_112_35","Overall patient-program direction count is 112 concordant / 35 discordant",
      sum(obs_deltas$class_aligned_delta>tol)==112L &&
      sum(obs_deltas$class_aligned_delta< -tol)==35L,
      paste0(sum(obs_deltas$class_aligned_delta>tol),"/",
             sum(obs_deltas$class_aligned_delta< -tol)))
check("PATIENT_5PLUS","16/21 patients have at least 5 of 7 class-concordant programs",
      sum(obs_pat$core7_concordant_n>=5L)==16L,
      sum(obs_pat$core7_concordant_n>=5L))
check("PATIENT_6PLUS","13/21 patients have at least 6 of 7 class-concordant programs",
      sum(obs_pat$core7_concordant_n>=6L)==13L,
      sum(obs_pat$core7_concordant_n>=6L))
check("PATIENT_7OF7","5/21 patients have all 7 class-concordant",
      sum(obs_pat$core7_concordant_n==7L)==5L,
      sum(obs_pat$core7_concordant_n==7L))
check("APICAL_HETEROGENEOUS","Apical Junction is 10/21 class-concordant and 11/21 discordant",
      exp_counts["HALLMARK_APICAL_JUNCTION"]==10L &&
      obs_prog$discordant_direction_n[obs_prog$pathway=="HALLMARK_APICAL_JUNCTION"]==11L,
      paste0(exp_counts["HALLMARK_APICAL_JUNCTION"],"/",
             obs_prog$discordant_direction_n[obs_prog$pathway=="HALLMARK_APICAL_JUNCTION"]))
check("IFNA_STRONG","IFN-alpha is 19/21 class-concordant",
      exp_counts["HALLMARK_INTERFERON_ALPHA_RESPONSE"]==19L,
      exp_counts["HALLMARK_INTERFERON_ALPHA_RESPONSE"])
check("IFNG_STRONG","IFN-gamma is 16/21 class-concordant",
      exp_counts["HALLMARK_INTERFERON_GAMMA_RESPONSE"]==16L,
      exp_counts["HALLMARK_INTERFERON_GAMMA_RESPONSE"])

# Descriptive correlation headline.
getrho <- function(a,b) {
  obs_cor$spearman_rho[obs_cor$pathway_1==a & obs_cor$pathway_2==b][1]
}
check("IFN_PAIR_COR","IFN-alpha vs IFN-gamma class-aligned deltas show rho >0.90",
      getrho("HALLMARK_INTERFERON_ALPHA_RESPONSE",
             "HALLMARK_INTERFERON_GAMMA_RESPONSE")>0.90,
      getrho("HALLMARK_INTERFERON_ALPHA_RESPONSE",
             "HALLMARK_INTERFERON_GAMMA_RESPONSE"))

interpretation <- data.frame(
  item=c(
    "R4B_role",
    "patient_n",
    "program_n",
    "patient_program_pair_n",
    "overall_class_concordant_n",
    "overall_class_concordant_fraction",
    "reversal_class_concordant_fraction",
    "worsening_class_concordant_fraction",
    "patients_at_least_5_of_7",
    "patients_at_least_6_of_7",
    "patients_7_of_7",
    "apical_junction_concordant_n",
    "apical_junction_discordant_n",
    "interferon_alpha_concordant_n",
    "interferon_gamma_concordant_n",
    "interferon_pair_delta_spearman_rho",
    "inferential_tests",
    "multiple_testing_FDR",
    "independent_validation",
    "site_confounding",
    "allowed_manuscript_interpretation",
    "forbidden_interpretation"
  ),
  value=c(
    "DESCRIPTIVE_PATIENT_LEVEL_HETEROGENEITY_CHARACTERIZATION",
    "21","7","147","112",as.character(112/147),
    as.character(77/105),as.character(35/42),
    "16","13","5","10","11","19","16",
    as.character(getrho("HALLMARK_INTERFERON_ALPHA_RESPONSE",
                        "HALLMARK_INTERFERON_GAMMA_RESPONSE")),
    "NONE","NONE","NO","YES_COMPLETE_21_OF_21",
    "MOST_FROZEN_CORE7_PROGRAMS_SHOW_BROAD_PATIENT_LEVEL_DIRECTIONAL_CONSISTENCY_BUT_APICAL_JUNCTION_IS_MARKEDLY_HETEROGENEOUS",
    "DO_NOT_CALL_R4B_INDEPENDENT_VALIDATION;DO_NOT_USE_P_VALUE_LANGUAGE;DO_NOT_CLAIM_SITE_INDEPENDENT_RECOVERY_OR_WORSENING"
  ),
  stringsAsFactors=FALSE
)
awrite(interpretation,file.path(OUT,"R4B_STEP3_INTERPRETATION_FREEZE.csv"))

summary <- data.frame(
  metric=c("patients","programs","patient_program_pairs","class_concordant_pairs",
           "class_discordant_pairs","patients_ge5_of7","patients_ge6_of7","patients_7of7",
           "apical_concordant","apical_discordant","ifna_concordant","ifng_concordant"),
  value=c(21,7,147,112,35,16,13,5,10,11,19,16),
  stringsAsFactors=FALSE
)
awrite(summary,file.path(OUT,"R4B_STEP3_VALIDATED_SUMMARY.csv"))

audit <- do.call(rbind,AUD)
hard_fail <- sum(audit$status=="FAIL" & audit$critical=="YES")
awrite(audit,file.path(OUT,"R4B_STEP3_VALIDATION_AUDIT.csv"))

state <- if(hard_fail==0L) {
  "FINAL_CLOSED_R4B_PEA_PATIENT_LEVEL_TRAJECTORY_CHARACTERIZATION"
} else {
  "HOLD_R4B_STEP3_POSTGEN_VALIDATION"
}
awrite(data.frame(
  final_state=state,run_id=STAMP,hard_failures=hard_fail,
  source_level_independent_reconstruction="YES",
  Step2_scientific_outputs_modified="NO",
  new_scientific_testing="NO",
  inferential_tests_executed="NO",
  multiple_testing_FDR_executed="NO",
  responder_subgroups_defined="NO",
  thresholds_retuned="NO",
  terminal_closed=if(hard_fail==0L) "YES" else "NO",
  next_stage=if(hard_fail==0L) "R4C_R0_NF_PRV_RVF_PROGRESSION_PREFLIGHT"
             else "STOP_AND_REPAIR_VALIDATION_ONLY",
  stringsAsFactors=FALSE
),file.path(OUT,"R4B_STEP3_STATUS.csv"))

cat("FINAL_STATE:",state,"\n")
cat("RUN_ID:",STAMP,"\n")
cat("HARD_FAILURES:",hard_fail,"\n")
cat("OVERALL_CLASS_CONCORDANT:112/147\n")
cat("PATIENTS_GE5_OF7:16/21\n")
cat("APICAL_JUNCTION:10_CONCORDANT_11_DISCORDANT\n")
cat("IFN_ALPHA:19/21\n")
cat("IFN_GAMMA:16/21\n")
quit(save="no",status=if(hard_fail==0L) 0 else 133,runLast=FALSE)
