#########################################
# Clustering - environmental variables  #
# and datasets                          #
#########################################

source("src/packages.R")


# This is all depreciated now that we aren't combining datasets #
# TS: removing from rakefile

## ---------------------- mclust ----------------------- ##

# now use mclust to ask whether Europe/USA/LMIC data are substantially different
# and cluster into seperate groups

# cluster based on the predictors we used
test_data <- R0_data[,c("dataset", "R0", "February_20_TC", "Pop_density")]
names(test_data) <- c("location_type", "R0", "Temperature", "Population density")
test_data$`Population density` <- log(test_data$`Population density`)

class <- test_data$location_type

# remove the locations column
X <- test_data[,-1]

# run mclust model fitting
mod <- Mclust(X)
summary(mod$BIC)
summary(mod)

# plot the BIC traces, removing the two models with lower BIC
png("figures/dataset_clustering.png")
plot(mod, what = "BIC", ylim = range(mod$BIC[,-(1:2)], na.rm = TRUE),
     legendArgs = list(x = "bottomleft"))
dev.off()

# EVE preferred, with 3 categories

# The adjusted Rand index (ARI; Hubert and Arabie, 1985), which can be used for evaluating a clustering solution.
adjustedRandIndex(class, mod$classification)
# The ARI is a measure of agreement between two partitions, 
# one estimated by a statistical procedure independent of the labelling of the groups,
# and one being the true classification. It has zero expected value in the case of a random partition,
# and it is bounded above by 1, with higher values representing better partition accuracy.

# bootstrap sequential likelihood ratio tests for the
# number of mixture components
LRT <- mclustBootstrapLRT(X, modelName = "EVE")
LRT # p-values indicate the presence of 3 clusters

# fitted model provides a reasonable recovery of the true groupings
table(class, mod$classification)
