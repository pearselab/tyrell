# --- Get population density for UK regions --- #
#
# 

source("src/packages.R")

# get uk shapefiles
UK_NUTS <- shapefile("raw-data/gis/NUTS_Level_1__January_2018__Boundaries.shp")
UK_LTLA <- shapefile("raw-data/gis/Local_Authority_Districts__December_2019__Boundaries_UK_BFC.shp")

# population data
pop_data <- velox("ext-data/gpw_v4_population_density_rev11_2020_15_min.tif")

# reproject uk data
UK_NUTS_reproj <- spTransform(UK_NUTS, pop_data$crs)
UK_LTLA_reproj <- spTransform(UK_LTLA, pop_data$crs)

# extract across the raster
NUTS.popdensity <- pop_data$extract(UK_NUTS_reproj, small = TRUE, fun=function(x)mean(x, na.rm = TRUE))
LTLA.popdensity <- pop_data$extract(UK_LTLA_reproj, small = TRUE, fun=function(x)mean(x, na.rm = TRUE))

# add names
dimnames(NUTS.popdensity) <- list(
  UK_NUTS$nuts118nm, "Pop_density")
dimnames(LTLA.popdensity) <- list(
  UK_LTLA$lad19nm, "Pop_density")

# save
saveRDS(NUTS.popdensity, "clean-data/population-density-UK-NUTS.RDS")
saveRDS(LTLA.popdensity, "clean-data/population-density-UK-LTLA.RDS")