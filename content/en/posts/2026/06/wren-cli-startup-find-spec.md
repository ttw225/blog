---
title: "find_spec over Eager Import: 6–11x Faster Wren CLI Startup"
slug: "wren-cli-startup-find-spec"
date: 2026-06-10T21:30:00+08:00
description: "Two different problems lie behind one slow command in the Wren AI CLI: a recurring ~3s from eagerly importing the whole ML stack just to detect an optional extra, and a one-time ~50s macOS XProtect scan. The fix is a one-line switch to importlib.util.find_spec."
tags: ["wren", "wrenai", "python", "cli", "performance", "importtime", "macos", "open-source"]
categories: ["open-source"]
---

> [!NOTE]
> **Both fixes are merged into Wren AI**  
> Performance fix: [Canner/WrenAI#2352](https://github.com/Canner/WrenAI/pull/2352) — `perf(cli): use find_spec instead of eager import to detect memory extra`  
> First-run docs: [Canner/WrenAI#2354](https://github.com/Canner/WrenAI/pull/2354) — `docs(wren): document macOS memory first-run scan`

After installing [Wren AI](https://github.com/Canner/WrenAI) (`wrenai[memory,main]`), the first `wren --version` or `wren --help` takes almost a minute, and every run after that still takes around three seconds — for commands that only print version or help text.

This single symptom corresponds to **two different problems**, and separating them is the key to the analysis.

| Symptom | Real cause | Nature |
| :-- | :-- | :-- |
| First run ~50s | macOS XProtect scanning newly-unpacked native ML binaries | One-time, per fresh install |
| Every run ~3s | CLI eagerly imports the whole ML stack at startup | Recurring, a code issue |

## Is it `uv` or `wren`?

The first step is to rule out `uv`. Measured warm (excluding first-run cost):

| How it runs | Time |
| :-- | --: |
| `uv run wren --version` | 3.03s |
| `.venv/bin/wren --version` (bypassing uv) | 3.05s |
| `python -c "import wren"` (the package only) | 0.15s |

Bypassing `uv` gives essentially the same time, so `uv`'s overhead is ~0; the cost lies inside `wren`.

## The recurring ~3s: an eager import

Tracing the CLI entry point `wren.cli` with `python -X importtime`:

```bash
python -X importtime -c "import wren.cli"
```

Nearly all three seconds go into eagerly importing a heavy ML stack at startup (excerpt, sorted by time):

```
sentence_transformers   ~1.8s
lancedb                 ~0.45s
  └ transformers / sklearn / numpy / pyarrow / torch ...
```

`wren --version` loads `torch` because `wren/cli.py` used a **real import at module top level** to detect whether the optional `memory` extra is installed:

```python {title="wren/cli.py"}
try:
    import lancedb                       # noqa: F401
    import sentence_transformers         # noqa: F401

    from wren.memory.cli import memory_app
    app.add_typer(memory_app)
except ImportError:
    # memory extra not installed: just don't register the subcommands
    pass
```

The intent is sound: register the `wren memory` subcommands only when the extra is present. The problem is that this detection block runs on **every** CLI startup, including `--version`, `context`, and `dry-run`, none of which touch memory; and `import lancedb` transitively pulls in the entire embedding backend chain (`sentence_transformers → transformers → torch`). So even checking the version requires loading the whole ML stack, just to determine whether an optional feature is installed.

## The one-time ~50s: a one-time macOS XProtect scan

Reproducing from a clean folder (`uv init` → `uv add 'wrenai[main,memory]'` → run immediately):

```
time uv run wren --version
wrenai 0.9.0
uv run wren --version  7.80s user 1.64s system 15% cpu 59.731 total
```

Wall-clock is 60 seconds, but CPU is only **15%**, with no network activity (`~/.cache/huggingface` and `~/.cache/torch` are absent), indicating the time is spent waiting on an external process rather than computing. Sampling system processes every 0.3s during that window:

```
XprotectService    dozens of hits, 60–83% CPU   ← macOS first-run security scan
```

Running it a second time (same files, now already scanned) verifies the cause:

| | First run (fresh) | Second run (same files) |
| :-- | --: | --: |
| Time | 59.7s | 3.8s |
| XProtect samples | dozens (60–83% CPU) | 0 |
| CPU | 15% (waiting) | 85% (importing) |

The `memory` extra unpacks **314 native libraries totaling ~836MB**; `libtorch_cpu.dylib` alone is 240MB. These are large, unsigned binaries carrying the `com.apple.provenance` attribute, which is exactly what triggers macOS's first-execution security scan. XProtect scans them serially (hence the low CPU), the OS caches the result, and it does not recur. This is a one-time operating-system cost, unrelated to the logic of `uv` or `wren`. It is documented in [#2354](https://github.com/Canner/WrenAI/pull/2354) so the cause can be identified quickly.

## The fix: `find_spec` instead of a real import

The detection only needs to know whether a package *exists on disk*, not run it. `importlib.util.find_spec` locates a package without executing its `__init__`:

```python {title="wren/cli.py"}
import importlib.util

if importlib.util.find_spec("lancedb") and importlib.util.find_spec(
    "sentence_transformers"
):
    # find_spec does not import lancedb/sentence_transformers, so torch is
    # never pulled in. wren.memory.cli's own heavy imports are already lazy
    # (inside each command), so registering them adds almost no overhead.
    from wren.memory.cli import memory_app

    app.add_typer(memory_app)
```

Why this is safe (with measurements):

1. **`find_spec` does not load the heavy packages.** Probing both costs ~0.07ms, and afterwards `torch` / `sentence_transformers` are absent from `sys.modules`.
2. **`wren/memory/cli.py` is clean at the top.** It only imports `json/os/typer/yaml`; the heavy dependencies are already lazy-imported inside each command. So `from wren.memory.cli import memory_app` costs ~0.16s and does not touch torch.
3. **Behavior is unchanged.** With the extra installed, the subcommands register; without it, they do not. The heavy import is deferred to when `wren memory <cmd>` is actually run.

Measured on the same machine, fresh venv:

| Command | Before | After | Speedup |
| :-- | --: | --: | --: |
| `uv run wren --version` | 2.559s | 0.414s | ~6.2x |
| `uv run wren --help` | 4.006s | 0.358s | ~11.2x |

`torch` no longer enters `sys.modules` for non-memory commands, so a fresh install also stops triggering the 50s XProtect scan on those paths. Besides the one-line change, the PR adds `tests/test_cli_memory_detection.py`, which verifies that `torch`/`lancedb` stay out of `sys.modules` and that the subcommands still register conditionally.

## Summary

1. **To detect an optional dependency, use `find_spec` rather than `try: import`.** A real import used as a feature probe pays the full load cost on every startup, and can pull a 240MB tensor library into a command like `--version`.
2. **Separate one-time OS costs from recurring code costs.** The 50s came from macOS and is one-time; the fixable, recurring latency was the 3s.
3. The problem was located mainly with `python -X importtime` and a 0.3s process sampler.

Details in the PRs: [#2352](https://github.com/Canner/WrenAI/pull/2352) (the fix) and [#2354](https://github.com/Canner/WrenAI/pull/2354) (the macOS first-run write-up).
