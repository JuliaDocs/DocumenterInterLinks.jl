using Documenter.Builder: DocumentPipeline
using Documenter.HTMLWriter: HTML, HTMLContext, get_url, pretty_url, getpage, pagetitle
using Documenter.MDFlatten: mdflatten
using Documenter: Documenter, anchor_fragment, doccat
import Documenter: Selectors
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
    if isdefined(Documenter.HTMLWriter, :write_inventory)
        @debug "Skip writing inventories in DocumenterInterLinks: handled by Documenter"
    else
        @info "WriteInventory: writing `objects.inv` and `inventory.toml.gz` file."
        write_inventory(doc)
    end
end


function write_inventory(doc::Documenter.Document)

    project = doc.user.sitename
    version = doc.user.version

    if isempty(version)
        @warn "No `version` in `makedocs`. Please pass `version` as a keyword argument."
    else
        @warn "Thank you for providing a `version` in `makedocs`! Currently, there is a bug in Documenter (#2385) that prevents the version selection menu from working properly if `version` is specified. So, until #2389 is merged, you may want to comment out the `version`."
    end
    # TODO: If this gets moved to Documenter, this function should be called
    # at the end of the HTML Writer and we wouldn't need to check for HTML
    # output here, or construct a dummy `ctx`.
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
    #     format = "Documenter inventory version 1"
    _write_toml_val(io_toml, "project", project)
    _write_toml_val(io_toml, "version", version)
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
        _write_toml_val(io_toml, "name", name)
        _write_toml_val(io_toml, "uri", uri)
        (dispname != "-") && _write_toml_val(io_toml, "dispname", dispname)
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
        _write_toml_val(io_toml, "name", name)
        _write_toml_val(io_toml, "uri", uri)
        (dispname != "-") && _write_toml_val(io_toml, "dispname", dispname)
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
        _write_toml_val(io_toml, "name", name)
        _write_toml_val(io_toml, "uri", uri)
    end

    close(io_inv)
    close(io_inv_header)
    close(io_toml)
    close(_io_toml)

end


function _write_toml_val(io::IO, name::AbstractString, value::AbstractString)
    # Cf. TOML.Internals.Printer.print_toml_escaped, but that's way too
    # internal to just use.
    write(io, name)
    write(io, " = \"")
    for c::AbstractChar in value
        if !isvalid(c)
            msg = "Invalid character $(repr(c)) encountered while writing TOML"
            throw(ArgumentError(msg))
        end
        if c == '\b'
            print(io, '\\', 'b')
        elseif c == '\t'
            print(io, '\\', 't')
        elseif c == '\n'
            print(io, '\\', 'n')
        elseif c == '\f'
            print(io, '\\', 'f')
        elseif c == '\r'
            print(io, '\\', 'r')
        elseif c == '"'
            print(io, '\\', '"')
        elseif c == '\\'
            print(io, "\\", '\\')
        elseif iscntrl(c)
            print(io, "\\u")
            print(io, string(UInt32(c), base=16, pad=4))
        else
            print(io, c)
        end
    end
    write(io, "\"\n")
end


function _write_toml_val(io::IO, name::AbstractString, value::Int64)
    write(io, name, " = ", value, "\n")
end


function _get_inventory_uri(doc, ctx, name::AbstractString, anchor::Documenter.Anchor)
    filename = relpath(anchor.file, doc.user.build)
    page_url = pretty_url(ctx, get_url(ctx, filename))
    if Sys.iswindows()
        # https://github.com/JuliaDocs/Documenter.jl/issues/2387
        page_url = replace(page_url, "\\" => "/")
    end
    label = _escapeuri(Documenter.anchor_label(anchor))
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

_escapeuri(c::Char) = string('%', uppercase(string(Int(c), base=16, pad=2)))
_escapeuri(str::AbstractString) =
    join(_issafe(c) ? c : _escapeuri(c) for c in _utf8_chars(str))
