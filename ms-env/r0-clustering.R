#########################################
# Clustering - environmental variables  #
# and datasets                          #
#########################################

source("src/packages.R")

R0_data <- read.csv("clean-data/climate_and_R0.csv")

## ---------------------- PCA ----------------------- ##

# First we want to do a PCA to look at collinearity between climate variables

R0_data <- R0_data[!is.na(R0_data$Feb_UV),]
test_data <- R0_data[,c("February_20_TC", "February_20_AH", "Feb_UV", "Pop_density")]
names(test_data) <- c("Temperature", "Absolute Humidity", "UV-B", "Population density")
# need to log the pop density as massively skewed
test_data$`Population density` <- log(test_data$`Population density`)

# do the PCA
pca_model <- prcomp(test_data, scale. = TRUE, center = TRUE)

png("figures/pca_plot.png", width = 400, height = 400)
ggbiplot(pca_model, groups = R0_data$dataset, varname.size = 4, varname.adjust = 1) + 
  #geom_point(aes(colour = R0_data$dataset), size = 3) +
  theme_bw() + 
  xlim(c(-2, 3)) + 
  ylim(c(-3, 3)) + 
  theme(legend.position = c(0.85, 0.8),
        legend.text = element_text(size = 12),
        legend.title = element_blank(),
        aspect.ratio=1,
        axis.text = element_text(size = 12),
        axis.title = element_text(size = 14))
dev.off()



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
