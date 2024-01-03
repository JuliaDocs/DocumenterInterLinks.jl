# DocumenterInterLinks.jl


```@eval
using Markdown
using Pkg

VERSION = Pkg.dependencies()[Base.UUID("d12716ef-a0f6-4df4-a9f1-a5a34e75c656")].version

github_badge = "[![Github](https://img.shields.io/badge/JuliaDocs-DocumenterInterLinks.jl-blue.svg?logo=github)](https://github.com/JuliaDocs/DocumenterInterLinks.jl)"

version_badge = "![v$VERSION](https://img.shields.io/badge/version-v$(replace("$VERSION", "-" => "--"))-green.svg)"

if get(ENV, "DOCUMENTER_BUILD_PDF", "") == ""
    Markdown.parse("$github_badge $version_badge")
else
    Markdown.parse("""
    -----

    On Github: [JuliaDocs/DocumenterInterLinks.jl](https://github.com/JuliaDocs/DocumenterInterLinks.jl)

    Version: $VERSION

    -----

    """)
end
```

[DocumenterInterLinks.jl](https://github.com/JuliaDocs/DocumenterInterLinks.jl#readme) is a plugin for [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl) to link to external projects. It is interoperable with [Intersphinx](https://www.sphinx-doc.org/en/master/usage/extensions/intersphinx.html).


## Installation Instructions


As usual, the package can be installed via

```
] add DocumenterInterLinks
```

in the Julia REPL, or by adding

```
DocumenterInterLinks = "d12716ef-a0f6-4df4-a9f1-a5a34e75c656"
```

to the relevant `Project.toml` file.


## Telling Documenter.jl about External Projects

In [`docs/make.jl`](https://github.com/JuliaDocs/DocumenterInterLinks.jl/blob/master/docs/make.jl) instantiate an [`InterLinks`](@ref) object to define external projects you want to link to. For example,

```@example usage
using DocumenterInterLinks

links = InterLinks(
    "sphinx" => "https://www.sphinx-doc.org/en/master/objects.inv",
    "matplotlib" => "https://matplotlib.org/3.7.3/",
    "Documenter" => (
        "https://documenter.juliadocs.org/stable/",
        joinpath(@__DIR__, "inventories", "Documenter.toml")
    ),
    "Julia" => (
        "https://docs.julialang.org/en/v1/",
        joinpath(@__DIR__, "inventories", "Julia.toml")
    ),
);
nothing # hide
```

defines the external projects "[sphinx](https://www.sphinx-doc.org/)", "[matplotlib](https://matplotlib.org)", and "[Julia](https://docs.julialang.org/en/v1/)", . For each project, it specifies the root URL of that project's online documentation and the location of an [inventory file](@ref Inventory-Files).

The above examples illustrates three possibilities for specifying the root url and inventory location

* Map the project name to the URL of an inventory file. The project root URL is the given URL with the filename stripped
* Map that project name to project root URL. This will look for an inventory file `objects.inv` directly underneath the given URL.
* Map the project name to a tuple containing the root URL first, and then one ore more possible locations for an inventory file. These may be local file paths, which allows using an self-maintained inventory file for a project that does not provide one.

See the documentation of [`InterLinks`](@ref) for details.

The instantiated `links` object must be passed to [`Documenter.makedocs`](@extref) as an element to the `plugins` keyword argument.

## Inventory Files

Inventory files contain a mapping of names to linkable locations relative to the root URL of a project's online documentation. The [Sphinx documentation generator](@extref sphinx :doc:`index`) automatically creates an `objects.inv` inventory file.

Inventory files are handled by the [`DocInventories`](@extref DocInventories :doc:`index`) package.


## How to Use External References in Your Documentation.

The `DocumenterInterLinks` plugin adds support for `@extref` link targets to `Documenter`. At the most fundamental level, they work just like Documenter's standard `@ref` link targets. Replacing `@ref` with `@extref` switches from a *local* reference to an *external* one:

```
* [`Documenter.makedocs`](@extref)
* [Documenter's `makedocs` function](@extref Documenter.makedocs)
* See the section about Documenter's [Writers](@extref).
```

The above markdown code renders as follows:

> * [`Documenter.makedocs`](@extref)
> * [Documenter's `makedocs` function](@extref Documenter.makedocs)
> * See the section about Documenter's [Writers](@extref).


To disambiguate (and speed up) the references, the name of the inventory (as defined when instantiating `InterLinks`) can be included in the `@extref`. The previous example would have been better written as

```
* See the section about Documenter's [Writers](@extref Documenter).
```

to clarify that we are linking to the section name "Writers" in Documenter's documentation. When the link text and link target differ, the inventory name should be given between `@extref` and the target name, e.g., ```[`Regex`](@extref Julia Base.Regex)```, which turns into "[`Regex`](@extref Julia Base.Regex)".


Since `DocumenterInterLinks` is fully compatible with Sphinx inventories, it also provides an extended `@extref` syntax that builds on the Sphinx concept of ["domains"](https://www.sphinx-doc.org/en/master/glossary.html#term-domain) and ["roles"](https://www.sphinx-doc.org/en/master/glossary.html#term-role).
