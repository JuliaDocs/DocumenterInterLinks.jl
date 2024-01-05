using Documenter.Builder: DocumentPipeline
using Documenter.HTMLWriter: HTML, HTMLContext, get_url, pretty_url, getpage, pagetitle
using Documenter.MDFlatten: mdflatten
using Documenter: Documenter, anchor_fragment, doccat
import Documenter: Selectors
using TOML  # to properly escape strings
using CodecZlib


# Note: this file does not use `DocInventories`, but writes out the inventory
# files (.inv and .toml.gz) directly. This is so that the code could be moved
# into Documenter without incurring a dependency on `DocInventories`. A
# dependency on `CodecZlib` is still necessary, as we need to write compressed
# data.


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

function Selectors.runner(::Type{WriteInventory}, doc::Documenter.Document)
    @info "WriteInventory: writing `objects.inv` and `inventory.toml.gz` file."
    write_inventory(doc)
end


function write_inventory(doc::Documenter.Document)

    project = doc.user.sitename
    version = doc.user.version

    if isempty(version)
        @warn "No `version` in `makedocs`. Please pass `version` as a keyword argument."
    end
    i_html = findfirst(fmt -> (fmt isa HTML), doc.user.format)
    if isnothing(i_html)
        @info "Skip writing $(repr(filename)): No HTML output"
        return
    end
    ctx = HTMLContext(doc, doc.user.format[i_html])

    io_inv_header = open(joinpath(doc.user.build, "objects.inv"), "w")
    _io_toml = open(joinpath(doc.user.build, "inventory.toml.gz"), "w")
    io_toml = GzipCompressorStream(_io_toml)

    write(io_toml, "[Inventory]\n")
    write(io_toml, "format = \"DocInventories v0\"\n")
    # TODO: If this gets moved to Documenter, it should be
    #     format = "Documenter Inventory v1"
    TOML.print(io_toml, Dict("project" => project))
    TOML.print(io_toml, Dict("version" => version))
    write(io_toml, "\n")

    write(io_inv_header, "# Sphinx inventory version 2\n")
    write(io_inv_header, "# Project: $project\n")
    write(io_inv_header, "# Version: $version\n")
    write(io_inv_header, "# The remainder of this file is compressed using zlib.\n")
    io_inv = ZlibCompressorStream(io_inv_header)

    domain = "std"
    role = "doc"
    priority = -1
    for navnode in doc.internal.navlist
        name = replace(splitext(navnode.page)[1], "\\" => "/")
        uri = _get_inventory_uri(doc, ctx, navnode)
        dispname = _get_inventory_dispname(doc, ctx, navnode)
        line = "$name $domain:$role $priority $uri $dispname\n"
        write(io_inv, line)
        write(io_toml, "[[$domain.$role]]\n")
        TOML.print(io_toml, Dict("name" => name))
        TOML.print(io_toml, Dict("uri" => uri))
        (dispname != "-") && TOML.print(io_toml, Dict("dispname" => dispname))
    end
    write(io_toml, "\n")

    domain = "std"
    role = "label"
    priority = -1
    for name in keys(doc.internal.headers.map)
        anchor = Documenter.anchor(doc.internal.headers, name)
        if isnothing(anchor)
            # anchor not unique -> exclude from inventory
            continue
        end
        uri = _get_inventory_uri(doc, ctx, name, anchor)
        dispname = _get_inventory_dispname(doc, ctx, name, anchor)
        line = "$name $domain:$role $priority $uri $dispname\n"
        write(io_inv, line)
        write(io_toml, "[[$domain.$role]]\n")
        TOML.print(io_toml, Dict("name" => name))
        TOML.print(io_toml, Dict("uri" => uri))
        (dispname != "-") && TOML.print(io_toml, Dict("dispname" => dispname))
    end
    write(io_toml, "\n")

    domain = "jl"
    priority = 1
    for name in keys(doc.internal.docs.map)
        anchor = Documenter.anchor(doc.internal.docs, name)
        if isnothing(anchor)
            # anchor not unique -> exclude from inventory
            continue
        end
        uri = _get_inventory_uri(doc, ctx, name, anchor)
        role = lowercase(doccat(anchor.object))
        dispname = "-"
        line = "$name $domain:$role $priority $uri $dispname\n"
        write(io_inv, line)
        write(io_toml, "[[$domain.$role]]\n")
        TOML.print(io_toml, Dict("name" => name))
        TOML.print(io_toml, Dict("uri" => uri))
    end

    close(io_inv)
    close(io_inv_header)
    close(io_toml)
    close(_io_toml)

end


function _get_inventory_uri(doc, ctx, name::AbstractString, anchor::Documenter.Anchor)
    filename = relpath(anchor.file, doc.user.build)
    page_url = pretty_url(ctx, get_url(ctx, filename))
    if Sys.iswindows()
        # https://github.com/JuliaDocs/Documenter.jl/issues/2387
        page_url = replace(page_url, "\\" => "/")
    end
    label = escapeuri(Documenter.anchor_label(anchor))
    if label == name
        uri = page_url * raw"#$"
    else
        uri = page_url * "#$label"
    end
    return uri
end


function _get_inventory_uri(doc, ctx, navnode::Documenter.NavNode)
    uri = pretty_url(ctx, get_url(ctx, navnode.page))
    if Sys.iswindows()
        # https://github.com/JuliaDocs/Documenter.jl/issues/2387
        uri = replace(uri, "\\" => "/")
    end
    return uri
end


function _get_inventory_dispname(doc, ctx, name::AbstractString, anchor::Documenter.Anchor)
    dispname = mdflatten(anchor.node)
    if dispname == name
        dispname = "-"
    end
    return dispname
end


function _get_inventory_dispname(doc, ctx, navnode::Documenter.NavNode)
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


@inline _issafe(c::Char) =
    c == '-' || c == '.' || c == '_' || (isascii(c) && (isletter(c) || isnumeric(c)))

_utf8_chars(str::AbstractString) = (Char(c) for c in codeunits(str))

escapeuri(c::Char) = string('%', uppercase(string(Int(c), base=16, pad=2)))
escapeuri(str::AbstractString) =
    join(_issafe(c) ? c : escapeuri(c) for c in _utf8_chars(str))
