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
env <- env[,34:148]
sd.env <- sd(env, na.rm=TRUE)
sd.pop <- sd(pop, na.rm=TRUE)
# Remove variables with same names (unnecessary, but done for clarity!)
rm(env,pop,env,meta,processed_data)

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

# Relative reduction plot
pdf("ms-env/us-bayes-posterior.pdf")
dotchart(summary["50%",], xlim=c(1,70), pch=20, color=cols, pt.cex=4, font=2, frame.plot=FALSE, xlab="Percent reduction needed in average mobility to mitigate", labels=labels)
arrows(summary["25%",], 1:6, summary["75%",], length=0, lwd=10, col=cols)
arrows(summary["10%",], 1:6, summary["90%",], length=0, lwd=5, col=cols)
arrows(summary["5%",], 1:6, summary["95%",], length=0, lwd=1, col=cols)
dev.off()

# Generate paper summary statistics
summary <- apply(data, 2, quantile, prob=c(.025,.05,.1,.25,.5,.75,.9,.95,.975))
sink("ms-env/rt-bayes-downstream.txt")
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
sink()
