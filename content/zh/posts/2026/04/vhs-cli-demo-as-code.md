---
title: "產生指令截圖和動圖的利器：VHS"
slug: "vhs-cli-demo-as-code"
date: 2026-04-17T14:04:03+08:00
description: "用 VHS 把 CLI 操作流程寫成 `.tape`，穩定自動產生截圖與 GIF，讓文件維護更省力。"
tags: ["vhs", "cli", "documentation", "automation", "gif"]
categories: ["open-source"]
featureimage: "img/vhs-cli-demo-as-code/cover.gif"
---

{{< postimg "cover.gif" >}}

{{< github repo="charmbracelet/vhs" showThumbnail=false >}}

## 痛點

- 想用圖像化方式展示 CLI 功能（截圖或動圖）。
- 需要錄製互動流程，但每次手動錄影都很耗時。
- 很難維持每次輸出的條件一致，例如終端機大小、背景與執行環境。
- 希望指令執行節奏穩定，畫面輸出可重現（reproducible）。
- 當程式碼改版時，截圖與動圖常常需要整批重做。

## VHS 可以自動化產生指令截圖和動畫

我是在為 [commitizen](https://github.com/commitizen-tools/commitizen) [文件](https://commitizen-tools.github.io/commitizen/)做貢獻時，第一次接觸到 VHS。最吸引我的地方是：

VHS 可以在可重現的狀態下，自動產生終端機截圖與動畫，特別適合用在技術文件的功能展示。

## 使用範例

### 安裝 VHS

使用套件管理工具安裝：
```sh
# macOS or Linux
brew install vhs

# Arch Linux (btw)
pacman -S vhs

# Nix
nix-env -iA nixpkgs.vhs

# Windows using scoop
scoop install vhs
```
更多安裝資訊，請參考[官方文件](https://github.com/charmbracelet/vhs?tab=readme-ov-file#installation)

### Hello World

1. 建立 `demo.tape` 檔案

VHS 透過 `.tape` 檔案描述操作流程：
```elixir {title="demo.tape"}
# Where should we write the GIF?
Output demo.gif

# Set up a 1200x600 terminal with 46px font.
Set FontSize 46
Set Width 1200
Set Height 600

# Type a command in the terminal.
Type "echo 'Welcome to VHS!'"

# Pause for dramatic effect...
Sleep 500ms

# Run the command by pressing enter.
Enter

# Admire the output for a bit.
Sleep 3s
```

2. 執行 VHS

```sh
vhs demo.tape
```

3. 產生 GIF

{{< postimg "demo.gif" >}}

本文開頭的動畫，就是這支 GIF 的製作過程。

## commitizen 文件中如何實際應用

### 截圖

- 每個指令的 `--help` 都會自動產生截圖，並附在文件中。
- 實作細節：
  [gen_cli_help_screenshots.py](https://github.com/commitizen-tools/commitizen/blob/master/scripts/gen_cli_help_screenshots.py) 會從 `commitizen.cli.data` 讀出所有子命令，自動執行 `cz <命令> --help`（外加 `cz --help`）並輸出 SVG。

例如：`cz init --help`

{{< postimg "cz_init___help.svg" >}}

### 動圖

特定功能會額外製作動圖，用來展示互動流程（interactive flow）。

- `.tape` 撰寫
    - 針對不同功能與互動情境，個別撰寫 `.tape`，並存放於 `docs/images/*.tape`。
- VHS 的 Source 功能可以重用 `.tape` 的程式碼
    - 常見的資料夾建立、環境初始化設定等，可透過共用 `.tape` 減少重複程式碼並提升可維護性（maintainability）。
    - 我的 PR [commitizen-tools/commitizen#1906](https://github.com/commitizen-tools/commitizen/pull/1906) 就是在做這件事。
- 常見執行流程：
    - 建立執行環境：`/tmp/commitizen-example`。
    - 初始化 git 和 cz
    - 執行互動
    - 互動結束，清理環境
    - 產出圖檔
- 細節：
    - [gen_cli_interactive_gifs.py](https://github.com/commitizen-tools/commitizen/blob/master/scripts/gen_cli_interactive_gifs.py) 會讀取 `docs/images/*.tape` 並執行，產出 GIF 檔。

### CI 自動流程總覽

透過 GitHub Actions，在功能更新時，自動重新產生圖檔並發布於新版文件當中。

{{< mermaid >}}
flowchart TD
    ciTrigger["push(master) or workflow_dispatch"] --> ciWorkflow["docspublish.yml"]
    ciWorkflow --> screenshotJob["update-cli-screenshots"]
    screenshotJob --> uvTask["uv run --no-sync poe doc:screenshots"]
    uvTask --> helpScript["gen_cli_help_screenshots.py"]
    uvTask --> gifScript["gen_cli_interactive_gifs.py"]
    helpScript --> helpOut["docs/images/cli_help/*.svg"]
    gifScript --> tapeFiles["docs/images/*.tape"]
    tapeFiles --> vhsRun["vhs"]
    vhsRun --> gifOut["docs/images/cli_interactive/*.gif"]
    helpOut --> gitCheck["git status --porcelain"]
    gifOut --> gitCheck
    gitCheck --> publishJob["publish-documentation"]
    publishJob --> docBuild["uv run --no-sync poe doc:build"]
    docBuild --> ghPages["Deploy gh-pages"]
{{< /mermaid >}}

## 附註

由於 Commitizen 的圖片生成流程是在 GitHub Actions 上執行，環境相對乾淨且一致。

如果要在自己的電腦上執行，請務必確認執行內容是受信任的程式碼。

或是建議使用 Docker 建立隔離環境來執行。

## VHS 錄製 GIF 的限制與實務解法

我後來實測發現，`imgcat`、`chafa`、`viu` 這類「在終端顯示圖片」的方式，不一定能穩定出現在 VHS 最終輸出的 GIF 中。

實務上比較穩定的做法是採「兩段式展示」：

1. 第一段（VHS GIF）只錄製流程本身，例如：
   - 執行 `vhs demo.tape`
   - 用 `ls -lh demo.gif`、`file demo.gif` 驗證產物
2. 第二段再直接展示 `demo.gif` 成品（獨立嵌入或後製拼接）

這樣可以保留「流程可重現」與「成果可視化」兩個目標，同時避免被 terminal image protocol 的相容性卡住。

## 小結

VHS 在實務上非常好用，能把原本繁瑣的手工截圖與錄製流程轉成可重現、可維護的自動化流程。
