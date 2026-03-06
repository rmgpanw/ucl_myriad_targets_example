# _targets_config.R — Machine-specific crew controller and thread settings
#
# This file is tracked for this example repo. In production pipelines,
# add it to .gitignore and let each developer create their own.

# ---------------------------------------------------------------------------
# Thread limiting (prevents oversubscription on multi-core machines)
# ---------------------------------------------------------------------------
ncores <- parallel::detectCores()

# ---------------------------------------------------------------------------
# Option 1: LOCAL (comment out to use SGE instead)
# ---------------------------------------------------------------------------
# crew_workers <- 4L
# threads_per_worker <- max(1L, floor(ncores / crew_workers))
#
# Sys.setenv(
#   OMP_NUM_THREADS = threads_per_worker,
#   OPENBLAS_NUM_THREADS = threads_per_worker
# )
#
# controller <- crew::crew_controller_local(
#   workers = crew_workers,
#   seconds_idle = 30
# )

# ---------------------------------------------------------------------------
# Option 2: SGE / UCL MYRIAD
# ---------------------------------------------------------------------------
crew_workers <- 4L
threads_per_worker <- 1L

Sys.setenv(
  OMP_NUM_THREADS = threads_per_worker,
  OPENBLAS_NUM_THREADS = threads_per_worker
)

sif_path <- file.path(Sys.getenv("HOME"), "Scratch", "ucl_myriad_targets_example", "ucl_myriad_targets_example.sif")
project_dir <- file.path(Sys.getenv("HOME"), "Scratch", "ucl_myriad_targets_example")

controller <- crew.cluster::crew_controller_sge(
  workers = crew_workers,
  seconds_idle = 120,
  script_lines = c(
    "#$ -l h_rt=1:00:00",
    "#$ -l mem=4G",
    "#$ -l tmpfs=2G",
    "#$ -pe smp 1",
    paste0("#$ -wd ", project_dir),
    "module load apptainer",
    # Trailing backslash: crew appends "Rscript -e 'crew::crew_worker(...)'"
    # on the next line, so it becomes the command argument to apptainer exec.
    paste0(
      "apptainer exec",
      " --bind ", project_dir, ":", project_dir,
      " --env RENV_ACTIVATE_PROJECT=FALSE",
      " --env TMPDIR=", project_dir, "/tmp",
      " ", sif_path, " \\"
    )
  ),
  sge_log_output = file.path(project_dir, "logs/"),
  sge_log_error = file.path(project_dir, "logs/")
)
