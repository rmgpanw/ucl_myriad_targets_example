# Design decisions

This document records the architectural choices made for running a
targets + crew.cluster pipeline on UCL MYRIAD, including approaches that
were tried and why they failed.

## The problem

We need the **controller** process (which runs `targets::tar_make()`) to be able
to call `qsub` to submit SGE worker jobs. At the same time, workers need a
reproducible R environment with all analysis packages — best provided by an
Apptainer (Singularity) container.

The challenge is that MYRIAD runs **RHEL 7.9** while our container is built on
**Ubuntu 22.04**. These two systems have fundamentally incompatible shared
libraries (glibc, libssl, etc.).

## What we tried

### Approach 1: Everything inside the container (FAILED)

**Idea**: Run both the controller *and* workers inside Apptainer. Bind-mount
SGE's `/opt/sge` into the container so the controller can call `qsub`.

**Commits**: `727b7a4` → `7b2c0c0`

**What happened**:

1. **Bind-mount `/opt/sge` only** (`727b7a4`): `qsub` failed —
   missing `libmunge.so.2`.

2. **Add `/usr/lib64/libmunge.so.2`** (`0de48a2`): `qsub` then needed
   `libssl.so.10`, `libcrypto.so.10`, and many more RHEL libraries.

3. **Bind-mount `/lib64` directly** (`2801f28`): This broke R itself — the
   Ubuntu container's dynamic linker tried to load RHEL's `glibc` (2.17),
   but R was compiled against Ubuntu's `glibc` (2.35). Result:
   ```
   /lib/x86_64-linux-gnu/libc.so.6: version `GLIBC_2.34' not found
   ```

4. **Bind to `/host_lib64` + selective `LD_LIBRARY_PATH`** (`7910a33`): Even
   when isolating the RHEL libraries to a separate mount point and only setting
   `LD_LIBRARY_PATH` for `qsub` calls, the symbol tables were incompatible:
   ```
   symbol lookup error: /host_lib64/libpthread.so.0:
     undefined symbol: _dl_make_stack_executable, version GLIBC_PRIVATE
   ```

5. **Wrapper scripts for qsub/qstat/qdel** (`7b2c0c0`): Created shell wrappers
   in `scripts/wrappers/` that set `LD_LIBRARY_PATH` only for the SGE binary
   call. Same `GLIBC_PRIVATE` symbol error — the RHEL `.so` files are
   fundamentally ABI-incompatible with the Ubuntu container's dynamic linker.

**Root cause**: You cannot mix glibc versions within a single process's
address space. The RHEL 7.9 host libraries (`glibc` 2.17) and the Ubuntu 22.04
container libraries (`glibc` 2.35) have incompatible ABIs. No amount of
`LD_LIBRARY_PATH` isolation can fix this because the dynamic linker itself
differs.

**Possible workaround** (not attempted): Build the container from a
**RHEL 7 / CentOS 7** base image instead of Ubuntu. If the container uses the
same glibc version as the host, bind-mounting `/opt/sge` and `/lib64` would
work. However, CentOS 7 is EOL, and finding up-to-date R packages and system
libraries would be harder.

### Approach 2: Native controller + containerised workers (WORKS)

**Idea**: Run the controller **natively** using MYRIAD's R module (`module load
r/4.5.1-openblas/gnu-10.2.0`). The controller has direct access to `qsub`.
Workers are submitted as SGE jobs that run inside the Apptainer container.

**Commit**: `e1985b3`

**How it works**:

1. The controller job (`scripts/run_pipeline_myriad.sh`) loads MYRIAD's R module
   and runs `targets::tar_make()` natively.

2. `_targets_config.R` defines a `crew.cluster::crew_controller_sge()` with
   `script_lines` that include the `apptainer exec ... \` command. The trailing
   backslash (`\`) is critical — crew appends `Rscript -e 'crew::crew_worker(...)'`
   on the next line, making it the command argument to `apptainer exec`.

3. Workers run inside the container with the full analysis environment.
   `RENV_ACTIVATE_PROJECT=FALSE` prevents renv from interfering with the
   container's pre-installed packages.

**Result**: 22 targets completed successfully (11m 15s), with crew submitting
SGE worker jobs that executed inside Apptainer containers.

## The trailing backslash trick

The key insight for making `crew.cluster` work with containers is the
`script_lines` trailing backslash. crew.cluster generates a job script like:

```bash
#!/bin/bash
#$ -l h_rt=1:00:00
#$ -l mem=4G
...
module load apptainer
apptainer exec --bind ... --env ... /path/to.sif \
Rscript -e 'crew::crew_worker("...", ...)'
```

The `\` at the end of the `apptainer exec` line continues onto the
crew-generated `Rscript` line, so the R command runs **inside** the container.
Without it, `apptainer exec` and `Rscript` would be two separate commands, and
the worker would run outside the container using MYRIAD's native R (which lacks
the analysis packages).

This pattern was identified from
[crew.cluster discussion #35](https://github.com/wlandau/crew.cluster/discussions/35).

## Controller package requirements

The native controller only needs orchestration packages:

- **targets**, **tarchetypes** — pipeline definition
- **crew**, **crew.cluster** — worker management via SGE
- **dplyr**, **purrr**, **rlang**, **cli** — referenced by `tar_option_set(packages = ...)`
  and helper function definitions
- **quarto** — R package (not CLI) needed by `tarchetypes::tar_quarto()` at
  definition time

These are installed once via `scripts/install_controller_packages.R`. The heavy
analysis packages (and Quarto CLI) live only in the container.

## Other issues encountered

### TMPDIR inside containers

SGE sets `TMPDIR` to a node-local path (e.g. `/tmpdir/job/123456/user`) that
does not exist inside the Apptainer container. This breaks Quarto's Deno
runtime, which writes to `TMPDIR`. Fix: override with a project-local
directory via `--env TMPDIR=${PROJECT_DIR}/tmp`.

### renv + rig library paths

rig installs R to `/opt/R/4.4.2/` rather than `/usr/local/`. When building the
Docker image, `renv::restore()` must be told to install to the correct library:
```r
renv::restore(library = R.home('library'), prompt = FALSE)
```

Setting `ENV RENV_ACTIVATE_PROJECT=FALSE` in the Dockerfile (and at runtime
via `--env`) prevents renv from redirecting `.libPaths()` to a project-local
library, letting R find the container's pre-installed packages directly.

### renv implicit snapshot and indirect dependencies

`renv::snapshot(type = "implicit")` only captures packages that appear in
`library()` or `pkg::fn()` calls within project files. Packages required
indirectly (e.g. `crew.cluster` loaded via `_targets_config.R`, `quarto`
loaded by `tarchetypes::tar_quarto()`) may be missed.

Fix: create an `_additional_packages.R` file with explicit `library()` calls
for indirect dependencies so they appear in `renv.lock`:
```r
library(crew.cluster)
library(quarto)
library(xml2)
```

### crew.cluster API deprecations

In `crew.cluster` >= 0.3.2, `script_lines`, `sge_log_output`, and
`sge_log_error` are deprecated in favour of the `options_cluster` argument.
The deprecated arguments still work but emit warnings. TODO: migrate to the
new API.

## Considerations for migrating a real pipeline

For a production pipeline (e.g. one using `devtools::install("mrpipeline")`
and `tar_option_set(imports = "mrpipeline")`), the controller would also need
the pipeline package and all its dependencies installed natively. Options:

1. **Conditional install**: Set a flag in `_targets_config.R`
   (`install_mrpipeline <- FALSE`) to skip `devtools::install()` on HPC, where
   the package is pre-installed in the controller's library.

2. **Replace `imports` with `tar_source()`**: Source the package's R files
   directly instead of loading as a package namespace. Simpler for HPC but
   loses automatic change detection.

3. **RHEL-based container**: If the container matched MYRIAD's OS, the
   bind-mount approach (Approach 1) would work, avoiding the need for any
   native R packages.

4. **Install everything natively**: Use renv + MYRIAD's R module for all
   packages (no container). Simpler but less reproducible — at the mercy of
   MYRIAD's system libraries and module versions.
