#########################
# Headers ###############
#########################
source("src/packages.R")

# Wrapper for many shapefiles
avg.poly.clim <- function(shapefile, data, var, shp.metadata, FUNC=median){
    .internal <- function(polygon, data, var, FUNC){
        output <- raster::extract(data, polygon, fun=FUNC, na.rm=TRUE)   
        if(is.null(output[[1]]))
            return(NA)
        return(as.numeric(output))
    }

    if(!var %in% colnames(data))
        stop("Invalid climatic variable")
    data <- rasterFromXYZ(data.frame(data[,c("longitude", "latitude",var)]))
    data <- velox(data)
    return(data$extract(shapefile, fun=function(x) FUNC(x, na.rm=TRUE)))
    
    #return(setNames(
    #    sapply(
    #        seq_len(length(shapefile)),
    #        function(i) .internal(shapefile[i,], data, var, FUNC)
    #    ),
    #    shp.metadata$NAME_0
    #))
}


# Get countries and states
countries <- shapefile("clean-data/gadm-countries.shp")
states <- shapefile("clean-data/gadm-states.shp")

# Calculate summaries across DENVfoiMap data and write out
# - MIR - Middle Infrared Reflectance, EVI - Enhanced Vegetation Index, and RFE - Precipitation
clim_vars <- readRDS("raw-data/denvfoimap-raster.RDS")
c.summary <- sapply(c("latitude", "altitude", "DayTemp_const_term", "EVI_const_term", "MIR_const_term", "NightTemp_const_term", "RFE_const_term", "log_pop_den", "birth_rate", "mean_age", "sd_age"),
                    function(x) avg.poly.clim(countries, clim_vars, x, countries_data)
                    )
s.summary <- sapply(c("latitude", "altitude", "DayTemp_const_term", "EVI_const_term", "MIR_const_term", "NightTemp_const_term", "RFE_const_term", "log_pop_den", "birth_rate", "mean_age", "sd_age"),
                    function(x) avg.poly.clim(states, clim_vars, x, states_data)
                    )

write.csv(c.summary, "clean-data/denvfoimap-rasters-countries.csv")
write.csv(s.summary, "clean-data/denvfoimap-rasters-states.csv")
