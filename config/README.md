# Hugo configuration

This site follows the standard Hugo config layout:

- `config/_default/` — settings merged for every environment.
- `hugo.toml` — site-wide options (theme, baseURL, taxonomies, outputs).
- `languages.*.toml` — per-language `contentDir`, `title`, and `[params]`.
- `menus.*.toml` — menu entries for that language (`[[main]]`, `[[footer]]`).
- `params.toml` — Blowfish theme `[params]` shared across languages unless overridden in `languages.*.toml`.
- `markup.toml` — Goldmark / highlight / TOC.

Optional layers (not present yet): `config/development/`, `config/production/` for overrides.

Content lives in `content/en/` and `content/zh/`; language-specific mounts may also come from the theme module.

Before deploying, run `make check` and follow [docs/PRELAUNCH.md](../docs/PRELAUNCH.md).
