Code for all analyses for “Pupil dilation indicates arousal-related mediation of perceptual belief updating across auditory domains” - Fleischmann et al, 2026  

This repository contains all scripts to reproduce all results and plots found in our paper from the data found in:  https://osf.io/equ2b/  

This pipeline works from the already fitted variables, which can be found in the OSF repository to download. The Bayesian Direction CP Model itself can (if necessary) be accessed here in the folder: "bayesian_directoin_cp_model" (making use of functions in "specific to spatial experiment" and "specific to temporal experiment").  

For questions contact: Roman.Fleischmann@oeaw.ac.at or meijerdavid1@gmail.com  

Skripts are roughly executed in alphabetical/numerical order as follows:  

1. PREPROCESSING (Matlab):  
Contains preprocessing of the pupil data of the respective dataset, utilizes the PUPILs toolbox (H. Relaño-Iborra and P. Bækgaard, “PUPILS pipeline: A flexible Matlab toolbox for eyetracking and pupillometry data processing,” arXiv.org. Accessed: Sep. 05, 2024. [Online]. Available: https://arxiv.org/abs/2011.05118v1)  

	A1_UNPACK_AND_PREPROCESS_MOTION.m  
	A2_UNPACK_AND_PREPROCESS_TEMPO.m  

2. DECONVOLUTION-BASED PUPIL MODEL (Matlab):  
These scripts apply the deconvolution-based pupil model (MATLAB FUNCTIONS/pupil_model).  

	B1_PRF_FITTING_vers2023_motion.m  
	B2_PRF_FITTING_vers2023_tempo.m  

3. PLOTTING TRIALS (Matlab):  
These scripts produce plots of individual trials with the respective latent variables, such as Figure 2.  

	B3_PLOTTING_PUPILTRACE_AND_DELTAS.m  
	B4_PLOTTING_PUPILTRACE_AND_DELTAS_AND_LATENTS.m  

4. BEHAVIORAL ANALYSES (Matlab):  
These scripts contain all ANOVAs with their respective effect sizes and test for the respective assumptions.  

	D2_BEHAVIORAL_ACCURACY.m  
	D3_BEHAVIORAL_CONFIDENCE.m  

5. EXPORT FOR FURTHER ANALYSIS IN R (Matlab):  
This scripts exports all relevant measure in a convenient format, to be further processed in R  

	E1_EXP_4_R.m  

6. EFFECT SIZES FOR PUPIL MODEL AND BEHAVIORAL MODEL (Matlab):  
These scripts calculate predictive accuracies of the behavioral and the pupil model  

	F1_R_SQUARED.m  
	F2_R_SQUARED_BEHAVIOR.m  

7. CLUSTER BASED PERMUTATION ANALYSIS, MODELFREE (Matlab):  
This script utilizes the fieldtrip toolbox and performs the cluster-based permutation analyses, produces an output file with all test statistics as well as Figure 4.  

	G9_MODELFREE_CLUSTPERM.m  

8. REGRESSION ANALYSES (R):   
These scripts perform all regression analysis and model comparisons within nested models, they produce the relevant output found in Table 2  

	MIXED_EFFECTS_v4.R  
	MODELFREE_ANALYSIS.R  

9. MODEL COMPARISONS  (R):   
These scripts perform the Bayesian model comparison (producing the output for Table 3) as well as the frequentist analogue (producing the output and figure found in the supplement)  

	ACROSS_MODEL_COMPARISON.R  
	ACROSS_MODEL_COMPARISON_FREQUENTIST.R  

10. PLOTTING (R):  
These scripts separately produce, then combine, plots 3 and 5.  

	PLOTS_BEHAVIORAL.R  
	R_7_PLOTTING_RED_MODELS_SURPRISE_V2.R  
	R_9_PLOTTING_RED_MODELS_INFOGAIN.R  
	R_9_PLOTTING_ACCURACIES_AND_SAC_STUFF.R  


