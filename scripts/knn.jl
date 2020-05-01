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
function knn_virus(train::T, predict::T; k::Integer=3, cutoff::Integer=1) where {T <: BipartiteNetwork}
    predictions = DataFrame(virus = String[], host = String[], match = Float64[])
    for s in species(predict; dims=1)
        @assert s in species(train)
        hosts = train[s,:]
        neighbors = Dict([neighbor => tanimoto(hosts, train[neighbor,:]) for neighbor in filter(x -> x != s, species(train; dims=1))])
        top_k = sort(collect(neighbors), by=x->x[2], rev=true)[1:k]
        hosts_count = StatsBase.countmap(vcat(collect.([predict[n.first,:] for n in top_k])...))
        likely = filter(p -> p.second >= cutoff, sort(collect(hosts_count), by=x->x[2], rev=true))
        for l in likely
            l.first ∈ predict[s, :] && continue
            push!(predictions,
                (s, l.first, l.second/k)
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
BtoB = knn_virus(B, B)
MtoM = knn_virus(M, M)

pred_mtob = MtoB[MtoB.virus.=="Betacoronavirus",:]
select!(pred_mtob, Not(:virus))
pred_mtob.host = replace.(pred_mtob.host, " "=>"_")
sort!(pred_mtob, :match, rev=true)

pred_btob = BtoB[BtoB.virus.=="Betacoronavirus",:]
select!(pred_btob, Not(:virus))
pred_btob.host = replace.(pred_btob.host, " "=>"_")
sort!(pred_btob, :match, rev=true)

pred_mtom = MtoM[MtoM.virus.=="Betacoronavirus",:]
select!(pred_mtom, Not(:virus))
pred_mtom.host = replace.(pred_mtom.host, " "=>"_")
sort!(pred_mtom, :match, rev=true)

CSV.write(
    joinpath(predict_path, "PoisotTanimotoChiropteraToChiropteraPredictions.csv"),
    pred_btob;
    writeheader=false
)

CSV.write(
    joinpath(predict_path, "PoisotTanimotoMammalsToChiropteraPredictions.csv"),
    pred_mtob;
    writeheader=false
)

CSV.write(
    joinpath(predict_path, "PoisotTanimotoMammalsToMammalsPredictions.csv"),
    pred_mtom;
    writeheader=false
)

## Linear filtering path
lf_path = joinpath(pwd(), "predictions", "linearfilter")
ispath(lf_path) || mkpath(lf_path)

## Linear filtering
predictions_lf_bats = DataFrame(species=String[], score=Float64[])
predictions_lf_all = DataFrame(species=String[], score=Float64[])
predictions_lf_meta = DataFrame(species=String[], score=Float64[])

α = [0.0, 1.0, 1.0, 1.0]

for i in interactions(linearfilter(B; α=α))
    B[i.from, i.to] && continue
    i.to ∈ species(B; dims=2) || continue
    if i.from == "Betacoronavirus"
        push!(predictions_lf_bats, 
            (replace(i.to, " "=>"_"), i.probability)
        )
    end
end

for i in interactions(linearfilter(M; α=α))
    M[i.from, i.to] && continue
    i.to ∈ species(B; dims=2) || continue
    if i.from == "Betacoronavirus"
        push!(predictions_lf_all, 
            (replace(i.to, " "=>"_"), i.probability)
        )
    end
end

for i in interactions(linearfilter(M; α=α))
    M[i.from, i.to] && continue
    i.to ∈ species(M; dims=2) || continue
    if i.from == "Betacoronavirus"
        push!(predictions_lf_meta, 
            (replace(i.to, " "=>"_"), i.probability)
        )
    end
end

sort!(predictions_lf_all, :score, rev=true)
sort!(predictions_lf_bats, :score, rev=true)
sort!(predictions_lf_meta, :score, rev=true)

CSV.write(
    joinpath(lf_path, "PoisotLinearFilterChiropteraToChiropteraPredictions.csv"),
    predictions_lf_bats;
    writeheader=false
)

CSV.write(
    joinpath(lf_path, "PoisotLinearFilterMammalsToChiropteraPredictions.csv"),
    predictions_lf_all;
    writeheader=false
)

CSV.write(
    joinpath(lf_path, "PoisotLinearFilterMammalsToMammalsPredictions.csv"),
    predictions_lf_meta;
    writeheader=false
)