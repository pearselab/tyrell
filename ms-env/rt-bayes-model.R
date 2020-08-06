# Headers
source("../../src/packages.R")
source('usa/code/utils/read-data-usa.r')
source('usa/code/utils/process-covariates.r')
args = c('base-usa',
         '~ -1 + averageMobility + I(transit * transit_use) + residential',
         '~ 1 +  averageMobility',
         '~ -1 + I(transit * transit_use)'
         )

cat(sprintf("Running:\nStanModel = %s\nFixed effects:%s\nRandom effects regional:%s\nRandom effects state:%s\n",
            "env-usa",args[2],args[3], args[4]))


# Read JHU and NYT data
death_data <- read_death_data(source = "jhu", smooth = FALSE)
ny_data <- read_death_data(source = "nyt", smooth = FALSE)
ny_data <- ny_data[ny_data$code=='NY', ]

# NYT and JHU death data is different lengths
max_ny <- max(ny_data$date)
max_jhu <- max(death_data$date)
max_date <- min(max_ny, max_jhu)
death_data <- death_data[!death_data$code %in% c('NY'), ] 
death_data <- bind_rows(death_data, ny_data)
death_data <- death_data[which(death_data$date <= max_date),]

# Choose states
states <- unique(death_data$code)
# Read ifr 
ifr_by_state <- read_ifr_data()
# Read google mobility
mobility <- read_google_mobility()
# At times google has mobility na for some days in that cae you will need to impute those values
# else code will fail 
# read predictions of future days from foursquare
# if you need predictions from foursquare please run file mobility-regression.r in
# the folder usa/code/utils/mobility-reg
google_pred <- read.csv('usa/data/google-mobility-forecast.csv', stringsAsFactors = FALSE)
google_pred$date <- as.Date(google_pred$date, format = '%Y-%m-%d') 
google_pred$sub_region_2 <- ""
google_pred$country_region <- "United States"
google_pred$country_region_code <- "US"
colnames(google_pred)[colnames(google_pred) == 'state'] <- 'sub_region_1'
if (max(google_pred$date) > max(mobility$date)){
  google_pred <- google_pred[google_pred$date > max(mobility$date),]
  # reading mapping of states of csv
  un<-unique(mobility$sub_region_1)
  states_code = read.csv('usa/data/states.csv', stringsAsFactors = FALSE)
  google_pred$code = "!!"
  for(i in 1:length(un)){
    google_pred$code[google_pred$sub_region_1==un[i]] = states_code$Abbreviation[states_code$State==un[i]]
  }
  mobility <- rbind(as.data.frame(mobility),as.data.frame(google_pred[,colnames(mobility)]))
}


max_date <- max(mobility$date)
death_data <- death_data[which(death_data$date <= max_date),]

# read interventions
interventions <- readRDS('usa/data/covariates.RDS')
# read interventions lifted date
interventions_lifted <- readRDS('usa/data/covariates_ended.RDS')
# Number of days to forecast
forecast <- 0
# Maximum number of days to simulate
num_days_sim <- (max(death_data$date) - min(death_data$date) + 1 + forecast)[[1]]
formula = as.formula(args[2])
formula_partial_regional = as.formula(args[3])
formula_partial_state = as.formula(args[4])
processed_data <- process_covariates(states = states, 
                                     mobility = mobility,
                                     death_data = death_data , 
                                     ifr_by_state = ifr_by_state, 
                                     num_days_sim = num_days_sim, 
                                     interventions = interventions, 
                                     interventions_lifted = interventions_lifted,
                                     formula = formula, formula_partial_regional = formula_partial_regional,
                                     formula_partial_state = formula_partial_state)
stan_data <- processed_data$stan_data
saveRDS(processed_data, "../../ms-env/processed_data_usa.RDS")

# Add envirionmental data
env <- readRDS("../../clean-data/temp-midday-states.RDS")
pop <- readRDS("../../clean-data/population-density-states.RDS")
meta <- shapefile("../../clean-data/gadm-states.shp")
env <- env[meta$NAME_0=="United States",]
pop <- pop[meta$NAME_0=="United States",]
meta <- meta[meta$NAME_0=="United States",]
meta$code <- sapply(strsplit(meta$HASC_1, ".", fixed=TRUE), function(x) x[2])
env <- env[match(names(processed_data$reported_deaths), meta$code),]
pop <- log10(pop[match(names(processed_data$reported_deaths), meta$code)])
.pad <- function(x, pad.length)
    return(c(x, rep(x[length(x)], pad.length-length(x))))
env_time <- matrix(NA, nrow=nrow(env), ncol=115)
for(i in seq_len(nrow(env_time)))
    env_time[i,] <- .pad(env[i,as.character(processed_data$dates[[i]])], 115)
env_time <- (env_time-mean(env_time)) / sd(env_time)
pop <- as.numeric(scale(pop))
stan_data$env_time <- t(env_time); stan_data$pop_dat <- pop

dates <- processed_data$dates
reported_deaths <- processed_data$reported_deaths
reported_cases <- processed_data$reported_cases
options(mc.cores = parallel::detectCores())
rstan_options(auto_write = TRUE)
m <- stan_model('rt-bayes-model.stan')

Sys.time()
fit = sampling(m,data=stan_data,iter=10000,warmup=8000,chains=5,thin=1,control = list(adapt_delta = 0.98, max_treedepth = 15))
Sys.time()

covariate_data = list(interventions, mobility)

out <- rstan::extract(fit)
estimated_cases_raw <- out$prediction
estimated_deaths_raw <- out$E_deaths
estimated_deaths_cf <- out$E_deaths0

save(fit, dates, reported_cases, reported_deaths, states,
     estimated_cases_raw, estimated_deaths_raw, estimated_deaths_cf,
     formula, formula_partial_regional,formula_partial_state, stan_data,covariate_data, 
     file='results/rt-bayes.Rdata')
