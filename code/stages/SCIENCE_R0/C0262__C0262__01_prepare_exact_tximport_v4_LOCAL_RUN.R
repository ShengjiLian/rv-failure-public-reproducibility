options(stringsAsFactors=FALSE, warn=1)

# Gate9L engineering-only wrapper for accepted C0262.
# It creates the R0 sample manifest in the CURRENT RUN from already-authoritative
# local GEO metadata + counts + surrogate variables, then executes accepted C0262 unchanged.

.RV_PROJECT_ROOT_ENV <- Sys.getenv("RV_PROJECT_ROOT", unset="")
RV_PROJECT_ROOT <- if(nzchar(.RV_PROJECT_ROOT_ENV)) {
  normalizePath(.RV_PROJECT_ROOT_ENV,winslash="/",mustWork=TRUE)
} else {
  normalizePath(getwd(),winslash="/",mustWork=TRUE)
}

if(!requireNamespace("digest",quietly=TRUE))
  stop("R package 'digest' is required by Gate9L C0262 wrapper.")

sha <- function(p) digest::digest(file=p,algo="sha256",serialize=FALSE)

canonical_sample_id <- function(x) {
  x <- trimws(as.character(x))
  hit <- regmatches(x,regexpr("P[0-9]+",x,perl=TRUE))
  hit[!nzchar(hit)] <- NA_character_
  hit
}

parse_geo_soft <- function(path) {
  lines <- readLines(gzfile(path),warn=FALSE)
  acc <- sub("^!Sample_geo_accession = ","",
             grep("^!Sample_geo_accession = ",lines,value=TRUE))
  title <- sub("^!Sample_title = ","",
               grep("^!Sample_title = ",lines,value=TRUE))
  if(length(acc)!=length(title))
    stop("GEO SOFT accession/title records are not aligned.")
  data.frame(geo_accession=acc,geo_title=title,stringsAsFactors=FALSE)
}

results_r0 <- file.path(RV_PROJECT_ROOT,"results","R0")
dir.create(results_r0,recursive=TRUE,showWarnings=FALSE)

soft_path <- file.path(RV_PROJECT_ROOT,"data","metadata","GSE345645",
                       "GSE345645_family.soft.gz")
counts_path <- file.path(RV_PROJECT_ROOT,"data","processed","GSE345645",
                         "GSE345645_gene_counts.csv.gz")
sv_path <- file.path(RV_PROJECT_ROOT,"data","processed","GSE345645",
                     "GSE345645_subseries1_adult_bulk_surrogate_variables.csv.gz")
manifest_path <- file.path(results_r0,"R0_sample_manifest.csv")

required <- c(soft_path,counts_path,sv_path)
missing <- required[!file.exists(required)]
if(length(missing))
  stop("Gate9L C0262 wrapper missing authority input(s): ",
       paste(missing,collapse="; "))

expected_sha <- c(
  soft="63d5d98bc092f652d49f6d578e85b0b96944bef3f24021b3def33698ad6621e4",
  counts="d1740b5890f989797cac9bd28b021a54bccbe9eb022cfd5d5649c7b6d4318ded",
  sv="f0307bbb168a874708e75539135896f2b38804901f0fd3adeee3fdf8b7dd2e27"
)
observed_sha <- c(soft=sha(soft_path),counts=sha(counts_path),sv=sha(sv_path))
if(!identical(tolower(observed_sha),tolower(expected_sha))) {
  stop("Gate9L C0262 wrapper authority SHA mismatch.")
}

geo <- parse_geo_soft(soft_path)
geo$sample_id <- canonical_sample_id(geo$geo_title)
geo$disease_group <- sub("^.*_(NF|pRV|RVF)$","\\1",geo$geo_title,perl=TRUE)
geo$disease_group[!geo$disease_group %in% c("NF","pRV","RVF")] <- NA_character_

count_header <- utils::read.csv(
  gzfile(counts_path),check.names=FALSE,stringsAsFactors=FALSE,nrows=0L
)
count_ids <- canonical_sample_id(names(count_header)[-1L])

sv_raw <- utils::read.csv(gzfile(sv_path),check.names=FALSE,stringsAsFactors=FALSE)
sv_ids <- canonical_sample_id(sv_raw[[1L]])

if(nrow(geo)!=142L ||
   anyNA(geo$sample_id) ||
   anyDuplicated(geo$sample_id) ||
   sum(geo$disease_group=="NF")!=29L ||
   sum(geo$disease_group=="pRV")!=78L ||
   sum(geo$disease_group=="RVF")!=35L ||
   !setequal(geo$sample_id,count_ids) ||
   !setequal(geo$sample_id,sv_ids)) {
  stop("Gate9L C0262 wrapper sample-universe contract failed.")
}

manifest <- geo[,c("sample_id","geo_accession","disease_group")]
manifest$SV_available <- manifest$sample_id %in% sv_ids
manifest$expression_available <- manifest$sample_id %in% count_ids
manifest <- manifest[order(manifest$sample_id),,drop=FALSE]
rownames(manifest) <- NULL

tmp_manifest <- paste0(manifest_path,".gate9l_tmp_",Sys.getpid())
on.exit(if(file.exists(tmp_manifest))unlink(tmp_manifest,force=TRUE),add=TRUE)
utils::write.csv(manifest,tmp_manifest,row.names=FALSE,na="")

expected_manifest_sha <- "c229f22a9dae1345f0d4a058aeae5e376cabfae844725cbfede35fad8ece2262"
got_manifest_sha <- sha(tmp_manifest)
if(!identical(tolower(got_manifest_sha),expected_manifest_sha)) {
  stop("Gate9L C0262 wrapper reconstructed manifest SHA mismatch: expected=",
       expected_manifest_sha," observed=",got_manifest_sha)
}

if(file.exists(manifest_path)) {
  existing_sha <- sha(manifest_path)
  if(!identical(tolower(existing_sha),expected_manifest_sha)) {
    stop("Existing R0_sample_manifest.csv is not the frozen exact manifest; refusing overwrite.")
  }
  unlink(tmp_manifest,force=TRUE)
} else {
  if(!file.rename(tmp_manifest,manifest_path)) {
    stop("Failed to atomically publish current-run R0_sample_manifest.csv")
  }
}

base_script <- file.path(
  RV_PROJECT_ROOT,"scripts","paper","GATE9L_BASE_C0262_ACCEPTED.R"
)
if(!file.exists(base_script))
  stop("Accepted C0262 base missing: ",base_script)

# Run accepted C0262 code unchanged after the current-run manifest producer.
source(base_script,chdir=FALSE)
