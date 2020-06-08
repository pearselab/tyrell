# For Michael
setwd("/home/michael/Documents/Grad School/Research Projects/Tyrell/imptf-models/covid19model-6.0")

source("../../src/packages.R")
source("Brazil/code/preprocessing-subnation-brazil.r")

####################################################################
#### Parameters to input:
forecast <- 7
N2 <- (max(as.Date(df$DateRep, format="%Y-%m-%d")) - min(as.Date(df$DateRep, format="%Y-%m-%d")) + 1 + forecast)[[1]]
countries <- c("RJ","SP","PE","CE","AM","BA","ES","MA","MG","PR","PA","RN","RS","SC","AL","PB")
####################################################################
processed_data <- process_data(countries,N2,df)
stan_data <- processed_data$stan_data
dates <- processed_data$dates
deaths_by_country <- processed_data$deaths_by_country
reported_cases <- processed_data$reported_cases

# Add envirionmental data
states <- readRDS("../../clean-data/gadm-states.RDS")
states <- states$polygons
states <- states[states$NAME_0=="Brazil",]
states <- states[states$NAME_1 %in% c("São Paulo","Rio de Janeiro","Pernambuco","Ceará","Amazonas","Pará","Maranhão","Bahia","Espírito Santo","Paraná","Minas Gerais","Paraíba","Rio Grande do Sul","Rio Grande do Norte","Alagoas","Santa Catarina"),] # List taken from table 1 in report
states$code <- toupper(substr(states$NAME_1, 0, 2))
states$code[states$NAME_1=="Rio de Janeiro"] <- "RJ"
states$code[states$NAME_1=="São Paulo"] <- "SP"
states$code[states$NAME_1=="Minas Gerais"] <- "MG"
states$code[states$NAME_1=="Paraíba"] <- "PB"
states$code[states$NAME_1=="Paraná"] <- "PR"
states$code[states$NAME_1=="Espírito Santo"] <- "ES"
states$code[states$NAME_1=="Rio Grande do Sul"] <- "RS"
states$code[states$NAME_1=="Rio Grande do Norte"] <- "RN"
states$code[states$NAME_1=="Santa Catarina"] <- "SC"
states <- states[match(countries, states$code),]
env_dat <- readRDS("../../clean-data/worldclim-states.RDS")[states$GID_1,,"tmean"]
env_dat <- env_dat[,c(12, rep(1:5, c(31,29,31,30,12)))]
stan_data$env_dat <- scale(t(env_dat))

options(mc.cores = parallel::detectCores())
rstan_options(auto_write = TRUE)
m = stan_model('stan-models/stan-brazil.stan')

fit = sampling(m,data=stan_data,iter=1500,warmup=500,chains=8,thin=1, 
               control = list(adapt_delta = 0.95, max_treedepth = 15))



out = rstan::extract(fit)
prediction = out$prediction
estimated.deaths = out$E_deaths

save(fit, dates, reported_cases,deaths_by_country, countries,
     prediction, estimated.deaths,stan_data,df_pop,filename,df_region_codes,
     file=paste0('results/env-brazil-stanfit.Rdata'))
