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

# apply the function to extract median humidity across the countries and states data
c.humidity <- sapply(humidityFiles, function(x) avg.climate(shapefile = countries, x))
s.humidity <- sapply(humidityFiles, function(x) avg.climate(shapefile = states, x))
# repeat for CDS temperature data
c.temperature <- sapply(temperatureFiles, function(x) avg.climate(shapefile = countries, x))
s.temperature <- sapply(temperatureFiles, function(x) avg.climate(shapefile = states, x))

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


# add names to the matrices
dimnames(c.humidity) <- list(
  countries$NAME_0,
  c("January_19_RH","February_19_RH","March_19_RH","April_19_RH","May_19_RH","June_19_RH","July_19_RH","August_19_RH","September_19_RH",
    "October_19_RH", "November_19_RH","December_19_RH", "January_20_RH","February_20_RH","March_20_RH","April_20_RH","May_20_RH")
)

dimnames(s.humidity) <- list(
  states$GID_1,
  c("January_19_RH","February_19_RH","March_19_RH","April_19_RH","May_19_RH","June_19_RH","July_19_RH","August_19_RH","September_19_RH",
    "October_19_RH", "November_19_RH","December_19_RH", "January_20_RH","February_20_RH","March_20_RH","April_20_RH","May_20_RH")
)

# TC for temperature (Celsius)
dimnames(c.temperature) <- list(
  countries$NAME_0,
  c("January_19_TC","February_19_TC","March_19_TC","April_19_TC","May_19_TC","June_19_TC","July_19_TC","August_19_TC","September_19_TC",
    "October_19_TC", "November_19_TC","December_19_TC", "January_20_TC","February_20_TC","March_20_TC","April_20_TC","May_20_TC")
)

dimnames(s.temperature) <- list(
  states$GID_1,
  c("January_19_TC","February_19_TC","March_19_TC","April_19_TC","May_19_TC","June_19_TC","July_19_TC","August_19_TC","September_19_TC",
    "October_19_TC", "November_19_TC","December_19_TC", "January_20_TC","February_20_TC","March_20_TC","April_20_TC","May_20_TC")
)

dimnames(c.abs_hum) <- list(
  countries$NAME_0,
  c("January_19_AH","February_19_AH","March_19_AH","April_19_AH","May_19_AH","June_19_AH","July_19_AH","August_19_AH","September_19_AH",
    "October_19_AH", "November_19_AH","December_19_AH", "January_20_AH","February_20_AH","March_20_AH","April_20_AH","May_20_AH")
)

dimnames(s.abs_hum) <- list(
  states$GID_1,
  c("January_19_AH","February_19_AH","March_19_AH","April_19_AH","May_19_AH","June_19_AH","July_19_AH","August_19_AH","September_19_AH",
    "October_19_AH", "November_19_AH","December_19_AH", "January_20_AH","February_20_AH","March_20_AH","April_20_AH","May_20_AH")
)

rownames(c.humidity) <- gsub(" ", "_", rownames(c.humidity))
rownames(c.temperature) <- gsub(" ", "_", rownames(c.temperature))
rownames(c.abs_hum) <- gsub(" ", "_", rownames(c.abs_hum))

saveRDS(c.humidity, "clean-data/relative-humidity-countries.RDS")
saveRDS(s.humidity, "clean-data/relative-humidity-states.RDS")
saveRDS(c.temperature, "clean-data/temperature-countries.RDS")
saveRDS(s.temperature, "clean-data/temperature-states.RDS")
saveRDS(c.abs_hum, "clean-data/absolute-humidity-countries.RDS")
saveRDS(s.abs_hum, "clean-data/absolute-humidity-states.RDS")
