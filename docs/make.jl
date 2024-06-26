using DocumenterInterLinks
using Documenter
using DocInventories
using Pkg

PROJECT_TOML = Pkg.TOML.parsefile(joinpath(@__DIR__, "..", "Project.toml"))
VERSION = PROJECT_TOML["version"]
NAME = PROJECT_TOML["name"]
AUTHORS = join(PROJECT_TOML["authors"], ", ") * " and contributors"
GITHUB = "https://github.com/JuliaDocs/DocumenterInterLinks.jl"

links = InterLinks(
    "Julia" => "https://docs.julialang.org/en/v1/",
    "Documenter" => "https://documenter.juliadocs.org/stable/",
    "DocInventories" => "https://juliadocs.org/DocInventories.jl/stable/",
    "sphinx" => "https://www.sphinx-doc.org/en/master/",
    "sphobjinv" => "https://sphobjinv.readthedocs.io/en/stable/",
    "matplotlib" => "https://matplotlib.org/3.7.3/",
)


fallbacks = ExternalFallbacks(
    "makedocs" => "@extref Documenter.makedocs",
    "Other-Output-Formats" => "@extref Documenter `Other-Output-Formats`",
    "Inventory-File-Formats" => "@extref DocInventories `Inventory-File-Formats`",
)


println("Starting makedocs")

PAGES = [
    "Home" => "index.md",
    "Syntax" => "syntax.md",
    "Fallback Resolution" => "fallback.md",
    "Inventory Generation" => "write_inventory.md",
    "Compatibility with Sphinx" => "sphinx.md",
    "How-Tos" => "howtos.md",
    "Internals" => joinpath("api", "internals.md"),
]

HTML_OPTIONS = Dict(
    :prettyurls => true,
    :canonical => "https://juliadocs.org/DocumenterInterLinks.jl",
    :footer => "[$NAME.jl]($GITHUB) v$VERSION docs powered by [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl).",
)
if Documenter.DOCUMENTER_VERSION >= v"1.3.0"
    HTML_OPTIONS[:inventory_version] = VERSION
end


makedocs(
    authors=AUTHORS,
    linkcheck=(get(ENV, "DOCUMENTER_CHECK_LINKS", "1") != "0"),
    # Link checking is disabled in REPL, see `devrepl.jl`.
    #warnonly=true,
    warnonly=[:linkcheck,],
    sitename="DocumenterInterLinks.jl",
    format=Documenter.HTML(; HTML_OPTIONS...),
    pages=PAGES,
    plugins=[links, fallbacks],
)

println("Finished makedocs")

deploydocs(; repo="github.com/JuliaDocs/DocumenterInterLinks.jl.git", push_preview=true)
