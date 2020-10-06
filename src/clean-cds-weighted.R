# Get daily average temperature/uv/humidity/pm2.5 for countries/states
# weighted by population density
source("src/packages.R")

# function to subset to the dates wanted
.drop.col <- function(i, sp.df){
  sp.df@data <- sp.df@data[,i,drop=FALSE]
  return(sp.df)
}

# function to do a climate average across countries/states, weighted by population density
.avg.wrapper.weighted <- function(climate, region, pop_density){
  pop_data_project <- projectRaster(pop_density, climate) # stacks population density and climate data
  values(pop_data_project)[which(is.na(values(pop_data_project)))] <- 0 # needed to do this because the weighted_mean algorithm craps out when there are NA gaps in the polygon
  return(exact_extract(climate, region, fun="weighted_mean", weights=pop_data_project))
}

# function to name the data
.give.names <- function(output, rows, cols, rename=FALSE){
  dimnames(output) <- list(rows, cols)
  if(rename)
    rownames(output) <- gsub(" ", "_", rownames(output))
  return(output)
}

# Get countries and states (as sf for our weighting code)
countries <- st_as_sf(shapefile("clean-data/gadm-countries.shp"))
states <- st_as_sf(shapefile("clean-data/gadm-states.shp"))

# get the population data for weighted means
pop_data <- raster("ext-data/gpw_v4_population_density_rev11_2020_15_min.tif")

# Load climate data and subset into rasters for each day of the year
days <- as.character(as.Date("2020-01-01") + 0:243)

# not using velox here because I don't think it'll work with our weighted average code
temp <- rgdal::readGDAL("raw-data/gis/cds-era5-temp-dailymean.grib")
temp <- lapply(seq_along(days), function(i, sp.df) raster::rotate(raster(.drop.col(i, sp.df))), sp.df=temp)

humid <- rgdal::readGDAL("raw-data/gis/cds-era5-humid-dailymean.grib")
humid <- lapply(seq_along(days), function(i, sp.df) raster::rotate(raster(.drop.col(i, sp.df))), sp.df=humid)

uv <- rgdal::readGDAL("raw-data/gis/cds-era5-uv-dailymean.grib")
uv <- lapply(seq_along(days), function(i, sp.df) raster::rotate(raster(.drop.col(i, sp.df))), sp.df=uv)

# note, dont need to rotate this raster, like in the cds global climate data
pm2pt5 <- rgdal::readGDAL("ext-data/ads-cams-pm2pt5-dailymean.grib")
pm2pt5 <- lapply(seq_along(days), function(i, sp.df) raster(.drop.col(i, sp.df)), sp.df=pm2pt5)

# now average the climate across the region layers
countries.temp <- sapply(temp, function(i, region, pop_density) .avg.wrapper.weighted(i, region, pop_density), 
                         region = countries, pop_density = pop_data)
states.temp <- sapply(temp, function(i, region, pop_density) .avg.wrapper.weighted(i, region, pop_density), 
                         region = states, pop_density = pop_data)
countries.humid <- sapply(humid, function(i, region, pop_density) .avg.wrapper.weighted(i, region, pop_density), 
                         region = countries, pop_density = pop_data)
states.humid <- sapply(humid, function(i, region, pop_density) .avg.wrapper.weighted(i, region, pop_density), 
                      region = states, pop_density = pop_data)
countries.uv <- sapply(uv, function(i, region, pop_density) .avg.wrapper.weighted(i, region, pop_density), 
                         region = countries, pop_density = pop_data)
states.uv <- sapply(uv, function(i, region, pop_density) .avg.wrapper.weighted(i, region, pop_density), 
                      region = states, pop_density = pop_data)
countries.pm2pt5 <- sapply(pm2pt5, function(i, region, pop_density) .avg.wrapper.weighted(i, region, pop_density), 
                         region = countries, pop_density = pop_data)
states.pm2pt5 <- sapply(pm2pt5, function(i, region, pop_density) .avg.wrapper.weighted(i, region, pop_density), 
                      region = states, pop_density = pop_data)

# and save
saveRDS(
  .give.names(countries.temp, countries$NAME_0, days, TRUE),
  "clean-data/temp-dailymean-countries-popweighted.RDS"
)
saveRDS(
  .give.names(states.temp, states$GID_1, days),
  "clean-data/temp-dailymean-states-popweighted.RDS"
)
saveRDS(
  .give.names(countries.humid, countries$NAME_0, days, TRUE),
  "clean-data/humid-dailymean-countries-popweighted.RDS"
)
saveRDS(
  .give.names(states.humid, states$GID_1, days),
  "clean-data/humid-dailymean-states-popweighted.RDS"
)
saveRDS(
  .give.names(countries.uv, countries$NAME_0, days, TRUE),
  "clean-data/uv-dailymean-countries-popweighted.RDS"
)
saveRDS(
  .give.names(states.uv, states$GID_1, days),
  "clean-data/uv-dailymean-states-popweighted.RDS"
)
saveRDS(
  .give.names(countries.pm2pt5, countries$NAME_0, days, TRUE),
  "clean-data/pm2pt5-dailymean-countries-popweighted.RDS"
)
saveRDS(
  .give.names(states.pm2pt5, states$GID_1, days),
  "clean-data/pm2pt5-dailymean-states-popweighted.RDS"
)
