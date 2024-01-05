using Test
using TestingUtilities: @Test
using DocInventories
using DocumenterInterLinks
using IOCapture: IOCapture


@testset "valid interlinks" begin

    links = InterLinks(
        "Documenter" => (
            "https://documenter.juliadocs.org/stable/",
            joinpath(@__DIR__, "inventories", "Documenter.toml")
        ),
    )
    if Sys.isunix()
        expected = "InterLinks(\"Documenter\" => Inventory(\"$(@__DIR__)/inventories/Documenter.toml\"; root_url=\"https://documenter.juliadocs.org/stable/\"))"
        @Test repr(links) == expected
        @Test repr("text/plain", links) == repr(links)
    end

    links = InterLinks(
        "Documenter" => (
            "https://documenter.juliadocs.org/stable/",
            joinpath(@__DIR__, "inventories", "Documenter.toml")
        ),
        "Julia" => (
            "https://docs.julialang.org/en/v1/",
            joinpath(@__DIR__, "inventories", "Julia.toml")
        ),
    )

    #!format:off
    expected = """
    InterLinks(
        "Documenter" => Inventory("$(@__DIR__)/inventories/Documenter.toml"; root_url="https://documenter.juliadocs.org/stable/"),
        "Julia" => Inventory("$(@__DIR__)/inventories/Julia.toml"; root_url="https://docs.julialang.org/en/v1/"),
    )
    """
    #!format:on
    if Sys.isunix()
        @Test repr("text/plain", links) == chop(expected)
    end

    links = InterLinks(
        "Documenter" => [  # vector instead of tuple
            "https://documenter.juliadocs.org/stable/",
            joinpath(@__DIR__, "inventories", "Documenter.toml")
        ],
        "Julia" => [
            "https://docs.julialang.org/en/v1/",
            joinpath(@__DIR__, "inventories", "Julia.toml")
        ],
    )
    if Sys.isunix()
        @Test repr("text/plain", links) == chop(expected)
    end

    expected = "InterLinks(\"Documenter\" => Inventory(\"$(@__DIR__)/inventories/Documenter.toml\"; root_url=\"https://documenter.juliadocs.org/stable/\"), \"Julia\" => Inventory(\"$(@__DIR__)/inventories/Julia.toml\"; root_url=\"https://docs.julialang.org/en/v1/\"))"
    if Sys.isunix()
        @Test repr(links) == expected
    end

    c = IOCapture.capture(rethrow=Union{}) do
        InterLinks(
            "Documenter" => (
                "https://documenter.juliadocs.org/stable/",
                "https://documenter.juliadocs.org/stable/noexist.toml",
                joinpath(@__DIR__, "inventories", "Documenter.toml")
            ),
            "Julia" => (
                "https://docs.julialang.org/en/v1/",
                joinpath(@__DIR__, "inventories", "Julia.toml"),
                joinpath(@__DIR__, "inventories", "Julia110.toml")
            ),
            "matplotlib" => "https://matplotlib.org/stable/objects.inv",
        )
    end
    links = c.value
    @test links isa InterLinks
    @test eltype(collect(values(links))) == Inventory
    msg = "Warning: Failed to load inventory \"Documenter\" from possible source \"https://documenter.juliadocs.org/stable/noexist.toml\""
    @test contains(c.output, msg)
    @test links["Documenter"] isa Inventory
    @test links["Julia"] isa Inventory
    msg = "Could not load inventory \"matplotlib\" from any available sources"
    if contains(c.output, msg)
        @warn "Cannot access matplotlib inventory over network:\n$(c.output)"
    else
        @test links["matplotlib"] isa Inventory
        #!format:off
        expected = """
        InterLinks(
            "Documenter" => Inventory("$(@__DIR__)/inventories/Documenter.toml"; root_url="https://documenter.juliadocs.org/stable/"),
            "Julia" => Inventory("$(@__DIR__)/inventories/Julia.toml"; root_url="https://docs.julialang.org/en/v1/"),
            "matplotlib" => Inventory("https://matplotlib.org/stable/objects.inv"),
        )
        """
        #!format:on
        if Sys.isunix()
            @Test repr("text/plain", links) == chop(expected)
        end
    end

end


@testset "invalid interlinks" begin

    c = IOCapture.capture(rethrow=Union{}) do
        links = InterLinks(
            "Documenter" => (
                "https://documenter.juliadocs.org/stable/",
                "noexist1.toml",
                "noexist2.toml",
            ),
        )
    end
    msg = "Error: Could not load inventory \"Documenter\" from any available sources."
    @test contains(c.output, msg)
    msg = "Error: No inventories loaded in InterLinks"
    @test contains(c.output, msg)

    c = IOCapture.capture(rethrow=Union{}) do
        links = InterLinks("Documenter" => Inventory(project="Documenter"))
    end
    msg = "Error: Invalid inventory for \"Documenter\""
    @test contains(c.output, msg)
    msg = "Inventory has empty `root_url`"
    @test contains(c.output, msg)

    c = IOCapture.capture(rethrow=Union{}) do
        links = InterLinks("Documenter" => Inventory(project="Documenter", root_url="x"))
    end
    msg = "Error: Invalid inventory for \"Documenter\""
    @test contains(c.output, msg)
    msg = "Inventory has an invalid `root_url=\"x\"`"
    @test contains(c.output, msg)

    c = IOCapture.capture(rethrow=Union{}) do
        InterLinks(
            "Documenter" =>
                Inventory(project="Documenter", root_url="http://documenter.com")
        )
    end
    msg = "Inventory has an invalid `root_url=\"http://documenter.com\"`: must end with \"/\""
    @test contains(c.output, msg)

    c = IOCapture.capture(rethrow=Union{}) do
        InterLinks(
            "Online Docs" => (
                "https://documenter.juliadocs.org/stable/",
                joinpath(@__DIR__, "inventories", "Documenter.toml")
            ),
        )
    end
    @test c.value isa ArgumentError
    if c.value isa ArgumentError
        @test contains(c.value.msg, "must be an alphanumeric ASCII string")
    end

    c = IOCapture.capture(rethrow=Union{}) do
        InterLinks(
            ["Julia"],
            Dict(
                "Documenter" => Inventory(
                    project="Documenter",
                    root_url="https://documenter.juliadocs.org/stable/"
                )
            )
        )
    end
    @test c.value isa ArgumentError
    if c.value isa ArgumentError
        @test contains(c.value.msg, "Project \"Julia\" not found in inventories")
    end

    c = IOCapture.capture(rethrow=Union{}) do
        links = InterLinks(
            "docinventories" => (
                "https://juliadocs.org/DocInventories.jl/stable/",
                joinpath(@__DIR__, "inventories", "DocInventories.toml")
            ),
        )
    end
    msg = "Warning: The inventory for project \"docinventories\" mostly contains docstrings for `DocInventories.*` and should probably be named \"DocInventories\""
    @test contains(c.output, msg)

end


@testset "search in interlinks" begin

    links = InterLinks(
        "Documenter" => (
            "https://documenter.juliadocs.org/stable/",
            joinpath(@__DIR__, "inventories", "Documenter.toml")
        ),
        "Julia" => (
            "https://docs.julialang.org/en/v1/",
            joinpath(@__DIR__, "inventories", "Julia.toml")
        ),
    )

    search = links(":doc:`index`")
    @test search ==
          ["@extref Documenter :std:doc:`index`", "@extref Julia :std:doc:`index`",]

end
