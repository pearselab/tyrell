##################################################
# Join the UK Rt and environmental data together #
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

# function to add area names to the climate data then make it long
make_long <- function(df, clim_var){
  df$area <- row.names(df)
  return(pivot_longer(df,
                      cols = c(1:(ncol(df)-1)),
                      names_to = "date",
                      values_to = clim_var))
}


### Main code ###

# load Rt data
UK_Rt <- read.csv("raw-data/cases/imperial-uk-pred.csv")

UK_Rt$date <- as.Date(UK_Rt$date)

# merge the climate data together

uk_temperature <- as.data.frame(readRDS("clean-data/temp-UK-LTLA.RDS"))
uk_temperature_long <- make_long(uk_temperature, "temperature")

uk_humidity <- as.data.frame(readRDS("clean-data/humid-UK-LTLA.RDS"))
uk_humidity_long <- make_long(uk_humidity, "relative_humidity")

uk_uv <- as.data.frame(readRDS("clean-data/uv-UK-LTLA.RDS"))
uk_uv_long <- make_long(uk_uv, "uv")

# uk_pm2pt5 <- as.data.frame(readRDS("clean-data/pm2pt5-UK-LTLA.RDS"))
# uk_pm2pt5_long <- make_long(uk_pm2pt5, "pm2pt5")

# merge together
# climate_data <- cbind(uk_temperature_long, uk_humidity_long[,c("relative_humidity")], uk_uv_long[,c("uv")], uk_pm2pt5_long[,c("pm2pt5")])
climate_data <- cbind(uk_temperature_long, uk_humidity_long[,c("relative_humidity")], uk_uv_long[,c("uv")])

# calculate absolute humidity
climate_data$absolute_humidity <- calc_AH(RH = climate_data$relative_humidity, e_0 = 6.11, T_0 = 273.15,
                                          temp = climate_data$temperature+273.15)

# 5. merge pop density in

uk_popdensity <- as.data.frame(readRDS("clean-data/population-density-UK-LTLA.RDS"))
uk_popdensity$area <- row.names(uk_popdensity)

climate_data <- merge(climate_data, uk_popdensity, by.x = "area", by.y = "area")


# 6. Merge Rt and climate data

UK_Rt <- merge(UK_Rt, climate_data, by.x = c("area", "date"), by.y = c("area", "date"))


# merge mobility in
mobility_data <- read.csv("raw-data/uk-ltla-mobility.csv")

names(mobility_data)[15] <- "area"
mobility_data$date <- as.Date(mobility_data$date)

UK_Rt <- join(x = UK_Rt, y = mobility_data[,8:15], by = c("area", "date"), type = "left")


# 7. Get R0 and Rt data and estimate climate variables according to dates of estimates

# for each state, take R(t=0) as R0
UK_R0 <- data.frame(UK_Rt %>% 
                       group_by(area) %>% 
                       slice(which.min(date)))

# remove areas where Rt=0 occurs later than lockdown
lockdown_data <- read.csv("raw-data/imperial-interventions.csv")
lockdown_data <- lockdown_data[lockdown_data$Country == "United_Kingdom",]


UK_R0 <- UK_R0[UK_R0$date <= as.Date(as.character(lockdown_data[lockdown_data$Type == "Lockdown",]$Date.effective),
                                     format = "%d.%m.%y"),]


# now add a temperature variable, which is the average
# daily midday temperature, in the 2 weeks preceeding R(t=0)
# do the same for humidity/uv
# the average is weighted by the distribution of the serial interval (see Flaxman - gamma(6.5, 0.62))
area_list <- unique(as.character(UK_R0$area))
UK_R0$temperature <- NA
UK_R0$relative_humidity <- NA
UK_R0$absolute_humidity <- NA
UK_R0$uv <- NA


for(i in 1:length(area_list)){ # unweighted mean
  t <- UK_R0[UK_R0$area == area_list[i],]$date
  area_temp <- climate_data[climate_data$area == area_list[i] &
                               climate_data$date >= t-14 &
                               climate_data$date <= t,]

  UK_R0[UK_R0$area == area_list[i],]$temperature <- mean(area_temp$temperature, na.rm = TRUE)
  UK_R0[UK_R0$area == area_list[i],]$relative_humidity <- mean(area_temp$relative_humidity, na.rm = TRUE)
  UK_R0[UK_R0$area == area_list[i],]$absolute_humidity <- mean(area_temp$absolute_humidity, na.rm = TRUE)
  UK_R0[UK_R0$area == area_list[i],]$uv <- mean(area_temp$uv, na.rm = TRUE)

}

names(UK_R0) <- c("Area", "Date", "R0_lower", "R0", "R0_upper", "coverage", "Temperature", "Relative_humidity", "UV", "Absolute_humidity", 
                  "Pop_density", "retail", "grocery", "parks", "transit", "workplace", "residential")

# write out for later
write.csv(UK_R0, "clean-data/climate_and_R0_UK.csv", row.names = FALSE)

write.csv(UK_Rt, "clean-data/daily_climate_and_Rt_UK.csv", row.names = FALSE)
