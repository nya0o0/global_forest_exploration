# ============================================================================
# Forest Loss & Carbon (2001-2022) — DASC 3240 Final Project
# Single-file entry point: loads helpers, modules, builds UI + server, runs.
# ============================================================================

# Ensure UTF-8 so subscripts (CO₂) and en-dashes render in source/labels.
try(Sys.setlocale("LC_ALL", "C.UTF-8"), silent = TRUE)
options(encoding = "UTF-8")

suppressPackageStartupMessages({
  library(shiny)
  library(bslib)
  library(dplyr)
  library(tidyr)
  library(readr)
  library(ggplot2)
  library(plotly)
  library(scales)
  library(viridis)
  library(leaflet)
  library(sf)
  library(forcats)
})

# ---- Helpers + cached data --------------------------------------------------
source("helpers.R", local = TRUE)

DATA_DIR <- "data"
needed <- c("country_loss.rds", "country_carbon.rds",
            "country_joined.rds", "subnat_joined.rds")
if (!all(file.exists(file.path(DATA_DIR, needed)))) {
  message("Building cached data via data-raw/prep_data.R ...")
  source("data-raw/prep_data.R", local = TRUE)
}
country_loss   <- readRDS(file.path(DATA_DIR, "country_loss.rds"))
country_carbon <- readRDS(file.path(DATA_DIR, "country_carbon.rds"))
country_joined <- readRDS(file.path(DATA_DIR, "country_joined.rds"))
subnat_joined  <- readRDS(file.path(DATA_DIR, "subnat_joined.rds"))

# ---- Modules ----------------------------------------------------------------
for (f in list.files("modules", pattern = "\\.R$", full.names = TRUE)) source(f, local = TRUE)

# ---- Constants used across modules -----------------------------------------
YEAR_RANGE        <- 2001:2022
THRESHOLD_CHOICES <- c("10 %" = 10, "30 %" = 30, "50 %" = 50, "75 %" = 75)
DEFAULT_THRESHOLD <- 30
CARBON_METRICS    <- c("Gross emissions (Mg CO₂e/yr)" = "gross_emissions",
                       "Gross removals (Mg CO₂/yr)"   = "gross_removals",
                       "Net flux (Mg CO₂e/yr)"        = "net_flux")

# ---- UI ---------------------------------------------------------------------
ui <- navbarPage(
  id = "main_nav",
  title = tags$span("🌳 Forest Loss & Carbon (2001–2022)"),
  theme = bs_theme(version = 5, bootswatch = "flatly", primary = "#1f6f54"),
  header = tagList(
    tags$head(tags$link(rel = "stylesheet", href = "custom.css")),
    threshold_popover_init()
  ),

  tabPanel("Intro", icon = icon("leaf"),
    fluidRow(column(8, offset = 2,
      tags$h2("Where is the world losing its forests — and at what carbon cost?"),
      tags$p(class = "lead",
        "Between 2001 and 2022 the planet lost an area of tree cover larger than India.",
        "This app walks you through five chapters: from the global ranking, through the",
        "loss–carbon relationship, down to subnational hotspots, ending with the question",
        "that matters most for climate — are forests still a net carbon sink?"),

      # Always-visible data-source section (re-uses www/data-source.md)
      tags$hr(),
      div(class = "data-source-body",
          includeMarkdown("www/data-source.md")),

      tags$hr(),
      tags$h4("How to read this app"),
      tags$ol(
        tags$li(tags$b("1 · Overview "),     "— who loses the most?"),
        tags$li(tags$b("2 · Time trends "),  "— turning points 2001–2022"),
        tags$li(tags$b("3 · Loss ↔ Carbon "),"— is loss correlated with emissions?"),
        tags$li(tags$b("4 · Hotspots "),     "— zoom into subnational regions"),
        tags$li(tags$b("5 · Carbon budget "),"— sink or source?"),
        tags$li(tags$em("Bonus — animated 20-year ranking race"))
      ),
      tags$p(class = "text-muted",
        tags$i(class = "fa fa-info-circle"), " ",
        tags$b("Tree-cover density threshold:"),
        " the minimum % of canopy cover per 30 m pixel that counts as forest. ",
        "10 % = loose (savanna/shrubs), 30 % = FAO standard (default), 75 % = strict primary forest. ",
        "Hover the ", tags$i(class = "fa fa-info-circle"), " icon next to any threshold control for details."),

      tags$br(),
      actionButton("go_ch1", "Start →", class = "btn-primary btn-lg")
    ))
  ),

  tabPanel("1 · Overview",       icon = icon("ranking-star"),  mod_01_overview_ui("m1")),
  tabPanel("2 · Time trends",    icon = icon("chart-line"),    mod_02_trends_ui("m2")),
  tabPanel("3 · Loss ↔ Carbon",  icon = icon("circle-nodes"),  mod_03_loss_carbon_ui("m3")),
  tabPanel("4 · Hotspots",       icon = icon("map-location"),  mod_04_hotspots_ui("m4")),
  tabPanel("5 · Carbon budget",  icon = icon("scale-balanced"),mod_05_budget_ui("m5")),
  tabPanel("Bonus",              icon = icon("wand-magic-sparkles"), mod_99_bonus_race_ui("mb")),
  tabPanel("About",              icon = icon("circle-info"),
           fluidRow(column(8, offset = 2, includeMarkdown("www/about.md")))),

  footer = tags$footer(class = "app-footer",
    HTML("Source: <a href='https://www.kaggle.com/datasets/karnikakapoor/global-forest-data-2001-2022' target='_blank'>Global Forest Data: 2001–2022</a> (Kaggle, mirroring <a href='https://www.globalforestwatch.org' target='_blank'>Global Forest Watch</a>) · Hansen et al. (2013) · Harris et al. (2021). CC BY 4.0."),
    tags$div("Built for DASC 3240 · 2025/26 Spring · HKUST"))
)

# ---- Server -----------------------------------------------------------------
server <- function(input, output, session) {
  observeEvent(input$go_ch1, {
    updateNavbarPage(session, "main_nav", selected = "1 · Overview")
  })
  mod_01_overview_server   ("m1", country_loss   = country_loss)
  mod_02_trends_server     ("m2", country_loss   = country_loss)
  mod_03_loss_carbon_server("m3", country_joined = country_joined)
  mod_04_hotspots_server   ("m4", subnat_joined  = subnat_joined)
  mod_05_budget_server     ("m5", country_carbon = country_carbon,
                                  country_joined = country_joined)
  mod_99_bonus_race_server ("mb", country_loss   = country_loss)
}

shinyApp(ui = ui, server = server)
