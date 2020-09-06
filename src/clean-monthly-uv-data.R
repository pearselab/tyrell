# Clean average monthly UV data

source("src/packages.R")

# function to average UV across shapefile
avg.uv <- function(shapefile, x){
  # average the UV across each object in the shapefile
  return(x$extract(shapefile, small = TRUE, fun = function(x)median(x, na.rm = TRUE)))
}

# Get countries and states
countries <- shapefile("clean-data/gadm-countries.shp")
states <- shapefile("clean-data/gadm-states.shp")

# data is mean monthly UV-B between 2004-2013, in J m−2 d−1
# relating to this paper:  https://doi.org/10.1111/2041-210X.12168
uvFiles <- lapply(Sys.glob("raw-data/gis/glUV*"), velox)

c.uv <- sapply(uvFiles, function(x) avg.uv(shapefile = countries, x))
s.uv <- sapply(uvFiles, function(x) avg.uv(shapefile = states, x))

# add names
dimnames(c.uv) <- list(countries$NAME_0,
                       c("Feb_UV", "May_UV"))
dimnames(s.uv) <- list(states$GID_1,
                       c("Feb_UV", "May_UV"))

# remove spaces from the country names
rownames(c.uv) <- gsub(" ", "_", rownames(c.uv))

saveRDS(c.uv, "clean-data/monthly-avg-UV-countries.RDS")
saveRDS(s.uv, "clean-data/monthly-avg-UV-states.RDS")
