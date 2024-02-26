using Documenter: Documenter, Plugin

struct ExternalFallbacks <: Plugin
    mapping::Dict{String,String}
    function ExternalFallbacks(args...; kwargs...)
        @error "The `ExternalFallbacks` plugin is available only in Documenter ≥ v1.3.0" Documenter.DOCUMENTER_VERSION
        mapping = Dict{String,String}()
        new(mapping)
    end
end

function Base.show(io::IO, fallbacks::ExternalFallbacks)
    print(io, "ExternalFallbacks()")
end
