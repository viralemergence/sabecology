import Pkg; Pkg.activate(".")

using CSV
using DataFrames

using Plots
pyplot()

using EcologicalNetworks
using EcologicalNetworksPlots

using StatsBase

## Load the data and aggregate everything
data_path = joinpath(pwd(), "data", "interactions", "complete.csv")
virion = CSV.read(data_path)
select!(virion, Not(:origin))
select!(virion, Not(:id))
virion = unique(virion)

## Prepare the network
hosts = unique(virion.host_species)
viruses = unique(virion.virus_genus)
A = zeros(Bool, (length(viruses), length(hosts)))
U = BipartiteNetwork(A, viruses, hosts)

for interaction in eachrow(virion)
    U[interaction.virus_genus, interaction.host_species] = true
end

## Smaller networks
bats = unique(virion.host_species[findall(virion.host_order .== "Chiroptera")])
mammals = unique(virion.host_species[findall(virion.host_class .== "Mammalia")])

B = simplify(U[:,bats])
M = simplify(U[species(B; dims=1),mammals])

## kNN preparation
tanimoto(x::Set{T}, y::Set{T}) where {T} = length(x∩y)/length(x∪y)

## Main loop?
function knn_virus(train::T, predict::T; k::Integer=5, cutoff::Integer=1) where {T <: BipartiteNetwork}
    predictions = DataFrame(virus = String[], host = String[], match = Float64[])
    for s in species(predict; dims=1)
        @assert s in species(train)
        hosts = train[s,:]
        neighbors = Dict([neighbor => tanimoto(hosts, train[neighbor,:]) for neighbor in filter(x -> x != s, species(train; dims=1))])
        top_k = sort(collect(neighbors), by=x->x[2], rev=true)[1:k]
        hosts_count = StatsBase.countmap(vcat(collect.([predict[n.first,:] for n in top_k])...))
        likely = filter(p -> p.second >= cutoff, sort(collect(hosts_count), by=x->x[2], rev=true))
        for l in likely
          push!(predictions,
            (s, l.first, k-l.second+1)
            )
        end
    end
    return predictions
end


## Write this shit
predict_path = joinpath(pwd(), "predictions", "knn")
ispath(predict_path) || mkpath(predict_path)

## Predict and write
MtoB = knn_virus(M, B)
MtoM = knn_virus(M, M)
BtoB = knn_virus(B, B)

CSV.write(
    joinpath(predict_path, "mammal-bats.all.csv"),
    MtoB    
)

CSV.write(
    joinpath(predict_path, "mammal-bats.corona.csv"),
    MtoB[occursin.("corona", MtoB.virus),:]
)

CSV.write(
    joinpath(predict_path, "mammal-mammal.all.csv"),
    MtoM    
)

CSV.write(
    joinpath(predict_path, "mammal-mammal.corona.csv"),
    MtoM[occursin.("corona", MtoM.virus),:]
)

CSV.write(
    joinpath(predict_path, "bats-bats.all.csv"),
    BtoB
)

CSV.write(
    joinpath(predict_path, "bats-bats.corona.csv"),
    BtoB[occursin.("corona", BtoB.virus),:]
)