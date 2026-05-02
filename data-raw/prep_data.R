# ============================================================================
# data-raw/prep_data.R
# Reads the four raw CSVs from Global Forest Watch, tidies them into long
# format, joins loss × carbon at country and subnational-1 levels, and
# writes .rds files into data/.
#
# Run automatically by app.R on first launch, or manually:
#     source("data-raw/prep_data.R")
#

# Owner: CHEN Hongxing
# ============================================================================

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(readr); library(countrycode)
})

RAW_DIR <- "data-raw"
OUT_DIR <- "data"
if (!dir.exists(OUT_DIR)) dir.create(OUT_DIR, recursive = TRUE)

add_region <- function(df) {
  df %>%
    mutate(
      region = countrycode::countrycode(country, "country.name", "region", warn = FALSE),
      continent = countrycode::countrycode(country, "country.name", "continent", warn = FALSE),
      continent = ifelse(is.na(continent), "Other", continent)
    )
}

# ---- 1. Country tree-cover loss --------------------------------------------
country_loss <- read_csv(file.path(RAW_DIR, "Country-tree-cover-loss.csv"),
                         show_col_types = FALSE) %>%
  rename_with(tolower) %>%
  pivot_longer(starts_with("tc_loss_ha_"),
               names_to = "year", names_prefix = "tc_loss_ha_",
               values_to = "tc_loss_ha") %>%
  mutate(year = as.integer(year),
         threshold = as.integer(threshold),
         tc_loss_ha = as.numeric(tc_loss_ha)) %>%
  filter(!is.na(country), country != "") %>%
  add_region()

saveRDS(country_loss, file.path(OUT_DIR, "country_loss.rds"))

# ---- 2. Country carbon -----------------------------------------------------
raw_cc <- read_csv(file.path(RAW_DIR, "Country-carbon-data.csv"),
                   show_col_types = FALSE) %>%
  rename_with(tolower)

# 2a. Static columns (annual averages)
cc_static <- raw_cc %>%
  rename(threshold      = umd_tree_cover_density_2000__threshold,
         extent_2000_ha = umd_tree_cover_extent_2000__ha,
         c_stocks_2000  = gfw_aboveground_carbon_stocks_2000__mg_c,
         c_density_2000 = `avg_gfw_aboveground_carbon_stocks_2000__mg_c_ha-1`,
         gross_removals = `gfw_forest_carbon_gross_removals__mg_co2_yr-1`,
         net_flux       = `gfw_forest_carbon_net_flux__mg_co2e_yr-1`) %>%
  select(country, threshold, extent_2000_ha, c_stocks_2000,
         c_density_2000, gross_removals, net_flux) %>%
  mutate(across(-country, ~ suppressWarnings(as.numeric(.x))),
         threshold = as.integer(threshold))

# 2b. Yearly emissions
cc_yearly <- raw_cc %>%
  rename(threshold = umd_tree_cover_density_2000__threshold) %>%
  pivot_longer(matches("^gfw_forest_carbon_gross_emissions_\\d{4}__"),
               names_to = "year",
               names_pattern = "gfw_forest_carbon_gross_emissions_(\\d{4})__",
               values_to = "gross_emissions") %>%
  mutate(year = as.integer(year),
         threshold = as.integer(threshold),
         gross_emissions = suppressWarnings(as.numeric(gross_emissions))) %>%
  select(country, threshold, year, gross_emissions)

country_carbon <- cc_static %>%
  left_join(cc_yearly, by = c("country", "threshold")) %>%
  filter(!is.na(country), country != "") %>%
  add_region()

saveRDS(country_carbon, file.path(OUT_DIR, "country_carbon.rds"))

# ---- 3. Country joined: loss × carbon emissions ----------------------------
country_joined <- country_loss %>%
  select(country, threshold, year, tc_loss_ha, extent_2000_ha, region, continent) %>%
  left_join(country_carbon %>%
              select(country, threshold, year, gross_emissions,
                     gross_removals, net_flux),
            by = c("country", "threshold", "year"))

saveRDS(country_joined, file.path(OUT_DIR, "country_joined.rds"))

# ---- 4. Subnational-1 loss × carbon ----------------------------------------
sub_loss <- read_csv(file.path(RAW_DIR, "Subnational-1-tree-cover-loss.csv"),
                     show_col_types = FALSE) %>%
  rename_with(tolower) %>%
  pivot_longer(starts_with("tc_loss_ha_"),
               names_to = "year", names_prefix = "tc_loss_ha_",
               values_to = "tc_loss_ha") %>%
  mutate(year = as.integer(year),
         threshold = as.integer(threshold),
         tc_loss_ha = as.numeric(tc_loss_ha)) %>%
  select(country, subnational1, threshold, year, tc_loss_ha, extent_2000_ha)

sub_carbon <- read_csv(file.path(RAW_DIR, "Subnational-1-carbon-data.csv"),
                       show_col_types = FALSE) %>%
  rename_with(tolower) %>%
  rename(threshold      = umd_tree_cover_density_2000__threshold,
         gross_removals = `gfw_forest_carbon_gross_removals__mg_co2_yr-1`,
         net_flux       = `gfw_forest_carbon_net_flux__mg_co2e_yr-1`) %>%
  pivot_longer(matches("^gfw_forest_carbon_gross_emissions_\\d{4}__"),
               names_to = "year",
               names_pattern = "gfw_forest_carbon_gross_emissions_(\\d{4})__",
               values_to = "gross_emissions") %>%
  mutate(year = as.integer(year),
         threshold = as.integer(threshold),
         gross_emissions = suppressWarnings(as.numeric(gross_emissions)),
         gross_removals  = suppressWarnings(as.numeric(gross_removals)),
         net_flux        = suppressWarnings(as.numeric(net_flux))) %>%
  select(country, subnational1, threshold, year,
         gross_emissions, gross_removals, net_flux)

subnat_joined <- sub_loss %>%
  left_join(sub_carbon, by = c("country", "subnational1", "threshold", "year")) %>%
  filter(!is.na(country), country != "")

saveRDS(subnat_joined, file.path(OUT_DIR, "subnat_joined.rds"))

message("✔ Data preparation complete. Files in '", OUT_DIR, "/'.")
