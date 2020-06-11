###########################################################
# Regress Rt against environment for Imperial predictions #
###########################################################

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


########################################################
# -- Step 1: load the various climate data and bind -- #
# -- together into a single data frame              -- #
########################################################

# temperature
countries_temperature <- readRDS("clean-data/worldclim-countries.RDS")
states_temperature <- readRDS("clean-data/worldclim-states.RDS")

# humidity
countries_humidity <- readRDS("clean-data/humidity-countries.RDS")
states_humidity <- readRDS("clean-data/humidity-states.RDS")

# population density
countries_popdensity <- readRDS("clean-data/population-density-countries.RDS")
states_popdensity <- readRDS("clean-data/population-density-states.RDS")

# order is the same - as it should be, its all been done in the same way
identical(row.names(countries_temperature), row.names(countries_popdensity))
identical(row.names(countries_temperature), row.names(countries_humidity))

# put all of the climate/population data into 1 massive dataframe
countries_climate_df <- cbind(row.names(countries_temperature),
                              as.data.frame(countries_temperature, row.names = FALSE),
                              as.data.frame(countries_humidity, row.names = FALSE),
                              as.data.frame(countries_popdensity, row.names = FALSE))
names(countries_climate_df)[1] <- "Country"

# repeat for states - check names match first
identical(row.names(states_temperature), row.names(states_popdensity))
identical(row.names(states_temperature), row.names(states_humidity))

states_climate_df <- cbind(row.names(states_temperature),
                              as.data.frame(states_temperature, row.names = FALSE),
                              as.data.frame(states_humidity, row.names = FALSE),
                              as.data.frame(states_popdensity, row.names = FALSE))
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
LMIC_data <- read.csv("~/Documents/COVID/2020-06-06_v2.csv")
# need to strip this down to only the Rt data
LMIC_Rt <- LMIC_data[LMIC_data$compartment == "Rt" & LMIC_data$scenario == "Maintain Status Quo",]

# -- US states -- #
USA_Rt <- read.csv("raw-data/imperial-usa-pred.csv")

# make date columns for everything
europe_Rt$date <- as.Date(europe_Rt$time)
europe_lockdown$date <- as.Date(europe_lockdown$Date.effective, format = "%d.%m.%y")
LMIC_Rt$date <- as.Date(LMIC_Rt$date)
USA_Rt$date <- as.Date(USA_Rt$date)


# -- Get "R0" from Rt estimates -- #
# for now, we're going to very simply estimate
# R0 as the earliest (i.e. date) Rt estimate
# they're in order from earlier to latest date
# so we can just match unique to get the first value

europe_R0 <- europe_Rt[match(unique(europe_Rt$country), europe_Rt$country),]
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



########################################################
# -- Step 3: combine the Rt data with climate data --- #
########################################################

# as lockdown happened in early March basically everywhere, but the pandemic didn't get
# going in some places until feb, maybe the sensible (albeit coarse) thing to do, is
# take the climate parameters for february only? 
#
# later on we can think about complicating it by doing something about the
# date when R0 was estimated from... or something?
#


# first we can just merge the climate data into the countries/states datasets
europe_climate_df <- merge(europe_R0_df, countries_climate_df, by.x = "Location", by.y = "Country")
LMIC_climate_df <- merge(LMIC_R0_df, countries_climate_df, by.x = "Location", by.y = "Country")

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


######################################
# -- Step 4: bind these all together #
# -- and do regressions/plotting     #
######################################

full_climate_df <- rbind(europe_climate_df, LMIC_climate_df, USA_climate_df)


# -- plot everything just to have a look -- #


# temperature
all_plot_temperature <- ggplot(full_climate_df, aes(x = February.tmean, y = R0)) + 
  geom_point(aes(fill = dataset), shape = 21, size = 3, alpha = 0.8) +
  geom_smooth(method = lm) +
  labs(x = expression(paste("Mean Temperature (", degree*C, ")")), y = expression(R[0])) +
  #geom_text(aes(label = Location), hjust = 0, vjust = 0, position = position_nudge(y = 0.05)) +
  main_theme +
  theme(legend.title = element_blank())
all_plot_temperature

# humidity
all_plot_humidity <- ggplot(full_climate_df, aes(x = February_20, y = R0)) + 
  geom_point(aes(fill = dataset), shape = 21, size = 3, alpha = 0.8) +
  geom_smooth(method = lm) +
  labs(x = "Relative Humidity", y = expression(R[0])) +
  #geom_text(aes(label = Location), hjust = 0, vjust = 0, position = position_nudge(y = 0.05)) +
  main_theme +
  theme(legend.title = element_blank())
all_plot_humidity

# population density
all_plot_popdensity <- ggplot(full_climate_df, aes(x = Pop_density, y = R0)) + 
  geom_point(aes(fill = dataset), shape = 21, size = 3, alpha = 0.8) +
  geom_smooth(method = lm) +
  labs(x = "Population Density (people per sq. km)", y = expression(R[0])) +
  #geom_text(aes(label = Location), hjust = 0, vjust = 0, position = position_nudge(y = 0.05)) +
  main_theme +
  theme(legend.title = element_blank())
all_plot_popdensity


# Interesting USA plots:
USA_plot_temperature <-  ggplot(full_climate_df[full_climate_df$dataset == "USA",], aes(x = February.tmean, y = R0)) + 
  geom_point(aes(fill = dataset), shape = 21, size = 3, alpha = 0.8) +
  geom_smooth(method = lm) +
  labs(x = expression(paste("Median February Temperature (", degree*C, ")")), y = expression(R[0])) +
  geom_text(aes(label = Location), hjust = 0, vjust = 0, position = position_nudge(y = 0.05)) +
  main_theme +
  theme(legend.position = "none")
USA_plot_temperature  

USA_plot_popdensity <-  ggplot(full_climate_df[full_climate_df$dataset == "USA",], aes(x = Pop_density, y = R0)) + 
  geom_point(aes(fill = dataset), shape = 21, size = 3, alpha = 0.8) +
  geom_smooth(method = lm) +
  labs(x = expression(paste("Population Density (People ", km^-2, ")")), y = expression(R[0])) +
  geom_text(aes(label = Location), hjust = 0, vjust = 0, position = position_nudge(y = 0.05)) +
  main_theme +
  theme(legend.position = "none")
USA_plot_popdensity

USA_plot_humidity <-  ggplot(full_climate_df[full_climate_df$dataset == "USA",], aes(x = February_20, y = R0)) + 
  geom_point(aes(fill = dataset), shape = 21, size = 3, alpha = 0.8) +
  geom_smooth(method = lm) +
  labs(x = "Relative Humidity", y = expression(R[0])) +
  geom_text(aes(label = Location), hjust = 0, vjust = 0, position = position_nudge(y = 0.05)) +
  main_theme +
  theme(legend.position = "none")
USA_plot_humidity


png("figures/USA_plots.png", width = 1000)
grid.arrange(USA_plot_temperature, USA_plot_popdensity, nrow = 1)
dev.off()

# --- regression models --- #


full_regression_model <- lm(R0 ~ February.tmean + February_20 + Pop_density, data = full_climate_df)
summary(full_regression_model)

full_regression_model_no_humidity <- lm(R0 ~ February.tmean + Pop_density, data = full_climate_df)
summary(full_regression_model_no_humidity)

Europe_regression_model <- lm(R0 ~ February.tmean + February_20 + Pop_density, data = full_climate_df[full_climate_df$dataset == "Europe",])
summary(Europe_regression_model)

LMIC_regression_model <- lm(R0 ~ February.tmean + February_20 + Pop_density, data = full_climate_df[full_climate_df$dataset == "LMIC",])
summary(LMIC_regression_model)

USA_regression_model <- lm(R0 ~ February.tmean + February_20 + Pop_density, data = full_climate_df[full_climate_df$dataset == "USA",])
summary(USA_regression_model)


# should we transform pop density?
ggplot(full_climate_df, aes(x = Pop_density)) + geom_histogram()
ggplot(full_climate_df, aes(x = sqrt(Pop_density))) + geom_histogram()
ggplot(full_climate_df, aes(x = log(Pop_density))) + geom_histogram()
# guess we'd better log it to make it more normally distributed