# Forests After COP26

An interactive R Shiny app exploring global tree-cover loss and forest carbon flux from **2001 to 2022** — telling the story of the broken **COP26 Glasgow Declaration on Forests** (2021), which 145 countries signed pledging to halt forest loss by 2030, only to see tropical primary forest loss **rise 10% in 2022**, with major countries flipping from carbon **sinks to sources**.

> 一个 R Shiny 互动应用，可视化 2001–2022 年全球森林流失与碳通量。讲述 COP26 格拉斯哥森林宣言（2021 年 145 国承诺 2030 年前停止毁林）落空的故事 —— 2022 年热带原始森林流失反而上升 10%，主要国家从碳汇翻转为碳源。

---

## Quick start — run from GitHub / 快速运行

```r
# install required packages once / 首次安装依赖
install.packages(c(
  "shiny", "bslib", "plotly", "dplyr", "scales", "htmltools"
))

# run the app directly from GitHub / 直接从 GitHub 运行
shiny::runGitHub("forests-after-cop26", "<your-github-username>")
```

Replace `<your-github-username>` with the GitHub account that hosts this repo.

---

## What you'll see / 应用功能

The app has **four tabs**:

| Tab | Description / 说明 |
|---|---|
| **World map** 世界地图 | Interactive plotly choropleth. Toggle tree-cover loss vs. net carbon flux, slide through years 2001–2022, change canopy threshold. KPI cards show global totals. |
| **Racing bar** 动态柱状图 | A pre-rendered `gganimate` GIF of the top 12 countries by cumulative tree-cover loss 2001–2022. |
| **Country drill-down** 国家详情 | Pick a country to see annual loss (with COP26 dashed line), top 10 subnational regions, and 2022 sink/source status. |
| **About** 关于 | Data source, license, story background, methodology, caveats, reproduce instructions. |

---

## Headline finding / 核心发现

> **145 countries pledged at COP26 (2021) to halt forest loss by 2030.**
> But tropical primary forest loss **rose 10% in 2022 vs. 2021**, and major tropical countries (notably **Indonesia**) have flipped from net carbon **sinks to sources** since the early 2000s.

Anchors:
- [GFW 2022 tree cover loss report](https://www.globalforestwatch.org/blog/forest-insights/global-tree-cover-loss-data-2022/)
- [Mongabay: 10% increase in primary tropical forest loss in 2022](https://news.mongabay.com/2023/06/new-data-show-10-increase-in-primary-tropical-forest-loss-in-2022/)

---

## Data / 数据

- **Source**: [Global Forest Data 2001–2022](https://www.kaggle.com/datasets/karnikakapoor/global-forest-data-2001-2022) (Kaggle)
- **Origin**: Hansen / UMD tree-cover-loss + Harris et al. 2021 forest carbon flux, distributed by [Global Forest Watch](https://www.globalforestwatch.org/)
- **License**: [Open Database License (ODbL) 1.0](https://opendatacommons.org/licenses/odbl/1.0/) — free to share and adapt with attribution
- **Coverage**: 236 countries × 8 canopy thresholds (0, 10, 15, 20, 25, 30, 50, 75 %) × 2001–2022, plus subnational level 1 (states/provinces)

---

## Project structure / 项目结构

```
forests-after-cop26/
├── app.R                          # Shiny app entry point (4 tabs)
├── R/
│   └── plot_helpers.R             # plotly + KPI helpers
├── data/
│   ├── country_panel.rds          # tidy long-form country panel
│   └── sub_panel.rds              # subnational level-1 panel
├── data-raw/
│   ├── 01_prepare_data.R          # CSV -> RDS pipeline
│   ├── 02_render_racing_gif.R     # gganimate GIF renderer
│   ├── Country-carbon-data.csv
│   ├── Country-tree-cover-loss-2.csv
│   ├── Subnational-1-carbon-data-3.csv
│   └── Subnational-1-tree-cover-loss-4.csv
├── www/
│   └── racing_bar.gif             # pre-rendered animation (Tab 2)
└── README.md
```

`shiny::runGitHub()` downloads the whole repo (including the `.rds` files and the `.gif`), so end users do **not** need to re-run the prep scripts.

---

## Reproducing the data prep / 重新运行数据准备 (optional)

If you want to regenerate the `.rds` files or the racing GIF from the raw CSVs:

```r
# extra packages for prep
install.packages(c(
  "tidyr", "readr", "stringr", "countrycode",
  "ggplot2", "gganimate", "gifski", "viridisLite"
))

# regenerate panels
source("data-raw/01_prepare_data.R")

# regenerate racing GIF
source("data-raw/02_render_racing_gif.R")
```

---

## Required packages / 所需 R 包

**Minimum to run the app** (just to use Shiny):
```
shiny, bslib, plotly, dplyr, scales, htmltools
```

**Additional for data prep**:
```
tidyr, readr, stringr, countrycode
```

**Additional for re-rendering the racing GIF**:
```
ggplot2, gganimate, gifski, viridisLite
```

R version used during development: **R 4.5.0**.

---

## Story / 叙事背景

At **COP26 in Glasgow (Nov 2021)**, leaders of **145 countries** signed the *Glasgow Leaders' Declaration on Forests and Land Use*, pledging to "halt and reverse forest loss and land degradation by 2030." It covered ~85% of the world's forests.

One year later, the data tells a different story:
- Global tree-cover loss in 2022 was about the same as 2021 — no decline.
- **Tropical primary forest loss rose ~10%** in 2022 vs. 2021.
- **Indonesia is a net carbon source** as of the latest year (positive net flux), and Brazil's Amazon states (Pará, Mato Grosso, Amazonas) dominate national loss.

This app lets you explore the data behind those headlines — country by country, year by year, region by region.

> COP26 格拉斯哥峰会上 145 个国家承诺 2030 年前停止毁林。然而一年后：2022 年全球热带原始森林流失反而上升约 10%；印尼已经成为净碳源；巴西亚马逊州（帕拉、马托格罗索、亚马逊纳斯）主导全国流失。这个应用让你逐国、逐年、逐区地查看数据背后的故事。

---

## Caveats / 注意事项

- **Tree-cover loss ≠ deforestation.** GFW's loss layer includes natural disturbances (fire, wind), plantation harvest, and land conversion. Not all loss is permanent forest conversion.
- **Canopy threshold matters.** The slider lets you compare 0 % to 75 %. Higher thresholds = denser, more "forest-like" pixels only.
- **Net carbon flux** combines emissions from tree cover loss with sequestration from regrowth. Negative = net sink, positive = net source. Methodology follows Harris et al. (2021).
- **Country names** come from GFW's table; ISO3 codes are added via the `countrycode` R package, with manual fallbacks for a handful of cases (Kosovo, Micronesia, Saint-Martin, etc.).

---

## Course context

Built for **DASC 3240 — Data Visualization** (HKUST). Uses **plotly** for the interactive choropleth and trend charts, and **gganimate** for the racing bar animation, per the assignment's requirement to combine interactive and animated visualizations.

---

## License / 许可证

- **Code**: MIT (feel free to fork and learn from it).
- **Data**: ODbL 1.0 — credit Hansen/UMD and Global Forest Watch when sharing derived figures.
