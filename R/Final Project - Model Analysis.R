mrt_weather_clean <- readRDS("Output/mrt_weather_clean.rds")
summary(mrt_weather_clean)

model1 <- lm(
  trip_count ~ rain +temperature +I(temperature^2) +humidity +
    weekend +factor(hour) +factor(mrt_station),
  data = mrt_weather_clean
)
summary(model1)
