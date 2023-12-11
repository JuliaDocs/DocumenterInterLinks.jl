# DocumenterInterLinks.jl

A plugin for [Documenter.jl](https://documenter.juliadocs.org/) that enables linking between projects.

Loading `DocumenterInterLinks` in `Docs/make.jl` causes Documenter to produce an "inventory file" `objects.inv` in the output folder, which should get deployed together with the documentation. This file contains a mapping from names to URLs for all link targets in the documentation.

Other projects may use this inventory file to resolve `@extref` links, see [External Citations](#external-citations).


## Installation

This package is currently under active development, and serves as a prototype for https://github.com/JuliaDocs/Documenter.jl/issues/2366. It is pending registration, and thus must be dev-installed.

It depends on `DocInventories`, which should be dev-installed from https://github.com/JuliaDocs/DocInventories.jl first.


## Plugin Instantiation

In `docs/make.jl`, instantiate an `InterLinks` object:

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

<details>
<summary>Arguments</summary>

The `InterLinks` plugin receives mappings of project names to the project root URL and inventory locations. Each project names must be an alphanumerical ASCII string. For Julia projects, it should be the name of the package without the `.jl` suffix, e.g., `"Documenter"` for [Documenter.jl](https://documenter.juliadocs.org/). For Python projects, it should be the name of project's main module.

The root url / inventory location (the value of the mapping), can be given in any of the following forms:

* A single string with a URL of the inventory file, e.g.

  ```
  "sphinx" => "https://www.sphinx-doc.org/en/master/objects.inv"
  ````

  The root URL relative which all URIs inside the inventory are taken to be relative is everything up to the final slash in the inventory URL, `"https://www.sphinx-doc.org/en/master/"` in this case.

* A single string with a project root URL, for example,

  ```
  "sphinx" => "https://www.sphinx-doc.org/en/master/",
  ````

  which must end with slash. This is exactly equivalent to previous example: it assumes `"objects.inv"` (the standard [Sphinx](https://www.sphinx-doc.org/) inventory file) to be reachable directly underneath the given URL.

* A tuple of strings, where the first element is the project root URL and all
  subsequent elements are locations (URLs or local file paths) to an inventory
  file, e.g.,

  ```
  "Julia" => (
      "https://docs.julialang.org/en/v1/",
      joinpath(@__DIR__, "src", "interlinks", "Julia.toml")
  ),
  "Documenter" => (
      "https://documenter.juliadocs.org/stable/",
      "https://documenter.juliadocs.org/stable/inventory.toml.gz",
      joinpath(@__DIR__, "src", "interlinks", "Documenter.toml")
  )
  ```

  The first reachable inventory file will be used. This enables, e.g., to
  define a local inventory file as a fallback in case the online inventory file
  location is unreachable, as in the last example.

* A `DocInventories.Inventory` instance.

</details>

See [`docs/src/interlinks`](https://github.com/JuliaDocs/DocumenterInterLinks.jl/tree/master/docs/src/interlinks) for some exemplary inventory file in TOML format.

## External Citations

Instead of Documenter's `@ref`, the `@extref` link target can be used to resolve the link via any of the available inventories set up in the `InterLinks` plugin:

```
* [`Documenter.makedocs`](@extref)
* [Documenter's `makedocs` function](@extref Documenter.makedocs)
* See the section about Documenter's [Writers](@extref).
```

To disambiguate (and speed up) the references, the name of the inventory (as defined when instantiating `InterLinks`) can be included in the `@extref`. The previous example would have been better written as

```
* See the section about Documenter's [Writers](@extref Documenter).
```

to clarify that we are linking to the section name "Writers" in Documenter's documentation. When the link text and link target differ, the inventory name should be given between `@extref` and the target name.


```
* [`Regex`](@extref Julia Base.Regex)
```


## Compatibility with Sphinx

`DocumenterInterLinks` is fully compatible with [Sphinx](https://www.sphinx-doc.org/en/master/), respectively [Intersphinx](https://www.sphinx-doc.org/en/master/usage/quickstart.html#intersphinx). That is, `DocumenterInterLinks` writes an `objects.inv` file that is compatible with Intersphinx, and conversely, by loading existing `objects.inv` from (mostly Python) projects that build their documentation with Sphinx in the `InterLinks` plugin, `@extref` can link to the documentation of these non-Julia projects.

Sphinx/Intersphinx has the concept of ["domains"](https://www.sphinx-doc.org/en/master/glossary.html#term-domain) and ["roles"](https://www.sphinx-doc.org/en/master/glossary.html#term-role). When generating the `objects.inv` file, `DocumenterInterLinks` uses an ad-hoc `jl` domain for Julia code objects, with the possible roles `obj`, `macro`, `func`, `abstract`, `type`, and `mod` (cf. `DocInventories.JULIA_ROLES`). Section headings are registered with the domain `std` and role `label`  and output html files with the domain `std` and role `doc`.

The domain and role can optionally be included in an `@extref` link, using the same [cross-referencing syntax as Sphinx](https://www.sphinx-doc.org/en/master/usage/referencing.html#cross-referencing-syntax):

```
:domain:role:`name`
:role:`name`
```

Some examples:

```
* [`Documenter.makedocs`](@extref :jl:func:`Documenter.makedocs`)
* [`Documenter.makedocs`](@extref :func:`Documenter.makedocs`)
* [Sphinx](@extref sphinx :doc:`index`)
* [`subplots`](@extref matplotlib :py:function:`matplotlib.pyplot.subplots`)
```

`DocumenterInterLinks` is much less strict than Sphinx (which requires that domains are formally defined). The optional domain and role in `@extref` links are for disambiguation only. If a domain or role is not specified, anything will match.


# Usage of DocumenterInterLinks inventory files with Sphinx

See [`index.rst`](https://raw.githubusercontent.com/goerz-testing/test-sphinx-to-documenter-links/master/docs/source/index.rst) in [`goerz-testing/test-sphinx-documenter-links`](https://github.com/goerz-testing/test-sphinx-to-documenter-links) for an example of how to use the inventory from within Sphinx.

This includes a minimal [formal definition of the custom `jl` domain](https://github.com/goerz-testing/test-sphinx-to-documenter-links/blob/master/docs/source/_extensions/julia_domain.py), which is required in order for Sphinx to resolve links to Julia objects.
