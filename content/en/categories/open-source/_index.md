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

## CPython

{{< github repo="python/cpython" showThumbnail=false >}}

CPython is the reference implementation of [Python](https://www.python.org), carried forward by a large, active community of contributors. I started contributing after [PyCon Taiwan](https://pycon.tw) and the sprint events run by [Eddie Kao](https://pythonbook.cc/about) (高見龍). See also the [introduction chapter](https://pythonbook.cc/chapters/basic/introduction) of *為你自己學 Python*.

### Open PR

Work in progress:

- [gh-139819: rlcompleter – avoid suggesting attributes not accessible on instances](https://github.com/python/cpython/pull/139820)
  - Tighten `rlcompleter` so tab completion skips attributes that are not accessible on instances
  - Status: still waiting for review—quiet thread

### Merged PR

Merged into CPython:

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
- [Refactor: Doc(images) VHS tapes with shared snippets](https://github.com/commitizen-tools/commitizen/pull/1906)
  - Refactor VHS tape scripts used for documentation images
  - Extract shared snippets to remove duplication and make the docs easier to follow
- [Feat: add live subject preview for interactive commit (--preview)](https://github.com/commitizen-tools/commitizen/pull/1902)
  - Add a live preview for the commit subject in interactive mode
- [Fix and improve test: message_length_limit](https://github.com/commitizen-tools/commitizen/pull/1900)
  - Fix and extend tests around the `message_length_limit` setting

### Merged PR

Merged into Commitizen:

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

- PyCon TW 2025: Program team, Communications team
- PyCon TW 2026: Program team, Communications team

---

## Articles

Think of this section as an open-source diary—short notes on contributions large and small.
