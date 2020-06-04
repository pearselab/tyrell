# Headers
source("src/packages.R")

# Plotting wrappers
.get.branch.trait <- function(trait, tree){
    trait <- c(trait[tree$tip.label], fastAnc(tree, trait))
    names(trait)[1:length(tree$tip.label)] <- 1:length(tree$tip.label)
    edge.mat <- matrix(trait[tree$edge], nrow(tree$edge), 2)
    trait <- rowMeans(edge.mat)
    return(trait)
}
.limit <- function(x){
    min <- min(x); max <- max(x)
    x <- x - min
    x <- x/max(x)
    attr(x, "range") <- c(min, max)
    return(x)
}

# Load data
tree <- read.tree("raw-data/nxtstr-tree-date.tre")
meta <- read.delim("raw-data/nxtstr-meta.tsv")
c.temp <- readRDS("clean-data/worldclim-countries.RDS")[,,"tmean"]
s.temp <- readRDS("clean-data/worldclim-states.RDS")[,,"tmean"]

# Map country and state-level temperatures onto phylogeny
meta$month <- month(as.Date(meta$Collection.Data))
meta$c.temp <- c.temp[meta$Country,meta$month]
meta$s.temp <- c.temp[meta$Admin.Division,meta$month]

# Match data in comparative.data object
tree <- multi2di(tree)
tree$node.label <- NULL
c.data <- comparative.data(tree, meta, names.col=Strain)

# Estimate signal
sink("phylo-env/signal-nxtstrain-mtemp.txt")
phylosig(c.data$phy, c.data$data$c.temp, method="lambda", test=TRUE)
phylosig(c.data$phy, c.data$data$c.temp, method="K", test=TRUE)
phylosig(c.data$phy, c.data$data$s.temp, method="lambda", test=TRUE)
phylosig(c.data$phy, c.data$data$s.temp, method="K", test=TRUE)
sink()

# Reconstruct temperature (hackety-hack)
c.data <- c.data[sample(nrow(c.data$data), 1000, replace=FALSE),]
cols <- .get.branch.trait(c.data$data$temp.min, c.data$phy)
cols[is.na(cols)] <- c.data$data$temp.min

# Make plot
cut <- cut(cols, seq(-28, 25, length.out=1000))
v.cols <- viridis(1000)
pdf("phylo-env/signal-nxtstrain-mtemp.pdf", width=10, height=3)
bg <- plot(c.data$phy, edge.color=v.cols[cut], direction="up", show.tip.label=FALSE, no.margin=TRUE)
gradient.rect(1500, .02, bg$x.lim[2], .075, col=v.cols, border=NA)
text(seq(1500,bg$x.lim[2], length.out=7), .048, labels=round(seq(min(c.data$data$temp.min),max(c.data$data$temp.min), length.out=7)))
text(median(c(1500,bg$x.lim[2])), .085, "Temperature (°C)", font=2)
dev.off()
