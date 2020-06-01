source("src/packages.R")

# Load stan model fits
load("imptf-models/covid19model-6.0/results/env-europe-stanfit.Rdata")
europe <- unlist(extract(fit, "env_slp"))

# Estimate impacts and probabilities
print(summary(europe))
print(sum(europe < 0) / length(europe))
