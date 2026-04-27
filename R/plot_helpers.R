# =========================================================
# R/plot_helpers.R
# Reusable plotting functions for app.R
# =========================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(plotly)
  library(scales)
})

# Big numbers as "1.2M ha"
fmt_big <- function(x) {
  ifelse(is.na(x), "-",
    ifelse(abs(x) >= 1e9, paste0(round(x / 1e9, 1), "B"),
      ifelse(abs(x) >= 1e6, paste0(round(x / 1e6, 1), "M"),
        ifelse(abs(x) >= 1e3, paste0(round(x / 1e3, 1), "k"),
               as.character(round(x, 0))))))
}

# ---------- Tab 1: World choropleth ----------
plot_world_map <- function(df, year_sel, threshold_sel = 30,
                           metric = c("loss", "flux")) {
  metric <- match.arg(metric)
  d <- df %>%
    filter(threshold == threshold_sel, year == year_sel,
           !is.na(iso3))
  if (metric == "loss") {
    d$z <- d$loss_ha
    title_t <- paste0("Annual tree cover loss in ", year_sel,
                      " - canopy threshold >= ", threshold_sel, "%")
    colorbar_title <- "Loss (ha)"
    colorscale <- "YlOrRd"
    reversescale <- FALSE
    zmid <- NULL
  } else {
    d$z <- d$net_flux_yr / 1e6  # to Mt for readability
    title_t <- "Net forest carbon flux (Mt CO2e/yr) - red = source, green = sink"
    colorbar_title <- "Mt CO2e/yr"
    colorscale <- "RdYlGn"
    reversescale <- TRUE
    zmid <- 0
  }
  hover <- paste0(
    "<b>", d$country, "</b><br>",
    ifelse(metric == "loss",
           paste0("Loss: ", scales::comma(d$loss_ha), " ha"),
           paste0("Net flux: ", round(d$z, 1), " Mt CO2e/yr")),
    "<extra></extra>"
  )
  p <- plot_geo(d) %>%
    add_trace(
      z = ~z, locations = ~iso3, text = ~country,
      colorscale = colorscale, reversescale = reversescale,
      zmid = zmid,
      colorbar = list(title = colorbar_title),
      hovertemplate = hover,
      source = "world_map"
    ) %>%
    layout(
      title = list(text = title_t, font = list(size = 14)),
      geo = list(
        projection = list(type = "natural earth"),
        showcoastlines = TRUE, coastlinecolor = "#888",
        showland = TRUE, landcolor = "#f5f5f5",
        showocean = TRUE, oceancolor = "#e8f0f5",
        showframe = FALSE
      ),
      margin = list(l = 0, r = 0, t = 50, b = 0)
    ) %>%
    config(displayModeBar = FALSE)
  p
}

# ---------- Tab 3: Country annual loss area chart ----------
plot_country_trend <- function(df, country_sel, threshold_sel = 30) {
  d <- df %>%
    filter(country == country_sel, threshold == threshold_sel) %>%
    arrange(year)
  ymax <- max(d$loss_ha, na.rm = TRUE)
  plot_ly(d, x = ~year, y = ~loss_ha, type = "scatter",
          mode = "lines+markers",
          fill = "tozeroy",
          fillcolor = "rgba(220, 60, 50, 0.35)",
          line = list(color = "rgb(180, 30, 30)", width = 2),
          marker = list(size = 6, color = "rgb(180, 30, 30)"),
          hovertemplate = paste0(
            "%{x}<br>Loss: %{y:,.0f} ha<extra></extra>")) %>%
    layout(
      title = list(text = paste0("Annual tree cover loss - ",
                                 country_sel),
                   font = list(size = 13)),
      xaxis = list(title = "", dtick = 2),
      yaxis = list(title = "hectares"),
      shapes = list(
        list(type = "line", x0 = 2021, x1 = 2021,
             y0 = 0, y1 = ymax,
             line = list(color = "black", dash = "dash", width = 1.5))
      ),
      annotations = list(
        list(x = 2021, y = ymax, text = "COP26 pledge",
             showarrow = FALSE, xanchor = "right", yanchor = "top",
             font = list(size = 11))
      ),
      margin = list(l = 50, r = 20, t = 40, b = 40)
    ) %>%
    config(displayModeBar = FALSE)
}

# ---------- Tab 3: Subnational top 10 bar chart ----------
plot_subnational_bar <- function(sub_df, country_sel, threshold_sel = 30) {
  d <- sub_df %>%
    filter(country == country_sel, threshold == threshold_sel) %>%
    group_by(subnational1) %>%
    summarise(total_loss = sum(loss_ha, na.rm = TRUE), .groups = "drop") %>%
    arrange(desc(total_loss)) %>%
    slice_head(n = 10) %>%
    mutate(subnational1 = factor(subnational1, levels = rev(subnational1)))
  if (nrow(d) == 0) {
    return(plotly_empty(type = "scatter", mode = "markers") %>%
             layout(title = "No subnational data available"))
  }
  plot_ly(d, x = ~total_loss, y = ~subnational1, type = "bar",
          orientation = "h",
          marker = list(color = "#2c7a7b"),
          hovertemplate = "%{y}<br>%{x:,.0f} ha<extra></extra>") %>%
    layout(
      title = list(text = paste0("Top 10 subnational regions - ",
                                 country_sel,
                                 " (cumulative loss 2001-2022)"),
                   font = list(size = 13)),
      xaxis = list(title = "hectares"),
      yaxis = list(title = ""),
      margin = list(l = 120, r = 20, t = 40, b = 40)
    ) %>%
    config(displayModeBar = FALSE)
}

# ---------- Headline KPI card ----------
make_kpi_html <- function(country_sel, df, threshold_sel = 30) {
  d <- df %>% filter(country == country_sel, threshold == threshold_sel)
  total_loss <- sum(d$loss_ha, na.rm = TRUE)
  flux <- unique(d$net_flux_yr)[1]  # one value per country
  flux_label <- if (is.na(flux)) "--" else if (flux > 0) "Net carbon SOURCE" else "Net carbon SINK"
  flux_color <- if (is.na(flux)) "#666" else if (flux > 0) "#c0392b" else "#27ae60"
  HTML(sprintf(
    '<div style="display:flex;gap:24px;flex-wrap:wrap;margin-top:12px">
       <div style="flex:1;min-width:200px;padding:14px;background:#fff;
                   border-radius:8px;box-shadow:0 1px 3px rgba(0,0,0,.08)">
         <div style="font-size:12px;color:#666">Cumulative loss 2001-2022</div>
         <div style="font-size:24px;font-weight:600">%s ha</div>
       </div>
       <div style="flex:1;min-width:200px;padding:14px;background:#fff;
                   border-radius:8px;box-shadow:0 1px 3px rgba(0,0,0,.08)">
         <div style="font-size:12px;color:#666">Forest carbon role</div>
         <div style="font-size:20px;font-weight:600;color:%s">%s</div>
         <div style="font-size:12px;color:#888">Net flux: %s Mt CO2e/yr</div>
       </div>
     </div>',
    scales::comma(total_loss), flux_color, flux_label,
    if (is.na(flux)) "--" else round(flux / 1e6, 1)
  ))
}
