source("src/packages.R")

# Load stan model fits
load("imptf-models/covid19model-6.0/results/env-europe-stanfit.Rdata")
europe <- unlist(rstan::extract(fit, "env_slp"))
load("imptf-models/covid19model-6.0/results/env-usa-stanfit.Rdata")
usa <- unlist(rstan::extract(fit, "env_slp"))
load("imptf-models/covid19model-6.0/results/env-brazil-stanfit.Rdata")
brazil <- unlist(rstan::extract(fit, "env_slp"))

# Estimate impacts and probabilities
print("Europe:")
print(summary(europe))
print(sum(europe < 0) / length(europe))
print("\n\n")
print("USA:")
print(summary(usa))
print(sum(usa < 0) / length(usa))
print("\n\n")
print("Brazil:")
print(summary(brazil))
print(sum(brazil < 0) / length(brazil))
print("\n\n")
