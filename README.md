# DocumenterInterLinks.jl

[![Version](https://juliahub.com/docs/DocumenterInterLinks/version.svg)](https://juliahub.com/ui/Packages/General/DocumenterInterLinks)
[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://juliadocs.org/DocumenterInterLinks.jl/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://juliadocs.org/DocumenterInterLinks.jl/dev)
[![Build Status](https://github.com/JuliaDocs/DocumenterInterLinks.jl/workflows/CI/badge.svg)](https://github.com/JuliaDocs/DocumenterInterLinks.jl/actions)
[![Coverage](https://codecov.io/gh/JuliaDocs/DocumenterInterLinks.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaDocs/DocumenterInterLinks.jl)

A plugin for [Documenter.jl](https://documenter.juliadocs.org/) that enables linking between projects.

**WARNING: This is a prototype. If you use this package pre-1.0, be prepared to having to adapt to breaking changes at any time.**

Loading `DocumenterInterLinks` in `docs/make.jl` causes Documenter to produce an "inventory file" `objects.inv` in the output folder, which should get deployed together with the documentation. This file contains a mapping from names to URLs for all link targets in the documentation.

Other projects may use this inventory file to resolve `@extref` links, see [External Citations](#external-citations).


## Installation

As usual, the package can be installed via

```
] add DocumenterInterLinks
```

in the Julia REPL, or by adding

```
DocumenterInterLinks = "d12716ef-a0f6-4df4-a9f1-a5a34e75c656"
```

to the relevant `Project.toml` file.


## Plugin Instantiation

In `docs/make.jl`, instantiate an [`InterLinks`](https://juliadocs.org/DocumenterInterLinks.jl/stable/internals/#DocumenterInterLinks.InterLinks) object:

```julia
using DocumenterInterLinks

links = InterLinks(
    "project1" => "https://project1.url/",
    "project2" => "https://project2.url/inventory.file",
    "project3" => (
        "https://project3.url/",
        joinpath(@__DIR__, "src", "interlinks", "inventory.file")
    )
)
```

See [`docs/make.jl`](https://github.com/JuliaDocs/DocumenterInterLinks.jl/blob/master/docs/make.jl#L11-L27) for an example.

The resulting plugin object that must be passed as an element of the `plugins` keyword argument to `Documenter.makedocs`. This then enables `@extref` links in the project's documentation to be resolved.

See [`docs/src/inventories`](https://github.com/JuliaDocs/DocumenterInterLinks.jl/tree/master/docs/src/inventories) for some exemplary inventory files in [TOML format](https://juliadocs.org/DocInventories.jl/stable/formats/#TOML-Format).


## External Citations

Instead of [Documenter's `@ref`](https://documenter.juliadocs.org/stable/man/syntax/#@ref-link), the `@extref` link target can be used to resolve the link via any of the available projects defined in the `InterLinks` plugin:

```
* [`Documenter.makedocs`](@extref)
* [Documenter's `makedocs` function](@extref `Documenter.makedocs`)
* See the section about Documenter's [Writers](@extref Documenter).
```

See the [documentation](https://juliadocs.org/DocumenterInterLinks.jl/dev/#Using-External-References) and [recommended syntax](https://juliadocs.org/DocumenterInterLinks.jl/dev/syntax/#Recommended-Syntax) for details.


## Inventories

Until [Documenter issue #2366](https://github.com/JuliaDocs/Documenter.jl/issues/2366) is resolved and a version of Documenter is released and widely adopted that automatically writes inventory files, you may obtain inventory files for some projects at the [Inventory File Repository (Wiki)](https://github.com/JuliaDocs/DocumenterInterLinks.jl/wiki/Inventory-File-Repository). Feel free to [generate your own inventory files](http://juliadocs.org/DocumenterInterLinks.jl/stable/howtos/#howto-manual-inventory) and contribute them.


## Documentation

The [full documentation of this project is available online](https://juliadocs.org/DocumenterInterLinks.jl/dev/).
