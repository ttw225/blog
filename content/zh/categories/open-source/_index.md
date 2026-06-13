---
title: "開源"
linkTitle: "開源"
description: "開源專案與貢獻紀錄。"
url: /open-source/
aliases:
  - /tags/open-source/
  - /categories/open-source/
cascade:
  showReadingTime: false
  showWordCount: false
  showDate: true
cardView: true
groupByYear: false
---

這頁整理我的開源貢獻與代表性的專案。

## Wren AI

{{< github repo="Canner/WrenAI" showThumbnail=false >}}

[Wren AI](https://github.com/Canner/WrenAI) 是一個開源的 AI agent context layer，透過 MDL 語意模型補足資料庫 schema 缺少的商業語意、範例與記憶，讓 AI 能在權限與查詢規則約束下產生可信任的 SQL、圖表與分析。

### Open PR

進行中：

- [chore(wren-core-py): migrate from Poetry to uv](https://github.com/Canner/WrenAI/pull/2363)
  - `core/wren-core-py` 是 repo 裡唯一仍用 Poetry 的 Python 模組，其餘已是 uv；原先建置 Rust binding 也得先走 Poetry 環境跑 maturin。PR 把這條 dev/build 流程改到 uv（build backend 仍是 maturin），並對齊 justfile 與 CI，讓 Rust→binding→CLI 整條鏈不再混用兩套工具。

### Merged PR

已合併進 Wren AI：

- [docs(wren): fix cube quickstart and align YAML/CLI examples with implementation](https://github.com/Canner/WrenAI/pull/2359)
  - 在官方 [QuickStart](https://docs.getwren.ai/oss/get_started/quickstart) 文件中補上缺少的 Cube 建立流程，並修正範例寫法，讓 YAML / CLI 範例符合範例資料的欄位設計、與實作一致
- [fix(memory): avoid identifier columns in aggregation seed queries](https://github.com/Canner/WrenAI/pull/2358)
  - `wren memory index` 會自動生成一批 seed NL→SQL pair 寫入向量庫，供之後的 `recall` 以相似度檢索。但 seed 生成把 `customer_id` 這類 foreign key 當成可加總的度量，生成 `SUM(customer_id)` 這類無意義 seed 並降低檢索品質；修正改為排除 foreign key / `*_id` 欄位
  - 相關文章:
{{< article link="/blog/posts/wren-memory-seed-query-noise/" showSummary=false compactSummary=false >}}
- [perf(cli): use find_spec instead of eager import to detect memory extra](https://github.com/Canner/WrenAI/pull/2352)
  - 把 CLI 偵測可選 extra 的方式從 eager import 整套 ML stack 改成 `find_spec`，讓 `wren --version` / `--help` 加速約 6–11x，且 torch 等大型套件不會進入 `sys.modules`
  - 相關文章:
{{< article link="/blog/posts/wren-cli-startup-find-spec/" showSummary=false compactSummary=false >}}
- [docs(wren): document macOS memory first-run scan](https://github.com/Canner/WrenAI/pull/2354)
  - 記錄 macOS 首次執行 ~50s 的真正來源是 XProtect 對未簽章原生 binary 的一次性掃描，並非 wren 本身的缺陷
- [fix(wren): load cubes from folder-per-entity layout](https://github.com/Canner/WrenAI/pull/2350)
  - 修正 cube loader 掃描的資料夾架構：從 v1 `cubes/<name>.yml` 升級成 v2 `cubes/<name>/metadata.yml`
- [ci(release): sync wrenai version in uv.lock](https://github.com/Canner/WrenAI/pull/2351)
  - 讓每次 release 自動同步 `uv.lock` 內的 `wrenai` 版本

---

## CPython

{{< github repo="python/cpython" showThumbnail=false >}}

CPython 是 [Python](https://www.python.org) 的參考實作，由大量活躍的開發者共同維護。
我開始投入 CPython，是受到 [PyCon TW](https://pycon.tw) 與 [高見龍大大](https://pythonbook.cc/about) 衝刺開發活動的啟發。教材可參考 [《為你自己學 Python》](https://pythonbook.cc/chapters/basic/introduction) 的介紹章節。

### Merged PR

這些貢獻已被合併進 CPython：

- [gh-139819: rlcompleter – avoid suggesting attributes not accessible on instances](https://github.com/python/cpython/pull/139820)
  - 優化 `rlcompleter`：自動補全時略過在實例上無法存取的屬性
- [gh-139487: doc(enum): add missing imports for standalone doctest examples](https://github.com/python/cpython/pull/139488)
  - 在 enum 說明文件中，為可獨立執行的 doctest 範例補上缺少的 import
- [gh-139743: avoid import-time print in test_sqlite3 that leaks into help('modules')](https://github.com/python/cpython/pull/139746)
  - 修正 `sqlite3` 測試，避免 import 時的輸出汙染 `help('modules')`

---

## Commitizen

{{< github repo="commitizen-tools/commitizen" showThumbnail=false >}}

[Commitizen](https://github.com/commitizen-tools/commitizen) 是以 Python 撰寫的工具，協助寫出一致的 Git commit message，並支援自動化、外掛與套件發佈等流程。
強者我學長 [Wei Lee](https://github.com/Lee-W) 帶我入門；他是台灣唯一的 [Apache Airflow](https://github.com/apache/airflow/) PMC Member。可以參考他的部落格：[成為 Airflow PMC Member](https://blog.wei-lee.me/posts/tech/2025/10/becoming-an-airflow-pmc-member/)。

### Open PR

這些貢獻正在進行中：

- [Feat: Validate message_length_limit is non-negative](https://github.com/commitizen-tools/commitizen/pull/1908)
  - 明確要求 `message_length_limit >= 0`
- [Feat: add live subject preview for interactive commit (--preview)](https://github.com/commitizen-tools/commitizen/pull/1902)
  - 在互動式 commit 流程中，為 commit subject 提供即時預覽
- [Fix and improve test: message_length_limit](https://github.com/commitizen-tools/commitizen/pull/1900)
  - 修正並擴充與 `message_length_limit` 設定相關的測試
  - 相關文章:
{{< article link="/blog/posts/commitizen-argparse-none-get-trap/" showSummary=false compactSummary=false >}}

### Merged PR

這些貢獻已合併進 Commitizen：

- [Refactor: Doc(images) VHS tapes with shared snippets](https://github.com/commitizen-tools/commitizen/pull/1906)
  - 重構用於產生指令動圖的 VHS 錄影腳本
  - 將重複片段抽成共用片段，降低重複並降低撰寫門檻
  - 相關文章:
{{< article link="/blog/posts/vhs-cli-demo-as-code/" showSummary=false compactSummary=false >}}
- [docs: document and demo use_shortcuts keyboard shortcuts](https://github.com/commitizen-tools/commitizen/pull/1891)
  - 改進 `use_shortcuts` 的文件與範例
- [CI: make release workflows fork-friendly](https://github.com/commitizen-tools/commitizen/pull/1889)
  - 調整 GitHub Actions 觸發條件，避免 fork 在無意間觸發 release 工作流程
- [Doc: Clarify cz_customize deprecation warning with rationale link](https://github.com/commitizen-tools/commitizen/pull/1887)
  - 釐清 `cz_customize` 棄用警告的官方文件說明
- [Resolve tempfile path spaces issue in git commit function](https://github.com/commitizen-tools/commitizen/pull/1039)
  - 第一次貢獻 Commitizen：修正 Git commit 流程中，暫存檔路徑含空白字元時的問題

---

## PyCon Taiwan

[PyCon Taiwan](https://pycon.tw) 在台灣推廣 Python 和開源，每年舉行一次大型技術研討會。我從 2025 年開始加入志工行列。

- PyCon TW 2026: 議程組副組長、審稿委員、公關組組員
- PyCon TW 2025: 議程組、公關組組員

---

## 文章

我把這裡當成開源日記，記錄大大小小的貢獻與雜事～
