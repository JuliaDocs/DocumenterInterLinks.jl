using Documenter: Plugin
using DocInventories: Inventory, InventoryItem, uri, spec, split_url, search_in_inventory


"""
Plugin for enabling external links in `Documenter.jl.`

```julia
links = InterLinks(
    "project1" => "https://project1.url/",
    "project2" => "https://project2.url/inventory.file",
    "project3" => (
        "https://project3.url/",
        joinpath(@__DIR__, "src", "interlinks", "inventory.file")
    );
    default_inventory_file="objects.inv",
    alias_methods_as_function=true,
)
```

instantiates a plugin object that must be passed as an element of the `plugins`
keyword argument to [`Documenter.makedocs`](@extref). This then
enables `@extref` links in the project's documentation to be resolved, see the
Documentation for details.

# Arguments

The `InterLinks` plugin receives mappings of project names to the project root
URL and inventory locations. Each project names must be an alphanumerical ASCII
string. For Julia projects, it should be the name of the package without the
`.jl` suffix, e.g., `"Documenter"` for
[Documenter.jl](https://documenter.juliadocs.org/). For Python projects, it
should be the name of project's main module.

The root url / inventory location (the value of the mapping), can be given in
any of the following forms:

* A single string with a URL of the inventory file, e.g.

  ```
  "sphinx" => "https://www.sphinx-doc.org/en/master/objects.inv"
  ````

  The root URL relative which all URIs inside the inventory are taken to be
  relative is everything up to the final slash in the inventory URL,
  `"https://www.sphinx-doc.org/en/master/"` in this case.

* A single string with a project root URL, for example,

  ```
  "sphinx" => "https://www.sphinx-doc.org/en/master/",
  ````

  which must end with slash. This looks for the inventory file with the name
  corresponding to `default_inventory_file` directly underneath the given root
  URL.

* A tuple of strings, where the first element is the project root URL and all
  subsequent elements are locations (URLs or local file paths) to an inventory
  file, e.g.,

  ```
  "Julia" => (
      "https://docs.julialang.org/en/v1/",
      joinpath(@__DIR__, "src", "interlinks", "Julia.toml")
  ),
  "Documenter" => (
      "https://documenter.juliadocs.org/stable/",
      "https://documenter.juliadocs.org/stable/inventory.toml.gz",
      joinpath(@__DIR__, "src", "interlinks", "Documenter.toml")
  )
  ```

  The first reachable inventory file will be used. This enables, e.g., to
  define a local inventory file as a fallback in case the online inventory file
  location is unreachable, as in the last example.

* A [`DocInventories.Inventory`](@extref) instance.

# Keyword arguments

* `default_inventory_file`: The file name for the inventory file to use if the
  "inventory location" is given as the root URL. Since both Sphinx and
  Documenter automatically write `objects.inv`, there is little conceivable
  reason to set this to something other than the default `objects.inv`.
* `alias_methods_as_function`: If `true` (default), for any inventory loaded
  from a file or URL, automatically add a `:jl:function:` alias for any
  `:jl:method` if that alias is unambiguous. This accounts for Documenter
  preferentially generating method-docstrings from `@autodoc` blocks, even if
  that method is the only method for the underlying function. For example, the
  [`Documenter.Selectors.dispatch`](@extref) function only has a
  method-docstring that would have to be referenced as the excessively long

  ```
  [`Documenter.Selectors.dispatch`](@extref `Documenter.Selectors.dispatch-Union{Tuple{T}, Tuple{Type{T}, Vararg{Any}}} where T<:Documenter.Selectors.AbstractSelector`)
  ```

  With the alias, this can be shortened to
  ```[`Documenter.Selectors.dispatch`](@extref)```. No alias will be created
  if there are docstrings for multiple methods of the same function, or if
  there is an existing function docstring.

# Properties

* `names`: A list of project names
* `inventories`: A dictionary of project names to
  [`DocInventories.Inventory`](@extref) instances
* `rx`: a [`Regex`](@extref Julia Base.Regex) that matches any valid `@extref`
  expression that can be resolved.

The `InterLinks` object also acts as a (read-only) ordered dictionary so that,
e.g., `links["project1"]` returns the [`DocInventories.Inventory`](@extref) for
that project.

# Search

Free-form search in a particular inventory is possible with, e.g.,

```julia
links["Julia"](search)
```

See the discussion on search in the [`DocInventories.Inventory`](@extref)
documentation. Such a search returns a list of matching
[`DocInventories.InventoryItem`](@extref) instances.

In addition,

```
links(search)
```

allows to search across *all* inventories. This returns a list of `@extref`
strings that could be used to reference the matching items.

# Methods

* [`find_in_interlinks(links, extref)`](@ref) – find the URL for an `extref`

# See also

The `InterLinks` mapping is deliberately reminiscent of the
[`intersphinx_mapping`](@extref sphinx) setting in
[Sphinx](@extref sphinx :doc:`index`).
"""
struct InterLinks <: Plugin
    names::Vector{String}
    inventories::Dict{String,Inventory}  # name => inventory
    rx::Regex

    function InterLinks(names::Vector{String}, inventories::Dict{String,Inventory})
        for project in names
            if isnothing(match(r"^[A-Za-z0-9]+$", project))
                msg = "Project $(repr(project)) is invalid: must be an alphanumeric ASCII string"
                throw(ArgumentError(msg))
            end
            if !haskey(inventories, project)
                msg = "Project $(repr(project)) not found in inventories"
                throw(ArgumentError(msg))
            end
            _check_project_name(project, inventories[project])
        end
        rx_project = "(?<project>" * join(names, "|") * ")"
        rx_spec = raw"(:((?<domain>\w+):)?((?<role>\w+):)?)?(?<name>.+)"
        # Cf. DocInventories._rx_domain_role_name
        rx = "^@extref\\s*( $rx_project\\s*)?( (?<spec>$rx_spec))?\\s*\$"
        new(names, inventories, Regex(rx))
    end
end


function _check_project_name(project, inventory)
    # We count how many times each package / module is referenced in the
    # inventory. If there's one that's referenced 90% of the time,
    # that should be the project name for maximum efficiency, see
    # https://juliadocs.org/DocumenterInterLinks.jl/dev/syntax/#Performance-Tips
    counts = Dict{String,Int64}()
    for item in inventory
        (item.domain == "std") && continue
        m = match(r"^(\w+)\.", item.name)
        # Cf. the short-circuiting syntax rules
        if !isnothing(m)
            mod = m.captures[1]
            counts[mod] = (mod in keys(counts)) ? counts[mod] + 1 : 1
        end
    end
    if !isempty(counts)
        N = float(sum(values(counts)))
        mod = argmax(counts)
        if (counts[mod] > 5) && ((counts[mod] / N) > 0.9)
            # 90% should be a sufficiently high bar to justify a warning
            if project != mod
                msg = "The inventory for project $(repr(project)) mostly contains docstrings for `$mod.*` and should probably be named $(repr(mod))"
                @warn msg
            end
        end
    end
end



function InterLinks(
    mapping...;
    default_inventory_file="objects.inv",
    alias_methods_as_function=true
)
    names = String[]
    inventories_list = Inventory[]
    try
        for (project, spec) in mapping
            if spec isa AbstractString  # -> convert to tuple
                if endswith(spec, "/")
                    spec = (spec, spec * default_inventory_file)
                else
                    root_url = split_url(spec)[1]
                    spec = (root_url, spec)
                end
            end
            inventory = nothing
            sources = []
            if spec isa Inventory
                try
                    inventory = _validate_inventory(spec)
                catch exc
                    @error "Invalid inventory for $(repr(project))." exception = exc
                    continue  # next project
                end
            else  # assume Tuple
                root_url = spec[begin]
                sources = spec[begin+1:end]
                for source in sources
                    try
                        inventory = Inventory(source; root_url=root_url)
                        @debug "Successfully loaded inventory $(repr(project)) from source $(repr(source))."
                        if alias_methods_as_function
                            _set_method_aliases!(inventory)
                        end
                        break  # stop after first successful source
                    catch exception
                        msg = "Failed to load inventory $(repr(project)) from possible source $(repr(source))."
                        @warn msg exception
                    end
                end
            end
            if isnothing(inventory)
                @error "Could not load inventory $(repr(project)) from any available sources." sources
            else
                push!(inventories_list, inventory)
                push!(names, project)
            end
        end
    catch exc
        @error "Invalid InterLinks specification" exception = (exc, catch_backtrace())
    end
    N = length(names)
    if (length(mapping) > 0) && (N == 0)
        @error "No inventories loaded in InterLinks"
    end
    @assert length(inventories_list) == N
    inventories_dict = Dict(names[i] => inventories_list[i] for i = 1:N)
    return InterLinks(names, inventories_dict)
end


Base.iterate(links::InterLinks, state=1) =
    if state > length(links.names)
        nothing
    else
        (links.names[state], links.inventories[links.names[state]]) => state + 1
    end

Base.length(links::InterLinks) = length(links.names)

Base.getindex(links::InterLinks, key) = links.inventories[key]

Base.keys(links::InterLinks) = links.names

Base.values(links::InterLinks) = map(name -> links.inventories[name], links.names)


struct InventoryItemNotFoundError <: Exception
    msg::String
end


function (links::InterLinks)(search)
    results = String[]
    for (name, inventory) in links
        for item in inventory(search)
            push!(results, "@extref $name $(spec(item))")
        end
    end
    return results
end


function _set_method_aliases!(inventory)
    aliases = Dict{String,Vector{String}}()
    for method_item in search_in_inventory(inventory, ":jl:method:`")
        func_name = replace(method_item.name, r"-.*$" => "")
        if haskey(aliases, func_name)
            push!(aliases[func_name], spec(method_item))
        else
            aliases[func_name] = [spec(method_item)]
        end
    end
    for (func_name, method_specs) in aliases
        func_spec = ":jl:function:`$func_name`"
        if length(method_specs) == 1
            method_spec = method_specs[1]
            if isnothing(inventory[func_spec])
                @debug "Setting alias $method_spec -> $func_spec"
                push!(inventory, InventoryItem(func_spec => uri(inventory[method_spec])))
            else
                @debug "Not setting alias $method_spec -> $func_spec: function entry already exists"
            end
        else
            @debug "Not setting alias to $func_spec: ambiguous" method_specs
        end
    end
    return inventory
end


"""Find an `@extref` link in any of the [`InterLinks`](@ref) inventories.

```julia
url = find_in_interlinks(links, extref)
```

finds `extref` in `links` and returns the full URL that resolves the link.

# Arguments

* `links`: the [`InterLinks`](@ref) instance to resolve the reference in
* `extref`: a string of the form
   `"@extref [project] [[:domain][:role]:]name"`
"""
function find_in_interlinks(links::InterLinks, extref::AbstractString)
    m = match(links.rx, extref)
    msg = "Invalid query $(repr(extref)). Should be \"@extref [project] [[:domain][:role]:]name\" where the optional \"project\" is one of $(keys(links))."
    if isnothing(m)
        throw(ArgumentError(msg))
    else
        if isnothing(m["spec"])
            throw(ArgumentError(msg * " Missing [[:domain][:role]:]name."))
        end
        if isnothing(m["project"])
            shortcircuit = match(r"^`?(?<project>\w+)\.", m["name"])
            if !isnothing(shortcircuit)
                # E.g., [`Documenter.makedocs`](@extref) or
                # [text](@extref Documenter.makedocs) looks in an inventory
                # "Documenter" first, under the assumption the people follow
                # the recommended approach of naming their inventories in
                # InterLinks according to the project name.
                try
                    project = shortcircuit["project"]
                    @debug "Trying short-circuit resolution" extref project
                    return _uri(links, project, m["spec"])
                catch exception
                    msg = "Failed short-circuit resolution"
                    @debug msg exception # = (exception, catch_backtrace())
                    # If anything fails (e.g., the project name is not an
                    # inventory name), we just continue with the normal
                    # approach of iterating through all inventories until we
                    # can resolve the link.
                end
            end
            @debug "Looking in *all* inventories" extref
            for (project, inventory) in links
                item = inventory[m["spec"]]
                if !isnothing(item)
                    @debug "Found in inventory \"$(project)\""
                    return uri(item; root_url=inventory.root_url)
                end
            end
            msg = "Cannot find $(repr(m["spec"])) in any InterLinks inventory: $(links.names)\n"
            throw(InventoryItemNotFoundError(msg))
        else
            return _uri(links, m["project"], m["spec"])
        end
    end
end


function _uri(links::InterLinks, project::AbstractString, spec::AbstractString)
    inventory = links[project]
    item = inventory[spec]
    if isnothing(item)
        msg = "Cannot find $(repr(spec)) in InterLinks inventory $(repr(project))"
        throw(InventoryItemNotFoundError(msg))
    else
        return uri(item; root_url=inventory.root_url)
    end
end


function Base.show(io::IO, links::InterLinks)
    N = length(links)
    print(io, "InterLinks(")
    for (i, (project, inventory)) in enumerate(collect(links))
        print(io, "$(repr(project)) => $(repr(inventory))")
        (i < N) && print(io, ", ")
    end
    print(io, ")")
end


function Base.show(io::IO, ::MIME"text/plain", links::InterLinks)
    N = length(links)
    if N <= 1
        show(io, links)
    else
        println(io, "InterLinks(")
        for (i, (project, inventory)) in enumerate(collect(links))
            println(io, "    $(repr(project)) => $(repr(inventory)),")
        end
        print(io, ")")
    end
end


function _validate_inventory(inventory::Inventory)
    root_url = inventory.root_url
    if isempty(root_url)
        throw(ArgumentError("Inventory has empty `root_url`"))
    else
        if !startswith(root_url, r"https?://")
            msg = "Inventory has an invalid `root_url=$(repr(root_url))`: must start with \"http://\" or \"https://\""
            throw(ArgumentError(msg))
        end
        if !endswith(root_url, r"/")
            msg = "Inventory has an invalid `root_url=$(repr(root_url))`: must end with \"/\""
            throw(ArgumentError(msg))
        end
    end
    return inventory
end
