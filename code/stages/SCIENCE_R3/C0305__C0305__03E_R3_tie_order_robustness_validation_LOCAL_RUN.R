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
# RV Project — R3 Step 3E
# POSTGEN TIE-ORDER ROBUSTNESS VALIDATION
#
# PURPOSE
#   Validate the already-generated Step3D V1.1 program results against the
#   exact-rank-tie warning emitted by fgsea.
#
# IMPORTANT
#   - This is POSTGEN VALIDATION ONLY.
#   - It does NOT replace or tune the Step3D V1.1 primary result.
#   - It does NOT change Hallmark membership, thresholds, FDR families,
#     rank statistics, or program-classification rules.
#   - It does NOT refit R0/R1 models.
#
# VALIDATION DESIGN
#   A. Exact primary replay:
#      reconstruct the same four rank vectors and rerun Step3D V1.1 with the
#      same deterministic tie order and same fgsea RNG seed.
#      Primary replay must match the frozen Step3D V1.1 outputs.
#
#   B. Tie-order sensitivity:
#      20 deterministic alternative orderings of genes ONLY WITHIN EXACTLY
#      EQUAL NUMERIC RANK VALUES. Rank values themselves are never jittered.
#      For each ordering:
#        - rerun R0 50 Hallmarks
#        - rerun R1 50 Hallmarks
#        - recompute the R0/R1 stable-program family
#        - rerun R3 main and same-site for the fixed primary stable family
#        - reclassify the fixed primary 16 programs
#
# CLEAN_ROBUST requires:
#   - primary replay exact within frozen tolerance
#   - all 20 alternative tie orders preserve the exact stable-program family
#   - all 20 preserve every primary program class
#
# Any sensitivity is REVIEW_REQUIRED, not a new primary result.
# ==============================================================================

options(stringsAsFactors=FALSE, warn=1)
ROOT <- normalizePath(getwd(),winslash="/",mustWork=TRUE)
if(!identical(tolower(ROOT),tolower(RV_PROJECT_ROOT)))
  stop("Expected D:/RV_project")

R0 <- file.path(ROOT,"results","R0","v4_LOCAL_RUN")
R1 <- file.path(ROOT,"results","R1_GSE240921")
R3 <- file.path(ROOT,"results","R3_GSE249696")
AUTH <- file.path(ROOT,"data","authority","MSigDB")
TXDIR <- file.path(ROOT,"data","tximport","GSE345645")
LOGD <- file.path(ROOT,"logs")
dir.create(LOGD,recursive=TRUE,showWarnings=FALSE)

STEP3D_GATE <- file.path(R3,"R3_STEP3D_V1_1_DETERMINISTIC_PROGRAM_EXECUTION_PASS.txt")
P_R0 <- file.path(R3,"R3_STEP3D_V1_1_R0_HALLMARK_GSEA.csv")
P_R1 <- file.path(R3,"R3_STEP3D_V1_1_R1_HALLMARK_GSEA.csv")
P_STABLE <- file.path(R3,"R3_STEP3D_V1_1_R0_R1_STABLE_PROGRAMS.csv")
P_MAIN <- file.path(R3,"R3_STEP3D_V1_1_R3_MAIN_STABLE_PROGRAM_GSEA.csv")
P_SAME <- file.path(R3,"R3_STEP3D_V1_1_R3_SAME_SITE_STABLE_PROGRAM_GSEA.csv")
P_CLASS <- file.path(R3,"R3_STEP3D_V1_1_PROGRAM_CLASSIFICATION.csv")
P_SUM <- file.path(R3,"R3_STEP3D_V1_1_PROGRAM_CLASS_SUMMARY.csv")

GMT <- file.path(AUTH,"h.all.v2026.1.Hs.symbols.gmt")
R0_FULL <- file.path(R0,"R0_FINAL_RVF_vs_pRV_assessable_results.csv")
R1_FULL <- file.path(R1,"R1_GSE240921_primary_Wald_all_genes.csv")
TX2GENE <- file.path(TXDIR,"GSE345645_transcript_to_gene.csv.gz")
R3_MAIN <- file.path(R3,"R3_STEP3A_FIG5c_author_stats_minimal.csv.gz")
R3_SAME <- file.path(R3,"R3_STEP1D_ED4b_same_site_author_stats_minimal.csv.gz")

OUT_AUD <- file.path(R3,"R3_STEP3E_primary_replay_audit.csv")
OUT_RUN <- file.path(R3,"R3_STEP3E_tie_sensitivity_runs.csv")
OUT_PROG <- file.path(R3,"R3_STEP3E_program_tie_robustness.csv")
OUT_PASS <- file.path(R3,"R3_STEP3E_TIE_ORDER_ROBUSTNESS_PASS.txt")
OUT_REVIEW <- file.path(R3,"R3_STEP3E_TIE_ORDER_SENSITIVITY_REVIEW_REQUIRED.txt")
OUT_HOLD <- file.path(R3,"R3_STEP3E_TIE_ORDER_VALIDATION_HOLD.txt")
LOG <- file.path(LOGD,"R3_STEP3E_TIE_ORDER_ROBUSTNESS.log")

if(file.exists(LOG)) {
  old <- file.path(LOGD,paste0("R3_STEP3E_TIE_ORDER_ROBUSTNESS_",
                               format(Sys.time(),"%Y%m%d_%H%M%S"),
                               "_previous.log"))
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
  if(!file.rename(tmp,dest)) {unlink(tmp); stop("Atomic replace failed: ",dest)}
}
awrite <- function(x,p) {
  t <- paste0(p,".tmp_",Sys.getpid()); write.csv(x,t,row.names=FALSE,na="")
  replace_file(t,p)
}
twrite <- function(x,p) {
  t <- paste0(p,".tmp_",Sys.getpid()); writeLines(x,t,useBytes=TRUE)
  replace_file(t,p)
}

A <- list()
add <- function(item,expected,observed,status,notes="") {
  A[[length(A)+1L]] <<- data.frame(
    item=as.character(item),expected=as.character(expected),
    observed=as.character(observed),status=as.character(status),
    notes=as.character(notes),stringsAsFactors=FALSE)
  logline("[",status,"] ",item," | expected=",expected,
          " | observed=",observed,
          if(nzchar(notes))paste0(" | ",notes) else "")
}
flush_audit <- function() if(length(A)) awrite(do.call(rbind,A),OUT_AUD)

hold <- function(reason,code=261L) {
  flush_audit()
  twrite(c(
    "R3_STEP3E_TIE_ORDER_VALIDATION_HOLD",
    paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
    paste0("reason=",reason),
    "primary_Step3D_V1_1_result_modified=NO",
    "upstream_model_refit=NO",
    "automatic_rerun_allowed=NO"
  ),OUT_HOLD)
  quit(save="no",status=code,runLast=FALSE)
}
options(error=function() {
  msg <- geterrmessage()
  try(flush_audit(),silent=TRUE)
  try(twrite(c(
    "R3_STEP3E_TIE_ORDER_VALIDATION_HOLD_RUNTIME_ERROR",
    paste0("error=",gsub("[\r\n]+"," | ",msg)),
    "primary_Step3D_V1_1_result_modified=NO",
    "automatic_rerun_allowed=NO"
  ),OUT_HOLD),silent=TRUE)
  q(save="no",status=262,runLast=FALSE)
})

read_gmt <- function(p) {
  z <- readLines(p,warn=FALSE,encoding="UTF-8")
  sp <- strsplit(z,"\t",fixed=TRUE)
  nm <- vapply(sp,`[`,character(1),1)
  out <- lapply(sp,function(x)unique(x[-c(1,2)]))
  names(out) <- nm
  out
}
signed_z <- function(p,lfc) {
  p <- suppressWarnings(as.numeric(p))
  lfc <- suppressWarnings(as.numeric(lfc))
  ok <- is.finite(p) & p>=0 & p<=1 & is.finite(lfc) & lfc!=0
  out <- rep(NA_real_,length(p))
  pp <- pmax(p[ok],1e-300)
  out[ok] <- sign(lfc[ok])*stats::qnorm(pp/2,lower.tail=FALSE)
  out
}
flatten_le <- function(x) if(is.null(x)||length(x)==0L) "" else paste(as.character(x),collapse=";")

# Base rank table: one row per unique final symbol.
make_rank_df <- function(gene,score,lfc,label,expected_n) {
  d <- data.frame(
    gene=trimws(as.character(gene)),
    score=suppressWarnings(as.numeric(score)),
    lfc=suppressWarnings(as.numeric(lfc)),
    stringsAsFactors=FALSE
  )
  d <- d[!is.na(d$gene)&nzchar(d$gene)&is.finite(d$score)&is.finite(d$lfc),,drop=FALSE]
  if(nrow(d)!=expected_n) stop(label,": rank n mismatch ",nrow(d)," vs ",expected_n)
  if(anyDuplicated(d$gene)) stop(label,": duplicate final symbols")
  d
}

# Ordering policies alter ONLY ordering within exact numeric score ties.
# Numeric rank values are never changed.
order_rank <- function(d,policy="PRIMARY",perm_seed=NA_integer_) {
  if(policy=="PRIMARY") {
    o <- order(-d$score,-abs(d$lfc),d$gene)
  } else if(policy=="SYMBOL_ASC") {
    o <- order(-d$score,d$gene)
  } else if(policy=="SYMBOL_DESC") {
    # Stable deterministic descending symbol tie breaker.
    sym_rank <- rank(d$gene,ties.method="first")
    o <- order(-d$score,-sym_rank,d$gene)
  } else if(policy=="ABS_LFC_ASC") {
    o <- order(-d$score,abs(d$lfc),d$gene)
  } else if(policy=="HASH") {
    if(!requireNamespace("digest",quietly=TRUE)) stop("digest unavailable")
    h <- vapply(
      paste0(perm_seed,"|",d$gene),
      function(x) digest::digest2int(x,seed=perm_seed),
      integer(1)
    )
    o <- order(-d$score,h,d$gene)
  } else stop("Unknown order policy")
  v <- d$score[o]; names(v) <- d$gene[o]; v
}

run_fgsea <- function(pathways,stats) {
  set.seed(20260910)
  warns <- character()
  x <- withCallingHandlers(
    fgsea::fgseaMultilevel(
      pathways=pathways,stats=stats,
      minSize=10,maxSize=500,eps=0,
      scoreType="std",gseaParam=1,nproc=1
    ),
    warning=function(w) {
      warns <<- c(warns,conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  x <- as.data.frame(x,stringsAsFactors=FALSE)
  x$pathway <- as.character(x$pathway)
  x$BH_FDR_frozen_family <- p.adjust(x$pval,method="BH")
  if("leadingEdge" %in% names(x))
    x$leadingEdge <- vapply(x$leadingEdge,flatten_le,character(1))
  attr(x,"warnings") <- unique(warns)
  x[order(x$pathway),,drop=FALSE]
}
eq_num <- function(a,b,tol=1e-12) {
  isTRUE(all.equal(as.numeric(a),as.numeric(b),
                   tolerance=tol,check.attributes=FALSE))
}
compare_fgsea <- function(obs,ref,label,tol=1e-12) {
  if(!setequal(obs$pathway,ref$pathway)) {
    add(paste0(label,": pathway identity"),"EXACT","MISMATCH","FAIL")
    return(FALSE)
  }
  obs <- obs[match(ref$pathway,obs$pathway),,drop=FALSE]
  ok_nes <- eq_num(obs$NES,ref$NES,tol)
  ok_p <- eq_num(obs$pval,ref$pval,tol)
  ok_f <- eq_num(obs$BH_FDR_frozen_family,ref$BH_FDR_frozen_family,tol)
  add(paste0(label,": NES replay"),"EXACT_TOL_1E-12",
      if(ok_nes)"MATCH" else "MISMATCH",if(ok_nes)"PASS" else "FAIL")
  add(paste0(label,": p replay"),"EXACT_TOL_1E-12",
      if(ok_p)"MATCH" else "MISMATCH",if(ok_p)"PASS" else "FAIL")
  add(paste0(label,": BH replay"),"EXACT_TOL_1E-12",
      if(ok_f)"MATCH" else "MISMATCH",if(ok_f)"PASS" else "FAIL")
  ok_nes && ok_p && ok_f
}

classify_fixed <- function(stable_primary,gm,gs) {
  cl <- stable_primary[,c("pathway","failure_direction"),drop=FALSE]
  mm <- match(cl$pathway,gm$pathway)
  ss <- match(cl$pathway,gs$pathway)
  cl$main_NES <- gm$NES[mm]
  cl$main_BH_FDR <- gm$BH_FDR_frozen_family[mm]
  cl$same_site_NES <- gs$NES[ss]
  cl$same_site_BH_FDR <- gs$BH_FDR_frozen_family[ss]
  cl$same_site_assessable <- !is.na(ss) & is.finite(cl$same_site_NES)
  fs <- ifelse(cl$failure_direction=="UP_IN_FAILURE",1,-1)
  main_rel <- ifelse(sign(cl$main_NES)==-fs,"REVERSAL","WORSENING")
  same_rel <- ifelse(cl$same_site_assessable,
                     ifelse(sign(cl$same_site_NES)==-fs,"REVERSAL","WORSENING"),
                     "UNAVAILABLE")
  sig <- is.finite(cl$main_BH_FDR) & cl$main_BH_FDR<0.05
  out <- rep("PROGRAM_INDETERMINATE_NO_MAIN_SIGNAL",nrow(cl))
  for(i in seq_len(nrow(cl))) {
    if(!is.finite(cl$main_NES[i]) || !is.finite(cl$main_BH_FDR[i])) {
      out[i] <- "PROGRAM_UNASSESSABLE"
    } else if(!sig[i]) {
      out[i] <- "PROGRAM_INDETERMINATE_NO_MAIN_SIGNAL"
    } else if(!cl$same_site_assessable[i]) {
      out[i] <- "PROGRAM_MAIN_ONLY_UNRESOLVED"
    } else if(main_rel[i]!=same_rel[i]) {
      out[i] <- "PROGRAM_SITE_CONFLICT"
    } else if(main_rel[i]=="REVERSAL") {
      out[i] <- "PROGRAM_REVERSAL_SUPPORTED"
    } else {
      out[i] <- "PROGRAM_MALADAPTIVE_NONREVERSAL_WORSENING_SUPPORTED"
    }
  }
  data.frame(
    pathway=cl$pathway,
    main_NES=cl$main_NES,
    main_BH_FDR=cl$main_BH_FDR,
    same_site_NES=cl$same_site_NES,
    same_site_BH_FDR=cl$same_site_BH_FDR,
    program_class=out,
    stringsAsFactors=FALSE
  )
}

logline("============================================================")
logline("R3 Step3E postgen tie-order robustness validation")
logline("============================================================")

needed <- c(STEP3D_GATE,P_R0,P_R1,P_STABLE,P_MAIN,P_SAME,P_CLASS,P_SUM,
            GMT,R0_FULL,R1_FULL,TX2GENE,R3_MAIN,R3_SAME)
for(p in needed) {
  ok <- file.exists(p)
  add(paste0("file_exists:",basename(p)),"YES",if(ok)"YES" else "NO",
      if(ok)"PASS" else "FAIL")
}
if(any(!file.exists(needed))) hold("MISSING_REQUIRED_PRIMARY_OR_UPSTREAM_FILE",263L)

gate <- readLines(STEP3D_GATE,warn=FALSE,encoding="UTF-8")
gate_ok <- length(gate)>0L &&
  trimws(gate[1])=="R3_STEP3D_V1_1_DETERMINISTIC_PROGRAM_EXECUTION_PASS"
add("Step3D V1.1 gate identity",
    "R3_STEP3D_V1_1_DETERMINISTIC_PROGRAM_EXECUTION_PASS",
    if(length(gate))trimws(gate[1]) else "<EMPTY>",
    if(gate_ok)"PASS" else "FAIL")
if(!gate_ok) hold("STEP3D_V1_1_GATE_IDENTITY_DRIFT",264L)

if(!requireNamespace("fgsea",quietly=TRUE)) hold("FGSEA_UNAVAILABLE",265L)
if(as.character(utils::packageVersion("fgsea"))!="1.38.0")
  hold("FGSEA_VERSION_DRIFT",266L)
if(!requireNamespace("digest",quietly=TRUE)) hold("DIGEST_UNAVAILABLE",267L)

pathways <- read_gmt(GMT)
if(length(pathways)!=50L) hold("HALLMARK_SET_COUNT_DRIFT",268L)

# Load primary outputs.
pr0 <- read.csv(P_R0,stringsAsFactors=FALSE,check.names=FALSE)
pr1 <- read.csv(P_R1,stringsAsFactors=FALSE,check.names=FALSE)
pst <- read.csv(P_STABLE,stringsAsFactors=FALSE,check.names=FALSE)
pm <- read.csv(P_MAIN,stringsAsFactors=FALSE,check.names=FALSE)
ps <- read.csv(P_SAME,stringsAsFactors=FALSE,check.names=FALSE)
pc <- read.csv(P_CLASS,stringsAsFactors=FALSE,check.names=FALSE)
if(nrow(pr0)!=50L || nrow(pr1)!=50L || nrow(pst)!=16L ||
   nrow(pm)!=16L || nrow(ps)!=16L || nrow(pc)!=16L)
  hold("PRIMARY_STEP3D_ROWCOUNT_DRIFT",269L)

# Reconstruct exact four rank tables.
r0 <- read.csv(R0_FULL,stringsAsFactors=FALSE,check.names=FALSE)
d0 <- make_rank_df(r0$gene_id,r0$stat,r0$log2FoldChange,"R0",18621L)

r1 <- read.csv(R1_FULL,stringsAsFactors=FALSE,check.names=FALSE)
tx <- read.csv(gzfile(TX2GENE),stringsAsFactors=FALSE,check.names=FALSE)
gc <- c("ensembl_gene_id","gene_id","ensembl_gene_id_version")
sc <- c("external_gene_name","gene_symbol","symbol")
gc <- gc[gc %in% names(tx)]
sc <- sc[sc %in% names(tx)]
if(length(gc)<1L || length(sc)<1L) hold("TX2GENE_SCHEMA_DRIFT",270L)
te <- sub("\\.[0-9]+$","",trimws(as.character(tx[[gc[1]]])))
ts <- trimws(as.character(tx[[sc[1]]]))
ok <- !is.na(te)&nzchar(te)&!is.na(ts)&nzchar(ts)
pairs <- unique(data.frame(ens=te[ok],sym=ts[ok],stringsAsFactors=FALSE))
ns <- tapply(pairs$sym,pairs$ens,function(x)length(unique(x)))
good <- names(ns)[ns==1L]
one <- pairs[pairs$ens %in% good,,drop=FALSE]
one <- one[!duplicated(one$ens),,drop=FALSE]
re <- sub("\\.[0-9]+$","",trimws(as.character(r1$gse240921_gene_id)))
mi <- match(re,one$ens)
cand <- data.frame(
  gene=one$sym[mi],
  score=suppressWarnings(as.numeric(r1$stat)),
  lfc=suppressWarnings(as.numeric(r1$log2FoldChange)),
  stringsAsFactors=FALSE
)
cand <- cand[!is.na(cand$gene)&nzchar(cand$gene)&
             is.finite(cand$score),,drop=FALSE]
nr <- table(cand$gene)
cand <- cand[cand$gene %in% names(nr)[nr==1L],,drop=FALSE]
d1 <- make_rank_df(cand$gene,cand$score,cand$lfc,"R1",27222L)

rm <- read.csv(gzfile(R3_MAIN),stringsAsFactors=FALSE,check.names=FALSE)
rs <- read.csv(gzfile(R3_SAME),stringsAsFactors=FALSE,check.names=FALSE)
make_r3 <- function(d,label,nexp) {
  gene <- trimws(as.character(d$gene))
  lfc <- suppressWarnings(as.numeric(d$log2FoldChange))
  z <- signed_z(d$pvalue,lfc)
  x <- data.frame(gene=gene,score=z,lfc=lfc,stringsAsFactors=FALSE)
  x <- x[!is.na(x$gene)&nzchar(x$gene)&is.finite(x$score)&is.finite(x$lfc),,drop=FALSE]
  ct <- table(x$gene)
  x <- x[x$gene %in% names(ct)[ct==1L],,drop=FALSE]
  make_rank_df(x$gene,x$score,x$lfc,label,nexp)
}
dm <- make_r3(rm,"R3_MAIN",33129L)
ds <- make_r3(rs,"R3_SAME",21695L)

# --------------------------------------------------------------------------
# A. Exact primary replay
# --------------------------------------------------------------------------
logline("[PRIMARY REPLAY] exact Step3D V1.1 tie policy")
s0 <- order_rank(d0,"PRIMARY")
s1 <- order_rank(d1,"PRIMARY")
sm <- order_rank(dm,"PRIMARY")
ss <- order_rank(ds,"PRIMARY")

g0 <- run_fgsea(pathways,s0)
g1 <- run_fgsea(pathways,s1)
ok0 <- compare_fgsea(g0,pr0,"R0 primary replay")
ok1 <- compare_fgsea(g1,pr1,"R1 primary replay")

j <- merge(
  g0[,c("pathway","NES","BH_FDR_frozen_family")],
  g1[,c("pathway","NES","BH_FDR_frozen_family")],
  by="pathway",suffixes=c("_R0","_R1"),sort=TRUE
)
j$stable <- j$BH_FDR_frozen_family_R0<0.05 &
            j$BH_FDR_frozen_family_R1<0.05 &
            sign(j$NES_R0)==sign(j$NES_R1)
replay_stable <- sort(j$pathway[j$stable])
primary_stable <- sort(as.character(pst$pathway))
stable_replay_ok <- identical(replay_stable,primary_stable)
add("primary stable-family replay","EXACT_16",
    paste0("n=",length(replay_stable),"; exact=",stable_replay_ok),
    if(stable_replay_ok)"PASS" else "FAIL")

pways16 <- pathways[primary_stable]
gm <- run_fgsea(pways16,sm)
gs <- run_fgsea(pways16,ss)
okm <- compare_fgsea(gm,pm,"R3 main primary replay")
oks <- compare_fgsea(gs,ps,"R3 same-site primary replay")

creplay <- classify_fixed(pst,gm,gs)
pc2 <- pc[match(creplay$pathway,pc$pathway),,drop=FALSE]
class_replay_ok <- identical(as.character(creplay$program_class),
                             as.character(pc2$program_class))
add("primary classification replay","EXACT_16",
    paste0("exact=",class_replay_ok),
    if(class_replay_ok)"PASS" else "FAIL")

if(!(ok0&&ok1&&stable_replay_ok&&okm&&oks&&class_replay_ok))
  hold("PRIMARY_STEP3D_V1_1_REPLAY_MISMATCH",271L)

# --------------------------------------------------------------------------
# B. 20 deterministic alternative exact-tie orders
# --------------------------------------------------------------------------
policies <- c("SYMBOL_ASC","SYMBOL_DESC","ABS_LFC_ASC",
              rep("HASH",17))
seeds <- c(NA,NA,NA,11001:11017)

run_rows <- list()
prog_rows <- list()

for(ii in seq_along(policies)) {
  policy <- policies[ii]
  pseed <- seeds[ii]
  label <- if(policy=="HASH") paste0("HASH_",pseed) else policy
  logline("[SENSITIVITY ",ii,"/20] ",label)

  x0 <- order_rank(d0,policy,pseed)
  x1 <- order_rank(d1,policy,pseed)
  xm <- order_rank(dm,policy,pseed)
  xs <- order_rank(ds,policy,pseed)

  a0 <- run_fgsea(pathways,x0)
  a1 <- run_fgsea(pathways,x1)
  jj <- merge(
    a0[,c("pathway","NES","BH_FDR_frozen_family")],
    a1[,c("pathway","NES","BH_FDR_frozen_family")],
    by="pathway",suffixes=c("_R0","_R1"),sort=TRUE
  )
  jj$stable <- jj$BH_FDR_frozen_family_R0<0.05 &
               jj$BH_FDR_frozen_family_R1<0.05 &
               sign(jj$NES_R0)==sign(jj$NES_R1)
  st_i <- sort(jj$pathway[jj$stable])
  added <- setdiff(st_i,primary_stable)
  dropped <- setdiff(primary_stable,st_i)
  st_exact <- identical(st_i,primary_stable)

  am <- run_fgsea(pways16,xm)
  as <- run_fgsea(pways16,xs)
  ci <- classify_fixed(pst,am,as)
  ci <- ci[match(primary_stable,ci$pathway),,drop=FALSE]
  cp <- pc[match(primary_stable,pc$pathway),,drop=FALSE]

  class_same <- ci$program_class==cp$program_class
  main_sign_same <- sign(ci$main_NES)==sign(cp$main_NES)
  same_sign_same <- sign(ci$same_site_NES)==sign(cp$same_site_NES)
  main_sig_same <- (ci$main_BH_FDR<0.05)==(cp$main_BH_FDR<0.05)

  run_rows[[ii]] <- data.frame(
    sensitivity_run=ii,
    tie_policy=label,
    stable_n=length(st_i),
    stable_family_exact=st_exact,
    stable_added=paste(added,collapse=";"),
    stable_dropped=paste(dropped,collapse=";"),
    primary16_class_exact=all(class_same),
    class_changed_n=sum(!class_same),
    main_NES_sign_changed_n=sum(!main_sign_same),
    same_site_NES_sign_changed_n=sum(!same_sign_same),
    main_significance_changed_n=sum(!main_sig_same),
    stringsAsFactors=FALSE
  )

  prog_rows[[ii]] <- data.frame(
    sensitivity_run=ii,
    tie_policy=label,
    pathway=primary_stable,
    stable_in_this_run=primary_stable %in% st_i,
    main_NES=ci$main_NES,
    main_BH_FDR=ci$main_BH_FDR,
    same_site_NES=ci$same_site_NES,
    same_site_BH_FDR=ci$same_site_BH_FDR,
    program_class=ci$program_class,
    class_matches_primary=class_same,
    main_sign_matches_primary=main_sign_same,
    same_site_sign_matches_primary=same_sign_same,
    main_significance_matches_primary=main_sig_same,
    stringsAsFactors=FALSE
  )
}

runs <- do.call(rbind,run_rows)
progs <- do.call(rbind,prog_rows)
awrite(runs,OUT_RUN)

rob <- do.call(rbind,lapply(primary_stable,function(h) {
  x <- progs[progs$pathway==h,,drop=FALSE]
  data.frame(
    pathway=h,
    stable_in_20=sum(x$stable_in_this_run),
    class_matches_primary_20=sum(x$class_matches_primary),
    main_sign_matches_primary_20=sum(x$main_sign_matches_primary),
    same_site_sign_matches_primary_20=sum(x$same_site_sign_matches_primary),
    main_significance_matches_primary_20=sum(x$main_significance_matches_primary),
    distinct_classes=paste(sort(unique(x$program_class)),collapse=";"),
    main_NES_min=min(x$main_NES),
    main_NES_max=max(x$main_NES),
    same_site_NES_min=min(x$same_site_NES),
    same_site_NES_max=max(x$same_site_NES),
    stringsAsFactors=FALSE
  )
}))
awrite(rob,OUT_PROG)
flush_audit()

all_stable <- all(runs$stable_family_exact)
all_class <- all(runs$primary16_class_exact)
all_main_sign <- all(runs$main_NES_sign_changed_n==0L)
all_same_sign <- all(runs$same_site_NES_sign_changed_n==0L)
all_main_sig <- all(runs$main_significance_changed_n==0L)

if(all_stable && all_class) {
  twrite(c(
    "R3_STEP3E_TIE_ORDER_ROBUSTNESS_PASS",
    paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
    "role=POSTGEN_VALIDATION_ONLY",
    "primary_Step3D_V1_1_result_modified=NO",
    "primary_replay=EXACT",
    "alternative_tie_orders=20",
    "numeric_rank_jitter=NO",
    "stable_family_exact_20_of_20=YES",
    "primary16_classification_exact_20_of_20=YES",
    paste0("main_NES_sign_exact_20_of_20=",if(all_main_sign)"YES" else "NO"),
    paste0("same_site_NES_sign_exact_20_of_20=",if(all_same_sign)"YES" else "NO"),
    paste0("main_significance_exact_20_of_20=",if(all_main_sig)"YES" else "NO"),
    "tie_order_sensitivity_conclusion=CLEAN_ROBUST",
    "upstream_model_refit=NO",
    "pathway_collection_changed=NO",
    "next_stage=ChatGPT_INDEPENDENT_AUDIT_THEN_STEP3D_TERMINAL_FREEZE"
  ),OUT_PASS)
  if(file.exists(OUT_REVIEW)) unlink(OUT_REVIEW,force=TRUE)
  if(file.exists(OUT_HOLD)) unlink(OUT_HOLD,force=TRUE)
  logline("FINAL_GATE: R3_STEP3E_TIE_ORDER_ROBUSTNESS_PASS")
  quit(save="no",status=0,runLast=FALSE)
} else {
  twrite(c(
    "R3_STEP3E_TIE_ORDER_SENSITIVITY_REVIEW_REQUIRED",
    paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
    "role=POSTGEN_VALIDATION_ONLY",
    "primary_Step3D_V1_1_result_modified=NO",
    "primary_replay=EXACT",
    "alternative_tie_orders=20",
    paste0("stable_family_exact_runs=",sum(runs$stable_family_exact),"/20"),
    paste0("classification_exact_runs=",sum(runs$primary16_class_exact),"/20"),
    paste0("main_sign_exact_runs=",sum(runs$main_NES_sign_changed_n==0L),"/20"),
    paste0("same_site_sign_exact_runs=",sum(runs$same_site_NES_sign_changed_n==0L),"/20"),
    paste0("main_significance_exact_runs=",sum(runs$main_significance_changed_n==0L),"/20"),
    "tie_order_sensitivity_conclusion=REVIEW_REQUIRED",
    "scientific_contract_changed=NO",
    "automatic_primary_reclassification=NO",
    "next_stage=ChatGPT_ADJUDICATION_BEFORE_ANY_TERMINAL_FREEZE"
  ),OUT_REVIEW)
  if(file.exists(OUT_PASS)) unlink(OUT_PASS,force=TRUE)
  if(file.exists(OUT_HOLD)) unlink(OUT_HOLD,force=TRUE)
  logline("FINAL_GATE: R3_STEP3E_TIE_ORDER_SENSITIVITY_REVIEW_REQUIRED")
  quit(save="no",status=0,runLast=FALSE)
}
