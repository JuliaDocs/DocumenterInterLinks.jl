# Test of Fallback Resolution

We can have a local link like [`makedocs`](@ref) fall back to `@extref` (although this is very much not recommended usage: this should have been written with an `@extref` link directly).

The real purpose of the [`ExternalFallbacks`](@ref) [`Plugin`](@ref Documenter.Plugin) is that we can embed docstrings that might contain their own `@ref` links:

```@docs
DocumenterInterLinks.ExternalFallbacks
Documenter.Plugin
DocInventories.MIME_TYPES
```
