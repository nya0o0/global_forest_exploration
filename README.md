# 🌳 Global Forest Tree Cover Loss & Carbon Flux (2001–2022)

**DASC 3240 — Final Project, 2025/26 Spring · HKUST** **Instructor:** Dr. Masayuki USHIO

An interactive Shiny app that walks through the global pattern of forest tree-cover loss between 2001 and 2022 and its relationship with forest carbon emissions.

------------------------------------------------------------------------

## 🚀Run the app

``` r
# Install dependencies once
install.packages(c("shiny", "bslib", "dplyr", "tidyr", "readr",
                   "ggplot2", "plotly", "scales", "viridis",
                   "leaflet", "sf", "rnaturalearth", "rnaturalearthdata",
                   "countrycode", "forcats", "gganimate", "gifski",
                   "markdown"))

# `rnaturalearth::ne_states()` needs the high-resolution data package,
# which lives on R-universe (not CRAN):
install.packages("rnaturalearthhires",
                 repos = c("https://ropensci.r-universe.dev",
                           "https://cloud.r-project.org"))

# Run directly from GitHub
shiny::runGitHub("global_forest_exploration", "<nya0o0>", ref = "main")
```

## 1. Research question

**Between 2001 and 2022, which countries and subnational regions experienced the most severe forest tree-cover loss, how is this loss related to forest carbon emissions, and which spatial hotspots deserve highest priority?**

The narrative arc:

| \#  | Chapter          | Question                               |
|-----|------------------|----------------------------------------|
| 1   | Global overview  | Where is forest loss concentrated?     |
| 2   | Time trends      | How has it evolved 2001–2022?          |
| 3   | Loss ↔ Carbon    | Is loss correlated with emissions?     |
| 4   | Spatial hotspots | Which subnational regions matter most? |
| 5   | Carbon budget    | Sink or source?                        |
| ⭑   | Bonus            | Animated 20-year ranking race          |

------------------------------------------------------------------------

## 2. Dataset

### Source

All four CSV files are taken from the Kaggle release [**Global Forest Data: 2001–2022**](https://www.kaggle.com/datasets/karnikakapoor/global-forest-data-2001-2022) (uploaded by Karnika Kapoor, January 2024), which mirrors the official [**Global Forest Watch (GFW)**](https://www.globalforestwatch.org/) country / subnational summary tables. The two upstream geospatial products are:

- **Tree-cover loss** — UMD GLAD lab, [Hansen et al. (2013)](https://www.science.org/doi/10.1126/science.1244693), updated annually.
- **Forest carbon flux** — [Harris et al. (2021)](https://doi.org/10.1038/s41558-020-00976-6), refined in [Gibbs et al. (2025)](https://essd.copernicus.org/articles/17/1217/2025/).

### How the data was collected

The upstream observations are produced by **satellite remote sensing**, not surveys:

1.  **Imagery** — Landsat-7 / 8 / 9 scenes (30 m resolution) are mosaicked globally for every year from 2000 onward.
2.  **Per-pixel forest definition** — each 30 m pixel is classified by its *percent tree-canopy cover in the year 2000* (the `threshold` column in this dataset). A pixel only counts as "forest" once its canopy cover exceeds the chosen threshold (10 %, 30 %, 50 %, 75 %).
3.  **Loss detection** — a pixel is flagged as *tree-cover loss* in year *t* when its canopy is removed (clear-cut, fire, windthrow, conversion). Loss area (ha) is reported per country × year × threshold.
4.  **Carbon flux** — aboveground biomass is estimated from satellite-LiDAR (GEDI / ICESat) calibrated against field plots; gross emissions, gross removals and net flux (Mg CO₂e / yr) are derived from the loss raster + biomass raster + IPCC-style carbon-pool factors.
5.  **Spatial aggregation** — pixels are summed inside official country and subnational-1 (state / province) administrative boundaries, producing the four CSVs used by this app.

> **Caveat — not the same as "deforestation".** GFW measures any tree-cover *removal*, including planned timber rotations, fires, and storms. Boreal "loss" often regrows; tropical "loss" usually does not.

### Files

| File | Unit of analysis | Years | Key columns |
|------------------|------------------|------------------|------------------|
| `Country-tree-cover-loss.csv` | country × threshold | 2001–2022 | `tc_loss_ha_<year>`, `extent_2000_ha`, `gain_2000–2020_ha` |
| `Country-carbon-data.csv` | country × threshold | 2001–2022 + averages | `gross_emissions_<year>`, `gross_removals`, `net_flux`, `aboveground_carbon_stocks_2000` |
| `Subnational-1-tree-cover-loss.csv` | country × admin-1 × threshold | 2001–2022 | same as country, plus `subnational1` |
| `Subnational-1-carbon-data.csv` | country × admin-1 × threshold | 2001–2022 | same as country carbon |

`threshold` (one of 10, 15, 20, 25, 30, 50, 75 %) is the canopy-cover cutoff that defines "forest" — see the **ⓘ** popover next to any threshold control inside the app.

### License

The Kaggle mirror are **Database Contents License (DbCL) v1.0** — free to redistribute and modify with attribution.

- Hansen, M. C. et al. (2013) "High-Resolution Global Maps of 21st-Century Forest Cover Change." *Science* 342: 850–853.
- Harris, N. L. et al. (2021) "Global maps of twenty-first century forest carbon fluxes." *Nature Climate Change* 11: 234–240.
- Gibbs, D. A. et al. (2025) "An updated global biomass map for forest carbon flux." *Earth System Science Data* 17: 1217.
- Kapoor, K. (2024) *Global Forest Data: 2001–2022*. Kaggle.

App code is **MIT** (see `LICENSE`).

### Cleaning steps (`data-raw/prep_data.R`)

The raw CSVs ship in **wide** format (one column per year). Our preprocessing:

1.  Read all four CSVs and lower-case column names.
2.  Pivot `tc_loss_ha_2001 … tc_loss_ha_2022` and the per-year `gross_emissions_<year>` columns into **long** format (`year`, `value`).
3.  Coerce numeric columns; replace blanks / `"#N/A"` with `NA`.
4.  Drop empty / aggregate rows (e.g. blank country names).
5.  Join **loss × carbon** on `(country, [subnational1,] threshold, year)`.
6.  Add `region` / `continent` via the `countrycode` package.
7.  Cache the four resulting tables as compressed `.rds` files in `data/`. The app loads these on launch (so the slow CSV parse only runs once).

------------------------------------------------------------------------

## 3. Repo structure

```         
forest-loss-shiny/
├── app.R                       # global + ui + server in one file
├── helpers.R                   # all shared helpers (data + plot + theme)
├── modules/                    # one file per chapter
│   ├── mod_01_overview.R
│   ├── mod_02_trends.R
│   ├── mod_03_loss_carbon.R
│   ├── mod_04_hotspots.R
│   ├── mod_05_budget.R
│   └── mod_99_bonus_race.R
├── data-raw/                   # raw CSVs + prep script
│   ├── Country-tree-cover-loss.csv
│   ├── Country-carbon-data.csv
│   ├── Subnational-1-tree-cover-loss.csv
│   ├── Subnational-1-carbon-data.csv
│   └── prep_data.R
├── data/                       # generated .rds (git-ignored)
├── www/
│   ├── custom.css
│   └── about.md
├── docs/
│   ├── narrative.md            # full storyline
│   └── division-of-labour.md   # who does what
├── .gitignore
├── LICENSE
└── README.md
```

------------------------------------------------------------------------

## 4. Team

| \# | Member | Module | Cross-cutting role |
|------------------|------------------|------------------|------------------|
| 1 | CHEN, Yanyu | Ch.1 Overview | Repo lead · Git workflow · final integration |
| 2 | CHEN, Hongxing | Ch.2 Trends | Data engineer (`prep_data.R`) |
| 3 | WING, Yui Yan | Ch.3 Loss ↔ Carbon | Narrative writer (Intro page + insights) |
| 4 | LI, Yuan | Ch.4 Hotspots | Cartography (Leaflet + polygons) |
| 5 | YING, Yuling | Ch.5 Budget + Bonus race | Design / UX / theming + demo recording |

------------------------------------------------------------------------

## 5. Citation

> Hansen, M. C., et al. (2013). *Science* 342, 850–853. Harris, N. L., et al. (2021). *Nature Climate Change* 11, 234–240. Gibbs, D. A., et al. (2025). *Earth System Science Data* 17, 1217. [Group N] (2026). *Global Forest Tree Cover Loss & Carbon Flux Shiny App*. DASC 3240, HKUST.
