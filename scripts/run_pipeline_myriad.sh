#!/bin/bash -l
#$ -l h_rt=2:00:00
#$ -l mem=4G
#$ -l tmpfs=2G
#$ -pe smp 1
#$ -N targets_controller
#$ -wd /home/rmgpanw/Scratch/ucl_myriad_targets_example
#$ -o logs/controller.log
#$ -e logs/controller.err

# Controller job — submits SGE workers via crew.cluster
# Workers are launched by crew, not by this script.

set -euo pipefail

PROJECT_DIR="/home/${USER}/Scratch/ucl_myriad_targets_example"
SIF="${PROJECT_DIR}/ucl_myriad_targets_example.sif"

# Create logs directory
mkdir -p "${PROJECT_DIR}/logs"

module load singularity-env

singularity exec \
  --bind "${PROJECT_DIR}:${PROJECT_DIR}" \
  "${SIF}" \
  Rscript -e "setwd('${PROJECT_DIR}'); targets::tar_make()"
