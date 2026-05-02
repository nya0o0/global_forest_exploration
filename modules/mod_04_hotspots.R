# ============================================================================
# Module 4 — Subnational hotspots (Leaflet)                  Owner: LI, Yuan
# Question: Which subnational regions concentrate loss + emissions?
# ============================================================================

mod_04_hotspots_ui <- function(id) {
  ns <- NS(id)
  fluidPage(
    module_header(
      chapter  = 4,
      title    = "Zooming in: subnational hotspots",
      subtitle = "Identify exact regions driving the crisis. Are we losing the most massive forests, or are smaller regions disappearing fastest?"
    ),
    sidebarLayout(
      sidebarPanel(width = 3,
                   selectInput(ns("country"), "Scope (Global or Country)", choices = NULL),
                   sliderInput(ns("year"), "Year",
                               min = 2001, max = 2022, value = 2022, step = 1, sep = ""),
                   selectInput(ns("threshold"), "Tree-cover threshold",
                               choices = THRESHOLD_CHOICES, selected = DEFAULT_THRESHOLD),
                   radioButtons(ns("metric"), "Map & Chart metric",
                                choices = c("Tree-cover loss (ha)" = "tc_loss_ha",
                                            "Loss rate (% of 2000 extent)" = "loss_pct",
                                            "Gross emissions (Mg CO₂e)" = "gross_emissions",
                                            "Net flux (Mg CO₂e)" = "net_flux")),
                   tags$hr(),
                   helpText("👆 Tip: Switch to 'Loss rate (%)' to find regions losing forest at the fastest relative pace."),
                   helpText("🖱️ Click any region on the map to see its full 2001–2022 history below.")
      ),
      mainPanel(width = 9,
                leafletOutput(ns("map"), height = "450px"),
                tags$br(),
                fluidRow(
                  column(6, plotlyOutput(ns("top_rank"), height = "260px")),
                  column(6, plotlyOutput(ns("region_ts"), height = "260px"))),
                insight_box("Insight",
                            HTML("Hotspots cluster heavily in Russia (Sakha, Krasnoyarsk, Irkutsk), Brazil (Para, Mato Grosso, Santa Cruz, Amazonas), 
                            Canada (Saskatchewan, Alberta, British Columbia), and US (Alaska).<br>
                            Notice how switching from absolute 'Tree-cover loss (ha)' to relative 'Loss rate (%)' 
                                 shifts the spotlight: some smaller provinces are being deforested at alarming speeds relative to 
                                 their baseline size, pushing their carbon flux deep into 'Net Source' territory."))
      )
    )
  )
}

mod_04_hotspots_server <- function(id, subnat_joined) {
  moduleServer(id, function(input, output, session) {
    
    observe({
      ctry <- sort(unique(subnat_joined$country))
      choices_list <- c("🌍 Global View", ctry)
      updateSelectInput(session, "country", choices = choices_list, selected = "🌍 Global View")
    })
    
    polys <- reactive({
      req(input$country)
      if (input$country == "🌍 Global View") {
        sf <- tryCatch(rnaturalearth::ne_states(returnclass = "sf"), error = function(e) NULL)
      } else {
        sf <- tryCatch(rnaturalearth::ne_states(country = input$country, returnclass = "sf"), error = function(e) NULL)
      }
      validate(need(!is.null(sf), "Spatial boundaries currently unavailable."))
      sf
    })
    
    map_df <- reactive({
      req(input$country)
      d <- subnat_joined %>%
        filter(year == input$year, threshold == as.integer(input$threshold)) %>%
        mutate(
          loss_pct = ifelse(extent_2000_ha > 0, (tc_loss_ha / extent_2000_ha) * 100, NA),
          net_flux = gross_emissions - gross_removals)
      
      if (input$country != "🌍 Global View") { d <- d %>% filter(country == input$country)}
      d
    })
    
    output$map <- renderLeaflet({
      shp <- polys()
      d <- map_df()
      req(nrow(d) > 0)
      
      name_col <- intersect(c("name_en", "name", "gn_name", "woe_name"), names(shp))[1]
      admin_col <- intersect(c("admin", "sovereignt", "geounit"), names(shp))[1]
      
      clean_name <- function(x) {
        x <- tolower(as.character(x))
        x <- gsub("['`’]", "", x)                  
        x <- gsub("\\s*\\(.*?\\)", "", x)         
        x <- gsub(" republic| oblast| krai| province| state| region| autonomous okrug| okrug | autonomous| uygur| zhuang| hui", "", x)
        trimws(x)}
      
      clean_country <- function(x) {
        x <- as.character(x)
        x[x == "United States of America"] <- "United States"
        x[x == "Russian Federation"] <- "Russia"
        x}
      
      shp$.subnat_match <- clean_name(shp[[name_col]])
      shp$.country_match <- clean_country(shp[[admin_col]])
      shp$.layer_id <- paste(shp$.country_match, shp$.subnat_match, sep = "||")
      
      d <- d %>% mutate(.layer_id = paste(country, clean_name(subnational1), sep = "||"))
      
      shp <- shp %>%
        dplyr::left_join(d %>% select(.layer_id, value = !!sym(input$metric), original_name = subnational1) %>%
                           distinct(.layer_id, .keep_all = TRUE), by = ".layer_id", relationship = "many-to-many")
      
      if (input$metric == "net_flux") {
        pal <- leaflet::colorNumeric("RdYlBu", domain = shp$value, reverse = TRUE, na.color = "transparent")
      } else {
        pal <- leaflet::colorNumeric(viridis::viridis(9, option = "rocket", direction = -1),
                                     domain = shp$value, na.color = "transparent")
      }
      
      metric_label <- names(which(c("Tree-cover loss (ha)" = "tc_loss_ha",
                                    "Loss rate (%)" = "loss_pct",
                                    "Gross emissions" = "gross_emissions",
                                    "Net flux" = "net_flux") == input$metric))
      
      leaflet(shp) %>%
        addProviderTiles(providers$CartoDB.Positron) %>%
        addPolygons(fillColor = ~pal(value), weight = 0.5, color = "#999",
                    fillOpacity = ~ifelse(is.na(value), 0, 0.85),
                    label = ~paste0(.country_match, " - ", ifelse(is.na(original_name), shp[[name_col]], original_name), ": ", 
                                    ifelse(is.na(value), "No data", scales::comma(round(value, 2)))),
                    layerId = ~.layer_id, 
                    highlightOptions = highlightOptions(weight = 2, color = "#000", bringToFront = TRUE)) %>%
        addLegend(pal = pal, values = shp$value, title = metric_label, position = "bottomright")
    })
    
    clicked_region <- reactiveVal(NULL)
    observeEvent(input$map_shape_click, { clicked_region(input$map_shape_click$id) })
    
    output$top_rank <- renderPlotly({
      metric_sym <- input$metric
      
      d <- map_df() %>%
        group_by(country, subnational1) %>%
        summarise(metric_val = mean(!!sym(metric_sym), na.rm = TRUE), .groups = "drop") %>%
        filter(!is.na(metric_val)) %>%
        arrange(desc(metric_val)) %>%
        slice_head(n = 10)
      
      if (input$country == "🌍 Global View") {
        d <- d %>% mutate(label_name = paste0(subnational1, " (", substr(country, 1, 3), ")"))
      } else {
        d <- d %>% mutate(label_name = subnational1)
      }
      
      d <- d %>%
        mutate(
          label_name = forcats::fct_reorder(label_name, metric_val),
          hover_text = paste0(label_name, "<br>Value: ", scales::comma(round(metric_val))))
      
      validate(need(nrow(d) > 0, "No data to rank."))
      
      g <- ggplot(d, aes(x = metric_val, y = label_name, fill = metric_val, text = hover_text)) +
        geom_col() + 
        scale_fill_viridis_c(option = "rocket", direction = -1, guide = "none") +
        scale_x_continuous(labels = fmt_si) +
        labs(title = paste("Top 10 Regions -", input$year), x = NULL, y = NULL) +
        plot_theme() +
        theme(axis.text.y = element_text(size = 10))
      
      to_plotly(g, tooltip = "text")
    })
    
    output$region_ts <- renderPlotly({
      r_id <- clicked_region()
      validate(need(!is.null(r_id), "👈 Click a region on the map to see its timeline."))
      
      parts <- strsplit(r_id, "\\|\\|")[[1]]
      c_click <- parts[1]
      s_click_clean <- parts[2]
      
      clean_name <- function(x) {
        x <- tolower(as.character(x))
        x <- gsub("['`’]", "", x)
        x <- gsub("\\s*\\(.*?\\)", "", x)
        x <- gsub(" republic| oblast| krai| province| state| region| autonomous okrug| okrug | autonomous| uygur| zhuang| hui", "", x)
        trimws(x)}
      
      ts <- subnat_joined %>%
        filter(country == c_click, clean_name(subnational1) == s_click_clean, threshold == as.integer(input$threshold)) %>%
        mutate(
          loss_pct = ifelse(extent_2000_ha > 0, (tc_loss_ha / extent_2000_ha) * 100, NA),
          net_flux = gross_emissions - gross_removals)
      
      validate(need(nrow(ts) > 0, "No temporal data available for this region."))
      
      display_name <- ts$subnational1[1]
      
      g <- ggplot(ts, aes(x = year, y = !!sym(input$metric))) +
        geom_col(fill = "#1f6f54", alpha = 0.8) +
        geom_smooth(method = "loess", se = FALSE, color = "#D55E00", linewidth = 0.8) +
        scale_y_continuous(labels = fmt_si) +
        labs(title = paste(display_name, "Timeline"), x = NULL, y = NULL) +
        plot_theme()
      
      to_plotly(g)
    })
  })
}
