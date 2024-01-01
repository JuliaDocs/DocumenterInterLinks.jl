using Test
using SafeTestsets
using DocumenterInterLinks


# Note: comment outer @testset to stop after first @safetestset failure
@time @testset verbose = true "DocumenterInterLinks" begin

    println("\n* instantiate interlinks (test_interlinks.jl):")
    @time @safetestset "expand extrefs" begin
        include("test_interlinks.jl")
    end

    println("\n* expand extrefs (test_expand_extrefs.jl):")
    @time @safetestset "expand extrefs" begin
        include("test_expand_extrefs.jl")
    end

    println("\n* integration test (test_integration.jl):")
    @time @safetestset "integration" begin
        include("test_integration.jl")
    end

end

nothing  # avoid noise when doing `include("test/runtests.jl")`
