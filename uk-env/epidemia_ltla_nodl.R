# Base epidemia model without mobility/temperature
source("src/packages.R")

args = commandArgs(trailingOnly=TRUE)

load("ext-data/epidemia-workspace.Rdata")

# Sets observation
deaths <- epiobs(formula = deaths(Name, date) ~ 1,
                 prior_intercept = rstanarm::normal(0.01,0.001),
                 link = "identity",
                 i2o = EuropeCovid$obs$deaths$i2o)

# Sets si
si <- EuropeCovid$si

# Sets population
pop <- data.frame(mydata[,c("Name", "Population")] %>%
                    group_by(Name) %>% 
                    slice(1))

names(pop) <- c("Name", "pop")
pop$ifr <- 0.01035044 # UK infection fatality rate

# remove pops with NA values
pop <- pop[!is.na(pop$pop),]
pop <- pop[pop$pop > 0,]
# and remove the same data from the main dataset
mydata <- mydata[mydata$Name %in% pop$Name,]


# Sets rt formulation
rt <- epirt(formula = R(Name, date) ~ (1 | Name) + temperature + Pop_density + average + rw(time=week, gr = Name, prior_scale=0.1),
            prior_intercept = rstanarm::normal(log(3.8), 0.075))


options(mc.cores=4)

sampling_args <- list(iter=5000,
                      chains = 4,
                      control=list(adapt_delta=0.99, max_treedepth=15))

fm <- epim(rt = rt,
           obs = list(deaths),
           data = mydata,
           pops = pop,
           si = si,
           seed_days = 6,
           prior_tau = rstanarm::exponential(rate=4),
           algorithm = "sampling",
           sampling_args = sampling_args)

# plot_rt(fm, plotly=TRUE)
# plot_obs(fm, type = "deaths", group = "Aberdeen City", plotly=TRUE)
# 
# fm$stanfit
# fm$rt

rt_out <- posterior_rt(fm)

save(fm, mydata, deaths, pop, rt, sampling_args, si, rt_out, 
     file=paste0("uk-env/epidemia-UKltla-", args[1], ".Rdata"))
