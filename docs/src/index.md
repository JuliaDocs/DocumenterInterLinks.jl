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

[DocumenterInterLinks.jl](https://github.com/JuliaDocs/DocumenterInterLinks.jl#readme) is a plugin for [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl) to link to external projects. It is interoperable with [InterSphinx](https://www.sphinx-doc.org/en/master/usage/extensions/intersphinx.html).

## Usage

* Load the package in your `docs/make.jl` file:

  ```
  using DocumenterInterLinks
  ```

  This is sufficient to generate and `objects.inv` file when the documentation is built with [`Documenter.makedocs`](@extref).


* Define an [`InterLinks`](@ref) mapping and pass the resulting object as an element of `plugins` to [`Documenter.makedocs`](@extref).


* Use `@extref` like you would normally use `@ref` to resolve links via the mappings defined in [`InterLinks`](@ref).
