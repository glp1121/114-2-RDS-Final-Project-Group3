library(dplyr)
library(modelsummary)
library(performance)
library(broom)
library(ggplot2)
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

#
station_fe <- tidy(m4) %>%
  filter(grepl("factor\\(mrt_station\\)", term)) %>%
  mutate(
    station = gsub("factor\\(mrt_station\\)", "", term)
  ) %>%
  select(station, estimate)

anova(m0, m1)
anova(m1, m2)
anova(m1, m3)
anova(m1, m4)

# Top 10
top10 <- station_fe %>%
  arrange(desc(estimate)) %>%
  slice(1:10)

# Bottom 10
bottom10 <- station_fe %>%
  arrange(estimate) %>%
  slice(1:10)

plot_station <- bind_rows(
  top10,
  bottom10
)

f8 <- ggplot(plot_station,
       aes(x = reorder(station, estimate),
           y = estimate)) +
  geom_col() +
  coord_flip() +
  labs(
    title = "Top and Bottom MRT Station Fixed Effects",
    subtitle = "Controlling for weather and time factors",
    x = NULL,
    y = "Station Fixed Effect"
  ) +
  theme_minimal(base_family = "PingFang TC")
ggsave("Figures/figure8.png", f8, width = 8, height = 5, dpi = 300)
