source("src/packages.R")

# Load data
data <-  read.csv("clean-data/daily_climate_and_Rt_UK.csv")
# Format into matrices and average mobility together (excluding parks and residential)
r <- with(data, tapply(Rt, list(area, date), mean, na.rm=TRUE))
temp <- with(data, tapply(temperature, list(area, date), mean, na.rm=TRUE))
humid <- with(data, tapply(absolute_humidity, list(area, date), mean, na.rm=TRUE))
uv <- with(data, tapply(uv, list(area, date), mean, na.rm=TRUE))
pop <- log10(with(data, tapply(Pop_density, list(area, date), mean, na.rm=TRUE)))
pm2pt5 <- log10(with(data, tapply(pm2pt5, list(area, date), mean, na.rm=TRUE)))
data$avg.mob <- with(data, mapply(median, retail_and_recreation_percent_change_from_baseline, grocery_and_pharmacy_percent_change_from_baseline, transit_stations_percent_change_from_baseline, workplaces_percent_change_from_baseline, na.rm = TRUE))
mob <- with(data, tapply(avg.mob, list(area, date), mean, na.rm=TRUE))

# these are correlations independent of time, i.e. across space:
# Run models
date.cors <- rep(NA, ncol(r))
for(i in seq_along(date.cors)){
  tryCatch({
    model <- lm(r[,i] ~ temp[,i] + pop[,i] + mob[,i])
    date.cors[i] <- summary(model)$r.squared
  }, error=function(x) NA)
}
date.cors[date.cors==0] <- NA
# Plot model r2
plot(date.cors, type="b", pch=20, axes=FALSE, xlab="", ylab=expression(r^2))
dates <- c("2020-03-01","2020-04-01","2020-05-01","2020-06-01","2020-07-01","2020-08-01")
dates <- setNames(dates, match(dates, colnames(r)))
axis(1, at=names(dates), labels=c("Mar","Apr","May","June","July","Aug"))
axis(2)


# these correlations across the whole time-series:
temp.cors <- hum.cors <- uv.cors <- poll.cors <- mob.cors <- rep(NA, nrow(r))
for(i in seq_along(temp.cors)){
  tryCatch({
    temp.cors[i] <- cor(x = temp[i,], y = r[i,], use = "complete.obs")
    hum.cors[i] <- cor(x = humid[i,], y = r[i,], use = "complete.obs")
    uv.cors[i] <- cor(x = uv[i,], y = r[i,], use = "complete.obs")
    poll.cors[i] <- cor(x = pm2pt5[i,], y = r[i,], use = "complete.obs")
    mob.cors[i] <- cor(x = mob[i,], y = r[i,], use = "complete.obs")
  }, error=function(x) NA)
}

# join these into a nice dataframe
cor.results <- data.frame(area = rep(rownames(r), 5), cor = c(temp.cors, hum.cors, uv.cors, poll.cors, mob.cors), 
                          var = rep(c("temperature", "humidity", "uv", "pollution", "mobility"), each = nrow(r)))

ggplot(cor.results, aes(x = var, y = cor)) + 
  geom_boxplot(outlier.shape = NA) +
  geom_point(position = position_jitter(width = 0.2), alpha = 0.5)


ggplot(cor.results, aes(x = cor)) + 
  geom_density() +
  facet_wrap(~var, ncol = 1) 

# as expected, mobility generally positively correlated with Rt
# climate generally negatively correlated (but can be due to temporal autocorrelation)