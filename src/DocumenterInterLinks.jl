module DocumenterInterLinks

using Documenter: Documenter

export InterLinks, ExternalFallbacks


include("interlinks.jl")
include("expand_extrefs.jl")
include("fallback.jl")

function __init__()
    for errname in (:external_cross_references,)
        if !(errname in Documenter.ERROR_NAMES)
            push!(Documenter.ERROR_NAMES, errname)
        end
    end
end

end
