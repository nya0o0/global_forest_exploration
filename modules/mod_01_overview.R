# Module 1 — Global overview (ranking bar chart)            Owner: CHEN, Yanyu
# Question: Where is forest tree-cover loss concentrated?

mod_01_overview_ui <- function(id) {
  ns <- NS(id)
  fluidPage(
    module_header(
      chapter  = 1,
      title    = "Where is the world losing its forests?",
      subtitle = "A handful of countries account for the majority of global loss \u2014 and only a few of them gain back what they lose."
    ),
    # Create side bar
    sidebarLayout(
      sidebarPanel(width = 3,
                   sliderInput(ns("year"), "Year",
                               min = 2001, max = 2022, value = 2022, step = 1, sep = "",
                               animate = animationOptions(interval = 800, loop = FALSE)), # Year slider
                   selectInput(ns("threshold"), threshold_label("Tree-cover density threshold"),
                               choices = THRESHOLD_CHOICES, selected = DEFAULT_THRESHOLD), # A dropdown to choose tree-cover density threshold
                   sliderInput(ns("topn"), "Top N countries",
                               min = 5, max = 25, value = 10, step = 1), # Top N slider
                   helpText("Tip: drag the year slider or hit play to scan 2001\u20132022, choose your preferred tree-cover density threshold and the number of top countries you want to see."),
                   tags$hr(),
                   downloadButton(ns("download"), "Download data shown") # Down load button
      ),
      # Create the main panel
      mainPanel(width = 9,
                # Top: yearly ranking
                plotlyOutput(ns("bar"), height = "520px"), # Fixed height
                insight_box("Insight",
                            "Just 5\u20136 countries (Brazil, Indonesia, the DRC, Russia, Canada, the USA) typically account for >60\u202f% of annual global loss \u2014 global forest loss is geographically unequal."
                ),
                # collapsible country profiles
                tags$details(class = "country-profiles",
                             tags$summary(tags$b("Who are these countries? "),
                                          tags$small(class = "text-muted",
                                                     "\u2014 click to expand brief profiles of the recurring top-10")),
                             tags$div(class = "country-grid",
                                      tags$div(class = "country-card",
                                               tags$h5("\U0001F1E7\U0001F1F7 Brazil"),
                                               tags$p(tags$small(tags$b("Tropical \u00b7 Amazon biome."),
                                                                 " The world\u2019s largest rainforest nation. Loss is dominated by ",
                                                                 "cattle-ranching and soy expansion in the Amazon and Cerrado, ",
                                                                 "plus seasonal fires. Annual loss spiked under weakened enforcement ",
                                                                 "(2019\u20132022) and fell sharply afterwards."))),
                                      tags$div(class = "country-card",
                                               tags$h5("\U0001F1F7\U0001F1FA Russia"),
                                               tags$p(tags$small(tags$b("Boreal \u00b7 Taiga biome."),
                                                                 " Hosts ~20\u202f% of the world\u2019s forest. Most \u201closs\u201d here is ",
                                                                 "large-scale wildfire in Siberia and the Far East, plus commercial ",
                                                                 "logging. Because boreal forests regenerate, gain partially offsets loss."))),
                                      tags$div(class = "country-card",
                                               tags$h5("\U0001F1E8\U0001F1E6 Canada"),
                                               tags$p(tags$small(tags$b("Boreal \u00b7 Taiga & temperate."),
                                                                 " Loss is mostly from wildfire (BC, Alberta, NWT) and commercial ",
                                                                 "logging. Like Russia, much of this regrows \u2014 boreal forests are ",
                                                                 "the closest thing to a \u201cbalanced\u201d loss/gain profile."))),
                                      tags$div(class = "country-card",
                                               tags$h5("\U0001F1EE\U0001F1E9 Indonesia"),
                                               tags$p(tags$small(tags$b("Tropical \u00b7 Rainforest & peatland."),
                                                                 " Loss driven by oil-palm and pulpwood plantations across Sumatra, ",
                                                                 "Borneo (Kalimantan) and Papua, plus peat fires. A 2018 moratorium ",
                                                                 "and corporate \u201cno-deforestation\u201d pledges drove the trend down post-2017."))),
                                      tags$div(class = "country-card",
                                               tags$h5("\U0001F1E8\U0001F1E9 DR Congo"),
                                               tags$p(tags$small(tags$b("Tropical \u00b7 Congo Basin."),
                                                                 " The world\u2019s second-largest rainforest. Loss is mainly from ",
                                                                 "smallholder shifting agriculture and charcoal demand around cities, ",
                                                                 "with rising industrial logging. Trend is steadily upward."))),
                                      tags$div(class = "country-card",
                                               tags$h5("\U0001F1FA\U0001F1F8 United States"),
                                               tags$p(tags$small(tags$b("Mixed \u00b7 Temperate & boreal."),
                                                                 " Loss is dominated by commercial timber rotations in the SE ",
                                                                 "\u201cwood basket\u201d (GA, AL, MS) and large wildfires in the West. ",
                                                                 "Net of replanting, loss and gain are roughly comparable."))),
                                      tags$div(class = "country-card",
                                               tags$h5("\U0001F1E7\U0001F1F4 Bolivia"),
                                               tags$p(tags$small(tags$b("Tropical \u00b7 Amazon & Chiquitano."),
                                                                 " One of the fastest-rising hotspots: cattle and soy frontier in ",
                                                                 "Santa Cruz, plus mega-fires in 2019\u20132023 (Chiquitano dry forest)."))),
                                      tags$div(class = "country-card",
                                               tags$h5("\U0001F1F5\U0001F1FE Paraguay"),
                                               tags$p(tags$small(tags$b("Tropical \u00b7 Gran Chaco."),
                                                                 " Highest deforestation rate per capita in South America \u2014 ",
                                                                 "large-scale conversion of dry Chaco forest to cattle ranches ",
                                                                 "and soy."))),
                                      tags$div(class = "country-card",
                                               tags$h5("\U0001F1F2\U0001F1FE Malaysia"),
                                               tags$p(tags$small(tags$b("Tropical \u00b7 Rainforest."),
                                                                 " Sustained loss from oil-palm expansion in Sabah & Sarawak (Borneo). ",
                                                                 "Trend has slowed since 2017 as accessible lowland forest is exhausted."))),
                                      tags$div(class = "country-card",
                                               tags$h5("\U0001F1F8\U0001F1EA Sweden / \U0001F1EB\U0001F1EE Finland"),
                                               tags$p(tags$small(tags$b("Boreal \u00b7 Managed timber."),
                                                                 " Most \u201closs\u201d is rotational clear-cutting on production forest ",
                                                                 "that is replanted within a few years \u2014 visible as loss in this dataset ",
                                                                 "but not permanent deforestation."))),
                                      tags$div(class = "country-card",
                                               tags$h5("\U0001F1E6\U0001F1F7 Argentina"),
                                               tags$p(tags$small(tags$b("Tropical/subtropical \u00b7 Gran Chaco."),
                                                                 " Soy and cattle frontier in the northern Chaco provinces; ",
                                                                 "loss has decelerated since native-forest law (2007) but remains high."))),
                                      tags$div(class = "country-card",
                                               tags$h5("\U0001F1F2\U0001F1FF Mozambique"),
                                               tags$p(tags$small(tags$b("Tropical \u00b7 Miombo woodland."),
                                                                 " Loss from charcoal production, smallholder farming and ",
                                                                 "recent commercial agriculture; cyclones (Idai, 2019) added pulses.")))
                             )
                ),
                # Bottom: cumulative Loss vs Gain comparison
                tags$hr(style = "margin: 2rem 0;"),
                tags$h4("Loss vs gain \u2014 same countries, two decades"),
                tags$p(class = "text-muted",
                       tags$small("Top: cumulative tree-cover loss 2001\u20132022. ",
                                  "Bottom: cumulative tree gain 2000\u20132020 ",
                                  "Note the two panels use independent x-axis scales.")),
                plotlyOutput(ns("loss_gain"), height = "520px"),
                insight_box("Insight",
                            "Loss and gain are far from balanced. Boreal countries (Russia, Canada) come close to recovering what they lose, but tropical hotspots (Brazil, Indonesia, DRC, Bolivia, Paraguay) lose 5\u201310\u00d7 more than they regain \u2014 a structural deficit that drives the global net carbon flux you'll see in Chapters 3 and 5."
                )
      )
    )
  )
}

# Server function setup
mod_01_overview_server <- function(id, country_loss) {
  moduleServer(id, function(input, output, session) {
    
    # Top chart: yearly ranking (existing logic)
    # Defines a reactive expression top_df that filters/aggregates country_loss via top_countries_loss() for the selected year, threshold, and top‑N.
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
                             scales::comma(round(tc_loss_ha)), " ha")) # Reorders country factor levels by loss magnitude for plotting, and creates a text field used as a hover tooltip (country + formatted loss in ha).
      # Builds a ggplot object
      g <- ggplot(d, aes(x = country, y = tc_loss_ha,
                         text = text, fill = tc_loss_ha)) +
        geom_col() + coord_flip() +
        scale_y_continuous(labels = fmt_si) +
        scale_fill_viridis_c(option = "D", direction = -1, guide = "none") +
        labs(title    = paste0("Top ", input$topn,
                               " countries by tree-cover loss \u00b7 ", input$year),
             subtitle = paste0("Tree-cover density threshold \u2265 ",
                               input$threshold, "%"),
             x = NULL, y = "Tree-cover loss (ha)") +
        plot_theme()
      to_plotly(g, tooltip = "text") # Converts the ggplot object into an interactive Plotly object
    })
    
    # Bottom chart: 22-yr cumulative Loss vs 20-yr Gain
    loss_gain_df <- reactive({
      thr <- as.integer(input$threshold)
      # Filters country_loss to the selected threshold, groups by country, and computes total loss and total gain
      country_loss %>%
        dplyr::filter(threshold == thr) %>% 
        dplyr::group_by(country) %>% 
        dplyr::summarise(
          loss_total = sum(tc_loss_ha, na.rm = TRUE),
          gain_total = dplyr::first(`gain_2000-2020_ha`),
          .groups = "drop") %>%
        dplyr::filter(!is.na(gain_total)) %>% # Removes countries with missing gain data
        dplyr::arrange(dplyr::desc(loss_total)) %>% #  sorts by descending total loss
        head(input$topn) # only the top‑N selected
    })
    # Begins the server logic
    output$loss_gain <- renderPlotly({
      d <- loss_gain_df()
      validate(need(nrow(d) > 0, "No data for the selected threshold."))
      
      lvls <- d$country[order(d$loss_total)]
      # Reshapes the data from wide to long format
      long <- d %>%
        tidyr::pivot_longer(c(loss_total, gain_total),
                            names_to = "type", values_to = "value") %>%
        dplyr::mutate(
          type = dplyr::recode(type,
                               loss_total = "Tree-cover loss (2001\u20132022)",
                               gain_total = "Tree gain (2000\u20132020)"),
          type = factor(type,
                        levels = c("Tree-cover loss (2001\u20132022)",
                                   "Tree gain (2000\u20132020)")),
          country = factor(country, levels = lvls),
          text = paste0(country, "<br>",
                        scales::comma(round(value)), " ha"))
      
      g <- ggplot(long, aes(x = country, y = value, fill = type, text = text)) +
        geom_col() + coord_flip() +
        # Facets by type into two panels (loss and gain) with independent x-scales
        facet_wrap(~ type, ncol = 2, scales = "free_x") +
        scale_y_continuous(labels = fmt_si) +
        scale_fill_manual(values = c(
          "Tree-cover loss (2001\u20132022)" = "#c0392b",
          "Tree gain (2000\u20132020)"        = "#27ae60"), #  red for loss, green for gain
          guide = "none") +
        labs(title    = paste0("Cumulative loss vs gain \u00b7 Top ",
                               input$topn, " forest-losing countries"),
             subtitle = paste0("Threshold \u2265 ", input$threshold,
                               "%. Two panels use independent x-axis scales."),
             x = NULL, y = "Hectares") +
        plot_theme() +
        theme(strip.text = element_text(face = "bold"))
      to_plotly(g, tooltip = "text")
    })
    
    # Download (top-N for current year)
    output$download <- downloadHandler(
      # Generates a dynamic filename based on current year and threshold
      filename = function() paste0("top_loss_", input$year,
                                   "_thr", input$threshold, ".csv"),
      # Writes the current top_df() reactive data to the specified file as a CSV
      content  = function(file) write.csv(top_df(), file, row.names = FALSE)
    )
  })
}
