# Source this script as e.g.
#
#     include("PATH/TO/devrepl.jl")
#
# from *any* Julia REPL or run it as e.g.
#
#     julia -i --banner=no PATH/TO/devrepl.jl
#
# from anywhere. This will change the current working directory and
# activate/initialize the correct Julia environment for you.
#
# You may also run this in vscode to initialize a development REPL
#
using Pkg
Pkg.activate("test")

function _instantiate()
    path = joinpath("..", "DocumenterInventoryWritingBackport.jl")
    if isdir(path)
        Pkg.develop(path=path)
    else
        Pkg.add(url="https://github.com/JuliaDocs/DocumenterInventoryWritingBackport.jl")
    end
    path = joinpath("..", "DocInventories.jl")
    if isdir(path)
        Pkg.develop(path=path)
    end
    Pkg.develop(path=".")
end

if !isfile(joinpath("test", "Manifest.toml"))
    _instantiate()
end
include("test/init.jl")

# Disable link-checking in interactive REPL, since it is the slowest part
# of building the docs.
ENV["DOCUMENTER_CHECK_LINKS"] = "0"

if abspath(PROGRAM_FILE) == @__FILE__
    help()
end
