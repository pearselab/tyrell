# Load packages that are already installed
packages <- c("rstan",
              "raster", "sp", "lubridate", # src/climate-data.R
              "devtools" # to install GitHub packages (like Lorenzo's)
              )

ready <- sapply(packages, require, character.only=TRUE, quietly=TRUE)

# Install missing packages
for(i in seq_along(ready))
    if(!ready[i])
        install.packages(ready[i], quietly=FALSE)

# Error out if not all packages installed
ready <- sapply(packages, require, character.only=TRUE, quietly=TRUE)
if(any(!ready))
    stop("Cannot install packages", ready[!ready])

# GitHub packages
if(!require("DENVfoiMap")){
    install_github("lorecatta/DENVfoiMap")
    if(!require("DENVfoiMap"))
        stop("Cannot install DENVfoiMap")
