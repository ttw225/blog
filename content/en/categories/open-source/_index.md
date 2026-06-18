---
title: "Open Source"
linkTitle: "Open Source"
description: "Open source projects and a record of contributions."
url: /en/open-source/
aliases:
  - /categories/open-source/
cascade:
  showReadingTime: false
  showWordCount: false
  showDate: true
cardView: true
groupByYear: false
---

This page collects my open-source contributions and the projects I care about most.

## Wren AI

{{< github repo="Canner/WrenAI" showThumbnail=false >}}

[Wren AI](https://github.com/Canner/WrenAI) is an open-source AI agent context layer. Through an MDL semantic model, it supplies the business semantics, examples, and memory that a database schema lacks, so AI can produce trustworthy SQL, charts, and analyses under access and query-rule constraints.

### Open PR

Work in progress:

- [chore(wren): separate SDK and local core install flows](https://github.com/Canner/WrenAI/pull/2375)
  - Separates the normal `core/wren` Python SDK / CLI development setup from the local Rust engine / PyO3 binding workflow. `just install` is now a plain `uv sync`, while `just install-local` / `just use-local-core` explicitly handle local `wren-core-py` wheel overlays, keeping lockfile sync and local wheel builds out of the same path.

### Merged PR

Merged into Wren AI:

- [chore(wren-core-py): migrate from Poetry to uv](https://github.com/Canner/WrenAI/pull/2363)
  - `core/wren-core-py` was the only Python module still on Poetry while `core/wren` and the SDKs use uv—the Rust binding build also ran maturin inside that Poetry env. The PR moves the dev/build flow to uv (maturin unchanged), aligns justfile and CI, and lets contributors build the Rust→binding→CLI chain without juggling two toolchains.
- [docs(wren): fix cube quickstart and align YAML/CLI examples with implementation](https://github.com/Canner/WrenAI/pull/2359)
  - Adds the missing Cube creation flow to the official [QuickStart](https://docs.getwren.ai/oss/get_started/quickstart) and corrects the examples so the YAML / CLI match the sample data's field design and the implementation
- [fix(memory): avoid identifier columns in aggregation seed queries](https://github.com/Canner/WrenAI/pull/2358)
  - `wren memory index` auto-generates seed NL→SQL pairs into a vector store for `recall` to retrieve by similarity. Seed generation treated foreign keys like `customer_id` as summable metrics, producing meaningless `SUM(customer_id)` seeds that degraded retrieval; the fix excludes foreign-key / `*_id` columns
  - Featured write-up:
{{< article link="/blog/en/posts/wren-memory-seed-query-noise/" showSummary=false compactSummary=false >}}
- [perf(cli): use find_spec instead of eager import to detect memory extra](https://github.com/Canner/WrenAI/pull/2352)
  - Switched how the CLI detects the optional extra — from eagerly importing the whole ML stack to `find_spec` — making `wren --version` / `--help` ~6–11x faster, with large packages like torch no longer entering `sys.modules`
  - Featured write-up:
{{< article link="/blog/en/posts/wren-cli-startup-find-spec/" showSummary=false compactSummary=false >}}
- [docs(wren): document macOS memory first-run scan](https://github.com/Canner/WrenAI/pull/2354)
  - Documented that the real source of the ~50s first run on macOS is XProtect's one-time scan of unsigned native binaries, rather than a defect in wren itself
- [fix(wren): load cubes from folder-per-entity layout](https://github.com/Canner/WrenAI/pull/2350)
  - Fixed the folder layout the cube loader scans: upgraded from v1 `cubes/<name>.yml` to v2 `cubes/<name>/metadata.yml`
- [ci(release): sync wrenai version in uv.lock](https://github.com/Canner/WrenAI/pull/2351)
  - Each release now automatically syncs the `wrenai` version in `uv.lock`

---

## CPython

{{< github repo="python/cpython" showThumbnail=false >}}

CPython is the reference implementation of [Python](https://www.python.org), carried forward by a large, active community of contributors. I started contributing after [PyCon Taiwan](https://pycon.tw) and the sprint events run by [Eddie Kao](https://pythonbook.cc/about) (高見龍). See also the [introduction chapter](https://pythonbook.cc/chapters/basic/introduction) of *為你自己學 Python*.

### Merged PR

Merged into CPython:

- [gh-139819: rlcompleter – avoid suggesting attributes not accessible on instances](https://github.com/python/cpython/pull/139820)
  - Tighten `rlcompleter` so tab completion skips attributes that are not accessible on instances
- [gh-139487: doc(enum): add missing imports for standalone doctest examples](https://github.com/python/cpython/pull/139488)
  - Add missing imports to standalone doctest examples in the enum docs
- [gh-139743: avoid import-time print in test_sqlite3 that leaks into help('modules')](https://github.com/python/cpython/pull/139746)
  - Fix `sqlite3` tests so import-time output does not pollute `help('modules')`

---

## Commitizen

{{< github repo="commitizen-tools/commitizen" showThumbnail=false >}}

[Commitizen](https://github.com/commitizen-tools/commitizen) is a Python toolkit for writing consistent Git commit messages, with room for automation, plugins, and packaging workflows. [Wei Lee](https://github.com/Lee-W)—who got me into the project—is Taiwan’s only [Apache Airflow](https://github.com/apache/airflow/) PMC member. His post on the path: [Becoming an Airflow PMC Member](https://blog.wei-lee.me/posts/tech/2025/10/becoming-an-airflow-pmc-member/).

### Open PR

Work in progress:

- [Feat: Validate message_length_limit is non-negative](https://github.com/commitizen-tools/commitizen/pull/1908)
  - Require `message_length_limit >= 0` explicitly
- [Feat: add live subject preview for interactive commit (--preview)](https://github.com/commitizen-tools/commitizen/pull/1902)
  - Add a live preview for the commit subject in interactive mode
- [Fix and improve test: message_length_limit](https://github.com/commitizen-tools/commitizen/pull/1900)
  - Fix and extend tests around the `message_length_limit` setting
  - Featured write-up:
{{< article link="/blog/en/posts/commitizen-argparse-none-get-trap/" showSummary=false compactSummary=false >}}

### Merged PR

Merged into Commitizen:

- [Refactor: Doc(images) VHS tapes with shared snippets](https://github.com/commitizen-tools/commitizen/pull/1906)
  - Refactor VHS tape scripts used for documentation images
  - Extract shared snippets to remove duplication and make the docs easier to follow
  - Related Post:
{{< article link="/blog/en/posts/vhs-cli-demo-as-code/" showSummary=false compactSummary=false >}}
- [docs: document and demo use_shortcuts keyboard shortcuts](https://github.com/commitizen-tools/commitizen/pull/1891)
  - Improve `use_shortcuts` documentation and examples
- [CI: make release workflows fork-friendly](https://github.com/commitizen-tools/commitizen/pull/1889)
  - Adjust GitHub Actions triggers so forks do not run release workflows unintentionally
- [Doc: Clarify cz_customize deprecation warning with rationale link](https://github.com/commitizen-tools/commitizen/pull/1887)
  - Clarify official docs around the `cz_customize` deprecation
- [Resolve tempfile path spaces issue in git commit function](https://github.com/commitizen-tools/commitizen/pull/1039)
  - My first Commitizen contribution: fix temp-file paths that contain spaces in the Git commit flow

---

## PyCon Taiwan

[PyCon Taiwan](https://pycon.tw) promotes Python and open source in Taiwan with a major conference each year. I joined as a volunteer in 2025.

- PyCon TW 2026: Deputy Program team lead, Review committee, Communications team
- PyCon TW 2025: Program team, Communications team

---

## Articles

Think of this section as an open-source diary—short notes on contributions large and small.
