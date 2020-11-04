##################################################
# Join the R0/Rt and environmental data together #
##################################################

source("src/packages.R")

### Functions ####

# calculate absolute humididy from relative humidity
calc_AH <- function(RH, e_0, T_0, temp){
  L <- 2257000
  Rv <- 461.53
  return(
    
    1000*( (e_0 * exp((L/Rv)*(1/T_0 - 1/temp))) * RH /
            (Rv*temp))
    
  )
}

# function to add state names to the climate data then make it long long
make_long <- function(df, clim_var){
  df$State <- row.names(df)
  USA_df <- df[with(df, grepl("USA", State)),]
  USA_df$State <- gsub("US.", "", US_data$HASC_1)
  return(pivot_longer(USA_df,
                      cols = c(1:(ncol(USA_df)-1)),
                      names_to = "date",
                      values_to = clim_var))
}


### Main code ###

# 1. load Rt data
USA_Rt <- read.csv("raw-data/cases/imperial-usa-pred-2020-05-25.csv")

USA_Rt$date <- as.Date(USA_Rt$date)


# 2. merge in google mobility data

mobility_data <- read.csv("raw-data/google-mobility.csv")
mobility_data$country_region_simple <- gsub(" ", "_", mobility_data$country_region)
mobility_data$date <- as.Date(mobility_data$date)

USA_mobility <- mobility_data[ mobility_data$country_region_simple == "United_States",]
USA_mobility$state_simple <- gsub('.{3}', '', USA_mobility$iso_3166_2_code)

# calculate an overall "average mobility change" for the types of mobility used in the model:
# everything except parks and residential
USA_mobility$average_mobility_change <- rowMeans(USA_mobility[,c("retail_and_recreation_percent_change_from_baseline",
                                                                 "grocery_and_pharmacy_percent_change_from_baseline",
                                                                 "workplaces_percent_change_from_baseline")])

# subset to state-level data only
USA_mobility_states <- USA_mobility[USA_mobility$state_simple != "",]

# merge the mobility into the Rt data
USA_Rt <- merge(USA_Rt, USA_mobility_states[,c("date", "state_simple", "average_mobility_change")], 
                by.x = c("state", "date"), by.y = c("state_simple", "date"))


if(FALSE){ # visualising mobility through time
  png("ms-env/mobility_versus_time.png", width = 1000, height = 1000)
  ggplot(USA_mobility_states, aes(x = as.Date(date), y = average_mobility_change)) +
    geom_line() +
    geom_hline(yintercept = -20) +
    facet_wrap(~state_simple)
  dev.off()
}


# 3. merge the interventions data

interventions <- read.csv("raw-data/USstatesCov19distancingpolicy.csv")
# bring to emergency decrees
emergency_decrees <- interventions[interventions$StatePolicy == "EmergDec",]

# Oklahoma and south dakota both have 2 emergency decrees - take the earliest declared in each case
emergency_decrees <- emergency_decrees[-c(17, 25, 40, 46),]

USA_Rt <- merge(USA_Rt, emergency_decrees[,c("StatePostal", "DateIssued")], by.x = "state", by.y = "StatePostal")
names(USA_Rt)[18] <- "emergency_decree"
USA_Rt$emergency_decree <- as.Date(as.character(USA_Rt$emergency_decree), "%Y%m%d")

# do the same for stay at home orders
stay_at_home <- interventions[interventions$StatePolicy == "StayAtHome",]
stay_at_home <- stay_at_home[stay_at_home$StateWide == 1,]

# take only 1 from each state
stay_at_home <- stay_at_home[-c(2, 34, 39),]

USA_Rt <- merge(USA_Rt, stay_at_home[,c("StatePostal", "DateEnacted")], by.x = "state", by.y = "StatePostal")
names(USA_Rt)[19] <- "stay_at_home"
USA_Rt$stay_at_home <- as.Date(as.character(USA_Rt$stay_at_home), "%Y%m%d")

# also get the dates of the first 10 deaths

date_first_ten <- readRDS("ext-data/dates_ten.RDS")
names(date_first_ten)[2] <- "date_first_ten"
USA_Rt <- merge(USA_Rt, date_first_ten, by.x = "state", by.y = "code")
USA_Rt$date_first_ten <- as.Date(USA_Rt$date_first_ten)


if(FALSE){ # can plot to see which states are already in lockdown when Rt is calculated
  
  png("ms-env/mobility_versus_time.png", width = 1000, height = 1000)
  ggplot(USA_Rt, aes(x = as.Date(date), y = average_mobility_change)) +
    geom_line() +
    geom_hline(yintercept = -20, colour = "red", linetype = "dashed") +
    geom_vline(aes(xintercept = emergency_decree)) +
    geom_vline(aes(xintercept = stay_at_home), colour = "blue") +
    geom_vline(aes(xintercept = stay_at_home+14), colour = "green") +
    facet_wrap(~state)
  dev.off()
  
  png("ms-env/Rt_versus_time.png", width = 1000, height = 1000)
  ggplot(USA_Rt, aes(x = as.Date(date), y = mean_time_varying_reproduction_number_R.t.)) +
    geom_line() +
    geom_hline(yintercept = 1, colour = "red", linetype = "dashed") +
    geom_vline(aes(xintercept = emergency_decree)) +
    geom_vline(aes(xintercept = stay_at_home), colour = "blue") +
    geom_vline(aes(xintercept = stay_at_home+14), colour = "green") +
    facet_wrap(~state)
  dev.off()

}

# 4. merge the climate data together

# load the original GADM files again...
states_data <- shapefile("clean-data/gadm-states.shp")
US_data <- states_data[states_data$GID_0 == "USA",]

# temperature
states_temperature <- as.data.frame(readRDS("clean-data/temp-dailymean-states.RDS"))
USA_temperature_long <- make_long(df = states_temperature, clim_var = "temperature")

# humidity
states_humidity <- as.data.frame(readRDS("clean-data/humid-dailymean-states.RDS"))
USA_humidity_long <- make_long(df = states_humidity, clim_var = "relative_humidity")

# UV
states_uv <- as.data.frame(readRDS("clean-data/uv-dailymean-states.RDS"))
USA_uv_long <- make_long(df = states_uv, clim_var = "uv")

# merge together
climate_data <- cbind(USA_temperature_long, USA_humidity_long[,c("relative_humidity")], USA_uv_long[,c("uv")])

# calculate absolute humidity
climate_data$absolute_humidity <- calc_AH(RH = climate_data$relative_humidity, e_0 = 6.11, T_0 = 273.15, 
                                                          temp = climate_data$temperature+273.15)

# 5. merge pop density in

states_popdensity <- as.data.frame(readRDS("clean-data/population-density-states.RDS"))
states_popdensity$State <- row.names(states_popdensity)
USA_states_popdensity <- states_popdensity[with(states_popdensity, grepl("USA", State)),]
USA_states_popdensity$State <- gsub("US.", "", US_data$HASC_1)

climate_data <- merge(climate_data, USA_states_popdensity, by.x = "State", by.y = "State")

# and also total population

states_population <- read.csv("raw-data/usa-regions.csv")
climate_data <- merge(climate_data, states_population[,c("code", "pop_count")], by.x = "State", by.y = "code")

# 6. add in urban population (2010 census)
# download is here: https://www.icip.iastate.edu/sites/default/files/uploads/tables/population/pop-urban-pct-historical.xls

# urban_pop_data <- read.xls("~/Documents/COVID/testing/pop-urban-pct-historical.xls", pattern = "FIPS", sheet = 2)
urban_pop_data <- read.xls("raw-data/pop-urban-pct-historical.xls", pattern = "FIPS", sheet = 2)
urban_pop_data <- urban_pop_data[,c("Area.Name", "X2010")]
names(urban_pop_data) <- c("State_name", "Urban_pop")
# match 2-letter state codes to state names
urban_pop_data$State <- mapply(function(x) gsub("US.", "", US_data[US_data$NAME_1 == x,]$HASC_1), urban_pop_data$State_name)

climate_data <- merge(climate_data, urban_pop_data[,c("Urban_pop", "State")], by.x = "State", by.y = "State")
climate_data$Total_urban_pop <- climate_data$pop_count*climate_data$Urban_pop*0.01

# 7. Merge Rt and climate data

USA_Rt <- merge(USA_Rt, climate_data, by.x = c("state", "date"), by.y = c("State", "date"))

# 8. Pull in the airport data for later

airport_data <- read.csv("clean-data/airport_data.csv")
airport_data$Date <- as.Date(as.character(airport_data$Date))

# 9. Get R0 and Rt data and estimate climate variables according to dates of estimates

# for each state, take R(t=0) as R0
USA_R0 <- data.frame(USA_Rt %>% 
  group_by(state) %>% 
  slice(which.min(date)))

# remove states where an emergency decree was issued
# before the R0 estimate

USA_R0 <- USA_R0[USA_R0$date <= USA_R0$emergency_decree,]

# now add a temperature variable, which is the average
# daily midday temperature, in the 2 weeks preceeding R(t=0)
# do the same for humidity/uv
# the average is weighted by the distribution of the serial interval (see Flaxman - gamma(6.5, 0.62))
states_list <- unique(as.character(USA_R0$state))
USA_R0$temperature <- NA
USA_R0$relative_humidity <- NA
USA_R0$absolute_humidity <- NA
USA_R0$uv <- NA
USA_R0$avg_mobility_change <- NA
USA_R0$airport_arrivals <- NA

if(FALSE){
for(i in 1:length(states_list)){
  t <- USA_R0[USA_R0$state == states_list[i],]$date
  state_temp <- climate_data[climate_data$State == states_list[i] &
                                       climate_data$date >= t-14 &
                                       climate_data$date <= t,]
  state_mob <- USA_mobility_states[USA_mobility_states$state_simple == states_list[i] & 
                                     USA_mobility_states$date >= t-14 & 
                                     USA_mobility_states$date <= t,]
  USA_R0[USA_R0$state == states_list[i],]$temperature <- weighted.mean(state_temp$temperature, #
                                                                       w = dgamma(seq(1,15,1), shape =  6.5, scale = 0.62),
                                                                       na.rm = TRUE)
  USA_R0[USA_R0$state == states_list[i],]$absolute_humidity <- weighted.mean(state_temp$absolute_humidity, #
                                                                             w = dgamma(seq(1,15,1), shape =  6.5, scale = 0.62),
                                                                             na.rm = TRUE)
  USA_R0[USA_R0$state == states_list[i],]$uv <- weighted.mean(state_temp$uv, #
                                                                             w = dgamma(seq(1,15,1), shape =  6.5, scale = 0.62),
                                                                             na.rm = TRUE)
  USA_R0[USA_R0$state == states_list[i],]$avg_mobility_change <- weighted.mean(state_mob$average_mobility_change, #
                                                              w = dgamma(seq(1,15,1), shape =  6.5, scale = 0.62),
                                                              na.rm = TRUE)
}
}

for(i in 1:length(states_list)){ # unweighted mean
  t <- USA_R0[USA_R0$state == states_list[i],]$date
  state_temp <- climate_data[climate_data$State == states_list[i] &
                               climate_data$date >= t-14 &
                               climate_data$date <= t,]
  state_mob <- USA_mobility_states[USA_mobility_states$state_simple == states_list[i] & 
                                     USA_mobility_states$date >= t-14 & 
                                     USA_mobility_states$date <= t,]
  USA_R0[USA_R0$state == states_list[i],]$temperature <- mean(state_temp$temperature, na.rm = TRUE)
  USA_R0[USA_R0$state == states_list[i],]$absolute_humidity <- mean(state_temp$absolute_humidity, na.rm = TRUE)
  USA_R0[USA_R0$state == states_list[i],]$uv <- mean(state_temp$uv, na.rm = TRUE)
  USA_R0[USA_R0$state == states_list[i],]$avg_mobility_change <- mean(state_mob$average_mobility_change, na.rm = TRUE)
  # also get airport data in here
  state_airports <- airport_data[airport_data$State == states_list[i] &
                                   airport_data$Date >= t-14 &
                                   airport_data$Date <= t,]
  # check if the state actually has any airports, else give it zero
  if(nrow(state_airports) > 0){
    USA_R0[USA_R0$state == states_list[i],]$airport_arrivals <- sum(state_airports$Scheduled_Arrivals)
  }
  else{
    USA_R0[USA_R0$state == states_list[i],]$airport_arrivals <- 0
  }
}

USA_R0 <- USA_R0[,c("state", "date", "mean_time_varying_reproduction_number_R.t.", "temperature", "absolute_humidity", "uv", "Pop_density",
                    "pop_count", "Urban_pop", "Total_urban_pop", "average_mobility_change", "airport_arrivals", "emergency_decree",
                    "stay_at_home", "date_first_ten")]
names(USA_R0) <- c("State", "Date", "R0", "Temperature", "Absolute_Humidity", "UV", "Pop_density", "Pop_count", "Urban_pop",
                   "Total_urban_pop", "Avg_mobility_change", "Airport_arrivals", "Emergency_decree", "Stay_at_home", "Date_first_ten")



# Rt 
# For Rt during lockdown, we're going to try to take a mean
# Rt for the 2 weeks following a state-wide stay-at-home order
# as something generally reproducible across states

Rt <- c()
temperature <- c()
humidity <- c()
uv <- c()
state <- c()
pop_density <- c()
total_pop <- c()
urban_pop <- c()
urban_pop_total <- c()
mobility_change <- c()
airport_arrivals <- c()
emerg_dec <- c()
stay_home <- c()
date_ten <- c()

for(i in 1:length(states_list)){
  state_subs <- USA_Rt[USA_Rt$state == states_list[i],]
  t_min <- unique(state_subs$stay_at_home)
  t_max <- t_min+14
  Rt_window <- state_subs[state_subs$date >= t_min & 
                            state_subs$date <= t_max,]
  Rt <- c(Rt, mean(Rt_window$mean_time_varying_reproduction_number_R.t.))
  temperature <- c(temperature, mean(Rt_window$temperature))
  humidity <- c(humidity, mean(Rt_window$absolute_humidity))
  uv <- c(uv, mean(Rt_window$uv))
  pop_density <- c(pop_density, unique(Rt_window$Pop_density))
  total_pop <- c(total_pop, unique(Rt_window$pop_count))
  urban_pop <- c(urban_pop, unique(Rt_window$Urban_pop))
  urban_pop_total <- c(urban_pop_total, unique(Rt_window$Total_urban_pop))
  mobility_change <- c(mobility_change, mean(Rt_window$average_mobility_change))
  state <- c(state, states_list[i])
  emerg_dec <- c(emerg_dec, unique(Rt_window$emergency_decree))
  stay_home <- c(stay_home, unique(Rt_window$stay_at_home))
  date_ten <- c(date_ten, unique(Rt_window$date_first_ten))
  state_airports <- airport_data[airport_data$State == states_list[i] &
                                   airport_data$Date >= t_min &
                                   airport_data$Date <= t_max,]
  # check if the state actually has any airports, else give it zero
  if(nrow(state_airports) > 0){
    airport_arrivals <- c(airport_arrivals, sum(state_airports$Scheduled_Arrivals))
  }
  else{
    airport_arrivals <- c(airport_arrivals, 0)
  }
}

USA_Rt_df <- data.frame(Rt, temperature, humidity, uv, state, pop_density, total_pop, urban_pop, urban_pop_total, 
                        mobility_change, airport_arrivals, emerg_dec, stay_home, date_ten)
names(USA_Rt_df) <- c("Rt", "Temperature", "Absolute_Humidity", "UV", "State", "Pop_density", "Pop_count", "Urban_pop",
                      "Total_urban_pop", "Avg_mobility_change", "Airport_arrivals", "Emergency_decree", "Stay_at_home", "Date_first_ten")

names(USA_Rt)[11] <- "Rt"

# write out for later
write.csv(USA_R0, "clean-data/climate_and_R0_USA.csv", row.names = FALSE)
write.csv(USA_Rt_df, "clean-data/climate_and_lockdown_Rt_USA.csv", row.names = FALSE)

write.csv(USA_Rt, "clean-data/daily_climate_and_Rt_USA.csv", row.names = FALSE)
