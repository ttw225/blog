# Project task entrypoint. Run `make` or `make help` to list targets.
# Add "## description" at end of a target line to show it in help.

.PHONY: help dev build check theme-update post

# First target is default
help: ## Show this help (default)
	@echo "Usage: make [target]"
	@echo ""
	@awk -F'## ' '/^[a-zA-Z0-9_-]+:.*## / {split($$1, a, ":"); printf "  %-15s %s\n", a[1], $$2}' $(MAKEFILE_LIST)

dev: ## Start Hugo dev server for local preview
	hugo server

build: ## Build site to public/ (--gc --minify)
	hugo --gc --minify

check: ## Pre-launch: build with path warnings + verify key artifacts
	hugo --gc --minify --printPathWarnings
	test -f public/index.html
	test -f public/en/index.html
	test -f public/robots.txt
	test -f public/sitemap.xml
	test -f public/index.xml
	test -f public/en/index.xml
	@echo "OK."

theme-update: ## Update Blowfish theme submodule (--remote --merge)
	git submodule update --remote --merge

post: ## Create new blog post in en/ and zh/ via hugo new
	@name=$(filter-out $@,$(MAKECMDGOALS)); \
	if [ -z "$$name" ]; then \
		echo "Usage: make post <slug>"; \
		exit 1; \
	fi; \
	hugo new content/en/posts/$$name.md; \
	if [ ! -f content/en/posts/$$name.md ]; then \
		echo "Expected file content/en/posts/$$name.md not found; adjust Makefile if your contentDir is different."; \
		exit 1; \
	fi; \
	hugo new content/zh/posts/$$name.md; \
	if [ ! -f content/zh/posts/$$name.md ]; then \
		echo "Expected file content/zh/posts/$$name.md not found; adjust Makefile if your contentDir is different."; \
		exit 1; \
	fi

%::
	@:
