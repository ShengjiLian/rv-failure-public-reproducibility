# RV Project public cold-start R3 Step4B canonical structural preflight V1.1
# Replaces the historical V1.0-V1.7 repair chain as the primary public path.
# Scientific scope: structural/input-availability inspection only.
# No normalization, clustering, integration, module scoring, differential testing,
# GSEA, or program reclassification is performed.

options(stringsAsFactors=FALSE,warn=1)

.RV_PROJECT_ROOT_ENV <- Sys.getenv("RV_PROJECT_ROOT",unset="")
ROOT <- if(nzchar(.RV_PROJECT_ROOT_ENV)) {
  normalizePath(.RV_PROJECT_ROOT_ENV,winslash="/",mustWork=TRUE)
} else {
  normalizePath(getwd(),winslash="/",mustWork=TRUE)
}
OUTDIR <- Sys.getenv("RV_R3_STEP4B_OUTDIR",unset="")
if(!nzchar(OUTDIR)) stop("RV_R3_STEP4B_OUTDIR is required")
dir.create(OUTDIR,recursive=TRUE,showWarnings=FALSE)
OUTDIR <- normalizePath(OUTDIR,winslash="/",mustWork=TRUE)

R3 <- file.path(ROOT,"results","R3_GSE249696")
STEP4A_GATE <- file.path(R3,"R3_STEP4A_LOCALIZATION_TARGETS_FROZEN.txt")
STEP4A_GENE <- file.path(R3,"R3_STEP4A_supported_program_gene_manifest.csv")
SNRNA_RDS <- file.path(ROOT,"data","raw","GSE345646","GSE345646_snRV_ref.rds")
XENIUM_RDS <- file.path(ROOT,"data","raw","GSE345643","GSE345643_RV_Xenium_ambient_corrected_568651cells.rds")

OUT_AUD <- file.path(OUTDIR,"R3_STEP4B_CANONICAL_structural_preflight_audit.csv")
OUT_OBJ <- file.path(OUTDIR,"R3_STEP4B_V1_6_object_summary.csv")
OUT_ASSAY <- file.path(OUTDIR,"R3_STEP4B_V1_6_assay_layer_manifest.csv")
OUT_META <- file.path(OUTDIR,"R3_STEP4B_V1_6_metadata_column_manifest.csv")
OUT_VAL <- file.path(OUTDIR,"R3_STEP4B_V1_6_candidate_metadata_value_counts.csv")
OUT_COV <- file.path(OUTDIR,"R3_STEP4B_V1_6_supported_program_feature_coverage.csv")
OUT_ENV <- file.path(OUTDIR,"R3_STEP4B_CANONICAL_environment_versions.csv")
OUT_PASS <- file.path(OUTDIR,"R3_STEP4B_CANONICAL_STRUCTURAL_PREFLIGHT_FROZEN.txt")
OUT_HOLD <- file.path(OUTDIR,"R3_STEP4B_CANONICAL_STRUCTURAL_PREFLIGHT_HOLD.txt")
LEGACY_TERMINAL_ALIAS <- file.path(OUTDIR,"R3_STEP4B_V1_7_STRUCTURAL_PREFLIGHT_TERMINAL_FROZEN.txt")
LOG <- file.path(OUTDIR,"R3_STEP4B_CANONICAL_STRUCTURAL_PREFLIGHT.log")

logline <- function(...) {
  z <- paste0(
    format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    " | ", paste0(..., collapse="")
  )
  cat(z, "\n", sep="")
  cat(z, "\n", file=LOG, append=TRUE, sep="")
  flush.console()
}

replace_file <- function(tmp, dest) {
  if (file.exists(dest)) unlink(dest, force=TRUE)
  if (!file.rename(tmp, dest)) {
    unlink(tmp, force=TRUE)
    stop("Atomic replacement failed: ", dest)
  }
}

awrite <- function(x, p) {
  t <- paste0(p, ".tmp_", Sys.getpid())
  write.csv(x, t, row.names=FALSE, na="")
  replace_file(t, p)
}

twrite <- function(x, p) {
  t <- paste0(p, ".tmp_", Sys.getpid())
  writeLines(x, t, useBytes=TRUE)
  replace_file(t, p)
}

A <- list()
add <- function(item, expected, observed, status, notes="") {
  A[[length(A)+1L]] <<- data.frame(
    item=as.character(item),
    expected=as.character(expected),
    observed=as.character(observed),
    status=as.character(status),
    notes=as.character(notes),
    stringsAsFactors=FALSE
  )
  logline(
    "[", status, "] ", item,
    " | expected=", expected,
    " | observed=", observed,
    if (nzchar(notes)) paste0(" | ", notes) else ""
  )
}
flush_audit <- function() {
  if (length(A)) awrite(do.call(rbind, A), OUT_AUD)
}

hold <- function(reason, code=341L) {
  flush_audit()
  twrite(c(
    "R3_STEP4B_CANONICAL_STRUCTURAL_PREFLIGHT_HOLD",
    paste0("timestamp=", format(Sys.time(), "%Y-%m-%d %H:%M:%S %z")),
    paste0("reason=", reason),
    "role=STRUCTURAL_INPUT_PREFLIGHT_ONLY",
    "normalization_executed=NO",
    "clustering_executed=NO",
    "integration_executed=NO",
    "module_scoring_executed=NO",
    "differential_testing_executed=NO",
    "program_reclassification=NO",
    "automatic_rerun_allowed=NO"
  ), OUT_HOLD)
  logline("FINAL_GATE: HOLD | ", reason)
  quit(save="no", status=code, runLast=FALSE)
}

options(error=function() {
  msg <- geterrmessage()
  try(logline("[UNHANDLED_R_ERROR] ", gsub("[\r\n]+", " | ", msg)), silent=TRUE)
  try(flush_audit(), silent=TRUE)
  try(twrite(c(
    "R3_STEP4B_CANONICAL_STRUCTURAL_PREFLIGHT_HOLD_RUNTIME_ERROR",
    paste0("timestamp=", format(Sys.time(), "%Y-%m-%d %H:%M:%S %z")),
    paste0("error=", gsub("[\r\n]+", " | ", msg)),
    "automatic_rerun_allowed=NO"
  ), OUT_HOLD), silent=TRUE)
  q(save="no", status=342, runLast=FALSE)
})

parse_kv <- function(p) {
  z <- readLines(p, warn=FALSE, encoding="UTF-8")
  z <- z[nzchar(trimws(z)) & grepl("=", z, fixed=TRUE)]
  out <- sub("^[^=]*=", "", z)
  names(out) <- sub("=.*$", "", z)
  out
}

sha256_file <- function(p) {
  digest::digest(file=p, algo="sha256", serialize=FALSE)
}

collapse0 <- function(x) {
  x <- x[!is.na(x) & nzchar(as.character(x))]
  if (!length(x)) "" else paste(as.character(x), collapse=";")
}

safe_slot <- function(x, s) {
  if (isS4(x) && s %in% methods::slotNames(x)) {
    return(methods::slot(x, s))
  }
  NULL
}

candidate_roles <- function(nm) {
  n <- tolower(nm)
  roles <- character()

  if (grepl("cell.?type|celltype|annotation|annot|cell.?label|major.?type|subtype", n))
    roles <- c(roles, "CELL_TYPE_ANNOTATION_CANDIDATE")

  if (grepl("disease|condition|phenotype|clinical|status|group|category|state", n))
    roles <- c(roles, "DISEASE_STATE_CANDIDATE")

  if (grepl("^orig\\.ident$|sample|donor|patient|subject|individual|specimen", n))
    roles <- c(roles, "SAMPLE_DONOR_ID_CANDIDATE")

  if (grepl("cluster|seurat_clusters|ident", n))
    roles <- c(roles, "CLUSTER_ID_CANDIDATE")

  if (grepl("region|section|capture|fov|field|tissue|site|compartment", n))
    roles <- c(roles, "REGION_SECTION_CANDIDATE")

  if (grepl("^sex$|gender|^age$|age_", n))
    roles <- c(roles, "DEMOGRAPHIC_CANDIDATE")

  if (!length(roles)) "NONE" else paste(unique(roles), collapse=";")
}

metadata_manifest <- function(dataset, md) {
  if (is.null(md) || !is.data.frame(md)) {
    return(data.frame(
      dataset=character(), column=character(), class=character(),
      n_rows=integer(), n_missing=integer(), n_unique=numeric(),
      candidate_role=character(), representative_values=character(),
      stringsAsFactors=FALSE
    ))
  }

  out <- lapply(names(md), function(nm) {
    v <- md[[nm]]
    cls <- paste(class(v), collapse=";")

    if (is.atomic(v) || is.factor(v)) {
      vv <- as.character(v)
      miss <- sum(is.na(vv) | vv=="")
      u <- unique(vv[!is.na(vv) & vv!=""])
      nu <- length(u)
      role <- candidate_roles(nm)
      reps <- ""
      if (role != "NONE" && nu <= 100L) {
        reps <- paste(utils::head(sort(u), 100L), collapse=";")
      }
    } else {
      miss <- NA_integer_
      nu <- NA_integer_
      role <- candidate_roles(nm)
      reps <- ""
    }

    data.frame(
      dataset=dataset,
      column=nm,
      class=cls,
      n_rows=nrow(md),
      n_missing=miss,
      n_unique=nu,
      candidate_role=role,
      representative_values=reps,
      stringsAsFactors=FALSE
    )
  })
  do.call(rbind, out)
}

candidate_value_counts <- function(dataset, md, manifest) {
  if (is.null(md) || !is.data.frame(md) || !nrow(manifest)) {
    return(data.frame(
      dataset=character(), column=character(), candidate_role=character(),
      value=character(), n=integer(), fraction=numeric(),
      stringsAsFactors=FALSE
    ))
  }

  ans <- list()
  k <- 0L
  cand <- manifest[
    manifest$candidate_role != "NONE" &
      !is.na(manifest$n_unique) &
      manifest$n_unique <= 100L,
    , drop=FALSE
  ]

  for (i in seq_len(nrow(cand))) {
    nm <- cand$column[i]
    v <- md[[nm]]
    if (!(is.atomic(v) || is.factor(v))) next
    vv <- as.character(v)
    vv[is.na(vv) | vv==""] <- "<NA_OR_EMPTY>"
    tb <- sort(table(vv), decreasing=TRUE)
    for (j in seq_along(tb)) {
      k <- k + 1L
      ans[[k]] <- data.frame(
        dataset=dataset,
        column=nm,
        candidate_role=cand$candidate_role[i],
        value=names(tb)[j],
        n=as.integer(tb[j]),
        fraction=as.numeric(tb[j]) / length(vv),
        stringsAsFactors=FALSE
      )
    }
  }

  if (!length(ans)) {
    return(data.frame(
      dataset=character(), column=character(), candidate_role=character(),
      value=character(), n=integer(), fraction=numeric(),
      stringsAsFactors=FALSE
    ))
  }
  do.call(rbind, ans)
}

assay_details <- function(dataset, obj) {
  assays <- safe_slot(obj, "assays")
  if (is.null(assays)) {
    return(list(
      manifest=data.frame(
        dataset=character(), assay=character(), assay_class=character(),
        n_features=numeric(), n_cells=numeric(), layer_or_slot=character(),
        layer_n_features=numeric(), layer_n_cells=numeric(),
        stringsAsFactors=FALSE
      ),
      features=list()
    ))
  }

  an <- names(assays)
  rows <- list()
  feats <- list()
  k <- 0L

  for (nm in an) {
    a <- assays[[nm]]
    acl <- paste(class(a), collapse=";")

    f <- tryCatch(rownames(a), error=function(e) NULL)
    cc <- tryCatch(colnames(a), error=function(e) NULL)
    feats[[nm]] <- if (is.null(f)) character() else as.character(f)

    nf <- if (is.null(f)) NA_integer_ else length(f)
    nc <- if (is.null(cc)) NA_integer_ else length(cc)

    layers <- safe_slot(a, "layers")
    if (!is.null(layers) && length(layers)) {
      ln <- names(layers)
      if (is.null(ln)) ln <- paste0("layer_", seq_along(layers))
      for (ii in seq_along(layers)) {
        dd <- tryCatch(dim(layers[[ii]]), error=function(e) NULL)
        k <- k + 1L
        rows[[k]] <- data.frame(
          dataset=dataset, assay=nm, assay_class=acl,
          n_features=nf, n_cells=nc,
          layer_or_slot=ln[ii],
          layer_n_features=if (length(dd)>=1L) dd[1] else NA_integer_,
          layer_n_cells=if (length(dd)>=2L) dd[2] else NA_integer_,
          stringsAsFactors=FALSE
        )
      }
    } else {
      slots <- if (isS4(a)) methods::slotNames(a) else character()
      candidate_slots <- intersect(c("counts","data","scale.data"), slots)

      if (!length(candidate_slots)) {
        k <- k + 1L
        rows[[k]] <- data.frame(
          dataset=dataset, assay=nm, assay_class=acl,
          n_features=nf, n_cells=nc,
          layer_or_slot="<NO_MATRIX_LAYER_IDENTIFIED>",
          layer_n_features=NA_integer_, layer_n_cells=NA_integer_,
          stringsAsFactors=FALSE
        )
      } else {
        for (ss in candidate_slots) {
          mat <- safe_slot(a, ss)
          dd <- tryCatch(dim(mat), error=function(e) NULL)
          k <- k + 1L
          rows[[k]] <- data.frame(
            dataset=dataset, assay=nm, assay_class=acl,
            n_features=nf, n_cells=nc,
            layer_or_slot=ss,
            layer_n_features=if (length(dd)>=1L) dd[1] else NA_integer_,
            layer_n_cells=if (length(dd)>=2L) dd[2] else NA_integer_,
            stringsAsFactors=FALSE
          )
        }
      }
    }
  }

  list(manifest=do.call(rbind, rows), features=feats)
}

feature_coverage <- function(dataset, assay_features, frozen_gene) {
  ans <- list()
  k <- 0L
  pathways <- unique(as.character(frozen_gene$pathway))

  for (assay in names(assay_features)) {
    f <- unique(assay_features[[assay]])
    f <- f[!is.na(f) & nzchar(f)]
    for (h in pathways) {
      target <- unique(as.character(
        frozen_gene$gene_symbol[frozen_gene$pathway == h]
      ))
      present <- intersect(target, f)
      k <- k + 1L
      ans[[k]] <- data.frame(
        dataset=dataset,
        assay=assay,
        pathway=h,
        frozen_module_genes=length(target),
        genes_present=length(present),
        coverage_fraction=if (length(target)) length(present)/length(target) else NA_real_,
        present_gene_symbols=paste(sort(present), collapse=";"),
        absent_gene_symbols=paste(sort(setdiff(target, present)), collapse=";"),
        role="INPUT_FEATURE_AVAILABILITY_ONLY_NO_MODULE_SCORE",
        stringsAsFactors=FALSE
      )
    }
  }

  if (!length(ans)) {
    return(data.frame(
      dataset=character(), assay=character(), pathway=character(),
      frozen_module_genes=integer(), genes_present=integer(),
      coverage_fraction=numeric(), present_gene_symbols=character(),
      absent_gene_symbols=character(), role=character(),
      stringsAsFactors=FALSE
    ))
  }
  do.call(rbind, ans)
}

inspect_object <- function(dataset, path, frozen_gene, expected_cells=NA_integer_) {
  logline("[HASH START] ", dataset, " | ", path)
  fi <- file.info(path)
  sha <- sha256_file(path)
  logline("[HASH DONE] ", dataset, " | bytes=", fi$size, " | sha256=", sha)

  logline("[LOAD START] ", dataset,
          " | Large RDS may take several minutes. Do not interrupt.")
  obj <- tryCatch(
    readRDS(path),
    error=function(e) hold(
      paste0(dataset, "_RDS_READ_FAILED__", gsub("[^A-Za-z0-9_.-]+","_",conditionMessage(e))),
      350L
    )
  )
  logline("[LOAD DONE] ", dataset, " | class=", paste(class(obj), collapse=";"))

  obj_class <- paste(class(obj), collapse=";")
  pkg_class <- paste(unique(na.omit(vapply(
    class(obj),
    function(cl) {
      z <- attr(cl, "package")
      if (is.null(z)) NA_character_ else as.character(z)
    },
    character(1)
  ))), collapse=";")

  md <- safe_slot(obj, "meta.data")
  if (is.null(md) && is.list(obj) && "meta.data" %in% names(obj))
    md <- obj[["meta.data"]]
  if (!is.null(md)) md <- as.data.frame(md, stringsAsFactors=FALSE)

  assays <- safe_slot(obj, "assays")
  default_assay <- safe_slot(obj, "active.assay")
  default_assay <- if (is.null(default_assay)) "" else as.character(default_assay)[1]

  reductions <- safe_slot(obj, "reductions")
  images <- safe_slot(obj, "images")
  graphs <- safe_slot(obj, "graphs")

  ad <- assay_details(dataset, obj)
  mm <- metadata_manifest(dataset, md)
  vv <- candidate_value_counts(dataset, md, mm)
  cv <- feature_coverage(dataset, ad$features, frozen_gene)

  n_cells <- if (!is.null(md)) nrow(md) else {
    vals <- unique(na.omit(ad$manifest$n_cells))
    if (length(vals)==1L) vals else NA_integer_
  }

  summary <- data.frame(
    dataset=dataset,
    file_path=normalizePath(path, winslash="/", mustWork=TRUE),
    file_bytes=as.numeric(fi$size),
    file_mtime=as.character(fi$mtime),
    file_sha256=sha,
    object_class=obj_class,
    class_package_attribute=pkg_class,
    n_cells=n_cells,
    n_metadata_columns=if (is.null(md)) 0L else ncol(md),
    assay_count=if (is.null(assays)) 0L else length(assays),
    assay_names=if (is.null(assays)) "" else collapse0(names(assays)),
    default_assay=default_assay,
    reduction_names=if (is.null(reductions)) "" else collapse0(names(reductions)),
    image_or_FOV_names=if (is.null(images)) "" else collapse0(names(images)),
    graph_names=if (is.null(graphs)) "" else collapse0(names(graphs)),
    stringsAsFactors=FALSE
  )

  add(paste0(dataset, " object metadata available"),
      "YES", if (!is.null(md)) "YES" else "NO",
      if (!is.null(md)) "PASS" else "FAIL")

  add(paste0(dataset, " assay container available"),
      "YES", if (!is.null(assays) && length(assays)>0L) "YES" else "NO",
      if (!is.null(assays) && length(assays)>0L) "PASS" else "FAIL")

  extractable_assays <- sum(vapply(ad$features, length, integer(1)) > 0L)
  add(paste0(dataset, " assays with extractable feature names"),
      ">0", extractable_assays,
      if (extractable_assays>0L) "PASS" else "FAIL")

  if (!is.na(expected_cells)) {
    add(paste0(dataset, " expected processed-object cells"),
        expected_cells, n_cells,
        if (isTRUE(n_cells == expected_cells)) "PASS" else "FAIL",
        "Expectation comes from the accession-provided processed RDS filename.")
  }

  # Return only small summaries. Remove the multi-GB object immediately.
  rm(obj, md, assays, reductions, images, graphs)
  invisible(gc(verbose=FALSE))
  logline("[OBJECT RELEASED] ", dataset, " | garbage collection completed")

  list(
    summary=summary,
    assay=ad$manifest,
    meta=mm,
    values=vv,
    coverage=cv
  )
}

logline("============================================================")
logline("R3 Step4B CLEAN CANONICAL processed-RDS structural preflight")
logline("Historical V1.0-V1.7 failure artifacts are NOT generation inputs")
logline("============================================================")

needed <- c(STEP4A_GATE,STEP4A_GENE,SNRNA_RDS,XENIUM_RDS)
for(p in needed) {
  ok <- file.exists(p)
  add(paste0("file_exists:",basename(p)),"YES",if(ok)"YES"else"NO",if(ok)"PASS"else"FAIL")
}
if(any(!file.exists(needed))) hold("MISSING_CANONICAL_INPUT",501L)

# Frozen Step4A scientific contract.
a4 <- parse_kv(STEP4A_GATE)
req4 <- c(
  upstream_program_analysis_status="FINAL_CLOSED",
  stable_program_universe="16",
  primary_localization_programs="7",
  primary_reversal_programs="5",
  primary_worsening_programs="2",
  primary_module_definition="FULL_OFFICIAL_HALLMARK_MEMBERSHIP",
  primary_module_membership_rows="1183",
  can_downstream_localization_redefine_Step3F_class="NO"
)
for(k in names(req4)) {
  obs <- if(k %in% names(a4)) unname(a4[[k]]) else "<MISSING>"
  exp <- unname(req4[[k]])
  add(paste0("Step4A invariant:",k),exp,obs,if(identical(obs,exp))"PASS"else"FAIL")
}
if(any(vapply(A,function(x)any(x$status=="FAIL"),logical(1))))
  hold("STEP4A_AUTHORITY_DRIFT",502L)

fg <- read.csv(STEP4A_GENE,stringsAsFactors=FALSE,check.names=FALSE)
if(!all(c("pathway","gene_symbol","program_class") %in% names(fg)))
  hold("STEP4A_GENE_MANIFEST_SCHEMA_DRIFT",503L)
add("Step4A primary module membership rows","1183",nrow(fg),if(nrow(fg)==1183L)"PASS"else"FAIL")
add("Step4A pathway-gene duplicate rows","0",sum(duplicated(fg[,c("pathway","gene_symbol")])),
    if(!anyDuplicated(fg[,c("pathway","gene_symbol")]))"PASS"else"FAIL")
if(any(vapply(A,function(x)any(x$status=="FAIL"),logical(1))))
  hold("STEP4A_GENE_MANIFEST_DRIFT",503L)

# Environment is consumed, never installed, by the scientific stage.
# Historical accepted Step4B V1.6 froze SeuratObject 5.4.0 in the project-local
# R 4.6 library. The clean producer must resolve that same library explicitly;
# relying on the user's default .libPaths() would change the environment authority.
PROJECT_LIB <- file.path(ROOT, "R_library", "R-4.6")
project_lib_exists <- dir.exists(PROJECT_LIB)
add("project-local R 4.6 library exists","YES",
    if(project_lib_exists)"YES"else"NO",
    if(project_lib_exists)"PASS"else"FAIL",
    PROJECT_LIB)
if(!project_lib_exists) hold("PROJECT_LOCAL_R46_LIBRARY_MISSING_RUN_ENVIRONMENT_BOOTSTRAP",504L)
.libPaths(c(PROJECT_LIB,.libPaths()))

if(!requireNamespace("digest",quietly=TRUE)) hold("DIGEST_REQUIRED_RUN_ENVIRONMENT_BOOTSTRAP",504L)
if(!requireNamespace("SeuratObject",quietly=TRUE)) hold("SEURATOBJECT_REQUIRED_RUN_ENVIRONMENT_BOOTSTRAP",504L)
so_ver <- as.character(utils::packageVersion("SeuratObject"))
add("SeuratObject version","5.4.0",so_ver,if(identical(so_ver,"5.4.0"))"PASS"else"FAIL")
if(!identical(so_ver,"5.4.0")) hold("SEURATOBJECT_VERSION_DRIFT",504L)

loadNamespace("SeuratObject")
ns_pkg_path <- normalizePath(
  getNamespaceInfo(asNamespace("SeuratObject"),"path"),
  winslash="/",mustWork=TRUE
)
project_norm <- normalizePath(PROJECT_LIB,winslash="/",mustWork=TRUE)
ns_parent <- normalizePath(dirname(ns_pkg_path),winslash="/",mustWork=TRUE)
ns_from_project <- identical(tolower(ns_parent),tolower(project_norm)) &&
                   identical(basename(ns_pkg_path),"SeuratObject")
add("SeuratObject namespace sourced from project library","YES",
    if(ns_from_project)"YES"else"NO",
    if(ns_from_project)"PASS"else"FAIL",
    paste0("namespace=",ns_pkg_path,"; project_library=",project_norm))
if(!ns_from_project) hold("SEURATOBJECT_NAMESPACE_NOT_FROM_PROJECT_LIBRARY",504L)

full_seurat_available <- requireNamespace("Seurat",quietly=TRUE)

# Immutable input identities.
expected_inputs <- data.frame(
  dataset=c("GSE345646","GSE345643"),
  path=c(SNRNA_RDS,XENIUM_RDS),
  bytes=c(3381735778,170494043),
  sha256=c(
    "a5b6b452566bac584c2d62180ef36a360d8e83e64451fb9de7d46779da64bfb1",
    "afe397aed68d0b5fa4cf683c1702b86f990df73c14f1e7f82e38c9f61c255a9a"
  ),
  stringsAsFactors=FALSE
)
for(i in seq_len(nrow(expected_inputs))) {
  pp <- expected_inputs$path[i]
  obs_b <- as.numeric(file.info(pp)$size)
  obs_s <- sha256_file(pp)
  add(paste0(expected_inputs$dataset[i]," bytes"),as.character(expected_inputs$bytes[i]),
      as.character(obs_b),if(identical(obs_b,as.numeric(expected_inputs$bytes[i])))"PASS"else"FAIL")
  add(paste0(expected_inputs$dataset[i]," SHA256"),expected_inputs$sha256[i],
      obs_s,if(identical(obs_s,expected_inputs$sha256[i]))"PASS"else"FAIL")
}
if(any(vapply(A,function(x)any(x$status=="FAIL"),logical(1))))
  hold("PROCESSED_RDS_IDENTITY_DRIFT",505L)

env <- data.frame(
  item=c("R_version","digest_version","SeuratObject_version",
         "project_library","SeuratObject_namespace_path","full_Seurat_available",
         "package_installation_inside_stage"),
  value=c(as.character(getRversion()),as.character(utils::packageVersion("digest")),
          so_ver,project_norm,ns_pkg_path,
          if(full_seurat_available)"YES"else"NO","NO"),
  stringsAsFactors=FALSE
)
awrite(env,OUT_ENV)

# Sequential structural inspection; no scientific analysis.
sn <- inspect_object(
  dataset="GSE345646_snRNA",path=SNRNA_RDS,frozen_gene=fg,expected_cells=61398L
)
xe <- inspect_object(
  dataset="GSE345643_Xenium_ambient_corrected",path=XENIUM_RDS,
  frozen_gene=fg,expected_cells=568651L
)
obj <- rbind(sn$summary,xe$summary)
assay <- rbind(sn$assay,xe$assay)
meta <- rbind(sn$meta,xe$meta)
vals <- rbind(sn$values,xe$values)
cov <- rbind(sn$coverage,xe$coverage)

awrite(obj,OUT_OBJ);awrite(assay,OUT_ASSAY);awrite(meta,OUT_META);awrite(vals,OUT_VAL);awrite(cov,OUT_COV)

# Exact structural authority frozen by the accepted historical execution.
get_obj <- function(ds,col) {
  z <- obj[obj$dataset==ds,col]
  if(length(z)!=1L) return(NA)
  z[[1]]
}
facts <- list(
  c("GSE345646_snRNA","file_bytes","3381735778"),
  c("GSE345646_snRNA","file_sha256","a5b6b452566bac584c2d62180ef36a360d8e83e64451fb9de7d46779da64bfb1"),
  c("GSE345646_snRNA","object_class","Seurat"),
  c("GSE345646_snRNA","n_cells","61398"),
  c("GSE345646_snRNA","assay_names","RNA"),
  c("GSE345646_snRNA","default_assay","RNA"),
  c("GSE345643_Xenium_ambient_corrected","file_bytes","170494043"),
  c("GSE345643_Xenium_ambient_corrected","file_sha256","afe397aed68d0b5fa4cf683c1702b86f990df73c14f1e7f82e38c9f61c255a9a"),
  c("GSE345643_Xenium_ambient_corrected","object_class","Seurat"),
  c("GSE345643_Xenium_ambient_corrected","n_cells","568651"),
  c("GSE345643_Xenium_ambient_corrected","assay_names","Xenium"),
  c("GSE345643_Xenium_ambient_corrected","default_assay","Xenium")
)
for(x in facts) {
  obs <- as.character(get_obj(x[1],x[2]))
  add(paste0(x[1],":",x[2]),x[3],obs,if(identical(obs,x[3]))"PASS"else"FAIL")
}

sn_counts <- assay[assay$dataset=="GSE345646_snRNA"&assay$assay=="RNA"&assay$layer_or_slot=="counts",,drop=FALSE]
sn_data <- assay[assay$dataset=="GSE345646_snRNA"&assay$assay=="RNA"&assay$layer_or_slot=="data",,drop=FALSE]
sn_scale <- assay[assay$dataset=="GSE345646_snRNA"&assay$assay=="RNA"&assay$layer_or_slot=="scale.data",,drop=FALSE]
xe_counts <- assay[assay$dataset=="GSE345643_Xenium_ambient_corrected"&assay$assay=="Xenium"&assay$layer_or_slot=="counts",,drop=FALSE]
assay_ok <- nrow(sn_counts)==1L && sn_counts$layer_n_features==32938L && sn_counts$layer_n_cells==61398L &&
            nrow(sn_data)==1L && sn_data$layer_n_features==32938L && sn_data$layer_n_cells==61398L &&
            nrow(sn_scale)==1L && sn_scale$layer_n_features==2000L && sn_scale$layer_n_cells==61398L &&
            nrow(xe_counts)==1L && xe_counts$layer_n_features==477L && xe_counts$layer_n_cells==568651L
add("assay/layer dimensions",
    "SNRNA_COUNTS_DATA_32938x61398_SCALE2000x61398__XENIUM_COUNTS477x568651",
    if(assay_ok)"SNRNA_COUNTS_DATA_32938x61398_SCALE2000x61398__XENIUM_COUNTS477x568651"else"MISMATCH",
    if(assay_ok)"PASS"else"FAIL")

has_meta <- function(ds,col,nuniq) {
  z <- meta[meta$dataset==ds & meta$column==col,,drop=FALSE]
  nrow(z)==1L && as.integer(z$n_unique)==as.integer(nuniq)
}
meta_ok <- all(
  has_meta("GSE345646_snRNA","group",3),has_meta("GSE345646_snRNA","patient",11),
  has_meta("GSE345646_snRNA","Names",12),has_meta("GSE345646_snRNA","Subnames",37),
  has_meta("GSE345646_snRNA","Subnames_manual",34),
  has_meta("GSE345643_Xenium_ambient_corrected","group",3),
  has_meta("GSE345643_Xenium_ambient_corrected","patient",9),
  has_meta("GSE345643_Xenium_ambient_corrected","cell_type_seurat",34),
  has_meta("GSE345643_Xenium_ambient_corrected","cell_type_rctd_doublet",12),
  has_meta("GSE345643_Xenium_ambient_corrected","roi_Sample",3)
)
add("metadata fields required for Step4C","ALL_PRESENT_WITH_EXPECTED_CARDINALITY",
    if(meta_ok)"ALL_PRESENT_WITH_EXPECTED_CARDINALITY"else"MISMATCH",if(meta_ok)"PASS"else"FAIL")

expected_cov <- data.frame(
  dataset=c(rep("GSE345646_snRNA",7),rep("GSE345643_Xenium_ambient_corrected",7)),
  pathway=rep(c("HALLMARK_APICAL_JUNCTION","HALLMARK_ESTROGEN_RESPONSE_EARLY",
                "HALLMARK_IL2_STAT5_SIGNALING","HALLMARK_IL6_JAK_STAT3_SIGNALING",
                "HALLMARK_INTERFERON_ALPHA_RESPONSE","HALLMARK_INTERFERON_GAMMA_RESPONSE",
                "HALLMARK_TNFA_SIGNALING_VIA_NFKB"),2),
  genes_present=c(196,195,198,86,96,196,199,14,9,20,11,3,17,25),
  stringsAsFactors=FALSE
)
cv <- merge(expected_cov,cov[,c("dataset","pathway","genes_present")],
            by=c("dataset","pathway"),all.x=TRUE,suffixes=c("_expected","_observed"))
cov_ok <- nrow(cv)==14L && all(!is.na(cv$genes_present_observed)) &&
          all(cv$genes_present_expected==cv$genes_present_observed)
add("7-program feature-coverage identities","14_EXACT_ROWS",
    if(cov_ok)"14_EXACT_ROWS"else"MISMATCH",if(cov_ok)"PASS"else"FAIL")

add("normalization executed","NO","NO","PASS")
add("integration executed","NO","NO","PASS")
add("clustering executed","NO","NO","PASS")
add("module scoring executed","NO","NO","PASS")
add("differential testing executed","NO","NO","PASS")
add("program reclassification","NO","NO","PASS")
add("historical failed-run artifact required","NO","NO","PASS")

if(any(vapply(A,function(x)any(x$status=="FAIL"),logical(1))))
  hold("CANONICAL_STRUCTURAL_AUTHORITY_DRIFT",506L)

flush_audit()

canonical_gate <- c(
  "R3_STEP4B_CANONICAL_STRUCTURAL_PREFLIGHT_FROZEN",
  paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
  "producer=CLEAN_COLD_START_CANONICAL_NO_HISTORICAL_FAILURE_CHAIN",
  "upstream_scientific_contract=R3_STEP4A_LOCALIZATION_TARGETS_FROZEN",
  "SeuratObject_version=5.4.0",
  paste0("full_Seurat_available=",if(full_seurat_available)"YES"else"NO"),
  "full_Seurat_required=NO",
  "GSE345646_bytes=3381735778",
  "GSE345646_SHA256=a5b6b452566bac584c2d62180ef36a360d8e83e64451fb9de7d46779da64bfb1",
  "GSE345646_object_class=Seurat",
  "GSE345646_cells=61398",
  "GSE345646_assay=RNA",
  "GSE345646_counts_features=32938",
  "GSE345646_group_levels=3",
  "GSE345646_patients=11",
  "GSE345643_bytes=170494043",
  "GSE345643_SHA256=afe397aed68d0b5fa4cf683c1702b86f990df73c14f1e7f82e38c9f61c255a9a",
  "GSE345643_object_class=Seurat",
  "GSE345643_cells=568651",
  "GSE345643_assay=Xenium",
  "GSE345643_measured_features=477",
  "GSE345643_group_levels=3",
  "GSE345643_patients=9",
  "primary_localization_programs=7",
  "primary_module_membership_rows=1183",
  "normalization_executed=NO",
  "integration_executed=NO",
  "clustering_executed=NO",
  "module_scoring_executed=NO",
  "differential_testing_executed=NO",
  "program_reclassification=NO"
)
twrite(canonical_gate,OUT_PASS)

# Compatibility alias for currently frozen downstream consumers.
# This is generated directly by the clean canonical producer, not by replaying V1.0-V1.7.
legacy <- c(
  "R3_STEP4B_V1_7_STRUCTURAL_PREFLIGHT_TERMINAL_FROZEN",
  paste0("timestamp=",format(Sys.time(),"%Y-%m-%d %H:%M:%S %z")),
  "canonical_producer=R3_STEP4B_CANONICAL_STRUCTURAL_PREFLIGHT_FROZEN",
  "historical_failure_chain_replayed=NO",
  "Step4B_V1_7_status=STRUCTURAL_PREFLIGHT_TERMINAL_FROZEN",
  "SeuratObject_version=5.4.0",
  paste0("full_Seurat_installed=",if(full_seurat_available)"YES"else"NO"),
  "full_Seurat_required=NO",
  "GSE345646_cells=61398","GSE345646_assay=RNA",
  "GSE345643_cells=568651","GSE345643_assay=Xenium",
  "GSE345643_measured_features=477",
  "primary_localization_programs=7",
  "primary_module_membership_rows=1183",
  "program_reclassification=NO"
)
twrite(legacy,LEGACY_TERMINAL_ALIAS)

if(file.exists(OUT_HOLD)) unlink(OUT_HOLD,force=TRUE)
logline("FINAL_GATE: R3_STEP4B_CANONICAL_STRUCTURAL_PREFLIGHT_FROZEN")
quit(save="no",status=0,runLast=FALSE)
