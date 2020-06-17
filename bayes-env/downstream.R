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
    print(sum(env.const < 0))
    cat("\n\t env_time:\n")
    print(summary(env.time))
    print(sum(env.time < 0))
    cat("\n\t pop:\n")
    print(summary(pop))
    print(sum(pop < 0))
    cat("\n")
}

# Load stan model fits
.model.coefs("imptf-models/covid19model-6.0/results/env-europe-stanfit.Rdata", "Europe")
.model.coefs("imptf-models/covid19model-6.0/results/env-europe-stanfit.Rdata", "US")
.model.coefs("imptf-models/covid19model-6.0/results/env-europe-stanfit.Rdata", "Italy")
.model.coefs("imptf-models/covid19model-6.0/results/env-europe-stanfit.Rdata", "Brazil")
