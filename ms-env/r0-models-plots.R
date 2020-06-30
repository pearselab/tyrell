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

# load in the data
full_climate_df_R0 <- read.csv("clean-data/climate_and_R0.csv")
full_climate_df_lockdown <- read.csv("clean-data/climate_and_lockdown_Rt.csv")

# should we transform pop density?
# ggplot(full_climate_df, aes(x = Pop_density)) + geom_histogram()
# ggplot(full_climate_df, aes(x = sqrt(Pop_density))) + geom_histogram()
# ggplot(full_climate_df, aes(x = log(Pop_density))) + geom_histogram()
# guess we'd better log it to make it more normally distributed

##############################
# --- USA vs environment --- #
##############################

USA_R0_data <- full_climate_df_R0[full_climate_df_R0$dataset == "USA",]
USA_Rt_data <- full_climate_df_lockdown[full_climate_df_lockdown$dataset == "USA",]

## -- Regressions -- ##

# 1. all variables

USA_regression_model_full <- lm(R0 ~ February_20_TC + February_20_AH + Feb_UV + log(Pop_density), data = USA_R0_data)
summary(USA_regression_model_full)
# print(xtable(summary(USA_regression_model_full)))
# scaled coefficicents:
# summary(lm(R0 ~ scale(February_20_TC) + scale(February_20_AH) + scale(Feb_UV) + scale(Pop_density), data = USA_R0_data))

# 2. check corellation between climate variables

USA_clim_vars <- USA_R0_data[,c("February_20_TC", "February_20_AH", "Feb_UV")]

USA_clim_vars <- USA_clim_vars[!is.na(USA_clim_vars$February_20_TC) &
                         !is.na(USA_clim_vars$February_20_AH) &
                         !is.na(USA_clim_vars$Feb_UV),]

cor(USA_clim_vars)

# 3. temperature + pop density only

USA_regression_model <- lm(R0 ~ February_20_TC + log(Pop_density), data = USA_R0_data)
summary(USA_regression_model)
# print(xtable(summary(USA_regression_model)))
# scaled coefficients?
summary(lm(R0 ~ scale(February_20_TC) + scale(log(Pop_density)), data = USA_R0_data))

# 4. check effects of lockdown
USA_regression_model_lockdown <- lm(Rt ~ May_20_TC + log(Pop_density), data = USA_Rt_data)
summary(USA_regression_model_lockdown)
# no longer significant effects

# 5. t-test of R0 vs Rt to show importance of lockdown

USA_R0_data$Rt <- NA
locations <- as.character(unique(USA_R0_data$Location))
for(i in 1:length(locations)){
  
  R_t <- USA_Rt_data[USA_Rt_data$Location == locations[i],]$Rt
  if(length(R_t) > 0){
    USA_R0_data[USA_R0_data$Location == locations[i],]$Rt <- R_t 
  }
}

t.test(USA_R0_data$R0, USA_R0_data$Rt, paired = TRUE, alternative = "greater", na.rm = TRUE)


# 6. plot temperature and population density pre- and post- lockdown regressions

USA_plot_temperature <-  ggplot(USA_R0_data, aes(x = February_20_TC, y = R0)) +
  geom_point(aes(fill = dataset), shape = 21, size = 3, alpha = 0.8) +
  geom_smooth(method = lm, col = "black") +
  labs(x = expression(paste("Median February 2020 Temperature (", degree*C, ")")), y = expression(R[0])) +
  geom_text(aes(label = Location), hjust = 0, vjust = 0, position = position_nudge(y = 0.05)) +
  scale_fill_manual(values=c("#56B4E9")) +
  main_theme +
  theme(legend.position = "none")
USA_plot_temperature

USA_plot_popdensity <-  ggplot(USA_R0_data, aes(x = log(Pop_density), y = R0)) +
  geom_point(aes(fill = dataset), shape = 21, size = 3, alpha = 0.8) +
  geom_smooth(method = lm, col = "black") +
  labs(x = expression(paste("log (People ", km^-2, ")")), y = expression(R[0])) +
  geom_text(aes(label = Location), hjust = 0, vjust = 0, position = position_nudge(y = 0.05)) +
  scale_fill_manual(values=c("#56B4E9")) +
  main_theme +
  theme(legend.position = "none")
USA_plot_popdensity

ggsave("figures/USA_temperature_plot.png", USA_plot_temperature)
ggsave("figures/USA_pop_density_plot.png", USA_plot_popdensity)

USA_plot_temperature_lockdown <-  ggplot(USA_Rt_data, aes(x = May_20_TC, y = Rt)) +
  geom_point(aes(fill = dataset), shape = 21, size = 3, alpha = 0.8) +
  geom_smooth(method = lm, col = "black") +
  labs(x = expression(paste("Median May 2020 Temperature (", degree*C, ")")), y = expression(R[t])) +
  geom_text(aes(label = Location), hjust = 0, vjust = 0, position = position_nudge(y = 0.05)) +
  scale_fill_manual(values=c("#56B4E9")) +
  main_theme +
  theme(legend.position = "none")
USA_plot_temperature_lockdown

USA_plot_popdensity_lockdown <-  ggplot(USA_Rt_data, aes(x = log(Pop_density), y = Rt)) +
  geom_point(aes(fill = dataset), shape = 21, size = 3, alpha = 0.8) +
  geom_smooth(method = lm, col = "black") +
  labs(x = expression(paste("log (People ", km^-2, ")")), y = expression(R[t])) +
  geom_text(aes(label = Location), hjust = 0, vjust = 0, position = position_nudge(y = 0.05)) +
  scale_fill_manual(values=c("#56B4E9")) +
  main_theme +
  theme(legend.position = "none")
USA_plot_popdensity_lockdown

ggsave("figures/USA_temperature_plot_lockdown.png", USA_plot_temperature_lockdown)
ggsave("figures/USA_pop_density_plot_lockdown.png", USA_plot_popdensity_lockdown)


# 7. plot residuals from pop density regression against temperature

d <- USA_R0_data[USA_R0_data$Location != "DC",c("February_20_TC", "February_20_AH", "Feb_UV", "Pop_density", "R0", "Location")]
names(d) <- c("Temperature", "Humidity", "UV", "Pop_density", "R0", "State")

d$pop_residuals <- residuals(lm(R0 ~ log(Pop_density), data = d))

USA_residual_plot <- ggplot(d, aes(x = Temperature, y = pop_residuals)) + 
  geom_point(shape = 21, size = 3, alpha = 0.8, fill = "#56B4E9") +
  geom_smooth(method = lm, col = "black") +
  labs(x = expression(paste("Median February 2020 Temperature (", degree*C, ")")), 
       y = expression(paste("Residuals (", R[0], "~ log(Population density))"))) +
  geom_text(aes(label = State), hjust = 0, vjust = 0, position = position_nudge(y = 0.05)) +
  main_theme
USA_residual_plot

ggsave("figures/USA_pop_residuals_vs_temperature.png", USA_residual_plot)


#### Supplementary things to tidy up ####

if(FALSE){

#############################
##   Plots of everything   ##
#############################

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
# all_plot_temperature

# relative humidity
all_plot_humidity_rel <- ggplot(full_climate_df_R0, aes(x = February_20_RH, y = R0)) + 
  geom_point(aes(fill = dataset), shape = 21, size = 3, alpha = 0.8) +
  geom_smooth(method = lm, col = "black") +
  labs(x = expression(paste("February Relative Humidity (", '%', ")")), y = expression(R[0])) +
  scale_fill_manual(values=cbPalette) +
  annotate("text", x = 15, y = 5.5, label = "B", size = 10) +
  main_theme +
  theme(legend.position = "none")
# all_plot_humidity_rel

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
# all_plot_humidity_abs

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
# all_plot_uv

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
# all_plot_popdensity

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

vif(full_regression_model)
# variance of Temp and UV especially massively inflated due to collinearity
small_model_temp <- lm(R0 ~ February_20_TC +  log(Pop_density), data = full_climate_df_R0)
summary(small_model_temp)
vif(small_model_temp)
# scaled coefficients?
summary(lm(R0 ~ scale(February_20_TC) +  scale(log(Pop_density)), data = full_climate_df_R0))


small_model_uv <- lm(R0 ~ Feb_UV +  log(Pop_density), data = full_climate_df_R0)
summary(small_model_uv)

small_model_humidity <- lm(R0 ~ February_20_AH + log(Pop_density), data = full_climate_df_R0)
summary(small_model_humidity)

small_model_Rhumidity <- lm(R0 ~ February_20_RH + log(Pop_density), data = full_climate_df_R0)
summary(small_model_Rhumidity)

cor.test(full_climate_df_R0$February_20_TC, full_climate_df_R0$R0)
cor.test(full_climate_df_R0$Feb_UV, full_climate_df_R0$R0)
cor.test(full_climate_df_R0$February_20_AH, full_climate_df_R0$R0)

# latex version
# print(xtable(summary(full_regression_model)))

Europe_regression_model <- lm(R0 ~ February_20_TC + log(Pop_density), data = full_climate_df_R0[full_climate_df_R0$dataset == "Europe",])
summary(Europe_regression_model)

LMIC_regression_model <- lm(R0 ~ February_20_TC  + log(Pop_density), data = full_climate_df_R0[full_climate_df_R0$dataset == "LMIC",])
summary(LMIC_regression_model)

USA_regression_model <- lm(R0 ~ February_20_TC + log(Pop_density), data = full_climate_df_R0[full_climate_df_R0$dataset == "USA",])
summary(USA_regression_model)
# (xtable(summary(USA_regression_model)))
# scaled coefficients?
summary(lm(R0 ~ scale(February_20_TC) + scale(log(Pop_density)), data = full_climate_df_R0[full_climate_df_R0$dataset == "USA",]))

europe_and_USA_model <- lm(R0 ~ February_20_TC  + log(Pop_density), data = full_climate_df_R0[full_climate_df_R0$dataset != "LMIC",])
summary(europe_and_USA_model)

full_regression_model_lockdown <- lm(Rt ~ May_20_TC + May_20_AH + Feb_UV + log(Pop_density), data = full_climate_df_lockdown)
summary(full_regression_model_lockdown)

small_regression_model_lockdown <- lm(Rt ~ May_20_TC + log(Pop_density), data = full_climate_df_lockdown)
summary(small_regression_model_lockdown)

USA_regression_model_lockdown <- lm(Rt ~ February_20_TC + log(Pop_density) + lockdown_strength, data = full_climate_df_lockdown[full_climate_df_lockdown$dataset == "USA",])
summary(USA_regression_model_lockdown)

europe_regression_model_lockdown <- lm(Rt ~ February_20_TC + log(Pop_density) + lockdown_strength, data = full_climate_df_lockdown[full_climate_df_lockdown$dataset == "Europe",])
summary(europe_regression_model_lockdown)

LMIC_regression_model_lockdown <- lm(Rt ~ February_20_TC + log(Pop_density) + lockdown_strength, data = full_climate_df_lockdown[full_climate_df_lockdown$dataset == "LMIC",])
summary(LMIC_regression_model_lockdown)


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


# can we plot the USA model residuals onto the US states map?
# i.e. which states have higher R0 than our model predicts, which have lower?

library("usmap")

# list of all US states
us_state_list <- data.frame(unique(usmap::us_map()$abbr))
names(us_state_list) <- c("state")

# get residuals from the temp + pop density US model

d$all_residuals <- residuals(lm(R0 ~ Temperature + log(Pop_density), data = d))
# d$all_residuals <- residuals(lm(R0 ~ log(Pop_density), data = d))
# d$all_residuals <- residuals(lm(R0 ~ Temperature, data = d))


us_residuals_data <- d[,c("State", "all_residuals")]
names(us_residuals_data) <- c("state", "value")
us_state_data <- merge(x = us_state_list, y = us_residuals_data, by.x = "state", by.y = "state", all.x = TRUE)

png("~/Documents/COVID/figures/USA_residuals_map.png", width = 800, height = 600)
plot_usmap(data = us_state_data, values = "value") + 
  scale_fill_gradient2(low = "blue", mid = "white", high = "red", name = "Model Residuals") +
  theme(legend.text = element_text(size = 12),
        legend.title = element_text(size = 14),
        legend.position = c(0, 0.15))
dev.off()

# -- Old stuff -- #

# # --- USA only plots --- #
# 

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

}