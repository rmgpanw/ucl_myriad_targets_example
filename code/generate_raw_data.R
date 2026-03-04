# generate_raw_data.R — Create a small CSV per item (format = "file" target)

generate_raw_data <- function(item_id) {
  dir <- "output/raw"
  if (!dir.exists(dir)) dir.create(dir, recursive = TRUE)

  outfile <- file.path(dir, paste0(item_id, ".csv"))

  df <- data.frame(
    item_id = item_id,
    x = stats::rnorm(100),
    y = stats::rnorm(100)
  )

  utils::write.csv(df, outfile, row.names = FALSE)
  outfile
}
