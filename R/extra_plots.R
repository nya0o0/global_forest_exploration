# =========================================================
# R/extra_plots.R
# Extra plotly helpers:
#   - plot_loss_heatmap()     : intensity heatmap (top N countries x years)
#   - plot_sink_source()      : 4-quadrant sink vs source scatter
# Both are pure plotly, no extra packages beyond what app.R already loads.
# =========================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(plotly)
  library(scales)
})

# ---------------------------------------------------------
# 1) Loss intensity heatmap
#    Rows = top N countries by cumulative loss
#    Cols = years 2001..2022
#    Cell = annual loss as % of country's 2000 forest extent
# ---------------------------------------------------------
plot_loss_heatmap <- function(df,
                              threshold_sel = 30,
                              top_n         = 30) {
  
  d <- df %>%
    filter(threshold == threshold_sel,
           !is.na(loss_ha),
           extent_2000_ha > 0)
  
  # rank countries by total loss (so the heatmap is ordered)
  rank_tbl <- d %>%
    group_by(country) %>%
    summarise(total = sum(loss_ha, na.rm = TRUE),
              extent = first(extent_2000_ha),
              .groups = "drop") %>%
    arrange(desc(total)) %>%
    slice_head(n = top_n)
  
  d2 <- d %>%
    filter(country %in% rank_tbl$country) %>%
    mutate(intensity_pct = 100 * loss_ha / extent_2000_ha,
           country = factor(country, levels = rev(rank_tbl$country)))
  
  # build matrix in the order plotly wants: x = years, y = countries
  years     <- sort(unique(d2$year))
  countries <- levels(d2$country)
  z <- matrix(NA_real_,
              nrow = length(countries),
              ncol = length(years),
              dimnames = list(countries, as.character(years)))
  for (i in seq_len(nrow(d2))) {
    z[as.character(d2$country[i]), as.character(d2$year[i])] <- d2$intensity_pct[i]
  }
  
  # cap color scale so a single bad year does not flatten everything
  zmax <- quantile(z, 0.98, na.rm = TRUE)
  
  hover_text <- matrix("", nrow = nrow(z), ncol = ncol(z))
  for (r in seq_len(nrow(z))) {
    for (c in seq_len(ncol(z))) {
      v <- z[r, c]
      hover_text[r, c] <- paste0(
        "<b>", rownames(z)[r], "</b><br>",
        "Year: ", colnames(z)[c], "<br>",
        "Loss intensity: ",
        ifelse(is.na(v), "n/a", paste0(round(v, 3), "% of 2000 forest")),
        "<extra></extra>")
    }
  }
  
  plot_ly(
    x = colnames(z),
    y = rownames(z),
    z = z,
    type = "heatmap",
    colorscale = "YlOrRd",
    zmin = 0, zmax = zmax,
    text = hover_text,
    hovertemplate = "%{text}",
    colorbar = list(title = "Loss %\nof 2000\nforest")
  ) %>%
    layout(
      title = list(
        text = paste0("Annual tree-cover loss intensity - top ", top_n,
                      " countries (canopy >= ", threshold_sel, "%)"),
        font = list(size = 13)
      ),
      xaxis = list(title = "", tickangle = 0, dtick = 2),
      yaxis = list(title = "", automargin = TRUE),
      margin = list(l = 140, r = 20, t = 50, b = 40)
    ) %>%
    config(displayModeBar = FALSE)
}


# ---------------------------------------------------------
# 2) Sink-vs-source 4-quadrant scatter
#    x = cumulative loss 2001-2022 (Mha)
#    y = annual net carbon flux (Mt CO2e/yr); +ve = source, -ve = sink
#    bubble size = 2000 forest extent
#    color = simple region grouping
# ---------------------------------------------------------

# tiny region lookup (no extra deps); defaults to "Other"
.region_for <- function(country) {
  asia <- c("China","India","Indonesia","Malaysia","Myanmar","Vietnam",
            "Thailand","Philippines","Cambodia","Laos","Lao People's Democratic Republic",
            "Papua New Guinea","Japan","Korea, Republic of",
            "Korea, Democratic People's Republic of","Mongolia","Bangladesh",
            "Sri Lanka","Nepal","Bhutan","Pakistan","Afghanistan","Kazakhstan",
            "Uzbekistan","Turkmenistan","Tajikistan","Kyrgyzstan",
            "Iran, Islamic Republic of","Iraq","Saudi Arabia","Yemen","Oman",
            "United Arab Emirates","Qatar","Kuwait","Bahrain","Jordan","Lebanon",
            "Syrian Arab Republic","Israel","Palestine, State of","Brunei Darussalam",
            "Timor-Leste","Singapore","Maldives")
  africa <- c("Algeria","Angola","Benin","Botswana","Burkina Faso","Burundi",
              "Cameroon","Cabo Verde","Central African Republic","Chad","Comoros",
              "Congo","Democratic Republic of the Congo","Cote d'Ivoire",
              "C\u00f4te d'Ivoire","Djibouti",
              "Egypt","Equatorial Guinea","Eritrea","Eswatini","Ethiopia","Gabon",
              "Gambia","Ghana","Guinea","Guinea-Bissau","Kenya","Lesotho","Liberia",
              "Libya","Madagascar","Malawi","Mali","Mauritania","Mauritius","Morocco",
              "Mozambique","Namibia","Niger","Nigeria","Rwanda","Sao Tome and Principe",
              "Senegal","Seychelles","Sierra Leone","Somalia","South Africa",
              "South Sudan","Sudan","Tanzania","Togo","Tunisia","Uganda","Zambia",
              "Zimbabwe","United Republic of Tanzania")
  europe <- c("Albania","Andorra","Austria","Belarus","Belgium","Bosnia and Herzegovina",
              "Bulgaria","Croatia","Cyprus","Czechia","Denmark","Estonia","Finland",
              "France","Germany","Greece","Hungary","Iceland","Ireland","Italy",
              "Latvia","Liechtenstein","Lithuania","Luxembourg","Malta",
              "Moldova, Republic of","Monaco","Montenegro","Netherlands",
              "North Macedonia","Norway","Poland","Portugal","Romania",
              "Russian Federation","San Marino","Serbia","Slovakia","Slovenia",
              "Spain","Sweden","Switzerland","Turkey","Ukraine","United Kingdom",
              "Kosovo","Russia")
  americas_n <- c("Canada","United States","Mexico")
  americas_lat <- c("Argentina","Bolivia","Brazil","Chile","Colombia","Costa Rica",
                    "Cuba","Dominican Republic","Ecuador","El Salvador","Guatemala",
                    "Guyana","Haiti","Honduras","Jamaica","Nicaragua","Panama",
                    "Paraguay","Peru","Suriname","Trinidad and Tobago","Uruguay",
                    "Venezuela, Bolivarian Republic of","Venezuela","Belize","Bahamas",
                    "Barbados","Saint Lucia","Saint Vincent and the Grenadines",
                    "Grenada","Antigua and Barbuda","Dominica","French Guiana")
  oceania <- c("Australia","New Zealand","Fiji","Solomon Islands","Vanuatu",
               "Samoa","Tonga","Kiribati","Tuvalu","Nauru","Palau",
               "Micronesia, Federated States of","Marshall Islands","New Caledonia")
  
  region <- rep("Other", length(country))
  region[country %in% asia]         <- "Asia"
  region[country %in% africa]       <- "Africa"
  region[country %in% europe]       <- "Europe / N. Asia"
  region[country %in% americas_n]   <- "N. America"
  region[country %in% americas_lat] <- "Latin America"
  region[country %in% oceania]      <- "Oceania"
  region
}

plot_sink_source <- function(df,
                             threshold_sel = 30,
                             min_loss_ha   = 50000) {
  
  # one row per country: total loss, latest net flux, 2000 forest extent
  d <- df %>%
    filter(threshold == threshold_sel,
           !is.na(net_flux_yr)) %>%
    group_by(country) %>%
    summarise(
      total_loss_ha = sum(loss_ha, na.rm = TRUE),
      net_flux_yr   = first(net_flux_yr),  # one value per country
      extent_2000   = first(extent_2000_ha),
      .groups = "drop"
    ) %>%
    filter(total_loss_ha >= min_loss_ha,
           !is.na(net_flux_yr),
           extent_2000 > 0)
  
  d <- d %>%
    mutate(
      total_loss_Mha = total_loss_ha / 1e6,
      flux_Mt_yr     = net_flux_yr   / 1e6,
      region         = .region_for(country)
    )
  
  # plotly wants size in 'sizeref' scaled px; pick a reasonable baseline
  sizeref_val <- 2 * max(d$extent_2000, na.rm = TRUE) / (40 ^ 2)
  
  hover <- paste0(
    "<b>", d$country, "</b><br>",
    "Cumulative loss: ", scales::comma(round(d$total_loss_Mha, 2)), " Mha<br>",
    "Net flux: ", round(d$flux_Mt_yr, 1), " Mt CO2e/yr<br>",
    "2000 forest extent: ", scales::comma(round(d$extent_2000 / 1e6, 1)), " Mha<br>",
    "Region: ", d$region,
    "<extra></extra>"
  )
  
  # label only a few notable countries to avoid clutter
  label_set <- c("Brazil","Indonesia","Russia","Russian Federation","United States",
                 "Canada","Democratic Republic of the Congo","Malaysia",
                 "Bolivia","Australia","Paraguay","Peru","Colombia","Argentina",
                 "Myanmar","Cambodia")
  d$label <- ifelse(d$country %in% label_set, d$country, "")
  
  region_palette <- c(
    "Africa"            = "#e67e22",
    "Asia"              = "#c0392b",
    "Europe / N. Asia"  = "#2980b9",
    "Latin America"     = "#16a085",
    "N. America"        = "#8e44ad",
    "Oceania"           = "#27ae60",
    "Other"             = "#7f8c8d"
  )
  
  fig <- plot_ly(
    d,
    x = ~total_loss_Mha,
    y = ~flux_Mt_yr,
    type = "scatter", mode = "markers+text",
    text = ~label,
    textposition = "top center",
    textfont = list(size = 10, color = "#333"),
    color = ~region, colors = region_palette,
    marker = list(
      size = ~extent_2000,
      sizemode = "area",
      sizeref = sizeref_val,
      sizemin = 4,
      line = list(width = 0.5, color = "#fff"),
      opacity = 0.75
    ),
    hovertemplate = hover
  )
  
  # quadrant guides
  fig <- fig %>%
    layout(
      title = list(
        text = paste0("Sink vs source - cumulative loss x current carbon balance (canopy >= ",
                      threshold_sel, "%)"),
        font = list(size = 13)
      ),
      xaxis = list(title = "Cumulative tree-cover loss 2001-2022 (Mha)",
                   zeroline = FALSE),
      yaxis = list(title = "Net forest carbon flux (Mt CO2e/yr)\n+ = source, - = sink",
                   zeroline = FALSE),
      shapes = list(
        list(type = "line", x0 = 0, x1 = 1, xref = "paper",
             y0 = 0, y1 = 0,
             line = list(color = "#888", dash = "dash", width = 1))
      ),
      annotations = list(
        list(x = 0.99, y = 0.97, xref = "paper", yref = "paper",
             text = "Quadrant I: high loss + net SOURCE",
             showarrow = FALSE, xanchor = "right",
             font = list(size = 11, color = "#c0392b")),
        list(x = 0.99, y = 0.03, xref = "paper", yref = "paper",
             text = "Quadrant IV: high loss but still net SINK",
             showarrow = FALSE, xanchor = "right",
             font = list(size = 11, color = "#27ae60"))
      ),
      legend = list(orientation = "h", y = -0.18),
      margin = list(l = 70, r = 20, t = 50, b = 80)
    ) %>%
    config(displayModeBar = FALSE)
  
  fig
}