---
title: "find_spec 取代 eager import：Wren CLI 啟動加速 6–11x"
slug: "wren-cli-startup-find-spec"
date: 2026-06-10T21:30:00+08:00
description: "Wren AI CLI 的一個慢指令其實對應兩個不同問題：常態 ~3s 來自啟動時為偵測一個可選 extra 而 eager import 整套 ML 依賴；首次 ~50s 則是 macOS XProtect 的一次性掃描。修正方式是把偵測改用 importlib.util.find_spec。"
tags: ["wren", "wrenai", "python", "cli", "performance", "importtime", "macos", "open-source"]
categories: ["open-source"]
---

> [!NOTE]
> **兩個修正都已合併進 Wren AI**  
> 效能修正：[Canner/WrenAI#2352](https://github.com/Canner/WrenAI/pull/2352) — `perf(cli): use find_spec instead of eager import to detect memory extra`  
> 首次掃描文件：[Canner/WrenAI#2354](https://github.com/Canner/WrenAI/pull/2354) — `docs(wren): document macOS memory first-run scan`

安裝 [Wren AI](https://github.com/Canner/WrenAI)（`wrenai[memory,main]`）後，第一次執行 `wren --version` 或 `wren --help` 約需一分鐘，之後每次仍需約三秒，而這些指令僅是輸出版本或說明文字。

這個症狀其實對應**兩個不同的問題**，分開來看是釐清此議題的關鍵。

| 症狀 | 真正原因 | 性質 |
| :-- | :-- | :-- |
| 首次 ~50s | macOS XProtect 掃描新解壓縮的原生 ML binary | 一次性，每次全新安裝各觸發一次 |
| 每次 ~3s | CLI 啟動時 eager import 整套 ML 依賴 | 常態，屬程式設計問題 |

## 是 `uv` 還是 `wren`？

首先排除 `uv`。warm 狀態下實測（排除冷啟動）：

| 執行方式 | 耗時 |
| :-- | --: |
| `uv run wren --version` | 3.03s |
| `.venv/bin/wren --version`（繞過 uv） | 3.05s |
| `python -c "import wren"`（只 import 套件本身） | 0.15s |

繞過 `uv` 直接執行的時間幾乎相同，代表 uv 的 overhead 接近 0，成本位於 `wren` 本身。

## 常態的 ~3s：一個 eager import

以 `python -X importtime` 追蹤 CLI 進入點 `wren.cli`：

```bash
python -X importtime -c "import wren.cli"
```

這三秒幾乎全部花在啟動時 eager import 一整套大型 ML 依賴（以下為節錄、依耗時排序）：

```
sentence_transformers   ~1.8s
lancedb                 ~0.45s
  └ transformers / sklearn / numpy / pyarrow / torch ...
```

`wren --version` 之所以會載入 `torch`，是因為 `wren/cli.py` 在**模組頂層以實際的 import** 作為偵測 memory extra 是否安裝的方法：

```python {title="wren/cli.py"}
try:
    import lancedb                       # noqa: F401
    import sentence_transformers         # noqa: F401

    from wren.memory.cli import memory_app
    app.add_typer(memory_app)
except ImportError:
    # memory extra 未安裝：單純不註冊這組子命令
    pass
```

此設計的目的合理：僅在安裝 `memory` extra 時才註冊 `wren memory` 子命令。問題在於這段偵測程式在**每次** CLI 啟動時都會執行，包含 `--version`、`context`、`dry-run` 等與 memory 無關的指令；而 `import lancedb` 會連帶載入整條 embedding backend 鏈（`sentence_transformers → transformers → torch`）。因此即使只是要查版本，也得先載入整套 ML stack，只為了判斷一個可選功能是否安裝。

## 首次的 ~50s：macOS XProtect 的一次性掃描

從乾淨資料夾重現此現象（`uv init` → `uv add 'wrenai[main,memory]'` → 立即執行）：

```
time uv run wren --version
wrenai 0.9.0
uv run wren --version  7.80s user 1.64s system 15% cpu 59.731 total
```

wall-clock 為 60 秒，但 CPU 僅 **15%**，且全程沒有網路活動（`~/.cache/huggingface`、`~/.cache/torch` 皆不存在），代表時間花在等待外部處理，而非自身運算。在這 60 秒內每 0.3s 取樣一次系統程序：

```
XprotectService    命中數十次，60–83% CPU   ← macOS 首次執行的安全掃描
```

立即執行第二次（檔案未變，僅是已被掃描過）即可驗證因果：

| | 第 1 次（全新） | 第 2 次（同批檔案） |
| :-- | --: | --: |
| 耗時 | 59.7s | 3.8s |
| XProtect 取樣命中 | 數十次（60–83% CPU） | 0 |
| CPU | 15%（在等待） | 85%（在 import） |

`memory` extra 會解壓縮出 **314 個原生函式庫，合計約 836MB**，其中 `libtorch_cpu.dylib` 即達 240MB。這些是體積龐大的未簽章 binary，帶有 `com.apple.provenance` 屬性，正是觸發 macOS 首次執行安全掃描的條件。XProtect 以單執行緒序列掃描（因此 CPU 偏低），掃描結果由系統快取，之後不再發生。這是作業系統的一次性成本，與 uv 或 wren 的程式邏輯無關。此現象已整理為文件 [#2354](https://github.com/Canner/WrenAI/pull/2354)，以利後續使用者快速辨識。

## 修正：以 `find_spec` 取代實際 import

偵測只需要知道套件**在磁碟上是否存在**，不需要執行它。`importlib.util.find_spec` 會定位套件但**不執行其 `__init__`**：

```python {title="wren/cli.py"}
import importlib.util

if importlib.util.find_spec("lancedb") and importlib.util.find_spec(
    "sentence_transformers"
):
    # find_spec 不會 import lancedb/sentence_transformers，因此 torch 不會被拉進來。
    # wren.memory.cli 對大型套件的 import 本來就是 lazy（放在各指令函式內），
    # 因此在這裡註冊子命令幾乎沒有額外開銷。
    from wren.memory.cli import memory_app

    app.add_typer(memory_app)
```

此修正安全的理由（附實測）：

1. **`find_spec` 不會載入這些大型套件。** 偵測兩個套件共 ~0.07ms，事後 `sys.modules` 裡 `torch`、`sentence_transformers` 都不存在。
2. **`wren/memory/cli.py` 頂層本來就乾淨。** 只 import `json/os/typer/yaml`，大型依賴已 lazy import 在各指令函式內。故 `from wren.memory.cli import memory_app` 只需 ~0.16s，且不觸發 torch。
3. **行為不變。** 安裝 extra 時子命令照常註冊；未安裝則不註冊。真正耗時的 import 延後到實際執行 `wren memory <cmd>` 時才發生。

同一台機器、全新 venv 量測：

| 指令 | Before | After | 改善 |
| :-- | --: | --: | --: |
| `uv run wren --version` | 2.559s | 0.414s | ~6.2x |
| `uv run wren --help` | 4.006s | 0.358s | ~11.2x |

非 memory 指令不再將 `torch` 載入 `sys.modules`，因此全新安裝在這些路徑上也不再觸發那 50 秒的 XProtect 首次掃描。除了一行主要修正，PR 另附上 `tests/test_cli_memory_detection.py`，用以確保「`torch`／`lancedb` 不進入 `sys.modules`」與「子命令仍條件式註冊」。

## 小結

1. **偵測可選依賴應使用 `find_spec`，而非 `try: import`。** 以實際 import 作為功能探測，等於每次啟動都付出完整載入成本，並可能將一個 240MB 的張量函式庫載入到 `--version` 這類指令中。
2. **區分作業系統的一次性成本與程式的常態成本。** 那 50 秒來自 macOS、屬一次性；可修正且會重複發生的是常態的 3 秒。
3. 本次定位問題主要依靠 `python -X importtime` 與一個每 0.3s 的程序取樣器。

細節見 PR：[#2352](https://github.com/Canner/WrenAI/pull/2352)（修正）與 [#2354](https://github.com/Canner/WrenAI/pull/2354)（macOS 首次掃描的調查）。
