# Syntax

The possible forms of an `@extref` link are as follows:

1. ```[title](@extref)``` where `title` is a section title
2. ```[`name`](@extref)``` where `name` is a fully specified code object 🏅
3. ```[text](@extref name)``` where `text` is an arbitrary link text
4. ```[text](@extref `name`)``` where `name` is a fully specified code object or sluggified section title  🏅
5. ```[title](@extref project)``` where `project` is a known project in the underlying [`InterLinks`](@ref) object
6. ```[`name`](@extref project)``` 🥈
7. ```[text](@extref :role:`name`)```
8. ```[text](@extref :domain:role:`name`)```
9. ```[text](@extref project name)```
10. ```[text](@extref project `name`)``` 🏅
11. ```[text](@extref project :role:`name`)``` 🥈
12. ```[text](@extref project :domain:role:`name`)```


The most commonly used forms of syntax should be (2), (4), and (10) 🏅, with (6), and (11) being useful in some situations 🥈, see the [Recommended Syntax](@ref).

Assuming an [`InterLinks`](@ref) instance `links`, all of the above will reference the [`DocInventories.InventoryItem`](@extref) `links[project][":domain:role:name"]`. If `project` is not specified, the first project in `links` that contains a matching item will be used (up to a [performance shortcut](@ref Performance-Tips)). If `domain` or `role` are not given, any domain or role will match.

Forms (1-3) most directly extend [Documenter's built-in `@ref` syntax](@extref Documenter `@ref-link`), but are not universally recommended for [optimum performance](@ref Performance-Tips). Form (5) takes precedence over form (3) if `project` is a known element of `links`. The use of backticks in form (4) would avoid this ambiguity.

Forms (1) and (5) apply a [`sluggification`](@extref `Documenter.slugify-Tuple{AbstractString}`) to transform `title` into a `name`.  This matches Documenter's `@ref` behavior for linking to section titles. The specifics of the sluggification algorithm are not guaranteed to be stable between different versions of Documenter, and they do not match the sluggification used by other documentation generators like [Sphinx](@extref sphinx :doc:`index`). For this reason, forms (1) and (5) only have limited usefulness.

## Performance Tips

Although resolving external references is unlikely to have a significant impact on the build time of a project's documentation, there are some internals that affect the relative performance of the above `@extref` syntax forms.

When no `project` is given in the `@extref` specification, all projects declared in the [`InterLinks`](@ref) object may have to be searched for a matching item. The projects are searched in order, so the ordering in the definition of [`InterLinks`](@ref) matters.

However, `DocumenterInterLinks` implements a short-circuit mechanism to avoid having to specify the `project` when linking to code objects in most cases: If `name` is enclosed in backticks, and starts with the name of a `project` followed by a period, then that project is searched first.

For example, in order to link to [`Documenter.makedocs`](@extref), we can use

```
[`Documenter.makedocs`](@extref)
```

to immediately search the inventory `links["Documenter"]`, making the reference lookup as efficient as for the more verbose

```
[`Documenter.makedocs`](@extref Documenter)
```

Further `@extref` calls that will use the short-circuit mechanism for efficient lookup are

```
[`makedocs`](@extref `Documenter.makedocs`)
[`makedocs`](@extref :function:`Documenter.makedocs`)
[`makedocs`](@extref :jl:function:`Documenter.makedocs`)
```

where the latter two are unnecessarily verbose, as `Documenter.makedocs` is already uniquely specified without the `role` or `domain`.

On the other hand,

```
[`makedocs`](@extref Documenter.makedocs)
```

will work, but it will *not* use the short-circuit mechanism, due to the lack of backticks.

The short-circuit mechanism only works if the project name used in the instantiation of [`InterLinks`](@ref) matches the package name as it occurs in the fully specified name of any code object. That is, name the project `"Documenter"`, not, e.g., `"Documenter121"` for version `1.2.1` of `Documenter`.

When this is not possible, e.g. for the `Julia` project which contains many different modules without a common prefix (`Base`, `Core`, `LinearAlgebra`, …), it is best to declare that project as the *first* element in [`InterLinks`](@ref). That way,

```
[`Base.sort!`](@extref)
```

looks in the `Julia` project first, avoiding the need for

```
[`Base.sort!`](@extref Julia)
```

(although you may still prefer the latter as a matter of clarity).


!!! warning
    If possible, use the name of a package as it occurs in the fully specified name of any code objects when declaring the project in [`InterLinks`](@ref).


## Recommended Syntax

With the [Performance Tips](@ref) in mind, not all of the [12 possible Syntax forms](@ref Syntax) are recommended in practice. For maximum clarity and performance, use the following guidelines:

1. When referencing section headers in another project, e.g. the [Basic Markdown](@extref Documenter Basic-Markdown) section in Documenter's documentation, look up the appropriate sluggified name:

   ```@example syntax
   using DocumenterInterLinks # hide
   links = InterLinks("Documenter" => ("https://documenter.juliadocs.org/stable/", joinpath(@__DIR__, "inventories", "Documenter.toml")),) # hide
   links["Documenter"]("Basic Markdown")
   ```

   and use form (10):

   ```
   [Basic Markdown](@extref Documenter `Basic-Markdown`)
   ```

2. When directly referencing a code object, e.g., [`Documenter.makedocs`](@extref), use form (2):

   ```
   [`Documenter.makedocs`](@extref)
   ```

   Make sure that `Documenter` is a project name in `links` (see [Performance Tips](@ref)).

   This gets slightly more complicated when the code object is a "method" (where the docstring is for specific types of arguments), e.g., [`Documenter.parseblock`](@extref `Documenter.parseblock-Tuple{AbstractString, Any, Any}`). You will generally have to look up the full name

   ```@example syntax
   links["Documenter"]("parseblock")
   ```

   and then use form (4),

   ```
   [`Documenter.parseblock`](@extref `Documenter.parseblock-Tuple{AbstractString, Any, Any}`)
   ```

   If the module name of the object cannot match the project name (e.g., for the `Julia` documentation, which contains docstrings for `Base`, `Core`, `LinearAlgebra`, etc.), use form (6),

   ```
   [`Base.sort!`](@extref Julia)
   ```

3. When referencing a page, e.g. the [Home page of the Documenter documentation](@extref Documenter :doc:`index`), use form (11):

   ```
   [Home page of the Documenter documentation](@extref Documenter :doc:`index`)
   ```

   The `doc` role is not strictly necessary, but it clearly distinguishes references to documents from references to headings (especially when both may exist with the same `name`).


Thus, the most commonly used forms of syntax for `@extref` links should be (2), (4), and (10), highlighted with 🏅 in [Syntax](@ref), with (6), and (11) being useful in some situations (🥈).
