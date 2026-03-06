# install_controller_packages.R
#
# Run this ONCE on MYRIAD after loading the R module:
#   module purge && module load r/4.5.1-openblas/gnu-10.2.0
#   Rscript scripts/install_controller_packages.R
#
# The controller runs natively (not in a container) so it can call qsub.
# It only needs packages for pipeline orchestration — the heavy analysis
# packages live inside the Apptainer container where workers run.

# Packages needed by the controller:
#   - targets, tarchetypes: pipeline definition
#   - crew, crew.cluster: worker orchestration via SGE
#   - dplyr, purrr, rlang, cli: used by tar_option_set(packages = ...)
#     and sourced helper functions (needed at pipeline-definition time)

pkgs <- c(

"targets",
  "tarchetypes",
  "crew",
  "crew.cluster",
  "dplyr",
  "purrr",
  "rlang",
  "cli"
)

# Use P3M binary repo for faster installs
options(repos = c(
  P3M = "https://p3m.dev/cran/latest",
  CRAN = "https://cloud.r-project.org"
))

install.packages(pkgs)

cat("\nInstalled packages:\n")
for (pkg in pkgs) {
  v <- tryCatch(packageVersion(pkg), error = function(e) "FAILED")
  cat(sprintf("  %-20s %s\n", pkg, v))
}
