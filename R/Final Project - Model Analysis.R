library(dplyr)
library(modelsummary)
library(performance)

mrt_weather_clean <- readRDS("Output/mrt_weather_clean.rds")

# Model0: Weather only
m0 <- lm(
  trip_count ~
    rain_dummy +
    temperature +
    I(temperature^2) +
    humidity,
  data = mrt_weather_clean
)

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

# Model performance comparison
model_performance <- compare_performance(
  m0, m1, m2, m3, m4
)
model_performance


# 3. Nested model tests

# 時間變數是否顯著改善模型？
anova(m0, m1)

# 平日/假日的日內型態是否不同？
anova(m1, m2)

# 雨天效果是否因時段不同而異？
anova(m1, m3)

# 站點固定效果是否重要？
anova(m1, m4)

# 4. Export model comparison table
modelsummary(
  list(
    "M0" = m0,
    "M1" = m1,
    "M2" = m2,
    "M3" = m3,
    "M4" = m4
  ),
  coef_omit = "factor\\(hour\\)|factor\\(mrt_station\\)",
  output = "Tables/regression.png"
)
