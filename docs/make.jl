using DocumenterInterLinks
using Documenter
using Pkg

PROJECT_TOML = Pkg.TOML.parsefile(joinpath(@__DIR__, "..", "Project.toml"))
VERSION = PROJECT_TOML["version"]
NAME = PROJECT_TOML["name"]
AUTHORS = join(PROJECT_TOML["authors"], ", ") * " and contributors"
GITHUB = "https://github.com/JuliaDocs/DocumenterInterLinks.jl"

links = InterLinks(
    "Julia" => (
        "https://docs.julialang.org/en/v1/",
        joinpath(@__DIR__, "src", "inventories", "Julia.toml")
    ),
    "Documenter" => (
        "https://documenter.juliadocs.org/stable/",
        joinpath(@__DIR__, "src", "inventories", "Documenter.toml")
    ),
    "DocInventories" => "https://juliadocs.org/DocInventories.jl/stable/",
    "sphinx" => "https://www.sphinx-doc.org/en/master/",
    "sphobjinv" => "https://sphobjinv.readthedocs.io/en/stable/",
    "matplotlib" => "https://matplotlib.org/3.7.3/",
)

println("Starting makedocs")

PAGES = [
    "Home" => "index.md",
    "Syntax" => "syntax.md",
    "Inventory Generation" => "write_inventory.md",
    "Compatibility with Sphinx" => "sphinx.md",
    "How-Tos" => "howtos.md",
    "Internals" => joinpath("api", "internals.md"),
]

makedocs(
    authors=AUTHORS,
    #version=VERSION,  # https://github.com/JuliaDocs/Documenter.jl/issues/2385
    linkcheck=(get(ENV, "DOCUMENTER_CHECK_LINKS", "1") != "0"),
    # Link checking is disabled in REPL, see `devrepl.jl`.
    warnonly=true,
    #warnonly=[:linkcheck,],
    sitename="DocumenterInterLinks.jl",
    format=Documenter.HTML(
        prettyurls=true,
        canonical="https://juliadocs.org/DocumenterInterLinks.jl",
        footer="[$NAME.jl]($GITHUB) v$VERSION docs powered by [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl).",
    ),
    pages=PAGES,
    plugins=[links]
)

println("Finished makedocs")

deploydocs(; repo="github.com/JuliaDocs/DocumenterInterLinks.jl.git", push_preview=true)
