---
title: "Commitizen Argparse None Get Trap"
slug: "commitizen-argparse-none-get-trap"
date: 2026-04-10T11:09:13+08:00
description: "修正 Commitizen `message_length_limit` 的優先順序陷阱：當 CLI 未傳值時，`argparse` 的 `None` 會讓 `dict.get()` 提前返回，導致設定檔被忽略。"
tags: ["commitizen", "argparse", "python", "cli", "testing", "open-source"]
categories: ["open-source"]
featureimage: "img/commitizen-argparse-none-get-trap/cover.jpeg"
---

{{< postimg "cover.jpeg" >}}

> [!NOTE]
> **已發 Issue 和 PR，尚待審閱**  
> Issue: [commitizen-tools/commitizen#1899](https://github.com/commitizen-tools/commitizen/issues/1899)  
> PR: [commitizen-tools/commitizen#1900](https://github.com/commitizen-tools/commitizen/pull/1900)  
> 核心修正是重寫 `message_length_limit` 的賦值邏輯，明確處理 `None`。

在 `pyproject.toml` 設定 `message_length_limit`，理論上應該在 `cz commit` / `cz check` 生效；但實際上設定值被忽略。

以下先用 `commit` 說明，`check` 有相同問題。

## get 的誤用

原始碼關鍵片段如下：

```python {title="commitizen/commands/commit.py"}
self.max_msg_length = arguments.get(
    "message_length_limit", config.settings.get("message_length_limit", 0)
```

表面上看起來是「CLI > config > 0」，但實際上不是。

### 陷阱一：`add_argument` 預設 `None`，且一定存在

`argparse` 在沒有指定 `default` 時，該 argument 仍會存在於 namespace，只是值為 `None`。

換句話說，使用者就算沒帶 `-l`，`arguments["message_length_limit"]` 是 `None`，而不是「不存在」。

這會讓 `arguments.get("message_length_limit", ...)` 直接回傳 `None`，後面的 fallback 根本不會執行。

所以上述程式在這個情境下，等價於：

```python
self.max_msg_length = arguments.get("message_length_limit")
```

### 陷阱二：`config.settings["message_length_limit"]` 其實一定存在

`config.settings` 會先載入 `DEFAULT_SETTINGS`，再套用使用者設定。

在 `DEFAULT_SETTINGS` 裡，`message_length_limit` 預設是 `0`：

```python {title="commitizen/defaults.py"}
"message_length_limit": 0,  # 0 for no limit
```

因此對 `config.settings.get("message_length_limit", 0)` 而言，`0` 這個 fallback 幾乎沒有機會被用到。

## 回到原始碼

### 一開始 `commit` 的 argument 設定

```python {title="commitizen/cli.py"}
...
{
    "name": ["-l", "--message-length-limit"],
    "type": int,
    "help": "Set the length limit of the commit message; 0 for no limit.",
},
...
```

因為沒設 `default`，當使用者未傳入 `-l/--message-length-limit` 時，值就是 `None`。

### commit 檢查長度的函式

```python {title="commitizen/commands/commit.py"}
def _validate_subject_length(self, message: str) -> None:
    message_length_limit = self.arguments.get(
        "message_length_limit", self.config.settings.get("message_length_limit", 0)
    )
    # By the contract, message_length_limit is set to 0 for no limit
    if message_length_limit is None or message_length_limit <= 0:
        return
```

| CLI 是否傳值 | Config 是否有值 | 實際取值結果 | 是否符合預期 |
| :-----: | :-----: | :-----: | :-----: |
| Yes | No | 用 CLI 值 | ✅ |
| No | No | 取到 `None`，被視為無限制 | ✅（結果碰巧合理） |
| No | Yes | 仍取到 `None`，忽略 config | ❌ |
| Yes | Yes | 用 CLI 值 | ✅ |

問題會被隱藏，是因為後續又寫了：

```python
if message_length_limit is None or message_length_limit <= 0:
    return
```

這讓「取值邏輯錯了」時，很多情況看起來仍可運作。

### 如何修正

把 `get()` 與 fallback 拆開，先判斷 CLI 值是否為 `None`：

```python
message_length_limit: int | None = arguments.get("message_length_limit")
self.message_length_limit: int = (
    message_length_limit
    if message_length_limit is not None
    else config.settings["message_length_limit"]
)
```

重點：
1. 先取 `arguments["message_length_limit"]`，再判斷是否為 `None`
2. 一定要用 `is not None`，否則會把合法的 `0` 誤判為 False
3. CLI 沒給值時才回退到 `config.settings["message_length_limit"]`
4. 這樣才能真正滿足 `CLI > config > default(0)` 的意圖

## 為何 test cover 卻沒能驗證錯誤

### test 的寫法

`commit` 測試常見寫法如下：

```python {title="tests/commands/test_commit_command.py"}
commands.Commit(config, {"message_length_limit": message_length})()
```

第一個參數 `config` 沒問題；盲點主要在第二個參數（模擬 CLI arguments）：
- 測試常直接給「有值」的 dict
- 卻少了「使用者未傳入 CLI 參數時，值其實是 `None`」這個關鍵狀態

簡單說，缺少了對 `{"message_length_limit": None}` 的真實模擬。

### 修正

補上 `None` 情境後，才能穩定抓到「config 值被忽略」的 bug。

## 結語

這類問題常見但隱蔽：`argparse` 的「參數存在但值為 `None`」語義，會和 `dict.get()` 的 fallback 機制互相干擾。再加上 `0` 與 `None` 在判斷式中的行為不同，就很容易留下邏輯漏洞。

更多細節可見 PR：[commitizen-tools/commitizen#1900](https://github.com/commitizen-tools/commitizen/pull/1900)
