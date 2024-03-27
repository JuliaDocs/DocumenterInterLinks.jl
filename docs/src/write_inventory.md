# Inventory Generation

The inventory files that get loaded into [`InterLinks`](@ref) should be automatically created by a project's documentation generator.

* The [Sphinx documentation generator](@extref sphinx :doc:`index`) used by most Python packages automatically [creates an `objects.inv` inventory file](@extref sphinx :doc:`usage/extensions/intersphinx`) in the root of every HTML build.
* For Julia projects that build their documentation with [`Documenter`](@extref Documenter :doc:`index`) `≥ v1.3`, an `objects.inv` inventory file in the same format is automatically created in the `docs/build/` folder.
* [`DocumenterInventoryWritingBackport.jl`](https://github.com/JuliaDocs/DocumenterInventoryWritingBackport.jl) backports the automatic inventory writing to older versions of `Documenter` (`≥ v0.25`). This package simply needs to be loaded in a project's `docs/make.jl` file.
* Any package loading `DocumenterInterLinks` in `docs/make.jl` also gets the `DocumenterInventoryWritingBackport` automatically.

The inventory file should be deployed together with the rest of the documentation, so that it is [accessible to other projects](@ref howto-inventory-location). When a project does not use a documentation generator that writes an inventory file, it may be possible to [maintain an inventory by hand](@ref howto-manual-inventory). See also the [Wiki](https://github.com/JuliaDocs/DocumenterInterLinks.jl/wiki/Inventory-File-Repository) for a collection of inventory files for Julia and other projects.

For a Documenter-based project, the automatic inventory contains:

* An entry for every docstring included in the documentation. These use [the ad-hoc `jl` domain](@ref The-Julia-Domain) and a `role` that depends on the object.
* An entry for every section heading. To ensure compatibility with Sphinx, these entries use the `std` domain, the `label` role, a slugified version of the heading (or [the explicit header `@id`](@extref Documenter Duplicate-Headers)) as a `name`, and the full heading (stripped of formatting, but including spaces) as the `dispname`.
* An entry for every page in the documentation. These use the `std` domain and the `doc` role. The name is the path (with Unix-style forward-slash path separators) of the `.md` file from which the page was generated, without the `.md` extension. This should correspond to the relative URI of the resulting page, excluding a final slash or an `.html` extension.

## The Julia Domain

!!! info
    You  probably will not need to worry about the information in this section.

The inventory for a `Documenter`-based documentation includes [entries](@extref `DocInventories.InventoryItem`) for docstrings using an [ad-hoc](@ref Compatibility-with-Sphinx) `jl` domain. The `role` for each entry matches how `Documenter` identifies the underlying object with [`Documenter.doccat`](@extref). You will find this identification as part of how the docstring shows in the documentation; for example, note the "— Type" in the header of [` DocumenterInterLinks.InterLinks`](@ref). The `role` that will be written to the inventory is simply the lowercase string of this identification. Currently, `Documenter` uses the following:

* "Macro" (role `macro`): for macros. For example, ```":jl:macro:`Base.@inbounds`"``` for [`Base.@inbounds`](@extref Julia :jl:macro:`Base.@inbounds`).
* "Keyword" (role `keyword`): for Julia keywords (used in the documentation of the Julia language itself, only). For example, ```":jl:keyword:`if`"``` for [the `if` keyword](@extref Julia :jl:keyword:`if`).
* "Function" (role `function`): for functions. For example, ```":jl:function:`Statistics.mean`"``` for [`Statistics.mean`](@extref Julia :jl:function:`Statistics.mean`).
* "Method" (role `method`): for methods of functions. This is used when there is a docstring for a specific tuple of argument types. For example, ```":jl:method:`Base.:*-Tuple{AbstractMatrix, AbstractMatrix}`"``` for the [`*` operator of two matrices](@extref Julia :jl:method:`Base.:*-Tuple{AbstractMatrix, AbstractMatrix}`).
* "Type" (role `type`): For types, both structs and abstract types. For example, ```":jl:type:`Base.AbstractMatrix`"``` for [`AbstractMatrix`](@extref Julia :jl:type:`Base.AbstractMatrix`).
* "Module" (role `module`): For modules. For example, ```":jl:module:`LinearAlgebra.BLAS`"``` for [`LinearAlgebra.BLAS`](@extref Julia :jl:module:`LinearAlgebra.BLAS`).
* "Constant" (role `constant`): For documented data / constants inside a module. For example, ```":jl:constant:`Base.VERSION`"``` for [Julia's `VERSION` constant](@extref Julia :jl:constant:`Base.VERSION`).

As discussed in [Syntax](@ref), the domain and roles are for disambiguation only. In practice, the above example references might be written as

```
* [`Base.@inbounds`](@extref)
* [the `if` keyword](@extref Julia `if`)
* [`Statistics.mean`](@extref)
* [`*` operator of two matrices](@extref `Base.:*-Tuple{AbstractMatrix, AbstractMatrix}`)
* [`LinearAlgebra.BLAS`](@extref)
* [Julia's `VERSION` constant](@extref `Base.VERSION`)
```

These render as:

> * [`Base.@inbounds`](@extref)
> * [the `if` keyword](@extref Julia `if`)
> * [`Statistics.mean`](@extref)
> * [`*` operator of two matrices](@extref `Base.:*-Tuple{AbstractMatrix, AbstractMatrix}`)
> * [`LinearAlgebra.BLAS`](@extref)
> * [Julia's `VERSION` constant](@extref `Base.VERSION`)

Leaving out the project name `Julia` in all but the second item [is recommended](@ref Performance-Tips) only if `Julia` is the *first* project in the [`InterLinks`](@ref) object.
