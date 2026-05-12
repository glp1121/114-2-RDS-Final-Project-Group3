library(jsonlite)
library(dplyr)
library(sf)

mrt <- read.csv("MRT.csv", fileEncoding = "Big5")
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

mrt_sf <- st_as_sf(mrt, coords = c("經度", "緯度"), crs = 4326) #WGS84 全球經緯度系統
mrt_sf <- st_transform(mrt_sf, 3826) #轉成：「台灣的公尺座標系」TM2
mrt_buffer <- st_buffer(mrt_sf, dist = 200)
nearby <- st_join(bike_sf, mrt_buffer, join = st_within)

Youbike_6 <- read.csv("202506_YouBike2.0票證刷卡資料.csv", header = FALSE)
names(Youbike_6) <- c(
  "start_time",
  "start_station",
  "end_time",
  "end_station",
  "duration",
  "bike_type",
  "date"
) #讀資料

mrt_bike_station <- nearby %>% 
  filter(!is.na(出入口名稱)) %>% distinct(sna) #選定在捷運站入口附近兩百公尺的站點

mrt_bike_station <- mrt_bike_station %>%
  mutate(
    sna = gsub("YouBike2.0_", "", sna)
  ) 
Youbike_6 <- Youbike_6 %>%
  mutate(
    start_station = trimws(start_station),
    end_station = trimws(end_station)
  )
#讓站名字串統一

Youbike_6 <- Youbike_6 %>%
  mutate(
    start_near_mrt =
      start_station %in% mrt_bike_station$sna,
    end_near_mrt =
      end_station %in% mrt_bike_station$sna
  )

mrt_sub_Youbike_6 <- Youbike_6 %>%
  filter(
    start_near_mrt &
      end_near_mrt
  )

#讀天氣資料
# 3. 讀取氣象站清單

weather_sta <- read.csv(
  "Data/weather_sta_list_2025-06-09.csv",
  fileEncoding = "UTF-8"
)

# 4. 篩出台北市氣象站

weather_north <- weather_sta %>%
  filter(城市 %in% c("臺北市", "新北市"))
  filter(!is.na(經度), !is.na(緯度))
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

# 10. 檢查結果

head(bike_weather_map)

# 看每個氣象站被分配到多少 YouBike 站

bike_weather_map %>% count(nearest_weather_station, sort = TRUE)

# 11. 輸出成 CSV

write.csv(
  bike_weather_map,
  "Data/bike_weather_station_map.csv",
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

