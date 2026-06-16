## nb model
library(MASS)
mrt_weather_clean <- readRDS("Output/mrt_weather_clean.rds")

model_nb <- glm.nb(
  trip_count ~ rain_dummy + temperature + I(temperature^2) +
    humidity + weekend + factor(hour) + factor(mrt_station),
  data = mrt_weather_clean
)
summary(model_nb)

modelsummary(
  list(
    "OLS" = m4,
    "Negative Binomial" = model_nb
  ),
  coef_omit = "factor\\(",
  coef_map = c(
    rain_dummy = "Rain Dummy",
    temperature = "Temperature",
    "I(temperature^2)" = "Temperature²",
    humidity = "Humidity",
    weekend = "Weekend"
  ),
  estimate = "{estimate}{stars}",
  statistic = "({std.error})",
  stars = c('*' = .05, '**' = .01, '***' = .001),
  output = "Appendix_Robustness.png"
)
