source("src/packages.R")

# Load workspace
load("imptf-models/covid19model-6.0/results/env-pop-usa-stanfit.Rdata")

# Get raw coefficients
env <- unlist(rstan::extract(fit, "env_time_slp"))
pop <- unlist(rstan::extract(fit, "pop_slp"))
average <- unlist(rstan::extract(fit, "alpha[1]"))
transit <- unlist(rstan::extract(fit, "alpha[2]"))
residential <- unlist(rstan::extract(fit, "alpha[3]"))

# Transform (for comparison, following Gelman 2013 for the halving rule)
# and the equations in the SI for the inv.logit
inv.logit <- function (x) 
    exp(x)/(exp(x) + 1)
env <- env/2; pop <- pop/2
average <- 2*inv.logit(average); transit <- 2*inv.logit(transit); residential <- 2*inv.logit(residential)

# Get relative effect sizes and neaten data
data <- data.frame(
    env, pop, average, transit, residential
)
summary <- apply(data, 2, quantile, prob=c(.025,.05,.1,.25,.5,.75,.9,.95,.975))
summary <- summary[,order(summary[1,])]
summary[,"env"] <- -summary[,"env"]

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
