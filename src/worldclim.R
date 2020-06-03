# Headers
source("src/packages.R")

# Get countries and states
c(countries, countries_data) %<-% readRDS("clean-data/gadm-countries.RDS")
c(states, states_data) %<-% readRDS("clean-data/gadm-states.RDS")

# Get WORLDCLIM data
clim_variables <- c("t_min", "t_mean", "t_max")
tmean <- velox(getData("worldclim",var="tmean",res=10)) / 10
tmin <- velox(getData("worldclim",var="tmin",res=10))   / 10
tmax <- velox(getData("worldclim",var="tmax",res=10))   / 10

# Average across countries and states
c.clim <- abind(
    tmean$extract(countries, fun=function(x) median(x, na.rm=TRUE)),
    tmin$extract(countries, fun=function(x) median(x, na.rm=TRUE)),
    tmax$extract(countries, fun=function(x) median(x, na.rm=TRUE)),
    along=3
)
s.clim <- abind(
    tmean$extract(states, fun=function(x) median(x, na.rm=TRUE)),
    tmin$extract(states, fun=function(x) median(x, na.rm=TRUE)),
    tmax$extract(states, fun=function(x) median(x, na.rm=TRUE)),
    along=3
)
dimnames(c.clim) <- list(
    names(countries),
    c("January","February","March","April","May","June","July","August","September","October","November","December"),
    c("tmean", "tmin", "tmax")
)
dimnames(s.clim) <- list(
    names(states),
    c("January","February","March","April","May","June","July","August","September","October","November","December"),
    c("tmean", "tmin", "tmax")
)

# remove spaces from the country names
rownames(c.clim) <- gsub(" ", "_", rownames(c.clim))

saveRDS(c.clim, "clean-data/worldclim-countries.RDS")
saveRDS(s.clim, "clean-data/worldclim-states.RDS")
