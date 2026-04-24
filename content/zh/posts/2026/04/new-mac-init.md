---
title: "新 Mac 初始化清單：我會先安裝的工具"
slug: "new-mac-init"
date: 2026-04-23T18:03:06+08:00
description: "整理我在新 MacBook Pro 的初始化清單，涵蓋 CLI、AI Agent、開發與生產力工具，並標示清楚的安裝路徑。"
tags: ["macOS", "setup", "cli", "productivity", "developer-tools"]
categories: ["macOS", "Setup Guide"]
featureimage: "img/new-mac-init/cover.jpeg"
---

這篇整理我在新 MacBook Pro 上會先安裝的工具與原因。

## CLI 工具

### Brew

套件管理工具

- [Brew](https://brew.sh)

安裝方式：安裝指令

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### iTerm2 + zsh + Oh My Zsh

終端機工具組合，提供更完整的 shell 使用體驗。

可以參考[這篇文](https://spreered.medium.com/客製我的-cli-終於稍微搞懂-iterm-zsh-d3feed27f664)的介紹，我覺得蠻清楚易懂的

- [iTerm2](https://iterm2.com): terminal
- [zsh](https://www.zsh.org): shell
- [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh): plugins

安裝方式：App 下載 + 指令

- iTerm2：官網下載安裝
- zsh、Oh My Zsh：使用指令安裝

zsh 安裝

```sh
brew install zsh
```

Oh My Zsh 安裝

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

### Xcode Command Line Tools

macOS 上提供給終端機使用的開發工具包，包含編譯(`clang`)、建置(`make`)與版本(`git`)控制等常用命令列工具。

- [Xcode command-line tools](https://developer.apple.com/documentation/xcode/installing-the-command-line-tools/)

安裝方式：系統指令

```sh
xcode-select --install
```

### gh

GitHub 的官方 CLI 工具。

- [gh](https://cli.github.com)

安裝方式：Homebrew

```sh
# Install
brew install gh

# GitHub Login
gh auth login
```

## AI 工具

### Claude

- [Claude](https://claude.ai/downloads)

用途：AI Agent，桌面 App 與 CLI 可搭配使用。

安裝方式：App 下載 + Homebrew

- App：官網下載 Claude Desktop
- CLI：安裝 Claude Code

```sh
brew install --cask claude-code
```

### Codex

- [Codex](https://openai.com/zh-Hant/codex/get-started/)

用途：OpenAI Agent，可用 App 或 CLI。

安裝方式：App 下載 + Homebrew

- App：官網下載
- CLI：安裝 Codex CLI

```sh
brew install codex
```

### Cursor

- [Cursor](https://cursor.com/zh-Hant/download)

用途：AI-first 編輯器，桌面 App 與 CLI 可搭配使用。

安裝方式：App 下載 + 安裝指令

- App：官網下載 Cursor Desktop
- CLI：使用官方安裝指令

```sh
curl https://cursor.com/install -fsS | bash
```

### Gemini CLI

- [Gemini](https://geminicli.com/docs/get-started/installation/)

用途：Google 的 AI Agent。

安裝方式：Homebrew

```sh
brew install gemini-cli
```

## Mac 好用工具

### Raycast

Raycast 是一款以鍵盤操作為主的工具，能快速開啟 App、執行指令和整合常用服務。
Apple Spotlight 的完美替代品

- [Raycast](https://www.raycast.com)

安裝方式：App 下載

可以在官網安裝，這邊是我常用的功能與套件：

- [Clipboard History](https://raycastapp.notion.site/Core-6e452e76ad7f4d8d96428e69c3e0d791)
- [Window Management](https://raycastapp.notion.site/Window-Management-30b5f3e5210e43ebb63969cfc8cda717)
- [Google Translate](https://github.com/raycast/extensions/blob/0bb5fc231653829b1201e08fc23d6b8e61cf9f2a/extensions/google-translate/README.md)
- [Internet Speedtest](https://github.com/raycast/extensions/blob/d9f69635328288366e2e51784b99cc79575a699a/extensions/speedtest/README.md)

### AppCleaner

移除第三方 APP 唯一推薦，清很乾淨也跑很快

- [AppCleaner](https://freemacsoft.net/appcleaner/)

安裝方式：App 下載

### BetterDisplay

外接螢幕必裝，可以直接控制外接螢幕亮度、喇叭等設定

- [BetterDisplay](https://betterdisplay.com.tw)

安裝方式：Homebrew（cask）

```sh
brew install --cask betterdisplay
```

### KeyClu

按住快捷鍵可快速查看各 App 支援的鍵盤快捷鍵

- [KeyClu](https://sergii.tatarenkov.name/keyclu/support/)

安裝方式：App 下載

## 開發工具

### VSCode

輕量好用編輯器

- [Visual Studio Code](https://code.visualstudio.com)

安裝方式：App 下載

### Docker

容器化開發與部署工具，方便在本機重現一致的執行環境

- [Docker](https://www.docker.com/products/docker-desktop/)

安裝方式：App 下載

### GPG

用來加密、解密與簽署檔案或 Git commit 的金鑰工具。

安裝方式：CLI / GUI，擇一或並用
- [GnuPG](https://gnupg.org): CLI
- [GPG Suite](https://gpgtools.org): GUI
- 只需要終端機與 Git 簽章：選 CLI 即可
- 需要圖形化管理金鑰：可加裝 GUI

CLI 安裝（選用）：

```sh
brew install gnupg
```


## 選單列工具

### EzyCal

在選單列快速檢視行事曆並建立事件

- [EzyCal](https://appyogi.com/webapps/index.php?product_id=48)

安裝方式：App 下載


### Hidden Bar

自動整理選單列圖示，讓 Mac menu bar 更乾淨

- [Hidden Bar](https://github.com/dwarvesf/hidden)

安裝方式：Homebrew（cask）

```sh
brew install --cask hiddenbar
```

### Stats

在選單列即時顯示 CPU、記憶體、溫度與網路等系統資訊

- [Stats](https://github.com/exelban/stats)

安裝方式：Homebrew（cask）

```sh
brew install --cask stats
```

## 筆記軟體

### Obsidian

以本地 Markdown 為核心的知識管理與筆記工具

- [Obsidian](https://obsidian.md)

安裝方式：App 下載

### Notion

整合筆記、文件與專案管理的全方位工作空間

- [Notion](https://www.notion.so)

安裝方式：App 下載
