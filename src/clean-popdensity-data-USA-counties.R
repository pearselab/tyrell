# --- Get population density for USA counties --- #
#
# 

source("src/packages.R")

# Get counties
counties <- shapefile("clean-data/gadm-counties.shp")
US_counties <- counties[counties$GID_0 == "USA",]

# location of population density data: https://sedac.ciesin.columbia.edu/downloads/data/gpw-v4/gpw-v4-population-density-rev11/gpw-v4-population-density-rev11_2020_2pt5_min_tif.zip
# ^ may need an account to download this directly
#pop_data <- raster("../COVID/Pop_density/gpw_v4_population_density_rev11_2020_2pt5_min.tif")
#pop_data <- velox("ext-data/gpw_v4_population_density_rev11_2020_15_min.tif")
pop_data <- velox("ext-data/gpw_v4_population_density_rev11_2020_30_sec.tif")


us.c.popdensity <- pop_data$extract(US_counties, small = TRUE, fun=function(x)mean(x, na.rm = TRUE))

# add names
dimnames(us.c.popdensity) <- list(
  US_counties$NAME_2, "Pop_density")

saveRDS(us.c.popdensity, "clean-data/population-density-USA-counties.RDS")