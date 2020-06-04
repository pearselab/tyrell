# Headers
source("../../src/packages.R")
source('Italy/code/utils/read-data-subnational.r')
source('Italy/code/utils/process-covariates-italy.r')

args = c('base-italy', 'google', 'interventions',
         '~ -1 + residential + transit + averageMobility',
         '~ -1 + residential + transit + averageMobility'
         ) 


cat(sprintf("Running:\nMobility = %s\nInterventions = %s\nFixed effects:%s\nRandom effects:%s\n\n",
            args[2],args[3], args[4],args[5]))

# Read deaths data for regions
d <- read_obs_data()
regions<-unique(as.factor(d$country))

# Read ifr 
ifr.by.country <- read_ifr_data(unique(d$country))
ifr.by.country <- ifr.by.country[1:22,]

# Read google mobility, apple mobility, interventions, stringency
google_mobility <- read_google_mobility("Italy")
mobility<-google_mobility[which(google_mobility$country!="Italy"),]

# Read interventions
interventions <- read_interventions()
interventions<-interventions[which(interventions$Country!="Italy"),]


# Table 1 and top 7
regions_sum <- d %>% group_by(country) %>% summarise(Deaths=sum(Deaths)) %>%
  inner_join(ifr.by.country) %>% mutate(deathsPer1000=Deaths/popt) %>% 
  arrange(desc(deathsPer1000))
regions_sum <- regions_sum[,-which(colnames(regions_sum) %in% c("X"))]
regions_sum$ifr<-signif(regions_sum$ifr*100,2)
regions_sum$deathsPer1000 <- signif(regions_sum$deathsPer1000*1000,2)

top_7 <- regions_sum[1:7,]

forecast <- 7 # increaseto get correct number of days to simulate
# Maximum number of days to simulate
N2 <- (max(d$DateRep) - min(d$DateRep) + 1 + forecast)[[1]]

formula = as.formula(args[4])
formula_partial = as.formula(args[5])
processed_data <- process_covariates(regions = regions, mobility = mobility, intervention = interventions, 
                                     d = d , ifr.by.country = ifr.by.country, N2 = N2, formula = formula, formula_partial = formula_partial)

stan_data <- processed_data$stan_data
dates <- processed_data$dates
reported_deaths <- processed_data$deaths_by_country
reported_cases <- processed_data$reported_cases

# Add envirionmental data
states <- readRDS("../../clean-data/gadm-states.RDS")
states <- states[states$NAME_0=="Italy",]
states$NAME_1 <- gsub(" ", "_", states$NAME_1)
states$NAME_1[states$NAME_1=="Lombardia"] <- "Lombardy"
states$NAME_1[states$NAME_1=="Trentino-Alto_Adige"] <- "Trento"
states$NAME_1[states$NAME_1=="Piemonte"] <- "Piedmont"
states$NAME_1[states$NAME_1=="Sardegna"] <- "Sardinia"
states$NAME_1[states$NAME_1=="Toscana"] <- "Tuscany"
states$NAME_1[states$NAME_1=="Valle_d'Aosta"] <- "Aosta"
match <- match(regions, states$NAME_1)
# Manually add in Bolzano, which is a city
match[is.na(match)] <- which(states$NAME_1=="Trento")
states <- states[match,]
env_dat <- readRDS("../../clean-data/worldclim-states.RDS")[states$GID_1,,"tmean"]
env_dat <- env_dat[,rep(1:6, c(4,29,31,30,30,6))]
stan_data$env_dat <- scale(t(env_dat))

options(mc.cores = parallel::detectCores())
rstan_options(auto_write = TRUE)
m = stan_model('stan-models/stan-italy.stan')

fit = sampling(m,data=stan_data,iter=2000,warmup=1500,chains=4,thin=1,control = list(adapt_delta = 0.95, max_treedepth = 15))

out <- rstan::extract(fit)
estimated_cases_raw <- out$prediction
estimated_deaths_raw <- out$E_deaths
estimated_deaths_cf <- out$E_deaths0

regions <- unique(d$country)


# This is a hack to get it to save
states = regions

covariate_data = list(interventions, mobility)

save(fit, dates, reported_cases, reported_deaths, regions, states, 
     estimated_cases_raw, estimated_deaths_raw, estimated_deaths_cf, stan_data, covariate_data,
     file='results/env-italy-stanfit.Rdata')
