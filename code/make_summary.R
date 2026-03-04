# make_summary.R — Aggregate branch results into a data.frame

make_summary <- function(analysis_results) {
  dplyr::bind_rows(analysis_results)
}
