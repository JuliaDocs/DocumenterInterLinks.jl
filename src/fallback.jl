using Documenter: Documenter, Plugin
import Documenter: XRefResolvers, Selectors, xref_unresolved

"""Plugin for letting `@ref` links fall back to `@extref` links.

!!! warning
    This plugin is available only with `Documenter >= v1.3.0` and should be
    considered as experimental.

```julia
fallbacks = ExternalFallbacks(pairs...)
```

defines a mapping of `@ref`-slugs to `@external` links. If an `@ref` cannot be
resolved locally, the [`InterLinks`](@ref) plugin will be used to resolve it
with the `@extref` link target defined in the mapping.

The `@ref`-slug can be found in the message printed by `Documenter` when it
cannot resolve an `@ref` link, e.g.,

```
Error: Cannot resolve @ref for 'makedocs' …
Error: Cannot resolve @ref for 'Other-Output-Formats'
```

from some unresolvable links ```[`makedocs`](@ref)``` and
`[Other Output Formats](@ref)`.

The "slug" is the string inside the quotes. It should be mapped to a complete
`@extref` link, e.g.,

```julia
fallbacks = ExternalFallbacks(
    "makedocs" => "@extref Documenter.makedocs",
    "Other-Output-Formats" =>  "@extref Documenter `Other-Output-Formats`",
)
```

This will then resolve the link ```[`makedocs`](@ref)``` as if it had been
written as ```[`makedocs`](@extref Documenter.makedocs)```, and
`[Other Output Format](@ref)` as if it had been written as
```[Other Output Format](@extref Documenter `Other-Output-Formats`)```
and link to [`makedocs`](@ref) and [Other Output Formats](@ref), respectively.
"""
struct ExternalFallbacks <: Plugin
    mapping::Dict{String,String}
    function ExternalFallbacks(pairs::Pair{String,String}...)
        mapping = Dict{String,String}()
        for (k, v) in pairs
            if startswith(v, "@extref ")
                mapping[k] = v
            else
                throw(ArgumentError("value in mapping must start with \"@extref \""))
            end
        end
        new(mapping)
    end
end


function Base.show(io::IO, fallbacks::ExternalFallbacks)
    print(io, "ExternalFallbacks(")
    N = length(fallbacks.mapping)
    for (i, (k, v)) in enumerate(fallbacks.mapping)
        print(io, "$(repr(k)) => $(repr(v))")
        (i < N) && print(io, ", ")
    end
    print(io, ")")
end


function Base.show(io::IO, ::MIME"text/plain", fallbacks::ExternalFallbacks)
    N = length(fallbacks.mapping)
    if N > 2
        println(io, "ExternalFallbacks(")
        for (k, v) in fallbacks.mapping
            println(io, "  $(repr(k)) => $(repr(v)),")
        end
        println(io, ")")
    else
        show(io, fallbacks)
    end
end


abstract type ExternalFallbackResolver <: XRefResolvers.XRefResolverPipeline end


Selectors.order(::Type{ExternalFallbackResolver}) = 10.0


function Selectors.matcher(
    ::Type{ExternalFallbackResolver},
    node,
    slug,
    meta,
    page,
    doc,
    errors
)
    fallback = Documenter.getplugin(doc, ExternalFallbacks)
    return (xref_unresolved(node) && haskey(fallback.mapping, slug))
end


function Selectors.runner(
    ::Type{ExternalFallbackResolver},
    node,
    slug,
    meta,
    page,
    doc,
    errors
)
    links = Documenter.getplugin(doc, InterLinks)
    fallback = Documenter.getplugin(doc, ExternalFallbacks)
    @assert node.element isa MarkdownAST.Link
    extref = fallback.mapping[slug]
    m = match(links.rx, extref)
    @assert !isnothing(m)  # Can't think of any way for the match to fail
    if isnothing(m["spec"])
        push!(errors, "$(repr(extref)) is not a complete @extref link")
    end
    try
        node.element.destination = find_in_interlinks(links, extref)
    catch exc
        push!(errors, "Cannot resolve $(repr(extref))")
    end

end
