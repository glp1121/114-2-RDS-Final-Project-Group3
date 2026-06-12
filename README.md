# Weather Effects on MRT-Related YouBike Demand in Taipei

## Project Overview

This project was completed as the final project for Research Data Science (RDS) at National Chengchi University.

The objective of this project is to demonstrate a complete data science workflow, including data collection, data cleaning, data integration, exploratory data analysis (EDA), spatial data processing, statistical modeling, and result interpretation.

Using Taipei YouBike trip records, MRT station location data, and weather observations, we investigate how weather conditions affect MRT-related YouBike demand and explore the relationship between weather and first-/last-mile transportation behavior.

---

## Research Questions

This study aims to answer the following questions:

1. Does rainfall reduce MRT-related YouBike demand?
2. How does temperature influence MRT-related YouBike usage?
3. Does the impact of weather on MRT-related YouBike demand exhibit temporal and spatial heterogeneity?

---

## Data Sources

### 1. YouBike Trip Data

Taipei YouBike 2.0 trip records containing:

- Origin station
- Destination station
- Start time
- End time
- Trip duration

### 2. MRT Station Data

Taipei Metro station and exit location data containing:

- MRT station names
- Exit locations
- Geographic coordinates

### 3. Weather Data

Weather observations obtained from the Central Weather Administration (CWA):

- Temperature
- Rainfall
- Relative humidity

### 4. Weather Station Metadata

Weather station information:

- Station coordinates
- Station identifiers

Source:
https://github.com/Raingel/weather_station_list

---

## Data Science Workflow

### 1. Data Collection

Multiple open datasets were collected from different sources, including transportation and weather databases.

### 2. Data Cleaning

Data preprocessing procedures included:

- Missing value inspection
- Datetime conversion
- Coordinate standardization
- Variable transformation

### 3. Data Integration

To combine multiple datasets, we performed:

- Spatial matching between MRT exits and nearby YouBike stations
- Weather station assignment based on geographic proximity
- Temporal matching between trip records and hourly weather observations

### 4. Exploratory Data Analysis (EDA)

Before constructing the regression models, we conducted several exploratory analyses to understand the characteristics of MRT-related YouBike demand.

Our EDA focused on:

- **Hourly demand patterns**, identifying morning and evening peaks associated with commuting activities.
- **Station-level demand variation**, comparing MRT stations with different demand intensities and usage characteristics.
- **Weather effects on demand**, examining differences in ridership between rainy and non-rainy conditions.
- **Temporal heterogeneity**, investigating whether weather impacts vary across different hours of the day.
- **Spatial heterogeneity**, comparing weather-demand relationships across different MRT station types.
- **Nonlinear relationships between weather variables and demand**, including temperature and humidity effects on YouBike usage.

These analyses provide preliminary evidence that weather conditions, time of day, and station characteristics jointly influence MRT-related YouBike demand.

### 5. Statistical Modeling

To estimate the effects of weather conditions on MRT-related YouBike demand, we implemented:

- Multiple Linear Regression
- Negative Binomial Regression

Control variables include:

- Temperature
- Relative humidity
- Weekend indicator
- Hour fixed effects
- Station fixed effects

### 6. Result Interpretation

Model outputs were used to evaluate how weather conditions influence MRT-related YouBike demand and to understand station-level heterogeneity across Taipei.

---

## Main Findings

### Rainfall Significantly Reduces Demand

Rainy weather is associated with a substantial decline in MRT-related YouBike trips.

### Nonlinear Temperature Effect

Trip demand increases with temperature up to a certain level, but extremely high temperatures discourage cycling activity.

### Strong Station Heterogeneity

Station-specific characteristics explain a large proportion of variation in trip demand, indicating that location remains an important determinant of MRT-related YouBike usage.

---

## Repository Structure

text . ├── Data/              # Raw datasets ├── Output/            # Processed datasets ├── Figures/           # Figures and visualizations ├── R/                 # Data cleaning and analysis scripts ├── Report/            # Final report and presentation slides └── README.md 

---

## Course Information

Course: Research Data Science (RDS)

Instructor: LIAO JEN-CHE

National Chengchi University

Spring 2026