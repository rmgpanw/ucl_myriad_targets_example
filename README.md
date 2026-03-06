# ucl_myriad_targets_example

A minimal [targets](https://docs.ropensci.org/targets/) pipeline that exercises
[crew.cluster](https://wlandau.github.io/crew.cluster/) with SGE on
UCL MYRIAD. Use this to validate the full workflow —
build container, upload, submit, workers launch, targets complete — before
migrating a real pipeline.

## What it does

The pipeline creates 10 synthetic datasets, fits a linear model to each
(branched targets), aggregates results, and optionally renders a Quarto website.
Each analysis branch sleeps for 30 seconds to simulate real work.

## Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│  SGE controller job (native R on MYRIAD)                        │
│  • module load r/4.5.1-openblas/gnu-10.2.0                     │
│  • Has qsub/qstat/qdel access                                  │
│  • Runs targets::tar_make() — orchestrates only                │
│                                                                  │
│     ┌──── qsub ────▶ ┌─────────────────────────────────────┐   │
│     │                 │  SGE worker job (inside Apptainer)   │   │
│     │                 │  • Runs crew::crew_worker()          │   │
│     │                 │  • Full R environment in container   │   │
│     │                 │  • Executes analysis targets         │   │
│     │                 └─────────────────────────────────────┘   │
│     │                                                            │
│     ├──── qsub ────▶  [worker 2] ...                            │
│     ├──── qsub ────▶  [worker 3] ...                            │
│     └──── qsub ────▶  [worker N] ...                            │
└──────────────────────────────────────────────────────────────────┘
```

The controller runs **natively** (not in a container) so it has direct access
to SGE commands. Workers run **inside Apptainer containers** with the full
analysis environment. See [DESIGN.md](DESIGN.md) for why this split is
necessary and what alternatives were tried.

## Quick start: local (no HPC)

Run the pipeline on your own machine using `crew::crew_controller_local()`.

```bash
git clone https://github.com/rmgpanw/ucl_myriad_targets_example.git
cd ucl_myriad_targets_example
```

1. **Edit `_targets_config.R`** — uncomment the "Option 1: LOCAL" block and
   comment out the "Option 2: SGE / UCL MYRIAD" block.

2. **Restore packages** (first time only):
   ```r
   renv::restore()
   ```

3. **Run the pipeline**:
   ```r
   targets::tar_make()
   ```

## Quick start: local with Apptainer (single-node, no SGE)

Test the container without needing an HPC scheduler. This validates that the
SIF works and all packages are present.

```bash
# Build the container (requires Docker + Apptainer)
bash scripts/build_container.sh

# Run the pipeline inside the container
# First edit _targets_config.R to use Option 1 (LOCAL)
apptainer exec \
  --bind "$(pwd):$(pwd)" \
  --env RENV_ACTIVATE_PROJECT=FALSE \
  --env TMPDIR="$(pwd)/tmp" \
  ucl_myriad_targets_example.sif \
  Rscript -e "setwd('$(pwd)'); targets::tar_make()"
```

## Quick start: MYRIAD with SGE workers

### One-time setup

1. **Clone the repo on MYRIAD**:
   ```bash
   ssh myriad
   cd ~/Scratch
   git clone https://github.com/rmgpanw/ucl_myriad_targets_example.git
   cd ucl_myriad_targets_example
   mkdir -p logs tmp
   ```

2. **Upload the SIF** (from a machine with Docker + Apptainer):
   ```bash
   # On your local machine:
   bash scripts/build_container.sh
   scp ucl_myriad_targets_example.sif myriad:~/Scratch/ucl_myriad_targets_example/
   ```

3. **Install controller packages** (on MYRIAD, once):
   ```bash
   module purge && module load r/4.5.1-openblas/gnu-10.2.0
   Rscript scripts/install_controller_packages.R
   ```
   This installs ~9 orchestration packages (targets, crew, crew.cluster, etc.)
   into renv's project library. Takes ~60 minutes on first run (some packages
   compile from source on RHEL 7.9). Subsequent runs use the cache.

4. **Ensure `_targets_config.R` uses Option 2** (SGE). This is the default.

### Run the pipeline

```bash
# On MYRIAD:
cd ~/Scratch/ucl_myriad_targets_example
module purge && module load r/4.5.1-openblas/gnu-10.2.0
qsub scripts/run_pipeline_myriad.sh
```

### Monitor

```bash
# Check job status (controller + workers)
qstat -u $USER

# Watch controller log
tail -f ~/Scratch/ucl_myriad_targets_example/logs/controller.log

# Check worker logs
ls -lt ~/Scratch/ucl_myriad_targets_example/logs/crew-worker*
```

## Key files

| File | Purpose |
|------|---------|
| `_targets.R` | Pipeline definition (items → raw_data → analysis → summary) |
| `_targets_config.R` | Machine-specific crew controller (local vs SGE) |
| `code/` | Helper functions: `generate_raw_data.R`, `run_analysis.R`, `make_summary.R` |
| `Dockerfile` | Container image (Ubuntu 22.04 + rig + R 4.4.2 + Quarto + renv) |
| `scripts/build_container.sh` | Build Docker image → Apptainer SIF |
| `scripts/run_pipeline_myriad.sh` | SGE job script for the controller |
| `scripts/install_controller_packages.R` | One-time package install for MYRIAD's native R |
| `DESIGN.md` | Architecture decisions and failed approaches |

## Design decisions

See [DESIGN.md](DESIGN.md) for detailed documentation of the architecture,
including what was tried and why certain approaches failed.
