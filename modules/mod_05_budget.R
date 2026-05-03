# ============================================================================
# Module 5 — Carbon budget (sink vs source)                 Owner: Member E
# Question: Are forests still a net sink, or already a net source?
# ============================================================================

mod_05_budget_ui <- function(id) {
  ns <- NS(id)
  fluidPage(
    module_header(
      chapter  = 5,
      title    = "Sink or source? The carbon budget verdict",
      subtitle = "Net flux = gross emissions − gross removals. Positive values mean the forest system is a net source of carbon."
    ),
    tabsetPanel(id = ns("budget_tab"), type = "pills",
      tabPanel("Single country",
        sidebarLayout(
          sidebarPanel(width = 3,
            sidebar_title("Country"),
            selectInput(ns("country"), label = NULL, choices = NULL),

            threshold_sidebar_title("Threshold"),
            selectInput(ns("threshold"), label = NULL,
                        choices = THRESHOLD_CHOICES, selected = DEFAULT_THRESHOLD),

            tags$hr(),
            helpText("Removals are reported as a single annual average ",
                     "(data limitation), shown as a constant baseline.")
          ),
          mainPanel(width = 9, plotlyOutput(ns("country_plot"), height = "520px"))
        )
      ),
      tabPanel("Country ranking",
        fluidRow(
          column(3, class = "sidebar-panel-like well",
            sidebar_title("Average over years"),
            sliderInput(ns("yrs"), label = NULL,
                        min = 2001, max = 2022, value = c(2018, 2022),
                        step = 1, sep = ""),

            threshold_sidebar_title("Threshold"),
            selectInput(ns("threshold2"), label = NULL,
                        choices = THRESHOLD_CHOICES, selected = DEFAULT_THRESHOLD),

            sidebar_title("Top N"),
            sliderInput(ns("topn"), label = NULL,
                        min = 5, max = 30, value = 15)
          ),
          column(9, plotlyOutput(ns("rank_plot"), height = "520px"))
        )
      )
    ),
    conditionalPanel(
      condition = "input.budget_tab == 'Single country'",
      ns = ns,
      insight_box("Real-time Insight", textOutput(ns("dynamic_insight")))
    ),
    insight_box("Key Insight",
      "Several tropical countries — notably Brazil and Indonesia — have shifted from net sinks to net sources in recent years, driven by record-breaking loss and fires. Large boreal countries (Russia, Canada) and reforesting nations (China, India) remain strong net sinks. The global forest balance is still negative (a net sink), but tropical erosion is steadily narrowing the margin."
    )
  )
}

mod_05_budget_server <- function(id, country_carbon, country_joined) {
  moduleServer(id, function(input, output, session) {

    observe({
      ctry <- sort(unique(country_joined$country))
      updateSelectInput(session, "country", choices = ctry, selected = "Brazil")
    })

    output$country_plot <- renderPlotly({
      req(input$country)
      thr <- as.integer(input$threshold)
      d <- country_joined %>%
        filter(country == input$country, threshold == thr)
      removals_avg <- unique(d$gross_removals)[1]
      d <- d %>%
        mutate(`Gross emissions` = gross_emissions,
               `Gross removals (avg.)` = removals_avg,
               `Net flux` = gross_emissions - removals_avg) %>%
        select(year, `Gross emissions`, `Gross removals (avg.)`, `Net flux`) %>%
        pivot_longer(-year, names_to = "series", values_to = "value")

      g <- ggplot(d, aes(x = year, y = value, colour = series, group = series)) +
        geom_hline(yintercept = 0, linetype = 2, colour = "grey50") +
        geom_line(linewidth = 1) + geom_point(size = 1.4) +
        scale_y_continuous(labels = fmt_si) +
        scale_colour_manual(values = c("Gross emissions" = "#D55E00",
                                       "Gross removals (avg.)" = "#009E73",
                                       "Net flux" = "#0072B2")) +
        labs(title = paste0(input$country, " — forest carbon budget"),
             subtitle = "Mg CO₂e per year",
             x = NULL, y = NULL, colour = NULL,
             caption = "Note: Gross removals are reported as a single annual average (2001–2022) in the source data, shown as a constant baseline.") +
        plot_theme()
      to_plotly(g)
    })

    output$dynamic_insight <- renderText({
      req(input$country)
      thr <- as.integer(input$threshold)
      d <- country_joined %>%
        filter(country == input$country,
               threshold == thr,
               year >= 2018, year <= 2022) %>%
        mutate(net = gross_emissions - gross_removals)

      mean_net <- mean(d$net, na.rm = TRUE)
      req(is.finite(mean_net))

      if (mean_net > 0) {
        paste0(input$country,
               " has become a net carbon source over the past five years (2018-2022), and its forest ecosystem is now a net CO2 emitter.")
      } else {
        paste0(input$country,
               " has remained a net carbon sink over the past five years (2018-2022), and its forest ecosystem is still a net CO2 absorber.")
      }
    })

    output$rank_plot <- renderPlotly({
      thr <- as.integer(input$threshold2)
      d <- country_joined %>%
        filter(threshold == thr,
               year >= input$yrs[1], year <= input$yrs[2]) %>%
        mutate(net = gross_emissions - gross_removals) %>%
        group_by(country) %>%
        summarise(mean_net = mean(net, na.rm = TRUE), .groups = "drop") %>%
        filter(!is.na(mean_net))

      worst <- d %>% slice_max(mean_net, n = input$topn)
      best  <- d %>% slice_min(mean_net, n = input$topn)
      d2 <- bind_rows(
        worst %>% mutate(group = "Net source (highest)"),
        best  %>% mutate(group = "Net sink (lowest)")
      ) %>% mutate(country = forcats::fct_reorder(country, mean_net))

      g <- ggplot(d2, aes(x = country, y = mean_net, fill = group,
                          text = paste0(country, "<br>",
                                        scales::comma(round(mean_net)),
                                        " Mg CO₂e/yr"))) +
        geom_col() + coord_flip() +
        scale_y_continuous(labels = fmt_si) +
        scale_fill_manual(values = c("Net source (highest)" = "#D55E00",
                                     "Net sink (lowest)" = "#1f6f54")) +
        labs(title = paste0("Mean net flux, ", input$yrs[1], "–", input$yrs[2]),
             x = NULL, y = "Mean net flux (Mg CO₂e/yr)", fill = NULL) +
        plot_theme()
      to_plotly(g, tooltip = "text")
    })
  })
}
