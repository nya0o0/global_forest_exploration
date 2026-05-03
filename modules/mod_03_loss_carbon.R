# ============================================================================
# Module 3 — Loss ↔ Carbon (bubble scatter + regression)    Owner: Member C
# Question: Is annual loss associated with annual gross emissions?
# ============================================================================
TROPICAL_COUNTRIES <- c(
  "Brazil", "Indonesia", "Democratic Republic of the Congo", "Colombia",
  "Peru", "Malaysia", "Papua New Guinea", "Madagascar", "Cameroon",
  "Gabon", "Republic of Congo", "India", "Thailand", "Vietnam", "Laos",
  "Cambodia", "Myanmar", "Philippines", "Ecuador", "Bolivia", "Venezuela",
  "Guyana", "Suriname", "French Guiana", "Nigeria", "Ghana", "Ivory Coast",
  "Liberia", "Sierra Leone", "Uganda", "Tanzania", "Mozambique", "Angola",
  "Zambia", "Zimbabwe", "Central African Republic", "Sudan", "South Sudan",
  "Ethiopia", "Kenya", "Somalia", "Mexico", "Guatemala", "Honduras",
  "Nicaragua", "Costa Rica", "Panama", "Cuba", "Dominican Republic",
  "Haiti", "Jamaica", "Sri Lanka", "Bangladesh", "Benin", "Togo",
  "Equatorial Guinea", "Sao Tome and Principe", "Maldives", "Seychelles",
  "Mauritius", "Fiji", "Solomon Islands", "Vanuatu", "Belize"
  
)
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
                   sidebar_title("Year"),
                   sliderInput(ns("year"), label = NULL,
                               min = 2001, max = 2022, value = 2020, step = 1, sep = ""),

                   threshold_sidebar_title("Threshold"),
                   selectInput(ns("threshold"), label = NULL,
                               choices = c("30%" = 30, "50%" = 50, "75%" = 75),   # 10% 已移除
                               selected = 30),

                   sidebar_title("Carbon metric (y-axis)"),
                   radioButtons(ns("metric"), label = NULL,
                                choices = CARBON_METRICS, selected = "gross_emissions"),

                   sidebar_title("Highlight group"),
                   selectInput(ns("highlight"), label = NULL,
                               choices = c("All countries", "Tropical only", "Non‑tropical only"),
                               selected = "All countries"),

                   checkboxInput(ns("logaxes"), "Log-scale both axes", TRUE),
                   checkboxInput(ns("trend"),   "Show OLS trend line", TRUE),
                   tags$hr(),
                   tags$div(class = "corr-readout", textOutput(ns("corr_text")))
      ),
      mainPanel(width = 9,
                plotlyOutput(ns("scatter"), height = "560px"),
                insight_box("Insight 1", 
                            "Annual tree-cover loss is positively and significantly associated with annual gross forest carbon emissions, especially in tropical countries. The highlighted group makes this regional contrast immediately visible."),
                insight_box("Insight 2", 
                            "From 2011 to 2022, the Pearson correlation between annual tree‑cover loss and net flux across all countries slighly decreased, implying that global forest carbon balance is being shaped by an increasingly complex set of factors beyond loss alone."),           insight_box("Insight 3", 
                            "Indonesia consistently showed the highest net flux, primarily because its high tree‑cover loss leads to elevated gross emissions, while its gross removals remain comparatively low."),
                insight_box("Insight 4", 
                            "Russia showed the lowest net flux, likely because it possesses the world’s largest forest cover, enabling massive gross removals that substantially outweigh its gross emissions.")
      )
    )
  )
}
mod_03_loss_carbon_server <- function(id, country_joined) {
  moduleServer(id, function(input, output, session) {
    
    # 将热带国家列表直接放在模块内，避免外部依赖
    tropical_list <- tolower(c(
      "Brazil", "Indonesia", "Democratic Republic of the Congo", "Colombia",
      "Peru", "Malaysia", "Papua New Guinea", "Madagascar", "Cameroon",
      "Gabon", "Republic of Congo", "India", "Thailand", "Vietnam", "Laos",
      "Cambodia", "Myanmar", "Philippines", "Ecuador", "Bolivia", "Venezuela",
      "Guyana", "Suriname", "French Guiana", "Nigeria", "Ghana", "Ivory Coast",
      "Liberia", "Sierra Leone", "Uganda", "Tanzania", "Mozambique", "Angola",
      "Zambia", "Zimbabwe", "Central African Republic", "Sudan", "South Sudan",
      "Ethiopia", "Kenya", "Somalia", "Mexico", "Guatemala", "Honduras",
      "Nicaragua", "Costa Rica", "Panama", "Cuba", "Dominican Republic",
      "Haiti", "Jamaica", "Sri Lanka", "Bangladesh", "Benin", "Togo",
      "Equatorial Guinea", "Sao Tome and Principe", "Maldives", "Seychelles",
      "Mauritius", "Fiji", "Solomon Islands", "Vanuatu", "Belize"
    ))
    
    df_year <- reactive({
      d <- country_joined %>%
        filter(year == input$year,
               threshold == as.integer(input$threshold),
               !is.na(tc_loss_ha), tc_loss_ha > 0,
               !is.na(.data[[input$metric]])) %>%
        mutate(metric_value = .data[[input$metric]])
      
      # 创建一个可用于匹配的小写国家列
      d <- d %>% mutate(country_lower = tolower(trimws(country)))
      
      # 根据下拉框标记高亮组
      if (input$highlight == "All countries") {
        d <- d %>% mutate(highlight = TRUE)
      } else if (input$highlight == "Tropical only") {
        d <- d %>% mutate(highlight = country_lower %in% tropical_list)
      } else if (input$highlight == "Non‑tropical only") {
        d <- d %>% mutate(highlight = !(country_lower %in% tropical_list))
      }
      d
    })
    
    # 调试输出：显示匹配数量
    output$debug_highlight <- renderPrint({
      d <- df_year()
      n_high <- sum(d$highlight)
      cat(sprintf("Highlight group: %s | Highlighted countries: %d | Total countries shown: %d",
                  input$highlight, n_high, length(unique(d$country))))
      if (input$highlight != "All countries" && n_high == 0) {
        cat("\nWARNING: No countries matched! Check country names.")
      }
    })
    
    output$corr_text <- renderText({
      d <- df_year()
      if (input$highlight != "All countries") {
        d <- d %>% filter(highlight)
      }
      r <- loss_carbon_corr(d, input$year, as.integer(input$threshold))
      if (is.na(r)) return("Pearson r: not enough data in highlighted group")
      group_label <- switch(input$highlight,
                            "Tropical only" = "Tropical countries",
                            "Non‑tropical only" = "Non‑tropical countries",
                            "All countries" = "all countries")
      sprintf("Pearson r (loss × %s) in %s = %.2f",
              names(CARBON_METRICS)[CARBON_METRICS == input$metric],
              group_label, r)
    })
    
    output$scatter <- renderPlotly({
      d <- df_year()
      validate(need(nrow(d) > 0, "No data for this combination."))
      
      if (input$logaxes && input$metric == "gross_emissions") {
        d <- d %>% filter(metric_value > 0)
      }
      
      metric_label <- names(CARBON_METRICS)[CARBON_METRICS == input$metric]
      
      # 创建用于颜色映射的“显示洲”：
      # 非高亮 → "Other", 高亮 → continent
      d <- d %>%
        mutate(continent_display = if_else(highlight, as.character(continent), "Other"))
      
      # 固定颜色映射：原有 continent 调色板 + "Other" = grey
      all_continents <- c(unique(d$continent), "Other")
      color_map <- PALETTE_REGION[names(PALETTE_REGION) %in% all_continents]
      color_map["Other"] <- "grey80"
      
      g <- ggplot(d, aes(x = tc_loss_ha, y = metric_value,
                         size = extent_2000_ha,
                         colour = continent_display,
                         text = paste0(country, "<br>",
                                       "Loss: ", scales::comma(round(tc_loss_ha)), " ha<br>",
                                       metric_label, ": ",
                                       scales::comma(round(metric_value))))) +
        geom_point(alpha = ifelse(d$highlight, 0.85, 0.3)) +  # 透明度通过向量控制
        scale_size_area(max_size = 14, labels = fmt_si, name = "Forest 2000 (ha)") +
        scale_colour_manual(values = color_map, name = "Continent") +
        labs(title = paste0("Forest loss vs. ", metric_label, " · ", input$year,
                            if(input$highlight != "All countries")
                              paste0(" — Highlight: ", input$highlight)),
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
        trend_data <- d %>% filter(highlight)
        if (nrow(trend_data) >= 3) {
          g <- g + geom_smooth(
            data = trend_data,
            inherit.aes = FALSE,
            aes(x = tc_loss_ha, y = metric_value),
            method = "lm", formula = y ~ x,
            colour = "grey20", linetype = 2, se = FALSE,
            linewidth = 0.6, show.legend = FALSE
          )
        }
      }
      
      to_plotly(g, tooltip = "text")
    })
  })
}