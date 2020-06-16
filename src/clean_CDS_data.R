# --- Get average humidity for countries/states --- #
#
# ISSUES:
# - currently this isn't working properly for small area countries/states
# and we're just generating NAs for those :(

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
  return(climate_velox$extract(shapefile, fun = function(x)median(x, na.rm = TRUE)))
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
humidityFiles <- lapply(Sys.glob("raw-data/cdsar5-1month_mean_Global_ea_r2*.grib"), rgdal::readGDAL)
# also read all of the monthly temperature data
temperatureFiles <- lapply(Sys.glob("raw-data/cdsar5-1month_mean_Global_ea_2t*.grib"), rgdal::readGDAL)

# Extract humidity and temperature across files
.avg.wrapper <- function(climate, region)
    return(do.call(cbind, mcMap(
                                 function(x) avg.climate(shapefile=region, x),
                       climate)))

c.humidity <- .avg.wrapper(humidityFiles, countries)
s.humidity <- .avg.wrapper(humidityFiles, states)
c.humidity <- .avg.wrapper(temperatureFiles, countries)
s.humidity <- .avg.wrapper(temperatureFiles, states)

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
dimnames(s.humidity) <- list(states$GID_1, paste0(month.year,"_TC"))
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
