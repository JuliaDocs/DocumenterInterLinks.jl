# How-Tos

---

```@contents
Pages=["howtos.md"]
Depth=3:3
```

---

### [How do I find a project's inventory file?](@id howto-inventory-location)

The documentation generator [should generate an inventory file](@ref Inventory-Generation) in the root of its output folder. These then get deployed with the rest of the documentation. For most projects, this "root" ends up in a subfolder named after the version or branch.

For example, you will find `objects.inv` inventory files under the following URLs:

* [https://www.sphinx-doc.org/en/master/objects.inv](https://www.sphinx-doc.org/en/master/objects.inv)
* [https://matplotlib.org/3.7.3/objects.inv](https://matplotlib.org/3.7.3/objects.inv)
* [https://docs.python.org/3/objects.inv](https://docs.python.org/3/objects.inv)
* [https://juliadocs.org/DocInventories.jl/stable/objects.inv](https://juliadocs.org/DocInventories.jl/stable/objects.inv)
* [https://juliadocs.org/DocInventories.jl/v0.2/objects.inv](https://juliadocs.org/DocInventories.jl/v0.2/objects.inv)

The [Julia language](@extref Julia :doc:`index`) and [Documenter.jl](@extref Documenter :doc:`index`) currently do not provide an inventory file, but if they did, it would be immediately underneath

* [https://docs.julialang.org/en/v1/](https://docs.julialang.org/en/v1/)
* [https://documenter.juliadocs.org/stable/](https://documenter.juliadocs.org/stable/)

If it is not obvious where an inventory file is located, simply try to load it in the REPL until you find a working URL:

```@repl howto-inventory-location
using DocInventories
Inventory("https://www.sphinx-doc.org/en/objects.inv")
Inventory("https://www.sphinx-doc.org/en/master/objects.inv")
```

If you cannot find any inventory file, see [What if I want to link to a project that does not provide an inventory file?](@ref howto-manual-inventory)


### [How do I figure out the correct name for the `@extref` link?](@id howto-find-extref)

Use the search capabilities of [`InterLinks`](@ref) or [`DocInventories.Inventory`](@extref).

If you have set up an [`InterLinks`](@ref) object named `links` in your `docs/make.jl` [as described before](@ref Declaring-External-Projects), you are presumably able to build your documentation locally by starting a Julia REPL in the appropriate environment (e.g., `julia --project=docs`) and then running `include("docs/make.jl")`.

This also puts the `links` object into your REPL, allowing you to search it interactively.

```@repl howto-find-extref
# include("docs/make.jl")
using DocumenterInterLinks # hide
links = InterLinks("sphinx" => "https://www.sphinx-doc.org/en/master/objects.inv", "matplotlib" => "https://matplotlib.org/3.7.3/", "Documenter" => ("https://documenter.juliadocs.org/stable/", joinpath(@__DIR__, "inventories", "Documenter.toml")), "Julia" => ("https://docs.julialang.org/en/v1/", joinpath(@__DIR__, "inventories", "Julia.toml"))); # hide
links
```

For example, trying to find the appropriate `@extref` link to to the [LaTeX Syntax](@extref Documenter :label:`latex_syntax`) section in the Documenter manual, you might search for

```@repl howto-find-extref
links["Documenter"]("latex")
```

and determine that an appropriate `@extref` would be

```
[LaTeX Syntax](@extref Documenter :label:`latex_syntax`)
```

[This search is quite flexible](@extref DocInventories Exploring-Inventories). Using regular expression, you could do something crazy like search the Julia documentation for docstrings of any method that involves two or more strings:

```@repl howto-find-extref
links["Julia"](r":method:`.*-.*AbstractString.*AbstractString.*`")
```

You can also search *across* all projects, using a lookup in the [`InterLinks`](@ref) object directly, e.g.,

```@repl howto-find-extref
links("`index`")
```

These matching `@extref` links should be modified according to the [Recommended Syntax](@ref).


### [What if I want to link to a project that does not provide an inventory file?](@id howto-manual-inventory)

Inventory files really should created [automatically using a documentation generator](@ref Inventory-Generation). Try to get the project to use one that produces inventory files or help them set up their documentation system so that it does.

Until `Documenter` incorporates the [Inventory Generation](@ref) currently provided by this plugin, one may produce an inventory file for an existing Julia/Documenter-based project by cloning the project, opening a REPL so that `include("docs/make.jl")` successfully builds the documentation for that projects, and then repeat `include("docs/make.jl")` after running

```julia
julia> ] add DocumenterInterLinks
julia> using DocumenterInterLinks
```

in the same REPL. You should then find an `objects.inv` in the `docs/build` folder. [Use the `DocInventories` package to convert it](@extref DocInventories Saving-Inventories-to-File) to [TOML Format](@extref DocInventories). This is how the [inventory files](https://github.com/JuliaDocs/DocumenterInterLinks.jl/tree/master/docs/src/inventories) used in this documentation were generated, e.g., for the Julia project itself.

These inventory files are also available in the [project wiki](https://github.com/JuliaDocs/DocumenterInterLinks.jl/wiki/Inventory-File-Repository). You may contribute your own generated inventories there.

There may be projects that legitimately do not provide inventories. For example, some simple Julia projects write out their entire documentation in their README on Github. In that case, you should either use [standard links](@extref Julia `Links`) or [manually create an inventory file](@extref DocInventories Creating-Inventory-Files). The easiest way to do this is to write out an inventory in [TOML Format](@extref DocInventories) by hand.


### [Can I use this plugin for general external links?](@id howto-external-links)

Documenter's markdown flavor [lacks the ability for reference links](https://discourse.julialang.org/t/how-to-use-markdown-reference-links-with-documenter-jl/84232). If you link to the same very long URLs repeatedly, this becomes cumbersome.

In principle, you could [manually write out an inventory file](@extref DocInventories Creating-Inventory-Files) that defines link labels and their associated URLs, along the lines of the discussion in [Documenter's PR #1351](https://github.com/JuliaDocs/Documenter.jl/pull/1351). Whether you *should* abuse `DocumenterInterLinks` in this way might be a matter of debate.

A situation where I do think this makes sense is if you repeatedly link to some website with very structured content, e.g. Wikipedia or the [Julia Discourse Forum](https://discourse.julialang.org). As [shown in the `DocInventories` documentation](@extref DocInventories Maintain-an-Inventory-TOML-File-by-Hand), you could write a `Wikipedia` inventory file just for the articles you want to link to, and then have a link such as

```
[Julia](@extref Wikipedia)
```

in your documentation to link to [Julia (programming language)](https://en.wikipedia.org/wiki/Julia_(programming_language)).
