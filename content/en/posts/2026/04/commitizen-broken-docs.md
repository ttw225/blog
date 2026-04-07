---
title: "Commitizen broken docs: fenced code and Pygments 2.20.0"
slug: "commitizen-broken-docs"
date: 2026-04-03T17:27:37+08:00
description: "Why the Commitizen docs site broke: Pygments 2.20.0 HtmlFormatter with filename=None, the MkDocs/pymdown highlight chain, upstream issue/PR, and pinning pygments<2.20 until a fixed release."
tags: ["commitizen", "mkdocs", "pygments", "pymdown", "github-pages"]
categories: ["open-source"]
featureimage: "img/commitizen-broken-docs/cover.jpeg"
---

{{< postimg "broken-docs.jpeg" >}}

## What happened

The [Commitizen documentation](https://commitizen-tools.github.io/commitizen/) (MkDocs + Material on GitHub Pages) shows **fenced code blocks that fail to render correctly**: `` ```bash `` appears as plain text inside a paragraph, and lines starting with `#` in code are even interpreted as **Markdown headings** (`<h1>`).

In the static HTML you can see the usual pattern: the fence opener ends up inside `<p>` instead of `<div class="highlight"><pre><code>…`, and `#` lines become ATX headings.

## Where the bug is

In **[Pygments](https://github.com/pygments/pygments) 2.20.0**, `HtmlFormatter` runs `html.escape(...)` on `filename`. If the caller passes **`filename=None`**, `html.escape(None)` raises:

`AttributeError: 'NoneType' object has no attribute 'replace'`

## How the pieces connect

The docs are built with **MkDocs + Material** using **fenced code blocks**. Typical configs enable **`pymdownx.highlight`** and **`pymdownx.superfences`**. When a fence has **no title**, `pymdownx.highlight` builds `HtmlFormatter` and passes **`None`** to Pygments as `filename=title`. When highlighting fails, **`pymdownx.superfences` cannot replace the fence with the expected HTML**, and the leftover fence and body are parsed again as Markdown—hence “fence as plain text” plus “`#` becomes a heading.”

{{< mermaid >}}
flowchart TD
  fence[fenced code, no fence title]
  ph[pymdownx.highlight]
  crash["Pygments 2.20.0: html.escape on None"]
  sf[pymdownx.superfences cannot replace fence]
  md[Markdown reparses body]
  bad["# lines become ATX headings"]

  fence --> ph
  ph --> crash
  crash --> sf
  sf --> md
  md --> bad
{{< /mermaid >}}

If the same Markdown builds fine locally with `mkdocs build` but the [gh-pages output](https://github.com/commitizen-tools/commitizen/tree/gh-pages) looks wrong, look at **build dependency versions** (for example a lockfile resolving to `pygments==2.20.0`) or the build environment—not just the browser.

## What to do

### Pygments

The regression is tracked and fixed upstream; the fix is slated for **2.20.1**.

- Issue (closed): [pygments/pygments#3076](https://github.com/pygments/pygments/issues/3076)
- Fix (merged): [pygments/pygments#3078](https://github.com/pygments/pygments/pull/3078) (handle `None` before HTML escaping)

### Projects depending on Pygments (before fixed release)

If your project (for example, a docs build pipeline) depends on Pygments, apply a temporary mitigation until you can upgrade to a fixed release: **pin Pygments below 2.20**, for example:

- `pygments==2.19.2`, or
- `pygments<2.20`

A similar mitigation appears in [jj-vcs/jj#9233](https://github.com/jj-vcs/jj/pull/9233). Once the upstream fixed release is available and you upgrade, loosen the pin and re-run `mkdocs build` to confirm fenced code renders correctly.

### Update

The Commitizen docs have now been fixed. See the merged PR: [commitizen-tools/commitizen#1924](https://github.com/commitizen-tools/commitizen/pull/1924).

### Appendix: minimal Pygments repro

With `pygments==2.20.0` installed, the snippet below should raise the `AttributeError` above; **2.19.2** usually does not:

```python
from pygments.formatters.html import HtmlFormatter

HtmlFormatter(filename=None)
```

## What I did

### Tracing it in the build output

1. Noticed broken code blocks on the published site
2. Local builds looked fine
3. Compared environments and saw different Pygments versions
4. Checked the [gh-pages tree](https://github.com/commitizen-tools/commitizen/tree/gh-pages); HTML was already wrong, so the failure was in the build
5. **Compared HTML across Pygments versions**
6. Reproduced the failure manually and confirmed **`filename=None`** was the trigger
7. Found the existing Pygments issue and merged fix

### Comment on the Commitizen issue

I left a comment on [Broken docs #1922](https://github.com/commitizen-tools/commitizen/issues/1922#issuecomment-4181595422) with the summary below.

```text
Root cause: pygments==2.20.0 regressed HtmlFormatter so that when filename is None, it calls html.escape() on None and crashes with AttributeError: 'NoneType' object has no attribute 'replace'.

In our MkDocs stack, pymdownx.highlight ends up passing filename=None in the common case (no fence title), so the highlight step fails; pymdownx.superfences then doesn’t replace the fence, and the remaining text is parsed as normal Markdown — which is why fenced bash blocks and lines starting with # show up as plain text / headings.

Upstream:
- Issue: https://github.com/pygments/pygments/issues/3076
- Fix (merged): https://github.com/pygments/pygments/pull/3078 (targeted for Pygments 2.20.1)

Possible mitigation until a Pygments release with the fix is available: pin pygments<2.20 for the docs build (similar approach: https://github.com/jj-vcs/jj/pull/9233).
```
