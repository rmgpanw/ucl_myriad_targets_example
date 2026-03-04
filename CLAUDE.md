# Project Conventions

## Language

- Use **British English** spelling in all prose
- R code identifiers are exempt

## R Coding Style

- Use `pkg::fn()` notation in `code/` files (no `library()` calls)
- Use the **targets** package for pipeline orchestration
- Prefer **tidyverse** functions: `dplyr`, `purrr`, `rlang`, `cli`

## Project Structure

- `code/` — R scripts with reusable functions for the targets pipeline
- `analyses/` — Quarto notebooks rendered as part of the website
- `scripts/` — Shell scripts for container builds and HPC submission

## Crew Controller

- Machine-specific controller defined in `_targets_config.R`
- Local mode: `crew::crew_controller_local()` (default)
- HPC mode: `crew.cluster::crew_controller_sge()` (uncomment in config)
