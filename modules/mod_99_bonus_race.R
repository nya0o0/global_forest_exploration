# ============================================================================
# Module Bonus — Racing-bar animation (gganimate)            Owner: Member E
# ============================================================================

mod_99_bonus_race_ui <- function(id) {
  ns <- NS(id)
  fluidPage(
    module_header(
      chapter  = "Bonus",
      title    = "20 years in 30 seconds",
      subtitle = "Watch the global ranking of forest-loss countries shift across 2001–2022."
    ),
    sidebarLayout(
      sidebarPanel(width = 3,
        selectInput(ns("threshold"), "Threshold",
                    choices = THRESHOLD_CHOICES, selected = DEFAULT_THRESHOLD),
        sliderInput(ns("topn"), "Top N", min = 5, max = 15, value = 10),
        actionButton(ns("render"), "Render animation", class = "btn-primary"),
        helpText("Rendering takes ~10 seconds.")
      ),
      mainPanel(width = 9,
        imageOutput(ns("gif"), height = "560px"))
    )
  )
}

mod_99_bonus_race_server <- function(id, country_loss) {
  moduleServer(id, function(input, output, session) {

    gif_path <- eventReactive(input$render, {
      requireNamespace("gganimate", quietly = TRUE)
      requireNamespace("gifski",    quietly = TRUE)

      thr <- as.integer(input$threshold)
      d <- country_loss %>%
        filter(threshold == thr) %>%
        group_by(year) %>%
        mutate(rank = rank(-tc_loss_ha, ties.method = "first")) %>%
        filter(rank <= input$topn) %>% ungroup()

      g <- ggplot(d, aes(x = -rank, y = tc_loss_ha, fill = country)) +
        geom_col(show.legend = FALSE, width = 0.85) +
        geom_text(aes(label = country), hjust = 1.1, size = 4) +
        coord_flip(clip = "off") +
        scale_y_continuous(labels = fmt_si) +
        scale_fill_viridis_d(option = "D") +
        labs(title = "Top countries by tree-cover loss · {closest_state}",
             x = NULL, y = "Tree-cover loss (ha)") +
        plot_theme() +
        theme(plot.margin = margin(20, 60, 20, 80),
              axis.text.y = element_blank())

      anim <- g + gganimate::transition_states(year, transition_length = 4,
                                               state_length = 1) +
                  gganimate::ease_aes("cubic-in-out")

      tmp <- tempfile(fileext = ".gif")
      gganimate::anim_save(tmp,
        animation = gganimate::animate(anim, fps = 10, duration = 22,
                                       width = 800, height = 520,
                                       renderer = gganimate::gifski_renderer()))
      tmp
    })

    output$gif <- renderImage(deleteFile = FALSE, {
      req(gif_path())
      list(src = gif_path(), contentType = "image/gif",
           alt = "Racing-bar animation of forest loss")
    })
  })
}
