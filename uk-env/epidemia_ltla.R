# Base epidemia model without mobility/temperature
source("src/packages.R")

args = commandArgs(trailingOnly=TRUE)

# read in data
mydata <- read.csv("clean-data/climate-and-deaths-UK-LTLA.csv")

# remove weird symbols from place names
mydata$Name <- as.factor(gsub("[[:punct:]]", "", mydata$Name))

# gapfill missing data
mydata[is.na(mydata)] <- 0

##### CHANGE DATES TO FEWER TO JUST FIND R0 #######
# start dates for each region should be 30 days before the first 10 cumulative recorded deaths

mydata$Date <- as.Date(mydata$Date)

# mydata <- mydata[mydata$CumulativeDeaths > 10,]
# don't want to just do that, because of some NAs in cumulative data later along the line
# so find start dates for the epidemic in each region, and filter dataset to after those
t0 <- data.frame(mydata[mydata$CumulativeDeaths >= 10,c("Name", "Date")] %>%
                   group_by(Name) %>%
                   slice(which.min(Date)))
t0$Date <- t0$Date - 30
names(t0) <- c("Name", "StartDate")
# reduce data to only those things which actually had 10 cumulative deaths
mydata <- mydata[mydata$Name %in% t0$Name,]

mydata <- left_join(mydata, t0, by="Name") %>% filter(Date >= StartDate)

# now reduce it to just the end of May for ease

mydata <- mydata[mydata$Date < "2020-06-01",]

mydata$week <- format(as.Date(mydata$Date), "%V")
names(mydata)[2] <- "date"
names(mydata)[6] <- "deaths"

## Reformat mobility data ##
mydata$retail <- mydata$retail_and_recreation_percent_change_from_baseline*-0.01
mydata$grocery <- mydata$grocery_and_pharmacy_percent_change_from_baseline*-0.01
mydata$parks <- mydata$parks_percent_change_from_baseline*-0.01
mydata$transit <- mydata$transit_stations_percent_change_from_baseline*-0.01
mydata$workplace <- mydata$workplaces_percent_change_from_baseline*-0.01
mydata$residential <- mydata$residential_percent_change_from_baseline*-0.01

# calculate an average mobility
mydata$average <- rowMeans(mydata[,c("retail", "grocery", "workplace")], na.rm = TRUE)


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
