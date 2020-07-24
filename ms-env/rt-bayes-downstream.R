source("src/packages.R")

# Pull back in environmental data (modified from original model script)
env <- readRDS("clean-data/temp-midday-states.RDS")
pop <- readRDS("clean-data/population-density-states.RDS")
meta <- shapefile("clean-data/gadm-states.shp")
processed_data <- readRDS("ms-env/processed_data_usa.RDS")
env <- env[meta$NAME_0=="United States",]
pop <- pop[meta$NAME_0=="United States",]
meta <- meta[meta$NAME_0=="United States",]
meta$code <- sapply(strsplit(meta$HASC_1, ".", fixed=TRUE), function(x) x[2])
env <- env[match(names(processed_data$reported_deaths), meta$code),]
pop <- log10(pop[match(names(processed_data$reported_deaths), meta$code)])
env_time <- env[,34:148]
sd.env <- sd(env_time, na.rm=TRUE)
sd.pop <- sd(pop, na.rm=TRUE)
# Remove variables with same names (unnecessary, but done for clarity!)
rm(env,pop,env_time,meta,processed_data)

# Get raw coefficients and then back-transform, thne neaten and merge data
load("imptf-models/covid19model-6.0/results/rt-bayes.Rdata")
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
inv.logit <- function(x) exp(x) / (exp(x)+1)
logit <- function(x) log(x / (1-x))
optim.func <- function(x, target, mob.coef, new.r0) return(abs(target - (new.r0*inv.logit(-(1-x)*mob.coef))))
optim.wrap <- function(target, mob.coef, new.r0){
    output <- optim(0, optim.func, method="Brent", lower=-10, upper=10, target=target, mob.coef=mob.coef, new.r0=new.r0)
    if(output$convergence != 0)
        stop("Something has gone wrong")
    return(output$par)
}

data$e.average <- data$e.transit <- data$e.residential <- data$p.average <- data$p.transit <- data$p.residential <- -999
for(i in 1:50){
    #for(i in seq_len(nrow(data))){
    data$e.average[i] <- optim.wrap(1, data$average[i], 1+abs(data$r.env[i]))
    data$e.transit[i] <- optim.wrap(1, data$transit[i], 1+abs(data$r.env[i]))
    data$e.residential[i] <- optim.wrap(1, data$residential[i], 1+abs(data$r.env[i]))
    data$p.average[i] <- optim.wrap(1, data$average[i], 1+abs(data$r.pop[i]))
    data$p.transit[i] <- optim.wrap(1, data$transit[i], 1+abs(data$r.pop[i]))
    data$p.residential[i] <- optim.wrap(1, data$residential[i], 1+abs(data$r.pop[i]))    
}
    


summary <- apply(data, 2, quantile, prob=c(.025,.05,.1,.25,.5,.75,.9,.95,.975))
summary <- summary[,order(summary[1,])]







optim(1, optim.wrap, target=.1, mob.coef=1, method="Brent", lower=-10, upper=10)
hist(logit(data$r.env/2) / data$transit)

two.inv.logit()

# Neaten data (reversing env for pretty plotting)
data <- data.frame(
    env, pop, average, transit, residential, r.env, r.pop
)
summary <- apply(data, 2, quantile, prob=c(.025,.05,.1,.25,.5,.75,.9,.95,.975))
summary <- summary[,order(summary[1,])]
summary[,"env"] <- -summary[,"env"]; summary[,"r.env"] <- -summary[,"r.env"]

# Calculate relative 

# Generate plot
pdf("us-bayes-posterior.pdf")
cols <- c("red","red","black","black","black")
dotchart(summary["50%",], xlim=c(0,2), pch=20, color=cols, pt.cex=4, font=2, frame.plot=FALSE, xlab="Relative importance", labels=c("Temperature","Population density", "Transit mobility", "Residential mobility", "Average mobility"))
arrows(summary["25%",], 1:5, summary["75%",], length=0, lwd=10, col=cols)
arrows(summary["10%",], 1:5, summary["90%",], length=0, lwd=5, col=cols)
arrows(summary["2.5%",], 1:5, summary["97.5%",], length=0, lwd=1, col=cols)
dev.off()

# Summary statistics in paper are:
summary["50%",] # Coefficients
(sum(data$env < 0) / nrow(data)) * 100 # Bayesian p-value
(sum(data$pop > 0) / nrow(data)) * 100 # Bayesian p-value
