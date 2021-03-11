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


########################################
# --- USA vs environment           --- #
# --- Model and plotting functions --- #
########################################

# combine R0 and Rt data and add lockdown as an interaction term

R0_df <- USA_R0_data[,c("State", "R0", "Temperature", "Absolute_Humidity", "Pop_density", "Avg_mobility_change")]
R0_df$Lockdown <- "No"
names(R0_df)[2] <- "Rt"

Rt_df <- USA_Rt_data[,c("State", "Rt", "Temperature", "Absolute_Humidity", "Pop_density", "Avg_mobility_change")]
Rt_df$Lockdown <- "Yes"

interaction_df <- rbind(R0_df, Rt_df)

interaction_lm <- lm(Rt ~ (scale(Temperature) + scale(log(Pop_density)))*Lockdown, data = interaction_df)

# main text R0 analysis
table_1 <- function(){
  print("Table 1: Temperature vs R with lockdown interaction regression model with scaled coefficients:")
  return(xtable(summary(interaction_lm)))
}

# supplementary regression tables
table_S1 <- function(){
  print("Table S1: Full regression model with scaled coefficients:")
  return(xtable(summary(lm(R0 ~ scale(Temperature) + scale(Absolute_Humidity) + scale(UV) + scale(log10(Pop_density)), data = USA_R0_data))))
}

table_S3 <- function(){
  print("Table S3: Temperature vs R0 regression model with scaled coefficients:")
  return(xtable(summary(lm(R0 ~ scale(Temperature) + scale(log10(Pop_density)), data = USA_R0_data))))
}

table_S4 <- function(){
  print("Table S4: Temperature vs lockdown Rt regression model with scaled coefficients:")
  return(xtable(summary(lm(Rt~ scale(Temperature) +  scale(log10(Pop_density)), data = USA_Rt_data))))
}

table_S5 <- function(){
  additive_lm <- lm(Rt ~ scale(Temperature) + scale(log(Pop_density)) + Lockdown, data = interaction_df)
  print("Table S5: Temperature vs R with lockdown additive regression model with scaled coefficients:")
  return(xtable(summary(additive_lm)))
}

table_S6 <- function(){
  print("Table S6: Temperature vs R with lockdown interaction regression model with scaled coefficients, as table 1:")
  return(xtable(summary(interaction_lm)))
}


## -- Collinearity of climate variables -- ##

USA_clim_vars <- USA_R0_data[,c("Temperature", "Absolute_Humidity", "UV")]
USA_clim_vars <- USA_clim_vars[!is.na(USA_clim_vars$Temperature) &
                                 !is.na(USA_clim_vars$Absolute_Humidity) &
                                 !is.na(USA_clim_vars$UV),]

clim_cors <- function(){
  print("How correlated are the climate variables?")
  cor(USA_clim_vars)
}

variance_inflation <- function(){
  print("Variance inflation factors for the full model:")
  return(vif(lm(R0 ~ Temperature + Absolute_Humidity + UV + log10(Pop_density), data = USA_R0_data)))
}

table_S2 <- function(){
  # create a dataframe with corellation coefficients for each climate variable
  # with R0
  cors <- c(cor(USA_R0_data$R0, USA_R0_data$Temperature),
            cor(USA_R0_data$R0, USA_R0_data$Absolute_Humidity),
            cor(USA_R0_data$R0, USA_R0_data$UV))
  vars <- c("Temperature", "Absolute humidity", "UV")
  cor_df <- data.frame(vars, cors)
  names(cor_df) <- c("Variable", "Pearsons r")
  print("Table S2: which climate variable correlates most with R0?")
  return(xtable(cor_df))
}


# do a PCA to look further at collinearity between climate variables
figure_S1 <- function(){
  test_data <- USA_R0_data[,c("Temperature", "Absolute_Humidity", "UV", "Pop_density")]
  names(test_data) <- c("Temperature", "Absolute Humidity", "UV", "Population density")
  # need to log the pop density as massively skewed
  test_data$`Population density` <- log(test_data$`Population density`)
  
  pca_model <- prcomp(test_data, scale. = TRUE, center = TRUE)
  pca_plot <- ggbiplot(pca_model, varname.size = 4, varname.adjust = 1) + 
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
  
  ggsave("ms-env/pca_plot.png", pca_plot)
}



## -- Functions for the main plots in the manuscript -- ##

USA_regression_model <- lm(R0 ~ Temperature + log10(Pop_density), data = USA_R0_data)
# predict model over sensible grid of values
temps <- seq(-7, 21, by = 0.1)
pops <- 10^(seq(0.7, 3.5, by = 0.1))
grid <- with(USA_R0_data, expand.grid(temps, pops))
d <- setNames(data.frame(grid), c("Temperature", "Pop_density"))
vals <- predict(USA_regression_model, newdata = d)

# repeat for during lockdown
USA_regression_model_lockdown <- lm(Rt ~ Temperature + log10(Pop_density), data = USA_Rt_data)
# predict model over sensible grid of values (ld for lockdown)
temps_ld <- seq(4, 24, by = 0.1)
pops_ld <- 10^(seq(0.8, 3.5, by = 0.1))
grid_ld <- with(USA_Rt_data[USA_Rt_data$Location %in% USA_R0_data$Location,], expand.grid(temps_ld, pops_ld))
d_ld <- setNames(data.frame(grid_ld), c("Temperature", "Pop_density"))
vals_ld <- predict(USA_regression_model_lockdown, newdata = d_ld)


figure_1a <- function(){
  # form matrix and give to plotly
  R0 <- matrix(vals, nrow = length(unique(d$Temperature)), ncol = length(unique(d$Pop_density)))
  
  R0_3d <- plot_ly() %>% 
    add_surface(x = ~pops, y = ~temps, z = ~R0, opacity = 0.9, cmin = 0, cmax = 4) %>%
    add_trace(x = USA_R0_data$Pop_density, 
              y = USA_R0_data$Temperature,
              z = USA_R0_data$R0, 
              type = "scatter3d", 
              mode = "markers",
              marker = list(color = "grey", size = 10,
                            line = list(color = "black",width = 1)),
              opacity = 1) %>% 
    layout(scene = list(xaxis = list(title = "", autorange = "reversed", tickfont = list(size = 20), type = "log",
                                     tickvals = c(10, 100, 1000)),
                        yaxis = list(title = "", autotick = F, tickmode = "array", tickvals = c(-5, 0, 5, 10, 15, 20), 
                                     tickfont = list(size = 20)),
                        zaxis = list(title = "", range = c(0, 4), autotick = F, tickmode = "array", tickvals = c(1, 2, 3, 4),
                                     tickfont = list(size = 20))))
  return(R0_3d)
}


figure_1b <- function(){
  Rt <- matrix(vals_ld, nrow = length(unique(d_ld$Temperature)), ncol = length(unique(d_ld$Pop_density)))
  
  Rt_3d <- plot_ly() %>% 
    add_surface(x = ~pops_ld, y = ~temps_ld, z = ~Rt, opacity = 0.9, cmin = 0, cmax = 4) %>%
    add_trace(x = USA_Rt_data$Pop_density, 
              y = USA_Rt_data$Temperature,
              z = USA_Rt_data$Rt, 
              type = "scatter3d", 
              mode = "markers",
              marker = list(color = "grey", size = 10,
                            line = list(color = "black",width = 1)),
              opacity = 1) %>% 
    layout(scene = list(xaxis = list(title = "", autorange = "reversed", tickfont = list(size = 20), type = "log",
                                     tickvals = c(10, 100, 1000)),
                        yaxis = list(title = "", tickfont = list(size = 20)),
                        zaxis = list(title = "", range = c(0, 4), autotick = F, tickmode = "array", tickvals = c(1, 2, 3, 4),
                                     tickfont = list(size = 20))),
           showlegend = FALSE) %>%
    hide_colorbar() 
  return(Rt_3d)
}


figure_2a <- function(){ # heatmap plot
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
  ggsave("ms-env/heatmap_R0.png", heatmap_plot)
}


figure_2b <- function(){
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
  
  ggsave("ms-env/USA_pop_residuals_vs_temperature.png", USA_residual_plot)
}


# as figure 2a, but for lockdown Rt - maybe suitable for supplement
figure_2_supp <- function(){ # heatmap plot
  predicted_R0 <- data.frame(grid_ld, vals_ld)
  names(predicted_R0) <- c("Temperature", "Pop_density", "Rt")
  
  heatmap_plot <- ggplot(predicted_R0, aes(x = Temperature, y = Pop_density)) + 
    geom_tile(aes(fill = Rt)) +
    geom_point(data = USA_Rt_data, aes(x = Temperature, y = Pop_density, fill = Rt), size = 4, shape = 21) +
    geom_text(data = USA_Rt_data, aes(x = Temperature, y = Pop_density, label = State), hjust = 0, vjust = 0, 
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
  ggsave("ms-env/heatmap_Rt.png", heatmap_plot)
}

##################################
# --- Supplementary analyses --- #
##################################

# ---- Does the date R0 was estimated on have an effect? i.e. did states ---- #
# ---- where the pandemic emerged later learn from the earlier states?   ---- #

figure_S2 <- function(){
  date_plot <- ggplot(USA_R0_data, aes(x = as.Date(Date), y = R0)) +
    geom_point(size = 3, shape = 21, aes(fill = Temperature)) + 
    scale_fill_gradient2(low = "blue", mid = "white", high = "red", midpoint = 5) +
    geom_smooth(method = lm, colour = "black") +
    geom_text(aes(label = State), hjust = 0, vjust = 0, position = position_nudge(y = 0.02)) +
    labs(x = "Date of estimate (2020)",
         y = expression(R[0])) +
    main_theme +
    theme(aspect.ratio = 1)
  
  ggsave("ms-env/date_plot.pdf", date_plot)
}



## -- Airport arrivals -- ##

figure_S3 <- function(){
  airport_plot <- ggplot(USA_R0_data[USA_R0_data$Airport_arrivals > 0,], aes(x = log10(Airport_arrivals), y = R0)) +
    geom_point(size = 2) + 
    geom_smooth(method = lm, colour = "black") +
    geom_text(aes(label = State), hjust = 0, vjust = 0, position = position_nudge(y = 0.02)) +
    labs(x = "log10(Airport arrivals)",
         y = expression(R[0])) +
    main_theme +
    theme(aspect.ratio = 1)
  
  ggsave("ms-env/airport_plot.pdf", airport_plot)
}


# ---- What if transmission mostly happens in urban populations, ---- #
# ---- so state-wide pop density is maybe less meaningful?       ---- #

table_S7 <- function(){
  vars <- c("log10(Pop density)", "log10(Total pop)", "% Urban Pop", "log10(Total Urban Pop)")
  cors <- c(cor(USA_R0_data$R0, log10(USA_R0_data$Pop_density)),
            cor(USA_R0_data$R0, log10(USA_R0_data$Pop_count)),
            cor(USA_R0_data$R0, USA_R0_data$Urban_pop),
            cor(USA_R0_data$R0, log10(USA_R0_data$Total_urban_pop)))
  pop_df <- data.frame(vars, cors)
  names(pop_df) <- c("Predictor", "Pearsons r")
  print("Table S7: Correlations of population demographic predictors with R0:")
  return(xtable(pop_df))
}


#####################################
#####          MAIN              ####
#####################################


# Run analyses and generate latex tables
print("Main analysis:")
table_1()
print("")
print("=============================================================")
print("")
print("Collinearity of climate variables:")
print("")
table_S1()
print("")
variance_inflation()
print("")
table_S2()
print("")
print("============================================================")
print("")
print("Remaining Supplementary Tables:")
print("")
table_S3()
print("")
table_S4()
print("")
table_S5()
print("")
table_S6()
print("")
table_S7()

# write figures
figure_1a()
figure_1b()
figure_2a()
figure_2b()

figure_S1()
figure_S2()
figure_S3()



# -- Old depreciated stuff -- #


# can we plot the USA model residuals onto the US states map?
# i.e. which states have higher R0 than our model predicts, which have lower?
if(FALSE){
library("usmap")

# list of all US states
us_state_list <- data.frame(unique(usmap::us_map()$abbr))
names(us_state_list) <- c("state")

# get residuals from the temp + pop density US model

d$all_residuals <- residuals(lm(R0 ~ Temperature + log10(Pop_density), data = d))
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
