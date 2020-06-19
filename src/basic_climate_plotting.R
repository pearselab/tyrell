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
# colourblind friendly palette
cbPalette <- c("#CC0000", "#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#999999", "#CC79A7")


########################################################
# -- Step 1: load the various climate data and bind -- #
# -- together into a single data frame              -- #
########################################################

# temperature
# countries_temperature <- readRDS("clean-data/worldclim-countries.RDS")
# states_temperature <- readRDS("clean-data/worldclim-states.RDS")
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
identical(row.names(countries_temperature), row.names(countries_popdensity))
identical(row.names(countries_temperature), row.names(countries_humidity))
identical(row.names(countries_temperature), row.names(countries_abs_humidity))
identical(row.names(countries_temperature), row.names(countries_uv))

# put all of the climate/population data into 1 massive dataframe
countries_climate_df <- cbind(row.names(countries_temperature),
                              as.data.frame(countries_temperature, row.names = FALSE),
                              as.data.frame(countries_humidity, row.names = FALSE),
                              as.data.frame(countries_abs_humidity, row.names = FALSE),
                              as.data.frame(countries_popdensity, row.names = FALSE),
                              as.data.frame(countries_uv, row.names = FALSE))
names(countries_climate_df)[1] <- "Country"

# repeat for states - check names match first
identical(row.names(states_temperature), row.names(states_popdensity))
identical(row.names(states_temperature), row.names(states_humidity))

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
OJ_data <- readRDS("ext-data/vars_for_will.rds")
LMIC_alternative <- data.frame(OJ_data[1])
names(LMIC_alternative) <- c("R0", "Rt_0", "Rt", "Rt_min", "Meff", "date", "iso", "max_mobility_change", "mobility_at_t0", "continent", "country")
# remove spaces from the country names
LMIC_alternative$country <- gsub(" ", "_", LMIC_alternative$country)

# -- US states -- #
USA_Rt <- read.csv("raw-data/imperial-usa-pred.csv")

# make date columns for everything
europe_Rt$date <- as.Date(europe_Rt$time)
europe_lockdown$date <- as.Date(europe_lockdown$Date.effective, format = "%d.%m.%y")
LMIC_Rt$date <- as.Date(LMIC_Rt$date)
LMIC_alternative$date <- as.Date(LMIC_alternative$date)
USA_Rt$date <- as.Date(USA_Rt$date)

# reorder the alternative LMIC data from earliest date to latest
LMIC_alternative_ordered <- LMIC_alternative[order(LMIC_alternative$date),]

# -- Get "R0" from Rt estimates -- #
# for now, we're going to very simply estimate
# R0 as the earliest (i.e. date) Rt estimate
# they're in order from earlier to latest date
# so we can just match unique to get the first value

europe_R0 <- europe_Rt[match(unique(europe_Rt$country), europe_Rt$country),]
LMIC_R0 <- LMIC_alternative_ordered[match(unique(LMIC_alternative_ordered$country), LMIC_alternative_ordered$country),]
USA_R0 <- USA_Rt[match(unique(USA_Rt$state), USA_Rt$state),]

# get these formatted the same for later
europe_R0_df <- europe_R0[,c("country", "mean_time_varying_reproduction_number_R.t.", "date")]
names(europe_R0_df) <- c("Location", "R0", "date")
europe_R0_df$dataset <- "Europe"

LMIC_R0_df <- LMIC_R0[,c("country", "R0", "date")]
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

# as lockdown happened in early March basically everywhere, but the pandemic didn't get
# going in some places until feb, maybe the sensible (albeit coarse) thing to do, is
# take the climate parameters for february only? 
#
# later on we can think about complicating it by doing something about the
# date when R0 was estimated from... or something?
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
                  "Myanmar", "Montenegro", "Mozambique", "Mauritius", "Nepal", "Rwanda", "South_Sudan",
                  "Suriname", "Eswatini", "Syria", "Zambia", "Zimbabwe")
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

######################################
# -- Step 4: bind these all together #
# -- and do regressions/plotting     #
######################################

full_climate_df_R0 <- rbind(europe_climate_df, LMIC_climate_df, USA_climate_df)

full_climate_df_lockdown <- rbind(europe_climate_df_may, LMIC_climate_df_may, USA_climate_df_may)


# should we transform pop density?
# ggplot(full_climate_df, aes(x = Pop_density)) + geom_histogram()
# ggplot(full_climate_df, aes(x = sqrt(Pop_density))) + geom_histogram()
# ggplot(full_climate_df, aes(x = log(Pop_density))) + geom_histogram()
# guess we'd better log it to make it more normally distributed


# -- plot everything just to have a look -- #


# temperature
all_plot_temperature <- ggplot(full_climate_df_R0, aes(x = February_20_TC, y = R0)) + 
  geom_point(aes(fill = dataset), shape = 21, size = 3, alpha = 0.6) +
  geom_smooth(method = lm, aes(col = dataset), se = FALSE, size = 2) +
  geom_smooth(method = lm, col = "black", size = 2) +
  labs(x = expression(paste("February Temperature (", degree*C, ")")), y = expression(R[0])) +
  scale_fill_manual(values=cbPalette) +
  scale_colour_manual(values=cbPalette) +
  main_theme +
  #annotate("text", x = -18, y = 5.5, label = "A", size = 10) +
  theme(legend.title = element_blank(),
        legend.position = c(0.2, 0.8))
all_plot_temperature

# relative humidity
all_plot_humidity_rel <- ggplot(full_climate_df_R0, aes(x = February_20_RH, y = R0)) + 
  geom_point(aes(fill = dataset), shape = 21, size = 3, alpha = 0.8) +
  geom_smooth(method = lm, col = "black") +
  labs(x = expression(paste("February Relative Humidity (", '%', ")")), y = expression(R[0])) +
  scale_fill_manual(values=cbPalette) +
  annotate("text", x = 15, y = 5.5, label = "B", size = 10) +
  main_theme +
  theme(legend.position = "none")
all_plot_humidity_rel

# absolute humidity
all_plot_humidity_abs <- ggplot(full_climate_df_R0, aes(x = February_20_AH, y = R0)) + 
  geom_point(aes(fill = dataset), shape = 21, size = 3, alpha = 0.8) +
  geom_smooth(method = lm, aes(col = dataset), se = FALSE, size = 2) +
  geom_smooth(method = lm, col = "black", size = 2) +
  labs(x = expression(paste("February Absolute Humidity (g", m^-3, ")")) , y = expression(R[0])) +
  scale_fill_manual(values=cbPalette) +
  scale_colour_manual(values=cbPalette) +
  #annotate("text", x = 0.7, y = 5.5, label = "B", size = 10) +
  main_theme +
  theme(legend.position = "none")
all_plot_humidity_abs

# UV-B
all_plot_uv <- ggplot(full_climate_df_R0, aes(x = Feb_UV, y = R0)) + 
  geom_point(aes(fill = dataset), shape = 21, size = 3, alpha = 0.8) +
  geom_smooth(method = lm, aes(col = dataset), se = FALSE, size = 2) +
  geom_smooth(method = lm, col = "black", size = 2) +
  labs(x = expression(paste("February UV-B (", J, m^-2, d^-1, ")")), y = expression(R[0])) +
  scale_fill_manual(values=cbPalette) +
  scale_colour_manual(values=cbPalette) +
  #annotate("text", x = 0, y = 5.5, label = "C", size = 10) +
  main_theme +
  theme(legend.position = "none")
all_plot_uv

# population density
all_plot_popdensity <- ggplot(full_climate_df_R0, aes(x = log(Pop_density), y = R0)) + 
  geom_point(aes(fill = dataset), shape = 21, size = 3, alpha = 0.8) +
  geom_smooth(method = lm, aes(col = dataset), se = FALSE, size = 2) +
  geom_smooth(method = lm, col = "black", size = 2) +
  labs(x = expression(paste("log (People ", km^-2, ")")), y = expression(R[0])) +
  scale_fill_manual(values=cbPalette) +
  scale_colour_manual(values=cbPalette) +
  #annotate("text", x = 1, y = 5.5, label = "D", size = 10) +
  main_theme +
  theme(legend.position = "none")
all_plot_popdensity

png("figures/all_datasets_plot.png", width = 1200, height = 400)
grid.arrange(all_plot_temperature, all_plot_humidity_abs, all_plot_popdensity, nrow = 1)
dev.off()

ggsave("figures/temperature_plot.png", all_plot_temperature)
ggsave("figures/absolute_humidity_plot.png", all_plot_humidity_abs)
ggsave("figures/uv_plot.png", all_plot_uv)
ggsave("figures/pop_density_plot.png", all_plot_popdensity)

# --- compare to post-lockdown Rt vs May climate --- #

# temperature
lockdown_plot_temperature <- ggplot(full_climate_df_lockdown, aes(x = May_20_TC, y = Rt)) + 
  geom_point(aes(fill = dataset), shape = 21, size = 3, alpha = 0.6) +
  geom_smooth(method = lm, aes(col = dataset), se = FALSE, size = 2) +
  geom_smooth(method = lm, col = "black", size = 2) +
  labs(x = expression(paste("May Temperature (", degree*C, ")")), y = expression(paste("May ", R[t]))) +
  scale_fill_manual(values=cbPalette) +
  scale_colour_manual(values=cbPalette) +
  main_theme +
  #annotate("text", x = 3, y = 5.5, label = "D", size = 10) +
  theme(legend.position = "none")
lockdown_plot_temperature

ggsave("figures/temperature_plot_lockdown.png", lockdown_plot_temperature)

# population density

lockdown_plot_popdensity <- ggplot(full_climate_df_lockdown, aes(x = log(Pop_density), y = Rt)) + 
  geom_point(aes(fill = dataset), shape = 21, size = 3, alpha = 0.6) +
  geom_smooth(method = lm, aes(col = dataset), se = FALSE, size = 2) +
  geom_smooth(method = lm, col = "black", size = 2) +
  labs(x = expression(paste("log (People ", km^-2, ")")), y = expression(paste("May ", R[t]))) +
  scale_fill_manual(values=cbPalette) +
  scale_colour_manual(values=cbPalette) +
  main_theme +
  theme(legend.position = "none")
lockdown_plot_popdensity

ggsave("figures/popdensity_plot_lockdown.png", lockdown_plot_popdensity)



# --- regression models --- #

full_regression_model <- lm(R0 ~ February_20_TC + February_20_AH + Feb_UV + log(Pop_density), data = full_climate_df_R0)
summary(full_regression_model)

# latex version
# print(xtable(summary(full_regression_model)))

# Europe_regression_model <- lm(R0 ~ February_20_TC + February_20_AH + Feb_UV + log(Pop_density), data = full_climate_df_R0[full_climate_df_R0$dataset == "Europe",])
# summary(Europe_regression_model)
# 
# LMIC_regression_model <- lm(R0 ~ February_20_TC + February_20_AH + Feb_UV + log(Pop_density), data = full_climate_df_R0[full_climate_df_R0$dataset == "LMIC",])
# summary(LMIC_regression_model)
# 
# USA_regression_model <- lm(R0 ~ February_20_TC + February_20_AH + Feb_UV + log(Pop_density), data = full_climate_df_R0[full_climate_df_R0$dataset == "USA",])
# summary(USA_regression_model)


full_regression_model_lockdown <- lm(Rt ~ May_20_TC + May_20_AH + Feb_UV + log(Pop_density), data = full_climate_df_lockdown)
summary(full_regression_model_lockdown)


# plot USA residuals

d <- full_climate_df_R0[full_climate_df_R0$dataset == "USA" & full_climate_df_R0$Location != "DC",c("February_20_TC", "February_20_AH", "Feb_UV", "Pop_density", "R0", "Location")]
names(d) <- c("Temperature", "Humidity", "UV", "Pop_density", "R0", "State")

d$pop_residuals <- residuals(lm(R0 ~ log(Pop_density), data = d))

residual_plot_temp_alt <- ggplot(d, aes(x = Temperature, y = pop_residuals)) + 
  geom_point(shape = 21, size = 3, alpha = 0.8, fill = "#56B4E9") +
  geom_smooth(method = lm, col = "black") +
  labs(x = expression(paste("Median February 2020 Temperature (", degree*C, ")")), 
       y = expression(paste("Residuals (", R[0], "~ log(Population density))"))) +
  geom_text(aes(label = State), hjust = 0, vjust = 0, position = position_nudge(y = 0.05)) +
  main_theme
residual_plot_temp_alt


ggsave("figures/USA_pop_residuals_vs_temperature.png", residual_plot_temp_alt)


# test corellations between all environmental parameters
names(full_climate_df_R0)
clim_vars <- full_climate_df_R0[,c("February_20_TC", "February_20_AH", "Feb_UV")]
head(clim_vars)

clim_vars <- clim_vars[!is.na(clim_vars$February_20_TC) &
            !is.na(clim_vars$February_20_AH) &
            !is.na(clim_vars$Feb_UV),]

cor(clim_vars)

# now need a paired t-test; R0 against Rt
# check our dataframes are comparable (why didn't Rt and R0 go into the same df anyway???)

identical(full_climate_df_R0$Location, full_climate_df_lockdown$Location)
# uuh, loop through R0 data and add Rt for the same states

full_climate_df_R0$Rt <- NA
locations <- as.character(unique(full_climate_df_R0$Location))
for(i in 1:length(locations)){
  
  R_t <- full_climate_df_lockdown[full_climate_df_lockdown$Location == locations[i],]$Rt
  if(length(R_t) > 0){
    full_climate_df_R0[full_climate_df_R0$Location == locations[i],]$Rt <- R_t 
  }
}

t.test(full_climate_df_R0$R0, full_climate_df_R0$Rt, paired = TRUE, alternative = "greater", na.rm = TRUE)



# -- Old stuff -- #

# # --- USA only plots --- #
# 
# # Interesting USA plots:
# USA_plot_temperature <-  ggplot(full_climate_df_R0[full_climate_df_R0$dataset == "USA",], aes(x = February_20_TC, y = R0)) + 
#   geom_point(aes(fill = dataset), shape = 21, size = 3, alpha = 0.8) +
#   geom_smooth(method = lm, col = "black") +
#   labs(x = expression(paste("Median February 2020 Temperature (", degree*C, ")")), y = expression(R[0])) +
#   geom_text(aes(label = Location), hjust = 0, vjust = 0, position = position_nudge(y = 0.05)) +
#   scale_fill_manual(values=c("#56B4E9")) +
#   main_theme +
#   theme(legend.position = "none")
# USA_plot_temperature  
# 
# USA_plot_popdensity <-  ggplot(full_climate_df_R0[full_climate_df_R0$dataset == "USA",], aes(x = log(Pop_density), y = R0)) + 
#   geom_point(aes(fill = dataset), shape = 21, size = 3, alpha = 0.8) +
#   geom_smooth(method = lm, col = "black") +
#   labs(x = expression(paste("log (People ", km^-2, ")")), y = expression(R[0])) +
#   geom_text(aes(label = Location), hjust = 0, vjust = 0, position = position_nudge(y = 0.05)) +
#   scale_fill_manual(values=c("#56B4E9")) +
#   main_theme +
#   theme(legend.position = "none")
# USA_plot_popdensity
# 
# USA_plot_humidity <-  ggplot(full_climate_df_R0[full_climate_df_R0$dataset == "USA",], aes(x = February_20_AH, y = R0)) + 
#   geom_point(aes(fill = dataset), shape = 21, size = 3, alpha = 0.8) +
#   geom_smooth(method = lm, col = "black") +
#   labs(x = expression(paste("February Absolute Humidity (g", m^-3, ")")), y = expression(R[0])) +
#   geom_text(aes(label = Location), hjust = 0, vjust = 0, position = position_nudge(y = 0.05)) +
#   scale_fill_manual(values=c("#56B4E9")) +
#   main_theme +
#   theme(legend.position = "none")
# USA_plot_humidity
# 
# USA_plot_uv <-  ggplot(full_climate_df_R0[full_climate_df_R0$dataset == "USA",], aes(x = Feb_UV, y = R0)) + 
#   geom_point(aes(fill = dataset), shape = 21, size = 3, alpha = 0.8) +
#   geom_smooth(method = lm, col = "black") +
#   labs(x = expression(paste("February UV-B (", J, m^-2, d^-1, ")")), y = expression(R[0])) +
#   geom_text(aes(label = Location), hjust = 0, vjust = 0, position = position_nudge(y = 0.05)) +
#   scale_fill_manual(values=c("#56B4E9")) +
#   main_theme +
#   theme(legend.position = "none")
# USA_plot_uv


# plot the residuals from the USA model
# just do lm(R0 ~ pop density)
# then plot the residuals from that for the climate variables


# # Fit the model
# # fit <- lm(R0 ~ Temperature + Humidity + UV + log(Pop_density), data = d)
# 
# fit <- lm(R0 ~ log(Pop_density), data = d)
# summary(fit)
# 
# # Obtain predicted and residual values
# d$predicted <- predict(fit)
# d$residuals <- residuals(fit)
# head(d)
# 
# residual_plot_temp <- ggplot(d, aes(x = Temperature, y = R0)) +
#   geom_segment(aes(xend = Temperature, yend = predicted), alpha = 0.3) +  # Lines to connect points
#   geom_point(aes(color = residuals, size = abs(residuals))) +
#   geom_point(aes(y = predicted), shape = 1) +  # Points of predicted values
#   scale_color_gradient2(low = "blue", mid = "white", high = "red") +
#   guides(color = FALSE) +
#   geom_text(aes(label = State), hjust = 0, vjust = 0, position = position_nudge(y = 0.05)) +
#   #annotate("text", x = -10, y = 3.5, label = "A", size = 10) +
#   labs(x = expression(paste("February Temperature (", degree*C, ")")), y = expression(R[0])) +
#   main_theme +
#   theme(legend.position = "none")
# residual_plot_temp
# 
# residual_plot_humidity <- ggplot(d, aes(x = Humidity, y = R0)) +
#   geom_segment(aes(xend = Humidity, yend = predicted), alpha = 0.3) +  # Lines to connect points
#   geom_point(aes(color = residuals, size = abs(residuals))) +
#   geom_point(aes(y = predicted), shape = 1) +  # Points of predicted values
#   scale_color_gradient2(low = "blue", mid = "white", high = "red") +
#   guides(color = FALSE) +
#   geom_text(aes(label = State), hjust = 0, vjust = 0, position = position_nudge(y = 0.05)) +
#   #annotate("text", x = 2, y = 3.5, label = "B", size = 10) +
#   main_theme +
#   theme(legend.position = "none")
# residual_plot_humidity
# # guess we shouldn't really do humidity if its not significant anyway
# 
# residual_plot_pop <- ggplot(d, aes(x = log(Pop_density), y = R0)) +
#   geom_segment(aes(xend = log(Pop_density), yend = predicted), alpha = 0.3) +  # Lines to connect points
#   geom_point(aes(color = residuals, size = abs(residuals))) +
#   geom_point(aes(y = predicted), shape = 1) +  # Points of predicted values
#   scale_color_gradient2(low = "blue", mid = "white", high = "red") +
#   guides(color = FALSE) +
#   geom_text(aes(label = State), hjust = 0, vjust = 0, position = position_nudge(y = 0.05)) +
#   #annotate("text", x = 2, y = 3.5, label = "B", size = 10) +
#   labs(x = expression(paste("log (People ", km^-2, ")")), y = expression(R[0])) +
#   main_theme +
#   theme(legend.position = "none")
# residual_plot_pop
# 
# png("figures/USA_residual_plots.png", width = 800, height = 400)
# grid.arrange(residual_plot_temp, residual_plot_pop, nrow = 1)
# dev.off()