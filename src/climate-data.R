###
#(1) write an R function that takes a raster (e.g., temperature data) and a series of polygons 
#(e.g., country boundaries) and calculates something from the raster across the polygon groups
#(2) get that working for each of the gadm shapefiles loaded in by Tyrell. If you have time after that
#(3) plot those averages out on a chloropleth map
#(4) see if you can do that in RShiny (this will either have an easy example you can use or nothing)
###

source("src/packages.R")

setwd("/home/michael/Documents/Grad School/Research Projects/Tyrell")

`%!in%` <- Negate(`%in%`)

library(raster)
library(rgeos)
library(RColorBrewer)

old_par <- par()

shape_files <- list.files("raw-data/")[which(grepl("shp",list.files("raw-data/")))]
# shape 0: Countries
# shape 1: States
# shape 2: Counties - large fie
# shape 3: lower admin region - very large file
# shape 4: lower admin region - very large file
# shape 5: lower admin region - very large file


countries <- shapefile(paste0("raw-data/", shape_files[1]))
states <- shapefile(paste0("raw-data/", shape_files[2]))
#shape2 <- shapefile(paste0("raw-data/", shape_files[3]))
#shape3 <- shapefile(paste0("raw-data/", shape_files[4]))
#shape4 <- shapefile(paste0("raw-data/", shape_files[5]))
#shape5 <- shapefile(paste0("raw-data/", shape_files[6]))


if(FALSE){
  # simplifies the polygons for plotting. 0.005 is detailed enough to still have every country polygon
  simple_countries <- gSimplify(countries, tol=0.005, topologyPreserve=FALSE) # DONT SET TOPOLOGYPRESERVE=TRUE IT WILL KILL YOUR MEMORY
  simple_countries_data = SpatialPolygonsDataFrame(simple_countries, data=countries@data)
  paste("The simplified map is", round(object.size(simple_countries)/object.size(countries),3), "the complexity of the full map")
  
  par(mar=c(1,1,1,1))
  plot(simple_countries_data)
}

# this wasn't working for me at the time, so I went to the site to manually download the RDS file
if(FALSE){
  clim_url <- "https://mrcdata.dide.ic.ac.uk/resources/DENVfoiMap/all_squares_env_var_0_1667_deg.rds"
  clim_vars <- readRDS(url(clim_url))
}

head(clim_vars)

# from manual download
clim_vars <- readRDS("raw-data/all_squares_env_var_0_1667_deg.rds")
# Climate variables include:
# Temperature (DayTemp, NightTemp)
# Enhanced Vegetation Index (EVI)
# Middle Infrared Reflectance (MIR)
# Precipitation (RFE)

# Variables NOT included:
# humidity
# UV radiation

# averages climatic data over the extent of a (SINGLE) set of polygons (administrative region)
# this takes a while to run for large countries and for lots of islands - could probably be improved
shape.clim.avg <- function(poly, var="mean_age", avg_method = median){
  #poly <- poly_test
  if(var %!in% colnames(clim_vars)) stop("Invalid climatic variable")
  
  all_clim_vals <- rasterFromXYZ(data.frame(clim_vars[,c("longitude", "latitude",var)]))
  vals_in_poly <- raster::extract(all_clim_vals, poly, fun=avg_method, na.rm=TRUE)
  
  #plot(all_clim_vals)
  
  if(is.null(vals_in_poly[[1]])) return(NA)
  
  return(as.numeric(vals_in_poly))
}

if(FALSE){
  poly_test <- countries[29,] # just Belarus
  poly_test <- countries[171,] # NZ
  poly_test <- countries[12,] # Antarctica
  
  plot(poly_test)
  shape.clim.avg(poly_test, "mean_age")
}

# I don't know how to "apply" over S4 objects :(
shape.clim.avg.wrapper <- function(var="mean_age", avg_method = median){
  avgs <- rep(NA, nrow(country_avgs))
  
  for(i in 1:nrow(country_avgs)){
    country_poly <- countries[i,]
    print(country_poly$NAME_0)
    avgs[i] <- shape.clim.avg(country_poly, var, avg_method)
  }
  return(avgs)
}

country_avgs <- data.frame(country = countries$NAME_0)
country_avgs$temp <- shape.clim.avg.wrapper("DayTemp_const_term")
#country_avgs$mean_age <- shape.clim.avg.wrapper("mean_age")

countries$temp <- country_avgs$temp

spplot(countries, "temp") # this takes a VERY long time to plot, much longer than just the polygon outlines.




####################
### preliminary work
####################

### pulling average monthly climate data for European countries
# temperature (min, median, max)
# humidity
# UV radiation

if(FALSE){
  source("src/packages.R")
  
  `%!in%` <- Negate(`%in%`)
  
  countries <- c(
    "Denmark",
    "Italy",
    "Germany",
    "Spain",
    "United_Kingdom",
    "France",
    "Norway",
    "Belgium",
    "Austria", 
    "Sweden",
    "Switzerland"
  )
  countries <- sort(countries)
  
  # WorldClim only provides mean temperature, not median
  clim_variables <- c(
    "t_min",
    "t_mean",
    "t_max",
    "humidity",
    "UV"
  )
  
  gain = 0.1 # WorldClim has a gain of 0.1... gain(tmean) says otherwise, but I believe this is an error.
  
  country_codes_all <- getData('ISO3')
  countries_codes <- country_codes_all[which(country_codes_all$NAME %in% gsub("_"," ",countries)),]
  
  #fra <- getData("GADM", country="FRA", level=0)
  country_polies <- sapply(countries_codes$ISO3, function(x) getData("GADM", country = x, level=0))
  
  tmean <- getData("worldclim",var="tmean",res=10)
  tmin <- getData("worldclim",var="tmin",res=10)
  tmax <- getData("worldclim",var="tmax",res=10)
  
  #fra_tmean <- extract(tmean, fra, fun=mean)
  #swe_tmean <- extract(tmean, getData("GADM", country="SWE", level=0), fun=mean, na.rm=TRUE)
  country_tmean <- lapply(country_polies, function(x) extract(tmean, x, fun=mean, na.rm=TRUE))
  country_tmin <- lapply(country_polies, function(x) extract(tmin, x, fun=mean, na.rm=TRUE))
  country_tmax <- lapply(country_polies, function(x) extract(tmax, x, fun=mean, na.rm=TRUE))
  
  climate_array <- array(NA, dim = c(length(countries),length(clim_variables),12),
                         dimnames = list(countries, clim_variables, month.name))
  
  climate_array[,"t_mean",] <- matrix(unlist(country_tmean), nrow=length(countries), ncol=12, byrow=TRUE) * gain
  climate_array[,"t_min",] <- matrix(unlist(country_tmin), nrow=length(countries), ncol=12, byrow=TRUE) * gain
  climate_array[,"t_max",] <- matrix(unlist(country_tmax), nrow=length(countries), ncol=12, byrow=TRUE) * gain
  
  # manual relative humidity values from https://weather-and-climate.com/ - from the capitals of the countries
  # this is done visually from their plots, so the numbers are rough
  climate_array["Austria","humidity",] <- c(.79, .76, .71, .66, .67, .66, .67, .69, .74, .79, .81, .82)
  climate_array["Belgium","humidity",] <- c(.90, .88, .82, .80, .78, .76, .80, .81, .82, .86, .89, .88)
  climate_array["Denmark","humidity",] <- c(.86, .85, .81, .75, .73, .73, .74, .75, .80, .82, .83, .85)
  climate_array["France","humidity",] <- c(.90, .84, .77, .69, .69, .69, .70, .72, .78, .85, .89, .88)
  climate_array["Germany","humidity",] <- c(.82, .78, .68, .60, .58, .59, .61, .60, .65, .74, .83, .86)
  climate_array["Italy","humidity",] <- c(.75, .75, .75, .75, .75, .74, .73, .74, .75, .76, .78, .78)
  climate_array["Norway","humidity",] <- c(.83, .80, .77, .68, .60, .62, .68, .70, .76, .80, .87, .86)
  climate_array["Spain","humidity",] <- c(.78, .71, .62, .61, .55, .50, .41, .42, .53, .65, .74, .77)
  climate_array["Sweden","humidity",] <- c(.84, .80, .74, .68, .60, .62, .67, .74, .78, .82, .87, .79)
  climate_array["Switzerland","humidity",] <- c(.84, .81, .73, .69, .68, .72, .71, .73, .76, .82, .85, .86)
  climate_array["United_Kingdom","humidity",] <- c(.82, .79, .73, .64, .65, .65, .66, .64, .73, .78, .83, .84)
  
  # manual UV index values from https://www.weather-atlas.com/ - from the capitals of the countries
  # UV index is in integers, so this should not be a final measure of UV radiation
  
  climate_array["Austria","UV",] <- c(1, 2, 3, 4, 6, 7, 7, 6, 4, 3, 1, 1)
  climate_array["Belgium","UV",] <- c(1, 1, 3, 4, 6, 7, 6, 6, 4, 2, 1, 1)
  climate_array["Denmark","UV",] <- c(0, 1, 2, 3, 5, 6, 5, 5, 3, 1, 1, 0)
  climate_array["France","UV",] <- c(1, 2, 3, 4, 6, 7, 7, 6, 4, 3, 1, 1)
  climate_array["Germany","UV",] <- c(1, 1, 2, 4, 5, 6, 6, 5, 4, 2, 1, 0)
  climate_array["Italy","UV",] <- c(2, 2, 4, 6, 7, 8, 9, 8, 6, 4, 2, 1)
  climate_array["Norway","UV",] <- c(0, 1, 1, 3, 4, 5, 5, 4, 3, 1, 0, 0)
  climate_array["Spain","UV",] <- c(2, 3, 5, 6, 8, 9, 9, 8, 6, 4, 2, 2)
  climate_array["Sweden","UV",] <- c(0, 1, 1, 3, 4, 5, 5, 4, 3, 1, 0, 0)
  climate_array["Switzerland","UV",] <- c(1, 2, 3, 5, 7, 8, 8, 7, 5, 3, 1, 1)
  climate_array["United_Kingdom","UV",] <- c(1, 1, 2, 4, 5, 6, 6, 5, 4, 2, 1, 0)
  
  
  
  # this is ***typical climate*** at a point, in the month of the given date
  # the date is collapsed down into the month, years don't mean anything
  worldclim.point <- function(lat, lon, date="2020-01-01", var="tmean", lag=0){
    if(sum(is.na(c(lat,lon,date,var,lag)) > 0)){
      warning("NA in one or more of the arguments")
      return(NA)
    }
    if(var %!in% c("tmean", "tmin", "tmax")) error("unknown var")
    if(var == "tmean") clim_data <- tmean
    if(var == "tmin") clim_data <- tmin
    if(var == "tmax") clim_data <- tmax
    
    date <- as.Date(date)
    month_of_date <- month(date - lag)
    point <- SpatialPoints(data.frame(long = lon, lat = lat))
    var_value <- extract(clim_data, point) * gain
    output <- var_value[month_of_date]
    
    if(is.na(output)){
      warning(paste("The point at (", lat, ", ", lon, ") may be over water.", sep=""))
    }
    return(output)
  }
  
  saveRDS(climate_array, "clean-data/climate_array.RDS")
}


