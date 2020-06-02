# Headers
source("src/packages.R")

# Get countries and states
c(countries, countries_data) %<-% readRDS("clean-data/gadm-countries.RDS")
c(states, states_data) %<-% readRDS("clean-data/gadm-states.RDS")

# Get WORLDCLIM data
clim_variables <- c("t_min", "t_mean", "t_max")
tmean <- velox(getData("worldclim",var="tmean",res=10))
tmin <- velox(getData("worldclim",var="tmin",res=10))
tmax <- velox(getData("worldclim",var="tmax",res=10))

# Average across data
country_tmean <- tmean$extract(countries, fun=function(x) median(x, na.rm=TRUE))
country_tmin <- tmin$extract(countries, fun=function(x) median(x, na.rm=TRUE))
country_tmax <- tmax$extract(countries, fun=function(x) median(x, na.rm=TRUE))

# Format and save to disk
month.name <- c("January","Februrary","March","April","May","June","July","August","September","October","November","December")
climate_array <- array(NA, dim = c(length(countries),length(clim_variables),12),
                       dimnames = list(countries, clim_variables, month.name))
climate_array[,"t_mean",] <- matrix(unlist(country_tmean), nrow=length(countries), ncol=12, byrow=TRUE) /10
climate_array[,"t_min",] <- matrix(unlist(country_tmin), nrow=length(countries), ncol=12, byrow=TRUE) /10
climate_array[,"t_max",] <- matrix(unlist(country_tmax), nrow=length(countries), ncol=12, byrow=TRUE) /10

saveRDS(climate_array, "clean-data/worldclim-countries.RDS")
