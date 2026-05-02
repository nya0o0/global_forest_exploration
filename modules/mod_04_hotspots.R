# ============================================================================
# Module 4 — Subnational hotspots (Leaflet map)         Owner: Member D
# Question: Which subnational regions concentrate loss + emissions?
#
# Notes:
#   * High-resolution polygons come from {rnaturalearthhires}, which is NOT on
#     CRAN. Install once with:
#       install.packages("rnaturalearthhires",
#                        repos = c("https://ropensci.r-universe.dev",
#                                  "https://cloud.r-project.org"))
# ============================================================================

mod_04_hotspots_ui <- function(id) {
  ns <- NS(id)
  fluidPage(
    module_header(
      chapter  = 4,
      title    = "Zooming in: subnational hotspots",
      subtitle = "Hotspots cluster in the Amazon basin, Borneo and the Congo basin."
    ),
    sidebarLayout(
      sidebarPanel(width = 3,
        selectInput(ns("country"), "Country", choices = NULL),
        sliderInput(ns("year"), "Year",
                    min = 2001, max = 2022, value = 2022, step = 1, sep = ""),
        selectInput(ns("threshold"), threshold_label("Threshold"),
                    choices = THRESHOLD_CHOICES, selected = DEFAULT_THRESHOLD),
        radioButtons(ns("metric"), "Map fill",
                     choices = c("Tree-cover loss (ha)" = "tc_loss_ha",
                                 "Gross emissions"      = "gross_emissions",
                                 "Net flux"             = "net_flux")),
        tags$hr(),
        helpText("Click a region to see its 2001\u20132022 time-series.")
      ),
      mainPanel(width = 9,
        leaflet::leafletOutput(ns("map"), height = "520px"),
        helpText("Click a region on the map to see its time series."),
        plotlyOutput(ns("region_ts"), height = "240px"),
        insight_box("Insight",
          "Within a single country, loss is rarely uniform: a few states or provinces drive most of the damage (e.g. Par\u00e1 & Mato Grosso in Brazil, Riau & Central Kalimantan in Indonesia). Targeting these subnational hotspots can deliver disproportionate climate benefit."
        )
      )
    )
  )
}

mod_04_hotspots_server <- function(id, subnat_joined) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # ---- Country selector -----------------------------------------------------
    observe({
      ctry <- sort(unique(subnat_joined$country))
      updateSelectInput(session, "country", choices = ctry, selected = "Brazil")
    })

    # ---- Country-level subnational polygons (cached per country) --------------
    polys <- reactive({
      req(input$country)
      shp <- tryCatch(
        rnaturalearth::ne_states(country = input$country, returnclass = "sf"),
        error = function(e) NULL)
      validate(need(!is.null(shp),
                    "No subnational polygons available for this country."))
      shp
    })

    # ---- Filtered slice for current country / year / threshold ----------------
    map_df <- reactive({
      req(input$country)
      subnat_joined %>%
        dplyr::filter(country   == input$country,
                      year      == input$year,
                      threshold == as.integer(input$threshold))
    })

    # ---- Leaflet map ----------------------------------------------------------
    output$map <- leaflet::renderLeaflet({
      shp <- polys(); d <- map_df()
      validate(need(nrow(d) > 0, "No data for this country/year/threshold."))

      name_col <- intersect(c("name_en", "name", "gn_name", "woe_name"),
                            names(shp))[1]
      shp$.match <- shp[[name_col]]

      shp <- shp %>%
        dplyr::left_join(d %>% dplyr::select(subnational1,
                                             value = !!rlang::sym(input$metric)),
                         by = c(".match" = "subnational1"))

      pal <- leaflet::colorNumeric(viridis::viridis(9, option = "D",
                                                    direction = -1),
                                   domain = shp$value, na.color = "#dddddd")
      leaflet::leaflet(shp) %>%
        leaflet::addProviderTiles(leaflet::providers$CartoDB.Positron) %>%
        leaflet::addPolygons(
          fillColor = ~pal(value), weight = 1, color = "white",
          fillOpacity = 0.85,
          label = ~paste0(.match, ": ", scales::comma(round(value))),
          layerId = ~.match,
          highlightOptions = leaflet::highlightOptions(
            weight = 2, color = "#222", bringToFront = TRUE)) %>%
        leaflet::addLegend(pal = pal, values = shp$value,
                           title = input$metric, position = "bottomright")
    })

    # ---- Click \u2192 region time-series ----------------------------------------
    clicked_region <- reactiveVal(NULL)
    observeEvent(input$map_shape_click, {
      clicked_region(input$map_shape_click$id)
    })

    output$region_ts <- renderPlotly({
      r <- clicked_region()
      validate(need(!is.null(r) && nzchar(r),
                    "Click a region on the map to see its time series."))
      ts <- subnat_joined %>%
        dplyr::filter(country == input$country, subnational1 == r,
                      threshold == as.integer(input$threshold))
      validate(need(nrow(ts) > 0, "No time-series available for this region."))
      g <- ggplot(ts, aes(x = year, y = .data[[input$metric]])) +
        geom_col(fill = "#1f6f54") +
        scale_y_continuous(labels = fmt_si) +
        labs(title = paste0(r, " \u2014 ", input$metric),
             x = NULL, y = NULL) +
        plot_theme()
      to_plotly(g)
    })
  })
}
