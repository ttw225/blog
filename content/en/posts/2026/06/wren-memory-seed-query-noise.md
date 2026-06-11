---
title: "Foreign Keys Aren't Metrics: Improving Wren Memory's Retrieval Quality"
slug: "wren-memory-seed-query-noise"
date: 2026-06-10T22:10:00+08:00
description: "Wren AI's memory index auto-generates seed NL→SQL pairs to bootstrap retrieval. On jaffle_shop it produced SELECT SUM(customer_id) for the identifier column customer_id. The root cause: aggregation seeds select the first numeric column and exclude only the primary key, not foreign keys, although the relationship information needed is already present in the manifest."
tags: ["wren", "wrenai", "python", "memory", "retrieval", "embeddings", "semantic-layer", "open-source"]
categories: ["open-source"]
---

> [!NOTE]
> **Fixed and merged**  
> PR: [Canner/WrenAI#2358](https://github.com/Canner/WrenAI/pull/2358) — `fix(memory): avoid identifier columns in aggregation seed queries`  
> The fix excludes foreign-key / id-like columns from the aggregation seed template.

[Wren AI](https://github.com/Canner/WrenAI) gives AI agents a semantic layer over business data, and one piece of that is **memory**: `wren memory index` reads the model and writes a set of seed NL→SQL pairs into a vector store, so that `wren memory recall` can later retrieve relevant examples by similarity. Seed quality directly affects retrieval: meaningful seeds bootstrap it, while semantically empty seeds are mixed in and degrade the results.

Hand-writing an MDL for `jaffle_shop` (DuckDB) and running `wren memory index` produces `Indexed 38 schema items, 17 seed queries`. Of those 17, about a third carry no analytical meaning; one is `SELECT SUM(customer_id) FROM orders`, which applies `SUM` to the identifier column `customer_id`.

## These seeds reach retrieval results

The aggregation seeds follow a single template: apply `SUM` to a numeric column.

| seed | SQL | meaningful? |
| :-- | :-- | :-: |
| `Total number_of_orders in customers` | `SUM(number_of_orders)` | ✅ |
| `Total customer_id in orders` | `SUM(customer_id)` | ❌ summing an ID |
| `Total user_id in raw_orders` | `SUM(user_id)` | ❌ |
| `Total order_id in raw_payments` | `SUM(order_id)` | ❌ |

For the query "How many customers placed more than one order?", `wren memory recall` returns `SUM(customer_id)` in the **top 3** (distance 0.56). Noise generated at index time is retrieved at query time.

## How seed generation works

Seed generation does not involve an LLM. `generate_seed_queries(manifest)` is a pure function that reads `mdl.json` and fills fixed templates with column names. There are three templates:

```python {title="wren/memory/seed_queries.py"}
# 1) list the table
{"nl": f"List all {name}", "sql": f"SELECT * FROM {name} LIMIT 100"}

# 2) aggregate  ← the problem
{"nl": f"Total {numeric_col} in {name}", "sql": f"SELECT SUM({numeric_col}) FROM {name}"}

# 3) relationship JOIN
{"nl": f"{left} with {right} details", "sql": f"SELECT * FROM {left} JOIN {right} ..."}
```

The generated pairs are then embedded and written to LanceDB with a `source:seed` tag; at `recall` time the user's question is embedded and matched by vector similarity search. The key distinction is that generation and storage/retrieval are two separate stages: the empty seeds are produced **before** any data reaches the vector store, so the cause lies with neither the embedding model nor LanceDB.

## Root cause: the column-selection condition

The aggregation template selects the **first** numeric column. The selection logic is in `_model_seeds()`:

```python {title="wren/memory/seed_queries.py"}
for col in columns:
    col_type = (col.get("type") or "").split("(")[0].lower().strip()
    is_calc = col.get("isCalculated", False)
    is_pk = col["name"] == model.get("primaryKey")   # ← only excludes the PK

    if (
        col_type in _NUMERIC_TYPES
        and not is_calc
        and not is_pk                                 # ← FK is not excluded
        and numeric_col is None
    ):
        numeric_col = col["name"]
```

In jaffle_shop, the `orders` model's columns, in order, are `order_id` (PK), `customer_id` (FK to `customers`), `order_date`, and `status`.

For `orders`: with the PK `order_id` excluded, the first numeric non-PK column is the foreign key `customer_id`, producing `SUM(customer_id)`. `_NUMERIC_TYPES` treats `int/bigint` and similar types uniformly, so the generator cannot distinguish an identifier-typed INT from a metric-typed INT. This is the source of the empty seeds: in a data model, "numeric type" does not imply "suitable for aggregation". `customer_id` and `order_id` are INTs, but they are identifiers, not measures.

## The required information already exists in the manifest

The information needed to identify foreign keys already exists in the manifest, in **two places**:

1. a `relationships` condition: `orders.customer_id = customers.customer_id`
2. the column's own `description`: *"Foreign key to customers"*

So MDL provides sufficient information. Originally, however, `generate_seed_queries()` called `_model_seeds(model)` with a single model and did not pass the relationships in, and the column-level check excluded only the PK. The fix therefore needs no new MDL field: it passes the existing relationship information into the selection logic and completes the definition of an identifier.

After the fix, a column is treated as an identifier (and excluded as an aggregation target) if it meets any of these conditions:

1. **It is a primary key** (both single and composite PKs are supported).
2. **It is a foreign key**: it appears in a relationship's `condition` (i.e. a join key; columns on both sides are excluded).
3. **Its name is `id` or ends with `_id`** (covering identifiers not declared as relationships).

```python
# is_pk: whether the column is a primary key
# relationship_keys: join-key columns parsed from each relationship's condition
# _is_id_like: name is "id" or ends with "_id" (both case-insensitive)
is_identifier = is_pk or norm_name in relationship_keys or _is_id_like(col_name)

if col_type in _NUMERIC_TYPES and not is_calc and not is_identifier and numeric_col is None:
    numeric_col = col_name
```

The relationship keys are obtained by parsing each `condition` (e.g. `orders.customer_id = customers.customer_id`), covering declared foreign keys; the `*_id` heuristic catches undeclared identifiers; all comparisons are case-insensitive, for compatibility with warehouses that fold column names to upper case. Legitimate metrics such as `number_of_orders` still produce `SUM` seeds; relationship-JOIN and `accepted_values` seeds are unaffected.

## Which stage is responsible

Because the pipeline ends in a vector database, the cause is easily attributed to the wrong stage. Each is examined below:

| Stage | Source? | Notes |
| :-- | :-: | :-- |
| LanceDB / vector store | No | Only stores vectors and runs similarity search. The empty seeds exist before this stage; the store persists and retrieves them as-is. |
| Embedding model | No | Only converts `SUM(customer_id)` into a vector; it is not responsible for, and cannot judge, whether the SQL is business-meaningful. |
| MDL / model quality | No | The FK is correctly declared in `relationships`; a stronger model does not help, since the generator does not read it. |
| Generator logic | Yes | `_model_seeds()` excludes the PK but not FKs, and does not receive the relationships needed for the decision. |

A stronger model does not resolve this, because the source is insufficient coverage in a pure-Python condition, not input quality. Two MDL-side adjustments can reduce the number of empty seeds: tagging raw-layer models with `dbt_layer: raw` so they generate no seeds, and using structured `accepted_values` instead of free-text descriptions; both affect only the quantity, not the root cause.

## Summary

1. **A numeric type does not imply suitability for aggregation.** In a data model, identifiers are numeric as well. Logic that decides aggregation from type alone needs an additional basis for identifying identifiers, such as relationships, column naming, or an explicit semantic tag.
2. **Before adding new inputs, check whether the required information already exists in the manifest.** In this case it did, and the fix used existing data rather than requiring more.
3. **Seed quality is reflected directly in retrieval results.** In a retrieval system, what is indexed at build time is what can be retrieved at query time, so seed quality is equivalent to recall quality.

Details in the PR: [Canner/WrenAI#2358](https://github.com/Canner/WrenAI/pull/2358).
