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

## CPython

{{< github repo="python/cpython" showThumbnail=false >}}

CPython 是 [Python](https://www.python.org) 的參考實作，由大量活躍的開發者共同維護。
我開始投入 CPython，是受到 [PyCon TW](https://pycon.tw) 與 [高見龍大大](https://pythonbook.cc/about) 衝刺開發活動的啟發。教材可參考 [《為你自己學 Python》](https://pythonbook.cc/chapters/basic/introduction) 的介紹章節。

### Open PR

這些貢獻正在進行中：

- [gh-139819: rlcompleter – avoid suggesting attributes not accessible on instances](https://github.com/python/cpython/pull/139820)
  - 優化 `rlcompleter`：自動補全時略過在實例上無法存取的屬性
  - 狀態：仍在等待 review，討論串很安靜 QQ

### Merged PR

這些貢獻已被合併進 CPython：

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
- [Refactor: Doc(images) VHS tapes with shared snippets](https://github.com/commitizen-tools/commitizen/pull/1906)
  - 重構用於產生指令動圖的 VHS 錄影腳本
  - 將重複片段抽成共用片段，降低重複並降低撰寫門檻
- [Feat: add live subject preview for interactive commit (--preview)](https://github.com/commitizen-tools/commitizen/pull/1902)
  - 在互動式 commit 流程中，為 commit subject 提供即時預覽
- [Fix and improve test: message_length_limit](https://github.com/commitizen-tools/commitizen/pull/1900)
  - 修正並擴充與 `message_length_limit` 設定相關的測試
  - Featured write-up:
{{< article link="/blog/posts/commitizen-argparse-none-get-trap/" showSummary=false compactSummary=false >}}

### Merged PR

這些貢獻已合併進 Commitizen：

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

- PyCon TW 2025: 議程組、公關組組員
- PyCon TW 2026: 議程組、公關組組員

---

## 文章

我把這裡當成開源日記，記錄大大小小的貢獻與雜事～
