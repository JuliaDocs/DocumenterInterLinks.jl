.PHONY: help devrepl test coverage htmlcoverage docs clean distclean codestyle
.DEFAULT_GOAL := help

JULIA ?= julia

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

define DEVREPL_INIT_JLSCRIPT
using Revise
println("""
**Development REPL for DocumenterInterLinks.jl** (Revise active)

* `include("test/runtests.jl")` – Run the entire test suite
* `include("docs/make.jl")` – Build the documentation
""")
endef
export DEVREPL_INIT_JLSCRIPT


help:  ## show this help
	@julia -e "$$PRINT_HELP_JLSCRIPT" < $(MAKEFILE_LIST)


devrepl: test/Manifest.toml  ## Start an interactive REPL for testing and building documentation
	$(JULIA) --project=test -e "$$DEVREPL_INIT_JLSCRIPT" -i

test: ## Run the test suite
	$(JULIA) --project=. -e 'import Pkg; Pkg.test(;coverage=false, julia_args=["--check-bounds=yes", "--compiled-modules=yes", "--depwarn=yes"], force_latest_compatible_version=false, allow_reresolve=true)'

coverage: test/Manifest.toml ## Run the test suite with coverage
	$(JULIA) --project=test -e 'using LocalCoverage; report = generate_coverage("DocumenterInterLinks"; run_test = true); show(report)'

htmlcoverage: test/Manifest.toml ## Run the test suite with coverage and generate an HTML report in ./coverage
	$(JULIA) --project=test -e 'using LocalCoverage; html_coverage("DocumenterInterLinks"; dir = "coverage")'

docs: docs/Manifest.toml  ## Build the documentation
	$(JULIA) --project=docs docs/make.jl

clean:  ## Clean up build/doc/testing artifacts
	make -C docs/src/sphinx-to-documenter-links clean
	rm -f -- *.jl.*.cov src/*.jl.*.cov
	rm -f -- *.jl.cov src/*.jl.cov
	rm -f -- *.jl.mem src/*.jl.mem
	rm -f -- *.info
	rm -rf -- .coverage coverage docs/build


codestyle: test/Manifest.toml  ## Apply the codestyle to the entire project
	$(JULIA) --project=test -e 'using JuliaFormatter; format(["src", "docs", "test"], verbose=true)'

distclean: clean  ## Restore to a clean checkout state
	rm -f Manifest.toml test/Manifest.toml docs/Manifest.toml


test/Manifest.toml: test/Project.toml
	$(JULIA) --project=test -e 'using Pkg; Pkg.instantiate()'


docs/Manifest.toml: docs/Project.toml
	$(JULIA) --project=docs -e 'using Pkg; Pkg.instantiate()'






