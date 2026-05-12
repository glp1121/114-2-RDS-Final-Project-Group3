# MRT and YouBike Integration Project

## Project Goal

This project studies whether YouBike serves as a complement or substitute for MRT usage in Taipei.

We focus on MRT-related YouBike trips identified using GIS spatial matching.

---

# Data Sources

## 1. YouBike2.0臺北市公共自行車即時資訊
- Source:
`https://tcgbusfs.blob.core.windows.net/dotapp/youbike/v2/youbike_immediate.json`

- Description:
Real-time YouBike 2.0 station information including:
  - station name
  - latitude / longitude
  - district

- Usage:
Used for GIS spatial matching with MRT stations and weather stations.

---

## 2. 臺北捷運車站出入口座標
- Source:
`https://data.taipei/dataset/detail?id=cfa4778c-62c1-497b-b704-756231de348b`

- File:
`MRT.csv`

- Description:
Taipei MRT exit locations including coordinates.

- Usage:
Used to construct 200-meter MRT buffers to identify MRT-related YouBike stations.

---

## 3. 202506~202509_YouBike2.0 票證刷卡資料
- Source:
`Data/202506_YouBike2.0票證刷卡資料.csv`

- Description:
Trip-level YouBike transaction data including:
  - start station
  - end station
  - trip time
  - duration

- Usage:
Used to identify MRT-substitutable YouBike trips.

---

## 4. 202506~202509 台北氣候觀測資料
- Source:
Central Weather Administration (CWA) `https://codis.cwa.gov.tw/StationData`

- Description:
Hourly weather observations including:
  - rainfall
  - temperature
  - humidity

- Usage:
Merged with trip-level YouBike data based on nearest weather station and trip time.

## 4. Weather Station Metadata

- Source:

https://github.com/Raingel/weather_station_list

- Description:
Weather station metadata including:
  - station name
  - station ID
  - longitude / latitude
  - city
  - station type

- Usage:
Used to spatially match each YouBike station to its nearest weather station.
---

## Methods

- GIS spatial matching
- Trip classification
- Econometric regression

---

## Authors

- Group 3
