silent.require <- function(x) suppressMessages(require(package=x, character.only=TRUE, quietly=TRUE))

# Load packages that are already installed
packages <- c("rstan",
              "raster", "sp", "lubridate", # src/climate-data.R
              "devtools" # to install GitHub packages (like Lorenzo's)
              )

ready <- sapply(packages, silent.require)


# Install missing packages
for(i in seq_along(ready))
    if(!ready[i])
        install.packages(ready[i], quietly=TRUE)

# Error out if not all packages installed
ready <- sapply(packages, silent.require)
if(any(!ready))
    stop("Cannot install packages", ready[!ready])

# GitHub packages
if(!silent.require("DENVfoiMap")){
    install_github("lorecatta/DENVfoiMap")
    if(!silent.require("DENVfoiMap"))
        stop("Cannot install DENVfoiMap")
}
