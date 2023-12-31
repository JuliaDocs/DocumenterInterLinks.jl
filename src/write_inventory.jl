using Documenter.Builder: DocumentPipeline
using Documenter.HTMLWriter: HTML, HTMLContext, get_url, pretty_url, getpage, pagetitle
using Documenter.MDFlatten: mdflatten
using Documenter: Documenter, anchor_fragment, doccat
using DocInventories: Inventory, InventoryItem, save as save_inventory
import Documenter: Selectors


"""
Pipeline step to write the `objects.inv` inventory to the `build` directory.

This runs after [`Documenter.Builder.RenderDocument`](@extref Documenter) and
only if Documenter was set up for HTML output.
"""
abstract type WriteInventory <: DocumentPipeline end

Selectors.order(::Type{WriteInventory}) = 6.1  # after RenderDocument

function Selectors.matcher(::Type{WriteInventory}, doc::Documenter.Document)
    return any(fmt -> (fmt isa HTML), doc.user.format)
end


# from URIs.jl
@inline _issafe(c::Char) =
    c == '-' || c == '.' || c == '_' || (isascii(c) && (isletter(c) || isnumeric(c)))


_utf8_chars(str::AbstractString) = (Char(c) for c in _bytes(str))

_bytes(s::SubArray{UInt8}) = unsafe_wrap(Array, pointer(s), length(s))

_bytes(s::Union{Vector{UInt8},Base.CodeUnits}) = _bytes(String(s))
_bytes(s::AbstractString) = codeunits(s)

_bytes(s::Vector{UInt8}) = s

escapeuri(c::Char) = string('%', uppercase(string(Int(c), base=16, pad=2)))
escapeuri(str::AbstractString) =
    join(_issafe(c) ? c : escapeuri(c) for c in _utf8_chars(str))


function get_inventory_uri(doc, ctx, name, anchor)
    filename = relpath(anchor.file, doc.user.build)
    page_url = pretty_url(ctx, get_url(ctx, filename))
    label = escapeuri(Documenter.anchor_label(anchor))
    if label == name
        uri = page_url * raw"#$"
    else
        uri = page_url * "#$label"
    end
    return uri
end


function get_inventory_dispname(name, anchor)
    dispname = mdflatten(anchor.node)
    if dispname == name
        dispname = "-"
    end
    return dispname
end


function get_navnode_dispname(navnode, ctx)
    dispname = navnode.title_override
    if isnothing(dispname)
        page = getpage(ctx, navnode)
        title_node = pagetitle(page.mdast)
        if isnothing(title_node)
            dispname = "-"
        else
            dispname = mdflatten(title_node)
        end
    end
    return dispname
end


function Selectors.runner(::Type{WriteInventory}, doc::Documenter.Document)

    @info "WriteInventory: writing `objects.inv` file."

    project = doc.user.sitename
    version = doc.user.version
    inventory = Inventory(project=project, version=version)
    if isempty(version)
        @warn "No `version` in `makedocs`. Please pass `version` as a keyword argument."
    end
    i_html = findfirst(fmt -> (fmt isa HTML), doc.user.format)
    if isnothing(i_html)
        @info "Skip writing`objects.inv`: No HTML output"
        return
    end
    ctx = HTMLContext(doc, doc.user.format[i_html])

    domain = "std"
    role = "doc"
    priority = -1
    for navnode in doc.internal.navlist
        name = splitext(navnode.page)[1]
        uri = pretty_url(ctx, get_url(ctx, navnode.page))
        dispname = get_navnode_dispname(navnode, ctx)
        push!(inventory, InventoryItem(name, domain, role, priority, uri, dispname))
    end

    domain = "std"
    role = "label"
    priority = -1
    for name in keys(doc.internal.headers.map)
        anchor = Documenter.anchor(doc.internal.headers, name)
        if isnothing(anchor)
            # anchor not unique -> exclude from inventory
            continue
        end
        uri = get_inventory_uri(doc, ctx, name, anchor)
        dispname = get_inventory_dispname(name, anchor)
        push!(inventory, InventoryItem(name, domain, role, priority, uri, dispname))
    end

    domain = "jl"
    priority = 1
    for name in keys(doc.internal.docs.map)
        anchor = Documenter.anchor(doc.internal.docs, name)
        if isnothing(anchor)
            # anchor not unique -> exclude from inventory
            continue
        end
        uri = get_inventory_uri(doc, ctx, name, anchor)
        role = lowercase(doccat(anchor.object))
        dispname = "-"
        push!(inventory, InventoryItem(name, domain, role, priority, uri, dispname))
    end

    filename = joinpath(doc.user.build, "objects.inv")
    save_inventory(filename, inventory)

end
