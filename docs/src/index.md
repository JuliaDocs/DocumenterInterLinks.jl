# DocumenterInterLinks.jl

[DocumenterInterLinks.jl](https://github.com/JuliaDocs/DocumenterInterLinks.jl#readme) is a plugin for [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl) to link to external projects. It is interoperable with [InterSphinx](https://www.sphinx-doc.org/en/master/usage/extensions/intersphinx.html).

## Usage

* Load the package in your `docs/make.jl` file:

  ```
  using DocumenterInterLinks
  ```

  This is sufficient to generate and `objects.inv` file when the documentation is built with [`Documenter.makedocs`](@extref).


* Define an [`InterLinks`](@ref) mapping and pass the resulting object as an element of `plugins` to [`Documenter.makedocs`](@extref).


* Use `@extref` like you would normally use `@ref` to resolve links via the mappings defined in [`InterLinks`](@ref).
