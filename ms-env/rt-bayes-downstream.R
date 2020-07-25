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
data$e.average <- data$p.average <- -999 #data$e.transit <- data$e.residential <- data$p.average <- data$p.transit <- data$p.residential <- -999
dc <- 2 # Assume 2 Degree Change
pc <- 1 # Assume 1 log-unit Population Change (i.e., 10x)
for(i in seq_len(nrow(data))){
    data$e.average[i] <- optim.wrap(1, data$average[i], 1+abs(data$r.env[i]*dc))
    #data$e.transit[i] <- optim.wrap(1, data$transit[i], 1+abs(data$r.env[i]*dc))
    data$e.residential[i] <- optim.wrap(1, data$residential[i], 1+abs(data$r.env[i]*dc))
    data$p.average[i] <- optim.wrap(1, data$average[i], 1+abs(data$r.pop[i]*pc))
    #data$p.transit[i] <- optim.wrap(1, data$transit[i], 1+abs(data$r.pop[i]*pc))
    data$p.residential[i] <- optim.wrap(1, data$residential[i], 1+abs(data$r.pop[i]*pc))    
}
summary <- -apply(data[,c("p.residential","p.average","e.residential","e.average")], 2, quantile, prob=c(.05,.1,.25,.5,.75,.9,.95)) * 100

# Relative reduction plot
pdf("us-bayes-posterior.pdf")
cols <- c("black","red","black","red")
dotchart(summary["50%",], xlim=c(1,600), pch=20, color=cols, pt.cex=4, font=2, frame.plot=FALSE, xlab="Percent reduction needed in                       mobility to mitigate", labels=c("10x denser population","10x denser population","5°C cooler","5°C cooler"), log="x")
mtext("                                              residential", side=1, line=2.5, font=2, adj=0)
mtext("                                                 average", side=1, line=3.5, font=2, adj=0, col="red")
arrows(summary["25%",], 1:4, summary["75%",], length=0, lwd=10, col=cols)
arrows(summary["10%",], 1:4, summary["90%",], length=0, lwd=5, col=cols)
arrows(summary["5%",], 1:4, summary["95%",], length=0, lwd=1, col=cols)
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
sink()
