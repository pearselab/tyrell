##################################################
# Join the R0/Rt and environmental data together #
##################################################

source("src/packages.R")

library("countrycode")

########################################################
# -- Step 1: load the various climate data and bind -- #
# -- together into a single data frame              -- #
########################################################

# temperature
countries_temperature <- readRDS("clean-data/temperature-countries.RDS")
states_temperature <- readRDS("clean-data/temperature-states.RDS")

# relative humidity
countries_humidity <- readRDS("clean-data/relative-humidity-countries.RDS")
states_humidity <- readRDS("clean-data/relative-humidity-states.RDS")

# absolute_humidity
countries_abs_humidity <- readRDS("clean-data/absolute-humidity-countries.RDS")
states_abs_humidity <- readRDS("clean-data/absolute-humidity-states.RDS")

# population density
countries_popdensity <- readRDS("clean-data/population-density-countries.RDS")
states_popdensity <- readRDS("clean-data/population-density-states.RDS")

# UV-B (J m-2 d-1)
countries_uv <- readRDS("clean-data/monthly-avg-UV-countries.RDS")
states_uv <- readRDS("clean-data/monthly-avg-UV-states.RDS")

# order is the same - as it should be, its all been done in the same way
# identical(row.names(countries_temperature), row.names(countries_popdensity))
# identical(row.names(countries_temperature), row.names(countries_humidity))
# identical(row.names(countries_temperature), row.names(countries_abs_humidity))
# identical(row.names(countries_temperature), row.names(countries_uv))

# put all of the climate/population data into 1 massive dataframe
countries_climate_df <- cbind(row.names(countries_temperature),
                              as.data.frame(countries_temperature, row.names = FALSE),
                              as.data.frame(countries_humidity, row.names = FALSE),
                              as.data.frame(countries_abs_humidity, row.names = FALSE),
                              as.data.frame(countries_popdensity, row.names = FALSE),
                              as.data.frame(countries_uv, row.names = FALSE))
names(countries_climate_df)[1] <- "Country"

# repeat for states - check names match first
# identical(row.names(states_temperature), row.names(states_popdensity))
# identical(row.names(states_temperature), row.names(states_humidity))

states_climate_df <- cbind(row.names(states_temperature),
                           as.data.frame(states_temperature, row.names = FALSE),
                           as.data.frame(states_humidity, row.names = FALSE),
                           as.data.frame(states_abs_humidity, row.names = FALSE),
                           as.data.frame(states_popdensity, row.names = FALSE),
                           as.data.frame(states_uv, row.names = FALSE))
names(states_climate_df)[1] <- "State"


#######################################################
# -- Step 2: load the Rt data for Europe/USA/LMIC --- #
# --- and estimate R0 as the pre-intervention Rt  --- #
#######################################################

# --- read the various imperial predictions data --- #

# -- europe -- #
europe_Rt <- read.csv("raw-data/imperial-europe-pred.csv")
europe_lockdown <- read.csv("raw-data/imperial-interventions.csv") # when did lockdown start in europe?

# -- LMIC -- #
LMIC_data <- read.csv("raw-data/imperial-lmic-pred.csv")
# need to strip this down to only the Rt data
LMIC_Rt <- LMIC_data[LMIC_data$compartment == "Rt" & LMIC_data$scenario == "Maintain Status Quo",]
# remove spaces from the country names
LMIC_Rt$country <- gsub(" ", "_", LMIC_Rt$country)

# also the data that OJ sent us directly with R0 values
# LMIC_alternative <- readRDS("ext-data/vars_for_will_06_16.rds")
# names(LMIC_alternative)[1] <- "date"
# # add country names column from the normal LMIC data using countrycode package
# LMIC_alternative$country <- countrycode(LMIC_alternative$iso3c, origin =  "iso3c", destination = "country.name",
#                                         custom_match = c("PSE"="State of Palestine"))
# LMIC_alternative$country <- gsub(" ", "_", LMIC_alternative$country)


# -- US states -- #
USA_Rt <- read.csv("raw-data/imperial-usa-pred.csv")

# make date columns for everything
europe_Rt$date <- as.Date(europe_Rt$time)
europe_lockdown$date <- as.Date(europe_lockdown$Date.effective, format = "%d.%m.%y")
LMIC_Rt$date <- as.Date(LMIC_Rt$date)
# LMIC_alternative$date <- as.Date(LMIC_alternative$date)
USA_Rt$date <- as.Date(USA_Rt$date)

# reorder the alternative LMIC data from earliest date to latest
# LMIC_alternative_ordered <- LMIC_alternative[order(LMIC_alternative$date),]

# -- Get "R0" from Rt estimates -- #
# for now, we're going to very simply estimate
# R0 as the earliest (i.e. date) Rt estimate
# they're in order from earlier to latest date
# so we can just match unique to get the first value

europe_R0 <- europe_Rt[match(unique(europe_Rt$country), europe_Rt$country),]
# LMIC_R0 <- LMIC_alternative_ordered[match(unique(LMIC_alternative_ordered$country), LMIC_alternative_ordered$country),]
LMIC_R0 <- LMIC_Rt[match(unique(LMIC_Rt$country), LMIC_Rt$country),]
USA_R0 <- USA_Rt[match(unique(USA_Rt$state), USA_Rt$state),]

# get these formatted the same for later
europe_R0_df <- europe_R0[,c("country", "mean_time_varying_reproduction_number_R.t.", "date")]
names(europe_R0_df) <- c("Location", "R0", "date")
europe_R0_df$dataset <- "Europe"

LMIC_R0_df <- LMIC_R0[,c("country", "y_mean", "date")]
names(LMIC_R0_df) <- c("Location", "R0", "date")
LMIC_R0_df$dataset <- "LMIC"

USA_R0_df <- USA_R0[,c("state", "mean_time_varying_reproduction_number_R.t.", "date")]
names(USA_R0_df) <- c("Location", "R0", "date")
USA_R0_df$dataset <- "USA"


###############################################################
# --- Step 3: take the Rt data for Europe/USA/LMIC        --- #
# --- and take means for May as a post-lockdown estimate  --- #
###############################################################

europe_data_may <- europe_Rt[europe_Rt$date >= "2020-05-01" & europe_Rt$date < "2020-06-01",]
LMIC_data_may <- LMIC_Rt[LMIC_Rt$date >= "2020-05-01" & LMIC_Rt$date < "2020-06-01",]
USA_data_may <- USA_Rt[USA_Rt$date >= "2020-05-01" & USA_Rt$date < "2020-06-01",]

# take the mean Rt across the whole of the month for each country
europe_Rt_may <- aggregate(mean_time_varying_reproduction_number_R.t. ~ country, data = europe_data_may, FUN = "mean")
LMIC_Rt_may <- aggregate(y_mean ~ country, data = LMIC_data_may, FUN = "mean")
USA_Rt_may <- aggregate(mean_time_varying_reproduction_number_R.t. ~ state, data = USA_data_may, FUN = "mean")

# get them formatted the same for later
names(europe_Rt_may) <- c("Location", "Rt")
europe_Rt_may$dataset <- "Europe"

names(LMIC_Rt_may) <- c("Location", "Rt")
LMIC_Rt_may$dataset <- "LMIC"

names(USA_Rt_may) <- c("Location", "Rt")
USA_Rt_may$dataset <- "USA"


###########################################################
# -- Step 4: combine the R0/Rt data with climate data --- #
###########################################################

# we're going to need to do some adjusting to make sure that the country names match up properly

LMIC_R0_df$Location[20] <- "Côte_d'Ivoire"
LMIC_R0_df$Location[22] <- "Democratic_Republic_of_the_Congo"
LMIC_R0_df$Location[23] <- "Republic_of_Congo"
LMIC_R0_df$Location[26] <- "Cape_Verde"
LMIC_R0_df$Location[53] <- "Kyrgyzstan"
LMIC_R0_df$Location[63] <- "Macedonia"
LMIC_R0_df$Location[81] <- "Palestina"
LMIC_R0_df$Location[92] <- "São_Tomé_and_Príncipe"
LMIC_R0_df$Location[94] <- "Swaziland"

# as lockdown happened in early March basically everywhere, but the pandemic didn't get
# going in some places until feb, maybe the sensible (albeit coarse) thing to do, is
# take the climate parameters for february only
#

# first we can just merge the climate data into the countries/states datasets
# Europe
europe_climate_df <- merge(europe_R0_df, countries_climate_df, by.x = "Location", by.y = "Country")

# LMIC
LMIC_climate_df <- merge(LMIC_R0_df, countries_climate_df, by.x = "Location", by.y = "Country")
# need to drop the countries with unreliable R0 estimates
unique(LMIC_climate_df$Location)
dropped_LMIC <- c("Angola", "Burundi", "Benin", "Belize", "Botswana", "Central_African_Republic",
                  "Equatorial_Guinea", "Jordan", "Libya", "Sri_Lanka", "Madagascar", "Maldives",
                  "Myanmar", "Montenegro", "Mozambique", "Mauritius", "Nepal", "Palestina", "Rwanda",
                  "São_Tomé_and_Príncipe", "South_Sudan", "Suriname", "Swaziland", "Syria", "Zambia", "Zimbabwe")
LMIC_climate_df <- LMIC_climate_df[!(LMIC_climate_df$Location %in% dropped_LMIC),]


# USA a little more complicated, we need to match state GID1 codes (USA.1_1 e.g.)
# to the 2-letter state codes in the imperial predictions file

# bring the states climate df to USA only
USA_states_climate <- states_climate_df[with(states_climate_df, grepl("USA", State)),]
# load the original GADM files again...
c(states, states_data) %<-% readRDS("clean-data/gadm-states.RDS")
US_data <- states_data[states_data$GID_0 == "USA",]
# check if the climate data and GADM data are in the same order of states
identical(as.character(USA_states_climate$State), US_data$GID_1)
# TRUE - so we can take the state codes in the GADM data ($HASC_1) and add them to our climate dataframe
USA_states_climate$State <- gsub("US.", "", US_data$HASC_1)

# now do the merge
USA_climate_df <- merge(USA_R0_df, USA_states_climate, by.x="Location", by.y = "State")
# and specifically for the US, we need to remove the states that clearly have
# R0 measured after lockdown measures have already started:
dropped_states <- c("AK", "HI", "MT", "ND", "SD", "UT", "WV", "WY")
USA_climate_df <- USA_climate_df[!(USA_climate_df$Location %in% dropped_states),]


# --- repeat this for the may data --- #

# Europe
europe_climate_df_may <- merge(europe_Rt_may, countries_climate_df, by.x = "Location", by.y = "Country")

# LMIC
LMIC_climate_df_may <- merge(LMIC_Rt_may, countries_climate_df, by.x = "Location", by.y = "Country")
# need to drop the countries with unreliable Rt estimates as before
LMIC_climate_df_may <- LMIC_climate_df_may[!(LMIC_climate_df_may$Location %in% dropped_LMIC),]

# USA
USA_climate_df_may <- merge(USA_Rt_may, USA_states_climate, by.x="Location", by.y = "State")
# don't need to drop any states this time because we're all post-lockdown anyway!


###########################################
# --- Step 4: add the google mobility --- #
# --- data for each country/state     --- #
###########################################

# The LMIC methods do the following:
# We incorporate interventions using mobility data made publically available from Google, 
# which provides data on movement in each country and includes the percent change in visits to 
# places of interest (Grocery & Pharmacy, Parks, Transit Stations, Retail & Recreation, Residential, and Workplaces). 
# imilar to Version 1, we assume that mobility changes will reduce contacts outside the household, 
# whereas the increase in residential movement will not change household contacts.
# Consequently, we assume that the change in transmission over time can be summarised by averaging 
# the mobility trends for all categories except for Residential and Parks (in which we assume significant contact events are negligable).

# we'll do the same for consistency.

mobility_data <- read.csv("raw-data/google-mobility.csv")
mobility_data$country_region_simple <- gsub(" ", "_", mobility_data$country_region)
mobility_data$date <- as.Date(mobility_data$date)

# loop through and take the mean reduction in mobility for retail, grocery, transit and workplaces for May 
# as a measure of lockdown intensity
# cut the data to May only first then (as our climate data is monthly, we should work in months)
may_mobility_data <- mobility_data[mobility_data$date >= "2020-05-01" & mobility_data$date < "2020-06-01",]

# these data are percentage changes from a baseline, i.e. -50 is 50% reduction (or 0.5x original mobility),
# 50 is 50% increase (or 1.5x original mobility). A little confusing.
# I'm going to frame it as "lockdown strength", a positive integer (0-100) of how strong lockdown is,
# i.e. the negative of the percent change from baseline

# Europe first
europe_climate_df_may$lockdown_strength <- NA
country_names <- unique(as.character(europe_climate_df_may$Location))
for(i in 1:length(country_names)){
  subs_mobility <- may_mobility_data[may_mobility_data$country_region_simple == country_names[i],]
  avg_mobility_changes <- c(mean(subs_mobility$retail_and_recreation_percent_change_from_baseline, na.rm = TRUE),
                            mean(subs_mobility$grocery_and_pharmacy_percent_change_from_baseline, na.rm = TRUE),
                            mean(subs_mobility$transit_stations_percent_change_from_baseline, na.rm = TRUE),
                            mean(subs_mobility$workplaces_percent_change_from_baseline, na.rm = TRUE))
  europe_climate_df_may[europe_climate_df_may$Location == country_names[i],]$lockdown_strength <- 
    -mean(avg_mobility_changes, na.rm = TRUE)
}

# LMICs
LMIC_climate_df_may$lockdown_strength <- NA
country_names <- unique(as.character(LMIC_climate_df_may$Location))
for(i in 1:length(country_names)){
  subs_mobility <- may_mobility_data[may_mobility_data$country_region_simple == country_names[i],]
  avg_mobility_changes <- c(mean(subs_mobility$retail_and_recreation_percent_change_from_baseline, na.rm = TRUE),
                            mean(subs_mobility$grocery_and_pharmacy_percent_change_from_baseline, na.rm = TRUE),
                            mean(subs_mobility$transit_stations_percent_change_from_baseline, na.rm = TRUE),
                            mean(subs_mobility$workplaces_percent_change_from_baseline, na.rm = TRUE))
  if(!is.na(mean(avg_mobility_changes, na.rm = TRUE))){
    LMIC_climate_df_may[LMIC_climate_df_may$Location == country_names[i],]$lockdown_strength <- 
      -mean(avg_mobility_changes, na.rm = TRUE)
  }
}

# USA
USA_climate_df_may$lockdown_strength <- NA
state_names <- unique(as.character(USA_climate_df_may$Location))
USA_mobility <- may_mobility_data[may_mobility_data$country_region_simple == "United_States",]
USA_mobility$state_simple <- gsub('.{3}', '', USA_mobility$iso_3166_2_code)
for(i in 1:length(state_names)){
  subs_mobility <- USA_mobility[USA_mobility$state_simple == state_names[i],]
  avg_mobility_changes <- c(mean(subs_mobility$retail_and_recreation_percent_change_from_baseline, na.rm = TRUE),
                            mean(subs_mobility$grocery_and_pharmacy_percent_change_from_baseline, na.rm = TRUE),
                            mean(subs_mobility$transit_stations_percent_change_from_baseline, na.rm = TRUE),
                            mean(subs_mobility$workplaces_percent_change_from_baseline, na.rm = TRUE))
  if(!is.na(mean(avg_mobility_changes, na.rm = TRUE))){
    USA_climate_df_may[USA_climate_df_may$Location == state_names[i],]$lockdown_strength <- 
      -mean(avg_mobility_changes, na.rm = TRUE)
  }
}


########################################
# -- Step 5: bind these all together   #
# -- into a single dataset and export  #
########################################

full_climate_df_R0 <- rbind(europe_climate_df, LMIC_climate_df, USA_climate_df)
full_climate_df_lockdown <- rbind(europe_climate_df_may, LMIC_climate_df_may, USA_climate_df_may)

write.csv(full_climate_df_R0, "clean-data/climate_and_R0.csv", row.names = FALSE)
write.csv(full_climate_df_lockdown, "clean-data/climate_and_lockdown_Rt.csv", row.names = FALSE)
