library(dplyr)
library(modelsummary)
library(performance)
mrt_weather_clean <- readRDS("Output/mrt_weather_clean.rds")
#檢查相關問題
mrt_weather_clean %>%
  select(rain_dummy,
         temperature,
         humidity,
         weekend) %>%
  cor(use = "complete.obs")


# Model0: Weather only
m0 <- lm(
  trip_count ~
    rain_dummy +
    temperature +
    I(temperature^2) +
    humidity,
  data = mrt_weather_clean
)
summary(m0)

# Model 1: Weather + Time
m1 <- lm(
  trip_count ~
    rain_dummy +
    temperature +
    I(temperature^2) +
    humidity +
    weekend +
    factor(hour),
  data = mrt_weather_clean
)
summary(m1)

# Model 2: Weekend × Hour
#檢查平日與假日的日內需求型態是否不同

m2 <- lm(
  trip_count ~
    rain_dummy +
    temperature +
    I(temperature^2) +
    humidity +
    weekend * factor(hour),
  data = mrt_weather_clean
)
summary(m2)
# Model 3: Rain × Hour
# 檢查雨天效果是否因時段不同而異

m3 <- lm(
  trip_count ~
    rain_dummy * factor(hour) +
    temperature +
    I(temperature^2) +
    humidity +
    weekend,
  data = mrt_weather_clean
)
summary(m3)

# Model 4: Full model with MRT station fixed effects
#控制不同捷運站本身的需求差異

m4 <- lm(
  trip_count ~
    rain_dummy +
    temperature +
    I(temperature^2) +
    humidity +
    weekend +
    factor(hour) +
    factor(mrt_station),
  data = mrt_weather_clean
)
summary(m4)

# Model 5: Rain × Weekend
m5 <- lm(
  trip_count ~
    rain_dummy * weekend +
    temperature +
    I(temperature^2) +
    humidity +
    factor(hour) +
    factor(mrt_station),
  data = mrt_weather_clean
)
summary(m5)

# Model performance comparison
model_performance <- compare_performance(
  m0, m1, m2, m3, m4, m5
)
model_performance


# 4. Export model comparison table
modelsummary(
  list(
    "M0" = m0,
    "M1" = m1,
    "M2" = m2,
    "M3" = m3,
    "M4" = m4,
    "M5" = m5
  ),
  coef_omit = "factor\\(hour\\)|factor\\(mrt_station\\)",
  output = "Tables/regression.png"
)
