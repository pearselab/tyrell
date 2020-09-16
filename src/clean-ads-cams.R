# --- Get average daily PM 2.5 for countries/states (European data only) --- #
#
source("src/packages.R")

# Get countries and states
countries <- shapefile("clean-data/gadm-countries.shp")
states <- shapefile("clean-data/gadm-states.shp")

# Load climate data and subset into rasters for each day of the year
days <- as.character(as.Date("2020-01-01") + 0:243)
pm2pt5 <- rgdal::readGDAL("ext-data/ads-cams-pm2pt5-dailymean.grib")
.drop.col <- function(i, sp.df){
  sp.df@data <- sp.df@data[,i,drop=FALSE]
  return(sp.df)
}
# note, dont need to rotate this raster, like in the cds global climate data
pm2pt5 <- lapply(seq_along(days), function(i, sp.df) velox(raster(.drop.col(i, sp.df))), sp.df=pm2pt5)

# Do work; format and save
.avg.wrapper <- function(climate, region)
  return(do.call(cbind, mcMap(
    function(r) r$extract(region, small = TRUE, fun = function(x) median(x, na.rm = TRUE)),
    climate)))
.give.names <- function(output, rows, cols, rename=FALSE){
  dimnames(output) <- list(rows, cols)
  if(rename)
    rownames(output) <- gsub(" ", "_", rownames(output))
  return(output)
}

saveRDS(
  .give.names(.avg.wrapper(pm2pt5, countries), countries$NAME_0, days, TRUE),
  "clean-data/pm2pt5-dailymean-countries.RDS"
)
saveRDS(
  .give.names(.avg.wrapper(pm2pt5, states), states$GID_1, days),
  "clean-data/pm2pt5-dailymean-states.RDS"
)
