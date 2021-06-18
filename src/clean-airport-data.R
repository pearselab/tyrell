# clean airport xls data

source("src/packages.R")

# get list of airports and states that we're working with
airport_codes <- c("ABQ","ANC","ATL","AUS","BDL","BHM","BNA","BOS","BUF","BUR",
                   "BWI","CLE","CLT","CVG","DAL","DAY","DCA","DEN","DFW","DTW",
                   "EWR","FLL","GYY","HNL","HOU","HPN","IAD","IAH","IND","ISP",
                   "JAX","JFK","LAS","LAX","LGA","LGB","MCI","MCO","MDW","MEM",
                   "MHT","MIA","MKE","MSP","MSY","OAK","OGG","OMA","ONT","ORD",
                   "OXR","PBI","PDX","PHL","PHX","PIT","PSP","PVD","RDU","RFD",
                   "RSW","SAN","SAT","SDF","SEA","SFO","SJC","SJU","SLC","SMF",
                   "SNA","STL","SWF","TEB","TPA","TUS")

airport_states <-  c("NM","AK","GA","TX","CT","AL","TN","MA","NY","CA",
                     "MD","OH","NC","OH","TX","OH","DC","CO","TX","MI",
                     "NJ","FL","IN","HI","TX","NY","DC","TX","IN","NY",
                     "FL","NY","NV","CA","NY","CA","MO","FL","IL","TN",
                     "NH","FL","WI","MN","LA","CA","HI","NE","CA","IL",
                     "CA","FL","OR","PA","AZ","PA","CA","RI","NC","IL",
                     "FL","CA","TX","KY","WA","CA","CA","PR","CA","CA",
                     "CA","MO","NY","NJ","FL","AZ")

airports <- data.frame(airport_codes, airport_states)

# get the data for scheduled flights from the ASPM 77 airports
# these are basically the US airports with the greatest amount of traffic
# https://aspm.faa.gov/apm/sys/AnalysisAP.asp
# Output: analysis: - all flights; ms excel, no sub-totals
# Dates: range: 01 Feb --> 01 May
# Airports: click "ASPM 77" to fill all
# Grouping: select airport, date
# Select filters: use schedule
# Run
# put the resulting xls file into ext-data

# check if the file exists
f <- "ext-data/APM-Report.xls"
if (file.exists(f)){
  
  airport_data <- read.xls(f)
  
  # remove unnecessary rows, and rename columns
  airport_data <- airport_data[-(1:6),1:4]
  
  names(airport_data) <- c("Facility", "Date", "Scheduled_Departures", "Scheduled_Arrivals")
  
  # get rid of silly lines at the end
  airport_data <- airport_data[airport_data$Facility %in% airport_codes,]
  
  airport_data$Date <- as.Date(as.character(airport_data$Date), format = "%m/%d/%y")
  airport_data$Scheduled_Arrivals <- as.numeric(as.character(airport_data$Scheduled_Arrivals))
  airport_data$Facility <- as.character(airport_data$Facility)
  
  # png("figures/airport-arrivals.png", width = 1000, height = 1000)
  # ggplot(airport_data, aes(x = as.Date(Date), y = Scheduled_Arrivals)) + geom_line() + facet_wrap(~Facility) + theme_bw()
  # dev.off()
  
  # ok, what we need to do is match these up to states
  airport_data_states <- merge(x = airport_data, y = airports, by.x = "Facility", by.y = "airport_codes")
  names(airport_data_states)[5] <- "State"
  
  write.csv(airport_data_states, "clean-data/airport_data.csv", row.names = FALSE)
} else {
  out_string <- "Airport data file not found, follow rake instructions to download it"
  print(out_string)
  write.csv(out_string, "clean-data/airport_data.csv", row.names = FALSE)
}