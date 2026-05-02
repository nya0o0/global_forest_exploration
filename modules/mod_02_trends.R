# ============================================================================
# Module 2 — Time trends (multi-country line chart)          Owner: Member B
# Question: How has loss in key countries evolved 2001–2022?
# ============================================================================


mod_02_trends_ui <- function(id) {
  ns <- NS(id)
  fluidPage(
    module_header(
      chapter = 2,
      title = "World Forest Loss Trajectories, 2001 – 2022",
      subtitle = "Loss is not a smooth line — turning points reveal policy, fire or economic shocks."
    ),
    sidebarLayout(
      sidebarPanel(width = 3,
                   tags$div(class = "sidebar-title", "Select countries/regions"),
                   selectizeInput(ns("countries"), label = NULL,
                                  choices = NULL,
                                  multiple = TRUE,
                                  options = list(
                                    plugins = list("remove_button"),
                                    placeholder = "Search and select..."
                                  )),
                   
                   tags$div(class = "sidebar-title", "Year range"),
                   sliderInput(ns("years"), label = NULL,
                               min = 2001, max = 2022,
                               value = c(2001, 2022), step = 1, sep = ""),
                   
                   tags$div(class = "sidebar-title", "Threshold"),
                   selectInput(ns("threshold"), label = NULL,
                               choices = THRESHOLD_CHOICES, 
                               selected = DEFAULT_THRESHOLD),
                   
                   tags$hr(),
                   helpText("Defaults show the five largest losers worldwide.")
      ),
      mainPanel(width = 9,
                plotlyOutput(ns("line"), height = "560px"),
                uiOutput(ns("insight_ui"))
      )
    )
  )
}

mod_02_trends_server <- function(id, country_loss) {
  moduleServer(id, function(input, output, session) {
    
    # ====================== Event Insights Database (Updated) ======================
    EVENT_INSIGHTS <- list(
      "Brazil" = "Brazil experienced a sharp decline in forest loss after the launch of the PPCDAm action plan in 2004, reaching its lowest point around 2012. However, loss rebounded significantly after 2018 due to policy relaxation and increased pressures.",
      "Indonesia" = "Indonesia saw a major peak in tree-cover loss in 2015–2016 driven by severe El Niño fires. Loss declined substantially in later years thanks to the peatland moratorium, improved fire management, and stronger law enforcement.",
      "Russia" = "Russia has the highest fire-related tree-cover loss among all countries. Severe boreal forest wildfires occurred in multiple years, notably 2010 and 2019–2021, contributing to large-scale loss in the taiga.",
      "Canada" = "Canada experiences significant boreal forest wildfires. Major fire seasons within 2001–2022 caused substantial tree-cover loss, with fire being the dominant driver in its northern forests.",
      "United States" = "The United States, particularly in the western regions, has suffered increasing tree-cover loss from large wildfires and bark beetle outbreaks, exacerbated by climate conditions.",
      "Democratic Republic of the Congo" = "The Democratic Republic of the Congo has shown a relatively steady increase in forest loss throughout 2001–2022, primarily driven by small-scale agriculture and charcoal production.",
      "Bolivia" = "Bolivia recorded several record-high forest loss years, notably around 2010, 2019 and 2020, linked to agricultural expansion (soy and cattle ranching) and severe fires.",
      "Malaysia" = "Malaysia's forest loss has been heavily influenced by oil palm expansion. Government moratoriums on new plantations and the MSPO sustainable palm oil certification helped stabilize loss rates in later years.",
      "Colombia" = "Colombia saw a spike in deforestation after the 2016 peace agreement due to land grabbing and agricultural expansion, followed by renewed conservation efforts in recent years.",
      "Peru" = "Peru’s forest loss has been driven by gold mining, cocoa, and oil palm expansion, particularly in the Madre de Dios region.",
      "China" = "China has implemented large-scale reforestation and strict forest protection policies, resulting in net forest gains in many regions despite some local development pressures.",
      "Paraguay" = "Paraguay experienced rapid forest loss in the Chaco region, mainly due to cattle ranching and soy expansion.",
      "Madagascar" = "Madagascar has one of the highest proportional forest loss rates, driven by slash-and-burn agriculture, illegal logging, and charcoal production.",
      "Laos" = "Laos has seen significant forest loss due to rubber plantations and other cash crop expansion.",
      "Myanmar" = "Myanmar experienced increased logging and agricultural pressure following political transitions.",
      "Cote d'Ivoire" = "Côte d'Ivoire has high rates of forest loss, largely driven by cocoa plantation expansion.",
      "Finland" = "Finland’s forest loss is mainly from managed commercial forestry, with occasional wildfires in its boreal forests.",
      "Mozambique" = "Mozambique’s forest loss is primarily driven by charcoal production and small-scale agricultural expansion.",
      "Vietnam" = "Vietnam has undergone rapid rubber and cash crop plantation expansion, though reforestation efforts have increased in recent years.",
      "Angola" = "Angola has seen forest loss linked to post-conflict agricultural recovery and logging activities.",
      "Chile" = "Chile experienced major wildfires in 2017, particularly affecting commercial plantation forests.",
      "Tanzania" = "Tanzania’s forest loss is mainly driven by charcoal production and agricultural expansion.",
      "India" = "India shows a mixed picture with strong protection policies in some areas alongside development pressures in others.",
      "Argentina" = "Argentina has experienced significant forest loss, particularly in the Gran Chaco region, driven by agricultural expansion (soybeans) and cattle ranching.",
      "Sweden" = "Sweden’s forest loss is mainly from managed commercial forestry operations in its boreal forests, with relatively stable trends.",
      "Australia" = "Australia experiences periodic spikes in tree-cover loss due to severe bushfires, most notably during the 2019–2020 Black Summer fires."
    )
    # =====================================================================
    
    # Default top 5 countries
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
    
    # Data series
    series <- reactive({
      req(input$countries)
      country_time_series(country_loss,
                          countries = input$countries,
                          threshold_sel = as.integer(input$threshold),
                          year_min = input$years[1],
                          year_max = input$years[2])
    })
    
    # Insight UI
    output$insight_ui <- renderUI({
      req(input$countries)
      
      insight_list <- lapply(input$countries, function(cn) {
        title <- paste0("Insight — ", cn)
        
        if (cn %in% names(EVENT_INSIGHTS)) {
          content <- HTML(EVENT_INSIGHTS[[cn]])
          div(class = "insight-box insight-has-data",
              tags$h4(icon("lightbulb"), " ", title),
              tags$p(content))
        } else {
          content <- "Sorry, no event information available for this country/region yet."
          div(class = "insight-box insight-no-data",
              tags$h4(icon("lightbulb"), " ", title),
              tags$p(content))
        }
      })
      
      tagList(insight_list)
    })
    
    # ==================== Optimized Line Chart ====================
    output$line <- renderPlotly({
      d <- series()
      validate(need(nrow(d) > 0, "Pick at least one country/region."))
      
      d <- d %>%
        mutate(text = paste0(country, " · ", year, "<br>",
                             scales::comma(round(tc_loss_ha)), " ha"))
      
      y_max <- max(d$tc_loss_ha, na.rm = TRUE) * 1.08
      
      g <- ggplot(d, aes(x = year, y = tc_loss_ha,
                         colour = country, group = country, text = text)) +
        geom_line(linewidth = 0.95) + 
        geom_point(size = 1.4) +
        scale_y_continuous(labels = fmt_si, 
                           limits = c(0, y_max),
                           expand = expansion(mult = c(0, 0.06))) +
        scale_x_continuous(breaks = seq(2001, 2022, 3)) +
        labs(title = "Annual Tree-Cover Loss by Country",
             x = NULL, y = "Tree-cover loss (hectares)", color = NULL) +
        plot_theme() +
        theme(
          axis.line.x = element_line(color = "grey60", linewidth = 0.6),
          axis.ticks.x = element_line(color = "grey60"),
          axis.text.x = element_text(margin = margin(t = 8), color = "grey60"),
          axis.title.y = element_text(color = "#4b5563", size = 12),
          axis.text.y = element_text(color = "grey60", size = 12),
          plot.title = element_text(size = 17, face = "bold", hjust = 0.5, color = '#2d8f6c'),
          legend.position = "bottom",
          legend.margin = margin(t = 12)
        )
      
      # plotly ;  Control Title Position
      p <- to_plotly(g, tooltip = "text") %>%
        layout(
          title = list(
            text = "Annual Tree-Cover Loss by Country",
            x = 0.5,                
            xanchor = "center",     
            y = 0.98,               
            yanchor = "top",        
            font = list(color = "#2d8f6c", size = 25, family = "sans-serif")
          ),
          legend = list(title = list(text = ""))
        )
      
      p
    })
  })
}