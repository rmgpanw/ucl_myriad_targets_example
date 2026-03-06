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

# Create logs and tmp directories
mkdir -p "${PROJECT_DIR}/logs" "${PROJECT_DIR}/tmp"

module load apptainer

# TMPDIR: SGE sets this to a node-local path that doesn't exist inside the
# container, causing Quarto (Deno) to fail. Override with a project-local tmp.
# /opt/sge: crew.cluster needs qsub to submit worker jobs from inside the
# container. Bind-mount the SGE installation and forward its env vars.
apptainer exec \
  --bind "${PROJECT_DIR}:${PROJECT_DIR}" \
  --bind "/opt/sge:/opt/sge" \
  --bind "/usr/lib64/libmunge.so.2:/usr/lib64/libmunge.so.2:ro" \
  --env RENV_ACTIVATE_PROJECT=FALSE \
  --env TMPDIR="${PROJECT_DIR}/tmp" \
  --env SGE_ROOT="${SGE_ROOT}" \
  --env SGE_CELL="${SGE_CELL}" \
  --env PATH="/opt/sge/bin/lx-amd64:${PATH}" \
  --env LD_LIBRARY_PATH="/usr/lib64:${LD_LIBRARY_PATH}" \
  "${SIF}" \
  Rscript -e "setwd('${PROJECT_DIR}'); targets::tar_make()"
