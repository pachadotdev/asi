library(haven)
library(purrr)
library(xml2)
library(usethis)

use_cc0_license()

obs <- paste0("data-raw/", c("201920", "202021", "202122", "202223"))

available_datasets <- c("2019-20", "2020-21", "2021-22", "2022-23")

use_data(available_datasets, overwrite = TRUE)

# remove extra whitespace from list elements and from character attributes
# e.g. $citation$prodStmt$producer[[1]] == "\n  Industrial Statistics Wing\n"
# should become "Industrial Statistics Wing"

trim_recursive <- function(x) {
  # trim character vectors
  if (is.character(x)) {
    return(trimws(x))
  }

  # if atomic but not character, leave as is
  if (!is.list(x)) {
    return(x)
  }

  # if list, recurse into elements and also trim any character attributes
  x <- map(x, trim_recursive)

  # trim character attributes
  attrs <- attributes(x)
  if (!is.null(attrs)) {
    for (an in names(attrs)) {
      if (is.character(attrs[[an]])) {
        attrs[[an]] <- trimws(attrs[[an]])
      }
    }
    attributes(x) <- attrs
  }

  # Additionally, some lists carry attributes on their elements; normalize those
  x <- imap(x, function(el, nm) {
    if (!is.null(attributes(el))) {
      at <- attributes(el)
      for (an in names(at)) {
        if (is.character(at[[an]])) {
          at[[an]] <- trimws(at[[an]])
        }
      }
      attributes(el) <- at
    }
    el
  })

  x
}

# unwrap/splice list elements whose names are NA or empty so their children move up
# e.g. $<NA>$var$sumStat -> $var$sumStat
normalize_lists <- function(x) {
  if (!is.list(x)) {
    return(x)
  }

  # recurse first
  x <- imap(x, function(el, nm) normalize_lists(el))

  nms <- names(x)
  if (is.null(nms)) {
    return(x)
  }

  new <- list()
  new_nms <- character()

  for (i in seq_along(x)) {
    nm <- nms[i]
    el <- x[[i]]

    # skip empty list elements
    if (is.list(el) && length(el) == 0) next

    if (is.na(nm) || nm == "") {
      if (is.list(el) && length(el) > 0) {
        inner_nms <- names(el)
        if (is.null(inner_nms)) {
          for (j in seq_along(el)) {
            # skip empty inner elements
            if (is.list(el[[j]]) && length(el[[j]]) == 0) next
            new <- c(new, list(el[[j]]))
            new_nms <- c(new_nms, ifelse(is.null(names(el)[j]), "", names(el)[j]))
          }
        } else {
          for (j in seq_along(el)) {
            if (is.list(el[[j]]) && length(el[[j]]) == 0) next
            new <- c(new, list(el[[j]]))
            new_nms <- c(new_nms, inner_nms[j])
          }
        }
      } else {
        new <- c(new, list(el))
        new_nms <- c(new_nms, "")
      }
    } else {
      new <- c(new, list(el))
      new_nms <- c(new_nms, nm)
    }
  }

  # remove any elements that are NULL
  keep <- vapply(new, function(e) !is.null(e), logical(1))
  if (length(keep) > 0) {
    new <- new[keep]
    new_nms <- new_nms[keep]
  }

  if (length(new) == 0) {
    return(list())
  }
  # assign names, but treat empty strings as unnamed
  if (all(new_nms == "")) {
    names(new) <- NULL
  } else {
    # replace empty name entries with NA so they become unnamed
    new_nms[new_nms == ""] <- NA_character_
    names(new) <- new_nms
  }

  new
}

try(dir.create("data-tidy"))

map(
  obs,
  function(x) {
    # x = obs[1]

    nm <- paste0("asi", sub("data-raw/", "", x))

    fout <- paste0("data-tidy/", nm, ".rds")

    if (file.exists(fout)) {
      return(FALSE)
    }

    savs <- list.files(x, pattern = "\\.sav$", full.names = TRUE, recursive = TRUE)

    d <- map(
      savs,
      function(y) {
        # y = savs[1]
        read_sav(y)
      }
    )

    names(d) <- map_chr(
      seq_along(d),
      function(z) {
        # z = 1
        paste0("blk", unique(d[[z]]$blk))
      }
    )

    xmls <- list.files(x, pattern = "\\.xml$", full.names = TRUE, recursive = TRUE)

    d2 <- read_xml(xmls)

    d2 <- as_list(d2)
    d2 <- d2$codeBook

    names(d2) <- "codeBook"

    d2 <- trim_recursive(d2)

    d2 <- normalize_lists(d2)

    d <- list(data = d, metadata = d2)

    saveRDS(d, file = fout, compress = "xz")
  }
)
