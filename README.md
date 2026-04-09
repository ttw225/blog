# Personal Blog (Hugo + Blowfish)

This repo builds a bilingual personal blog with Hugo (extended) using the Blowfish theme.

<!-- stats:auto:start -->
## Statistics

[![latest-release](https://img.shields.io/github/v/release/ttw225/blog?display_name=tag)](https://github.com/ttw225/blog/releases/latest)
[![pages-build-deployment](https://github.com/ttw225/blog/actions/workflows/pages/pages-build-deployment/badge.svg?branch=gh-pages)](https://github.com/ttw225/blog/actions/workflows/pages/pages-build-deployment)

![post-pairs](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2Fttw225%2Fblog%2Fmain%2Fdocs%2Fstats-endpoint-pairs.json&query=%24.message&label=post-pairs&color=blue)
![total-content-chars](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2Fttw225%2Fblog%2Fmain%2Fdocs%2Fstats-endpoint-chars.json&query=%24.message&label=total-content-chars&color=6f42c1)

Last updated: `2026-04-09`
Counting rule: content chars are non-whitespace characters after front matter removal.

| Metric | EN | ZH | Total |
| --- | ---: | ---: | ---: |
| Posts | 3 | 3 | 6 |
| Content chars (no whitespace) | 6283 | 4759 | 11042 |
| Paired posts | - | - | 3 |

Trend (all snapshots):

```mermaid
xychart-beta
  title "Post Pairs and Total Content Chars (All snapshots)"
  x-axis ["03-27", "04-07", "04-08", "04-09"]
  y-axis "Count" 0 --> 11142
  bar [0, 2, 2, 3]
  line [0, 8506, 8506, 11042]
```
<!-- stats:auto:end -->

## Quick start

Prerequisites:
- `hugo` (extended)
- `git` (for theme submodule)

1. Init/update the theme submodule:
   - `git submodule update --init --recursive`
2. Run locally:
   - `make dev`
3. Build the static site:
   - `make build`
4. Run pre-launch checks:
   - `make ci`

## Folder structure (content)

- English posts: `content/en/posts/YYYY/MM/<slug>.md`
- Traditional Chinese posts: `content/zh/posts/YYYY/MM/<slug>.md`
- Post URL pattern is `/posts/<slug>/` (`YYYY/MM` folders are organizational only).
- Open-source posts can be generated with `make open-source <slug>` (prefills `categories: ["open-source"]`; add tags as needed).
- Open-source hub pages live at `content/{en,zh}/categories/open-source/_index.md` with canonical URLs `/open-source/` and `/en/open-source/`; Chinese aliases redirect old `/tags/open-source/` and `/categories/open-source/`.
- Shared images live in `assets/img/<slug>/` (auto-created by `make post <slug>`).
- Create new articles as bilingual pairs with `make post <slug>`.

If you add new posts or pages, keep the English and Chinese counterparts in sync (the repo includes scripts to verify pairing). Set an explicit `slug` in front matter when titles differ between languages so both locales share the same URL slug.

## Useful commands

- `make help` - list Makefile targets
- `make dev` - Hugo dev server
- `make build` - build to `public/`
- `make ci` - verify site artifacts + content checks
- `make post <slug>` - create paired posts under `posts/YYYY/MM/`, `assets/img/<slug>/`, and prefilled `featureimage` (optional: `POST_DATE=2026/05` to override the month folder)
- `make open-source <slug>` - create paired posts with open-source category prefilled (optional: `POST_DATE=2026/05`)
- Inline images by filename: `{{< postimg "screenshot.png" >}}` resolves to `assets/img/<slug>/screenshot.png` (see `layouts/shortcodes/postimg.html`)
- `make theme-update` - update the Blowfish submodule

## License

This project uses a split-license approach:

- Code, configuration, and automation files: `MIT` (see `LICENSE`)
- Blog content (posts and other content under `content/`, plus site assets under `assets/`): `CC BY 4.0` (see `LICENSE-CONTENT`)

Important for reuse:
- If you reuse blog content (text excerpts, images, screenshots), you must provide attribution and link back to the original post.
- Example attribution line (adapt as needed):
  - `Source: Peter Wang, "<post title>", <post URL>`

Third-party note:
- The Blowfish theme is licensed separately under `themes/blowfish/LICENSE`.

