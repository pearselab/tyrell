# Headers
source("src/packages.R")

# Wrapper/worker functions
load.jh <- function(filename, new.cases=FALSE, group.month=FALSE, thousands=TRUE){
    data <- read.csv(filename, as.is=TRUE)
    data$UID <- data$iso2 <- data$iso3 <- data$code3 <- data$FIPS <- data$Combined_Key <- NULL
    
    if(group.month){
        month <- format(as.Date(names(data)[-1:-5], format="X%m.%d.%y"), "%m-%y")
        data <- data.frame(data[,1:5], t(apply(data[-1:-5], 1, function(x) tapply(x, month, sum))))
        names(data)[-1:-5] <- as.character(as.Date(names(data)[-1:-5],format="X%m.%y"))
    } else {
        if(new.cases){
            for(i in seq(ncol(data)-1, 6, by=-1))
                data[,i+1] <- data[,i+1] - data[,i]
        }
        data <- melt(data, id.vars=names(data)[1:5], measure.vars=names(data)[-1:-5])
        data$variable <- gsub("X", "", data$variable)
        data$variable <- as.Date(data$variable, format="%m.%d.%y")
        names(data) <- tolower(names(data))
        names(data)[5:7] <- c("long","date","cases")
        data$doy <- as.numeric(data$date - as.Date("2020-01-01"))

        total <- with(data, tapply(cases, doy, sum))
        total <- data.frame(cases=total, doy=names(total), date=as.Date("2020-01-01")+as.numeric(names(total)))

        if(thousands){
            total$cases <- total$cases/1000
            data$cases <- data$cases/1000
        }
        return(list(states=data, total=total))
    }
}
run.arima <- function(x, days, offset, min, max, width, ar=2, i=2, ma=0, log=FALSE, thousands=TRUE){
    if(log)
        x <- log10(x)
    if(!thousands)
        stop("Assumes data are formatted for AGORA")
    model <- arima(x, order=c(ar, i, ma))
    pred <- predict(model, n.ahead=days)
    pred$pred <- pred$pred - offset
    bin <- seq(min, max, width)
    
    return(data.frame(
        prob=dnorm(bin, pred$pred[days], pred$se[days]),
        bin=bin
    ))
}

# Grab data
c(states, total) %<-% load.jh("raw-data/cases/jh-us-confirmed.csv")
c(d.states, d.total) %<-% load.jh("raw-data/cases/jh-us-confirmed.csv", new.cases=TRUE)

# Run prediction (formatting as needed)
curr.day <- total$date[nrow(total)]
n.days <- as.numeric(as.Date("2020-09-30") - as.Date(curr.day))
base <- total$cases[total$date=="2020-08-31"]
arima.pred <- run.arima(total$cases, days=n.days, offset=base, min=0, max=4000, width=25)
with(arima.pred, plot(prob ~ bin))

arima.pred <- run.arima(total$cases, days=n.days+30, offset=base, min=0, max=4000, width=25)
with(arima.pred, plot(prob ~ bin))
