source("src/packages.R")

# Simplifying rasters without losing names (from rgeos::gSimplify)
wSimplify <- function (spgeom, tol, name.var, topologyPreserve = FALSE){
    getCutEdges = as.logical(topologyPreserve)
    if (is.na(topologyPreserve)) 
        stop("Invalid value for topologyPreserve, must be logical")
    if (inherits(spgeom, "SpatialPolygons") && get_do_poly_check() && 
        rgeos:::notAllComments(spgeom)) 
        spgeom <- createSPComment(spgeom)
    id = eval(substitute(spgeom$XXX, list(XXX=name.var)))
    return(.Call("rgeos_simplify", rgeos:::.RGEOS_HANDLE, spgeom, tol, 
        id, FALSE, topologyPreserve, PACKAGE = "rgeos"))
}

countries <- shapefile("raw-data/gadm36_0.shp")
countries_data <- SpatialPolygonsDataFrame(countries, data=countries@data)
countries <- wSimplify(countries, tol=.005, "NAME_0", topologyPreserve=FALSE)
countries_data <- countries_data[countries_data$NAME_0 %in% names(countries),]
saveRDS(list(polygons=countries, metadata=countries_data), "clean-data/gadm-countries.RDS")

states <- shapefile("raw-data/gadm36_1.shp")
states_data <- SpatialPolygonsDataFrame(states, data=states@data)
states <- wSimplify(states, tol=0.005, "GID_1", topologyPreserve=FALSE)
states_data <- states_data[states_data$GID_1 %in% names(states),]    
saveRDS(list(polygons=states, metadata=states_data), "clean-data/gadm-states.RDS")
