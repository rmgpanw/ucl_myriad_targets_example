# Packages needed at runtime but not directly referenced in code.
# renv scans this file to include them in renv.lock.
library(crew.cluster)  # SGE controller (used in _targets_config.R)
library(quarto)        # required by tarchetypes::tar_quarto()
library(xml2)          # runtime dependency of crew.cluster
