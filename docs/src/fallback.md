# Fallback Resolution

!!! warning
    The [`ExternalFallbacks`](@ref) plugin described here is available only with `Documenter >= v1.3.0` and should be considered experimental.

In some situations, you may need to include a docstring from an external package in your documentation – for example, you you are extending a function from that package, you may want to show the function docstring. If that docstrings contains an `@ref` link, you have a problem: that link is resolvable in the external documentation, but not in *your* documentation.

If the `@ref` link is to another code object, you could include that docstring in your documentation as well, and so forth, until all references can be resolved. Unfortunately, you might end up having to include a significant portion of the external package's documentation, which is less than ideal.

The situation is even worse if the `@ref` link is to a section header. For example, the docstring of [`DocInventories.MIME_TYPES`](@extref) includes a reference to the section on [inventory file formats](@extref DocInventories Inventory-File-Formats) in the `DocInventories` documentation.
In that case, there is no way to make the reference resolve in your documentation (short of adding an "Inventory File Formats" section to your own documentation).

To remedy this, the `DocumenterInterLinks` package provides a special plugin, [`ExternalFallbacks`](@ref), that can rewrite specific `@ref` links to `@extref` links. It is instantiated by providing a mapping between "slugs" and `@extref` link specifications. For example,

```
fallbacks = ExternalFallbacks(
    "Inventory-File-Formats" => "@extref DocInventories `Inventory-File-Formats`",
)
```

!!! warning
    Like any plugin (and like the [`InterLinks`](@ref) object), `fallbacks` must be passed to [`Documenter.makedocs`](@extref) as an element of `plugins`.

The "slug" on the left-hand-side of the mapping can be obtained from message that `Documenter` prints when it fails to resolve the `@ref` link. Generally, for `[Section Title](@ref)` or `[text](@ref "Section Title)`, the slug is a "sluggified" version of the title (determined internally by `Documenter`, mostly just replacing spaces with dashes); and for ```[`code`](@ref)``` or `[text](@ref code)`, it is `"code"`. The right-hand-side of the mapping is a full `@extref` link. The plugin simply replaces the link target of original `@ref` link with the given `@extref`.

If there are any unresolvable `@ref` links, and there is no explicit `@extref`-mapping, [`ExternalFallbacks`](@ref) will search in all available inventories to resolve the link in an "automatic" mode. In this case, you will see messages like

```
[ Info: ExternalFallbacks automatic resolution of "Inventory-File-Formats" => "@extref DocInventories :std:label:`Inventory-File-Formats`"
```

in the output of [`Documenter.makedocs`](@extref). If this is correct, you should copy ```"Inventory-File-Formats" => "@extref DocInventories :std:label:`Inventory-File-Formats`"``` explicitly into the instantiation of the [`ExternalFallbacks`](@ref) plugin. The "automatic resolution" is both slow and has the potential for misidentifying the `@extref` link.

!!! warning
    Do not use `@ref` links in your documentation when you could use an `@extref` link! The [`ExternalFallbacks`](@ref) plugin is intended as a "last resort" to be used deliberately, not to automatically resolve all `@ref` links via [`InterLinks`](@ref) (the way the [Intersphinx](@extref sphinx :doc:`usage/extensions/intersphinx`) plugin does in [Sphinx](@extref sphinx :doc:`index`)).


With an `@extref` mapping for `"Inventory-File-Formats"` in place, it is now possible to include the docstring for [`DocInventories.MIME_TYPES`](@extref):


```@docs
DocInventories.MIME_TYPES
```

Note that the link in the last line of the docstring is an external link.
