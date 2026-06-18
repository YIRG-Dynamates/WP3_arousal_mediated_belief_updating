
## PLOTTING MODEL FREE PLOTSSSS


tbl_all <- read.table("C:/Users/rfleischmann/Desktop/DATA/RAW THINGS/motion+localization (WP3)/PROC DATA/tbl_all.txt", header = TRUE, sep = "\t")


#### packages needed for transformation and stuff ####
pacman::p_load(lme4, nlme, tidyverse, lmerTest, gridExtra, forecast, ggplot2, bayestestR, plotly, ggthemes, tidyverse, MuMIn)

# zscore and boxcox

subjects_all <- unique(tbl_all$sbj)

# transform per person
tbl_all$deltas <- tbl_all$deltas + 2500
tbl_all_bcox <- tbl_all # adding constant for boxcoc transformation

for (subject in subjects_all){
  current_idx <- tbl_all$sbj == subject #indexing the current subject
  tbl_all_bcox$surp[current_idx] <- BoxCox(tbl_all$surp[current_idx], lambda = "auto") #transform surprise
  tbl_all_bcox$deltas[current_idx] <- BoxCox(tbl_all$deltas[current_idx], lambda = "auto") #transform deltas
  print(subject)
}

# zscoring per person
tbl_all_bcox_zscore <- tbl_all_bcox

for (subject in subjects_all){
  current_idx <- tbl_all$sbj == subject #indexing the current subject
  tbl_all_bcox_zscore$surp[current_idx] <- scale(tbl_all_bcox$surp[current_idx], center = TRUE, scale = TRUE) #this is the zscoring - surprise
  tbl_all_bcox_zscore$deltas[current_idx] <- scale(tbl_all_bcox$deltas[current_idx], center = TRUE, scale = TRUE) #this is the zscoring - deltas
  print(subject)
}
### end ####

# absolute value of evidence to get rid of the latent state (sign)
tbl_all_bcox_zscore$evidence <- abs(tbl_all_bcox_zscore$evidence )

## 
tbl_all_bcox_zscore_quintile <- tbl_all_bcox_zscore %>%
  group_by(sbj) %>%
  mutate(quintile = ntile(evidence, 5))

tbl_all_bcox_zscore_quintile <- tbl_all_bcox_zscore_quintile %>%
  mutate(ev_hi_lo = case_when(
    quintile %in% c(1, 2) ~ 1,  # Convert 1 and 2 to 1
    quintile == 3 ~ 2,          # Convert 3 to 2
    quintile %in% c(4, 5) ~ 3   # Convert 4 and 5 to 3
  ))


### PLOT FOR BOTH DOMAINS; SEPERATED BY EVIDENCE

## calculate a medians and SEMs for subjects per sac

# Step 1: Calculate mean delta per evidence per sac for every subject
mean_table_both <- tbl_all_bcox_zscore_quintile %>%
  group_by(sbj, ev_hi_lo, sac) %>%
  summarize(mean_delta = mean(deltas), .groups = "drop")

# get rid of big SACs
mean_table_both <- mean_table_both %>%
  filter(sac <= 5)

# Step 2: Calculate SEM over medians for each SAC and evidence level
sem_table_both <- mean_table_both %>%
  group_by(ev_hi_lo, sac) %>%
  summarize(
    mean_mean = mean(mean_delta),
    sem = sd(mean_delta) / sqrt(n()),
    .groups = "drop"
  )


# Plot with both evidence levels in the same plot
ggplot(sem_table_both %>% filter(ev_hi_lo %in% c(1, 3)), 
       aes(x = sac, y = mean_mean, color = factor(ev_hi_lo))) +
  geom_point(size = 3) +
  geom_line() +
  geom_errorbar(aes(ymin = mean_mean - sem, ymax = mean_mean + sem), 
                width = 0.2) +
  scale_color_manual(values = c("1" = "blue", "3" = "red"),
                     labels = c("Low Evidence", "High Evidence")) +
  labs(
    x = "SAC",
    y = "Median Delta",
    color = "Evidence Level",
    title = "Mean Delta by SAC for High and Low Evidence",
    subtitle = "Error bars represent SEM over subjects: both domains"
  ) +
  theme_minimal()


### PLOT FOR SEPARATE DOMAINS; SEPERATED BY EVIDENCE


# Step 1: Calculate mean delta per evidence per sac for every subject
sem_table_seperate <- tbl_all_bcox_zscore_quintile %>%
  group_by(sbj, ev_hi_lo, sac, exp) %>%
  summarize(mean_delta = mean(deltas), .groups = "drop")

# get rid of big SACs
sem_table_seperate <- sem_table_seperate %>%
  filter(sac <= 5)

# Step 2: Calculate SEM over medians for each SAC and evidence level
sem_table_seperate <- sem_table_seperate %>%
  group_by(ev_hi_lo, sac, exp) %>%
  summarize(
    mean_mean = mean(mean_delta),
    sem = sd(mean_delta) / sqrt(n()),
    .groups = "drop"
  )




ggplot(sem_table_seperate %>% filter(ev_hi_lo %in% c(1, 3)), 
       aes(x = sac, y = mean_mean, color = factor(ev_hi_lo))) +
  geom_point(size = 3) +
  geom_line() +
  geom_errorbar(aes(ymin = mean_mean - sem, ymax = mean_mean + sem), 
                width = 0.2) +
  scale_color_manual(values = c("1" = "blue", "3" = "red"),
                     labels = c("Low Evidence", "High Evidence")) +
  labs(
    x = "SAC",
    y = "Mean Delta",
    color = "Evidence Level",
    title = "Mean Delta by SAC for Experimens",
    subtitle = "Error bars represent SEM over subjects"
  ) +
  facet_wrap(~exp, labeller = as_labeller(c("1" = "Motion", "2" = "Tempo"))) +
  theme_minimal()



## PLOT WITHOUT SEPERATION BETWEEN EVIDENCE

sem_table_both_noevidence <- tbl_all_bcox_zscore_quintile %>%
  group_by(sbj, exp, sac) %>%
  summarize(mean_delta = mean(deltas), .groups = "drop") 

# get rid of big SACs
sem_table_both_noevidence <- sem_table_both_noevidence %>%
  filter(sac <= 5)

# SEM calculated over the subjects of each exp
sem_table_both_noevidence_exp <- sem_table_both_noevidence %>%
  group_by(exp, sac) %>%
  summarize(
    mean_mean = mean(mean_delta), # Average delta per SAC and condition
    sem = sd(mean_delta) / sqrt(n()), # SEM over subjects
    .groups = "drop"
  )

# different SEM if calculated over all subjects
sem_table_both_noevidence_NOexp <- sem_table_both_noevidence %>%
  group_by(sac) %>%
  summarize(
    mean_mean = mean(mean_delta), # Average delta per SAC and condition
    sem = sd(mean_delta) / sqrt(n()), # SEM over subjects
    .groups = "drop"
  )


sem_table_both_noevidence_exp <- sem_table_both_noevidence_exp %>%
  mutate(group = as.character(exp)) # Use exp column as group label

sem_table_both_noevidence_NOexp <- sem_table_both_noevidence_NOexp %>%
  mutate(exp = 3) # Label combined data

# Move the 'exp' column to the first position
sem_table_both_noevidence_NOexp <- sem_table_both_noevidence_NOexp %>%
  select(exp, everything())

# bind together
plot_data <- bind_rows(sem_table_both_noevidence_exp, sem_table_both_noevidence_NOexp)

# make factor
sem_table_both_noevidence_NOexp <- sem_table_both_noevidence_NOexp %>%
  mutate(exp = factor(exp))



ggplot(plot_data, aes(x = sac, y = mean_mean, color = factor(exp))) +
  geom_point(size = 3) +  # Add points for the mean
  geom_line() +           # Connect the points with lines
  geom_errorbar(aes(ymin = mean_mean - sem, ymax = mean_mean + sem), width = 0.2) +  # Error bars for SEM
  scale_color_manual(values = c("1" = "blue", "2" = "red", "3" = "green"), 
                     labels = c("Motion", "Temporal", "Both")) +  # Customize color and labels for exp
  labs(
    x = "SAC",
    y = "Mean Delta",
    color = "Experimental Condition",
    title = "Mean Delta by SAC for Different Experimental Conditions",
    subtitle = "Error bars represent SEM"
  ) +
  theme_minimal() +
  theme(legend.position = "top")  # Position the legend at the top

