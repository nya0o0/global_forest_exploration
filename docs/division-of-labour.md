# 5 人分工方案 · 1 周冲刺版 / Division of labour — 1-week sprint

> **现实**：只剩 ~7 天。目标不是"完美的 app"，而是"按 rubric 全部 6 项都拿到 4 分及以上"的可交付 MVP。
>
> **核心原则**：
> 1. **先纵切，后横切**：第 1–2 天每人把自己模块跑通最简版本（哪怕只有一张静态图），保证 app 能从头到尾点完所有 tab；后面再逐个加交互/美化。
> 2. **数据 + Repo 提前 1 天搞定**：B 与 A 必须在 Day 1 结束前交付可用的 `data/*.rds` 和能 clone 的 repo，否则 C/D/E 全卡住。
> 3. **可砍清单**已标记 ⚠️：时间不够时直接放弃，不要硬撑。
> 4. **不写**：CI / shinyapps.io / 单元测试 / PPT。靠 `runGitHub()` + app 内 Intro 页交差。

---

## 总览：每人交付物

| 成员 | 模块 | 跨模块职能 | 必交（Must） | 可砍（Nice） |
|---|---|---|---|---|
| **A** | Ch.1 Overview | Repo Lead · 整合验收 | 排名 bar + 年份滑块 + threshold | Top-N 滑块、CSV 下载、动画播放按钮 |
| **B** | Ch.2 Trends | Data Engineer | `prep_data.R` 跑通 + 多国折线图 | 拐点标注、年份区间滑块 |
| **C** | Ch.3 Loss↔Carbon | 叙事撰稿人 | 散点 + Pearson r + 1 段叙事 | 回归线、log 轴、size/colour 编码 |
| **D** | Ch.4 Hotspots | 制图师 | Leaflet 地图（默认 Brazil）+ 填色 | 国家选择、点击联动时间序列、metric 切换 |
| **E** | Ch.5 Budget + 设计 | UX | 单国家 emissions/removals/net flux 折线 | Bonus 动画、ranking 视图、CSS 美化 |

---

## 7 天冲刺时间线

| 天 | 全员 | A | B | C | D | E |
|---|---|---|---|---|---|---|
| **D1**<br>(基建) | Kick-off 会 30 min：分工确认 + 每人 demo 各自模块 wireframe | clone 我交付的骨架 → 推到团队 GitHub repo → 加 4 个 collaborator → 每人都能 clone 并跑通 `shiny::runApp(".")` | **跑通 `prep_data.R`** → 提交 4 个 `.rds`（可临时入库，不进 .gitignore）→ 在 Issue 里写 5 行数据列说明 | 通读 `narrative.md` → 修订 Intro 页文案 + 5 个 insight_box 措辞 | 在自己机器装 `rnaturalearth` + `sf` → 跑通 `ne_states("Brazil")` 验证依赖 OK | 装 `gganimate` + `gifski` → 跑通最小 demo 验证依赖 OK |
| **D2**<br>(纵切) | **必须**：每人从 main 拉 `feat/X-mod-XX` 分支，把自己模块的"最简版本"推上去（下面"Must"列） | mod-01 排名 bar 跑通 | mod-02 多国折线（无标注）跑通 | mod-03 散点（无 r/log/trend）跑通 | mod-04 Brazil 默认地图跑通（不要求联动） | mod-05 单国 3 条线跑通（暂不做 ranking） |
| **D3**<br>(整合) | **第一次端到端 review**：A 拉所有 PR 到 main，5 人凑一次屏幕共享，从头到尾点一遍 app，记录 bug list | 合 PR + 在 Issue 列 bug list | 修 D2 数据问题（如有） | 写完所有 insight_box 文字 | 加国家选择下拉 | 加 ranking 视图 |
| **D4**<br>(交互) | 每人加 1–2 个交互 feature（"可砍"列里挑） | Top-N 滑块 + CSV 下载 | 加拐点标注 | 加 log 轴 + 回归线 + Pearson r | 加 metric 切换 + 点击联动 | CSS 全局微调 |
| **D5**<br>(打磨) | UX 大扫除：色盲安全色、axis label、单位、缺失值处理 | 顶层导航测试 | 检查 NA 在所有图里都不报错 | 文案最终定稿 | 测 5 个国家地图（Brazil/Indonesia/DRC/Russia/USA）都能渲染 | Bonus 动画（如有时间）⚠️ |
| **D6**<br>(预演) | **彩排**：在干净电脑（队友 B 的电脑）上 `shiny::runGitHub()` 验证 | 最终验证 + README 截图 | 数据回归测试 | 演讲口播稿 | 答辩 Q&A 准备 | 现场操作 app 跟讲 |
| **D7**<br>(交付) | 上午 buffer + 下午演示 | 守门：merge 一切 fix-only PR | 跟 A 互查 | 主讲 5 min | 协助答疑 | 演示驾驶 |

> **关键里程碑**：
> - D1 末：所有人能 `runApp(".")` 看到完整骨架（无内容也行）
> - D3 末：每个 tab 至少能看到一张图（哪怕静态）
> - D5 末：所有交互都能用，没有 console error
> - D6：在外部电脑上验证 `runGitHub()` 真能跑

---

## 详细分工

### 成员 A — Repo Lead

**Day 1 必做**
- [ ] 把我交付的骨架推到团队 GitHub repo（建议名 `dasc3240-forest-loss`）
- [ ] 加 4 位队友为 collaborator，每人确认能 clone
- [ ] 在 main 设 branch protection（必须 PR 合并）→ 时间紧也可不设，但每人 commit 前手动 pull
- [ ] 自己开 `feat/A-mod-01-overview` 分支

**Day 2 必交（mod-01）**
- [ ] 排名 bar（plotly）+ 年份滑块 + threshold 下拉

**Day 4 加交互**
- [ ] Top-N 滑块、CSV 下载、年份动画播放（直接用 sliderInput 的 animate 参数，1 行）

**整合职责**
- 每天晚上拉所有人 PR 到 main，跑一次 `shiny::runApp(".")`，把报错贴到群里
- D6 必须在外部电脑（同学/家人/B 的电脑）跑通 `shiny::runGitHub()`

---

### 成员 B — Data Engineer

**Day 1 必做（最关键的人，决定后面所有人能不能开工）**
- [ ] `Rscript -e 'source("data-raw/prep_data.R")'` 跑通
- [ ] 把生成的 4 个 `.rds` **临时**也提交到仓库（注释掉 `.gitignore` 里 `data/*.rds` 那一行）→ 这样队友不需要装 countrycode 包就能开发
- [ ] 在仓库开 1 个 Issue：贴上 `head()` 的输出 + 列说明，让 C/D/E 知道每张表长什么样

**Day 2 必交（mod-02）**
- [ ] 多国折线（默认 Top 5），threshold 下拉

**Day 4 加交互**
- [ ] 拐点标注（Brazil 2012/2019 + Indonesia 2016，已有代码骨架）

**已知坑**
- `gross_removals` / `net_flux` 是年均常数（不是年序列），E 的 mod-05 需要特殊处理 → 在 Issue 里特别提醒
- 部分国家在低 threshold 下 carbon 列为 NA → 各模块 filter 时记得 `!is.na()`

---

### 成员 C — 叙事撰稿人 + 统计模块

**Day 1 必做**
- [ ] 通读 `docs/narrative.md` → 改写成更流畅的中/英文（按队伍偏好）
- [ ] 改 `app.R` 里 Intro 页文案、改每个 mod 的 `module_header` subtitle

**Day 2 必交（mod-03）**
- [ ] 气泡散点（plotly），bubble size = `extent_2000_ha`，colour = continent

**Day 4 加交互**
- [ ] log 轴开关、回归线开关、Pearson r 文字输出（已有代码骨架）

**叙事职责**
- 每天回顾全 app insight_box 文字一致性
- D6 写 5 分钟讲稿（按 narrative.md 的过渡话术改）
- D7 主讲

---

### 成员 D — 制图师

**Day 1 必做**
- [ ] 装 `rnaturalearth` `sf`（macOS 可能需要 `brew install gdal`）
- [ ] 跑 `rnaturalearth::ne_states(country = "Brazil")` 验证依赖 OK

**Day 2 必交（mod-04 最简版）**
- [ ] Leaflet 地图，**写死默认 Brazil**，按 `tc_loss_ha` 填色，2022 年
- 不要求国家选择、不要求点击联动 ← 这些放 D3/D4

**Day 3–4 加交互**
- [ ] 国家选择下拉
- [ ] 点击 polygon → 下方时间序列
- [ ] metric 切换（loss / emissions / net flux）

**已知风险与应对**
- subnational1 名字与 `ne_states` 列名不完全匹配 → mod-04 已经写了多列 fallback（`name_en` / `name` / `gn_name`），但仍可能缺 → **应对方案**：测试 5 个国家时如果有匹配率太低的，**就在 UI 里把那个国家从下拉去掉**，不要花时间手工映射
- 时间不够 ⚠️：直接砍掉点击联动，只留地图填色 + tooltip

---

### 成员 E — Ch.5 + 设计

**Day 1 必做**
- [ ] 装 `gganimate` + `gifski`，跑 `gganimate` 官方 demo 验证依赖 OK

**Day 2 必交（mod-05 单国家视图）**
- [ ] Brazil 默认，3 条线（emissions 年序列 + removals 常数 + net flux 推算）

**Day 3 加 ranking 视图**
- [ ] mean net flux 排名条形图（最汇 vs 最源）

**Day 4–5 设计活**
- [ ] CSS 微调（颜色统一）
- [ ] 检查所有模块 axis label 一致性

**Bonus 动画 ⚠️**
- 如果 D5 之前其他工作都搞完，再做 Bonus（mod_99_bonus_race.R 已有骨架）
- 如果时间不够，**直接删掉 `tabPanel("Bonus", ...)` 那一行**，整个 Bonus 模块不影响主线

**演示驾驶**
- D7 现场点击 app 配合 C 的讲解

---

## Git 极简规范（1 周版）

- 每人一个分支：`feat/A-mod-01`, `feat/B-data-prep`, `feat/C-mod-03`, `feat/D-mod-04`, `feat/E-mod-05`
- Commit message 用大白话即可，不强求 conventional commits
- PR 不强求 review，自己合（但 A 每天晚上跑一次完整 app 检查）
- **禁止直接 push 到 main**（除非是 A 在做整合）

---

## 风险与应急

| 风险 | 触发条件 | 应急方案 |
|---|---|---|
| `prep_data.R` 跑不通 | D1 晚上 B 没交付 | A 立刻支援 B；如果 D2 仍跑不通，**临时手工在 Excel 里拼一个最简版数据**（只保留 Top 20 国家） |
| `rnaturalearth` 装不上 | D1 D 装不上 | 改用静态 ggplot 的 choropleth（用 `ggplot2::geom_sf` + 预下载的 `ne_download` 缓存） |
| `gganimate` 在 shinyapps 卡 | 不会出现（我们不部署） | 跳过 |
| 某队友 D3 仍未交付模块 | D3 晚上某 tab 还是空的 | A 把那个 tab 临时改成"Coming soon"占位，确保其他 tab 能用；该队友的工作转给最闲的人 |
| D6 `runGitHub()` 失败 | 外部电脑跑不起来 | 检查（1）是否所有 `library()` 包齐全；（2）`data/*.rds` 是否在仓库；（3）路径用相对路径 |

---

## Rubric 60 pt 自查（每天结束前过一遍）

- [ ] **Dataset & license (5 pt)** → README §2 + LICENSE 文件 → **D1 完成**
- [ ] **Storytelling (5 pt)** → 5 章 + Intro 页 + insight_box → **D5 完成**
- [ ] **Figure appearance (5 pt)** → 所有图有 title / axis label / 单位 / 色盲色 → **D5 完成**
- [ ] **Interactive figures (5 pt)** → 5+ plotly + 1 leaflet → **D4 完成**
- [ ] **Code reproducibility (5 pt)** → `runGitHub()` 在外部电脑跑通 → **D6 完成**
- [ ] **Collaborative work (5 pt)** → 至少 5 人各自有 commit + 有意义的 PR → **D6 完成**

> **保 4 分策略**：每项确保达到 rubric "2–4 (Developing)" 的下限——再往上拼"5 Exceptional"全看时间。优先保所有项都不为零。

---

## 给每个人的"今晚必做"清单（D1）

**A**：建 GitHub repo + 加协作者 + 每人能 clone
**B**：跑通 prep_data + 把 .rds 推上去 + 写数据说明 Issue
**C**：审定 Intro 页 + 5 个 insight_box 文案
**D**：装 rnaturalearth 验证能用
**E**：装 gganimate 验证能用

→ D1 晚上 22:00 群里截图汇报状态。如果有人没完成，A 立即拉群对齐应急方案。
