# average climate across UK regions
# pollution data is excluded from this until I can get
# the raw data to rake in properly

source("src/packages.R")

# dataset of the UK regional boundaries at:
# https://geoportal.statistics.gov.uk/datasets/nuts-level-1-january-2018-boundaries?geometry=-85.320%2C45.849%2C76.486%2C63.326&layer=0
# direct download link here:
# https://opendata.arcgis.com/datasets/01fd6b2d7600446d8af768005992f76a_0.zip?outSR=27700

# dataset of local authority boundaries here:
# https://geoportal.statistics.gov.uk/datasets/1d78d47c87df4212b79fe2323aae8e08_0
# direct dl link:
# https://opendata.arcgis.com/datasets/1d78d47c87df4212b79fe2323aae8e08_0.zip?outSR=%7B%22latestWkid%22%3A27700%2C%22wkid%22%3A27700%7D

UK_NUTS <- shapefile("raw-data/gis/NUTS_Level_1__January_2018__Boundaries.shp")
UK_LTLA <- shapefile("raw-data/gis/Local_Authority_Districts__December_2019__Boundaries_UK_BFC.shp")

# climate data
days <- as.character(as.Date("2020-01-01") + 0:243)
temp <- rgdal::readGDAL("raw-data/gis/cds-era5-temp-dailymean.grib")
humid <- rgdal::readGDAL("raw-data/gis/cds-era5-humid-dailymean.grib")
uv <- rgdal::readGDAL("raw-data/gis/cds-era5-uv-dailymean.grib")
# pm2pt5 <- rgdal::readGDAL("ext-data/ads-cams-pm2pt5-dailymean.grib")
.drop.col <- function(i, sp.df){
  sp.df@data <- sp.df@data[,i,drop=FALSE]
  return(sp.df)
}

temp <- lapply(seq_along(days), function(i, sp.df) velox(raster::rotate(raster(.drop.col(i, sp.df)))), sp.df=temp)
humid <- lapply(seq_along(days), function(i, sp.df) velox(raster::rotate(raster(.drop.col(i, sp.df)))), sp.df=humid)
uv <- lapply(seq_along(days), function(i, sp.df) velox(raster::rotate(raster(.drop.col(i, sp.df)))), sp.df=uv)
# note, dont need to rotate the pollution raster:
# pm2pt5 <- lapply(seq_along(days), function(i, sp.df) velox(raster(.drop.col(i, sp.df))), sp.df=pm2pt5)

# Do work; format and save
.avg.wrapper <- function(climate, region){
  return(mapply(function(r) r$extract(region, small = TRUE, fun = function(x) median(x, na.rm = TRUE)),
                climate))
}

# get the UK spatial data into the correct projection
UK_NUTS_reproj <- spTransform(UK_NUTS, temp[[1]]$crs)
UK_LTLA_reproj <- spTransform(UK_LTLA, temp[[1]]$crs)

# do the climate averaging
UK_NUTS.temp <- .avg.wrapper(temp, UK_NUTS_reproj)
UK_NUTS.humid <- .avg.wrapper(humid, UK_NUTS_reproj)
UK_NUTS.uv <- .avg.wrapper(uv, UK_NUTS_reproj)
# UK_NUTS.pm2pt5 <- .avg.wrapper(pm2pt5, UK_NUTS_reproj)

UK_LTLA.temp <- .avg.wrapper(temp, UK_LTLA_reproj)
UK_LTLA.humid <- .avg.wrapper(humid, UK_LTLA_reproj)
UK_LTLA.uv <- .avg.wrapper(uv, UK_LTLA_reproj)
# UK_LTLA.pm2pt5 <- .avg.wrapper(pm2pt5, UK_LTLA_reproj)

# give names
dimnames(UK_NUTS.temp) <- list(
  UK_NUTS$nuts118nm,
  days
)
dimnames(UK_NUTS.humid) <- list(
  U_NUTSK$nuts118nm,
  days
)
dimnames(UK_NUTS.uv) <- list(
  UK_NUTS$nuts118nm,
  days
)
# dimnames(UK_NUTS.pm2pt5) <- list(
#   UK_NUTS$nuts118nm,
#   days
# )

dimnames(UK_LTLA.temp) <- list(
  UK_LTLA$lad19nm,
  days
)
dimnames(UK_LTLA.humid) <- list(
  UK_LTLA$lad19nm,
  days
)
dimnames(UK_LTLA.uv) <- list(
  UK_LTLA$lad19nm,
  days
)
# dimnames(UK_LTLA.pm2pt5) <- list(
#   UK_LTLA$lad19nm,
#   days
# )


saveRDS(UK_NUTS.temp, "clean-data/temp-UK-NUTS.RDS")
saveRDS(UK_NUTS.humid, "clean-data/humid-UK-NUTS.RDS")
saveRDS(UK_NUTS.uv, "clean-data/uv-UK-NUTS.RDS")
# saveRDS(UK_NUTS.pm2pt5, "clean-data/pm2pt5-UK-NUTS.RDS")

saveRDS(UK_LTLA.temp, "clean-data/temp-UK-LTLA.RDS")
saveRDS(UK_LTLA.humid, "clean-data/humid-UK-LTLA.RDS")
saveRDS(UK_LTLA.uv, "clean-data/uv-UK-LTLA.RDS")
# saveRDS(UK_LTLA.pm2pt5, "clean-data/pm2pt5-UK-LTLA.RDS")
