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
  png("figures/mobility_versus_time.png", width = 1000, height = 1000)
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


if(FALSE){ # can plot to see which states are already in lockdown when Rt is calculated
  
  png("figures/mobility_versus_time.png", width = 1000, height = 1000)
  ggplot(USA_Rt, aes(x = as.Date(date), y = average_mobility_change)) +
    geom_line() +
    geom_hline(yintercept = -20, colour = "red", linetype = "dashed") +
    geom_vline(aes(xintercept = emergency_decree)) +
    geom_vline(aes(xintercept = stay_at_home), colour = "blue") +
    geom_vline(aes(xintercept = stay_at_home+14), colour = "green") +
    facet_wrap(~state)
  dev.off()
  
  png("figures/Rt_versus_time.png", width = 1000, height = 1000)
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


# 6. Merge Rt and climate data

USA_Rt <- merge(USA_Rt, climate_data, by.x = c("state", "date"), by.y = c("State", "date"))


# 7. Get R0 and Rt data and estimate climate variables according to dates of estimates

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
}

USA_R0 <- USA_R0[,c("state", "mean_time_varying_reproduction_number_R.t.", "temperature", "absolute_humidity", "uv", "Pop_density",
                    "average_mobility_change")]
names(USA_R0) <- c("State", "R0", "Temperature", "Absolute_Humidity", "UV", "Pop_density", "Avg_mobility_change")



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
mobility_change <- c()

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
  mobility_change <- c(mobility_change, mean(Rt_window$average_mobility_change))
  state <- c(state, states_list[i])
}

USA_Rt_df <- data.frame(Rt, temperature, humidity, uv, state, pop_density, mobility_change)
names(USA_Rt_df) <- c("Rt", "Temperature", "Absolute_Humidity", "UV", "State", "Pop_density", "Avg_mobility_change")

names(USA_Rt)[11] <- "Rt"

# write out for later
write.csv(USA_R0, "clean-data/climate_and_R0_USA.csv", row.names = FALSE)
write.csv(USA_Rt_df, "clean-data/climate_and_lockdown_Rt_USA.csv", row.names = FALSE)

write.csv(USA_Rt, "clean-data/daily_climate_and_Rt_USA.csv", row.names = FALSE)
