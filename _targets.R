# _targets.R — Minimal targets pipeline for HPC testing
# See _targets_config.R for machine-specific crew controller settings

library(targets)
library(tarchetypes)

# Source helpers
tar_source("code")

# Load machine-specific config (controller, thread settings)
source("_targets_config.R")

tar_option_set(
  packages = c("dplyr", "purrr", "rlang", "cli"),
  controller = controller
)

list(
  # 10 items for branching
  tar_target(items, paste0("item_", sprintf("%02d", 1:10))),

  # Generate a small CSV per item (format = "file")
  tar_target(
    raw_data,
    generate_raw_data(items),
    pattern = map(items),
    format = "file",
    iteration = "list"
  ),

  # Branched analysis — one per item

  tar_target(
    analysis,
    run_analysis(items, raw_data),
    pattern = map(items, raw_data),
    storage = "worker",
    retrieval = "worker",
    error = "continue",
    iteration = "list"
  ),

  # Aggregate all branch results
  tar_target(
    summary_table,
    make_summary(analysis)
  ),

  # Render Quarto website
  tar_quarto(website, path = ".")
)
