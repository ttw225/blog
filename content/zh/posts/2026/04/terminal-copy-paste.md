---
title: "更有效率的複製與貼上終端機輸出"
slug: "terminal-copy-paste"
date: 2026-04-09T16:42:24+08:00
description: "整理 macOS terminal 的實用複製貼上技巧，透過 pbcopy/pbpaste 與 shell function 快速複製指令輸出，方便貼給 AI 工具、GitHub issue 與 commit 流程。"
tags: ["macOS", "terminal", "clipboard", "pbcopy", "pbpaste", "shell", "zsh", "git"]
categories: []
featureimage: "img/terminal-copy-paste/cover.jpg"
---

## 常見情境

- 指令產出的大量資訊不好閱讀，卻又對解決 bug 至關重要
- 想把 terminal 中所有的資訊一股腦貼給 AI 工具
- terminal 過長的資訊不方便複製
- terminal 中超過一頁的資訊無法用滾動的方式全部複製
- GitHub 開 Issues 時被要求貼上指定指令的結果

## macOS 內建工具：`pbcopy` 與 `pbpaste`

macOS 內建 `pbcopy` 與 `pbpaste`，可以直接串接 shell pipeline。

例如，想複製電腦基本資訊：

```sh
uname -a
```

把輸出 pipe 給 `pbcopy`，內容就會直接進剪貼簿：

```sh
uname -a | pbcopy
```

如果想複製 staged diff，請 AI 協助撰寫 commit message：

```sh
git diff --cached --no-color | pbcopy
```

如果想檢查剪貼簿內容，可以用 `pbpaste`：

```sh
pbpaste | less
```

## 可以更方便一點嗎？

### 包成 shell function

先做一個專門複製 staged diff 的 function：

```sh
gdcopy() {
  git diff --cached --no-color | pbcopy
}
```

把這段 function 放到 shell 設定檔：
- zsh：`~/.zshrc`
- bash：`~/.bashrc`

之後只要輸入：

```sh
gdcopy
```

就能複製 staged diff。

### 同時複製「指令」與「輸出」

有時你希望貼出的內容包含：
- 你執行了哪個指令
- 指令實際輸出是什麼

可以用 command group 一次組好再丟進 `pbcopy`：

可以用一個區塊撰寫：

```sh
{
  echo "git diff --cached --no-color"
  git diff --cached --no-color
} | pbcopy
```

### 進階：做成可重用 helper

把上面的做法抽成 function：

```sh
copycmd() {
  local cmd="$*"
  {
    echo "$cmd"
    eval "$cmd"
  } | pbcopy
}
```

用法：

```sh
copycmd git diff --cached --no-color
```

> 注意：`eval` 會執行傳入字串，請只對你信任的指令使用這個 function。

## 想把 commit message 也寫得更穩定嗎？

答案是：規格化。

推薦工具：

{{< github repo="commitizen-tools/commitizen" showThumbnail=false >}}

我會再寫一篇文章專門介紹。
