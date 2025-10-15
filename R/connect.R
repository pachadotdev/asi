#' @keywords internal
asi_path <- function() {
  sys_asi_path <- Sys.getenv("ASI_PATH")
  sys_asi_path <- gsub("\\\\", "/", sys_asi_path)
  if (sys_asi_path == "") {
    return(gsub("\\\\", "/", tools::R_user_dir("asi")))
  } else {
    return(gsub("\\\\", "/", sys_asi_path))
  }
}

#' Local ASI database file path
#'
#' Returns the path to the local ASI database directory.
#'
#' @param dir Path to the ASI directory on disk. By default this is #' "asi" inside the user's R data directory, or the
#' directory specified by the `ASI_DIR` environment variable if set.
#'
#' @export
#'
#' @examples
#' asi_file_path()
asi_file_path <- function(dir = asi_path()) {
  duckdb_version <- utils::packageVersion("duckdb")
  paste0(dir, "/asi_duckdb_v", gsub("\\.", "", duckdb_version), ".sql")
}
