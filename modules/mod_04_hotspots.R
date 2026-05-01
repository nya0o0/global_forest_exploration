# ============================================================================
# Module 4 — Subnational hotspots (Leaflet)                  Owner: Member D
# Question: Which subnational regions concentrate loss + emissions?
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
        selectInput(ns("threshold"), "Threshold",
                    choices = THRESHOLD_CHOICES, selected = DEFAULT_THRESHOLD),
        radioButtons(ns("metric"), "Map fill",
                     choices = c("Tree-cover loss (ha)" = "tc_loss_ha",
                                 "Gross emissions"      = "gross_emissions",
                                 "Net flux"             = "net_flux")),
        tags$hr(),
        helpText("Click a region to see its 2001–2022 time-series.")
      ),
      mainPanel(width = 9,
        leafletOutput(ns("map"), height = "520px"),
        plotlyOutput(ns("region_ts"), height = "240px"),
        insight_box("Insight",
          "Within a single country, loss is rarely uniform: a few states or provinces drive most of the damage (e.g. Pará & Mato Grosso in Brazil, Riau & Central Kalimantan in Indonesia). Targeting these subnational hotspots can deliver disproportionate climate benefit."
        )
      )
    )
  )
}

mod_04_hotspots_server <- function(id, subnat_joined) {
  moduleServer(id, function(input, output, session) {

    observe({
      ctry <- sort(unique(subnat_joined$country))
      updateSelectInput(session, "country", choices = ctry, selected = "Brazil")
    })

    polys <- reactive({
      req(input$country)
      sf <- tryCatch(
        rnaturalearth::ne_states(country = input$country, returnclass = "sf"),
        error = function(e) NULL)
      validate(need(!is.null(sf),
                    "No subnational polygons available for this country."))
      sf
    })

    map_df <- reactive({
      req(input$country)
      subnat_joined %>%
        filter(country == input$country,
               year == input$year,
               threshold == as.integer(input$threshold))
    })

    output$map <- renderLeaflet({
      shp <- polys(); d <- map_df()
      name_col <- intersect(c("name_en", "name", "gn_name", "woe_name"),
                            names(shp))[1]
      shp$.match <- shp[[name_col]]

      shp <- shp %>%
        dplyr::left_join(d %>% select(subnational1, value = !!sym(input$metric)),
                         by = c(".match" = "subnational1"))

      pal <- leaflet::colorNumeric(viridis::viridis(9, option = "D", direction = -1),
                                   domain = shp$value, na.color = "#dddddd")
      leaflet(shp) %>%
        addProviderTiles(providers$CartoDB.Positron) %>%
        addPolygons(fillColor = ~pal(value), weight = 1, color = "white",
                    fillOpacity = 0.85,
                    label = ~paste0(.match, ": ",
                                    scales::comma(round(value))),
                    layerId = ~.match,
                    highlightOptions = highlightOptions(weight = 2,
                                                       color = "#222",
                                                       bringToFront = TRUE)) %>%
        addLegend(pal = pal, values = shp$value,
                  title = input$metric, position = "bottomright")
    })

    clicked_region <- reactiveVal(NULL)
    observeEvent(input$map_shape_click, {
      clicked_region(input$map_shape_click$id)
    })

    output$region_ts <- renderPlotly({
      r <- clicked_region()
      validate(need(!is.null(r),
                    "Click a region on the map to see its time series."))
      ts <- subnat_joined %>%
        filter(country == input$country, subnational1 == r,
               threshold == as.integer(input$threshold))
      g <- ggplot(ts, aes(x = year, y = .data[[input$metric]])) +
        geom_col(fill = "#1f6f54") +
        scale_y_continuous(labels = fmt_si) +
        labs(title = paste0(r, " — ", input$metric),
             x = NULL, y = NULL) +
        plot_theme()
      to_plotly(g)
    })
  })
}
