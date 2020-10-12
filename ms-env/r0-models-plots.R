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
USA_R0_data <- read.csv("clean-data/climate_and_R0_USA.csv")
USA_Rt_data <- read.csv("clean-data/climate_and_lockdown_Rt_USA.csv")


##############################
# --- USA vs environment --- #
##############################

## -- Regressions -- ##

# 1. all variables

USA_regression_model_full <- lm(R0 ~ Temperature + Absolute_Humidity + UV + log10(Pop_density), data = USA_R0_data)
# scaled coefficicents:
print("Full regression model with scaled coefficients, latex table:")
xtable(summary(lm(R0 ~ scale(Temperature) + scale(Absolute_Humidity) + scale(UV) + scale(log10(Pop_density)), data = USA_R0_data)))

# 2. check corellation between climate variables

USA_clim_vars <- USA_R0_data[,c("Temperature", "Absolute_Humidity", "UV")]

USA_clim_vars <- USA_clim_vars[!is.na(USA_clim_vars$Temperature) &
                         !is.na(USA_clim_vars$Absolute_Humidity) &
                           !is.na(USA_clim_vars$UV),]

print("")
print("How correlated are the climate variables?")
cor(USA_clim_vars)

print("")
print("Variance inflation factors for the full model:")
vif(USA_regression_model_full)

# which is the best fitting when pop density is accounted for?
# summary(lm(R0 ~ Temperature + log10(Pop_density), data = USA_R0_data))
# summary(lm(R0 ~ Absolute_Humidity + log10(Pop_density), data = USA_R0_data))
# summary(lm(R0 ~ UV + log10(Pop_density), data = USA_R0_data))
# temperature model has the highest r2
print("")
print("R0 vs temperature correlation coefficient:")
cor(USA_R0_data$R0, USA_R0_data$Temperature)
print("R0 vs humidity correlation coefficient:")
cor(USA_R0_data$R0, USA_R0_data$Absolute_Humidity)
print("R0 vs UV correlation coefficient:")
cor(USA_R0_data$R0, USA_R0_data$UV)


## ---------------------- PCA ----------------------- ##

# do a PCA to look further at collinearity between climate variables

# R0_data <- R0_data[!is.na(R0_data$Feb_UV),]
test_data <- USA_R0_data[,c("Temperature", "Absolute_Humidity", "UV", "Pop_density")]
names(test_data) <- c("Temperature", "Absolute Humidity", "UV", "Population density")
# need to log the pop density as massively skewed
test_data$`Population density` <- log(test_data$`Population density`)

# do the PCA
pca_model <- prcomp(test_data, scale. = TRUE, center = TRUE)

png("ms-env/pca_plot.png", width = 400, height = 400)
ggbiplot(pca_model, varname.size = 4, varname.adjust = 1) + 
  #geom_point(aes(colour = R0_data$dataset), size = 3) +
  theme_bw() + 
  #xlim(c(-2, 3)) + 
  #ylim(c(-3, 3)) + 
  theme(legend.position = c(0.85, 0.8),
        legend.text = element_text(size = 12),
        legend.title = element_blank(),
        aspect.ratio=1,
        axis.text = element_text(size = 12),
        axis.title = element_text(size = 14))
dev.off()



# 3. temperature + pop density only

USA_regression_model <- lm(R0 ~ Temperature + log10(Pop_density), data = USA_R0_data)
# scaled coefficients?
print("")
print("Temperature vs R0 regression model with scaled coefficients, latex table:")
xtable(summary(lm(R0 ~ scale(Temperature) + scale(log10(Pop_density)), data = USA_R0_data)))

# 4. check effects of lockdown
USA_regression_model_lockdown <- lm(Rt ~ Temperature + log10(Pop_density), data = USA_Rt_data)

print("")
print("Temperature vs lockdown Rt regression model with scaled coefficients, latex table:")
xtable(summary(lm(Rt~ scale(Temperature) +  scale(log10(Pop_density)), data = USA_Rt_data)))
# much lower correlations

# 5. t-test of R0 vs Rt to show importance of lockdown

USA_R0_data$Rt <- NA
locations <- as.character(unique(USA_R0_data$State))
for(i in 1:length(locations)){
  
  R_t <- USA_Rt_data[USA_Rt_data$State == locations[i],]$Rt
  if(length(R_t) > 0){
    USA_R0_data[USA_R0_data$State == locations[i],]$Rt <- R_t 
  }
}

print("")
print("t-test R0 vs lockdown Rt:")
t.test(USA_R0_data$R0, USA_R0_data$Rt, paired = TRUE, alternative = "greater", na.rm = TRUE)

# 6. Combine temperature and population density into one 3d plot with trend surface
# plot_ly method?

# predict model over sensible grid of values
temps <- seq(-7, 21, by = 0.1)
pops <- 10^(seq(0.7, 3.5, by = 0.1))
grid <- with(USA_R0_data, expand.grid(temps, pops))
d <- setNames(data.frame(grid), c("Temperature", "Pop_density"))
vals <- predict(USA_regression_model, newdata = d)

# form matrix and give to plotly
R0 <- matrix(vals, nrow = length(unique(d$Temperature)), ncol = length(unique(d$Pop_density)))

R0_3d <- plot_ly() %>% 
  add_surface(x = ~pops, y = ~temps, z = ~R0, opacity = 0.9, cmin = 0, cmax = 4) %>%
  add_trace(x = USA_R0_data$Pop_density, 
            y = USA_R0_data$Temperature,
            z = USA_R0_data$R0, 
            type = "scatter3d", 
            mode = "markers",
            marker = list(color = "grey", size = 3,
                          line = list(color = "black",width = 1)),
            opacity = 1) %>% 
  layout(scene = list(xaxis = list(title = "", autorange = "reversed", tickfont = list(size = 15), type = "log",
                                   tickvals = c(10, 100, 1000)),
                      yaxis = list(title = "", autotick = F, tickmode = "array", tickvals = c(-5, 0, 5, 10, 15, 20), 
                                   tickfont = list(size = 15)),
                      zaxis = list(title = "", range = c(0, 4), autotick = F, tickmode = "array", tickvals = c(1, 2, 3, 4),
                                   tickfont = list(size = 15))))
# In a really stupid method to get higher quality images from this
# I'm taking a screenshot with GIMP and saving that as a tif!
# R0_3d

# repeat for Rt data
# predict model over sensible grid of values (ld for lockdown)
temps_ld <- seq(4, 24, by = 0.1)
pops_ld <- 10^(seq(0.8, 3.5, by = 0.1))
grid_ld <- with(USA_Rt_data[USA_Rt_data$Location %in% USA_R0_data$Location,], expand.grid(temps_ld, pops_ld))
d_ld <- setNames(data.frame(grid_ld), c("Temperature", "Pop_density"))
vals_ld <- predict(USA_regression_model_lockdown, newdata = d_ld)

Rt <- matrix(vals_ld, nrow = length(unique(d_ld$Temperature)), ncol = length(unique(d_ld$Pop_density)))

Rt_3d <- plot_ly() %>% 
  add_surface(x = ~pops_ld, y = ~temps_ld, z = ~Rt, opacity = 0.9, cmin = 0, cmax = 4) %>%
  add_trace(x = USA_Rt_data$Pop_density, 
            y = USA_Rt_data$Temperature,
            z = USA_Rt_data$Rt, 
            type = "scatter3d", 
            mode = "markers",
            marker = list(color = "grey", size = 3,
                          line = list(color = "black",width = 1)),
            opacity = 1) %>% 
  layout(scene = list(xaxis = list(title = "", autorange = "reversed", tickfont = list(size = 15), type = "log",
                                   tickvals = c(10, 100, 1000)),
                      yaxis = list(title = "", tickfont = list(size = 15)),
                      zaxis = list(title = "", range = c(0, 4), autotick = F, tickmode = "array", tickvals = c(1, 2, 3, 4),
                                   tickfont = list(size = 15))),
                                   showlegend = FALSE) %>%
  hide_colorbar() 
# Rt_3d

# 7. plot residuals from pop density regression against temperature

d <- USA_R0_data[,c("Temperature", "Absolute_Humidity", "Pop_density", "R0", "State")]

d$pop_residuals <- residuals(lm(R0 ~ log10(Pop_density), data = d))

USA_residual_plot <- ggplot(d, aes(x = Temperature, y = pop_residuals)) + 
  geom_point(shape = 21, size = 3, alpha = 0.8, fill = "#56B4E9") +
  geom_smooth(method = lm, col = "black") +
  labs(x = "Temperature (°C)", 
       y = expression(paste("Corrected ", R[0]))) +
  geom_text(aes(label = State), hjust = 0, vjust = 0, position = position_nudge(y = 0.05)) +
  main_theme +
  theme(aspect.ratio = 1)
# USA_residual_plot

ggsave("ms-env/USA_pop_residuals_vs_temperature.png", USA_residual_plot)

# 8. Plot heatmap of temp vs population density, with
# cells coloured by R0, with datapoints overlayed

predicted_R0 <- data.frame(grid, vals)
names(predicted_R0) <- c("Temperature", "Pop_density", "R0")

heatmap_plot <- ggplot(predicted_R0, aes(x = Temperature, y = Pop_density)) + 
  geom_tile(aes(fill = R0)) +
  geom_point(data = USA_R0_data, aes(x = Temperature, y = Pop_density, fill = R0), size = 4, shape = 21) +
  geom_text(data = USA_R0_data, aes(x = Temperature, y = Pop_density, label = State), hjust = 0, vjust = 0, 
            position = position_nudge(y = 0.05), col = "white") +
  scale_fill_viridis_c(limits = c(0, 4)) +
  #scale_fill_gradient(low = "blue", high = "yellow") +
  scale_x_continuous(expand = c(0, 0)) +
  scale_y_log10(expand = c(0, 0)) +
  labs(x = "Temperature (°C)",
       y = expression(paste("Population density (people ", km^-2, ")")),
       fill = expression(R[0])) +
  main_theme +
  theme(aspect.ratio = 1)
# heatmap_plot

ggsave("ms-env/heatmap_R0.png", heatmap_plot)



################################
#### Supplementary material ####
################################

# ---- interactions ---- #

# combine R0 and Rt data and add lockdown as an interaction term

R0_df <- USA_R0_data[,c("State", "R0", "Temperature", "Absolute_Humidity", "Pop_density", "Avg_mobility_change")]
R0_df$Lockdown <- "No"
names(R0_df)[2] <- "Rt"

Rt_df <- USA_Rt_data[,c("State", "Rt", "Temperature", "Absolute_Humidity", "Pop_density", "Avg_mobility_change")]
Rt_df$Lockdown <- "Yes"

interaction_df <- rbind(R0_df, Rt_df)

additive_lm <- lm(Rt ~ scale(Temperature) + scale(log(Pop_density)) + Lockdown, data = interaction_df)
print("")
print("Temperature vs R with lockdown additive regression model with scaled coefficients, latex table:")
xtable(summary(additive_lm))
interaction_lm <- lm(Rt ~ (scale(Temperature) + scale(log(Pop_density)))*Lockdown, data = interaction_df)
print("")
print("Temperature vs R with lockdown interaction regression model with scaled coefficients, latex table:")
xtable(summary(interaction_lm))

print("")
print("Anova; is interaction model better than additive model?")
anova(additive_lm, interaction_lm)

if(FALSE){
# alternative, use the actual mobility changes instead of binary yes/no lockdown term
additive_lm_mobility <- lm(Rt ~ scale(Temperature) + scale(log(Pop_density)) + scale(Avg_mobility_change), data = interaction_df)
summary(additive_lm_mobility)

interaction_lm_mobility <- lm(Rt ~ (scale(Temperature) + scale(log(Pop_density)))* scale(Avg_mobility_change), data = interaction_df)
summary(interaction_lm_mobility)

print("Anova; is interaction model better than additive model?")
anova(additive_lm_mobility, interaction_lm_mobility)
# this is circular because mobility already goes into the model used to generate Rt in the first place
}


# ---- What if transmission mostly happens in urban populations, ---- #
# ---- so state-wide pop density is maybe less meaningful?       ---- #

urban_lm <- lm(R0 ~ Temperature + Pop_density + Urban_pop, USA_R0_data)
summary(urban_lm)

urban_lm <- lm(R0 ~ Temperature + Pop_density*Urban_pop, USA_R0_data)
summary(urban_lm)

urban_lm <- lm(R0 ~ scale(Temperature) + scale(Urban_pop), USA_R0_data)
summary(urban_lm)
# this is a worse predictor than population density at state level


# ---- Does the date R0 was estimated on have an effect? i.e. did states ---- #
# ---- where the pandemic emerged later learn from the earlier states?   ---- #

ggplot(USA_R0_data, aes(x = as.Date(Date), y = R0)) + geom_point() + geom_smooth(method = lm)
summary(lm(R0 ~ as.Date(Date), USA_R0_data))

# date has no effect on R0, but we can also check whether mobility was reduced already in later onset states

ggplot(USA_R0_data, aes(x = as.Date(Date), y = Avg_mobility_change)) + geom_point() + geom_smooth(method = lm)
summary(lm(Avg_mobility_change ~ as.Date(Date), USA_R0_data))
# thats weird - later onset states INCREASED their mobility???!
# does it relate to the R0?

ggplot(USA_R0_data, aes(x = Avg_mobility_change, y = R0)) + geom_point() + geom_smooth(method = lm)
summary(lm(R0 ~ Avg_mobility_change, USA_R0_data))
# not significant

# or should the question be whether date should be another covariate in the model?


# ---- Does the date when state-wide emergency decrees were implemented matter? ---- #

if(FALSE){
summary(lm(R0 ~ as.Date(emergency_decree), data = USA_R0_data))

emergdec_plot <- ggplot(USA_R0_data, aes(x = as.Date(emergency_decree), y = R0)) + 
  geom_point(size = 2) +
  geom_smooth(method = lm, col = "black") +
  geom_text(aes(label = Location), hjust = 0, vjust = 0, position = position_nudge(y = 0.02)) +
  labs(x = "Date of Emergency Decree",
       y = expression(R[0])) +
  main_theme +
  theme(aspect.ratio = 1)
emergdec_plot

ggsave("ms-env/emergdec_plot.png", emergdec_plot)

emergdec_lm <- lm(R0 ~ as.Date(emergency_decree) + February_20_TC + log10(Pop_density), data = USA_R0_data)
summary(emergdec_lm)
vif(emergdec_lm)

# date of first 10 deaths?

summary(lm(R0 ~ as.Date(date_first_ten), data = USA_R0_data))

firstten_plot <- ggplot(USA_R0_data, aes(x = as.Date(date_first_ten), y = R0)) + 
  geom_point(size = 2) +
  geom_smooth(method = lm, col = "black") +
  geom_text(aes(label = Location), hjust = 0, vjust = 0, position = position_nudge(y = 0.02)) +
  labs(x = "Date of First 10 Deaths",
       y = expression(R[0])) +
  main_theme +
  theme(aspect.ratio = 1)
firstten_plot

# new metric of "preparedness" of state 
# - how early did they put out emergency decree
# compared to their number of deaths

USA_R0_data$preparedness <- as.Date(USA_R0_data$date_first_ten) - as.Date(USA_R0_data$emergency_decree)

summary(lm(R0 ~ preparedness, data = USA_R0_data))

preparedness_plot <- ggplot(USA_R0_data, aes(x =preparedness, y = R0)) + 
  geom_point(size = 2) +
  geom_smooth(method = lm, col = "black") +
  geom_text(aes(label = Location), hjust = 0, vjust = 0, position = position_nudge(y = 0.02)) +
  labs(x = "Preparedness",
       y = expression(R[0])) +
  main_theme +
  theme(aspect.ratio = 1)
preparedness_plot

preparedness_lm <- lm(R0 ~ preparedness + February_20_TC + log10(Pop_density), data = USA_R0_data)
summary(preparedness_lm)
vif(preparedness_lm)
}

#
#
#
#

# -- Old stuff -- #


# can we plot the USA model residuals onto the US states map?
# i.e. which states have higher R0 than our model predicts, which have lower?
if(FALSE){
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

png("ms-env/USA_residuals_map.png", width = 800, height = 600)
plot_usmap(data = us_state_data, values = "value") +
  scale_fill_gradient2(low = "blue", mid = "white", high = "red", name = "Model Residuals") +
  theme(legend.text = element_text(size = 12),
        legend.title = element_text(size = 14),
        legend.position = c(0, 0.15))
dev.off()
}
