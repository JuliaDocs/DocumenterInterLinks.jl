module DocumenterInterLinks

using Documenter: Documenter

export InterLinks, ExternalFallbacks


include("interlinks.jl")
include("expand_extrefs.jl")

if Documenter.DOCUMENTER_VERSION >= v"1.3.0-dev"
    include("fallback.jl")
else
    include("fallback_not_available.jl")
end


function __init__()
    for errname in (:external_cross_references,)
        if !(errname in Documenter.ERROR_NAMES)
            push!(Documenter.ERROR_NAMES, errname)
        end
    end
end

# Ensure that any package loading DocumenterInterLinks also gets the
# inventory-writing backport automatically.
import DocumenterInventoryWritingBackport

end
