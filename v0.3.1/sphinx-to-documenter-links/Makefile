.PHONY: help docs clean distclean

help:   ## Show this help
	@grep -E '^([a-zA-Z_-]+):.*## ' $(MAKEFILE_LIST) | awk -F ':.*## ' '{printf "%-20s %s\n", $$1, $$2}'

docs:  ## Build the documentation
	hatch run docs:build

clean: ## Clean up build/doc/testing artifacts
	rm -rf docs/build
	rm -rf docs/source/_extensions/__pycache__
	rm -rf .pytest_cache

distclean: clean  ## Restore to a clean checkout state
