# ---- RV PUBLIC REPRODUCIBILITY PORTABILITY OVERLAY V1.0 ----
.RV_PROJECT_ROOT_ENV <- Sys.getenv('RV_PROJECT_ROOT', unset='')
RV_PROJECT_ROOT <- if (nzchar(.RV_PROJECT_ROOT_ENV)) {
  normalizePath(.RV_PROJECT_ROOT_ENV, winslash='/', mustWork=TRUE)
} else {
  normalizePath(getwd(), winslash='/', mustWork=TRUE)
}
# This overlay changes path binding only; scientific/statistical semantics remain historical authority.

source(file.path(RV_PROJECT_ROOT, 'code', 'lib', 'rv_runtime_helpers.R'))


options(stringsAsFactors=FALSE, warn=1)

ROOT <- normalizePath(getwd(), winslash="/", mustWork=TRUE)
if (!identical(ROOT,RV_PROJECT_ROOT)) stop("Expected D:/RV_project")
user_lib <- file.path(Sys.getenv("LOCALAPPDATA"),"R","win-library","4.6")
if (dir.exists(user_lib)) .libPaths(unique(c(user_lib,.libPaths())))
suppressPackageStartupMessages(library(DESeq2))

RES <- file.path(ROOT,"results","R0","v4_LOCAL_RUN")
LOGDIR <- file.path(ROOT,"logs")
dir.create(LOGDIR,recursive=TRUE,showWarnings=FALSE)

ORIG <- file.path(RES,"R0_fitted_dds.rds")
REP <- file.path(RES,"R0_fitted_dds_maxit1000.rds")
STEP2C <- file.path(RES,"R0_EXACT_MODEL_FIT_MAXIT1000_HOLD.txt")
OUT_TRANS <- file.path(RES,"R0_exact_step2D_betaConv_transitions.csv")
OUT_STAB <- file.path(RES,"R0_exact_step2D_primary_contrast_stability.csv")
OUT_LOST <- file.path(RES,"R0_exact_step2D_originally_converged_lost_after_maxit1000.csv")
OUT_TOP <- file.path(RES,"R0_exact_step2D_largest_primary_contrast_changes.csv")
GATE <- file.path(RES,"R0_STEP2D_TARGETED_STABILITY_AUDIT_PASS.txt")
LOG <- file.path(LOGDIR,"R0_STEP2D_targeted_stability_v4_LOCAL_RUN.log")

logline <- function(...) {
  z <- paste0(format(Sys.time(),"%Y-%m-%d %H:%M:%S")," | ",paste0(...,collapse=""))
  cat(z,"\n",sep="")
  cat(z,"\n",file=LOG,append=TRUE,sep="")
}
must <- function(x,msg) if(!isTRUE(x)) stop(msg,call.=FALSE)
awrite <- function(x,p) {
  t <- paste0(p,".tmp_",Sys.getpid())
  write.csv(x,t,row.names=FALSE,na="")
  if(!file.rename(t,p)) {unlink(t); stop("Atomic write failed: ",p)}
}
twrite <- function(x,p) {
  t <- paste0(p,".tmp_",Sys.getpid())
  writeLines(x,t,useBytes=TRUE)
  if(!file.rename(t,p)) {unlink(t); stop("Atomic write failed: ",p)}
}
qfun <- function(x,probs=c(0,.5,.9,.95,.99,.999,1)) {
  x <- x[is.finite(x)]
  if(!length(x)) return(rep(NA_real_,length(probs)))
  as.numeric(quantile(x,probs=probs,names=FALSE,type=7))
}

logline("Exact R0 Step 2D targeted stability audit; model objects are read only.")

must(file.exists(ORIG),"Missing original fitted DDS")
must(file.exists(REP),"Missing maxit1000 fitted DDS")
must(file.exists(STEP2C),"Missing Step-2C HOLD gate")

d0 <- readRDS(ORIG)
d1 <- readRDS(REP)
must(inherits(d0,"DESeqDataSet") && inherits(d1,"DESeqDataSet"),"Invalid DDS")
must(identical(dim(d0),dim(d1)) && all(dim(d0)==c(19428L,142L)),"DDS dimensions differ")
must(identical(rownames(d0),rownames(d1)),"Gene order differs")

m0 <- as.data.frame(S4Vectors::mcols(d0))
m1 <- as.data.frame(S4Vectors::mcols(d1))
b0 <- as.logical(m0$betaConv)
b1 <- as.logical(m1$betaConv)
must(sum(!b0,na.rm=TRUE)==807L && sum(is.na(b0))==0L,"Original betaConv unexpected")
must(sum(!b1,na.rm=TRUE)==698L && sum(is.na(b1))==0L,"maxit1000 betaConv unexpected")

transition <- ifelse(b0 & b1,"CONVERGED_TO_CONVERGED",
              ifelse(b0 & !b1,"CONVERGED_TO_NONCONVERGED",
              ifelse(!b0 & b1,"NONCONVERGED_TO_CONVERGED",
                     "NONCONVERGED_TO_NONCONVERGED")))
tt <- as.data.frame(table(transition),stringsAsFactors=FALSE)
names(tt) <- c("transition","genes")
awrite(tt,OUT_TRANS)

rn0 <- DESeq2::resultsNames(d0)
rn1 <- DESeq2::resultsNames(d1)
must(identical(rn0,rn1),"resultsNames schema changed")
need <- c("category_pRV_vs_NF","category_RVF_vs_NF")
must(all(need %in% rn0),
     paste("Required category coefficients absent:",paste(rn0,collapse=";")))

lfc0 <- as.numeric(m0[["category_RVF_vs_NF"]]) - as.numeric(m0[["category_pRV_vs_NF"]])
lfc1 <- as.numeric(m1[["category_RVF_vs_NF"]]) - as.numeric(m1[["category_pRV_vs_NF"]])
delta <- lfc1-lfc0
ad <- abs(delta)

idx0 <- which(b0)
idxboth <- which(b0 & b1)

summ <- function(idx,label) {
  x <- ad[idx]; q <- qfun(x)
  data.frame(
    set=label, genes=length(idx),
    abs_delta_min=q[1],abs_delta_median=q[2],abs_delta_p90=q[3],
    abs_delta_p95=q[4],abs_delta_p99=q[5],abs_delta_p999=q[6],
    abs_delta_max=q[7],
    n_gt_1e6=sum(x>1e-6,na.rm=TRUE),
    n_gt_1e4=sum(x>1e-4,na.rm=TRUE),
    n_gt_1e2=sum(x>1e-2,na.rm=TRUE),
    n_gt_0_1=sum(x>0.1,na.rm=TRUE),
    stringsAsFactors=FALSE
  )
}
awrite(rbind(
  summ(idx0,"ORIGINALLY_CONVERGED_18621"),
  summ(idxboth,"CONVERGED_IN_BOTH")
),OUT_STAB)

lost_idx <- which(b0 & !b1)
lost <- data.frame(
  gene_id=rownames(d0)[lost_idx],
  original_betaConv=b0[lost_idx],
  maxit1000_betaConv=b1[lost_idx],
  original_RVF_vs_pRV_log2FC=lfc0[lost_idx],
  maxit1000_RVF_vs_pRV_log2FC=lfc1[lost_idx],
  delta_log2FC=delta[lost_idx],
  abs_delta_log2FC=ad[lost_idx],
  baseMean=as.numeric(m0$baseMean[lost_idx]),
  dispersion=as.numeric(m0$dispersion[lost_idx]),
  stringsAsFactors=FALSE
)
awrite(lost,OUT_LOST)

ord <- order(ad[idx0],decreasing=TRUE,na.last=NA)
sel <- idx0[ord[seq_len(min(100L,length(ord)))]]
top <- data.frame(
  gene_id=rownames(d0)[sel],
  original_betaConv=b0[sel],
  maxit1000_betaConv=b1[sel],
  original_RVF_vs_pRV_log2FC=lfc0[sel],
  maxit1000_RVF_vs_pRV_log2FC=lfc1[sel],
  delta_log2FC=delta[sel],
  abs_delta_log2FC=ad[sel],
  baseMean=as.numeric(m0$baseMean[sel]),
  dispersion=as.numeric(m0$dispersion[sel]),
  stringsAsFactors=FALSE
)
awrite(top,OUT_TOP)

ncc <- sum(transition=="CONVERGED_TO_CONVERGED")
ncn <- sum(transition=="CONVERGED_TO_NONCONVERGED")
nnc <- sum(transition=="NONCONVERGED_TO_CONVERGED")
nnn <- sum(transition=="NONCONVERGED_TO_NONCONVERGED")

twrite(c(
  "R0_STEP2D_TARGETED_STABILITY_AUDIT_PASS",
  paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
  "model_refit_executed=NO",
  "downstream_results_executed=NO",
  paste0("converged_to_converged=",ncc),
  paste0("converged_to_nonconverged=",ncn),
  paste0("nonconverged_to_converged=",nnc),
  paste0("nonconverged_to_nonconverged=",nnn),
  paste0("primary_contrast_abs_delta_max_originally_converged=",format(max(ad[idx0],na.rm=TRUE),digits=12)),
  "next_action=Return outputs to ChatGPT for primary-fit adjudication"
),GATE)

logline("Transitions: CC=",ncc," CN=",ncn," NC=",nnc," NN=",nnn)
logline("Primary contrast max abs delta among original converged=",
        format(max(ad[idx0],na.rm=TRUE),digits=12))
logline("FINAL_GATE: R0_STEP2D_TARGETED_STABILITY_AUDIT_PASS")
quit(save="no",status=0,runLast=FALSE)
