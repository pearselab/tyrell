# Headers
source("src/packages.R")

# Load data
all_sqr_covariates <- readRDS("raw-data/denvfoimap-raster.RDS")

# Set parameters
extra_prms <- list(id_fld = "unique_id",
                   grp_flds = c("unique_id", "ID_0", "ID_1"),
                   ranger_threads = NULL,
                   fit_type = "boot",
                   parallel_2 = FALSE,
                   screening_ages = c(9, 16),
                   target_nm = c("I", "C", "HC", "R0_1", "R0_2"),
                   coord_limits = c(-74, -32, -34, 6))
my_col <- colorRamps::matlab.like(100)

# Variables that depend on parameters
parameters <- create_parameter_list(extra_params = extra_prms)
all_wgt <- parameters$all_wgt
all_predictors <- predictor_rank$name
base_info <- parameters$base_info
foi_offset <- parameters$foi_offset
coord_limits <- parameters$coord_limits
screening_ages <- parameters$screening_ages

# Pre-processing
foi_data$new_weight <- all_wgt
pAbs_wgt <- get_sat_area_wgts(foi_data, parameters)
foi_data[foi_data$type == "pseudoAbsence", "new_weight"] <- pAbs_wgt

# One bootstrap of data
foi_data_all_bsamples <- grid_and_boot(data_df = foi_data, parms = parameters)
foi_data_bsample <- foi_data_all_bsamples[[1]]

# Fit model (takes long time)
RF_obj_optim <- full_routine_bootstrap(parms = parameters,
                                       original_foi_data = foi_data,
                                       adm_covariates = admin_covariates,
                                       all_squares = all_sqr_covariates,
                                       covariates_names = all_predictors,
                                       boot_sample = foi_data_bsample)

# Save output
save.image("ml-env/analysis.RData")
