# =========================================================
# app.R - Forests After COP26 (DASC 3240 Final Project)
# Main Shiny entry point. Run with shiny::runApp() or
# shiny::runGitHub("<user>/forests-after-cop26").
# =========================================================

suppressPackageStartupMessages({
  library(shiny)
  library(bslib)
  library(plotly)
  library(dplyr)
})

# ---- load helpers ----
source("R/plot_helpers.R", local = TRUE)
source("R/extra_plots.R", local = TRUE)

# ---- load tidied data (built by data-raw/01_prepare_data.R) ----
country_panel <- readRDS("data/country_panel.rds")
sub_panel     <- readRDS("data/sub_panel.rds")

THRESHOLD_CHOICES <- c("10%" = 10, "25%" = 25,
                       "30% (default)" = 30, "50%" = 50, "75%" = 75)
COUNTRY_CHOICES   <- sort(unique(country_panel$country))

# ---------- UI ----------
ui <- page_navbar(
  title = "Forests After COP26",
  theme = bs_theme(version = 5, bootswatch = "minty",
                   base_font = font_google("Inter")),
  
  # ---- Tab 1: World map ----
  nav_panel(
    "World map",
    layout_sidebar(
      sidebar = sidebar(
        width = 280,
        h5("Map controls"),
        radioButtons("metric", "View:",
                     choices = c("Tree cover loss" = "loss",
                                 "Net carbon flux" = "flux"),
                     selected = "loss"),
        sliderInput("year", "Year:",
                    min = 2001, max = 2022, value = 2022, step = 1, sep = "",
                    animate = animationOptions(interval = 700, loop = FALSE)),
        selectInput("threshold", "Canopy threshold:",
                    choices = THRESHOLD_CHOICES, selected = 30),
        hr(),
        p(em("Tip: press the play button on the year slider to animate."),
          style = "font-size:12px;color:#666"),
        helpText(HTML(
          "Source: Hansen/UMD via <a href='https://www.globalforestwatch.org/' target='_blank'>Global Forest Watch</a>. Licensed under ODbL 1.0."
        ))
      ),
      div(
        style = "padding: 0 8px;",
        div(class = "alert alert-warning", style = "margin-bottom:12px",
            HTML(
              "<b>Headline:</b> 145 countries pledged at COP26 (2021) to halt forest loss by 2030. ",
              "But tropical primary forest loss <b>rose 10%</b> in 2022 vs. 2021 - and major tropical countries have flipped from carbon sinks to net carbon sources."
            )),
        plotlyOutput("world_map", height = "560px"),
        uiOutput("map_kpi")
      )
    )
  ),
  
  # ---- Tab 2: Racing bar ----
  nav_panel(
    "Racing bar",
    div(
      style = "padding: 12px 24px;",
      h3("22 years of cumulative forest loss - top 12 countries"),
      p("Russia, Brazil, Canada and the US dominate cumulative loss volumes.",
        " Watch for ", strong("Bolivia"), " surging into the top 5 after 2020,",
        " and the steady rise of the ", strong("Democratic Republic of the Congo.")),
      tags$img(src = "racing_bar.gif",
               style = "max-width: 950px; width: 100%; border-radius: 8px;
                        box-shadow: 0 2px 6px rgba(0,0,0,.1);"),
      p(em("GIF rendered with gganimate. Re-render with ",
           code("data-raw/02_render_racing_gif.R"), "."),
        style = "color:#777;font-size:12px;margin-top:8px")
    )
  ),
  
  # ---- Tab 3: Country drill-down ----
  nav_panel(
    "Country drill-down",
    layout_sidebar(
      sidebar = sidebar(
        width = 280,
        selectizeInput("country_sel", "Country:",
                       choices = COUNTRY_CHOICES,
                       selected = "Brazil"),
        selectInput("threshold2", "Canopy threshold:",
                    choices = THRESHOLD_CHOICES, selected = 30),
        hr(),
        p("Pick a country to see annual loss with a COP26 reference line, ",
          "its top subnational loss hotspots, and whether its forests act ",
          "as a net carbon sink or source.",
          style = "font-size: 12px; color:#555")
      ),
      uiOutput("country_kpi"),
      layout_columns(
        col_widths = c(6, 6),
        plotlyOutput("country_trend",   height = "380px"),
        plotlyOutput("subnational_bar", height = "380px")
      )
    )
  ),
  
  # ---- Tab 4: Loss heatmap ----
  nav_panel(
    "Loss heatmap",
    layout_sidebar(
      sidebar = sidebar(
        width = 280,
        h5("Heatmap controls"),
        selectInput("hm_threshold", "Canopy threshold:",
                    choices = THRESHOLD_CHOICES, selected = 30),
        sliderInput("hm_top_n", "Top N countries:",
                    min = 10, max = 50, value = 30, step = 5),
        hr(),
        p("Each cell shows annual tree-cover loss as a percent of that ",
          "country's year-2000 forest area. Hot streaks call out events like ",
          "Australia's 2019-20 Black Summer, Indonesia's 2015-16 peat fires, ",
          "and Cambodia's 2010-2017 commodity boom.",
          style = "font-size:12px;color:#555")
      ),
      div(
        style = "padding: 0 8px;",
        plotlyOutput("loss_heatmap", height = "640px")
      )
    )
  ),
  
  # ---- Tab 5: Sink vs source ----
  nav_panel(
    "Sink vs source",
    layout_sidebar(
      sidebar = sidebar(
        width = 280,
        h5("Scatter controls"),
        selectInput("ss_threshold", "Canopy threshold:",
                    choices = THRESHOLD_CHOICES, selected = 30),
        sliderInput("ss_min_loss", "Min cumulative loss (ha):",
                    min = 0, max = 500000, value = 50000, step = 25000),
        hr(),
        p("Bubble size = year-2000 forest extent. ",
          strong("Indonesia"), " sits alone in Quadrant I as a high-loss net ",
          "SOURCE. ", strong("Russia"), " has the largest absolute loss but ",
          "its boreal forests still soak up roughly 2 Gt CO2e per year ",
          "(Quadrant IV).",
          style = "font-size:12px;color:#555")
      ),
      div(
        style = "padding: 0 8px;",
        plotlyOutput("sink_source", height = "640px")
      )
    )
  ),
  
  # ---- Tab 6: About ----
  nav_panel(
    "About",
    div(
      style = "padding: 12px 24px; max-width: 900px;",
      h3("About this app"),
      p("This dashboard visualizes 22 years of global forest loss and forest ",
        "carbon flux to ask one question: ", strong("did the world's forest ",
                                                    "pledges actually slow forest loss?")),
      h4("Data"),
      tags$ul(
        tags$li(strong("Source: "),
                "Hansen/UMD tree cover loss + GFW/Harris et al. forest carbon flux ",
                "(via the ", a("Global Forest Watch open data portal",
                               href = "https://www.globalforestwatch.org/",
                               target = "_blank"), ")."),
        tags$li(strong("Coverage: "), "236 countries x 8 canopy thresholds x 2001-2022 (annual)."),
        tags$li(strong("License: "),
                a("Open Data Commons Database License (ODbL) 1.0",
                  href = "https://opendatacommons.org/licenses/dbcl/1.0/",
                  target = "_blank"), ".")
      ),
      h4("Story angle"),
      p("Two intertwined narratives:"),
      tags$ol(
        tags$li(strong("The COP26 promise gap. "),
                "At Glasgow in November 2021, 145 countries committed to halt ",
                "and reverse forest loss by 2030. The very next year, tropical ",
                "primary forest loss ", strong("rose 10%"), " - the equivalent of ",
                "11 football pitches per minute."),
        tags$li(strong("Sink to source. "),
                "Tropical countries with peat-rich forests (e.g. Indonesia) and ",
                "agricultural frontiers (e.g. Brazil) now release more CO2e from ",
                "forest disturbance than their forests absorb. The map's diverging ",
                "color scale shows this dramatically when you switch to the ",
                strong("Net carbon flux"), " view.")
      ),
      h4("Caveats"),
      tags$ul(
        tags$li("\"Tree cover\" includes plantations - it does not equal primary forest."),
        tags$li("Gain is for 2000-2020 only and does not reflect quality of regrowth."),
        tags$li("Carbon flux uses Harris et al. 2021 model, with year-level uncertainty.")
      ),
      h4("Reproduce this app"),
      p("All data prep is in ", code("data-raw/01_prepare_data.R"),
        " and the racing GIF is rendered by ",
        code("data-raw/02_render_racing_gif.R"), ".",
        " Run ", code("shiny::runGitHub(\"<your-username>/forests-after-cop26\")"),
        " to launch the app."),
      hr(),
      p(em("Built for DASC 3240 - Data Visualization."),
        style = "color:#888")
    )
  ),
  
  nav_spacer(),
  nav_item(tags$a(href = "https://www.globalforestwatch.org/",
                  target = "_blank", "Data: GFW ->"))
)

# ---------- SERVER ----------
server <- function(input, output, session) {
  
  # ---- Tab 1: world map ----
  output$world_map <- renderPlotly({
    plot_world_map(
      df            = country_panel,
      year_sel      = as.integer(input$year),
      threshold_sel = as.integer(input$threshold),
      metric        = input$metric
    )
  })
  
  output$map_kpi <- renderUI({
    d <- country_panel %>%
      filter(threshold == as.integer(input$threshold),
             year == as.integer(input$year))
    total_loss <- sum(d$loss_ha, na.rm = TRUE)
    n_sources <- sum(d$net_flux_yr > 0, na.rm = TRUE)
    n_sinks   <- sum(d$net_flux_yr < 0, na.rm = TRUE)
    HTML(sprintf(
      '<div style="display:flex;gap:18px;flex-wrap:wrap;margin-top:16px">
         <div style="flex:1;min-width:180px;padding:14px 16px;background:#fff;
                     border-radius:8px;box-shadow:0 1px 3px rgba(0,0,0,.08)">
           <div style="font-size:11px;color:#666">Global tree cover loss - %d</div>
           <div style="font-size:22px;font-weight:600">%s ha</div>
         </div>
         <div style="flex:1;min-width:180px;padding:14px 16px;background:#fff;
                     border-radius:8px;box-shadow:0 1px 3px rgba(0,0,0,.08)">
           <div style="font-size:11px;color:#666">Net carbon sources (countries)</div>
           <div style="font-size:22px;font-weight:600;color:#c0392b">%d</div>
         </div>
         <div style="flex:1;min-width:180px;padding:14px 16px;background:#fff;
                     border-radius:8px;box-shadow:0 1px 3px rgba(0,0,0,.08)">
           <div style="font-size:11px;color:#666">Net carbon sinks (countries)</div>
           <div style="font-size:22px;font-weight:600;color:#27ae60">%d</div>
         </div>
       </div>',
      input$year, scales::comma(total_loss), n_sources, n_sinks
    ))
  })
  
  # ---- Tab 1 -> Tab 3 click navigation ----
  observeEvent(event_data("plotly_click", source = "world_map"), {
    ev <- event_data("plotly_click", source = "world_map")
    iso <- ev$location
    if (!is.null(iso)) {
      hit <- country_panel %>%
        filter(iso3 == iso) %>% distinct(country) %>% pull(country)
      if (length(hit) > 0) {
        updateSelectizeInput(session, "country_sel", selected = hit[1])
        nav_select(id = NULL, selected = "Country drill-down")
      }
    }
  })
  
  # ---- Tab 3: country drill-down ----
  output$country_kpi <- renderUI({
    make_kpi_html(input$country_sel, country_panel,
                  threshold_sel = as.integer(input$threshold2))
  })
  
  output$country_trend <- renderPlotly({
    plot_country_trend(country_panel, input$country_sel,
                       as.integer(input$threshold2))
  })
  
  output$subnational_bar <- renderPlotly({
    plot_subnational_bar(sub_panel, input$country_sel,
                         as.integer(input$threshold2))
  })
  
  # ---- Tab 4: Loss heatmap ----
  output$loss_heatmap <- renderPlotly({
    plot_loss_heatmap(country_panel,
                      threshold_sel = as.integer(input$hm_threshold),
                      top_n         = as.integer(input$hm_top_n))
  })
  
  # ---- Tab 5: Sink vs source ----
  output$sink_source <- renderPlotly({
    plot_sink_source(country_panel,
                     threshold_sel = as.integer(input$ss_threshold),
                     min_loss_ha   = as.integer(input$ss_min_loss))
  })
}

shinyApp(ui, server)