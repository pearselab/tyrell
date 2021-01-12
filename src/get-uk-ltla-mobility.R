# can we match LTLA data to google mobility data?
source("src/packages.R")

mobility_data <- read.csv("raw-data/google-mobility.csv")

uk_mobil <- mobility_data[mobility_data$country_region_code == "GB",]

# first step we can do a lot of cleaning up with gsub to make the region names match
uk_mobil$sub_region_2 <- gsub("London Borough of ", "", uk_mobil$sub_region_2)
uk_mobil$sub_region_2 <- gsub("Metropolitan Borough of ", "", uk_mobil$sub_region_2)
uk_mobil$sub_region_2 <- gsub("Borough of ", "", uk_mobil$sub_region_2)
uk_mobil$sub_region_2 <- gsub(" District", "", uk_mobil$sub_region_2)
uk_mobil$sub_region_2 <- gsub("Royal ", "", uk_mobil$sub_region_2)
uk_mobil$sub_region_2 <- gsub(" Borough", "", uk_mobil$sub_region_2)

uk_mobil$sub_region_1 <- gsub(" Council", "", uk_mobil$sub_region_1)
uk_mobil$sub_region_1 <- gsub(" Principle Area", "", uk_mobil$sub_region_1)
uk_mobil$sub_region_1 <- gsub(" Principal Area", "", uk_mobil$sub_region_1)
uk_mobil$sub_region_1 <- gsub(" County Borough", "", uk_mobil$sub_region_1)
uk_mobil$sub_region_1 <- gsub("Borough of ", "", uk_mobil$sub_region_1)

# now the more specific things that need fixing individually
uk_mobil[uk_mobil$sub_region_1 == "Bristol" & !is.na(uk_mobil$sub_region_1),]$sub_region_1 <- "Bristol, City of"
uk_mobil[uk_mobil$sub_region_1 == "Edinburgh" & !is.na(uk_mobil$sub_region_1),]$sub_region_1 <- "City of Edinburgh"
uk_mobil[uk_mobil$sub_region_1 == "Derry and Strabane" & !is.na(uk_mobil$sub_region_1),]$sub_region_1 <- "Derry City and Strabane"
uk_mobil[uk_mobil$sub_region_1 == "Herefordshire" & !is.na(uk_mobil$sub_region_1),]$sub_region_1 <- "Herefordshire, County of"
uk_mobil[uk_mobil$sub_region_1 == "Kingston upon Hull" & !is.na(uk_mobil$sub_region_1),]$sub_region_1 <- "Kingston upon Hull, City of"
uk_mobil[uk_mobil$sub_region_1 == "Na h-Eileanan an Iar" & !is.na(uk_mobil$sub_region_1),]$sub_region_1 <- "Na h-Eileanan Siar"
uk_mobil[uk_mobil$sub_region_1 == "Orkney" & !is.na(uk_mobil$sub_region_1),]$sub_region_1 <- "Orkney Islands"
uk_mobil[uk_mobil$sub_region_1 == "Rhondda Cynon Taff" & !is.na(uk_mobil$sub_region_1),]$sub_region_1 <- "Rhondda Cynon Taf"

uk_mobil[uk_mobil$sub_region_2 == "City of Canterbury" & !is.na(uk_mobil$sub_region_2),]$sub_region_2 <- "Canterbury"
uk_mobil[uk_mobil$sub_region_2 == "City of Carlisle" & !is.na(uk_mobil$sub_region_2),]$sub_region_2 <- "Carlisle"
uk_mobil[uk_mobil$sub_region_2 == "City of Preston" & !is.na(uk_mobil$sub_region_2),]$sub_region_2 <- "Preston"
uk_mobil[uk_mobil$sub_region_2 == "Saint Albans" & !is.na(uk_mobil$sub_region_2),]$sub_region_2 <- "St Albans"
uk_mobil[uk_mobil$sub_region_2 == "Saint Helens" & !is.na(uk_mobil$sub_region_2),]$sub_region_2 <- "St. Helens"
uk_mobil[uk_mobil$sub_region_2 == "City of Westminster" & !is.na(uk_mobil$sub_region_2),]$sub_region_2 <- "Westminster"
uk_mobil[uk_mobil$sub_region_2 == "City of Winchester" & !is.na(uk_mobil$sub_region_2),]$sub_region_2 <- "Winchester"
uk_mobil[uk_mobil$sub_region_2 == "City of Wolverhampton" & !is.na(uk_mobil$sub_region_2),]$sub_region_2 <- "Wolverhampton"
uk_mobil[uk_mobil$sub_region_2 == "Folkestone & Hythe" & !is.na(uk_mobil$sub_region_2),]$sub_region_2 <- "Folkestone and Hythe"

# now we'll split the sub region 1 and 2 data and rebind into a single named column
# need to get rid of multiple instances of sub regions 1 (where sub region 2 is inside sub region 1) for later

uk_mobility_regions_1 <- uk_mobil[!is.na(uk_mobil$sub_region_1) & uk_mobil$sub_region_1 != "" &
                                    uk_mobil$sub_region_2 == "",]
uk_mobility_regions_2 <- uk_mobil[!is.na(uk_mobil$sub_region_2) & uk_mobil$sub_region_2 != "",]

uk_mobility_regions_1$ltla_name <- uk_mobility_regions_1$sub_region_1
uk_mobility_regions_2$ltla_name <- uk_mobility_regions_2$sub_region_2

# get East Suffolk by combining Suffolk Coastal and Waveney
suff_coast <- uk_mobility_regions_2[uk_mobility_regions_2$ltla_name == "Suffolk Coastal",]
waveney <- uk_mobility_regions_2[uk_mobility_regions_2$ltla_name == "Waveney",]

# we'll just copy suffolk coast then write over the bits we want to
east_suff <- suff_coast
east_suff$ltla_name <- "East Suffolk"
east_suff$retail_and_recreation_percent_change_from_baseline <- mapply(function(x, y) mean(c(x, y), na.rm = TRUE), 
                                                                       x = suff_coast$retail_and_recreation_percent_change_from_baseline,
                                                                       y = waveney$retail_and_recreation_percent_change_from_baseline)
east_suff$grocery_and_pharmacy_percent_change_from_baseline <- mapply(function(x, y) mean(c(x, y), na.rm = TRUE), 
                                                                       x = suff_coast$grocery_and_pharmacy_percent_change_from_baseline,
                                                                       y = waveney$grocery_and_pharmacy_percent_change_from_baseline)
east_suff$parks_percent_change_from_baseline <- mapply(function(x, y) mean(c(x, y), na.rm = TRUE), 
                                                                       x = suff_coast$parks_percent_change_from_baseline,
                                                                       y = waveney$parks_percent_change_from_baseline)
east_suff$transit_stations_percent_change_from_baseline <- mapply(function(x, y) mean(c(x, y), na.rm = TRUE), 
                                                                       x = suff_coast$transit_stations_percent_change_from_baseline,
                                                                       y = waveney$transit_stations_percent_change_from_baseline)
east_suff$workplaces_percent_change_from_baseline <- mapply(function(x, y) mean(c(x, y), na.rm = TRUE), 
                                                                       x = suff_coast$workplaces_percent_change_from_baseline,
                                                                       y = waveney$workplaces_percent_change_from_baseline)
east_suff$residential_percent_change_from_baseline <- mapply(function(x, y) mean(c(x, y), na.rm = TRUE), 
                                                                       x = suff_coast$residential_percent_change_from_baseline,
                                                                       y = waveney$residential_percent_change_from_baseline)

# get Somerset West and Taunton by combining Taunton Deane and West Somerset
taunton_deane <- uk_mobility_regions_2[uk_mobility_regions_2$ltla_name == "Taunton Deane",]
west_somerset <- uk_mobility_regions_2[uk_mobility_regions_2$ltla_name == "West Somerset",]
taunton_deane <- taunton_deane[taunton_deane$date %in% west_somerset$date,] # match the rows

# we'll just copy one then write over the bits we want to again
somerset_west <- west_somerset
somerset_west$ltla_name <- "Somerset West and Taunton"
somerset_west$retail_and_recreation_percent_change_from_baseline <- mapply(function(x, y) mean(c(x, y), na.rm = TRUE), 
                                                                       x = west_somerset$retail_and_recreation_percent_change_from_baseline,
                                                                       y = taunton_deane$retail_and_recreation_percent_change_from_baseline)
somerset_west$grocery_and_pharmacy_percent_change_from_baseline <- mapply(function(x, y) mean(c(x, y), na.rm = TRUE), 
                                                                      x = west_somerset$grocery_and_pharmacy_percent_change_from_baseline,
                                                                      y = taunton_deane$grocery_and_pharmacy_percent_change_from_baseline)
somerset_west$parks_percent_change_from_baseline <- mapply(function(x, y) mean(c(x, y), na.rm = TRUE), 
                                                       x = west_somerset$parks_percent_change_from_baseline,
                                                       y = taunton_deane$parks_percent_change_from_baseline)
somerset_west$transit_stations_percent_change_from_baseline <- mapply(function(x, y) mean(c(x, y), na.rm = TRUE), 
                                                                  x = west_somerset$transit_stations_percent_change_from_baseline,
                                                                  y = taunton_deane$transit_stations_percent_change_from_baseline)
somerset_west$workplaces_percent_change_from_baseline <- mapply(function(x, y) mean(c(x, y), na.rm = TRUE), 
                                                            x = west_somerset$workplaces_percent_change_from_baseline,
                                                            y = taunton_deane$workplaces_percent_change_from_baseline)
somerset_west$residential_percent_change_from_baseline <- mapply(function(x, y) mean(c(x, y), na.rm = TRUE), 
                                                             x = west_somerset$residential_percent_change_from_baseline,
                                                             y = taunton_deane$residential_percent_change_from_baseline)

uk_mobility_regions_2 <- uk_mobility_regions_2[!uk_mobility_regions_2$ltla_name %in% c("Suffolk Coastal", "Waveney",
                                                                                        "West Somerset", "Taunton Deane",
                                                                                       "Dorset"),]

uk_mobility_data <- rbind(uk_mobility_regions_1, uk_mobility_regions_2, east_suff, somerset_west)

# finally, find any missing values, and replace them with the average mobility across the whole UK as an approximation
uk_average <- uk_mobil[uk_mobil$sub_region_1 == "" & uk_mobil$sub_region_2 == "" &
                         !is.na(uk_mobil$country_region),]

regions <- unique(as.character(uk_mobility_data$ltla_name))
for(i in 1:length(regions)){
  regional_data <- uk_mobility_data[uk_mobility_data$ltla_name == regions[i],]
  dates <- unique(regional_data$date)
  for(k in 1:length(dates)){
    if(is.na(uk_mobility_data[uk_mobility_data$ltla_name == regions[i] &
                              uk_mobility_data$date == dates[k],]$retail_and_recreation_percent_change_from_baseline)){
      uk_mobility_data[uk_mobility_data$ltla_name == regions[i] &
                         uk_mobility_data$date == dates[k],]$retail_and_recreation_percent_change_from_baseline <-
        uk_average[uk_average$date == dates[k],]$retail_and_recreation_percent_change_from_baseline
    }
    if(is.na(uk_mobility_data[uk_mobility_data$ltla_name == regions[i] &
                              uk_mobility_data$date == dates[k],]$grocery_and_pharmacy_percent_change_from_baseline)){
      uk_mobility_data[uk_mobility_data$ltla_name == regions[i] &
                         uk_mobility_data$date == dates[k],]$grocery_and_pharmacy_percent_change_from_baseline <-
        uk_average[uk_average$date == dates[k],]$grocery_and_pharmacy_percent_change_from_baseline
    }
    if(is.na(uk_mobility_data[uk_mobility_data$ltla_name == regions[i] &
                              uk_mobility_data$date == dates[k],]$parks_percent_change_from_baseline)){
      uk_mobility_data[uk_mobility_data$ltla_name == regions[i] &
                         uk_mobility_data$date == dates[k],]$parks_percent_change_from_baseline <-
        uk_average[uk_average$date == dates[k],]$parks_percent_change_from_baseline
    }
    if(is.na(uk_mobility_data[uk_mobility_data$ltla_name == regions[i] &
                              uk_mobility_data$date == dates[k],]$transit_stations_percent_change_from_baseline)){
      uk_mobility_data[uk_mobility_data$ltla_name == regions[i] &
                         uk_mobility_data$date == dates[k],]$transit_stations_percent_change_from_baseline <-
        uk_average[uk_average$date == dates[k],]$transit_stations_percent_change_from_baseline
    }
    if(is.na(uk_mobility_data[uk_mobility_data$ltla_name == regions[i] &
                              uk_mobility_data$date == dates[k],]$workplaces_percent_change_from_baseline)){
      uk_mobility_data[uk_mobility_data$ltla_name == regions[i] &
                         uk_mobility_data$date == dates[k],]$workplaces_percent_change_from_baseline <-
        uk_average[uk_average$date == dates[k],]$workplaces_percent_change_from_baseline
    }
    if(is.na(uk_mobility_data[uk_mobility_data$ltla_name == regions[i] &
                              uk_mobility_data$date == dates[k],]$residential_percent_change_from_baseline)){
      uk_mobility_data[uk_mobility_data$ltla_name == regions[i] &
                         uk_mobility_data$date == dates[k],]$residential_percent_change_from_baseline <-
        uk_average[uk_average$date == dates[k],]$residential_percent_change_from_baseline
    }
  }
}

# write this out as its own file
write.csv(uk_mobility_data, "raw-data/uk-ltla-mobility.csv", row.names = FALSE)
