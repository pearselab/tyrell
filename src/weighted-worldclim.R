# For Michael
# setwd("/home/michael/Documents/Grad School/Research Projects/Tyrell")

# Headers
source("src/packages.R")

library(exactextractr)
library(sf)

# Get countries and states
# countries <- shapefile("clean-data/gadm-countries.shp")
states <- shapefile("clean-data/gadm-states.shp")

# overlay() not available in velox
tmean <- getData("worldclim",var="tmean",res=10)/10
#tmin <- getData("worldclim",var="tmin",res=10)/10
#tmax <- getData("worldclim",var="tmax",res=10)/10

# location of population density data: https://sedac.ciesin.columbia.edu/downloads/data/gpw-v4/gpw-v4-population-density-rev11/gpw-v4-population-density-rev11_2020_2pt5_min_tif.zip
# ^ may need an account to download this directly
#pop_data <- raster("raw-data/gis/gpw-v4-population-density-rev11_2020_2pt5_min_tif/gpw_v4_population_density_rev11_2020_2pt5_min.tif")
pop_data <- raster("raw-data/gis/gpw-v4-population-density-rev11_2020_15_min_tif/gpw_v4_population_density_rev11_2020_15_min.tif")

states_sf <- st_as_sf(states) # exact_extract needs an sf object
pop_data_project <- projectRaster(pop_data, tmean$tmean1) # converts to same resolution
clim_pop_stack <- stack(tmean$tmean1, pop_data_project) # stacks population density and climate data
values(pop_data_project)[which(is.na(values(pop_data_project)))] <- 0 # needed to do this because the weighted_mean algorithm craps out when there are NA gaps in the polygon

states$tmean1 <- exact_extract(tmean$tmean1, states_sf, fun="mean")
states$tmean1_weighted <- exact_extract(tmean$tmean1, states_sf, fun="weighted_mean", weights=pop_data_project)
# states$tmean1_weighted <- exact_extract(tmean$tmean1, states_sf, fun=function(x,weights) stats::weighted.mean(x, weights, na.rm=TRUE), weights=pop_data_project_adj) #doesn't work :(

png("mean_map.png", width=1500, height=1000)
spplot(states, "tmean1", main="mean")
dev.off()

png("weighted_mean_map.png", width=1500, height=1000)
spplot(states, "tmean1_weighted", main="weighted mean")
dev.off()

if(FALSE){
  # this multiplies temperature and population density... 
  # but upon second thought this doesn't make much sense because small population densities just draw negative and positive temp values closer to zero, which isn't really what we want. We want a weighted average.
  pop_clim <- overlay(clim_pop_stack, fun = prod) 
  
  #plotting
  cuts <- unique(quantile(values(pop_clim), probs = seq(0,1,length.out = 11), na.rm=TRUE))
  pal <- colorRampPalette(c("black","white"))
  plot(pop_clim, breaks=cuts, col = pal(length(cuts)))
}
