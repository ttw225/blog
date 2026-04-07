---
title: "Commitizen 程式碼區塊跑版"
slug: "commitizen-broken-docs"
date: 2026-04-03T17:27:37+08:00
description: "官網文件站 fenced code 解析異常：Pygments 2.20.0 的 HtmlFormatter 在 filename=None 時出錯，導致 pymdown 高亮鏈失敗；上游 issue/PR 與兩種避險路徑（pin Pygments 或升級 pymdown-extensions）。"
tags: ["commitizen", "mkdocs", "pygments", "pymdown", "github-pages"]
categories: ["open-source"]
featureimage: "img/commitizen-broken-docs/cover.jpeg"
---

{{< postimg "broken-docs.jpeg" >}}

> [!NOTE]
> **最新進展：已避開此問題**
> Commitizen 在合併 PR [commitizen-tools/commitizen#1924](https://github.com/commitizen-tools/commitizen/pull/1924) 後，文件站已恢復正常顯示。
> 這次解法的重點是升級文件工具鏈 `pymdown-extensions`。

## 發生了什麼事

Commitizen [官方文件](https://commitizen-tools.github.io/commitizen/)（MkDocs + Material，部署到 GitHub Pages）出現 **fenced code block 沒被正確渲染** 的現象：`` ```bash `` 像一般文字出現在段落裡，程式碼裡以 `#` 開頭的註解甚至被當成 **Markdown 標題**（`<h1>`）。

在靜態 HTML 裡可以對照到典型特徵：fence 起始行出現在 `<p>` 裡，而不是變成 `<div class="highlight"><pre><code>…`；`#` 開頭的行被當成 ATX heading。

## 問題在哪裡

**[Pygments](https://github.com/pygments/pygments) 2.20.0** 中，`HtmlFormatter` 會對 `filename` 做 `html.escape(...)`。若呼叫端把 **`filename` 設成 `None`**，`html.escape(None)` 在 Python 3 會拋出：

`AttributeError: 'NoneType' object has no attribute 'replace'`

## 技術鏈

官方文件站以 **MkDocs + Material** 撰寫，程式碼區塊為 **fenced code block**。常見設定會啟用 **`pymdownx.highlight`** 與 **`pymdownx.superfences`**。當 fenced code **沒有 title** 時，`pymdownx.highlight` 建立 `HtmlFormatter` 以 `filename=title` 的形式把 **`None`** 傳給 Pygments；高亮步驟一失敗，`pymdownx.superfences` 就 **無法把 fenced 區塊換成預期的 HTML**，未被替換的 fence 與內容會再被當成一般 Markdown 解析，於是出現「fence 像純文字」「`#` 變標題」的組合。

{{< mermaid >}}
flowchart TD
  fence[fenced code, no fence title]
  ph[pymdownx.highlight]
  crash["Pygments 2.20.0: html.escape on None"]
  sf[pymdownx.superfences cannot replace fence]
  md[Markdown reparses body]
  bad["# lines become ATX headings"]

  fence --> ph
  ph --> crash
  crash --> sf
  sf --> md
  md --> bad
{{< /mermaid >}}

同一套 Markdown 來源若在本機 `mkdocs build` 正常、但 [gh-pages 產物](https://github.com/commitizen-tools/commitizen/tree/gh-pages) 異常，多半要往 **建置依賴版本**（例如 lockfile 解析到 `pygments==2.20.0`）或建置環境查，而不是單純瀏覽器顯示問題。

## 如何處理

### Pygments

Pygments 已追蹤並合併修正，預計在 **2.20.1** 發佈。

- Issue（closed）：[pygments/pygments#3076](https://github.com/pygments/pygments/issues/3076)
- Fix（merged）：[pygments/pygments#3078](https://github.com/pygments/pygments/pull/3078)（Handle `None` before HTML escaping）

### 使用 MkDocs PyMdown 套件的專案

`pymdown-extensions 10.21.2` 修正了與新版 Pygments、`filename=None` 相關的高亮問題。

參考資訊： [changelog](https://github.com/facelessuser/pymdown-extensions/releases/tag/10.21.2)

### 其他使用到 Pygments 的專案（修復前）

若專案（例如文件建置流程）有依賴到 Pygments，在升級到「含修復版本」之前，實務上可先做暫時避險：**把 Pygments 鎖在 2.20 以下**，例如：

- `pygments==2.19.2`，或
- `pygments<2.20`

類似做法可參考：[jj-vcs/jj#9233](https://github.com/jj-vcs/jj/pull/9233)。等上游修復版本發佈並升級後，再鬆綁 pin，並以 `mkdocs build` 確認 fenced code 渲染正常。

### Commitizen PR #1924 是怎麼避開的

透過升級文件相依套件來避開觸發條件，關鍵包括：

- `pymdown-extensions`：`10.19.1 -> 10.21.2`
- `mkdocs-material`：`9.7.1 -> 9.7.6`
- `pygments` 在 lockfile 仍是 `2.20.0`


### 附錄：Pygments 最小重現

本機若已安裝 `pygments==2.20.0`，下面片段應會拋出上述 `AttributeError`；在 **2.19.2** 則通常不會：

```python
from pygments.formatters.html import HtmlFormatter

HtmlFormatter(filename=None)
```

## 我做了什麼

### 從程式碼找問題

1. 發現官網程式碼區塊跑版
2. 本機編譯卻正常
3. 觀察改動與環境差異，發現 Pygments 版本不同
4. 查看 [線上產物](https://github.com/commitizen-tools/commitizen/tree/gh-pages)，HTML 已不正確，推測問題在產出流程
5. **比對不同 Pygments 版本產出的 HTML**
6. 手動測試 Pygments，確認 `filename=None` 是關鍵
7. 查 Pygments Issue / PR，確認已有回報與修正

### 回覆 Issue 分享原因與解法

於 Commitizen Issue [Broken docs #1922](https://github.com/commitizen-tools/commitizen/issues/1922#issuecomment-4181595422) 留言（節錄如下）。

```text
Root cause: pygments==2.20.0 regressed HtmlFormatter so that when filename is None, it calls html.escape() on None and crashes with AttributeError: 'NoneType' object has no attribute 'replace'.

In our MkDocs stack, pymdownx.highlight ends up passing filename=None in the common case (no fence title), so the highlight step fails; pymdownx.superfences then doesn’t replace the fence, and the remaining text is parsed as normal Markdown — which is why fenced bash blocks and lines starting with # show up as plain text / headings.

Upstream:
- Issue: https://github.com/pygments/pygments/issues/3076
- Fix (merged): https://github.com/pygments/pygments/pull/3078 (targeted for Pygments 2.20.1)

Possible mitigation until a Pygments release with the fix is available: pin pygments<2.20 for the docs build (similar approach: https://github.com/jj-vcs/jj/pull/9233).
```
