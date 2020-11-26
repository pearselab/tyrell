# Collect deaths/cases from the UK using their new fancy API
# need to do this using paginated code, otherwise results get
# limited to a certain number of lines.
source("src/packages.R")


#' Extracts paginated data by requesting all of the pages
#' and combining the results.
#'
#' @param filters    API filters. See the API documentations for 
#'                   additional information.
#'                   
#' @param structure  Structure parameter. See the API documentations 
#'                   for additional information.
#'                   
#' @return list      Comprehensive list of dictionaries containing all 
#'                   the data for the given ``filter`` and ``structure`.`
get_paginated_data <- function (filters, structure) {
  
  endpoint     <- "https://api.coronavirus.data.gov.uk/v1/data"
  results      <- list()
  current_page <- 1
  
  repeat {
    
    httr::GET(
      url   = endpoint,
      query = list(
        filters   = paste(filters, collapse = ";"),
        structure = jsonlite::toJSON(structure, auto_unbox = TRUE),
        page      = current_page
      ),
      timeout(10)
    ) -> response
    
    # Handle errors:
    if ( response$status_code >= 400 ) {
      err_msg = httr::http_status(response)
      stop(err_msg)
    } else if ( response$status_code == 204 ) {
      break
    }
    
    # Convert response from binary to JSON:
    json_text <- content(response, "text")
    dt        <- jsonlite::fromJSON(json_text)
    results   <- rbind(results, dt$data)
    
    if ( is.null( dt$pagination$`next` ) ){
      break
    }
    
    current_page <- current_page + 1;
    
  }
  
  return(results)
  
}


# make calls to the function to grab different datasets
# nations - england/scotland/wales/n.ireland
nation_data <- get_paginated_data(filters = "areaType=nation", 
                                  structure = list(Date       = "date", 
                                                   Name       = "areaName", 
                                                   Code       = "areaCode", 
                                                   DailyCases      = "newCasesBySpecimenDate",
                                                   CumulativeCases = "cumCasesBySpecimenDate",
                                                   DailyDeaths = "newDeaths28DaysByDeathDate",
                                                   CumulativeDeaths = "cumDeaths28DaysByDeathDate"))

# regions - these are the 9 english NUTS regions
region_data <- get_paginated_data(filters = "areaType=region", 
                                  structure = list(Date       = "date", 
                                                   Name       = "areaName", 
                                                   Code       = "areaCode", 
                                                   DailyCases      = "newCasesBySpecimenDate",
                                                   CumulativeCases = "cumCasesBySpecimenDate",
                                                   DailyDeaths = "newDeaths28DaysByDeathDate",
                                                   CumulativeDeaths = "cumDeaths28DaysByDeathDate"))

# upper tier local authorities
utla_data <- get_paginated_data(filters = "areaType=utla", 
                                  structure = list(Date       = "date", 
                                                   Name       = "areaName", 
                                                   Code       = "areaCode", 
                                                   DailyCases      = "newCasesByPublishDate",
                                                   CumulativeCases = "cumCasesByPublishDate",
                                                   DailyDeaths = "newDeaths28DaysByDeathDate",
                                                   CumulativeDeaths = "cumDeaths28DaysByDeathDate"))

# lower tier local authorities
county_data <- get_paginated_data(filters = "areaType=ltla", 
                                  structure = list(Date       = "date", 
                                                   Name       = "areaName", 
                                                   Code       = "areaCode", 
                                                   DailyCases      = "newCasesByPublishDate",
                                                   CumulativeCases = "cumCasesByPublishDate",
                                                   DailyDeaths = "newDeaths28DaysByDeathDate",
                                                   CumulativeDeaths = "cumDeaths28DaysByDeathDate"))

# bind region and nation data together
region_dataset <- rbind(nation_data, region_data)

# add population data
population_data <- read.xls("raw-data/UK-population.xls", sheet = 6, pattern = "Code")
names(population_data)[names(population_data) == "All.ages"] <- "Population"

region_dataset <- join(region_dataset, population_data[,c("Code", "Population")], by = "Code")

merge_pop_data <- function(dataset){
  merged_data <- join(dataset, population_data[,c("Code", "Population")], by = "Code")
  merged_data$Population <- as.numeric(gsub(",", "", merged_data$Population))
  return(merged_data)
}

region_dataset <- merge_pop_data(region_dataset)
utla_data <- merge_pop_data(utla_data)
county_data <- merge_pop_data(county_data)

# write out the datasets
write.csv(region_dataset, "raw-data/cases/uk-regional.csv", row.names = FALSE)
write.csv(utla_data, "raw-data/cases/uk-utla.csv", row.names = FALSE)
write.csv(county_data, "raw-data/cases/uk-ltla.csv", row.names = FALSE)
