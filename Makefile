.PHONY: help devrepl test docs clean codestyle distclean
.DEFAULT_GOAL := help

JULIA ?= julia
PORT ?= 8000

define PRINT_HELP_JLSCRIPT
rx = r"^([a-z0-9A-Z_-]+):.*?##[ ]+(.*)$$"
for line in eachline()
    m = match(rx, line)
    if !isnothing(m)
        target, help = m.captures
        println("$$(rpad(target, 20)) $$help")
    end
end
endef
export PRINT_HELP_JLSCRIPT


help:  ## show this help
	@julia -e "$$PRINT_HELP_JLSCRIPT" < $(MAKEFILE_LIST)


devrepl:  ## Start an interactive REPL for testing and building documentation
	$(JULIA) --project=test --banner=no --startup-file=yes -i devrepl.jl

test:  ## Run the test suite
	$(JULIA) --project=test --code-coverage=.coverage/tracefile-%p.info --banner=no --startup-file=yes -e 'include("devrepl.jl"); include("test/runtests.jl")'
	$(JULIA) --project=test -e 'include("devrepl.jl"); display(show_coverage())'

docs: test/Manifest.toml ## Build the documentation
	$(JULIA) --project=test docs/make.jl
	@echo "Done. Consider using 'make devrepl'"

test/Manifest.toml:
	$(JULIA) --project=test --banner=no --startup-file=yes -e 'include("devrepl.jl")'

clean: ## Clean up build/doc/testing artifacts
	$(JULIA) -e 'include("test/clean.jl"); clean()'

codestyle: test/Manifest.toml ## Apply the codestyle to the entire project
	$(JULIA) --project=test -e 'using JuliaFormatter; format(["src", "docs", "test", "devrepl.jl"], verbose=true)'
	@echo "Done. Consider using 'make devrepl'"

distclean: clean ## Restore to a clean checkout state
	$(JULIA) -e 'include("test/clean.jl"); clean(distclean=true)'
