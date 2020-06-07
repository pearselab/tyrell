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

# Load data (note problems with NextStrain branch lengths)
tree <- read.tree("raw-data/nxtstr-tree-date.tre")
tree$edge.length[tree$edge.length <= 0] <- min(tree$edge.length[tree$edge.length > 0])
meta <- read.delim("raw-data/nxtstr-meta.tsv", as.is=TRUE, quote="")
c.temp <- readRDS("clean-data/worldclim-countries.RDS")[,,"tmean"]
countries <- shapefile("clean-data/gadm-countries.shp")
s.temp <- readRDS("clean-data/worldclim-states.RDS")[,,"tmean"]
states <- shapefile("clean-data/gadm-states.shp")

# Map country and state-level temperatures onto phylogeny
meta$month <- month(as.Date(meta$Collection.Data))
meta$c.temp <- c.temp[cbind(match(meta$Country,countries$NAME_0), meta$month)]
meta$s.temp <- s.temp[cbind(match(meta$Admin.Division,states$NAME_1), meta$month)]

# Merge temperatures together using whatever we can (prefering states)
meta$temp <- meta$s.temp
meta$temp[is.na(meta$temp)] <- meta$c.temp[is.na(meta$temp)]

# Match data in comparative.data object
tree <- multi2di(tree)
tree$node.label <- NULL
c.data <- comparative.data(tree, meta[,c("Strain","temp")], names.col=Strain)

# Estimate signal
sink("phylo-env/signal-nxtstrain-mtemp.txt")
phylosig(c.data$phy, c.data$data$temp, method="lambda", test=TRUE)
phylosig(c.data$phy, c.data$data$temp, method="K", test=TRUE)
sink()

# Reconstruct temperature
cols <- .get.branch.trait(c.data$data$temp, c.data$phy)
cols[is.na(cols)] <- c.data$data$temp

# Make plot
cut <- cut(cols, seq(floor(min(cols)), ceiling(max(cols)), length.out=1000))
v.cols <- viridis(1000)
pdf("phylo-env/signal-nxtstrain-mtemp.pdf", width=10, height=3)
bg <- plot(c.data$phy, edge.color=v.cols[cut], direction="up", show.tip.label=FALSE, no.margin=TRUE)
mid <- median(bg$x.lim)
gradient.rect(mid, .02, bg$x.lim[2], .075, col=v.cols, border=NA)
text(seq(mid,bg$x.lim[2], length.out=7), .048, labels=round(seq(min(c.data$data$temp),max(c.data$data$temp), length.out=7)))
text(median(c(mid,bg$x.lim[2])), .085, "Temperature (°C)", font=2)
dev.off()

# Save workspace because reconstruction takes a while (for nice plotting later)
save.image("phylo-env/signal.RData")
