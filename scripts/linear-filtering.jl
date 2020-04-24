import Pkg; Pkg.activate(".")

using CSV
using DataFrames

using Plots
using EcologicalNetworks
using EcologicalNetworksPlots

pyplot()

## Load the data and aggregate everything
data_path = joinpath(pwd(), "data", "interactions", "chiroptera.csv")
chiroptera = CSV.read(data_path)
select!(chiroptera, Not(:origin))
chiroptera = unique(chiroptera)

## Prepare the network
bats = unique(chiroptera.host_species)
viruses = unique(chiroptera.virus_genus)
A = zeros(Bool, (length(viruses), length(bats)))
U = BipartiteNetwork(A, viruses, bats)

for interaction in eachrow(chiroptera)
    U[interaction.virus_genus, interaction.host_species] = true
end

## Modularity analysis
_, partition = lp(U) |> m -> brim(m...)

## Degree
sort(collect(degree(U; dims=2)), by=x->x[2], rev=true)
sort(collect(degree(U; dims=1)), by=x->x[2], rev=true)

## Linear filter
P = linearfilter(U)
for virus in species(P; dims=1)
    probas = Dict([host => P[virus,host] for host in species(P; dims=2)])
    filter!(elem -> !(elem.first in U[virus,:]), probas)
    for elem in sort(collect(probas), by=x->x[2], rev=true)[1:5]
        @info "$(virus)\t$(elem.first)\t$(elem.second)"
    end
end