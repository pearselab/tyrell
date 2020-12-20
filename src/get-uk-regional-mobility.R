# Average mobility data across UK regions
setwd("~/Documents/Tyrell/")

source("src/packages.R")
library("COVID19") # use the COVID 19 data hub

# try to grab the mobility data then, using google key
gmr <- "https://www.gstatic.com/covid19/mobility/Global_Mobility_Report.csv"
uk_mobility <- as.data.frame(covid19(c("United Kingdom"), level = 2, gmr = gmr))

# save it
write.csv(uk_mobility, "raw-data/uk-regional-mobility.csv", row.names = FALSE)
