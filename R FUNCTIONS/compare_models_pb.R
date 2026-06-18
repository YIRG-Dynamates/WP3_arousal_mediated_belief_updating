compare_models_pb <- function(model1, model2, 
                              n_sim       = 100,
                              model1_name = "model1", 
                              model2_name = "model2",
                              seed        = 42) {
  
  set.seed(seed)
  
  # --- Observed LRT ---
  obs_lrt <- as.numeric(logLik(model1) - logLik(model2))
  
  # --- Bootstrap statistic ---
  make_lrt_stat <- function(m2) {
    function(m) {
      y_new    <- getME(m, "y")
      m2_refit <- refit(m2, y_new)
      as.numeric(logLik(m) - logLik(m2_refit))
    }
  }
  
  lrt_stat <- make_lrt_stat(model2)
  
  # --- Run bootstrap ---
  boot_out <- bootMer(
    model1,
    FUN      = lrt_stat,
    nsim     = n_sim,
    use.u    = FALSE,
    type     = "parametric",
    parallel = "snow",
    ncpus    = parallel::detectCores() - 1,
    seed     = seed
  )
  
  # --- Results ---
  p_one_sided  <- mean(boot_out$t >= obs_lrt)
  n_successful <- sum(!is.na(boot_out$t))
  
  cat("============================================================\n")
  cat("Parametric Bootstrap Model Comparison\n")
  cat("============================================================\n")
  cat("Model 1 (simulated from):", model1_name, "\n")
  cat("Model 2 (competitor):    ", model2_name, "\n")
  cat("Seed:                    ", seed, "\n")
  cat("------------------------------------------------------------\n")
  cat("logLik (model1):         ", as.numeric(logLik(model1)), "\n")
  cat("logLik (model2):         ", as.numeric(logLik(model2)), "\n")
  cat("Observed LRT:            ", round(obs_lrt, 4), "\n")
  cat("  (positive = model1 fits better)\n\n")
  cat("N simulations:           ", n_sim, "\n")
  cat("Successful sims:         ", n_successful, "/", n_sim, "\n")
  cat("Bootstrap p (1-sided):   ", round(p_one_sided, 4), "\n")
  cat("============================================================\n\n")
  
  # --- Return results invisibly (plot drawn later with shared axes) ---
  invisible(list(
    model1_name  = model1_name,
    model2_name  = model2_name,
    loglik_m1    = as.numeric(logLik(model1)),
    loglik_m2    = as.numeric(logLik(model2)),
    obs_lrt      = obs_lrt,
    boot_lrt     = boot_out$t,
    p_one_sided  = p_one_sided,
    n_successful = n_successful,
    n_sim        = n_sim,
    seed         = seed
  ))
}

plot_paraboot_results <- function(results, 
                                  save_path = "C:/Users/rfleischmann/Documents/GitHub/dynamates/modelling/spatiotemporal_comp_RF/paraboot_plots.png") {
  
  # --- Compute shared x-axis across all results ---
  all_lrt_values <- unlist(lapply(results, function(r) c(r$boot_lrt, r$obs_lrt)))
  x_min <- min(all_lrt_values, na.rm = TRUE)
  x_max <- max(all_lrt_values, na.rm = TRUE)
  x_pad <- (x_max - x_min) * 0.05
  x_lim <- c(x_min - x_pad, x_max + x_pad)
  
  # --- Save to PNG ---
  png(save_path, width = 1600, height = 2400, res = 150)
  par(mfrow = c(6, 1), mar = c(4, 4, 3, 1))
  
  for (r in results) {
    
    p_label <- ifelse(r$p_one_sided == 0 | r$p_one_sided < 1/r$n_sim,
                      paste0("p < .", formatC(1000/r$n_sim, width = 0), " (0/", r$n_sim, ")"),
                      ifelse(r$p_one_sided == 1,
                             paste0("p = 1.000 (", r$n_sim, "/", r$n_sim, ")"),
                             paste0("p = ", formatC(r$p_one_sided, digits = 3, format = "f"))))
    
    hist(r$boot_lrt,
         breaks = 40,
         xlim   = x_lim,
         main   = paste0("Null: ", r$model1_name, "  |  Alternative: ", r$model2_name),
         xlab   = paste0("logLik(", r$model1_name, ") - logLik(", r$model2_name, ")"),
         col    = "grey85",
         border = "white")
    
    abline(v = r$obs_lrt, col = "red",    lwd = 2, lty = 2)
    abline(v = 0,         col = "grey50", lwd = 1)
    
    legend("topright", cex = 0.75,
           legend = c(
             paste0("Observed LRT = ", round(r$obs_lrt, 2)),
             "LRT = 0",
             p_label
           ),
           col = c("red", "grey50", NA),
           lty = c(2, 1, NA),
           lwd = c(2, 1, NA))
  }
  
  dev.off()
  cat("Plots saved to:", save_path, "\n")
}