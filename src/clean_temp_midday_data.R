# --- Get average humidity for countries/states --- #
#
# ISSUES:
# - currently this isn't working properly for small area countries/states
#   and we're just generating NAs for those :(
# - (above copy-pasted from humidity data, because I'm assuming the same is true for that)

source("src/packages.R")

# Get countries and states
countries <- shapefile("clean-data/gadm-countries.shp")
states <- shapefile("clean-data/gadm-states.shp")

# Load temperature data and subset into rasters for each day of the year
# - NOTE: assumes Tom's humidity script applies here too
days <- as.Date("2020-01-01") + 0:151
temp <- rgdal::readGDAL("raw-data/cds-era5-temp-midday.grib")
.drop.col <- function(i){
    x <- temp
    x@data <- x@data[,i,drop=FALSE]
    return(x)
}
temp <- lapply(seq_along(days), function(i) velox(raster::rotate(raster(.drop.col(i)))))

# Do work; format and save
c.temp <- sapply(temp, function(r) r$extract(countries, fun = function(x) median(x, na.rm = TRUE)))
s.temp <- sapply(temp, function(r) r$extract(states, fun = function(x) median(x, na.rm = TRUE)))
dimnames(c.temp) <- list(countries$NAME_0, days)
dimnames(s.temp) <- list(states$GID_1, days)
rownames(c.temp) <- gsub(" ", "_", rownames(c.temp))
saveRDS(c.temp, "clean-data/temp-midday-countries.RDS")
saveRDS(s.temp, "clean-data/temp-midday-states.RDS")
