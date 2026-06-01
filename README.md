# Factors Affecting YouBike Demand Around MRT Stations in Taipei

## Project Overview

This project investigates the factors affecting YouBike usage demand around Taipei MRT stations.

Using GIS spatial matching, weather observations, and YouBike transaction data, we construct an MRT-related YouBike demand dataset and examine how weather conditions, time patterns, and station characteristics influence hourly YouBike usage.

The project combines exploratory data analysis (EDA) and econometric regression models to identify the major determinants of YouBike demand.

---

## Research Questions

This project focuses on the following questions:

1. How does YouBike demand vary throughout the day?
2. Are there different usage patterns between weekdays and weekends?
3. How do rainfall, temperature, and humidity affect YouBike demand?
4. Does rainfall affect demand differently across time periods?
5. How important are MRT station characteristics in explaining demand differences?

---

## Data Sources

### 1. YouBike 2.0 Transaction Data

**Period:** June 2025 – September 2025

Contains trip-level information including:

- Start station
- End station
- Rental time
- Trip duration

Used to construct hourly YouBike demand around MRT stations.

---

### 2. MRT Station Exit Coordinates

Source:

https://data.taipei/dataset/detail?id=cfa4778c-62c1-497b-b704-756231de348b

Contains:

- MRT station exits
- Geographic coordinates

Used to identify MRT-related YouBike stations through GIS spatial matching.

---

### 3. Weather Observation Data

Source:

Central Weather Administration (CWA)

https://codis.cwa.gov.tw/StationData

Variables:

- Rainfall
- Temperature
- Humidity

Hourly weather observations are matched with YouBike demand records.

---

### 4. Weather Station Metadata

Source:

https://github.com/Raingel/weather_station_list

Used to spatially match YouBike stations with the nearest weather station.

---

## Data Processing

### GIS Spatial Matching

- Construct MRT station buffers
- Identify nearby YouBike stations
- Match weather stations to YouBike stations

### Temporal Aggregation

Convert trip-level records into:

- MRT station × hour demand observations

### Weather Matching

Merge:

- Hourly weather conditions
- Hourly YouBike demand

---

## Exploratory Data Analysis

The project examines:

### Demand Distribution

- Histogram of trip counts
- Log-transformed demand distribution

### Station-Level Demand

- Top MRT stations by average YouBike demand

### Temporal Patterns

- Hourly demand pattern
- Morning and evening demand peaks
- Weekday versus weekend demand

### Weather Effects

- Rain versus no-rain demand
- Temperature-demand relationship
- Humidity-demand relationship

### Rainfall Heterogeneity

- Rain effects across MRT stations
- Rain effects across different time periods

---

## Econometric Models

### Model 0: Weather Model

```r
trip_count ~
rain_dummy +
temperature +
I(temperature^2) +
humidity
```

Examines the effects of weather conditions.

### Model 1: Time Model

```r
trip_count ~
rain_dummy +
temperature +
I(temperature^2) +
humidity +
weekend +
factor(hour)
```

Adds temporal demand patterns.

### Model 2: Weekend-Hour Interaction Model

```r
trip_count ~
rain_dummy +
temperature +
I(temperature^2) +
humidity +
weekend * factor(hour)
```

Tests whether weekday and weekend demand patterns differ.

### Model 3: Rain-Hour Interaction Model

```r
trip_count ~
rain_dummy * factor(hour) +
temperature +
I(temperature^2) +
humidity +
weekend
```

Tests whether rainfall effects vary across time periods.

### Model 4: Station Fixed Effects Model

```r
trip_count ~
rain_dummy +
temperature +
I(temperature^2) +
humidity +
weekend +
factor(hour) +
factor(mrt_station)
```

Controls for station-specific characteristics.

---

## Main Findings

### Temporal Factors Matter

Adding hour and weekend information substantially improves model performance.

### Weekday and Weekend Patterns Differ

Morning and evening commuting peaks are much stronger on weekdays.

### Rainfall Reduces Demand

Rainy conditions significantly decrease YouBike usage.

### Temperature Shows an Inverted-U Relationship

Demand increases with temperature up to a certain level and then declines.

### Station Characteristics Are Highly Important

Station fixed effects explain a large share of demand variation, indicating substantial differences across MRT station environments.

---

## Repository Structure

```
.
├── Data/
├── Output/
├── Figures/
├── Tables/
├── R/
├── README.md
└── Final Project.Rproj
```

---

## Methods

- GIS Spatial Matching
- Exploratory Data Analysis (EDA)
- Multiple Linear Regression
- Fixed Effects Modeling
- Model Comparison (AIC, BIC, RMSE, R²)

---

## Authors

National Chengchi University

Research Data Science (RDS)

Group 3
