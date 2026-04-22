---
title: "A Better Way to Copy and Paste Terminal Output"
slug: "terminal-copy-paste"
date: 2026-04-09T16:42:23+08:00
description: "A practical guide to copying terminal output on macOS with pbcopy/pbpaste and shell functions, so you can quickly share logs with AI tools, GitHub issues, and commit workflows."
tags: ["macOS", "terminal", "clipboard", "pbcopy", "pbpaste", "shell", "zsh", "git"]
categories: []
featureimage: "img/terminal-copy-paste/cover.jpeg"
---

{{< postimg "cover.jpeg" >}}

## Common pain points

- Command output is long and hard to read, but critical for debugging.
- You want to paste full terminal context into AI tools.
- Long terminal output is annoying to select manually.
- Output longer than one screen is difficult to copy completely by scrolling.
- GitHub issues often ask for full command output.

## Built-in macOS tools: `pbcopy` and `pbpaste`

macOS ships with `pbcopy` and `pbpaste`, which work nicely with shell pipelines.

For example, if I want to copy basic system information:

```sh
uname -a
```

Pipe it to `pbcopy` and it goes straight to the clipboard:

```sh
uname -a | pbcopy
```

If I want to copy the staged git diff for AI-generated commit messages:

```sh
git diff --cached | pbcopy
```

To inspect what is currently in the clipboard:

```sh
pbpaste | less
```

## Can this be even easier?

### Turn it into a shell function

Create a function specifically for copying staged diffs:

```sh
gdcopy() {
  git diff --cached | pbcopy
}
```

Put it in your shell config file:
- zsh: `~/.zshrc`
- bash: `~/.bashrc`

Then just run:

```sh
gdcopy
```

### Copy both the command and its output

Sometimes you want to include both:
- the command you ran
- the output it produced

You can use a command group:

```sh
{
  echo "git diff --cached"
  git diff --cached
} | pbcopy
```

### Advanced helper function

You can generalize this into a reusable helper:

```sh
copycmd() {
  local cmd="$*"
  {
    echo "$cmd"
    eval "$cmd"
  } | pbcopy
}
```

Usage:

```sh
copycmd git diff --cached --no-color
```

> Note: `eval` executes the input string. Only use this with commands you trust.

## Want better commit messages too?

Then standardize the format.

Recommended tool:

{{< github repo="commitizen-tools/commitizen" showThumbnail=false >}}

I will write a separate post about it soon.
