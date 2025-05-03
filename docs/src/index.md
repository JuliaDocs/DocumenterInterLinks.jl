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

[DocumenterInterLinks.jl](https://github.com/JuliaDocs/DocumenterInterLinks.jl#readme) is a plugin for [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl) to link to external projects. It is interoperable with [Intersphinx](@extref sphinx :doc:`usage/extensions/intersphinx`) for Python projects.


## Installation


As usual, the package can be installed via

```
] add DocumenterInterLinks
```

in the Julia REPL, or by adding

```
DocumenterInterLinks = "d12716ef-a0f6-4df4-a9f1-a5a34e75c656"
```

to the relevant `Project.toml` file (e.g., `docs/Project.toml`).

## Usage

* In your `docs/make.jl` file, load the `DocumenterInterLinks` package (`using DocumenterInterLinks`).
* [Declare external projects](@ref Declaring-External-Projects) by instantiating an [`InterLinks`](@ref) object and passing it as part of `plugins` to [`Documenter.makedocs`](@extref).
* Reference items from any external project with an [`@extref` link](@ref Using-External-References) in your documentation.


## Declaring External Projects

In [`docs/make.jl`](https://github.com/JuliaDocs/DocumenterInterLinks.jl/blob/master/docs/make.jl), instantiate an [`InterLinks`](@ref) object to define external projects you want to link to. For example,

```@example usage
using DocumenterInterLinks

links = InterLinks(
    "sphinx" => "https://www.sphinx-doc.org/en/master/",
    "matplotlib" => "https://matplotlib.org/3.7.3/objects.inv",
    "Julia" => (
        "https://docs.julialang.org/en/v1/",
        joinpath(@__DIR__, "inventories", "Julia.toml")
    ),
    "Documenter" => (
        "https://documenter.juliadocs.org/stable/",
        "https://documenter.juliadocs.org/stable/objects.inv",
        joinpath(@__DIR__, "inventories", "Documenter.toml")
    ),
);
nothing # hide
```

defines the external projects "[sphinx](https://www.sphinx-doc.org/)", "[matplotlib](https://matplotlib.org)", "[Julia](https://docs.julialang.org/en/v1/)" and "[Documenter](https://documenter.juliadocs.org/stable/)". For each project, it specifies the root URL of that project's online documentation and the location of an [inventory file](@ref Inventories).

The above examples illustrates three possibilities for specifying the root URL and inventory location:

* Map that project name to project root URL. This will look for an inventory file `objects.inv` directly underneath the given URL. In the `"sphinx"` entry of the example, the inventory file would be loaded from `https://www.sphinx-doc.org/en/master/objects.inv`. This is the recommended form in most cases.
* Map the project name to the URL of an inventory file. The project root URL is the given URL without the filename. In the `"matplotlib"` entry of the example, the project root URL would be `https://matplotlib.org/3.7.3/`. This form would only be used if the name of the inventory file is not the standard `objects.inv`.
* Map the project name to a tuple containing the root URL first, and then one or more possible locations for an inventory file. These may be local file paths, which allows using [a self-maintained inventory file](https://github.com/JuliaDocs/DocumenterInterLinks.jl/tree/master/docs/src/inventories) for a project that does not provide one.
  * In the `"Julia"` entry of the example, the inventory would be loaded *only* from the local file `docs/src/inventories/Julia.toml`. As of Julia 1.11, the [online documentation](https://docs.julialang.org/en/v1/) provides an inventory file, so using a local inventory for Julia is no longer necessary.
  * In the `"Documenter"` entry of the example, the inventory would first be loaded from the standard online location. Only if this fails (e.g., because the network connection fails), a "backup inventory" is loaded from `docs/src/inventories/Documenter.toml`.

See the doc-string of [`InterLinks`](@ref) for details.

!!! warning
    The instantiated `links` object **must** be passed to [`Documenter.makedocs`](@extref) as an element to the `plugins` keyword argument.

## Inventories

The inventory files referenced when instantiating [`InterLinks`](@ref) are assumed to have been created by a documentation generator, see [Inventory Generation](@ref). The [`DocInventories` package](@extref DocInventories :doc:`index`) is used as a backend to parse these files into [`DocInventories.Inventory`](@extref) objects. These are accessible by using `links` as a dict:

```@example usage
links["sphinx"]
```

As we can see, inventories contain a mapping of names to linkable locations relative to the root URL of a project's online documentation, see [`DocInventories.InventoryItem`](@extref).

The [`DocInventories` package](@extref DocInventories :doc:`index`) provides tools for interactively searching inventories for items to reference. See [Exploring Inventories](@extref DocInventories) and [How do I figure out the correct name for the `@extref` link?](@ref howto-find-extref).


## Using External References

The `DocumenterInterLinks` plugin adds support for `@extref` link targets to `Documenter`. At the most fundamental level, they work just like [Documenter's standard `@ref` link targets](@extref Documenter `at-ref-at-id-links`). Replacing `@ref` with `@extref` switches from a *local* reference to an *external* one:

```
* [`Documenter.makedocs`](@extref)
* [Documenter's `makedocs` function](@extref Documenter.makedocs)
* See the section about Documenter's [Writers](@extref).
```

The above markdown code renders as follows:

> * [`Documenter.makedocs`](@extref)
> * [Documenter's `makedocs` function](@extref Documenter.makedocs)
> * See the section about Documenter's [Writers](@extref).


To disambiguate (and [speed up](@ref Performance-Tips)) the references, the name of the inventory (as defined when instantiating `InterLinks`) can be included in the `@extref`. In particular, the last example should have been written as

```
* See the section about Documenter's [Writers](@extref Documenter).
```

to clarify that we are linking to the section name "Writers" found in `links["Documenter"]`. When the link text and link target differ, the inventory name should be given between `@extref` and the target name, e.g., ```[`Regex`](@extref Julia Base.Regex)```, which turns into "[`Regex`](@extref Julia Base.Regex)".

Since `DocumenterInterLinks` is fully compatible with [Sphinx](@extref sphinx :doc:`index`) inventories, it also provides an extended `@extref` syntax that builds on the Sphinx concept of ["domains"](@extref sphinx :term:`domain`) and ["roles"](@extref sphinx :term:`role`). You will see these when inspecting an [`InventoryItem`](@extref `DocInventories.InventoryItem`):

```@example usage
using DocInventories

DocInventories.show_full(links["Documenter"]["Documenter.makedocs"])
```

We can include the domain and role in an `@extref` link as

```
* [`makedocs`](@extref :function:`Documenter.makedocs`)
* [`makedocs`](@extref :jl:function:`Documenter.makedocs`)
```

using a [syntax](@ref Syntax) that is reminiscent of the [Sphinx cross-referencing syntax](@extref sphinx xref-syntax). The use of domains and roles in `DocumenterInterLinks` ([unlike in Sphinx](@ref Compatibility-with-Sphinx)) is for disambiguation only, in case there are multiple items with the same `name`. In general, follow the [Recommended Syntax](@ref) guidelines.


## Public API and Changelog

The `DocumenterInterLinks` project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html). See the [`CHANGELOG`](https://github.com/JuliaDocs/DocumenterInterLinks.jl/blob/master/CHANGELOG.md) for changes after `v1.0`. The "public API" extends to the documented `@extref` [Syntax](@ref) and to the instantiation of the [`InterLinks`](@ref) plugin. Other [Internals](@ref) or features marked as "experimental" may change in minor versions.
