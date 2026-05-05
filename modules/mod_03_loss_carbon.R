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
                   sliderInput(ns("year"), "Year",
                               min = 2001, max = 2022, value = 2020, step = 1, sep = ""),
                   selectInput(ns("threshold"), "Threshold",
                               choices = c("30%" = 30, "50%" = 50, "75%" = 75),
                               selected = 30),
                   radioButtons(ns("metric"), "Carbon metric (y-axis)",
                                choices = CARBON_METRICS, selected = "gross_emissions"),
                   selectInput(ns("highlight"), "Highlight group",
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
                            "From 2011 to 2022, the Pearson correlation between annual tree‑cover loss and net flux across all countries slightly decreased, implying that global forest carbon balance is being shaped by an increasingly complex set of factors beyond loss alone."),
                insight_box("Insight 3", 
                            "Indonesia consistently showed the highest net flux, primarily because its high tree‑cover loss leads to elevated gross emissions, while its gross removals remain comparatively low."),
                insight_box("Insight 4", 
                            "Russia showed the lowest net flux, likely because it possesses the world’s largest forest cover, enabling massive gross removals that substantially outweigh its gross emissions.")
      )
    )
  )
}

mod_03_loss_carbon_server <- function(id, country_joined) {
  moduleServer(id, function(input, output, session) {
    
    # 热带国家列表（小写）
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
    
    # 准备数据（过滤 + 高亮标记）
    df_year <- reactive({
      d <- country_joined %>%
        filter(year == input$year,
               threshold == as.integer(input$threshold),
               !is.na(tc_loss_ha), tc_loss_ha > 0,
               !is.na(.data[[input$metric]])) %>%
        mutate(metric_value = .data[[input$metric]])
      
      d <- d %>% mutate(country_lower = tolower(trimws(country)))
      
      if (input$highlight == "All countries") {
        d <- d %>% mutate(highlight = TRUE)
      } else if (input$highlight == "Tropical only") {
        d <- d %>% mutate(highlight = country_lower %in% tropical_list)
      } else if (input$highlight == "Non‑tropical only") {
        d <- d %>% mutate(highlight = !(country_lower %in% tropical_list))
      }
      d
    })
    
    # 调试输出（可选，不显示在 UI，仅供控制台）
    output$debug_highlight <- renderPrint({
      d <- df_year()
      n_high <- sum(d$highlight)
      cat(sprintf("Highlight group: %s | Highlighted countries: %d | Total countries shown: %d",
                  input$highlight, n_high, length(unique(d$country))))
      if (input$highlight != "All countries" && n_high == 0) {
        cat("\nWARNING: No countries matched! Check country names.")
      }
    })
    
    # ============================================================
    # 相关系数计算（直接内嵌，不再依赖外部函数 loss_carbon_corr）
    # ============================================================
    output$corr_text <- renderText({
      d <- df_year()
      # 基于高亮组筛选
      if (input$highlight != "All countries") {
        d <- d %>% filter(highlight)
      }
      
      # 检查数据量
      if (nrow(d) < 3) {
        return("Pearson r: not enough data in highlighted group")
      }
      
      # 计算 Pearson 相关系数（使用 loss 和当前 metric_value）
      r <- cor(d$tc_loss_ha, d$metric_value, use = "complete.obs")
      
      if (is.na(r)) {
        return("Pearson r: could not compute (check for constant values?)")
      }
      
      # 获取指标显示名称
      metric_label <- names(CARBON_METRICS)[CARBON_METRICS == input$metric]
      
      group_label <- switch(input$highlight,
                            "Tropical only" = "Tropical countries",
                            "Non‑tropical only" = "Non‑tropical countries",
                            "All countries" = "all countries")
      
      sprintf("Pearson r (loss × %s) in %s = %.2f",
              metric_label, group_label, r)
    })
    
    # 气泡散点图
    output$scatter <- renderPlotly({
      d <- df_year()
      validate(need(nrow(d) > 0, "No data for this combination."))
      
      if (input$logaxes && input$metric == "gross_emissions") {
        d <- d %>% filter(metric_value > 0)
      }
      
      metric_label <- names(CARBON_METRICS)[CARBON_METRICS == input$metric]
      
      # 颜色映射：高亮 -> 原 continent；非高亮 -> "Other"
      d <- d %>%
        mutate(continent_display = if_else(highlight, as.character(continent), "Other"))
      
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
        geom_point(alpha = ifelse(d$highlight, 0.85, 0.3)) +
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