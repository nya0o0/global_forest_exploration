# =========================================================
# 01_prepare_data.R
# Cleans the four GFW/UMD CSVs into tidy RDS files used by app.R
# Run once. Outputs: ../data/country_panel.rds and ../data/sub_panel.rds
# =========================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(readr)
  library(stringr)
  library(countrycode)
})

raw_dir   <- "data-raw"
out_dir   <- "data"
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

message("Reading raw CSVs ...")
country_carbon <- read_csv(file.path(raw_dir, "Country-carbon-data.csv"),
                           show_col_types = FALSE)
country_loss   <- read_csv(file.path(raw_dir, "Country-tree-cover-loss-2.csv"),
                           show_col_types = FALSE)
sub_carbon     <- read_csv(file.path(raw_dir, "Subnational-1-carbon-data-3.csv"),
                           show_col_types = FALSE)
sub_loss       <- read_csv(file.path(raw_dir, "Subnational-1-tree-cover-loss-4.csv"),
                           show_col_types = FALSE)

# ---- helper: pivot annual loss columns ----
pivot_loss <- function(df, group_cols) {
  df %>%
    pivot_longer(
      cols = starts_with("tc_loss_ha_"),
      names_to = "year",
      names_prefix = "tc_loss_ha_",
      values_to = "loss_ha"
    ) %>%
    mutate(year = as.integer(year)) %>%
    select(all_of(group_cols), threshold, year, loss_ha,
           extent_2000_ha, `gain_2000-2020_ha`)
}

# ---- helper: pivot annual gross-emissions columns ----
pivot_emis <- function(df, group_cols) {
  df %>%
    rename(threshold = umd_tree_cover_density_2000__threshold) %>%
    pivot_longer(
      cols = matches("gross_emissions_\\d{4}__Mg_CO2e$"),
      names_to = "year",
      names_pattern = "gross_emissions_(\\d{4})__Mg_CO2e",
      values_to = "emissions_mg_co2e"
    ) %>%
    mutate(year = as.integer(year)) %>%
    select(all_of(group_cols), threshold, year, emissions_mg_co2e,
           net_flux_yr      = `gfw_forest_carbon_net_flux__Mg_CO2e_yr-1`,
           gross_removals_yr = `gfw_forest_carbon_gross_removals__Mg_CO2_yr-1`,
           gross_emissions_yr = `gfw_forest_carbon_gross_emissions__Mg_CO2e_yr-1`,
           ac_stocks_2000   = gfw_aboveground_carbon_stocks_2000__Mg_C)
}

message("Tidying country-level files ...")
country_loss_long <- pivot_loss(country_loss, "country")
country_emis_long <- pivot_emis(country_carbon, "country")

country_panel <- country_loss_long %>%
  left_join(country_emis_long,
            by = c("country", "threshold", "year")) %>%
  group_by(country, threshold) %>%
  arrange(year, .by_group = TRUE) %>%
  mutate(cumulative_loss = cumsum(replace_na(loss_ha, 0))) %>%
  ungroup()

# Add ISO3 code for plotly choropleth
manual_iso <- c(
  "Kosovo" = "XKX",
  "Micronesia" = "FSM",
  "Saint-Martin" = "MAF"
)
suppressWarnings({
  country_panel <- country_panel %>%
    mutate(iso3 = countrycode(country, "country.name", "iso3c",
                              warn = FALSE),
           iso3 = coalesce(iso3, manual_iso[country]))
})

message("Tidying subnational files ...")
sub_loss_long <- pivot_loss(sub_loss,   c("country", "subnational1"))
sub_emis_long <- pivot_emis(sub_carbon, c("country", "subnational1"))

sub_panel <- sub_loss_long %>%
  left_join(sub_emis_long,
            by = c("country", "subnational1", "threshold", "year")) %>%
  group_by(country, subnational1, threshold) %>%
  arrange(year, .by_group = TRUE) %>%
  mutate(cumulative_loss = cumsum(replace_na(loss_ha, 0))) %>%
  ungroup()

# ---- save ----
saveRDS(country_panel, file.path(out_dir, "country_panel.rds"))
saveRDS(sub_panel,     file.path(out_dir, "sub_panel.rds"))

message("Done. Wrote:")
message("  ", file.path(out_dir, "country_panel.rds"),
        "  rows=", nrow(country_panel))
message("  ", file.path(out_dir, "sub_panel.rds"),
        "  rows=", nrow(sub_panel))
