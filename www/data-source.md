---

editor_options: 
  markdown: 
    wrap: 72
---

## About the data

### Source

All four CSV files come from the Kaggle release [**Global Forest Data: 2001–2022**](https://www.kaggle.com/datasets/karnikakapoor/global-forest-data-2001-2022) (uploaded by Karnika Kapoor, January 2024). The Kaggle release is itself a mirror of the official [**Global Forest Watch (GFW)**](https://www.globalforestwatch.org/) country / subnational summary tables, which combine two peer-reviewed geospatial products:

- **Tree-cover loss** — University of Maryland *GLAD* lab, derived from **Hansen et al. (2013)**, *Science* 342: 850–853, updated annually.
- **Forest carbon flux** — **Harris et al. (2021)**, *Nature Climate Change* 11: 234–240, refined in **Gibbs et al. (2025)**, *Earth System Science Data* 17: 1217.

License: **Database Contents License (DbCL) v1.0** for the Kaggle mirror — free to redistribute and modify with attribution.

### How the upstream data was collected

The underlying observations are not survey-based; they are produced by **satellite remote sensing**.

### Files in this project

| File | Unit of analysis | Years | Key columns |
|------------------|------------------|------------------|------------------|
| `Country-tree-cover-loss.csv` | country × threshold | 2001–2022 | `tc_loss_ha_<year>`, `extent_2000_ha`, `gain_2000–2020_ha` |
| `Country-carbon-data.csv` | country × threshold | 2001–2022 + averages | `gfw_forest_carbon_gross_emissions_<year>`, `gross_removals`, `net_flux`, `aboveground_carbon_stocks_2000` |
| `Subnational-1-tree-cover-loss.csv` | country × admin-1 × threshold | 2001–2022 | same as country, plus `subnational1` |
| `Subnational-1-carbon-data.csv` | country × admin-1 × threshold | 2001–2022 | same as country carbon |

`threshold` (one of 10, 15, 20, 25, 30, 50, 75 %) is the canopy-cover cutoff that defines "forest" — see the **ⓘ** popover next to any threshold control inside the app.
