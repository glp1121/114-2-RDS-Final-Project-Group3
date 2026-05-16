library(jsonlite)
library(dplyr)
library(sf)
library(stringr)
library(tidyr)
library(lubridate)
## cleaning pipeline
#1. 讀資料
#2. 建立 YouBike ↔ MRT 對照表
#3. 建立 YouBike ↔ 氣象站對照表
#4. 讀 6–9 月騎乘資料
#5. 篩 MRT-substitution trips
#6. aggregate 成 MRT × date × hour
#7. 讀天氣資料
#8. merge 天氣
#9. 輸出 final data

#捷運出入口資料
mrt <- read.csv("Data/MRT.csv", fileEncoding = "Big5") 

#Youbike站點資料
url <- "https://tcgbusfs.blob.core.windows.net/dotapp/youbike/v2/youbike_immediate.json"
bike <- fromJSON(url)
bike_station <- bike %>% select(sno, sna, sarea, latitude, longitude) 
head(bike_station)
bike_sf <- st_as_sf(
  bike_station,
  coords = c("longitude", "latitude"),
  crs = 4326
)
bike_sf <- st_transform(bike_sf, 3826)

#配對200公尺內有Youbike站的捷運站
mrt_sf <- st_as_sf(mrt, coords = c("經度", "緯度"), crs = 4326) #WGS84 全球經緯度系統
mrt_sf <- st_transform(mrt_sf, 3826) #轉成：「台灣的公尺座標系」TM2
mrt_buffer <- st_buffer(mrt_sf, dist = 200)
nearby <- st_join(bike_sf, mrt_buffer, join = st_within)
mrt_bike_station <- nearby %>% 
  filter(!is.na(出入口名稱)) %>% distinct(sna) #選定在捷運站入口附近兩百公尺的站點
#mrt_bike_station <- mrt_bike_station %>%
#  mutate(
#    sna = gsub("YouBike2.0_", "", sna)
#  )


#將youbike站配對到最近捷運站
mrt_bike_station_map <- nearby %>%
  filter(!is.na(出入口名稱)) %>%
  st_drop_geometry() %>%
  mutate(
    sna = gsub("YouBike2.0_", "", sna),
    mrt_station = str_extract(出入口名稱, ".*?站")
  ) %>%
  select(
    sna,
    mrt_station,
    出入口名稱
  ) %>%
  distinct()

#騎乘資料
trip_files <- list.files(
  "Data/票證資料",
  pattern = "YouBike2.0票證刷卡資料.csv",
  full.names = TRUE
)

read_youbike_trip <- function(file_path) {
  trip <- read.csv(
    file_path,
    header = FALSE
  )
  names(trip) <- c(
    "start_time",
    "start_station",
    "end_time",
    "end_station",
    "duration",
    "bike_type",
    "date"
  )
  trip <- trip %>%
    mutate(
      start_station = trimws(start_station),
      end_station = trimws(end_station),
      start_time = ymd_hms(start_time),
      date = as.Date(start_time),
      hour = hour(start_time)
    )
  return(trip)
}

Youbike_all <- trip_files %>%
  lapply(read_youbike_trip) %>%
  bind_rows()

Youbike_all <- Youbike_all %>%
  mutate(
    start_station = trimws(start_station),
    end_station = trimws(end_station)
  ) #讓站名字串統一

#篩選出符合騎乘起站以及終站都在捷運站附近的站點
Youbike_all <- Youbike_all %>%
  mutate(
    start_near_mrt =
      start_station %in% mrt_bike_station_map$sna,
    end_near_mrt =
      end_station %in% mrt_bike_station_map$sna
  )

mrt_sub_Youbike_all <- Youbike_all %>%
  filter(
    start_near_mrt &
      end_near_mrt &
      start_station != end_station
  )

#配對youbike到捷運站
nearest_mrt_idx <- st_nearest_feature(bike_sf, mrt_sf)
bike_mrt_map <- bike_sf %>%
  mutate(
    nearest_mrt_exit = mrt_sf$出入口名稱[nearest_mrt_idx],
    sna = gsub("YouBike2.0_", "", sna),
    mrt_station = stringr::str_extract(nearest_mrt_exit, ".*?站")
  ) %>%
  st_drop_geometry() %>%
  select(sna, mrt_station, nearest_mrt_exit) %>%
  distinct(sna, .keep_all = TRUE)

mrt_sub_Youbike_all <- mrt_sub_Youbike_all %>%
  left_join(
    bike_mrt_map %>% select(sna, mrt_station),
    by = c("start_station" = "sna")
  )

# 3. 讀取氣象站清單
weather_sta <- read.csv(
  "Data/weather_sta_list_2025-06-09.csv",
  fileEncoding = "UTF-8"
)

# 4. 篩出新北台北氣象站

weather_north <- weather_sta %>%
  filter(
    城市 %in% c("臺北市", "新北市"),
    !is.na(經度),
    !is.na(緯度),
    撤站日期 == ""
  )
  
# 5. 轉成 sf 空間資料
weather_sf <- st_as_sf(
  weather_north,
  coords = c("經度", "緯度"),
  crs = 4326
)
weather_sf <- st_transform(weather_sf, 3826)

# 6. 找每個 YouBike 站最近的氣象站
nearest_idx <- st_nearest_feature(
  bike_sf,
  weather_sf
)

# 7. 把最近氣象站資訊加回 YouBike 資料
bike_sf$nearest_weather_station <- weather_sf$站名[nearest_idx]
bike_sf$nearest_weather_id <- weather_sf$站號[nearest_idx]
bike_sf$nearest_weather_type <- weather_sf$站種[nearest_idx]

# 8. 計算距離（公尺）
bike_sf$distance_to_weather_m <- as.numeric(
  st_distance(
    bike_sf,
    weather_sf[nearest_idx, ],
    by_element = TRUE
  )
)

# 9. 轉回一般 dataframe
bike_weather_map <- bike_sf %>%
  st_drop_geometry() %>%
  select(
    sno,
    sna,
    sarea,
    nearest_weather_station,
    nearest_weather_id,
    nearest_weather_type,
    distance_to_weather_m
  )


# 看每個氣象站被分配到多少 YouBike 站 決定要下載哪些資料
bike_weather_map %>% count(nearest_weather_station, sort = TRUE)

bike_weather_map <- bike_weather_map %>%
  mutate(
    sna = gsub("YouBike2.0_", "", sna)
  )

mrt_sub_Youbike_all <- mrt_sub_Youbike_all %>%
  left_join(
    bike_weather_map %>%
      select(
        sna,
        nearest_weather_station,
        nearest_weather_id
      ),
    by = c("start_station" = "sna")
  )


# mrt_sub_Youbike_all <- mrt_sub_Youbike_all %>%
#   mutate(
#     start_time = ymd_hms(start_time),
#     date = as.Date(start_time),
#     hour = hour(start_time)
#   )

mrt_hourly <- mrt_sub_Youbike_all %>%
  filter(hour %in% c(0, 1, 6:23)) %>% 
  group_by(
    mrt_station,
    date,
    hour
  ) %>%
  summarise(
    trip_count = n(),
    nearest_weather_station =
      first(nearest_weather_station),
    .groups = "drop"
  )

rain_files <- list.files(
  "Data/weather",
  pattern = "Precipitation-hour.csv",
  full.names = TRUE
)

read_rain_file <- function(file_path) {
  
  library(dplyr)
  library(tidyr)
  library(stringr)
  library(lubridate)
  
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
      
      # 先建立字串
      date_str = paste0(
        year_month,
        "-",
        sprintf("%02d", day)
      ),
      
      # 安全轉日期
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
    
    # 去掉非法日期
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

# =========================
# 6. Aggregate to MRT-hour panel
# =========================

mrt_hourly <- mrt_sub_Youbike_all %>%
  group_by(
    mrt_station,
    date,
    hour
  ) %>%
  summarise(
    trip_count = n(),
    nearest_weather_station = first(nearest_weather_station),
    nearest_weather_id = first(nearest_weather_id),
    .groups = "drop"
  )


# =========================
# 7. Merge hourly rainfall data
# =========================

mrt_weather <- mrt_hourly %>%
  filter(
    nearest_weather_id != "G2AI50"
  ) %>%
  left_join(
    rain_panel,
    by = c(
      "nearest_weather_id" = "weather_station_id",
      "date",
      "hour"
    )
  )


# =========================
# 8. Clean analysis sample
# =========================

mrt_weather_clean <- mrt_weather %>%
  
  filter(
    hour %in% 6:23
  ) %>%
  
  mutate(
    
    rain =
      ifelse(
        is.na(rain),
        0,
        rain
      ),
    
    rain_dummy =
      ifelse(
        rain > 0,
        1,
        0
      ),
    
    weekday =
      weekdays(date),
    
    weekend =
      ifelse(
        weekday %in%
          c("Saturday", "Sunday"),
        1,
        0
      )
    
  ) %>%
  
  select(
    mrt_station,
    date,
    hour,
    trip_count,
    nearest_weather_station,
    nearest_weather_id,
    rain,
    rain_dummy,
    weekday,
    weekend
  )
