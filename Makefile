# Project task entrypoint. Run `make` or `make help` to list targets.
# Add "## description" at end of a target line to show it in help.

.PHONY: help dev build check ci check-double-ext check-bilingual check-pageref check-config theme-update post open-source

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

check-double-ext: ## Verify there are no *.md.md files
	./scripts/check_no_double_md.sh

check-bilingual: ## Verify zh/en content files are paired
	./scripts/check_bilingual_pairs.sh

check-pageref: ## Verify menu pageRef targets exist in both languages
	./scripts/check_pageref_targets.sh

check-config: ## Verify core Hugo config values
	./scripts/check_hugo_config.sh

ci: ## CI checks (strict superset of check)
	@set -e; \
	print_divider() { printf '%s\n' '------------------------------------------------------------'; }; \
	run_step() { \
		idx="$$1"; title="$$2"; target="$$3"; \
		print_divider; \
		printf '[CI %s/5] %s\n' "$$idx" "$$title"; \
		print_divider; \
		$(MAKE) --no-print-directory "$$target"; \
		printf '[CI %s/5] DONE: %s\n\n' "$$idx" "$$title"; \
	}; \
	printf '\n%s\n' '==================== CI PIPELINE START ===================='; \
	run_step 1 'Hugo build and key artifacts' check; \
	run_step 2 'File extension sanity (*.md.md)' check-double-ext; \
	run_step 3 'Bilingual pairing' check-bilingual; \
	run_step 4 'Menu pageRef targets' check-pageref; \
	run_step 5 'Hugo config assertions' check-config; \
	printf '%s\n' '==================== CI PIPELINE PASS ====================='

theme-update: ## Update Blowfish theme submodule (--remote --merge)
	git submodule update --remote --merge

post: ## Create en/zh posts under posts/YYYY/MM and assets/img/<slug>/ (usage: make post <slug>)
	@slug=$(filter-out $@,$(MAKECMDGOALS)); \
	if [ -z "$$slug" ]; then \
		echo "Usage: make post <slug>"; \
		exit 1; \
	fi; \
	ym=$${POST_DATE:-$$(date +%Y/%m)}; \
	en="content/en/posts/$$ym/$$slug.md"; \
	zh="content/zh/posts/$$ym/$$slug.md"; \
	if [ -f "$$en" ] || [ -f "$$zh" ]; then \
		echo "Refusing to overwrite existing: $$en or $$zh"; \
		exit 1; \
	fi; \
	mkdir -p "content/en/posts/$$ym" "content/zh/posts/$$ym" "assets/img/$$slug"; \
	hugo new --kind posts "$$en"; \
	hugo new --kind posts "$$zh"; \
	echo "Created $$en , $$zh and assets/img/$$slug/"

open-source: ## Create en/zh open-source pages under open-source/YYYY/MM and assets/img/<slug> (usage: make open-source <slug>)
	@slug=$(filter-out $@,$(MAKECMDGOALS)); \
	if [ -z "$$slug" ]; then \
		echo "Usage: make open-source <slug>"; \
		exit 1; \
	fi; \
	ym=$${POST_DATE:-$$(date +%Y/%m)}; \
	en="content/en/open-source/$$ym/$$slug.md"; \
	zh="content/zh/open-source/$$ym/$$slug.md"; \
	if [ -f "$$en" ] || [ -f "$$zh" ]; then \
		echo "Refusing to overwrite existing: $$en or $$zh"; \
		exit 1; \
	fi; \
	mkdir -p "content/en/open-source/$$ym" "content/zh/open-source/$$ym" "assets/img/$$slug"; \
	hugo new --kind open-source "$$en"; \
	hugo new --kind open-source "$$zh"; \
	echo "Created $$en , $$zh and assets/img/$$slug/"

%::
	@:
