# --- Get average humidity for countries/states --- #
#
# ISSUES:
# - currently this isn't working properly for small area countries/states
# and we're just generating NAs for those :(

source("src/packages.R")

# a function to first turn the grid data into raster, then apply the extract function across the shapefiles
avg.humidity <- function(shapefile, x){
  # turn the humidity data into a raster
  humidity_raster <- raster(x)
  # average the humidity across each object in the shapefile
  return(raster::extract(x = humidity_raster, y = shapefile, fun=function(x, na.rm = TRUE)median(x, na.rm = TRUE)))
}

# Get countries and states
countries <- shapefile("clean-data/gadm-countries.shp")
states <- shapefile("clean-data/gadm-states.shp")

# read ALL of the monthly humidity data in 1 go
humidityFiles <- lapply(Sys.glob("raw-data/cdsar5-1month_mean_Global_ea_r2*.grib"), rgdal::readGDAL)

# apply the function to extract median humidity across the countries and states data
c.humidity <- sapply(humidityFiles, function(x) avg.humidity(shapefile = countries, x))
s.humidity <- sapply(humidityFiles, function(x) avg.humidity(shapefile = states, x))

dimnames(c.humidity) <- list(
  row.names(countries),
  c("January_19","February_19","March_19","April_19","May_19","June_19","July_19","August_19","September_19","Octobe_19r",
    "November_19","December_19", "January_20","February_20","March_20","April_20","May_20")
)

dimnames(s.humidity) <- list(
  row.names(states),
  c("January_19","February_19","March_19","April_19","May_19","June_19","July_19","August_19","September_19","Octobe_19r",
    "November_19","December_19", "January_20","February_20","March_20","April_20","May_20")
)

saveRDS(c.clim, "clean-data/humidity-countries.RDS")
saveRDS(s.clim, "clean-data/humidity-states.RDS")