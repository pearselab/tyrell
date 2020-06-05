########################################################
# Plot Rt against temperature for Imperial predictions #
########################################################

source("src/packages.R")

# plotting theme
main_theme <- theme_bw() + 
  theme(axis.text.x = element_text(size = 14),
        axis.text.y = element_text(size = 14),
        axis.title.y = element_text(size = 16),
        axis.title.x = element_text(size = 16),
        plot.title = element_text(size=16, vjust=1),
        legend.text=element_text(size=16),
        legend.title = element_text(size = 16),
        strip.text.x = element_text(size = 14))

# load the climate data
countries_climate <- readRDS("clean-data/worldclim-countries.RDS")

# change it to a dataframe
countries_climate_df <- cbind(row.names(countries_climate),
                              as.data.frame(countries_climate, row.names = FALSE))
names(countries_climate_df)[1] <- "Country"

# read the imperial predictions data
imperial_predictions <- read.csv("raw-data/imperial-europe-pred.csv")
imperial_lockdown <- read.csv("raw-data/imperial-interventions.csv")

# make date columns
imperial_predictions$date <- as.Date(imperial_predictions$time)
imperial_lockdown$date <- as.Date(imperial_lockdown$Date.effective, format = "%d.%m.%y")

# ------ Chop Rt predictions to pre-lockdown ------- #

# countries list
countries <- as.character(unique(imperial_predictions$country))

# loop through the countries and select
# only the pre-lockdown data for each

# first a df to put the resultant rows
pre_lockdown <- as.data.frame(matrix(NA, nrow = 0, ncol = ncol(imperial_predictions)))
names(pre_lockdown) <- names(imperial_predictions)

# now loop through the countries
for(i in 1:length(countries)){
  
  lockdown_date <- min(imperial_lockdown[imperial_lockdown$Country == countries[i],]$date, na.rm = TRUE)
  
  pred_subs <- imperial_predictions[imperial_predictions$country == countries[i] & 
                                      imperial_predictions$date < lockdown_date,]
  
  # bind into dataframe
  pre_lockdown <- rbind(pre_lockdown, pred_subs)
  
}
# I'm sure theres a much more elegant way to do that

# basic first steps - take a mean pre-lockdown Rt for each country
pre_lockdown_avs <- setNames(aggregate(pre_lockdown[,"mean_time_varying_reproduction_number_R.t."], list(pre_lockdown$country), mean),
                             c("Country", "Rt"))

# when is lockdown date for each country?
aggregate(date ~ Country, imperial_lockdown, function(x) min(x))
# early-mid march (greece late feb)

# -- add climate data -- #

# take a mean of jan-feb temps as lockdown mostly occurred early in march
countries_climate_df$pre_lockdown_tmean <- rowMeans(countries_climate_df[,c("January.tmean", "February.tmean", "March.tmean")], na.rm=TRUE)

plotting_data_countries <- merge(pre_lockdown_avs, countries_climate_df[, c("Country", "pre_lockdown_tmean")], by="Country")


# Now repeat for the USA data

# load data and turn into dataframe
states_climate <- readRDS("clean-data/worldclim-states.RDS")
states_climate_df <- cbind(row.names(states_climate),
                           as.data.frame(states_climate, row.names = FALSE))
names(states_climate_df)[1] <- "State"
# take the USA states
USA_states_climate <- states_climate_df[with(states_climate_df, grepl("USA", State)),]
# get the names to match with imperial's predictions (with 2-letter state codes)
# first load in our GADM datasets which should have the proper names in it
c(states, states_data) %<-% readRDS("clean-data/gadm-states.RDS")
US_data <- states_data[states_data$GID_0 == "USA",]

# check if the climate data and GADM data are in the same order of states
identical(as.character(USA_states_climate$State), US_data$GID_1)
# TRUE - so we can take the state codes in the GADM data ($HASC_1) and add them to our climate dataframe
USA_states_climate$State <- gsub("US.", "", US_data$HASC_1)

# imperial predictions for USA:
imperial_predictions_USA <- read.csv("raw-data/imperial-usa-pred.csv")
# make date column
imperial_predictions_USA$date <- as.Date(imperial_predictions_USA$date)

# for USA, take only the first Rt estimate (earliest date)
USA_pre_lockdown <- imperial_predictions_USA[match(unique(imperial_predictions_USA$state), imperial_predictions_USA$state),]
names(USA_pre_lockdown)[c(1,11)] <- c("State", "Rt")
USA_pre_lockdown <- USA_pre_lockdown[,c("State", "Rt")]

# make jan/feb mean climate
USA_states_climate$pre_lockdown_tmean <- rowMeans(USA_states_climate[,c("January.tmean", "February.tmean")], na.rm=TRUE)

plotting_data_states <- merge(USA_pre_lockdown, USA_states_climate[, c("State", "pre_lockdown_tmean")], by="State")

# and finally remove those data which were recorded after some distancing measures
dropped_states <- c("AK", "HI", "MT", "ND", "SD", "UT", "WV", "WY")
plotting_data_states <- plotting_data_states[!(plotting_data_states$State %in% dropped_states),]

# now bind the countries and states together so we can plot them at the same time
# with another field to differentiate them by
names(plotting_data_countries)[1] <- "Location"
names(plotting_data_states)[1] <- "Location"

plotting_data_countries$Location_type <- "Europe"
plotting_data_states$Location_type <- "USA"

plotting_data <- rbind(plotting_data_countries, plotting_data_states)

# all together
all_plot <- ggplot(plotting_data, aes(x = pre_lockdown_tmean, y = Rt)) + 
  geom_point(aes(fill = Location_type), shape = 21, size = 3, alpha = 0.8) +
  geom_smooth(method = lm) +
  labs(x = expression(paste("Mean Temperature (", degree*C, ")")), y = expression(R[t])) +
  geom_text(aes(label = Location), hjust = 0, vjust = 0, position = position_nudge(y = 0.05)) +
  main_theme +
  theme(legend.title = element_blank())
all_plot

# states seperate to europe
seperate_plot <- ggplot(plotting_data, aes(x = pre_lockdown_tmean, y = Rt, fill = Location_type)) + 
  geom_point(shape = 21, size = 3, alpha = 0.8) +
  geom_smooth(method = lm, aes(col = Location_type)) +
  labs(x = expression(paste("Mean Temperature (", degree*C, ")")), y = expression(R[t])) +
  geom_text(aes(label = Location), hjust = 0, vjust = 0, position = position_nudge(y = 0.05)) +
  main_theme +
  theme(legend.title = element_blank())
seperate_plot

EU_plot <- ggplot(plotting_data_countries, aes(x = pre_lockdown_tmean, y = Rt)) + 
  geom_point(size = 3, alpha = 0.8) +
  geom_smooth(method = lm) +
  xlim(-8, 11) +
  ylim(1, 6) +
  labs(x = expression(paste("Mean Temperature (", degree*C, ")")), y = expression(R[t])) +
  geom_text(aes(label = Location), hjust = 1, vjust = 0, position = position_nudge(y = 0.05)) +
  main_theme +
  theme(legend.title = element_blank()) +
  ggtitle("European Countries")
EU_plot

US_plot <- ggplot(plotting_data_states, aes(x = pre_lockdown_tmean, y = Rt)) + 
  geom_point(size = 3, alpha = 0.8) +
  geom_smooth(method = lm) +
  labs(x = expression(paste("Mean Temperature (", degree*C, ")")), y = expression(R[t])) +
  geom_text(aes(label = Location), hjust = 1, vjust = 0, position = position_nudge(y = 0.05)) +
  main_theme +
  theme(legend.title = element_blank()) +
  ggtitle("US States")
US_plot

ggsave("../figures/EU_US_plot.png", all_plot)
ggsave("../figures/EU_US_plot_seperate.png", seperate_plot)
ggsave("../figures/COVID/EU_plot.png", EU_plot)
ggsave("../figures/COVID/US_plot.png", US_plot)

linmod <- lm(Rt ~ pre_lockdown_tmean, data = plotting_data[plotting_data$Location_type == "USA",])
summary(linmod)
