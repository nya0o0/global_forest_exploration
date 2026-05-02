## About this project

Built for **DASC 3240 — Final Project**, 2025/26 Spring (HKUST · Dr. Masayuki USHIO).

### The story

1.  **Global overview** — forest loss is geographically unequal.
2.  **Time trends** — turning points reveal policy and fire shocks.
3.  **Loss ↔ Carbon** — losses and emissions are tightly correlated, especially in the tropics.
4.  **Spatial hotspots** — within countries, a few subnational regions drive most of the damage.
5.  **Carbon budget** — some forests have already flipped from sink to source.

### Data

- **Dataset:** [Global Forest Data: 2001–2022](https://www.kaggle.com/datasets/karnikakapoor/global-forest-data-2001-2022) on Kaggle (Karnika Kapoor, 2024) — mirror of [Global Forest Watch](https://www.globalforestwatch.org) country / subnational summary tables. Database: Open Database, Contents: Database Contents.
- **Tree-cover loss** — [Hansen et al. (2013)](https://www.science.org/doi/10.1126/science.1244693), *Science* 342: 850–853 (UMD GLAD lab, updated annually).
- **Forest carbon flux** — [Harris et al. (2021)](https://doi.org/10.1038/s41558-020-00976-6), *Nature Climate Change* 11: 234–240; updated in [Gibbs et al. (2025)](https://essd.copernicus.org/articles/17/1217/2025/), *Earth System Science Data* 17, 1217.

A detailed description of the four CSV files, the satellite-based collection method, and our preprocessing steps is on the **Intro** tab (“Data source, collection method & cleaning steps”) and in [`www/data-source.md`](data-source.md).

### Code

Source: <https://github.com/nya0o0/global_forest_exploration> · MIT License.

### Team

| Member | Role                                        |
|--------|---------------------------------------------|
| CHEN, Yanyu      | Repo lead, Chapter 1 (Overview)             |
| CHEN, HongXing      | Data engineer, Chapter 2 (Trends)           |
| WING, Yui Yan      | Narrative writer, Chapter 3 (Loss ↔ Carbon) |
| Li, Yuan     | Cartographer, Chapter 4 (Hotspots)          |
| Ying, Yuling      | Designer + Bonus race, Chapter 5 (Budget)   |
