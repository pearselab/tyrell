# does mobility vary with environment?
# i.e. do people go to the park when its warm? :D

source("src/packages.R")

mobility_data <- read.csv("raw-data/google-mobility.csv")

countries_temperature <- readRDS("clean-data/temp-midday-countries.RDS")
states_temperature <- readRDS("clean-data/temp-midday-states.RDS")

# just do this for the USA states first
# for each state we want daily mobility and daily temperature
# df: state, date, temperature, mobility_x, mobility_y, etc...

US_mobility <- mobility_data[mobility_data$country_region_code == "US" & !is.na(mobility_data$country_region_code),]
head(US_mobility)
unique(US_mobility$sub_region_1)
# needs to be only the data with state codes (i.e. exclude the counties)
state_codes <- levels(as.factor(as.character(US_mobility$iso_3166_2_code)))[2:52]
US_mobility$iso_3166_2_code <- as.character(US_mobility$iso_3166_2_code)
US_mobility <- US_mobility[US_mobility$iso_3166_2_code %in% state_codes,]
US_mobility$date <- as.Date(US_mobility$date)

c(states, states_data) %<-% readRDS("clean-data/gadm-states.RDS")
US_data <- states_data[states_data$GID_0 == "USA",]

US_temperature <- states_temperature[US_data$GID_1,]
# swap the row names to proper state names to match mobility data
rownames(US_temperature) <- as.character(unique(US_data$NAME_1))

# make into a long dataframe
US_temperature <- as.data.frame(as.table(US_temperature))
names(US_temperature) <- c("State", "Date", "Temperature")
US_temperature$Date <- as.Date(US_temperature$Date)

# merge mobility and temperature based on state + date
combined_data <- merge(US_temperature, US_mobility, by.x = c("State", "Date"), by.y = c("sub_region_1", "date"))

# we'll loop it and diff each state then join together
state_names <- unique(as.character(combined_data$State))
Temperature_diff <- c()
mobility_diff <- c()
state_label <- c()

for(i in 1:length(state_names)){
  state_subs <- combined_data[combined_data$State == state_names[i],]
  Temperature_diff <- c(Temperature_diff, diff(state_subs$Temperature))
  mobility_diff <- c(mobility_diff, diff(state_subs$parks_percent_change_from_baseline))
  state_label <- c(state_label, rep(state_names[i], length(diff(state_subs$parks_percent_change_from_baseline))))
}

state_diffs <- data.frame(state_label, Temperature_diff, mobility_diff)

ggplot(state_diffs, aes(x = Temperature_diff, y = mobility_diff)) + geom_point()

summary(lm(mobility_diff ~ Temperature_diff, data = state_diffs))

cor.test(state_diffs$Temperature_diff, state_diffs$mobility_diff)