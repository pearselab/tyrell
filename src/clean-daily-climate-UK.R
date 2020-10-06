# test out averaging climate over UK regions
setwd("~/Documents/Tyrell/")

source("src/packages.R")

# alternative dataset of the UK boundaries at:
# https://geoportal.statistics.gov.uk/datasets/nuts-level-1-january-2018-boundaries?geometry=-85.320%2C45.849%2C76.486%2C63.326&layer=0
# direct download link here:
# https://opendata.arcgis.com/datasets/01fd6b2d7600446d8af768005992f76a_0.zip?outSR=27700

UK <- shapefile("~/Documents/COVID/testing/NUTS_Level_1__January_2018__Boundaries.shp")

# climate data
days <- as.character(as.Date("2020-01-01") + 0:243)
temp <- rgdal::readGDAL("raw-data/gis/cds-era5-temp-dailymean.grib")
humid <- rgdal::readGDAL("raw-data/gis/cds-era5-humid-dailymean.grib")
uv <- rgdal::readGDAL("raw-data/gis/cds-era5-uv-dailymean.grib")
.drop.col <- function(i, sp.df){
  sp.df@data <- sp.df@data[,i,drop=FALSE]
  return(sp.df)
}

temp <- lapply(seq_along(days), function(i, sp.df) velox(raster::rotate(raster(.drop.col(i, sp.df)))), sp.df=temp)
humid <- lapply(seq_along(days), function(i, sp.df) velox(raster::rotate(raster(.drop.col(i, sp.df)))), sp.df=humid)
uv <- lapply(seq_along(days), function(i, sp.df) velox(raster::rotate(raster(.drop.col(i, sp.df)))), sp.df=uv)

# Do work; format and save
.avg.wrapper <- function(climate, region){
  return(mapply(function(r) r$extract(region, small = TRUE, fun = function(x) median(x, na.rm = TRUE)),
                climate))
}

# get the UK spatial data into the correct projection
UK_reproj <- spTransform(UK, temp[[1]]$crs)

UK.temp <- .avg.wrapper(temp, UK_reproj)
UK.humid <- .avg.wrapper(humid, UK_reproj)
UK.uv <- .avg.wrapper(uv, USA)

dimnames(UK.temp) <- list(
  UK$nuts118nm,
  days
)
dimnames(UK.humid) <- list(
  UK$nuts118nm,
  days
)
dimnames(UK.uv) <- list(
  UK$nuts118nm,
  days
)


saveRDS(UK.temp, "clean-data/temp-UK.RDS")
saveRDS(UK.humid, "clean-data/humid-UK.RDS")
saveRDS(UK.uv, "clean-data/uv-UK.RDS")