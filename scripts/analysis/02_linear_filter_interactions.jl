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

N = BipartiteNetwork(edgelist_genus)

## Create a function to estimate the probability of absent interactions
function augmented_linear_filter(N::T; α=fill(0.25, 4)) where {T <: BinaryNetwork}
    P = linearfilter(N; α=α)
    for int in interactions(N)
        P[int.from, int.to] = 1.0
    end
    return P
end

only_hosts = (N; h=0.1) -> augmented_linear_filter(N; α=[0.0, 0.0, 1.0-h, h])
only_virus = (N; h=0.1) -> augmented_linear_filter(N; α=[0.0, 1.0-h, 0.0, h])
both_degree = (N; h=0.1) -> augmented_linear_filter(N; α=[0.0, 0.5*(1.0-h), 0.5*(1.0-h), h])
no_guess = (N; h=0.1) -> augmented_linear_filter(N; α=[(1.0-h)/3, (1.0-h)/3, (1.0-h)/3, h])

## Run the model and put results in a DataFrame
lf_output = DataFrame(virus = Symbol[], host = Symbol[], risk_h = Float64[], risk_v = Float64[], risk_b = Float64[], risk_e = Float64[])

Ph = only_hosts(N)
Pv = only_virus(N)
Pb = both_degree(N)
Pn = no_guess(N)

for vir in species(N; dims=1), hos in species(N; dims=2)
    if !N[vir, hos]
        push!(lf_output,
            (vir, hos, Ph[vir, hos], Pv[vir, hos], Pb[vir, hos], Pn[vir, hos])
        )
    end
end

for cname in [:risk_h, :risk_v, :risk_b, :risk_e]
    m = mean(lf_output[!,cname])
    s = std(lf_output[!,cname])
    lf_output[!,cname] = (lf_output[!,cname].-m)./s
end

## Write the CSV to file
output_path = joinpath("results", "link_prediction")
ispath(output_path) || mkpath(output_path)
CSV.write(joinpath(output_path, "augmented_linearfiltering.csv"), lf_output)
