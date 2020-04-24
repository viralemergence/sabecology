import Pkg; Pkg.activate(".")

using CSV
using DataFrames

using Plots
pyplot()

using EcologicalNetworks
using EcologicalNetworksPlots

using StatsBase

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

## kNN preparation

tanimoto(x::Set{T}, y::Set{T}) where {T} = length(x∩y)/length(x∪y)

## Main loop?
predictions = DataFrame(virus = String[], host = String[], match = Float64[])
for s in species(U; dims=1)
    hosts = U[s,:]
    neighbors = Dict([neighbor => tanimoto(hosts, U[neighbor,:]) for neighbor in filter(x -> x != s, species(U; dims=1))])
    top_5 = sort(collect(neighbors), by=x->x[2], rev=true)[1:5]
    hosts_count = StatsBase.countmap(vcat(collect.([U[n.first,:] for n in top_5])...))
    likely = filter(p -> p.second >= 3, sort(collect(hosts_count), by=x->x[2], rev=true))
    for l in likely
        push!(predictions,
        (s, l.first, l.second/length(top_5))
        )
    end
end

CSV.write(
    joinpath(pwd(), "knn.test.csv"),
    sort(predictions[occursin.("corona", predictions.virus), :], :match, rev=true)
)
