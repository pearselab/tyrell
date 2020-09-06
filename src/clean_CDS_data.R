# --- Get average humidity for countries/states --- #

source("src/packages.R")

###########################
##    -- Functions --    ##
###########################

# a function to first turn the grid data into raster, then apply the extract function across the shapefiles
# to calculate a median for the climate variable across the countries/states
avg.climate <- function(shapefile, x){
  # turn the humidity data into a raster
  climate_raster <- raster(x)
  # need to swap coordinates from [0 to 360] to [-180 to 180].
  rotated_raster <- raster::rotate(climate_raster)
  climate_velox <- velox(rotated_raster)
  # average the humidity across each object in the shapefile
  return(climate_velox$extract(shapefile, small = TRUE, fun = function(x)median(x, na.rm = TRUE)))
}

# similar to above function, but the climate data is weighted
# by population density - i.e. climate is more representative
# of where people are located
avg.climate.weighted <- function(shapefile, pop_density, x){
  # turn the humidity data into a raster
  climate_raster <- raster(x)
  # need to swap coordinates from [0 to 360] to [-180 to 180].
  rotated_raster <- raster::rotate(climate_raster)
  
  shapefile_sf <- st_as_sf(shapefile) # exact_extract needs an sf object
  pop_data_project <- projectRaster(pop_density, rotated_raster) # converts to same resolution
  clim_pop_stack <- stack(rotated_raster, pop_data_project) # stacks population density and climate data
  values(pop_data_project)[which(is.na(values(pop_data_project)))] <- 0 # needed to do this because the weighted_mean algorithm craps out when there are NA gaps in the polygon
  
  # average the humidity across each object in the shapefile,
  # weighted by pop density
  return(exact_extract(rotated_raster, shapefile_sf, fun="weighted_mean", weights=pop_data_project))
}

# calculate vapor pressure
# - a measure of absolute humidity
# VP is calculated from ambient temperature and relative humidity 
# using the Clausius–Clapeyron relation
# First calculate the saturation vapor pressure e_s(T) (mb)
# from the ambient temperature

calc_sat_VP <- function(e_0, T_0, temp){
  # e_0  : saturation vapor pressure at reference temperature, T_0 (6.11mb @ 273.15 K)
  # L    : latent heat of evaporation for water (2257 kJ/kg)
  # Rv   : gas constant for water vapor ( 461.53 J/(kg K) )
  # T_0  : reference temperature (Kelvin)
  # temp : ambient temperature (Kelvin)
  L <- 2257000
  Rv <- 461.53
  
  return(e_0 * exp((L/Rv)*(1/T_0 - 1/temp)))
}


# vapor pressure (VP)
calc_VP <- function(e_s, RH){
  # take the e_s at temperture T calculated before
  # and use relative humidity to calc vapor pressure
  return(100 * e_s * (RH/100))
}
  
# absolute humidity [ρv (g/m3)], is the mass of moisture per total volume of air. 
# It is associated to VP via the ideal gas law for the moist portion of the air
calc_AH <- function(VP, temp){
  # VP   : vapor pressure
  # Rv   : gas constant for water vapor ( 461.53 J/(kg K) )
  # temp : Temperature (Kelvin)
  Rv <- 461.53
  return(1000 * (VP / (Rv * temp)))
  
}


###########################
##    -- Main Code --    ##
###########################

# Get countries and states
countries <- shapefile("clean-data/gadm-countries.shp")
states <- shapefile("clean-data/gadm-states.shp")

# read ALL of the monthly humidity data in 1 go
humidityFiles <- lapply(Sys.glob("raw-data/gis/cdsar5-1month_mean_Global_ea_r2*.grib"), rgdal::readGDAL)
# also read all of the monthly temperature data
temperatureFiles <- lapply(Sys.glob("raw-data/gis/cdsar5-1month_mean_Global_ea_2t*.grib"), rgdal::readGDAL)

# get the population data for weighted means
pop_data <- raster("ext-data/gpw_v4_population_density_rev11_2020_15_min.tif")
                               
# Extract humidity and temperature across files
.avg.wrapper <- function(climate, region)
    return(do.call(cbind, mcMap(
                                 function(x) avg.climate(shapefile=region, x),
                       climate)))

c.humidity <- .avg.wrapper(humidityFiles, countries)
s.humidity <- .avg.wrapper(humidityFiles, states)
c.temperature <- .avg.wrapper(temperatureFiles, countries)
s.temperature <- .avg.wrapper(temperatureFiles, states)

# use these temperatures and humidities to calculate vapor pressure (or absolute humidity)
# countries first
c.satVP <- calc_sat_VP(e_0 = 6.11, T_0 = 273.15, temp = c.temperature)
c.VP <- calc_VP(e_s = c.satVP, RH = c.humidity)
c.abs_hum <- calc_AH(VP = c.VP, temp = c.temperature)
# then states
s.satVP <- calc_sat_VP(e_0 = 6.11, T_0 = 273.15, temp = s.temperature)
s.VP <- calc_VP(e_s = s.satVP, RH = s.humidity)
s.abs_hum <- calc_AH(VP = s.VP, temp = s.temperature)

# swap temperature into celsius
c.temperature <- c.temperature-273.15
s.temperature <- s.temperature-273.15


# add names to the matrices (TC -> Temperature Celsius)
month.year <- c("January_19","February_19","March_19","April_19","May_19","June_19","July_19","August_19","September_19","October_19", "November_19","December_19", "January_20","February_20","March_20","April_20","May_20")
dimnames(c.humidity) <- list(countries$NAME_0, paste0(month.year,"_RH"))
dimnames(s.humidity) <- list(states$GID_1, paste0(month.year,"_RH"))
dimnames(c.temperature) <- list(countries$NAME_0, paste0(month.year,"_TC"))
dimnames(s.temperature) <- list(states$GID_1, paste0(month.year,"_TC"))
dimnames(c.abs_hum) <- list(countries$NAME_0, paste0(month.year,"_AH"))
dimnames(s.abs_hum) <- list(states$GID_1, paste0(month.year,"_AH"))

rownames(c.humidity) <- gsub(" ", "_", rownames(c.humidity))
rownames(c.temperature) <- gsub(" ", "_", rownames(c.temperature))
rownames(c.abs_hum) <- gsub(" ", "_", rownames(c.abs_hum))

saveRDS(c.humidity, "clean-data/relative-humidity-countries.RDS")
saveRDS(s.humidity, "clean-data/relative-humidity-states.RDS")
saveRDS(c.temperature, "clean-data/temperature-countries.RDS")
saveRDS(s.temperature, "clean-data/temperature-states.RDS")
saveRDS(c.abs_hum, "clean-data/absolute-humidity-countries.RDS")
saveRDS(s.abs_hum, "clean-data/absolute-humidity-states.RDS")
