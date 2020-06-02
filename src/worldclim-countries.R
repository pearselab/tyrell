# Headers
source("src/packages.R")
`%!in%` <- Negate(`%in%`)

# Get countries and their data
country_codes_all <- getData('ISO3')
country_polies <- sapply(countries_codes_all$ISO3, function(x) getData("GADM", country = x, level=0))

# Get WORLDCLIM data
clim_variables <- c("t_min", "t_mean", "t_max")
tmean <- getData("worldclim",var="tmean",res=10)
tmin <- getData("worldclim",var="tmin",res=10)
tmax <- getData("worldclim",var="tmax",res=10)

# Average across data
country_tmean <- lapply(country_polies, function(x) raster::extract(tmean, x, fun=mean, na.rm=TRUE))
country_tmin <- lapply(country_polies, function(x) raster::extract(tmin, x, fun=mean, na.rm=TRUE))
country_tmax <- lapply(country_polies, function(x) raster::extract(tmax, x, fun=mean, na.rm=TRUE))

# Save to disk
climate_array <- array(NA, dim = c(length(countries),length(clim_variables),12),
                       dimnames = list(countries, clim_variables, month.name))

climate_array[,"t_mean",] <- matrix(unlist(country_tmean), nrow=length(country_polies), ncol=12, byrow=TRUE) * gain
climate_array[,"t_min",] <- matrix(unlist(country_tmin), nrow=length(country_polies), ncol=12, byrow=TRUE) * gain
climate_array[,"t_max",] <- matrix(unlist(country_tmax), nrow=length(country_polies), ncol=12, byrow=TRUE) * gain

saveRDS(climate_array, "clean-data/worldclim-countries.RDS")
