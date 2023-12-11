using Test
using SafeTestsets

# Note: comment outer @testset to stop after first @safetestset failure
@time @testset verbose = true "DocumenterInterLinks" begin

    @test true
    #=
    println("\n* read inventory (test_read_inventory.jl):")
    @time @safetestset "read inventory" begin
        include("test_read_inventory.jl")
    end
    =#

end

nothing  # avoid noise when doing `include("test/runtests.jl")`
