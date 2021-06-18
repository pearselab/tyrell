# Headers
source("src/packages.R")

# Get countries and states
countries <- shapefile("clean-data/gadm-countries.shp")
states <- shapefile("clean-data/gadm-states.shp")

# Get WORLDCLIM data
clim_variables <- c("t_min", "t_mean", "t_max")
tmean <- getData("worldclim",var="tmean",res=10) / 10
tmin <- getData("worldclim",var="tmin",res=10)   / 10
tmax <- getData("worldclim",var="tmax",res=10)   / 10

# Average across countries and states
c.clim <- abind(
    raster::extract(x = tmean, y = countries, fun=function(x, na.rm = TRUE)median(x, na.rm = TRUE), small = TRUE),
    raster::extract(x = tmin, y = countries, fun=function(x, na.rm = TRUE)median(x, na.rm = TRUE), small = TRUE),
    raster::extract(x = tmax, y = countries, fun=function(x, na.rm = TRUE)median(x, na.rm = TRUE), small = TRUE),
    along=3
)
s.clim <- abind(
    raster::extract(x = tmean, y = states, fun=function(x, na.rm = TRUE)median(x, na.rm = TRUE), small = TRUE),
    raster::extract(x = tmin, y = states, fun=function(x, na.rm = TRUE)median(x, na.rm = TRUE), small = TRUE),
    raster::extract(x = tmax, y = states, fun=function(x, na.rm = TRUE)median(x, na.rm = TRUE), small = TRUE),
    along=3
)
dimnames(c.clim) <- list(
    countries$NAME_0,
    c("January","February","March","April","May","June","July","August","September","October","November","December"),
    c("tmean", "tmin", "tmax")
)
dimnames(s.clim) <- list(
    states$GID_1,
    c("January","February","March","April","May","June","July","August","September","October","November","December"),
    c("tmean", "tmin", "tmax")
)

# remove spaces from the country names
rownames(c.clim) <- gsub(" ", "_", rownames(c.clim))

saveRDS(c.clim, "clean-data/worldclim-countries.RDS")
saveRDS(s.clim, "clean-data/worldclim-states.RDS")
