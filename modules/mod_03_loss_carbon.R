# ============================================================================
# Module 3 — Loss ↔ Carbon (bubble scatter + regression)    Owner: Member C
# Question: Is annual loss associated with annual gross emissions?
# ============================================================================

mod_03_loss_carbon_ui <- function(id) {
  ns <- NS(id)
  fluidPage(
    module_header(
      chapter  = 3,
      title    = "Does more loss mean more carbon emissions?",
      subtitle = "Bubble size = forest area in 2000; colour = continent."
    ),
    sidebarLayout(
      sidebarPanel(width = 3,
        sliderInput(ns("year"), "Year",
                    min = 2001, max = 2022, value = 2020, step = 1, sep = ""),
        selectInput(ns("threshold"), threshold_label("Threshold"),
                    choices = THRESHOLD_CHOICES, selected = DEFAULT_THRESHOLD),
        radioButtons(ns("metric"), "Carbon metric (y-axis)",
                     choices = CARBON_METRICS, selected = "gross_emissions"),
        checkboxInput(ns("logaxes"), "Log-scale both axes", TRUE),
        checkboxInput(ns("trend"),   "Show OLS trend line", TRUE),
        tags$hr(),
        tags$div(class = "corr-readout", textOutput(ns("corr_text")))
      ),
      mainPanel(width = 9,
        plotlyOutput(ns("scatter"), height = "560px"),
        insight_box("Insight",
          "Annual tree-cover loss is positively and significantly associated with annual gross forest carbon emissions, especially in tropical countries. Slopes differ by region: a hectare lost in the tropics releases far more carbon than one in temperate zones — a function of biomass density."
        )
      )
    )
  )
}

mod_03_loss_carbon_server <- function(id, country_joined) {
  moduleServer(id, function(input, output, session) {

    df_year <- reactive({
      country_joined %>%
        filter(year == input$year,
               threshold == as.integer(input$threshold),
               !is.na(tc_loss_ha), tc_loss_ha > 0,
               !is.na(.data[[input$metric]])) %>%
        mutate(metric_value = .data[[input$metric]])
    })

    output$corr_text <- renderText({
      r <- loss_carbon_corr(country_joined, input$year,
                            as.integer(input$threshold))
      if (is.na(r)) return("Pearson r: not enough data")
      sprintf("Pearson r (loss × gross emissions) = %.2f", r)
    })

    output$scatter <- renderPlotly({
      d <- df_year()
      validate(need(nrow(d) > 0, "No data for this combination."))
      if (input$logaxes && input$metric == "gross_emissions")
        d <- d %>% filter(metric_value > 0)

      metric_label <- names(CARBON_METRICS)[CARBON_METRICS == input$metric]

      g <- ggplot(d, aes(x = tc_loss_ha, y = metric_value,
                         size = extent_2000_ha, colour = continent,
                         text = paste0(country, "<br>",
                                       "Loss: ", scales::comma(round(tc_loss_ha)), " ha<br>",
                                       metric_label, ": ",
                                       scales::comma(round(metric_value))))) +
        geom_point(alpha = 0.75) +
        scale_size_area(max_size = 14, labels = fmt_si, name = "Forest 2000 (ha)") +
        scale_colour_manual(values = PALETTE_REGION, name = "Continent") +
        labs(title = paste0("Forest loss vs. ", metric_label, " · ", input$year),
             x = "Tree-cover loss (ha)", y = metric_label) +
        plot_theme()

      if (input$logaxes) {
        g <- g + scale_x_log10(labels = fmt_si)
        if (input$metric != "net_flux") g <- g + scale_y_log10(labels = fmt_si)
      } else {
        g <- g + scale_x_continuous(labels = fmt_si) +
                 scale_y_continuous(labels = fmt_si)
      }

      if (input$trend) {
        g <- g + geom_smooth(
          data = d, inherit.aes = FALSE,
          aes(x = tc_loss_ha, y = metric_value),
          method = "lm", formula = y ~ x,
          colour = "grey20", linetype = 2,
          se = FALSE, linewidth = 0.6, show.legend = FALSE)
      }
      to_plotly(g, tooltip = "text")
    })
  })
}
