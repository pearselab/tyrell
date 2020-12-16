# Combine death data with mobility,
# temperature, population density, etc.

source("src/packages.R")

# death data
region.deaths <- read.csv("raw-data/cases/uk-regional.csv")
local.deaths <- read.csv("raw-data/cases/uk-ltla.csv")

# mobility data
region.mob <- read.csv("raw-data/uk-regional-mobility.csv")
local.mob <- read.csv("raw-data/uk-ltla-mobility.csv")

# chop to columns we care about
region.mob <- region.mob[,c("date", "administrative_area_level_2", "retail_and_recreation_percent_change_from_baseline",
                            "grocery_and_pharmacy_percent_change_from_baseline", "parks_percent_change_from_baseline",
                            "transit_stations_percent_change_from_baseline", "workplaces_percent_change_from_baseline",
                            "residential_percent_change_from_baseline")]

local.mob <- local.mob[,c("date", "ltla_name", "retail_and_recreation_percent_change_from_baseline",
                            "grocery_and_pharmacy_percent_change_from_baseline", "parks_percent_change_from_baseline",
                            "transit_stations_percent_change_from_baseline", "workplaces_percent_change_from_baseline",
                            "residential_percent_change_from_baseline")]

names(region.mob)[2] <- "Name"
names(local.mob)[2] <- "Name"

# population density
region.pop <- as.data.frame(readRDS("clean-data/population-density-UK-NUTS.RDS"))
region.pop$Name <- gsub(" (England)", "", row.names(region.pop), fixed = TRUE)

local.pop <- as.data.frame(readRDS("clean-data/population-density-UK-LTLA.RDS"))
local.pop$Name <- row.names(local.pop)

# climate data
region.temp <- as.data.frame(readRDS("clean-data/temp-UK-NUTS.RDS"))
local.temp <- as.data.frame(readRDS("clean-data/temp-UK-LTLA.RDS"))

# function to add names to the climate data then make it long long
make_long <- function(df, clim_var){
  df$Name <- gsub(" (England)", "", row.names(df), fixed = TRUE)
  return(pivot_longer(df,
                      cols = c(1:(ncol(df)-1)),
                      names_to = "date",
                      values_to = clim_var))
}

region.temp.long <- make_long(region.temp, "temperature")
local.temp.long <- make_long(local.temp, "temperature")

# bind together

merge_datasets <- function(deaths, mobility, climate, population){
  # first pad the whole dataset with zeros for later
  #dates <- rep(seq(as.Date("2020-01-01"), as.Date("2020-12-31"), by = "day"), length(as.character(unique(deaths$Name))))
  #places <- rep(as.character(unique(deaths$Name)), each = 366)
  #base_df <- setnames(data.frame(dates, places), c("Date", "Name"))
  #padded_deaths <- merge(base_df, deaths, by = c("Name", "Date"), all.x = TRUE)
  df1 <- merge(deaths, mobility, by.x = c("Date", "Name"), by.y = c("date", "Name"), all.x = TRUE)
  df2 <- merge(df1, climate, by.x = c("Date", "Name"), by.y = c("date", "Name"), all.x = TRUE)
  df3 <- merge(df2, population, by.x = "Name", by.y = "Name", all.x = TRUE)
  return(df3)
}

region.data <- merge_datasets(deaths = region.deaths, mobility = region.mob,
                              climate = region.temp.long, population = region.pop)

local.data <- merge_datasets(deaths = local.deaths, mobility = local.mob,
                              climate = local.temp.long, population = local.pop)


# write out
write.csv(region.data, "clean-data/climate-and-deaths-UK-NUTS.csv", row.names = FALSE)
write.csv(local.data, "clean-data/climate-and-deaths-UK-LTLA.csv", row.names = FALSE)
