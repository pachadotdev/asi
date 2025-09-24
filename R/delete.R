#' Delete local ASI database
#'
#' Removes the ASI directory and all its contents.
#'
#' @param ask whether to prompt the user for confirmation before deleting existing census databases. Defaults to TRUE.
#' @return NULL (invisibly)
#' @export
#'
#' @examples
#' \dontrun{ asi_delete() }
asi_delete <- function(ask = TRUE) {
  if (ask) {
    answer <- utils::menu(c("Proceed", "Cancel"), 
                   title = "This will delete all ASI databases",
                   graphics = FALSE)
    if (answer == 2L) {
       return(invisible())
    }
  }
  
  try(unlink(asi_path(), recursive = TRUE))
  return(invisible())
}
