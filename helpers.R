# ============================================================================
# helpers.R — all shared helpers (data + plot + UI bits) in one file.
# ============================================================================

# ---- Palettes ---------------------------------------------------------------
PALETTE_REGION <- c(            # Okabe-Ito (colour-blind safe)
  "Africa"   = "#E69F00",
  "Asia"     = "#56B4E9",
  "Europe"   = "#009E73",
  "Americas" = "#D55E00",
  "Oceania"  = "#CC79A7",
  "Other"    = "#999999"
)

# ---- Data helpers -----------------------------------------------------------

#' Top-N countries by tree-cover loss for a given year and threshold.
top_countries_loss <- function(df, year_sel, threshold_sel, n = 10) {
  df %>%
    filter(year == year_sel, threshold == threshold_sel) %>%
    group_by(country) %>%
    summarise(tc_loss_ha = sum(tc_loss_ha, na.rm = TRUE), .groups = "drop") %>%
    arrange(desc(tc_loss_ha)) %>%
    slice_head(n = n)
}

#' Per-country annual time series for a list of countries.
country_time_series <- function(df, countries, threshold_sel,
                                year_min = 2001, year_max = 2022) {
  df %>%
    filter(country %in% countries,
           threshold == threshold_sel,
           year >= year_min, year <= year_max) %>%
    arrange(country, year)
}

#' Pearson correlation between annual loss and gross emissions.
loss_carbon_corr <- function(df, year_sel, threshold_sel) {
  d <- df %>%
    filter(year == year_sel, threshold == threshold_sel,
           !is.na(tc_loss_ha), !is.na(gross_emissions),
           tc_loss_ha > 0, gross_emissions > 0)
  if (nrow(d) < 5) return(NA_real_)
  suppressWarnings(cor(d$tc_loss_ha, d$gross_emissions, method = "pearson"))
}

#' SI label formatter (1.2M, 350k, ...)
fmt_si <- function(x) scales::label_number(scale_cut = scales::cut_short_scale())(x)

# ---- Plot helpers -----------------------------------------------------------

#' Project ggplot theme.
plot_theme <- function() {
  ggplot2::theme_minimal(base_size = 13) +
    ggplot2::theme(
      panel.grid.minor   = ggplot2::element_blank(),
      panel.grid.major.x = ggplot2::element_blank(),
      plot.title         = ggplot2::element_text(face = "bold", size = 16),
      plot.subtitle      = ggplot2::element_text(colour = "grey40"),
      legend.position    = "bottom",
      strip.text         = ggplot2::element_text(face = "bold")
    )
}

#' Convert ggplot to plotly with consistent config.
to_plotly <- function(g, tooltip = "text") {
  plotly::ggplotly(g, tooltip = tooltip) %>%
    plotly::config(displaylogo = FALSE,
                   modeBarButtonsToRemove = c("lasso2d", "select2d", "autoScale2d"))
}

# ---- UI helpers -------------------------------------------------------------

#' Insight callout used at the bottom of each chapter.
insight_box <- function(title, text) {
  div(class = "insight-box",
      tags$h4(icon("lightbulb"), " ", title),
      tags$p(text))
}

#' Module title block.
module_header <- function(chapter, title, subtitle) {
  div(class = "module-header",
      tags$small(class = "chapter-tag", paste("Chapter", chapter)),
      tags$h2(title),
      tags$p(class = "lead", subtitle))
}

#' Threshold label with an info-icon popover explaining what the
#' tree-cover density threshold actually means. Used as the `label`
#' argument of selectInput in every module that exposes the threshold.
threshold_label <- function(text = "Tree-cover density threshold") {
  tags$span(
    text, " ",
    tags$a(
      href      = "#",
      tabindex  = "0",
      class     = "threshold-info",
      role      = "button",
      `data-bs-toggle`   = "popover",
      `data-bs-trigger`  = "focus hover",
      `data-bs-html`     = "true",
      `data-bs-placement`= "right",
      `data-bs-title`    = "What is this threshold?",
      `data-bs-content`  = paste0(
        "<p>The minimum percentage of tree-canopy cover (per 30 m Landsat ",
        "pixel) that counts as <b>forest</b>.</p>",
        "<ul style='padding-left:1rem;margin-bottom:.4rem;'>",
        "<li><b>10 %</b> \u2014 loose: includes savanna &amp; shrubs</li>",
        "<li><b>30 %</b> \u2014 FAO international standard (default)</li>",
        "<li><b>75 %</b> \u2014 strict: dense / primary forest only</li>",
        "</ul>",
        "<small>Lower thresholds inflate forest area &amp; loss numbers; ",
        "higher thresholds focus on intact forest.</small>"),
      tags$i(class = "fa fa-info-circle",
             style = "color:#1f6f54; cursor:pointer;")
    )
  )
}

#' Activate Bootstrap 5 popovers everywhere in the app. Uses a
#' MutationObserver so popovers in lazily-rendered tab content also
#' get initialised the moment Shiny inserts them into the DOM.
threshold_popover_init <- function() {
  tagList(
    tags$script(HTML(
      "(function(){
         function scan(root){
           if (typeof bootstrap === 'undefined') return;
           var els = (root||document).querySelectorAll('[data-bs-toggle=\"popover\"]');
           els.forEach(function(el){
             if (!el._initd){
               try { bootstrap.Popover.getOrCreateInstance(el); el._initd = true; } catch(e){}
             }
           });
         }
         function start(){
           scan(document);
           var mo = new MutationObserver(function(muts){
             muts.forEach(function(m){
               m.addedNodes.forEach(function(n){
                 if (n.nodeType === 1) scan(n);
               });
             });
           });
           mo.observe(document.body, {childList:true, subtree:true});
           // Belt-and-braces: re-scan on common Shiny / Bootstrap events
           document.addEventListener('shown.bs.tab', function(){ scan(document); });
           if (window.$) {
             $(document).on('shiny:value shiny:bound shiny:connected', function(){ scan(document); });
           }
         }
         if (document.readyState === 'loading'){
           document.addEventListener('DOMContentLoaded', start);
         } else { start(); }
       })();"
    ))
  )
}
