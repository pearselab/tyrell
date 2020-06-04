source("src/packages.R")

# Simplifying rasters without losing names (from rgeos::gSimplify)
wSimplify <- function (spgeom, tol, name.var, topologyPreserve = FALSE){
    getCutEdges = as.logical(topologyPreserve)
    if (is.na(topologyPreserve)) 
        stop("Invalid value for topologyPreserve, must be logical")
    if (inherits(spgeom, "SpatialPolygons") && get_do_poly_check() && 
        rgeos:::notAllComments(spgeom)) 
        spgeom <- createSPComment(spgeom, overwrite=FALSE)
    id = row.names(spgeom)
    return(.Call("rgeos_simplify", rgeos:::.RGEOS_HANDLE, spgeom, tol, 
                    id, FALSE, topologyPreserve, PACKAGE = "rgeos"))
}

countries <- shapefile("raw-data/gadm36_0.shp")
countries_data <- SpatialPolygonsDataFrame(countries, data=countries@data)
countries <- gSimplify(countries, tol=0.005, topologyPreserve=FALSE)
countries_data <- countries_data[countries_data$GID_1 %in% row.names(countries),]
saveRDS(list(polygons=countries, metadata=countries_data), "clean-data/gadm-countries.RDS")

states <- shapefile("raw-data/gadm36_1.shp")
states_data <- SpatialPolygonsDataFrame(states, data=states@data)
states <- gSimplify(states, tol=0.005, topologyPreserve=FALSE)
states_data <- states_data[states_data$GID_1 %in% row.names(states),]
saveRDS(list(polygons=states, metadata=states_data), "clean-data/gadm-states.RDS")
