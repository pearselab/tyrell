silent.require <- function(x) suppressMessages(require(package=x, character.only=TRUE, quietly=TRUE))

# Load packages that are already installed
packages <- c("rstan", "parallel", "yaml",
              "zeallot", #src/clean-gadm.R (and because Will likes it)
              "raster", "sp", "lubridate", "rgeos", "RColorBrewer", "abind", "exactextractr", "sf", "ncdf4", "countrycode", # worldclim and gadm cleaning
              "plotly", # Tom's plotting things
              "devtools", # to install GitHub packages (like Lorenzo's)
              "matrixStats","data.table","gdata","dplyr","tidyr","EnvStats","scales","tidyverse","dplyr","abind","ggplot2","gridExtra","ggpubr","bayesplot","cowplot","optparse", "lubridate", "zoo", "ggstance", "geofacet", "denstrip", "svglite", "forecast", "xtable", "car", "mclust", "lattice", "plot3D", # Imperial models
              "ape", "caper", "phytools", "viridis", "plotrix", # Phylogenetics
              "httr", "COVID19" # to get the UK data
              )

ready <- sapply(packages, silent.require)


# Install missing packages
for(i in seq_along(ready))
    if(!ready[i])
        install.packages(packages[i], quietly=TRUE, dependencies=TRUE)

# Error out if not all packages installed
ready <- sapply(packages, silent.require)
if(any(!ready))
    stop("Cannot install packages", ready[!ready])

# GitHub packages
if(!silent.require("DENVfoiMap")){
    install_github("lorecatta/DENVfoiMap", upgrade=FALSE)
    if(!silent.require("DENVfoiMap"))
        stop("Cannot install DENVfoiMap")
}
if(!silent.require("velox")){ # src/clean-gadm.R and src/worldclim.R
    install_github("hunzikp/velox", upgrade=FALSE)
    if(!silent.require("velox"))
        stop("Cannot install velox")
}
if(!silent.require("ggbiplot")){ # ms-env PCAs
    install_github("vqv/ggbiplot", upgrade=FALSE)
    if(!silent.require("ggbiplot"))
        stop("Cannot install ggbiplot")
}
if(!silent.require("epidemia")){ # Bayesian modelling in epidemia
    install_github("ImperialCollegeLondon/epidemia", upgrade=FALSE)
    if(!silent.require("epidemia"))
        stop("Cannot install epidemia")
}


# Set number of cores (if desired)
library(yaml)
if(file.exists("config.yml")){
    config <- read_yaml("config.yml")
    if("r" %in% names(config)){
        r.config <- config$r
        if("mc.cores" %in% names(r.config))
            options(mc.cores=r.config$mc.cores)
    }
}
