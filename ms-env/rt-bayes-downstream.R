source("src/packages.R")
file_datestamp <- commandArgs(trailingOnly=TRUE)[1]

# Pull back in environmental data (modified from original model script)
env <- readRDS("clean-data/temp-dailymean-states.RDS")
pop <- readRDS("clean-data/population-density-states.RDS")
meta <- shapefile("clean-data/gadm-states.shp")
processed_data <- readRDS("ms-env/processed_data_usa.RDS")
env <- env[meta$NAME_0=="United States",]
pop <- pop[meta$NAME_0=="United States",]
meta <- meta[meta$NAME_0=="United States",]
meta$code <- sapply(strsplit(meta$HASC_1, ".", fixed=TRUE), function(x) x[2])
env <- env[match(names(processed_data$reported_deaths), meta$code),]
pop <- log10(pop[match(names(processed_data$reported_deaths), meta$code)])
env <- env[,34:148]
sd.env <- sd(env, na.rm=TRUE)
sd.pop <- sd(pop, na.rm=TRUE)
# Remove variables with same names (unnecessary, but done for clarity!)
rm(env,pop,meta,processed_data)

# Get raw coefficients and then back-transform, thne neaten and merge data
load(paste0("ms-env/rt-bayes-",file_datestamp".Rdata")
env <- unlist(rstan::extract(fit, "env_time_slp"))
pop <- unlist(rstan::extract(fit, "pop_slp"))
average <- unlist(rstan::extract(fit, "alpha[1]"))
transit <- unlist(rstan::extract(fit, "alpha[2]"))
residential <- unlist(rstan::extract(fit, "alpha[3]"))
data <- data.frame(
    env, pop, average, transit, residential
)
data$r.env <- data$env/sd.env; data$r.pop <- data$pop/sd.pop

# Calculate mobility changes needed to counter-act env/pop change
# NOTE: using optim for this, rather than algebra, because the
#       posterior distributions of the coefficients aren't always going to
#       be positive or negative (i.e., p!=1) and so you can have problems
#       using logits
# NOTE: using positive term for x*mob.coef because the X data are
#       flipped (i.e., reductions in mobility are positive); discussed
#       with Ettie
inv.logit <- function(x) exp(x) / (exp(x)+1)
logit <- function(x) log(x / (1-x))
optim.func <- function(x, target, mob.coef, new.r0) return(abs(target - (2*new.r0*inv.logit(x*mob.coef))))
optim.wrap <- function(target, mob.coef, new.r0){
    output <- optim(0, optim.func, method="Brent", lower=-10, upper=0, target=target, mob.coef=mob.coef, new.r0=new.r0)
    if(output$convergence != 0)
        stop("Something has gone wrong")
    return(output$par)
}
data$e.four <- data$e.two <- data$e.one <- data$p.twenty <- data$p.ten <- data$p.five <- -999
for(i in seq_len(nrow(data))){
    data$e.four[i] <- optim.wrap(1, data$average[i], 1+abs(data$r.env[i]*4))
    data$e.two[i] <- optim.wrap(1, data$average[i], 1+abs(data$r.env[i]*2))
    data$e.one[i] <- optim.wrap(1, data$average[i], 1+abs(data$r.env[i]*1))
    data$p.twenty[i] <- optim.wrap(1, data$residential[i], 1+abs(data$r.env[i]*log10(20)))
    data$p.ten[i] <- optim.wrap(1, data$residential[i], 1+abs(data$r.env[i]*log10(10)))
    data$p.five[i] <- optim.wrap(1, data$residential[i], 1+abs(data$r.env[i]*log10(5)))
}

summary <- -apply(data[,c("p.twenty","p.ten","p.five","e.four","e.two","e.one")], 2, quantile, prob=c(.05,.1,.25,.5,.75,.9,.95)) * 100
cols <- c("red","red","red","black","black","black")
labels <- c("20x denser population","10x denser population","5x denser population","4°C cooler","2°C cooler","1°C cooler")
cols <- cols[order(summary["50%",])]
labels <- labels[order(summary["50%",])]
summary <- summary[,order(summary["50%",])]

# Generate paper summary statistics
print("Begin summary stats for MS")
summary <- apply(data, 2, quantile, prob=c(.025,.05,.1,.25,.5,.75,.9,.95,.975))
print("Posterior summaries:")
summary["50%",]
print("")
print("P(env < 0):")
(sum(data$env < 0) / nrow(data)) * 100 # Bayesian p-value
print("")
print("P(pop > 0):")
(sum(data$pop > 0) / nrow(data)) * 100 # Bayesian p-value
print("")
print("Posterior correlations:")
cor(data)
print("")
print("Change estimates:")
print(paste0("5 degree change: ", mean(data$r.env)*5))
print(paste0("10x density change: ", mean(data$r.pop)*1))
print("")
print("Model coefficients for supplement:")
xtable(summary(fit, pars=c("alpha","alpha_state","alpha_region","mu","env_time_slp","pop_slp")))

## TS: New figure

# just make 1 new col, then take the distribution, save the quantiles... and overwrite this each new temp/pop

temp_seq <- seq(0.1, 5, 0.1)

# make an empty dataframe to populate with new results
temp_results <- data.frame(temperature = rep(NA, length(temp_seq)))
temp_results$mob_5 <- NA
temp_results$mob_12.5 <- NA
temp_results$mob_50 <- NA
temp_results$mob_87.5 <- NA
temp_results$mob_95 <- NA

for(i in 1:length(temp_seq)){
    temp <- temp_seq[i]
    data$e.temp <- -999
    
    for(j in seq_len(nrow(data))){
        data$e.temp[j] <- optim.wrap(1, data$average[j], 1+abs(data$r.env[j]*temp_seq[i]))
    }
    
    temp_results$temperature[i] <- temp
    temp_results$mob_5[i] <- -quantile(data$e.temp, prob=c(.05))*100
    temp_results$mob_12.5[i] <- -quantile(data$e.temp, prob=c(.125))*100
    temp_results$mob_50[i] <- -quantile(data$e.temp, prob=c(.5))*100
    temp_results$mob_87.5[i] <- -quantile(data$e.temp, prob=c(.875))*100
    temp_results$mob_95[i] <- -quantile(data$e.temp, prob=c(.95))*100
}

# now repeat for population density

pop_seq <- seq(1, 10, 0.1)

# make an empty dataframe to populate with new results
pop_results <- data.frame(pop_density = rep(NA, length(pop_seq)))
pop_results$mob_5 <- NA
pop_results$mob_12.5 <- NA
pop_results$mob_50 <- NA
pop_results$mob_87.5 <- NA
pop_results$mob_95 <- NA

for(i in 1:length(pop_seq)){
    pop <- pop_seq[i]
    data$e.pop <- -999
    
    for(j in seq_len(nrow(data))){
        data$e.pop[j] <- optim.wrap(1, data$average[j], 1+abs(data$r.pop[j]*log10(pop_seq[i])))
    }
    
    pop_results$pop_density[i] <- pop
    pop_results$mob_5[i] <- -quantile(data$e.pop, prob=c(.05))*100
    pop_results$mob_12.5[i] <- -quantile(data$e.pop, prob=c(.125))*100
    pop_results$mob_50[i] <- -quantile(data$e.pop, prob=c(.5))*100
    pop_results$mob_87.5[i] <- -quantile(data$e.pop, prob=c(.875))*100
    pop_results$mob_95[i] <- -quantile(data$e.pop, prob=c(.95))*100
}


fig3 <- ggplot(temp_results) +
    geom_line(aes(x = temperature, y = mob_50), col = "#CC6600", lwd = 2) +
    geom_line(aes(x = temperature, y = mob_12.5), alpha = 0.8, col = "#CC6600", linetype = "dashed", lwd = 1.5) +
    geom_line(aes(x = temperature, y = mob_87.5), alpha = 0.8, col = "#CC6600", linetype = "dashed", lwd = 1.5) +
    geom_line(aes(x = temperature, y = mob_95), alpha = 0.8, col = "#CC6600", linetype = "dotted", lwd = 1) +
    geom_line(aes(x = temperature, y = mob_5), alpha = 0.8, col = "#CC6600", linetype = "dotted", lwd = 1) +
    geom_line(data = pop_results, aes(x = pop_density/2, y = mob_50), col = "#6666FF", lwd = 2) +
    geom_line(data = pop_results, aes(x = pop_density/2, y = mob_12.5), alpha = 0.8, col = "#6666FF", linetype = "dashed", lwd = 1.5) +
    geom_line(data = pop_results, aes(x = pop_density/2, y = mob_87.5), alpha = 0.8, col = "#6666FF", linetype = "dashed", lwd = 1.5) +
    geom_line(data = pop_results, aes(x = pop_density/2, y = mob_95), alpha = 0.8, col = "#6666FF", linetype = "dotted", lwd = 1) +
    geom_line(data = pop_results, aes(x = pop_density/2, y = mob_5), alpha = 0.8, col = "#6666FF", linetype = "dotted", lwd = 1) +
    labs(x = "Temperature Decrease (°C)", y = "% Reduction in Mobility to Mitigate") +
    scale_x_continuous(sec.axis = sec_axis(~. *2, name = "X Greater Population Density")) +
    theme_bw() +
    theme(axis.title.x.bottom = element_text(colour = "#CC6600", size = 18, face = "bold"),
          axis.text.x.bottom = element_text(colour = "#CC6600", size = 16, face = "bold"),
          axis.title.x.top = element_text(colour = "#6666FF", size = 18, face = "bold"),
          axis.text.x.top = element_text(colour = "#6666FF", size = 16, face = "bold"),
          axis.text.y = element_text(size = 16, face = "bold"),
          axis.title.y = element_text(size = 18, face = "bold"),
          panel.grid.major.x = element_blank(),
          panel.grid.minor.x = element_blank())
fig3

ggsave("figures/US_bayes_plot.pdf", fig3)
