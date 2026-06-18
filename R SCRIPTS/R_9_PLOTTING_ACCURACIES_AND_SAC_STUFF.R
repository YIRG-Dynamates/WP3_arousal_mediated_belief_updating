#PLOT ACCURACIES AND COMBINE WITH MAIN PLOT

#### load stuff ####
pacman::p_load(lme4, nlme, tidyverse, lmerTest, gridExtra, forecast, ggplot2, bayestestR, plotly, ggthemes, tidyverse, MuMIn, grid)
#### end ####


df_all <- readRDS("C:/Users/rfleischmann/Desktop/DATA/RAW THINGS/motion+localization (WP3)/PROC DATA/tbl_all_bcox_zscore.rds")


# set absicissa for all plots
absc <- 0.05

## add evidence-binary to df_all
## ones (1) mark high evidence (lowest and highest quartile, because evidence goes into the negative with direction changes)

# Initialize the new column
df_all$evidence_binary <- 0

# Unique subjects
subjects <- unique(df_all$sbj)

for (s in subjects) {
  # Subset for this subject
  subj_rows <- df_all$sbj == s
  subj_values <- df_all$evidence[subj_rows]
  
  # Compute quartiles
  q <- quantile(subj_values, probs = c(0.25, 0.75), na.rm = TRUE)
  
  # Mark rows in the lowest or highest quartile as 1
  df_all$evidence_binary[subj_rows] <- ifelse(subj_values <= q[1] | subj_values >= q[2], 1, 0)
}

# filter for motion and tempo
df_all_motion <- df_all %>% filter(exp == 1)
df_all_tempo <- df_all %>% filter(exp == 2)

########### plot other stuff over SAC levels ##############
########### PUPIL GAIN

SE_m <- c()
Avg_m <- c()
SE_t <- c()
Avg_t <- c()

# Unique subjects per dataset
subjects_m <- unique(df_all_motion$sbj)
subjects_t <- unique(df_all_tempo$sbj)

for (i in 1:5){
  # ---- Motion ----
  # Calculate mean per subject for this SAC
  subj_means_m <- sapply(subjects_m, function(s) {
    #median(df_all_motion$deltas[df_all_motion$sac == i & df_all_motion$sbj == s])
    mean(df_all_motion$deltas[df_all_motion$sac == i & df_all_motion$sbj == s])
    
  })
  
  # Compute overall mean and SEM across subjects
  Avg_m[i] <- mean(subj_means_m)
  #Avg_m[i] <- median(subj_means_m)
  SE_m[i] <- sd(subj_means_m) / sqrt(length(subj_means_m))
  
  # ---- Tempo ----
  subj_means_t <- sapply(subjects_t, function(s) {
    mean(df_all_tempo$deltas[df_all_tempo$sac == i & df_all_tempo$sbj == s])
    #median(df_all_tempo$deltas[df_all_tempo$sac == i & df_all_tempo$sbj == s])
  })
  
  Avg_t[i] <- mean(subj_means_t)
  SE_t[i] <- sd(subj_means_t) / sqrt(length(subj_means_t))
}

# combine the values to frame
sac_data_motion <- data.frame(sac = c(1:5), Avg_delta = Avg_m, SE_delta = SE_m)
sac_data_tempo <- data.frame(sac = c(1:5), Avg_delta = Avg_t, SE_delta = SE_t)


plot_delta <- ggplot()+
  
  
  geom_point(data = sac_data_tempo,
             aes ( x=sac - absc, y = Avg_delta), colour="red", alpha=0.9, size=2) +
  
  geom_line(data = sac_data_tempo,
            aes ( x=sac - absc, y = Avg_delta), colour="red", alpha=0.9, size=1) +
  
  geom_errorbar(data = sac_data_tempo, 
                aes (x=sac - absc, ymin = Avg_delta - SE_delta, ymax = Avg_delta + SE_delta), width=0.4, colour="red", alpha=0.9, size=1) +
  
  geom_point(data = sac_data_motion,
             aes ( x=sac + absc, y = Avg_delta), colour="blue", alpha=0.9, size=2)+
  
  geom_line(data = sac_data_motion,
            aes ( x=sac + absc, y = Avg_delta), colour="blue", alpha=0.9, size=1)+
  
  
  geom_errorbar(data = sac_data_motion, 
                aes (x=sac + absc, ymin = Avg_delta - SE_delta, ymax = Avg_delta + SE_delta), width=0.4, colour="blue", alpha=0.9, size=1) +
  
  
  ylab("Pupil Dilation") + 
  xlab("SAC") + 
  theme(
    panel.grid = element_blank(),                        # Remove grid lines
    panel.background = element_rect(fill = "white"),     # Set white background
    plot.background = element_rect(fill = "white"),      # Set white background for entire plot area
    panel.border = element_rect(color = "black", fill = NA, linewidth = 1) # Add black frame around plot
  )

################# SURPRISAL ##################

SE_m <- c()
Avg_m <- c()
SE_t <- c()
Avg_t <- c()

# Unique subjects per dataset
subjects_m <- unique(df_all_motion$sbj)
subjects_t <- unique(df_all_tempo$sbj)

for (i in 1:5){
  # ---- Motion ----
  subj_means_m <- sapply(subjects_m, function(s) {
    mean(df_all_motion$surp[df_all_motion$sac == i & df_all_motion$sbj == s])
  })
  Avg_m[i] <- mean(subj_means_m)
  SE_m[i] <- sd(subj_means_m) / sqrt(length(subj_means_m))
  
  # ---- Tempo ----
  subj_means_t <- sapply(subjects_t, function(s) {
    mean(df_all_tempo$surp[df_all_tempo$sac == i & df_all_tempo$sbj == s])
  })
  Avg_t[i] <- mean(subj_means_t)
  SE_t[i] <- sd(subj_means_t) / sqrt(length(subj_means_t))
}

sac_data_motion <- data.frame(sac = c(1:5), Avg_surp = Avg_m, SE_surp = SE_m)
sac_data_tempo <- data.frame(sac = c(1:5), Avg_surp = Avg_t, SE_surp = SE_t)

ylim_modelled1 <- -0.8
ylim_modelled2 <- 1.3

highty <- 0.2
plot_surp <- ggplot()+
  
  
  geom_point(data = sac_data_tempo,
             aes ( x=sac - absc, y = Avg_surp), colour="red", alpha=0.9, size=2) +
  
  geom_line(data = sac_data_tempo,
            aes ( x=sac - absc, y = Avg_surp), colour="red", alpha=0.9, size=1) +
  
  geom_errorbar(data = sac_data_tempo, 
                aes (x=sac - absc, ymin = Avg_surp - SE_surp, ymax = Avg_surp + SE_surp), width=0.4, colour="red", alpha=0.9, size=1) +
  
  geom_point(data = sac_data_motion,
             aes ( x=sac + absc, y = Avg_surp), colour="blue", alpha=0.9, size=2)+
  
  geom_line(data = sac_data_motion,
            aes ( x=sac + absc, y = Avg_surp), colour="blue", alpha=0.9, size=1) +
  
  geom_errorbar(data = sac_data_motion, 
                aes (x=sac + absc, ymin = Avg_surp - SE_surp, ymax = Avg_surp + SE_surp), width=0.4, colour="blue", alpha=0.9, size=1) +
  
  # rectangle SD
  annotate("rect", xmin =  3.9, xmax =  5.1, ymin = 0.82 + highty, ymax = 1.07 + highty, alpha = 1, fill = "white", color = "black", size = 1) +
  
  # text SD
  annotation_custom(grob = textGrob("temporal", gp = gpar(col = "red", fontsize = 12),
                                    just = "left"), xmin = 3, xmax = 5, ymin = 1 + highty, ymax = 1 + highty)  +
  # text SD
  annotation_custom(grob = textGrob("spatial", gp = gpar(col = "blue", fontsize = 12),
                                    just = "left"), xmin = 3, xmax = 5, ymin = 0.9 + highty, ymax = 0.9 + highty)  +
  
  
  ylab("Modelled Surprisal") + 
  xlab("SAC") + 
  coord_cartesian(ylim=c(ylim_modelled1,ylim_modelled2)) +
  theme(
    panel.grid = element_blank(),                        # Remove grid lines
    panel.background = element_rect(fill = "white"),     # Set white background
    plot.background = element_rect(fill = "white"),      # Set white background for entire plot area
    panel.border = element_rect(color = "black", fill = NA, linewidth = 1) # Add black frame around plot
  )

############################### INFO GAIN

SE_m <- c()
Avg_m <- c()
SE_t <- c()
Avg_t <- c()

# Unique subjects per dataset
subjects_m <- unique(df_all_motion$sbj)
subjects_t <- unique(df_all_tempo$sbj)

for (i in 1:5){
  # ---- Motion ----
  subj_means_m <- sapply(subjects_m, function(s) {
    mean(df_all_motion$infog[df_all_motion$sac == i & df_all_motion$sbj == s])
    #median(df_all_motion$infog[df_all_motion$sac == i & df_all_motion$sbj == s])
  })
  Avg_m[i] <- mean(subj_means_m)
  #Avg_m[i] <- median(subj_means_m)
  
  SE_m[i] <- sd(subj_means_m) / sqrt(length(subj_means_m))
  
  # ---- Tempo ----
  subj_means_t <- sapply(subjects_t, function(s) {
    mean(df_all_tempo$infog[df_all_tempo$sac == i & df_all_tempo$sbj == s])
  })
  Avg_t[i] <- mean(subj_means_t)
  SE_t[i] <- sd(subj_means_t) / sqrt(length(subj_means_t))
}

sac_data_motion_infog <- data.frame(sac = c(1:5), Avg_infog= Avg_m, SE_infog = SE_m)
sac_data_tempo_infog <- data.frame(sac = c(1:5), Avg_infog = Avg_t, SE_infog = SE_t)

plot_infog <- ggplot()+
  
  
  geom_point(data = sac_data_tempo_infog,
             aes ( x=sac - absc, y = Avg_infog), colour="red", alpha=0.9, size=2) +
  
  geom_line(data = sac_data_tempo_infog,
            aes ( x=sac - absc, y = Avg_infog), colour="red", alpha=0.9, size=1) +
  
  geom_errorbar(data = sac_data_tempo_infog, 
                aes (x=sac - absc, ymin = Avg_infog - SE_infog, ymax = Avg_infog + SE_infog), width=0.4, colour="red", alpha=0.9, size=1) +
  
  geom_point(data = sac_data_motion_infog,
             aes ( x=sac + absc, y = Avg_infog), colour="blue", alpha=0.9, size=2)+
  
  geom_line(data = sac_data_motion_infog,
            aes ( x=sac + absc, y = Avg_infog), colour="blue", alpha=0.9, size=1) +
  
  geom_errorbar(data = sac_data_motion_infog, 
                aes (x=sac + absc, ymin = Avg_infog - SE_infog, ymax = Avg_infog + SE_infog), width=0.4, colour="blue", alpha=0.9, size=1) +
  
  # rectangle SD
  annotate("rect", xmin =  3.9, xmax =  5.1, ymin = 0.82 + highty, ymax = 1.07 + highty, alpha = 1, fill = "white", color = "black", size = 1) +
  
  # text SD
  annotation_custom(grob = textGrob("temporal", gp = gpar(col = "red", fontsize = 12),
                                    just = "left"), xmin = 3, xmax = 5, ymin = 1 + highty, ymax = 1 + highty)  +
  # text SD
  annotation_custom(grob = textGrob("spatial", gp = gpar(col = "blue", fontsize = 12),
                                    just = "left"), xmin = 3, xmax = 5, ymin = 0.9 + highty, ymax = 0.9 + highty)  +
  
  ylab("Modelled Infogain") + 
  xlab("SAC") + 
  coord_cartesian(ylim=c(ylim_modelled1,ylim_modelled2)) +
  theme(
    panel.grid = element_blank(),                        # Remove grid lines
    panel.background = element_rect(fill = "white"),     # Set white background
    plot.background = element_rect(fill = "white"),      # Set white background for entire plot area
    panel.border = element_rect(color = "black", fill = NA, linewidth = 1) # Add black frame around plot
  )



### IMPORTING ACCURACY FRM MATLAB

accuracy_sac_sems_tempo <- scan("C:/Users/rfleischmann/Desktop/DATA/RAW THINGS/motion+localization (WP3)/PROC DATA/accuracy_sac_sems_tempo.txt")
accuracy_sac_sems_motion <- scan("C:/Users/rfleischmann/Desktop/DATA/RAW THINGS/motion+localization (WP3)/PROC DATA/accuracy_sac_sems_motion.txt")
accuracy_sac_means_tempo<- scan("C:/Users/rfleischmann/Desktop/DATA/RAW THINGS/motion+localization (WP3)/PROC DATA/accuracy_sac_means_tempo.txt")
accuracy_sac_means_motion<- scan("C:/Users/rfleischmann/Desktop/DATA/RAW THINGS/motion+localization (WP3)/PROC DATA/accuracy_sac_means_motion.txt")

### convert to percent, then to log scale
accuracy_sac_sems_tempo_lowerbound <- accuracy_sac_means_tempo - accuracy_sac_sems_tempo
accuracy_sac_sems_tempo_higherbound <- accuracy_sac_means_tempo + accuracy_sac_sems_tempo

accuracy_sac_sems_motion_lowerbound <- accuracy_sac_means_motion - accuracy_sac_sems_motion
accuracy_sac_sems_motion_higherbound <- accuracy_sac_means_motion + accuracy_sac_sems_motion

accuracy_sac_sems_tempo_lowerbound <- (accuracy_sac_sems_tempo_lowerbound * 100)
accuracy_sac_sems_tempo_higherbound <- (accuracy_sac_sems_tempo_higherbound * 100)
accuracy_sac_sems_motion_lowerbound <- (accuracy_sac_sems_motion_lowerbound * 100)
accuracy_sac_sems_motion_higherbound <- (accuracy_sac_sems_motion_higherbound * 100)

accuracy_sac_means_tempo <- (accuracy_sac_means_tempo * 100)
accuracy_sac_means_motion <- (accuracy_sac_means_motion * 100)

motionframe <- data.frame(sac = c(1:5), means_motion = accuracy_sac_means_motion, lowerbound = accuracy_sac_sems_motion_lowerbound, higherbound = accuracy_sac_sems_motion_higherbound)
tempoframe <- data.frame(sac = c(1:5), means_tempo = accuracy_sac_means_tempo, lowerbound = accuracy_sac_sems_tempo_lowerbound, higherbound = accuracy_sac_sems_tempo_higherbound)

chancelevel = 0.5 * 100

plot_acc <- ggplot()+
  
  
  geom_point(data = tempoframe,
             aes ( x=sac - absc, y = means_tempo), colour="red", alpha=0.9, size=2) +
  
  geom_line(data = tempoframe,
            aes ( x=sac - absc, y = means_tempo), colour="red", alpha=0.9, size=1) +
  
  geom_errorbar(data = tempoframe, 
                aes (x=sac - absc, ymin = lowerbound, ymax = higherbound), width=0.4, colour="red", alpha=0.9, size=1) +
  
  geom_point(data = motionframe,
             aes ( x=sac + absc, y = means_motion), colour="blue", alpha=0.9, size=2)+
  
  geom_line(data = motionframe,
            aes ( x=sac + absc, y = means_motion), colour="blue", alpha=0.9, size=1) +
  
  geom_errorbar(data = motionframe,
                aes (x=sac + absc, ymin = lowerbound, ymax = higherbound), width=0.4, colour="blue", alpha=0.9, size=1) +
  
  geom_hline(yintercept = chancelevel, linetype = "dashed") +
  
  ylab("Accuracy") + 
  xlab("SAC") + 
  coord_cartesian(ylim=c(0,100)) +
  #scale_y_log10(limits = c(1, 100)) +
  
  theme(
    panel.grid = element_blank(),                        # Remove grid lines
    panel.background = element_rect(fill = "white"),     # Set white background
    plot.background = element_rect(fill = "white"),      # Set white background for entire plot area
    panel.border = element_rect(color = "black", fill = NA, linewidth = 1) # Add black frame around plot
  )


######## IMPORTING PREDICTED ACCURACY FROM MATLAB

accuracy_pred_sac_sems_tempo <- scan("C:/Users/rfleischmann/Desktop/DATA/RAW THINGS/motion+localization (WP3)/PROC DATA/accuracy_pred_sac_sems_tempo.txt")
accuracy_pred_sac_sems_motion <- scan("C:/Users/rfleischmann/Desktop/DATA/RAW THINGS/motion+localization (WP3)/PROC DATA/accuracy_pred_sac_sems_motion.txt")
accuracy_pred_sac_means_tempo<- scan("C:/Users/rfleischmann/Desktop/DATA/RAW THINGS/motion+localization (WP3)/PROC DATA/accuracy_pred_sac_means_tempo.txt")
accuracy_pred_sac_means_motion<- scan("C:/Users/rfleischmann/Desktop/DATA/RAW THINGS/motion+localization (WP3)/PROC DATA/accuracy_pred_sac_means_motion.txt")

### convert to percent, then to log scale
accuracy_pred_sac_sems_tempo_lowerbound <- accuracy_pred_sac_means_tempo - accuracy_pred_sac_sems_tempo
accuracy_pred_sac_sems_tempo_higherbound <- accuracy_pred_sac_means_tempo + accuracy_pred_sac_sems_tempo

accuracy_pred_sac_sems_motion_lowerbound <- accuracy_pred_sac_means_motion - accuracy_pred_sac_sems_motion
accuracy_pred_sac_sems_motion_higherbound <- accuracy_pred_sac_means_motion + accuracy_pred_sac_sems_motion

accuracy_pred_sac_sems_tempo_lowerbound <- (accuracy_pred_sac_sems_tempo_lowerbound * 100)
accuracy_pred_sac_sems_tempo_higherbound <- (accuracy_pred_sac_sems_tempo_higherbound * 100)
accuracy_pred_sac_sems_motion_lowerbound <- (accuracy_pred_sac_sems_motion_lowerbound * 100)
accuracy_pred_sac_sems_motion_higherbound <- (accuracy_pred_sac_sems_motion_higherbound * 100)

accuracy_pred_sac_means_tempo <- (accuracy_pred_sac_means_tempo * 100)
accuracy_pred_sac_means_motion<- (accuracy_pred_sac_means_motion * 100)

tempoframe_pred <- data.frame(sac = c(1:5), means_tempo = accuracy_pred_sac_means_tempo, lowerbound = accuracy_pred_sac_sems_tempo_lowerbound, higherbound = accuracy_pred_sac_sems_tempo_higherbound)
motionframe_pred <- data.frame(sac = c(1:5), means_motion = accuracy_pred_sac_means_motion, lowerbound = accuracy_pred_sac_sems_motion_lowerbound, higherbound = accuracy_pred_sac_sems_motion_higherbound)


plot_acc_pred <- ggplot()+
  
  
  geom_point(data = tempoframe_pred,
             aes ( x=sac - absc, y = means_tempo), colour="red", alpha=0.9, size=2) +
  
  geom_line(data = tempoframe_pred,
            aes ( x=sac - absc, y = means_tempo), colour="red", alpha=0.9, size=1) +
  
  geom_errorbar(data = tempoframe_pred, 
                aes (x=sac - absc, ymin = lowerbound, ymax = higherbound), width=0.4, colour="red", alpha=0.9, size=1) +
  
  geom_point(data = motionframe_pred,
             aes ( x=sac + absc, y = means_motion), colour="blue", alpha=0.9, size=2)+
  
  geom_line(data = motionframe_pred,
            aes ( x=sac + absc, y = means_motion), colour="blue", alpha=0.9, size=1) +
  
  geom_errorbar(data = motionframe_pred,
                aes (x=sac + absc, ymin = lowerbound, ymax = higherbound), width=0.4, colour="blue", alpha=0.9, size=1) +
  
  geom_hline(yintercept = chancelevel, linetype = "dashed") +
  
  
  ylab("Modelled Accuracy") + 
  xlab("SAC") + 
  coord_cartesian(ylim=c(0,100)) +
  #scale_y_log10(limits = c(40, 100)) +
  
  
  

  theme(
    panel.grid = element_blank(),                        # Remove grid lines
    panel.background = element_rect(fill = "white"),     # Set white background
    plot.background = element_rect(fill = "white"),      # Set white background for entire plot area
    panel.border = element_rect(color = "black", fill = NA, linewidth = 1) # Add black frame around plot
  )


######### IMPORTING CONFIDENCE PLOT FROM MATLAB

tempo_conflevel_mean <- scan("C:\\Users\\rfleischmann\\Desktop\\DATA\\RAW THINGS\\motion+localization (WP3)\\PROC DATA\\tempo_conflevel_mean.txt")
tempo_conflevel_sem <- scan("C:\\Users\\rfleischmann\\Desktop\\DATA\\RAW THINGS\\motion+localization (WP3)\\PROC DATA\\tempo_conflevel_sem.txt")
tempo_post_d_mean <- scan("C:\\Users\\rfleischmann\\Desktop\\DATA\\RAW THINGS\\motion+localization (WP3)\\PROC DATA\\tempo_post_d_mean.txt")
tempo_post_d_sem <- scan("C:\\Users\\rfleischmann\\Desktop\\DATA\\RAW THINGS\\motion+localization (WP3)\\PROC DATA\\tempo_post_d_sem.txt")

motion_conflevel_mean <- scan("C:\\Users\\rfleischmann\\Desktop\\DATA\\RAW THINGS\\motion+localization (WP3)\\PROC DATA\\motion_conflevel_mean.txt")
motion_conflevel_sem <- scan("C:\\Users\\rfleischmann\\Desktop\\DATA\\RAW THINGS\\motion+localization (WP3)\\PROC DATA\\motion_conflevel_sem.txt")
motion_post_d_mean <- scan("C:\\Users\\rfleischmann\\Desktop\\DATA\\RAW THINGS\\motion+localization (WP3)\\PROC DATA\\motion_post_d_mean.txt")
motion_post_d_sem <- scan("C:\\Users\\rfleischmann\\Desktop\\DATA\\RAW THINGS\\motion+localization (WP3)\\PROC DATA\\motion_post_d_sem.txt")

SAC <- c(1,2,3,4,5)

# Create a data frame
df_motion <- data.frame(
  SAC = SAC,
  mean = motion_conflevel_mean,
  sem = motion_conflevel_sem,
  ymin = motion_conflevel_mean - motion_conflevel_sem,
  ymax = motion_conflevel_mean + motion_conflevel_sem
)

df_tempo <- data.frame(
  SAC = SAC,
  mean = tempo_conflevel_mean,
  sem = tempo_conflevel_sem,
  ymin = tempo_conflevel_mean - tempo_conflevel_sem,
  ymax = tempo_conflevel_mean + tempo_conflevel_sem
)

# Add condition columns to the dataframes
df_motion$condition <- "Motion"
df_tempo$condition <- "Tempo"




plot_conf <- ggplot()+
  
  geom_point(data = df_motion, 
             aes(x = SAC + absc, y = mean), colour="blue", alpha=0.9, size=2) +
  
  geom_line(data = df_motion,
            aes(x = SAC + absc, y = mean), colour="blue", alpha=0.9, size=1) +
  
  geom_errorbar(data = df_motion, 
                aes (x=SAC + absc, ymin = ymin, ymax = ymax), width=0.4, colour="blue", alpha=0.9, size=1) +

  geom_point(data = df_tempo, 
           aes(x = SAC - absc, y = mean), colour="red", alpha=0.9, size=2) +
  
  geom_line(data = df_tempo,
            aes(x = SAC - absc, y = mean), colour="red", alpha=0.9, size=1) +
  
  geom_errorbar(data = df_tempo, 
                aes (x=SAC - absc, ymin = ymin, ymax = ymax), width=0.4, colour="red", alpha=0.9, size=1) +
  
  
  ylab("Confidence Rating") + 
  xlab("SAC") + 
  coord_cartesian(ylim=c(1,4)) +
  theme(
    panel.grid = element_blank(),                        # Remove grid lines
    panel.background = element_rect(fill = "white"),     # Set white background
    plot.background = element_rect(fill = "white"),      # Set white background for entire plot area
    panel.border = element_rect(color = "black", fill = NA, linewidth = 1) # Add black frame around plot
  )



###################### zoon SAC level 1

df_all_tempo_sac1  <- df_all_tempo[df_all_tempo$sac == 1, ]
df_all_motion_sac1 <- df_all_motion[df_all_motion$sac == 1, ]

# Unique subjects in the SAC 1 subsets
subjects_t <- unique(df_all_tempo_sac1$sbj)
subjects_m <- unique(df_all_motion_sac1$sbj)

# ================ SURPRISAL FIRST
# ---- Tempo ----
# Low evidence (evidence_binary = 0)
subj_means_low_t <- sapply(subjects_t, function(s) {
  mean(df_all_tempo_sac1$surp[df_all_tempo_sac1$sbj == s & df_all_tempo_sac1$evidence_binary == 0])
})
Avg_low_t <- mean(subj_means_low_t, na.rm = TRUE)
SE_low_t <- sd(subj_means_low_t, na.rm = TRUE) / sqrt(length(subj_means_low_t))

# High evidence (evidence_binary = 1)
subj_means_high_t <- sapply(subjects_t, function(s) {
  mean(df_all_tempo_sac1$surp[df_all_tempo_sac1$sbj == s & df_all_tempo_sac1$evidence_binary == 1])
})
Avg_high_t <- mean(subj_means_high_t, na.rm = TRUE)
SE_high_t <- sd(subj_means_high_t, na.rm = TRUE) / sqrt(length(subj_means_high_t))

# ---- Motion ----
# Low evidence (evidence_binary = 0)
subj_means_low_m <- sapply(subjects_m, function(s) {
  mean(df_all_motion_sac1$surp[df_all_motion_sac1$sbj == s & df_all_motion_sac1$evidence_binary == 0])
})
Avg_low_m <- mean(subj_means_low_m, na.rm = TRUE)
SE_low_m <- sd(subj_means_low_m, na.rm = TRUE) / sqrt(length(subj_means_low_m))

# High evidence (evidence_binary = 1)
subj_means_high_m <- sapply(subjects_m, function(s) {
  mean(df_all_motion_sac1$surp[df_all_motion_sac1$sbj == s & df_all_motion_sac1$evidence_binary == 1])
})
Avg_high_m <- mean(subj_means_high_m, na.rm = TRUE)
SE_high_m <- sd(subj_means_high_m, na.rm = TRUE) / sqrt(length(subj_means_high_m))

# ---- MOTION ----
mean_low_m  <- mean(subj_means_low_m)
mean_high_m <- mean(subj_means_high_m)

sem_low_m  <- sd(subj_means_low_m)  / sqrt(length(subj_means_low_m))
sem_high_m <- sd(subj_means_high_m) / sqrt(length(subj_means_high_m))

# ---- TEMPO ----
mean_low_t  <- mean(subj_means_low_t)
mean_high_t <- mean(subj_means_high_t)

sem_low_t  <- sd(subj_means_low_t)  / sqrt(length(subj_means_low_t))
sem_high_t <- sd(subj_means_high_t) / sqrt(length(subj_means_high_t))

# --- plottinggggg ----
plot_df <- data.frame(
  Dataset = c("Motion", "Motion", "Tempo", "Tempo"),
  Evidence = c("Low", "High", "Low", "High"),
  Mean = c(mean_low_m, mean_high_m,
           mean_low_t, mean_high_t),
  SEM  = c(sem_low_m, sem_high_m,
           sem_low_t, sem_high_t)
)

plot_df$Evidence <- factor(plot_df$Evidence, levels = c("Low", "High"))

library(ggplot2)

surprisal_per_evidencelevel <- ggplot(plot_df,
       aes(x = Evidence,
           y = Mean,
           group = Dataset,
           color = Dataset)) +
  geom_line(size = 1.2) +
  geom_point(size = 3) +
  geom_errorbar(aes(ymin = Mean - SEM,
                    ymax = Mean + SEM),
                width = 0.08,
                size = 1) +
  labs(
    x = "Evidence",
    y = "Mean Surprisal ± SEM",
    title = "SAC 1 Surprisal: Low vs High Evidence"
  ) +
  theme_minimal(base_size = 14)

# ================ INFOGAIN NEXT
# ---- Tempo ----
# Low evidence (evidence_binary = 0)
subj_means_low_t <- sapply(subjects_t, function(s) {
  mean(df_all_tempo_sac1$infog[df_all_tempo_sac1$sbj == s & df_all_tempo_sac1$evidence_binary == 0])
})
Avg_low_t <- mean(subj_means_low_t, na.rm = TRUE)
SE_low_t <- sd(subj_means_low_t, na.rm = TRUE) / sqrt(length(subj_means_low_t))

# High evidence (evidence_binary = 1)
subj_means_high_t <- sapply(subjects_t, function(s) {
  mean(df_all_tempo_sac1$infog[df_all_tempo_sac1$sbj == s & df_all_tempo_sac1$evidence_binary == 1])
})
Avg_high_t <- mean(subj_means_high_t, na.rm = TRUE)
SE_high_t <- sd(subj_means_high_t, na.rm = TRUE) / sqrt(length(subj_means_high_t))

# ---- Motion ----
# Low evidence (evidence_binary = 0)
subj_means_low_m <- sapply(subjects_m, function(s) {
  mean(df_all_motion_sac1$infog[df_all_motion_sac1$sbj == s & df_all_motion_sac1$evidence_binary == 0])
})
Avg_low_m <- mean(subj_means_low_m, na.rm = TRUE)
SE_low_m <- sd(subj_means_low_m, na.rm = TRUE) / sqrt(length(subj_means_low_m))

# High evidence (evidence_binary = 1)
subj_means_high_m <- sapply(subjects_m, function(s) {
  mean(df_all_motion_sac1$infog[df_all_motion_sac1$sbj == s & df_all_motion_sac1$evidence_binary == 1])
})
Avg_high_m <- mean(subj_means_high_m, na.rm = TRUE)
SE_high_m <- sd(subj_means_high_m, na.rm = TRUE) / sqrt(length(subj_means_high_m))

# ---- MOTION ----
mean_low_m  <- mean(subj_means_low_m)
mean_high_m <- mean(subj_means_high_m)

sem_low_m  <- sd(subj_means_low_m)  / sqrt(length(subj_means_low_m))
sem_high_m <- sd(subj_means_high_m) / sqrt(length(subj_means_high_m))

# ---- TEMPO ----
mean_low_t  <- mean(subj_means_low_t)
mean_high_t <- mean(subj_means_high_t)

sem_low_t  <- sd(subj_means_low_t)  / sqrt(length(subj_means_low_t))
sem_high_t <- sd(subj_means_high_t) / sqrt(length(subj_means_high_t))

# --- plottinggggg ----
plot_df <- data.frame(
  Dataset = c("Motion", "Motion", "Tempo", "Tempo"),
  Evidence = c("Low", "High", "Low", "High"),
  Mean = c(mean_low_m, mean_high_m,
           mean_low_t, mean_high_t),
  SEM  = c(sem_low_m, sem_high_m,
           sem_low_t, sem_high_t)
)

plot_df$Evidence <- factor(plot_df$Evidence, levels = c("Low", "High"))

library(ggplot2)
infogain_per_evidencelevel <- ggplot(plot_df,
                                      aes(x = Evidence,
                                          y = Mean,
                                          group = Dataset,
                                          color = Dataset)) +
  geom_line(size = 1.2) +
  geom_point(size = 3) +
  geom_errorbar(aes(ymin = Mean - SEM,
                    ymax = Mean + SEM),
                width = 0.08,
                size = 1) +
  labs(
    x = "Evidence",
    y = "Mean Surprisal ± SEM",
    title = "SAC 1 Infogain: Low vs High Evidence"
  ) +
  theme_minimal(base_size = 14)

evidenceplots <- arrangeGrob(surprisal_per_evidencelevel, infogain_per_evidencelevel,  ncol = 2, widths = c(1,1))
grid.arrange(evidenceplots)
################# ARRANGING

# arrange after importing a main plot
grid.arrange(plot5,plot6,plot7, plotmain, ncol=4)  
grid.arrange(plot5, plot6, plot7, plotmain,
             ncol = 4, 
             widths = c(1, 1, 1, 2))  # Make the last plot twice as wide

grid.arrange(plot_acc, plot_delta, plot_surp, plot_infog, mainplot_infog, ncol=5, widths = c(1, 1, 1, 1, 2))  


library(gridExtra)

top_row <- arrangeGrob(plot_acc, plot_conf, plot_acc_pred, ncol = 3, widths = c(1,1,1))

middle_row <- arrangeGrob(plot_surp, plot_delta, plot_infog, ncol = 3, widths = c(1,1,1))

bottom_row <- arrangeGrob(mainplot_surp, mainplot_infog, ncol = 2, widths = c(1, 1))

grid.arrange(top_row, middle_row, bottom_row, ncol = 1, heights = c(1, 1, 1.5))



plot_combined <- grid.arrange(plot_acc, plot_conf ,plot_acc_pred, plot_surp, plot_delta, plot_infog,  ncol=3)  
plot_combined <- grid.arrange(top_row, middle_row, bottom_row, ncol = 1, heights = c(1, 1, 1.5))

plot_combined <- grid.arrange(middle_row, bottom_row, ncol = 1, heights = c(1, 1.5))

ggsave("C:\\Users\\rfleischmann\\Desktop\\DATA\\RAW THINGS\\motion+localization (WP3)\\PROC DATA\\PLOTS\\R_9_COMBINED_SAC_PLOTS_v3.png", 
       plot = plot_combined, width = 8, height = 6, dpi = 300, device = "png")
ggsave("C:\\Users\\rfleischmann\\Desktop\\DATA\\RAW THINGS\\motion+localization (WP3)\\PROC DATA\\PLOTS\\R_9_COMBINED_SAC_PLOTS_v3.svg", 
       plot = plot_combined, width = 8, height = 6, dpi = 300, device = "svg")


ALLFOURSACPLOTS <- grid.arrange(plot6,plot5,  plot7, confidenceSACplot, ncol=2)  

ggsave("G:/My Drive/WORK/PUBLICATIONS/WP3 MANUSCRIPT/PLOTS/ALLFOURSACPLOTS.png", 
       plot = ALLFOURSACPLOTS, width = 8 , height = 7, dpi = 300, device = "png")


## ARRANGING FOR ABSTRACT

right_grid <- arrangeGrob(
  plot_acc, plot_delta,
  plot_surp, plot_infog,
  ncol = 2
)

# Use grid layout to combine the large plot and the right-side small plots
final_layout <- grid.arrange(
  grobs = list(right_grid, mainplot_surp),
  layout_matrix = rbind(c(1, 1, 2, 2),
                        c(1, 1, 2, 2)),
  widths = c(1, 1, 1, 1),
  heights = c(1, 1)
)


ggsave("G:/My Drive/WORK/PUBLICATIONS/WP3 MANUSCRIPT/PLOTS/COMBINED_PLOTS_ABSTRACT.png", 
       plot = final_layout, width = 10, height = 3.5, dpi = 300, device = "png")
ggsave("G:/My Drive/WORK/PUBLICATIONS/WP3 MANUSCRIPT/PLOTS/COMBINED_PLOTS_ABSTRACT.svg", 
       plot = final_layout, width = 10, height = 3.5, dpi = 300, device = "svg")

