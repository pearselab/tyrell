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
c(states, m.states) %<-% readRDS("../../clean-data/gadm-states.RDS")
states <- states[m.states$NAME_0=="Brazil",]
m.states <- m.states[m.states$NAME_0=="Brazil",]
m.states <- m.states[m.states$NAME_1 %in% c("São Paulo","Rio de Janeiro","Pernambuco","Ceará","Amazonas","Pará","Maranhão","Bahia","Espírito Santo","Paraná","Minas Gerais","Paraíba","Rio Grande do Sul","Rio Grande do Norte","Alagoas","Santa Catarina"),] # List taken from table 1 in report
m.states$code <- toupper(substr(m.states$NAME_1, 0, 2))
m.states$code[m.states$NAME_1=="Rio de Janeiro"] <- "RJ"
m.states$code[m.states$NAME_1=="São Paulo"] <- "SP"
m.states$code[m.states$NAME_1=="Minas Gerais"] <- "MG"
m.states$code[m.states$NAME_1=="Paraíba"] <- "PB"
m.states$code[m.states$NAME_1=="Paraná"] <- "PR"
m.states$code[m.states$NAME_1=="Espírito Santo"] <- "ES"
m.states$code[m.states$NAME_1=="Rio Grande do Sul"] <- "RS"
m.states$code[m.states$NAME_1=="Rio Grande do Norte"] <- "RN"
m.states$code[m.states$NAME_1=="Santa Catarina"] <- "SC"
m.states <- m.states[match(countries, m.states$code),]
env_dat <- readRDS("../../clean-data/worldclim-states.RDS")[m.states$GID_1,,"tmean"]
stan_data$env_dat <- env_dat

options(mc.cores = parallel::detectCores())
rstan_options(auto_write = TRUE)
m = stan_model('stan-models/env-brazil.stan')

fit = sampling(m,data=stan_data,iter=1500,warmup=500,chains=8,thin=1, 
               control = list(adapt_delta = 0.95, max_treedepth = 15))



out = rstan::extract(fit)
prediction = out$prediction
estimated.deaths = out$E_deaths

save(fit, dates, reported_cases,deaths_by_country, countries,
     prediction, estimated.deaths,stan_data,JOBID,df_pop,filename,df_region_codes,
     file=paste0('results/env-brazil-stanfit.Rdata'))
