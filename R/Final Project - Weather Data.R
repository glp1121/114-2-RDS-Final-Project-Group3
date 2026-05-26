library(jsonlite)
library(dplyr)
library(sf)
library(stringr)
library(tidyr)
library(lubridate)

#讀天氣資料
temp_files <- list.files(
  "Data/weather/temp",
  pattern = "AirTemperature-hour.csv",
  full.names = TRUE
)

read_temp_file <- function(file_path) {
  temp_raw <- read.csv(file_path)
  file_name <- basename(file_path)
  file_parts <- str_split(
    file_name,
    "-",
    simplify = TRUE
  )
  station_id <- file_parts[1]
  year_month <- paste0(
    file_parts[2],
    "-",
    file_parts[3]
  )
  message(
    "reading: ", file_name,
    " | station_id = ", station_id,
    " | year_month = ", year_month
  )
  temp_long <- temp_raw %>%
    mutate(
      across(
        starts_with("X"),
        as.character
      ),
      日.時 = as.character(日.時),
      day = str_extract(日.時, "\\d+"),
      day = as.numeric(day)
    ) %>%
    filter(
      !is.na(day),
      day >= 1,
      day <= 31
    ) %>%
    pivot_longer(
      cols = starts_with("X"),
      names_to = "hour",
      values_to = "temperature"
    ) %>%
    mutate(
      hour = as.numeric(
        gsub("X", "", hour)
      ),
      date_str = paste0(
        year_month,
        "-",
        sprintf("%02d", day)
      ),
      date = suppressWarnings(
        ymd(date_str)
      ),
      temperature = str_trim(temperature),
      temperature = case_when(
        temperature %in% c(
          "&",
          "X",
          "/",
          "-",
          "",
          "NA"
        ) ~ NA_character_,
        temperature == "T" ~ "0",
        TRUE ~ temperature
      ),
      temperature = as.numeric(temperature),
      weather_station_id = station_id
    ) %>%
    filter(!is.na(date)) %>%
    select(
      weather_station_id,
      date,
      hour,
      temperature
    )
  return(temp_long)
}

library(purrr)
temp_panel <- temp_files %>%
  map_dfr(read_temp_file)
saveRDS(temp_panel, "Output/temp_panel.rds")

#讀雨量資料
rain_files <- list.files(
  "Data/weather/rain",
  pattern = "Precipitation-hour.csv",
  full.names = TRUE
)

read_rain_file <- function(file_path) {
  rain_raw <- read.csv(file_path)
  file_name <- basename(file_path)
  file_parts <- str_split(
    file_name,
    "-",
    simplify = TRUE
  )
  station_id <- file_parts[1]
  year_month <- paste0(
    file_parts[2],
    "-",
    file_parts[3]
  )
  message(
    "reading: ", file_name,
    " | station_id = ", station_id,
    " | year_month = ", year_month
  )
  rain_long <- rain_raw %>%
    mutate(
      across(
        starts_with("X"),
        as.character
      ),
      日.時 = as.character(日.時),
      day = str_extract(日.時, "\\d+"),
      day = as.numeric(day)
    ) %>%
    filter(
      !is.na(day),
      day >= 1,
      day <= 31
    ) %>%
    pivot_longer(
      cols = starts_with("X"),
      names_to = "hour",
      values_to = "rain"
    ) %>%
    mutate(
      hour = as.numeric(
        gsub("X", "", hour)
      ),
      date_str = paste0(
        year_month,
        "-",
        sprintf("%02d", day)
      ),
      date = suppressWarnings(
        ymd(date_str)
      ),
      rain = str_trim(rain),
      rain = case_when(
        rain %in% c(
          "&",
          "X",
          "/",
          "-",
          "",
          "NA"
        ) ~ NA_character_,
        
        rain == "T" ~ "0",
        
        TRUE ~ rain
      ),
      
      rain = as.numeric(rain),
      
      weather_station_id = station_id
    ) %>%
    
    # 去掉日期
    filter(!is.na(date)) %>%
    
    select(
      weather_station_id,
      date,
      hour,
      rain
    )
  
  return(rain_long)
}

library(purrr)

rain_panel <- rain_files %>%
  map_dfr(read_rain_file)
saveRDS(rain_panel, "Output/rain_panel.rds")

#讀濕度資料
humidity_files <- list.files(
  "Data/weather/humidity",
  pattern = "RelativeHumidity-hour",
  full.names = TRUE
)

read_humidity_file <- function(file_path) {
  
  humidity_raw <- read.csv(file_path)
  
  file_name <- basename(file_path)
  
  file_parts <- str_split(
    file_name,
    "-",
    simplify = TRUE
  )
  
  station_id <- file_parts[1]
  
  year_month <- paste0(
    file_parts[2],
    "-",
    file_parts[3]
  )
  
  message(
    "reading: ", file_name,
    " | station_id = ", station_id,
    " | year_month = ", year_month
  )
  
  humidity_long <- humidity_raw %>%
    
    mutate(
      
      across(
        starts_with("X"),
        as.character
      ),
      
      日.時 = as.character(日.時),
      
      day = str_extract(日.時, "\\d+"),
      
      day = as.numeric(day)
      
    ) %>%
    
    filter(
      !is.na(day),
      day >= 1,
      day <= 31
    ) %>%
    
    pivot_longer(
      cols = starts_with("X"),
      names_to = "hour",
      values_to = "humidity"
    ) %>%
    
    mutate(
      
      hour = as.numeric(
        gsub("X", "", hour)
      ),
      
      date_str = paste0(
        year_month,
        "-",
        sprintf("%02d", day)
      ),
      
      date = suppressWarnings(
        ymd(date_str)
      ),
      
      humidity = str_trim(humidity),
      
      humidity = case_when(
        
        humidity %in% c(
          "&",
          "X",
          "/",
          "-",
          "",
          "NA",
          "..."
        ) ~ NA_character_,
        
        TRUE ~ humidity
        
      ),
      
      humidity = as.numeric(humidity),
      
      weather_station_id = station_id
      
    ) %>%
    
    filter(!is.na(date)) %>%
    
    select(
      weather_station_id,
      date,
      hour,
      humidity
    )
  
  return(humidity_long)
}

humidity_panel <- humidity_files %>%
  map_dfr(read_humidity_file)
saveRDS(rain_panel, "Output/RelativeHunidity.rds")
