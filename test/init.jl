using Revise
using Logging
using Coverage: Coverage, merge_coverage_counts
using LocalCoverage: LocalCoverage, eval_coverage_metrics
using JuliaFormatter

include("clean.jl")


"""Collect coverage information from all `.cov` and `.info` files recursively
found in `root`. Return a Vector of `FileCoverage` objects filtered to files in
`paths` (relative to `root`).
"""
function collect_coverage(paths::Vector{String}=["src",]; root=pwd())
    root = abspath(root)
    local coverage
    logger = Logging.SimpleLogger(stderr, Logging.Error)
    Logging.with_logger(logger) do
        coverage = merge_coverage_counts(
            Coverage.process_folder(root),  # .cov files in root
            Coverage.LCOV.readfolder(root),  # tracefile.info
        )
    end
    coverage = filter(coverage) do covitem
        any(startswith(abspath(covitem.filename), joinpath(root, path)) for path in paths)
    end
    return coverage
end


"""Print out a coverage summary from existing coverage data.

```julia
show_coverage(paths=["./src",]; root=pwd(), sort_by=nothing)
```

prints a a table showing the tracked files in `paths`, the total number of
tracked lines in that file ("Total"), the number of lines with coverage
("Hit"), the number of lines without coverage ("Missed") and the "Coverage" as
a percentage.

The coverage data is collected from `.cov` files in `paths` as well as
`tracefile-*.info` files in `root`.

Optionally, the table can be sorted by passing the name of a column to
`sort_by`, e..g. `sort_py=:Missed`.
"""
function show_coverage(paths=["src",]; root=pwd(), kwargs...)
    coverage = collect_coverage(paths; root=root)
    metrics = eval_coverage_metrics(coverage, root)
    return metrics
end


"""Generate an HTML report for existing coverage data.

```julia
generate_coverage_html(
    paths=["src", ]; root=pwd(), covdir="coverage", genhtml="genhtml"
)
```

creates a folder `covdir` in `root` and use the external `genhtml` program to
write an HTML coverage report into that folder.
"""
function generate_coverage_html(paths=["src", "ext"]; root=pwd(), kwargs...)
    coverage = collect_coverage(paths; root=root)
    generate_coverage_html(root, coverage; kwargs...)
end


function generate_coverage_html(
    root::String,
    coverage::Vector{LocalCoverage.CoverageTools.FileCoverage};
    covdir="coverage",
    genhtml="genhtml"
)
    root = abspath(normpath(root))
    covdir = normpath(root, covdir)
    mkpath(covdir)
    tracefile = joinpath(covdir, "lcov.info")
    Coverage.LCOV.writefile(tracefile, coverage)
    branch = try
        strip(read(`git rev-parse --abbrev-ref HEAD`, String))
    catch e
        @warn "git branch could not be detected.\nError message: $(sprint(Base.showerror, e))"
    end
    title = isnothing(branch) ? "N/A" : "on branch $(branch)"
    try
        run(`$(genhtml) -t $(title) -o $(covdir) $(tracefile)`)
    catch e
        @error(
            "Failed to run $(genhtml). Check that lcov is installed.\nError message: $(sprint(Base.showerror, e))"
        )
    end
    @info(
        "Generated coverage HTML. Serve with 'LiveServer.serve(dir=\"$(relpath(covdir, pwd()))\")'"
    )
end



REPL_MESSAGE = """
*******************************************************************************
DEVELOPMENT REPL

Revise, JuliaFormatter, LiveServer are loaded.

* `help()` – Show this message
* `format(".")` – Apply code formatting to all files
* `clean()` – Clean up build/doc/testing artifacts
* `distclean()` – Restore to a clean checkout state
* `show_coverage()` – Print a tabular overview of coverage data
* `generate_coverage_html()` – Generate an HTML coverage report
*******************************************************************************
"""

"""Show help"""
help() = println(REPL_MESSAGE)
