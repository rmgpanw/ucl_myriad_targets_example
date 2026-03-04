# run_analysis.R — Branched analysis function (one per item)

run_analysis <- function(item_id, data_file) {
  start <- proc.time()

  # Read the raw data

df <- utils::read.csv(data_file)

  # Simulate ~30s of work

Sys.sleep(30)

  # Simple analysis: fit a linear model

fit <- stats::lm(y ~ x, data = df)

  elapsed <- (proc.time() - start)[["elapsed"]]

  list(
    item_id = item_id,
    n = nrow(df),
    intercept = stats::coef(fit)[["(Intercept)"]],
    slope = stats::coef(fit)[["x"]],
    r_squared = summary(fit)$r.squared,
    elapsed_secs = round(elapsed, 1),
    worker_pid = Sys.getpid()
  )
}
