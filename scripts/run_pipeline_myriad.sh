#!/bin/bash -l
#$ -l h_rt=2:00:00
#$ -l mem=4G
#$ -l tmpfs=2G
#$ -pe smp 1
#$ -N targets_controller
#$ -wd /home/rmgpanw/Scratch/ucl_myriad_targets_example
#$ -o logs/controller.log
#$ -e logs/controller.err

# Controller job — runs NATIVELY (not in container) so it can call qsub.
# Workers are submitted by crew.cluster and run inside the Apptainer container
# via script_lines in _targets_config.R.

set -euo pipefail

PROJECT_DIR="/home/${USER}/Scratch/ucl_myriad_targets_example"

# Create logs and tmp directories
mkdir -p "${PROJECT_DIR}/logs" "${PROJECT_DIR}/tmp"

# Use MYRIAD's system R (needs targets, crew, crew.cluster installed)
module purge
module load r/4.4.2-openblas/gnu-10.2.0

cd "${PROJECT_DIR}"
Rscript -e "targets::tar_make()"
