---
title: "VHS CLI Demo as Code"
slug: "vhs-cli-demo-as-code"
date: 2026-04-17T14:04:02+08:00
description: "Use VHS `.tape` files to generate reproducible CLI screenshots and GIF demos for docs with less manual effort."
tags: ["vhs", "cli", "documentation", "automation", "gif"]
categories: ["open-source"]
featureimage: "img/vhs-cli-demo-as-code/cover.jpeg"
---

{{< postimg "cover.gif" >}}

{{< github repo="charmbracelet/vhs" showThumbnail=false >}}

## Pain points

- You want visual demos for CLI features (screenshots or GIFs).
- Recording interactive command flows manually is time-consuming.
- It is hard to keep outputs consistent across runs (terminal size, theme, environment).
- You need stable pacing for command playback and output display.
- When code changes, many screenshots and GIFs often need to be regenerated.

## VHS automates CLI screenshots and animated demos

I first discovered VHS while contributing to the [commitizen](https://github.com/commitizen-tools/commitizen) [documentation](https://commitizen-tools.github.io/commitizen/). What stood out to me most:

VHS can generate terminal screenshots and animations automatically in a controlled, reproducible way. That makes it a great fit for technical docs.

## Quick example

### Install VHS

Install it with your package manager:

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

For more installation options, see the [official documentation](https://github.com/charmbracelet/vhs?tab=readme-ov-file#installation).

### Hello World

1. Create a `demo.tape` file

VHS uses `.tape` files to describe terminal actions:

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

2. Run VHS

```sh
vhs demo.tape
```

3. Get the GIF output

{{< postimg "demo.gif" >}}

The opening animation in this post is the same workflow, captured as a GIF.

## How commitizen uses VHS in practice

### Screenshots

- Every command's `--help` output is captured and included in the docs.
- Implementation detail:
  [gen_cli_help_screenshots.py](https://github.com/commitizen-tools/commitizen/blob/master/scripts/gen_cli_help_screenshots.py) reads subcommands from `commitizen.cli.data`, runs `cz <command> --help` (plus `cz --help`), and outputs SVG files.

For example: `cz init --help`

{{< postimg "cz_init___help.svg" >}}

### GIF demos

Selected features also get GIF demos to show interactive flows.

- `.tape` authoring
    - Write separate `.tape` files for different features and interactions under `docs/images/*.tape`.
- Reusable `.tape` snippets with VHS Source
    - Shared setup actions (directory creation, environment initialization, etc.) can be extracted to reduce duplication and improve maintainability.
    - My PR [commitizen-tools/commitizen#1906](https://github.com/commitizen-tools/commitizen/pull/1906) focuses on this optimization.
- Typical execution flow:
    - Prepare runtime directory: `/tmp/commitizen-example`
    - Initialize git and cz
    - Run interactive flow
    - Clean up environment
    - Generate output files
- Implementation detail:
    - [gen_cli_interactive_gifs.py](https://github.com/commitizen-tools/commitizen/blob/master/scripts/gen_cli_interactive_gifs.py) discovers and executes `docs/images/*.tape` files, then exports GIFs.

### CI automation overview

With GitHub Actions, updated features can trigger automatic image regeneration and publication with the docs release.

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

## Notes

Commitizen runs image generation in GitHub Actions, where the environment is clean and consistent.

If you run similar scripts locally, make sure the code is trusted.

Or use Docker to isolate the execution environment.

## Wrap-up

VHS is very practical in real projects. It turns repetitive manual screenshot and recording work into a reproducible, maintainable automation workflow.
