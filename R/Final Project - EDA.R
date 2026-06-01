library(ggplot2)
library(dplyr)
library(tidyr)
library(scales)
library(gt)

mrt_weather_clean <- readRDS("Output/mrt_weather_clean.rds")
#1.  trip_count 
mrt_weather_clean %>% ggplot(aes(trip_count)) + geom_histogram()
mrt_weather_clean %>% ggplot(aes(x = log(trip_count+1))) + geom_histogram()

# 不同站點平均需求
station_mean <- mrt_weather_clean %>%
  group_by(mrt_station) %>%
  summarise(
    avg_trip = mean(trip_count, na.rm = TRUE),
    sd_trip = sd(trip_count, na.rm = TRUE),
    n = n()
  ) %>%
  arrange(desc(avg_trip))

f1 <- 
  station_mean %>%
  slice_head(n = 20) %>%
  ggplot(
    aes(
      x = reorder(mrt_station, avg_trip),
      y = avg_trip
    )
  ) +
  geom_col() +
  coord_flip() +
  labs(
    title = "Top 20 MRT Stations by Average YouBike Demand",
    x = "MRT Station",
    y = "Average Trip Count"
  ) +
  theme_minimal(base_family = "PingFang TC")

ggsave(
  "Figures/figure1.png",
  plot = f1,
  width = 8,
  height = 5,
  dpi = 300
)

# YouBike 使用量的日內變化
hourly_pattern <- mrt_weather_clean %>%
  group_by(hour) %>%
  summarise(
    avg_trip = mean(trip_count, na.rm = TRUE)
  )

f2 <- 
  hourly_pattern %>% ggplot(aes(x = hour, y = avg_trip))+
  geom_line(size = 1) +
  geom_point(size = 2) +
  scale_x_continuous(breaks = 6:23) +
  labs(
    title = "Hourly Pattern of YouBike Usage",
    x = "Hour of Day",
    y = "Average Trip Count"
  ) + theme_minimal()
ggsave(
  "Figures/figure2.png",
  plot = f2,
  width = 8,
  height = 5,
  dpi = 300
)

# 假日與平日的變化
hourly_weekend <- mrt_weather_clean %>% group_by(hour, weekend) %>% 
  summarise(avg_trip = mean(trip_count), .groups = 'drop')

f3 <-
  hourly_weekend %>% 
  ggplot(aes(x = hour, y = avg_trip, color = factor(weekend))) +
  geom_line(size = 1.2) +
  scale_x_continuous(
    breaks = 0:23
  ) +
  labs(
    title = "Hourly YouBike Demand",
    x = "Hour",
    y = "Average Trip Count",
    color = "Weekend"
  ) + theme_minimal()
ggsave(
  "Figures/figure3.png",
  plot = f3,
  width = 8,
  height = 5,
  dpi = 300
)

# 雨量
rain_hour <- mrt_weather_clean %>%
  group_by(hour, rain_dummy) %>%
  summarise(
    avg_trip = mean(trip_count, na.rm = TRUE),
    .groups = "drop"
  )

rain_hour <- rain_hour %>%
  mutate(
    rain_label = ifelse(rain_dummy == 1, "Rain", "No Rain")
  )

f4 <- rain_hour %>% 
  ggplot(aes(x = hour,y = avg_trip, color = rain_label, group = rain_label)) +
  geom_line(linewidth = 1.2) +
  geom_point() +
  scale_x_continuous(breaks = 0:23) +
  labs(
    x = "Hour",
    y = "Average Trip Count",
    color = "Rain Condition",
    title = "Hourly YouBike Demand by Rain Condition"
  ) +
  theme_minimal() +
  theme(
    legend.position = "right"
  )
ggsave(
  "Figures/figure4.png",
  plot = f4,
  width = 8,
  height = 5,
  dpi = 300
)

#溫度
temp_pattern <- mrt_weather_clean %>% 
  group_by(temperature) %>% 
  summarise(avg_trip = mean(trip_count), .groups = "drop")

f5 <- temp_pattern %>% ggplot(aes(x = temperature, y = avg_trip)) +
  geom_point(alpha = .5) +
  geom_smooth()
ggsave(
  "Figures/figure5.png",
  plot = f5,
  width = 8,
  height = 5,
  dpi = 300
)

#晴天與雨天的溫度差異
temp_rain <- mrt_weather_clean %>%
  group_by(temperature, rain_dummy) %>%
  summarise(
    avg_trip = mean(trip_count),
    .groups = "drop"
  )

f6 <- temp_rain %>% 
  ggplot(aes(temperature, avg_trip, color = factor(rain_dummy,labels = c("No Rain", "Rain")
    )
  )
) +
  geom_smooth(se = FALSE) +
  labs(
    color = "Weather Condition"
  )

ggsave(
  "Figures/figure6.png",
  plot = f6,
  width = 8,
  height = 5,
  dpi = 300
)

#濕度
humidity_pattern <- mrt_weather_clean %>%
  group_by(humidity) %>%
  summarise(
    avg_trip = mean(trip_count)
  )

f7 <- humidity_pattern %>%
  ggplot(aes(x = humidity, y = avg_trip)) +
  geom_point(
    alpha = 0.5,
    size = 2
  ) +
  geom_smooth(
    method = "loess",
    se = TRUE,
    linewidth = 1.2
  ) +
  labs(
    title = "Relationship Between Humidity and YouBike Demand",
    x = "Humidity (%)",
    y = "Average Trip Count"
  ) +
  theme_minimal(base_family = "PingFang TC") +
  theme(
    plot.title = element_text(
      hjust = 0.5,
      face = "bold"
    )
  )
ggsave(
  "Figures/figure7.png",
  plot = f7,
  width = 8,
  height = 5,
  dpi = 300
)

#
station_rain <- mrt_weather_clean %>%
  group_by(mrt_station, rain_dummy) %>%
  summarise(
    avg_trip = mean(trip_count),
    .groups = "drop"
  ) %>%
  pivot_wider(
    names_from = rain_dummy,
    values_from = avg_trip
  ) %>%
  mutate(
    rain_effect = (`1`-`0`)/`0`
  )

head(station_rain[order(station_rain$rain_effect),], 20)

t1 <- station_rain %>%
  arrange(rain_effect) %>%
  slice_head(n = 20) %>%
  gt() %>%
  cols_label(
    mrt_station = "MRT Station",
    `0` = "Mean Demand (No Rain)",
    `1` = "Mean Demand (Rain)",
    rain_effect = "Percentage Change"
  ) %>%
  fmt_percent(
    columns = rain_effect,
    decimals = 1
  )

gtsave(
  t1,
  "Tables/table1.png"
)
