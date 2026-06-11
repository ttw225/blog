---
title: "Foreign key 不是 metric：改善 Wren memory 檢索品質"
slug: "wren-memory-seed-query-noise"
date: 2026-06-10T22:10:00+08:00
description: "Wren AI 的 memory index 會自動生成 seed NL→SQL pair 來 bootstrap 檢索；在 jaffle_shop 上，它對識別碼欄位 customer_id 生成了 SELECT SUM(customer_id)。原因在於聚合查詢的 seed 在挑選欄位時只排除 primary key、未排除 foreign key，而判斷所需的 relationship 資訊其實已存在於 manifest。"
tags: ["wren", "wrenai", "python", "memory", "retrieval", "embeddings", "semantic-layer", "open-source"]
categories: ["open-source"]
---

> [!NOTE]
> **已修並合併**  
> PR：[Canner/WrenAI#2358](https://github.com/Canner/WrenAI/pull/2358) — `fix(memory): avoid identifier columns in aggregation seed queries`  
> 修正內容是把 foreign key / id 型欄位排除在聚合 seed 模板之外。

[Wren AI](https://github.com/Canner/WrenAI) 為 AI agent 提供一層架在商業資料之上的語意層，其中一塊是 **memory**：`wren memory index` 讀取 model，將一批 seed NL→SQL pair 寫入向量庫，之後 `wren memory recall` 便能以相似度檢索相關範例。seed 的品質直接影響檢索結果：語意有效的 seed 能 bootstrap 檢索，語意無效的 seed 則會混入並降低檢索品質。

在 `jaffle_shop`（DuckDB）上手寫 MDL 並執行 `wren memory index`，輸出為 `Indexed 38 schema items, 17 seed queries`。檢視這 17 條，約三分之一在語意上不具分析意義，其中之一為 `SELECT SUM(customer_id) FROM orders`，即對識別碼欄位 `customer_id` 套用 `SUM`。

## 無意義 seed 會被檢索出來

聚合查詢的 seed 集中於單一模板，即「對數值欄位套用 `SUM`」：

| seed | SQL | 是否具意義 |
| :-- | :-- | :-: |
| `Total number_of_orders in customers` | `SUM(number_of_orders)` | ✅ |
| `Total customer_id in orders` | `SUM(customer_id)` | ❌ 對 ID 加總 |
| `Total user_id in raw_orders` | `SUM(user_id)` | ❌ |
| `Total order_id in raw_payments` | `SUM(order_id)` | ❌ |

以「How many customers placed more than one order?」查詢時，`wren memory recall` 將 `SUM(customer_id)` 列入 **top 3**（distance 0.56）。在 index 階段生成的無意義 seed，會在 query 階段被實際檢索出來。

## seed 的生成流程

seed 的生成過程不涉及 LLM。`generate_seed_queries(manifest)` 是純函式，讀取 `mdl.json`，將欄位名稱填入固定模板。共三個模板：

```python {title="wren/memory/seed_queries.py"}
# 1) 列出全表
{"nl": f"List all {name}", "sql": f"SELECT * FROM {name} LIMIT 100"}

# 2) 聚合  ← 問題所在
{"nl": f"Total {numeric_col} in {name}", "sql": f"SELECT SUM({numeric_col}) FROM {name}"}

# 3) relationship JOIN
{"nl": f"{left} with {right} details", "sql": f"SELECT * FROM {left} JOIN {right} ..."}
```

生成的 pair 接著被計算 embedding、寫入 LanceDB（tag 標 `source:seed`）；`recall` 時將使用者問題同樣計算 embedding 後做向量相似度搜尋。關鍵在於「生成」與「儲存／檢索」屬於兩個不同階段：無意義 seed 在資料寫入向量庫**之前**即已生成，因此與 embedding 模型或 LanceDB 無關。

## 原因：聚合欄位的挑選條件

聚合模板會選取**第一個**數值欄位，判斷邏輯位於 `_model_seeds()`：

```python {title="wren/memory/seed_queries.py"}
for col in columns:
    col_type = (col.get("type") or "").split("(")[0].lower().strip()
    is_calc = col.get("isCalculated", False)
    is_pk = col["name"] == model.get("primaryKey")   # ← 只排除 PK

    if (
        col_type in _NUMERIC_TYPES
        and not is_calc
        and not is_pk                                 # ← FK 未被排除
        and numeric_col is None
    ):
        numeric_col = col["name"]
```

jaffle_shop 的 `orders` model 主要欄位依序為 `order_id`（PK）、`customer_id`（FK，指向 `customers`）、`order_date`、`status`。

以 `orders` 為例：PK `order_id` 被排除後，第一個數值且非 PK 的欄位為 foreign key `customer_id`，因此生成 `SUM(customer_id)`。`_NUMERIC_TYPES` 對 `int/bigint` 等型別一視同仁，生成器無法區分「識別碼型 INT」與「度量型 INT」。這是無意義 seed 的來源：在資料模型中，「型別為數值」並不等同於「適合加總」，`customer_id`、`order_id` 雖為 INT，但屬於識別碼而非度量。

## 判斷所需的資訊已存在於 manifest

判斷 foreign key 所需的資訊已存在於 manifest，且有**兩處**：

1. `relationships` 的 condition：`orders.customer_id = customers.customer_id`
2. 欄位本身的 `description`：*"Foreign key to customers"*

也就是說，MDL 已提供足夠的資訊。但原本 `generate_seed_queries()` 呼叫 `_model_seeds(model)` 時僅傳入單一 model、未傳入 relationships，欄位層級的檢查也只排除 PK。因此修正不需新增任何 MDL 欄位，只需把既有的 relationship 資訊傳入挑選邏輯，並把「識別碼」的判斷條件補齊。

修正後，一個欄位只要符合以下任一條件，就會被視為識別碼，不會被選為要聚合的欄位：

1. **是 primary key**（同時支援單一與複合 PK）
2. **是 foreign key**：出現在任何 relationship 的 `condition` 中（即 join key，條件兩側的欄位都排除）
3. **名稱為 `id` 或以 `_id` 結尾**（涵蓋未被宣告為 relationship 的識別碼）

```python
# is_pk：是否為 primary key
# relationship_keys：從各 relationship 的 condition 解析出的 join key 欄位集合
# _is_id_like：名稱為 id 或以 _id 結尾（皆不分大小寫）
is_identifier = is_pk or norm_name in relationship_keys or _is_id_like(col_name)

if col_type in _NUMERIC_TYPES and not is_calc and not is_identifier and numeric_col is None:
    numeric_col = col_name
```

其中 relationship 的 key 是直接解析 `condition`（例如 `orders.customer_id = customers.customer_id`）取得，涵蓋已宣告的 foreign key；`*_id` 命名啟發式則處理未宣告的識別碼；所有比對皆不分大小寫，以相容於會將欄位名轉為大寫的資料庫。`number_of_orders` 等正當度量仍會生成 `SUM` seed；relationship JOIN 與 `accepted_values` 類 seed 不受影響。

## 問題歸屬於哪個環節

由於整條 pipeline 以向量庫作結，問題容易被歸到錯誤的環節。逐一釐清如下：

| 環節 | 是否為來源 | 說明 |
| :-- | :-: | :-- |
| LanceDB / 向量庫 | 否 | 僅負責儲存向量與相似度搜尋。無意義 seed 在寫入**之前**已生成，向量庫如實儲存與檢索。 |
| embedding 模型 | 否 | 僅將 `SUM(customer_id)` 轉為向量，不負責、也無法判斷該 SQL 在商業上是否具意義。 |
| MDL / 模型品質 | 否 | FK 已正確宣告於 `relationships`；更換更強的模型亦無助益，因生成器並未讀取該資訊。 |
| 生成器邏輯 | 是 | `_model_seeds()` 排除 PK 但未排除 FK，且未取得可供判斷的 relationships。 |

更換更強的模型無法解決此問題，因為其來源是一段純 Python 條件判斷的覆蓋不足，而非輸入品質。另有兩項 MDL 端的調整可減少無意義 seed 的數量：將 raw 層 model 標註 `dbt_layer: raw` 使其不生成 seed，以及以結構化的 `accepted_values` 取代自由文字描述；但兩者僅影響數量，並非真正的原因。

## 小結

1. **「型別為數值」不等同於「適合加總」。** 在資料模型中，識別碼同樣是數值型別。僅依型別決定是否聚合的邏輯，需要額外的識別碼判斷依據，例如 relationship、欄位命名、或明確的語意標註。
2. **在新增輸入之前，先確認所需資訊是否已存在於 manifest。** 此案例中該資訊已存在，修正方式為運用既有資料，而非要求更多輸入。
3. **seed 的品質會直接反映在檢索結果。** 在檢索系統中，build 階段索引的內容即為 query 階段可被檢索的內容，因此 seed 品質等同於 recall 品質。

細節見 PR：[Canner/WrenAI#2358](https://github.com/Canner/WrenAI/pull/2358)。
