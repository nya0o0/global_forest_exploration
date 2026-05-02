# ============================================================================
# Module 2 — Time trends (multi-country line chart)          Owner: Member B
# Question: How has loss in key countries evolved 2001–2022?
# ============================================================================

mod_02_trends_ui <- function(id) {
  ns <- NS(id)
  fluidPage(
    module_header(
      chapter  = 2,
      title    = "Trajectories of forest loss, 2001 – 2022",
      subtitle = "Loss is not a smooth line — turning points reveal policy, fire, and economic shocks."
    ),
    sidebarLayout(
      sidebarPanel(width = 3,
        selectizeInput(ns("countries"), "Countries", choices = NULL,
                       multiple = TRUE,
                       options = list(plugins = list("remove_button"))),
        sliderInput(ns("years"), "Year range",
                    min = 2001, max = 2022,
                    value = c(2001, 2022), step = 1, sep = ""),
        selectInput(ns("threshold"), threshold_label("Threshold"),
                    choices = THRESHOLD_CHOICES, selected = DEFAULT_THRESHOLD),
        checkboxInput(ns("annotate"), "Highlight key turning points", TRUE),
        tags$hr(),
        helpText("Defaults show the five largest losers worldwide.")
      ),
      mainPanel(width = 9,
        plotlyOutput(ns("line"), height = "560px"),
        insight_box("Insight",
          "Brazil's loss fell sharply 2004–2012 after the PPCDAm action plan, then rebounded after 2018. Indonesia peaked in 2016 driven by fires, then declined under the moratorium. Each turning point coincides with policy or environmental shocks."
        )
      )
    )
  )
}

mod_02_trends_server <- function(id, country_loss) {
  moduleServer(id, function(input, output, session) {

    observe({
      all_countries <- sort(unique(country_loss$country))
      default_top5 <- country_loss %>%
        filter(threshold == DEFAULT_THRESHOLD) %>%
        group_by(country) %>%
        summarise(total = sum(tc_loss_ha, na.rm = TRUE)) %>%
        slice_max(total, n = 5) %>% pull(country)
      updateSelectizeInput(session, "countries",
                           choices = all_countries,
                           selected = default_top5,
                           server = TRUE)
    })

    series <- reactive({
      req(input$countries)
      country_time_series(country_loss,
                          countries     = input$countries,
                          threshold_sel = as.integer(input$threshold),
                          year_min      = input$years[1],
                          year_max      = input$years[2])
    })

    output$line <- renderPlotly({
      d <- series()
      validate(need(nrow(d) > 0, "Pick at least one country."))
      d <- d %>%
        mutate(text = paste0(country, " · ", year, "<br>",
                             scales::comma(round(tc_loss_ha)), " ha"))
      g <- ggplot(d, aes(x = year, y = tc_loss_ha,
                         colour = country, group = country, text = text)) +
        geom_line(linewidth = 0.9) + geom_point(size = 1.2) +
        scale_y_continuous(labels = fmt_si) +
        scale_x_continuous(breaks = seq(2001, 2022, 3)) +
        labs(title = "Annual tree-cover loss",
             subtitle = paste0("Threshold ≥ ", input$threshold, "%"),
             x = NULL, y = "Tree-cover loss (ha)", colour = NULL) +
        plot_theme()

      if (isTRUE(input$annotate)) {
        anno <- tibble::tribble(
          ~country,    ~year, ~label,
          "Brazil",    2012,  "PPCDAm low",
          "Brazil",    2019,  "Post-2018 rebound",
          "Indonesia", 2016,  "El Niño fires"
        ) %>%
          inner_join(d %>% select(country, year, tc_loss_ha),
                     by = c("country", "year"))
        if (nrow(anno) > 0)
          g <- g + ggplot2::geom_text(
            data = anno, inherit.aes = FALSE,
            aes(x = year, y = tc_loss_ha, label = label, colour = country),
            vjust = -1.2, size = 3, show.legend = FALSE)
      }
      to_plotly(g, tooltip = "text")
    })
  })
}
