# RV Project public cold-start runtime helpers V1.1
# Deterministic run authority resolution. Never select "newest" by mtime.

rv_resolve_stage_run <- function(stage_root) {
  stage_root <- normalizePath(stage_root, winslash="/", mustWork=TRUE)
  pointer <- file.path(stage_root, "CURRENT_RUN.txt")
  if (file.exists(pointer)) {
    id <- trimws(readLines(pointer, warn=FALSE, n=2L, encoding="UTF-8"))
    id <- id[nzchar(id)]
    if (length(id) != 1L) stop("Invalid CURRENT_RUN.txt in ", stage_root)
    p <- file.path(stage_root, id)
    if (!dir.exists(p)) stop("CURRENT_RUN points to missing directory: ", p)
    return(normalizePath(p, winslash="/", mustWork=TRUE))
  }
  dirs <- list.dirs(stage_root, recursive=FALSE, full.names=TRUE)
  dirs <- dirs[grepl("^[0-9]{8}_[0-9]{6}$", basename(dirs))]
  if (length(dirs) == 1L)
    return(normalizePath(dirs, winslash="/", mustWork=TRUE))
  stop("No deterministic run authority for ", stage_root,
       ". Expected CURRENT_RUN.txt or exactly one timestamped run directory.")
}

rv_stage_file <- function(stage_root, ...) {
  run <- rv_resolve_stage_run(stage_root)
  parts <- list(...)
  if (!length(parts)) return(run)
  do.call(file.path, c(list(run), parts))
}

rv_relpath <- function(path, root=RV_PROJECT_ROOT) {
  p <- normalizePath(path, winslash="/", mustWork=FALSE)
  r <- normalizePath(root, winslash="/", mustWork=TRUE)
  prefix <- paste0(r, "/")
  if (identical(p, r)) return(".")
  if (!startsWith(tolower(p), tolower(prefix)))
    stop("Path is outside RV_PROJECT_ROOT: ", p)
  substring(p, nchar(prefix) + 1L)
}

rv_stage_rel <- function(stage_root, ...) {
  rv_relpath(rv_stage_file(stage_root, ...))
}

rv_publish_stage_run <- function(stage_root, run_dir) {
  stage_root <- normalizePath(stage_root, winslash="/", mustWork=TRUE)
  run_dir <- normalizePath(run_dir, winslash="/", mustWork=TRUE)
  if (!identical(dirname(run_dir), stage_root))
    stop("run_dir is not a direct child of stage_root")
  tmp <- file.path(stage_root, paste0("CURRENT_RUN.txt.tmp_", Sys.getpid()))
  writeLines(basename(run_dir), tmp, useBytes=TRUE)
  dest <- file.path(stage_root, "CURRENT_RUN.txt")
  if (file.exists(dest)) unlink(dest, force=TRUE)
  if (!file.rename(tmp, dest)) {
    unlink(tmp, force=TRUE)
    stop("Failed to publish CURRENT_RUN authority")
  }
  invisible(dest)
}
