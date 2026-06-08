## nb model
library(MASS)
mrt_weather_clean <- readRDS("Output/mrt_weather_clean.rds")

model_nb <- glm.nb(
  trip_count ~ rain_dummy + temperature + I(temperature^2) +
    humidity + weekend + factor(hour) + factor(mrt_station),
  data = mrt_weather_clean
)
summary(model_nb)
