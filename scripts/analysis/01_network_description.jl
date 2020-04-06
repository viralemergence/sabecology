import Pkg; Pkg.activate(".")

import CSV
using DataFrames
using EcologicalNetworks

## Read the interaction files
interactions_file = CSV.read(joinpath("data", "network", "interactions.csv"))

## Create array of pairs for different taxonomic depths
edgelist_genus = unique([(Symbol(row.virus), Symbol(row.genus)) for row in eachrow(interactions_file)])
function EcologicalNetworks.BipartiteNetwork(edges::Vector{Tuple{T,T}}) where {T}
    n_virus = length(unique(first.(edges)))
    n_hosts = length(unique(last.(edges)))
    A = zeros(Bool, (n_virus, n_hosts))
    B = BipartiteNetwork(A, unique(first.(edges)), unique(last.(edges)))
    for e in edges
        B[first(e), last(e)] = true
    end
    return B
end

Ngen = BipartiteNetwork(edgelist_genus)

## Aggregate specieslevel properties
specieslevel = DataFrame(species = last(eltype(Ngen))[], degree = Int64[], community = Int64[], within_module_z = Float64[], participation_coefficient = Float64[])
deg = degree(Ngen)
mod = salp(Ngen)
fc = functional_cartography(mod...)

for s in species(Ngen)
    push!(specieslevel, 
        (s, deg[s], last(mod)[s], fc[s]...)
    )
end

## Correct NaN within-module degree
specieslevel.within_module_z[isnan.(specieslevel.within_module_z)] .= 0.0

## Create the folder if the folder is not present
network_path = joinpath("data", "network")
ispath(network_path) || mkpath(network_path)

## Write the unkown hosts to a file
CSV.write(joinpath(network_path, "genus_level_network_metrics.csv"), specieslevel)