#########################
# Headers ###############
#########################
source("src/packages.R")
`%!in%` <- Negate(`%in%`)

# Wrapper for many shapefiles
avg.poly.clim <- function(shapefile, data, var, shp.metadata, FUNC=median){
    .internal <- function(polygon, data, var, FUNC){
        output <- raster::extract(data, polygon, fun=FUNC, na.rm=TRUE)   
        if(is.null(output[[1]]))
            return(NA)
        return(as.numeric(output))
    }

    if(var %!in% colnames(data))
        stop("Invalid climatic variable")
    data <- rasterFromXYZ(data.frame(data[,c("longitude", "latitude",var)]))
    
    return(setNames(
        sapply(
            seq_len(length(shapefile)),
            function(i) .internal(shapefile[i,], data, var, FUNC)
        ),
        shp.metadata$NAME_0
    ))
}

# Load and simplify shapefiles and their metadata
# - (GADM files, from 0-5, are: countries, states, counties, and then lower admin regions)
countries <- shapefile("raw-data/gadm36_0.shp")
countries_data <- SpatialPolygonsDataFrame(countries, data=countries@data)
countries <- gSimplify(countries, tol=0.005, topologyPreserve=FALSE)
states <- shapefile("raw-data/gadm36_1.shp")
states_data <- SpatialPolygonsDataFrame(states, data=states@data)
states <- gSimplify(states, tol=0.005, topologyPreserve=FALSE)

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
