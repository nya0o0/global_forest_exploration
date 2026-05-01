# ============================================================================
# helpers.R — all shared helpers (data + plot + UI bits) in one file.
# ============================================================================

# ---- Palettes ---------------------------------------------------------------
PALETTE_REGION <- c(            # Okabe-Ito (colour-blind safe)
  "Africa"   = "#E69F00",
  "Asia"     = "#56B4E9",
  "Europe"   = "#009E73",
  "Americas" = "#D55E00",
  "Oceania"  = "#CC79A7",
  "Other"    = "#999999"
)

# ---- Data helpers -----------------------------------------------------------

#' Top-N countries by tree-cover loss for a given year and threshold.
top_countries_loss <- function(df, year_sel, threshold_sel, n = 10) {
  df %>%
    filter(year == year_sel, threshold == threshold_sel) %>%
    group_by(country) %>%
    summarise(tc_loss_ha = sum(tc_loss_ha, na.rm = TRUE), .groups = "drop") %>%
    arrange(desc(tc_loss_ha)) %>%
    slice_head(n = n)
}

#' Per-country annual time series for a list of countries.
country_time_series <- function(df, countries, threshold_sel,
                                year_min = 2001, year_max = 2022) {
  df %>%
    filter(country %in% countries,
           threshold == threshold_sel,
           year >= year_min, year <= year_max) %>%
    arrange(country, year)
}

#' Pearson correlation between annual loss and gross emissions.
loss_carbon_corr <- function(df, year_sel, threshold_sel) {
  d <- df %>%
    filter(year == year_sel, threshold == threshold_sel,
           !is.na(tc_loss_ha), !is.na(gross_emissions),
           tc_loss_ha > 0, gross_emissions > 0)
  if (nrow(d) < 5) return(NA_real_)
  suppressWarnings(cor(d$tc_loss_ha, d$gross_emissions, method = "pearson"))
}

#' SI label formatter (1.2M, 350k, ...)
fmt_si <- function(x) scales::label_number(scale_cut = scales::cut_short_scale())(x)

# ---- Plot helpers -----------------------------------------------------------

#' Project ggplot theme.
plot_theme <- function() {
  ggplot2::theme_minimal(base_size = 13) +
    ggplot2::theme(
      panel.grid.minor   = ggplot2::element_blank(),
      panel.grid.major.x = ggplot2::element_blank(),
      plot.title         = ggplot2::element_text(face = "bold", size = 16),
      plot.subtitle      = ggplot2::element_text(colour = "grey40"),
      legend.position    = "bottom",
      strip.text         = ggplot2::element_text(face = "bold")
    )
}

#' Convert ggplot to plotly with consistent config.
to_plotly <- function(g, tooltip = "text") {
  plotly::ggplotly(g, tooltip = tooltip) %>%
    plotly::config(displaylogo = FALSE,
                   modeBarButtonsToRemove = c("lasso2d", "select2d", "autoScale2d"))
}

# ---- UI helpers -------------------------------------------------------------

#' Insight callout used at the bottom of each chapter.
insight_box <- function(title, text) {
  div(class = "insight-box",
      tags$h4(icon("lightbulb"), " ", title),
      tags$p(text))
}

#' Module title block.
module_header <- function(chapter, title, subtitle) {
  div(class = "module-header",
      tags$small(class = "chapter-tag", paste("Chapter", chapter)),
      tags$h2(title),
      tags$p(class = "lead", subtitle))
}
