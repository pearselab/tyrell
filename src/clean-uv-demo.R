# Demo script for UV data

source("src/packages.R")

# 0.25 degree UV data
# https://disc.gsfc.nasa.gov/datasets/OMUVBG_003/summary?keywords=OMUVB
# 
# check out what the file we downloaded looks like
nc_open("raw-data/OMI-Aura_L2G-OMUVBG_2020m0611_v003-2020m0614t090001.he5")

# it has a load of different variables
# all detailed here: https://docserver.gesdisc.eosdis.nasa.gov/repository/Mission/OMI/3.3_ScienceDataProductDocumentation/3.3.2_ProductRequirements_Designs/OMUVBG_FileSpec_V003.pdf
# I think for now, we just want to take the uv index at noon, like so:

uv_0pt25degree <- raster("raw-data/OMI-Aura_L2G-OMUVBG_2020m0611_v003-2020m0614t090001.he5",
                         var="Data Fields/UVindex",ncdf=TRUE, resolution = 0.25, crs = "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")

extent(uv_0pt25degree)
# need to fix the extent
fix_coords <- extent(-180, 180, -90, 90)
uv_0pt25degree <- setExtent(uv_0pt25degree, fix_coords, keepres=FALSE)

# velox for speedier mapping to countries/states
uv_0pt25degree <- velox(uv_0pt25degree)

# load the countries/states data
countries <- shapefile("clean-data/gadm-countries.shp")
states <- shapefile("clean-data/gadm-states.shp")

# get UV data for the countries/states
countries$UVindex <- uv_0pt25degree$extract(countries, fun=function(x) median(x, na.rm=TRUE))
states$UVindex <- uv_0pt25degree$extract(states, fun=function(x) median(x, na.rm=TRUE))

italy.states <- states[states$NAME_0=="Italy",]

png("figures/countries_UV.png", width = 1500, height = 1000)
spplot(countries, "UVindex", main="UV index")
dev.off()

#spplot(states, "UVindex", main="UV index")

png("figures/italy_UV.png", width=500, height=600)
spplot(italy.states, "UVindex", main="UV index")
dev.off()