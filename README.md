
<!-- README.md is generated from README.Rmd. Please edit that file -->

# asi

<!-- badges: start -->
<!-- badges: end -->

The goal of asi is to …

## Installation

You can install the development version of asi like so:

``` r
# FILL THIS IN! HOW CAN PEOPLE INSTALL YOUR DEV PACKAGE?
```

## Example

Install the package from GitHub and load it:

``` r
# install.packages("devtools")
devtools::install_github("pachadotdev/asi")
```

``` r
library(asi)
```

Because of the datasets size, the package provides a function to
download the datasets and create a local DuckDB database. This results
in a CRAN-compliant package.

Here is how to get the ASI database ready for use:

``` r
asi_download()
```

Check the average day of manufacturing days per industry type (See
<https://microdata.gov.in/NADA/index.php/catalog/205/data-dictionary/F35?file_name=blkA202223>):

``` r
library(dplyr)
#> 
#> Attaching package: 'dplyr'
#> The following objects are masked from 'package:stats':
#> 
#>     filter, lag
#> The following objects are masked from 'package:base':
#> 
#>     intersect, setdiff, setequal, union
library(duckdb)
#> Loading required package: DBI

con <- dbConnect(duckdb(), asi_file_path())

dbListTables(con)
#>  [1] "2019-20-blkA" "2019-20-blkB" "2019-20-blkC" "2019-20-blkD" "2019-20-blkE"
#>  [6] "2019-20-blkF" "2019-20-blkG" "2019-20-blkH" "2019-20-blkI" "2019-20-blkJ"
#> [11] "2020-21-blkA" "2020-21-blkB" "2020-21-blkC" "2020-21-blkD" "2020-21-blkE"
#> [16] "2020-21-blkF" "2020-21-blkG" "2020-21-blkH" "2020-21-blkI" "2020-21-blkJ"
#> [21] "2021-22-blkA" "2021-22-blkB" "2021-22-blkC" "2021-22-blkD" "2021-22-blkE"
#> [26] "2021-22-blkF" "2021-22-blkG" "2021-22-blkH" "2021-22-blkI" "2021-22-blkJ"
#> [31] "2022-23-blkA" "2022-23-blkB" "2022-23-blkC" "2022-23-blkD" "2022-23-blkE"
#> [36] "2022-23-blkF" "2022-23-blkG" "2022-23-blkH" "2022-23-blkI" "2022-23-blkJ"

tbl(con, "2019-20-blkA") %>%
  group_by(a9) %>%
  mutate(
    a9chr = case_when(
      a9 == 1L ~ "Rural",
      a9 == 2L ~ "Urban",
      TRUE ~ as.character(NA)
    )
  ) %>%
  summarise(mwdays = mean(mwdays, na.rm = TRUE)) %>%
  collect()
#> # A tibble: 2 × 2
#>      a9 mwdays
#>   <dbl>  <dbl>
#> 1     2   233.
#> 2     1   226.

dbDisconnect(con, shutdown = TRUE)
```
