source("src/packages.R")

# Wrapper for model coefficients
.model.coefs <- function(fit, name){
    load(fit)
    env.time <- unlist(rstan::extract(fit, "env_time_slp"))
    env.const <- unlist(rstan::extract(fit, "env_const_slp"))
    pop <- unlist(rstan::extract(fit, "pop_slp"))
    cat("\n", name, ":")
    cat("\n\t env_const:\n")
    print(summary(env.const))
    print(sum(env.const < 0)/length(env.const))
    cat("\n\t env_time:\n")
    print(summary(env.time))
    print(sum(env.time < 0)/length(env.time))
    cat("\n\t pop:\n")
    print(summary(pop))
    print(sum(pop < 0)/length(pop))
    cat("\n")
}

# Load stan model fits
.model.coefs("imptf-models/covid19model-6.0/results/env-europe-stanfit.Rdata", "Europe")
.model.coefs("imptf-models/covid19model-6.0/results/env-europe-stanfit.Rdata", "US")
.model.coefs("imptf-models/covid19model-6.0/results/env-europe-stanfit.Rdata", "Italy")
.model.coefs("imptf-models/covid19model-6.0/results/env-europe-stanfit.Rdata", "Brazil")


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

# Get relative effect sizes
data <- data.frame(
    env, pop, average, transit, residential
)


data <- read.csv("~/wip.csv")
data$X <- NULL
summary <- apply(data, 2, quantile, prob=c(.025,.05,.1,.25,.5,.75,.9,.95,.975))
summary <- summary[,order(summary[1,])]
summary[,"env"] <- -summary[,"env"]

pdf("us-bayes-posterior.pdf")
cols <- c("red","red","black","black","black")
dotchart(summary["50%",], xlim=c(0,2), pch=20, color=cols, pt.cex=4, font=2, frame.plot=FALSE, xlab="Relative importance", labels=c("Temperature","Population density", "Transit mobility", "Residential mobility", "Average mobility"))
arrows(summary["25%",], 1:5, summary["75%",], length=0, lwd=10, col=cols)
arrows(summary["10%",], 1:5, summary["90%",], length=0, lwd=5, col=cols)
arrows(summary["2.5%",], 1:5, summary["97.5%",], length=0, lwd=1, col=cols)
dev.off()

png("~/Desktop/aaaaarg.png")
dotchart(1:3)
points(2,2, cex=1)
points(2,2, cex=2)
points(2,2, cex=3)
points(2,2, cex=4)
dev.off()



points(summary["50%",], 1:5, cex=3, col=cols)
points(summary["50%",], 1:5, cex=4, col=cols)



dotchart(1:5)
points(1:5, 1:5, cex=2)
points(1:5, 1:5, cex=3)
points(1:5, 1:5, cex=4)


points(summary["50%",], 1:5, cex=3, col=cols)
points(summary["50%",], 1:5, cex=4, col=cols)


points(.7, 6, col="grey60", xpd=TRUE, cex=4, pch=20)
arrows(.6,6,.8, length=0, lwd=10, col="grey60", xpd=TRUE)
arrows(.5,6,.9, length=0, lwd=5, col="grey60", xpd=TRUE)
arrows(.4,6,1, length=0, lwd=1, col="grey60", xpd=TRUE)

arrows(summary["10%",], 1:5, summary["90%",], length=0, lwd=5, col=cols)
arrows(summary["2.5%",], 1:5, summary["97.5%",], length=0, lwd=1, col=cols)

pairs(data)
cor(data)

with(data, tapply())

library("bayesplot")
library("rstanarm")
library("ggplot2")

posterior <- as.matrix(data)
mcmc_areas(posterior,
           prob = 0.8)

dotchart(apply(data, 2, median))
