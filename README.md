# 🌳 Global Forest Tree Cover Loss & Carbon Flux (2001–2022)

**DASC 3240 — Final Project, 2025/26 Spring · HKUST**
**Instructor:** Dr. Masayuki USHIO

An interactive Shiny app that walks through the global pattern of forest tree-cover loss between 2001 and 2022 and its relationship with forest carbon emissions.

---

## 🚀 Run the app (one-liner)

```r
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
shiny::runGitHub("forest-loss-shiny", "<your-org-or-user>", ref = "main")
```

### System libraries (Linux only)

On Debian/Ubuntu the spatial stack and a few build tools are required:

```bash
sudo apt-get install -y libgdal-dev libproj-dev libudunits2-dev libgeos-dev \
                        libabsl-dev cmake cargo rustc libuv1-dev
```

On macOS / Windows the binary CRAN packages already include these libraries — no extra steps needed.

To run locally:

```bash
git clone https://github.com/<your-org-or-user>/forest-loss-shiny.git
cd forest-loss-shiny
```

```r
shiny::runApp(".")
```

The first launch runs `data-raw/prep_data.R` automatically (~30 s) to build the cached `.rds` files in `data/`.

---

## 1. Research question

**Between 2001 and 2022, which countries and subnational regions experienced the most severe forest tree-cover loss, how is this loss related to forest carbon emissions, and which spatial hotspots deserve highest priority?**

The narrative arc:

| # | Chapter | Question |
|---|---|---|
| 1 | Global overview      | Where is forest loss concentrated? |
| 2 | Time trends          | How has it evolved 2001–2022? |
| 3 | Loss ↔ Carbon        | Is loss correlated with emissions? |
| 4 | Spatial hotspots     | Which subnational regions matter most? |
| 5 | Carbon budget        | Sink or source? |
| ⭑ | Bonus                | Animated 20-year ranking race |

---

## 2. Dataset

### Source
All four CSV files are from **[Global Forest Watch (GFW)](https://www.globalforestwatch.org/)**:
- **Tree-cover loss** — UMD GLAD lab, [Hansen et al. (2013)](https://www.science.org/doi/10.1126/science.1244693), updated annually.
- **Forest carbon flux** — [Harris et al. (2021)](https://doi.org/10.1038/s41558-020-00976-6), updated in [Gibbs et al. (2025)](https://essd.copernicus.org/articles/17/1217/2025/).

### Files

| File | Unit | Years |
|---|---|---|
| `Country-tree-cover-loss.csv` | country × threshold | 2001–2022 |
| `Country-carbon-data.csv` | country × threshold | annual emissions + average removals & net flux |
| `Subnational-1-tree-cover-loss.csv` | country × subnational1 × threshold | 2001–2022 |
| `Subnational-1-carbon-data.csv` | country × subnational1 × threshold | as above |

### License

Both datasets are **CC BY 4.0** — free to redistribute and modify with attribution.
- Hansen, M. C. et al. (2013) "High-Resolution Global Maps of 21st-Century Forest Cover Change." *Science* 342: 850–853.
- Harris, N. L. et al. (2021) "Global maps of twenty-first century forest carbon fluxes." *Nature Climate Change* 11: 234–240.

App code is **MIT** (see `LICENSE`).

### Cleaning steps (see `data-raw/prep_data.R`)
1. Read raw CSVs → lower-case column names.
2. Pivot wide year columns (`tc_loss_ha_2001…2022`) to long format.
3. Coerce numeric, replace blanks with `NA`.
4. Drop empty / aggregate rows.
5. Join loss × carbon on `(country, [subnational1,] threshold, year)`.
6. Add `region` / `continent` via `countrycode`.
7. Cache as `.rds` in `data/`.

---

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

---

## 4. Team

See [`docs/division-of-labour.md`](docs/division-of-labour.md).

| # | Member | Module | Cross-cutting role |
|---|---|---|---|
| 1 | A | Ch.1 Overview | Repo lead · Git workflow · final integration |
| 2 | B | Ch.2 Trends   | Data engineer (`prep_data.R`) |
| 3 | C | Ch.3 Loss ↔ Carbon | Narrative writer (Intro page + insights) |
| 4 | D | Ch.4 Hotspots | Cartography (Leaflet + polygons) |
| 5 | E | Ch.5 Budget + Bonus race | Design / UX / theming + demo recording |

---

## 5. Citation

> Hansen, M. C., et al. (2013). *Science* 342, 850–853.
> Harris, N. L., et al. (2021). *Nature Climate Change* 11, 234–240.
> Gibbs, D. A., et al. (2025). *Earth System Science Data* 17, 1217.
> [Group N] (2026). *Global Forest Tree Cover Loss & Carbon Flux Shiny App*. DASC 3240, HKUST.
