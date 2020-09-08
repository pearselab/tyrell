load.jh <- function(filename, new.cases=FALSE, group.month=FALSE){
    data <- read.csv(filename, as.is=TRUE)
    data$UID <- data$iso2 <- data$iso3 <- data$code3 <- data$FIPS <- data$Combined_Key <- NULL
    browser()
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
        
        return(list(states=data, total=total))
    }
}

c(states, total) %<-% load.jh("raw-data/cases/jh-us-confirmed.csv")
c(d.states, d.total) %<-% load.jh("raw-data/cases/jh-us-confirmed.csv", new.cases=TRUE)

with(d.states, plot(cases ~ doy, pch=20))
