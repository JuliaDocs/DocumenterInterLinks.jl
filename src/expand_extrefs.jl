using Documenter.Builder: DocumentPipeline
using Documenter: Documenter, is_doctest_only
using Markdown: Markdown
using MarkdownAST: MarkdownAST
import Documenter: Selectors

"""Pipeline step to expand all `@extref` cross-references.

This runs before [`Documenter.Builder.CrossReferences`](@extref Documenter).
"""
abstract type ExtCrossReferences <: DocumentPipeline end

Selectors.order(::Type{ExtCrossReferences}) = 2.2  # Before CrossReferences

function Selectors.runner(::Type{ExtCrossReferences}, doc::Documenter.Document)
    is_doctest_only(doc, "ExtCrossReferences") && return
    @info "ExtCrossReferences: building external (DocumenterInterLinks) cross-references."
    expand_extrefs!(doc)
end


function expand_extrefs!(doc::Documenter.Document)
    for (src, page) in doc.blueprint.pages
        #empty!(page.globals.meta) # XXX
        expand_extrefs!(doc, page, page.mdast)
    end
end


function expand_extrefs!(doc::Documenter.Document, page, mdast::MarkdownAST.Node)
    links = Documenter.getplugin(doc, InterLinks)
    replace!(mdast) do node
        if node.element isa Documenter.DocsNode
            # The docstring AST trees are not part of the tree of the page, so
            # we need to expand them explicitly
            for docstr in node.element.mdasts
                expand_extrefs!(doc, page, docstr)
            end
            node
        else
            expand_extref(doc, node, page.source, links)
        end
    end
end


function expand_extref(
    doc::Union{Nothing,Documenter.Document},
    node::MarkdownAST.Node,
    source::String,
    links::InterLinks;
    quiet=false
)
    (node.element isa MarkdownAST.Link) || return node
    startswith(lowercase(node.element.destination), "@extref") || return node
    extref = node.element.destination
    m = match(links.rx, extref)
    if isnothing(m)
        if !quiet
            msg = "On $(repr(source)), invalid @extref $(repr(extref)). Should be \"@extref [[inventory] [[:domain][:role]:]name]\"."
            @error msg node
        end
        if !isnothing(doc)
            push!(doc.internal.errors, :external_cross_references)
        end
        node.element.destination = ""
        # We clear the link destination to remove the link from
        # consideration in Documenter.crossref or the link checker.
        # Otherwise, the external links would error again in those later
        # stages, which is both verbose and confusing.
    else
        if isnothing(m["spec"])
            extref *= " " * _basic_xref_text(node)
        end
        try
            node.element.destination = find_in_interlinks(links, extref)
        catch exc
            if !quiet
                msg = "On $(repr(source)), cannot resolve external link: "
                if exc isa Union{ArgumentError,InventoryItemNotFoundError}
                    msg *= exc.msg
                else
                    msg *= sprint(showerror, exc)
                end
                @error msg node # exception=(exc, catch_backtrace())
            end
            if !isnothing(doc)
                push!(doc.internal.errors, :external_cross_references)
            end
            node.element.destination = ""
        end
    end
    return node
end


# Cf. Documenter.basicxref: We want the conversion of a link text to a "slug"
# to behave the same for @extref as for @ref.
function _basic_xref_text(node)
    @assert node.element isa MarkdownAST.Link
    if length(node.children) == 1 && isa(first(node.children).element, MarkdownAST.Code)
        return first(node.children).element.code
    else
        ast = MarkdownAST.@ast MarkdownAST.Document() do
            MarkdownAST.Paragraph() do
                MarkdownAST.copy_tree(node)
            end
        end
        md = convert(Markdown.MD, ast)
        text =
            strip(sprint(Markdown.plain, Markdown.Paragraph(md.content[1].content[1].text)))
        return Documenter.slugify(text)
    end
end
