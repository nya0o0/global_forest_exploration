# ============================================================================
# Module 1 — Global overview (ranking bar chart)            Owner: Member A
# Question: Where is forest tree-cover loss concentrated?
# ============================================================================

mod_01_overview_ui <- function(id) {
  ns <- NS(id)
  fluidPage(
    module_header(
      chapter  = 1,
      title    = "Where is the world losing its forests?",
      subtitle = "A handful of countries account for the majority of global loss."
    ),
    sidebarLayout(
      sidebarPanel(width = 3,
        sliderInput(ns("year"), "Year",
                    min = 2001, max = 2022, value = 2022, step = 1, sep = "",
                    animate = animationOptions(interval = 800, loop = FALSE)),
        selectInput(ns("threshold"), "Tree-cover density threshold",
                    choices = THRESHOLD_CHOICES, selected = DEFAULT_THRESHOLD),
        sliderInput(ns("topn"), "Top N countries",
                    min = 5, max = 25, value = 10, step = 1),
        helpText("Tip: drag the year slider or hit play to scan 2001–2022."),
        tags$hr(),
        downloadButton(ns("download"), "Download data shown")
      ),
      mainPanel(width = 9,
        plotlyOutput(ns("bar"), height = "560px"),
        insight_box("Insight",
          "Just 5–6 countries (Brazil, Indonesia, the DRC, Russia, Canada, the USA) typically account for >60 % of annual global loss — global forest loss is geographically unequal."
        )
      )
    )
  )
}

mod_01_overview_server <- function(id, country_loss) {
  moduleServer(id, function(input, output, session) {

    top_df <- reactive({
      top_countries_loss(country_loss,
                         year_sel      = input$year,
                         threshold_sel = as.integer(input$threshold),
                         n             = input$topn)
    })

    output$bar <- renderPlotly({
      d <- top_df()
      validate(need(nrow(d) > 0, "No data for the selected combination."))
      d <- d %>%
        mutate(country = forcats::fct_reorder(country, tc_loss_ha),
               text = paste0(country, "<br>",
                             scales::comma(round(tc_loss_ha)), " ha"))
      g <- ggplot(d, aes(x = country, y = tc_loss_ha,
                         text = text, fill = tc_loss_ha)) +
        geom_col() + coord_flip() +
        scale_y_continuous(labels = fmt_si) +
        scale_fill_viridis_c(option = "D", direction = -1, guide = "none") +
        labs(title    = paste0("Top ", input$topn,
                               " countries by tree-cover loss · ", input$year),
             subtitle = paste0("Tree-cover density threshold ≥ ",
                               input$threshold, "%"),
             x = NULL, y = "Tree-cover loss (ha)") +
        plot_theme()
      to_plotly(g, tooltip = "text")
    })

    output$download <- downloadHandler(
      filename = function() paste0("top_loss_", input$year,
                                   "_thr", input$threshold, ".csv"),
      content  = function(file) write.csv(top_df(), file, row.names = FALSE)
    )
  })
}
