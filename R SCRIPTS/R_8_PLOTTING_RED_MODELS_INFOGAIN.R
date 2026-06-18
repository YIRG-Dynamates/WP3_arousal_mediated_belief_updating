# this script is for plotting INFOGAIN differently than the other one :)


#### load stuff ####
pacman::p_load(lme4, nlme, tidyverse, lmerTest, gridExtra, forecast, ggplot2, bayestestR, plotly, ggthemes, tidyverse, MuMIn, grid, svglite)
#### end ####

# load stuff
df_all <- readRDS("C:/Users/rfleischmann/Desktop/DATA/RAW THINGS/motion+localization (WP3)/PROC DATA/tbl_all_bcox_zscore.rds")
both_domains_reduced_without_intercept <- readRDS("C:/Users/rfleischmann/Desktop/DATA/RAW THINGS/motion+localization (WP3)/PROC DATA/REGMODELS/nointer_both_reduced_delta_infog.rds") #path at ARI
summary(both_domains_reduced_without_intercept)


#### QUANTILING ####

# define limits for quantiles, these quantiles are over ALL infog values
qq <- quantile(df_all$infog, probs = seq(0, 1, 0.1))

# add column for quantiles
for (i in 1:10){
  df_all$quantile[df_all$infog >= qq[i]] <- i
}

#### SDs and SEMs per quantile ####

df_all_motion <- df_all %>% filter(exp == 1)
df_all_tempo <- df_all %>% filter(exp == 2)

## overwriting the quantiles with experiment specific quantilization
qq_motion <- quantile(df_all_motion$infog, probs = seq(0, 1, 0.1))
qq_tempo <- quantile(df_all_tempo$infog, probs = seq(0, 1, 0.1))


for (i in 1:10){
  df_all_motion$quantile_m[df_all_motion$infog >= qq_motion[i]] <- i
  df_all_tempo$quantile_t[df_all_tempo$infog >= qq_tempo[i]] <- i
}

## QUANTILING END
## MAKE AVERAGES AND SEMS P.P.

#initialize
subjects_motion <- unique(df_all_motion$sbj)
subjects_tempo <- unique(df_all_tempo$sbj)
quantiles <-1:10

# averages per person an percentile (not quintile anymore)
delta_participant_m <- matrix(NA, ncol = length(quantiles), nrow = length(subjects_motion))
infog_participant_m <- matrix(NA, ncol = length(quantiles), nrow = length(subjects_motion))
delta_participant_t <- matrix(NA, ncol = length(quantiles), nrow = 27)
infog_participant_t <- matrix(NA, ncol = length(quantiles), nrow = 27)

for (subject in subjects_motion){
  for (i in quantiles){
    
    delta_participant_m[subject-100, i] <- mean(df_all_motion$deltas[
      df_all_motion$quantile == i & df_all_motion$sbj == subject
    ])
    
    infog_participant_m[subject-100, i] <- mean(df_all_motion$infog[
      df_all_motion$quantile == i & df_all_motion$sbj == subject
    ])
  }
}

for (subject in subjects_tempo){
  for (i in quantiles){
    
    delta_participant_t[subject-200, i] <- mean(df_all_tempo$deltas[
      df_all_tempo$quantile == i & df_all_tempo$sbj == subject
    ])
    
    infog_participant_t[subject-200, i] <- mean(df_all_tempo$infog[
      df_all_tempo$quantile == i & df_all_tempo$sbj == subject
    ])
  }
}

#Deltas averaged per percentile, average from each subjects average
Avg_delta_m <- colMeans(delta_participant_m, na.rm = TRUE)
Avg_delta_t <- colMeans(delta_participant_t, na.rm = TRUE)
Avg_infog_m <- colMeans(infog_participant_m, na.rm = TRUE)
Avg_infog_t <- colMeans(infog_participant_t, na.rm = TRUE)

plot(Avg_delta_m)
plot(Avg_delta_t)

# Function to compute SEM
sem_fun <- function(x) {
  x <- x[!is.na(x)]  # remove NA values
  sd(x) / sqrt(length(x))
}

# Apply SEM function to each column
SEM_delta_m <- apply(delta_participant_m, 2, sem_fun)
SEM_delta_t <- apply(delta_participant_t, 2, sem_fun)


quantile_data_motion <- data.frame(quant_infog = c(1:10), Avg_delta = Avg_delta_m, SE_delta = SEM_delta_m, Avg_infog = Avg_infog_m)
quantile_data_tempo <- data.frame(quant_infog = c(1:10), Avg_delta = Avg_delta_t, SE_delta = SEM_delta_t, Avg_infog = Avg_infog_t)

#### EFFECTS FROM MODEL ####

fixed_effects <- fixef(both_domains_reduced_without_intercept)

# Create a dataset for plotting with 'infog' ranging from -3 to 3
plot_data <- data.frame(
  infog = seq(-3, 3, length.out = 100)  # Range of 'infog' from -3 to 3
)

# Calculate predicted values using the fixed effects
plot_data$predicted <- fixed_effects["(Intercept)"] + 
  fixed_effects["infog"] * plot_data$infog

# Calculate standard errors for the predictions
# (This requires the model's variance-covariance matrix)
vcov_matrix <- vcov(both_domains_reduced_without_intercept)
X <- model.matrix(~ infog, data = plot_data)  # Design matrix
plot_data$se <- sqrt(diag(X %*% vcov_matrix %*% t(X)))  # Standard errors

# Calculate 95% confidence intervals
plot_data$ci_lower <- plot_data$predicted - 1.96 * plot_data$se
plot_data$ci_upper <- plot_data$predicted + 1.96 * plot_data$se


##### MAKING THE MAIN PLOT - infogrise ######

Q1min <- 0.042

mainplot_infog <- ggplot()+
  
  # this geom object predicts with a different model this might be wrong double check this
  # geom_smooth(data = df_all, aes(x = infog, y = deltas),
  #             method = "lm", level=0.95 , fullrange = TRUE, size = 1) +
  
  geom_ribbon(data = plot_data, 
              aes(x = infog, y = predicted, ymin = ci_lower, ymax = ci_upper), fill = "lightblue", alpha = 0.5) +  # Shaded CI
  
  geom_line(data = plot_data, 
            aes(x = infog, y = predicted),
            color = "darkgrey", linewidth = 1) +  # Regression line
  
  #dashed lines to mark the infog quintiles
  geom_vline(xintercept = qq[1], linetype = "dashed") +
  geom_vline(xintercept = qq[2], linetype = "dashed") +
  geom_vline(xintercept = qq[3], linetype = "dashed") +
  geom_vline(xintercept = qq[4], linetype = "dashed") +
  geom_vline(xintercept = qq[5], linetype = "dashed") +
  geom_vline(xintercept = qq[6], linetype = "dashed") +
  geom_vline(xintercept = qq[7], linetype = "dashed") +
  geom_vline(xintercept = qq[8], linetype = "dashed") +
  geom_vline(xintercept = qq[9], linetype = "dashed") +
  geom_vline(xintercept = qq[10], linetype = "dashed") +
  
  # boxplots for quintiles
  
  geom_point(data = quantile_data_motion,
             aes (x = Avg_infog, y=Avg_delta), colour="blue", alpha=0.9, size=2.5) +
  
  geom_errorbar(data = quantile_data_motion, 
                aes (x = Avg_infog, ymin = Avg_delta - SE_delta, ymax = Avg_delta + SE_delta), width=0.1, colour="blue", alpha=0.9, size=1) +
  
  geom_point(data = quantile_data_tempo,
             aes (x = Avg_infog, y=Avg_delta), colour="red", alpha=0.9, size=2.5) +
  
  geom_errorbar(data = quantile_data_tempo, 
                aes (x = Avg_infog, ymin = Avg_delta - SE_delta, ymax = Avg_delta + SE_delta), width=0.1, colour= "red", alpha=0.9, size=1) +
  
  
  # # text quintile 1
  # annotation_custom(grob = textGrob("Q1", gp = gpar(col = "black", fontsize = 12),
  #                                   just = "centre"), xmin = Avg_infog[1] , xmax = Avg_infog[1] , ymin = Q1min, ymax = 0.08)  +
  # # text quintile 2
  # annotation_custom(grob = textGrob("Q2", gp = gpar(col = "black", fontsize = 12),
  #                                   just = "centre"), xmin = Avg_infog[2] , xmax = Avg_infog[2] , ymin = Q1min, ymax = 0.08)  +
  # # text quintile 3
  # annotation_custom(grob = textGrob("Q3", gp = gpar(col = "black", fontsize = 12),
  #                                   just = "centre"), xmin = Avg_infog[3] , xmax = Avg_infog[3] , ymin = Q1min, ymax = 0.08)  +
  # # text quintile 4
  # annotation_custom(grob = textGrob("Q4", gp = gpar(col = "black", fontsize = 12),
  #                                   just = "centre"), xmin = Avg_infog[4] , xmax = Avg_infog[4] , ymin = Q1min, ymax = 0.08)  +
  # # text quintile 5
  # annotation_custom(grob = textGrob("Q5", gp = gpar(col = "black", fontsize = 12),
  #                                   just = "centre"), xmin = Avg_infog[5] , xmax = Avg_infog[5] , ymin = Q1min, ymax = 0.08)  +
  
  coord_cartesian(ylim=c(-0.07, 0.09), xlim=c(-2, 2)) + 
  
  ylab("Pupil Dilation") +
  xlab("Modelled Infogain") +
  theme(
    panel.grid = element_blank(),                        # Remove grid lines
    panel.background = element_rect(fill = "white"),     # Set white background
    plot.background = element_rect(fill = "white"),      # Set white background for entire plot area
    panel.border = element_rect(color = "black", fill = NA, linewidth = 1) # Add black frame around plot
  )


### saving
ggsave("C:\\Users\\rfleischmann\\Desktop\\DATA\\RAW THINGS\\motion+localization (WP3)\\PROC DATA\\PLOTS\\R_8_CENTRAL_PLOT_INFOGAIN_PUPILGAIN.svg", 
       plot = mainplot_infog, width = 6.2, height = 4, dpi = 300, device = "svg")
ggsave("C:\\Users\\rfleischmann\\Desktop\\DATA\\RAW THINGS\\motion+localization (WP3)\\PROC DATA\\PLOTS\\R_8_CENTRAL_PLOT_INFOGAIN_PUPILGAIN.png", 
       plot = mainplot_infog, width = 6.2, height = 4, dpi = 300, device = "png")


