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
    start_near_mrt = start_station %in% mrt_bike_station_map$sna
  )

mrt_sub_Youbike_all <- Youbike_all %>%
  filter(
    (start_near_mrt)  & (start_station != end_station)
  )

#配對youbike到捷運站
nearest_mrt_idx <- st_nearest_feature(bike_sf, mrt_sf)
bike_mrt_map <- bike_sf %>%
  mutate(
    nearest_mrt_exit = mrt_sf$出入口名稱[nearest_mrt_idx],
    sna = gsub("YouBike2.0_", "", sna),
    mrt_station = str_extract(nearest_mrt_exit, ".*?站")
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
# =========================

# 建立 YouBike ↔ 氣象站對照表

# rain / temperature / humidity 分開配對

# =========================

# 讀取氣象站清單

weather_sta <- read.csv(
  "Data/weather_sta_list_2025-06-09.csv",
  fileEncoding = "UTF-8"
)

weather_north <- weather_sta %>%
  
  filter(
    
    城市 %in% c("臺北市", "新北市"),
    
    !is.na(經度),
    
    !is.na(緯度),
    
    撤站日期 == ""
    
  )

weather_sf <- st_as_sf(
  
  weather_north,
  
  coords = c("經度", "緯度"),
  
  crs = 4326
  
) %>%
  
  st_transform(3826)

# 讀入已整理好的 weather panel

rain_panel <- readRDS("Output/rain_panel.rds")

temp_panel <- readRDS("Output/temp_panel.rds")

humidity_panel <- readRDS("Output/RelativeHunidity.rds")

# 1. rain 最近測站

rain_station_ids <- unique(rain_panel$weather_station_id)

weather_rain_sf <- weather_sf %>%
  
  filter(站號 %in% rain_station_ids)

nearest_rain_idx <- st_nearest_feature(
  
  bike_sf,
  
  weather_rain_sf
  
)

bike_sf$nearest_rain_station <- weather_rain_sf$站名[nearest_rain_idx]

bike_sf$nearest_rain_id <- weather_rain_sf$站號[nearest_rain_idx]

# 2. temperature 最近測站

temp_station_ids <- unique(temp_panel$weather_station_id)

weather_temp_sf <- weather_sf %>%
  
  filter(站號 %in% temp_station_ids)

nearest_temp_idx <- st_nearest_feature(
  
  bike_sf,
  
  weather_temp_sf
  
)

bike_sf$nearest_temp_station <- weather_temp_sf$站名[nearest_temp_idx]

bike_sf$nearest_temp_id <- weather_temp_sf$站號[nearest_temp_idx]

# 3. humidity 最近測站

humidity_station_ids <- unique(humidity_panel$weather_station_id)

weather_humidity_sf <- weather_sf %>%
  
  filter(站號 %in% humidity_station_ids)

nearest_humidity_idx <- st_nearest_feature(
  
  bike_sf,
  
  weather_humidity_sf
  
)

bike_sf$nearest_humidity_station <- weather_humidity_sf$站名[nearest_humidity_idx]

bike_sf$nearest_humidity_id <- weather_humidity_sf$站號[nearest_humidity_idx]

# 建立 YouBike station ↔ weather station 對照表

bike_weather_map <- bike_sf %>%
  st_drop_geometry() %>%
  mutate(
    sna = gsub("YouBike2.0_", "", sna)
  ) %>%
  select(
    sno,
    sna,
    sarea,
    nearest_rain_station,
    nearest_rain_id,
    nearest_temp_station,
    nearest_temp_id,
    nearest_humidity_station,
    nearest_humidity_id
  )

mrt_sub_Youbike_all <- mrt_sub_Youbike_all %>%
  left_join(
    bike_weather_map %>%
      select(
        sna,
        nearest_rain_station,
        nearest_rain_id,
        nearest_temp_station,
        nearest_temp_id,
        nearest_humidity_station,
        nearest_humidity_id
      ),
    by = c(
      "start_station" = "sna"
    )
  )

mrt_hourly <- mrt_sub_Youbike_all %>%
  filter(
    hour %in% c(6:23)
  ) %>%
  mutate(weekday = weekdays(date), weekend = ifelse(weekday %in% c("Saturday", "Sunday"), 1, 0)
  ) %>% 
  group_by(
    mrt_station,
    date,
    hour
  ) %>%
  summarise(
    trip_count = n(),
    weekday = first(weekday),
    weekend = first(weekend),
    nearest_rain_station = first(nearest_rain_station),
    nearest_rain_id = first(nearest_rain_id),
    nearest_temp_station = first(nearest_temp_station),
    nearest_temp_id = first(nearest_temp_id),
    nearest_humidity_station = first(nearest_humidity_station),
    nearest_humidity_id = first(nearest_humidity_id),
    .groups = "drop"
  )

mrt_weather <- mrt_hourly %>%
  left_join(
    rain_panel,
    by = c("nearest_rain_id" = "weather_station_id", "date", "hour"))

# merge temperature

mrt_weather <- mrt_weather %>%
  left_join(
    temp_panel,
    by = c(
      "nearest_temp_id" =
        "weather_station_id",
      "date",
      "hour"
    )
 
  )

# merge humidity

mrt_weather <- mrt_weather %>%
  left_join(
    humidity_panel, 
    by = c(
      "nearest_humidity_id" =
        "weather_station_id",
      "date",
      "hour"
    )
  )

mrt_weather_clean <- mrt_weather %>% drop_na()
saveRDS(mrt_weather_clean, "Output/mrt_weather_clean.rds")
