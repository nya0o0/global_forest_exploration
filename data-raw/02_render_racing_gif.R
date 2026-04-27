# =========================================================
# 02_render_racing_gif.R
# Pre-renders the gganimate racing bar chart used in Tab 2.
# Saves to www/racing_bar.gif so the app loads it instantly.
# Run once (or whenever you want to re-render).
# =========================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(gganimate)
  library(scales)
  library(viridisLite)
})

country_panel <- readRDS("data/country_panel.rds")

racing <- country_panel %>%
  filter(threshold == 30, !is.na(cumulative_loss)) %>%
  group_by(year) %>%
  arrange(desc(cumulative_loss), .by_group = TRUE) %>%
  mutate(rank = row_number()) %>%
  filter(rank <= 12) %>%
  ungroup() %>%
  mutate(value_lbl = paste0(round(cumulative_loss / 1e6, 1), "M ha"))

# Stable color per country across frames
top_countries <- racing %>% distinct(country) %>% pull(country)
pal <- setNames(viridisLite::turbo(length(top_countries)), top_countries)

p <- ggplot(racing, aes(x = -rank, y = cumulative_loss,
                        fill = country, group = country)) +
  geom_col(width = 0.8, show.legend = FALSE) +
  geom_text(aes(label = country),
            hjust = 1, nudge_y = -max(racing$cumulative_loss) * 0.015,
            size = 4.2, fontface = "bold") +
  geom_text(aes(label = value_lbl),
            hjust = 0, nudge_y = max(racing$cumulative_loss) * 0.015,
            size = 4) +
  coord_flip(clip = "off") +
  scale_fill_manual(values = pal) +
  scale_y_continuous(labels = label_number(scale = 1e-6, suffix = "M"),
                     expand = expansion(mult = c(0.25, 0.18))) +
  labs(title    = "Cumulative tree cover loss · {closest_state}",
       subtitle = "Top 12 countries, 2001 through year shown · canopy ≥ 30%",
       caption  = "Data: Hansen/UMD via Global Forest Watch (ODbL 1.0)") +
  theme_minimal(base_size = 15) +
  theme(
    plot.title = element_text(size = 22, face = "bold"),
    plot.subtitle = element_text(size = 13, color = "#555"),
    plot.caption = element_text(color = "#888"),
    axis.title = element_blank(),
    axis.text.y = element_blank(),
    axis.ticks.y = element_blank(),
    panel.grid.major.y = element_blank(),
    panel.grid.minor   = element_blank(),
    plot.margin = margin(20, 60, 20, 20)
  ) +
  transition_states(year, transition_length = 4, state_length = 1) +
  ease_aes("cubic-in-out")

if (!dir.exists("www")) dir.create("www")

message("Rendering racing GIF (this takes ~1-2 min) ...")
animate(p,
        nframes  = 22 * 6,
        fps      = 12,
        width    = 900,
        height   = 600,
        renderer = gifski_renderer("www/racing_bar.gif"),
        end_pause = 18)

message("Done. Saved to www/racing_bar.gif")
