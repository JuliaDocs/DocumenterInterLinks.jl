using Test
using TestingUtilities: @Test
using DocumenterInterLinks
using Logging
using Markdown
using MarkdownAST
using DocInventories
using IOCapture: IOCapture


function parse_md_link(text)
    mdpage = Markdown.parse(text)
    paragraph = first(convert(MarkdownAST.Node, mdpage).children)
    if length(paragraph.children) != 1
        @error "citation $(repr(text)) must parse into a single MarkdownAST.Link" ast =
            collect(paragraph.children)
        error("Invalid citation: $(repr(text))")
    end
    link = first(paragraph.children)
    if !(link.element isa MarkdownAST.Link)
        @error "citation $(repr(text)) must parse into MarkdownAST.Link" ast = link
        error("Invalid citation: $(repr(text))")
    end
    return link
end


function ast_to_str(node::MarkdownAST.Node)
    if node.element isa MarkdownAST.Document
        document = node
    elseif node.element isa MarkdownAST.AbstractBlock
        document = MarkdownAST.@ast MarkdownAST.Document() do
            MarkdownAST.copy_tree(node)
        end
    else
        @assert node.element isa MarkdownAST.AbstractInline
        document = MarkdownAST.@ast MarkdownAST.Document() do
            MarkdownAST.Paragraph() do
                MarkdownAST.copy_tree(node)
            end
        end
    end
    text = Markdown.plain(convert(Markdown.MD, document))
    return strip(text)
end


function _expand_extref(text, links; quiet=false)
    link = parse_md_link(text)
    node = DocumenterInterLinks.expand_extref(nothing, link, "string", links; quiet=quiet)
    return ast_to_str(node)
end


@testset "expand in Julia inventory" begin

    links = InterLinks(
        "Documenter" => Inventory(
            joinpath(@__DIR__, "inventories", "Documenter.toml");
            root_url="https://documenter.juliadocs.org/stable/"
        ),
        "Julia" => Inventory(
            joinpath(@__DIR__, "inventories", "Julia.toml");
            root_url="https://docs.julialang.org/en/v1/"
        ),
    )

    push_url = "https://docs.julialang.org/en/v1/base/collections/#Base.push%21"

    text = "[`Base.push!`](@extref)"
    result = _expand_extref(text, links)
    @Test result == "[`Base.push!`]($push_url)"

    text = "[`Base.push!`](@extref Julia)"
    result = _expand_extref(text, links)
    @Test result == "[`Base.push!`]($push_url)"

    text = "[`push!`](@extref Base.push!)"
    result = _expand_extref(text, links)
    @Test result == "[`push!`]($push_url)"

    text = "[`push!`](@extref `Base.push!`)"
    result = _expand_extref(text, links)
    @Test result == "[`push!`]($push_url)"

    text = "[`push!`](@extref Julia Base.push!)"
    result = _expand_extref(text, links)
    @Test result == "[`push!`]($push_url)"

    text = "[`push!`](@extref Julia `Base.push!`)"
    result = _expand_extref(text, links)
    @Test result == "[`push!`]($push_url)"

    text = "[`push!`](@extref Julia :function:Base.push!)"
    result = _expand_extref(text, links)
    @Test result == "[`push!`]($push_url)"

    text = "[`push!`](@extref Julia :function:`Base.push!`)"
    result = _expand_extref(text, links)
    @Test result == "[`push!`]($push_url)"

    text = "[`push!`](@extref Julia :jl:function:Base.push!)"
    result = _expand_extref(text, links)
    @Test result == "[`push!`]($push_url)"

    text = "[the `push!` function](@extref Julia :jl:function:Base.push!)"
    result = _expand_extref(text, links)
    @Test result == "[the `push!` function]($push_url)"

    ceil_url = "https://docs.julialang.org/en/v1/stdlib/Dates/#Base.ceil-Tuple%7BUnion%7BDay%2C%20Week%2C%20TimePeriod%7D%2C%20Union%7BDay%2C%20Week%2C%20TimePeriod%7D%7D"

    text = "[`Base.ceil-Tuple{Union{Day, Week, TimePeriod}, Union{Day, Week, TimePeriod}}`](@extref)"
    result = _expand_extref(text, links)
    expected = "[`Base.ceil-Tuple{Union{Day, Week, TimePeriod}, Union{Day, Week, TimePeriod}}`]($ceil_url)"
    @Test result == expected

    text = "[ceiling function](@extref Base.ceil-Tuple{Union{Day, Week, TimePeriod}, Union{Day, Week, TimePeriod}})"
    result = _expand_extref(text, links)
    expected = "[ceiling function]($ceil_url)"
    @Test result == expected

    text = "[ceiling function](@extref :method:`Base.ceil-Tuple{Union{Day, Week, TimePeriod}, Union{Day, Week, TimePeriod}}`)"
    result = _expand_extref(text, links)
    expected = "[ceiling function]($ceil_url)"
    @Test result == expected

    text = "[ceiling function](@extref :function:`Base.ceil-Tuple{Union{Day, Week, TimePeriod}, Union{Day, Week, TimePeriod}}`)"
    c = IOCapture.capture() do
        _expand_extref(text, links)
    end
    @test c.value == "[ceiling function]()"
    @test contains(c.output, "cannot resolve external link")


    globals_url = "https://docs.julialang.org/en/v1/manual/calling-c-and-fortran-code/#Accessing-Global-Variables"

    text = "[Accessing Global Variables](@extref)"
    result = _expand_extref(text, links)
    expected = "[Accessing Global Variables]($globals_url)"
    @Test result == expected

    text = "[Accessing Global Variables](@extref Julia)"
    result = _expand_extref(text, links)
    expected = "[Accessing Global Variables]($globals_url)"
    @Test result == expected

    text = "[how to access global variables](@extref Julia Accessing-Global-Variables)"
    result = _expand_extref(text, links)
    expected = "[how to access global variables]($globals_url)"
    @Test result == expected

    text = "[how to access global variables](@extref Julia `Accessing-Global-Variables`)"
    result = _expand_extref(text, links)
    expected = "[how to access global variables]($globals_url)"
    @Test result == expected

    text = "[how to access global variables](@extref Julia :label:`Accessing-Global-Variables`)"
    result = _expand_extref(text, links)
    expected = "[how to access global variables]($globals_url)"
    @Test result == expected

    text = "[how to access global variables](@extref Julia :std:label:`Accessing-Global-Variables`)"
    result = _expand_extref(text, links)
    expected = "[how to access global variables]($globals_url)"
    @Test result == expected

    text = "[how to access global variables](@extref Julia \"Accessing-Global-Variables\")"
    c = IOCapture.capture() do
        result = _expand_extref(text, links)
    end
    @Test result == "[how to access global variables]()"
    @test contains(c.output, "cannot resolve external link")

    text = "[how to access global variables](@extref Julia Accessing Global Variables)"
    c = IOCapture.capture() do
        result = _expand_extref(text, links)
    end
    @Test result == "[how to access global variables]()"
    @test contains(c.output, "cannot resolve external link")

end


@testset "find in Python inventory" begin

    c = IOCapture.capture() do
        InterLinks(
            "matplotlib" => (
                "https://matplotlib.org/stable",
                joinpath(@__DIR__, "inventories", "matplotlib.inv")
            ),
            "python" => (
                "https://docs.python.org/3/",
                joinpath(@__DIR__, "inventories", "python.inv"),
                joinpath(@__DIR__, "inventories", "python312.inv")
            ),
        )
    end
    @test contains(c.output, "Failed to load inventory \"python\" from possible source")
    links = c.value

    zip_func_url = "https://docs.python.org/3/library/functions.html#zip"
    zip_2to3_url = "https://docs.python.org/3/library/2to3.html#to3fixer-zip"

    text = "[`zip`](@extref)"
    result = _expand_extref(text, links)
    @Test result == "[`zip`]($zip_func_url)"

    text = "[`zip`](@extref :2to3fixer:`zip`)"
    result = _expand_extref(text, links)
    @Test result == "[`zip`]($zip_2to3_url)"

    text = "[`zip`](@extref python)"
    result = _expand_extref(text, links)
    @Test result == "[`zip`]($zip_func_url)"

    text = "[`zip`](@extref python zip)"
    result = _expand_extref(text, links)
    @Test result == "[`zip`]($zip_func_url)"

    text = "[`zip`](@extref python `zip`)"
    result = _expand_extref(text, links)
    @Test result == "[`zip`]($zip_func_url)"

    text = "[`zip`](@extref :py:function:`zip`)"
    result = _expand_extref(text, links)
    @Test result == "[`zip`]($zip_func_url)"

    ppmp_url = "https://matplotlib.org/stableusers/installing/environment_variables_faq.html#envvar-PYTHONPATH"
    ppp_url = "https://docs.python.org/3/using/cmdline.html#envvar-PYTHONPATH"

    text = "[`PYTHONPATH`](@extref)"
    result = _expand_extref(text, links)
    @Test result == "[`PYTHONPATH`]($ppmp_url)"

    text = "[`PYTHONPATH`](@extref matplotlib)"
    result = _expand_extref(text, links)
    @Test result == "[`PYTHONPATH`]($ppmp_url)"

    text = "[`PYTHONPATH`](@extref python)"
    result = _expand_extref(text, links)
    @Test result == "[`PYTHONPATH`]($ppp_url)"

    text = "[the `PYTHONPATH` env var](@extref python PYTHONPATH)"
    result = _expand_extref(text, links)
    @Test result == "[the `PYTHONPATH` env var]($ppp_url)"

    text = "[the `PYTHONPATH` env var](@extref python :envvar:`PYTHONPATH`)"
    result = _expand_extref(text, links)
    @Test result == "[the `PYTHONPATH` env var]($ppp_url)"

end


@testset "short-circuit resolution" begin

    links = InterLinks(
        "Documenter" => Inventory(
            joinpath(@__DIR__, "inventories", "Documenter.toml");
            root_url="https://documenter.juliadocs.org/stable/"
        ),
        "Julia" => Inventory(
            joinpath(@__DIR__, "inventories", "Julia.toml");
            root_url="https://docs.julialang.org/en/v1/"
        ),
    )

    text = "[`Documenter.makedocs`](@extref)"
    c = IOCapture.capture() do
        with_logger(ConsoleLogger(stdout, Logging.Debug)) do
            _expand_extref(text, links)
        end
    end
    @test contains(c.output, "Debug: Trying short-circuit resolution")
    @test !contains(c.output, "Debug: Looking in *all* inventories")
    @test contains(c.value, "#Documenter.makedocs")

    text = "[The `makedocs` function](@extref `Documenter.makedocs`)"
    c = IOCapture.capture() do
        with_logger(ConsoleLogger(stdout, Logging.Debug)) do
            _expand_extref(text, links)
        end
    end
    @test contains(c.output, "Debug: Trying short-circuit resolution")
    @test !contains(c.output, "Debug: Looking in *all* inventories")
    @test contains(c.value, "#Documenter.makedocs")

    text = "[The `makedocs` function](@extref :function:`Documenter.makedocs`)"
    c = IOCapture.capture() do
        with_logger(ConsoleLogger(stdout, Logging.Debug)) do
            _expand_extref(text, links)
        end
    end
    @test contains(c.output, "Debug: Trying short-circuit resolution")
    @test contains(c.value, "#Documenter.makedocs")

    text = "[The `makedocs` function](@extref :jl:function:`Documenter.makedocs`)"
    c = IOCapture.capture() do
        with_logger(ConsoleLogger(stdout, Logging.Debug)) do
            _expand_extref(text, links)
        end
    end
    @test contains(c.output, "Debug: Trying short-circuit resolution")
    @test contains(c.value, "#Documenter.makedocs")

    # The shortcircuit logic even works without backticks

    text = "[The `makedocs` function](@extref Documenter.makedocs)"
    c = IOCapture.capture() do
        with_logger(ConsoleLogger(stdout, Logging.Debug)) do
            _expand_extref(text, links)
        end
    end
    @test contains(c.output, "Debug: Trying short-circuit resolution")
    @test contains(c.value, "#Documenter.makedocs")

    # For Base, short-circuit will fail, because it's in the Julia project

    text = "[`Base.sort`](@extref)"
    c = IOCapture.capture() do
        with_logger(ConsoleLogger(stdout, Logging.Debug)) do
            _expand_extref(text, links)
        end
    end
    @test contains(c.output, "Debug: Trying short-circuit resolution")
    @test contains(c.output, "Debug: Failed short-circuit resolution")
    @test contains(c.output, "KeyError: key \"Base\" not found")
    @test contains(c.output, "Debug: Looking in *all* inventories")
    @test contains(c.value, "#Base.sort")

    # This is how Base should be referenced:

    text = "[`Base.sort`](@extref Julia)"
    c = IOCapture.capture() do
        with_logger(ConsoleLogger(stdout, Logging.Debug)) do
            _expand_extref(text, links)
        end
    end
    @test !contains(c.output, "Debug: Trying short-circuit resolution")
    @test !contains(c.output, "Debug: Looking in *all* inventories")
    @test contains(c.value, "#Base.sort")

end


@testset "invalid extrefs" begin

    links = InterLinks()

    text = "[`Base.push!`](@extref)"
    c = IOCapture.capture() do
        _expand_extref(text, links)
    end
    @test c.value == "[`Base.push!`]()"
    @test contains(c.output, "cannot resolve external link")

    text = "[`Base.push!`](@extref Julia)"
    c = IOCapture.capture() do
        _expand_extref(text, links)
    end
    @test c.value == "[`Base.push!`]()"
    @test contains(c.output, "cannot resolve external link")
    @test contains(c.output, "Cannot find \"Julia\" in any InterLinks inventory")

    text = "[The `push!` function](@extref Julia `Base.push!`)"
    c = IOCapture.capture() do
        _expand_extref(text, links)
    end
    @test c.value == "[The `push!` function]()"
    @test contains(c.output, "cannot resolve external link")
    @test contains(
        c.output,
        "Cannot find \"Julia `Base.push!`\" in any InterLinks inventory"
    )

    links = InterLinks(
        "Julia" => Inventory(
            joinpath(@__DIR__, "inventories", "Julia.toml");
            root_url="https://docs.julialang.org/en/v1/"
        ),
    )

    text = "[`Base.push!`](@extrefJulia)"
    c = IOCapture.capture() do
        _expand_extref(text, links)
    end
    @test c.value == "[`Base.push!`]()"
    @test contains(c.output, "invalid @extref \"@extrefJulia\"")

    text = "[](@extref)"
    c = IOCapture.capture() do
        _expand_extref(text, links)
    end
    msg = "cannot resolve external link: Invalid query \"@extref \""
    @test contains(c.output, msg)

    text = "[release notes](@extref Julia doc:`NEWS`)"
    c = IOCapture.capture() do
        _expand_extref(text, links)
    end
    msg = "Did you forget a leading colon in \"doc:`NEWS`\"?"
    @test contains(c.output, msg)

end
