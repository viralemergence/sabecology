import Pkg; Pkg.activate(".")

using DataFrames
import CSV

## Read the ICTV file and remove the junk columns
ictv_master = CSV.read(joinpath(pwd(), "data", "raw", "ictv_master.csv"))

ictv_columns_to_drop = [
    Symbol("Sort"),
    Symbol("Species"),
    Symbol("Type Species?"),
    Symbol("Genome Composition"),
    Symbol("Last Change"),
    Symbol("MSL of Last Change"),
    Symbol("Proposal for Last Change "),
    Symbol("Taxon History URL"),
    :Column23
]

for column_to_drop in ictv_columns_to_drop
    select!(ictv_master, Not(column_to_drop))
end

## Create the new dataframe
ictv = DataFrame(id = Symbol[], name = String[], rank = Symbol[], ancestor = Union{Symbol,Missing}[])

## Read the ICTV master file and convert it
ictv_taxa = unique(ictv_master)
all_ranks = names(ictv_master)

for taxa in eachrow(ictv_taxa)
    taxa_values = values(taxa)
    no_missing = findall(!ismissing, taxa_values)
    this_ranks = all_ranks[no_missing]
    this_names = taxa_values[no_missing]
    for (depth, name) in enumerate(this_names)
        ancestor = missing
        if depth >= 2
            ancestor = Symbol(hash(this_names[depth-1]*string(this_ranks[depth-1])))
        end
        name_hash = Symbol(hash(name*string(this_ranks[depth])))
        if !(name_hash in ictv.id)
            push!(ictv, (
                name_hash,
                name,
                this_ranks[depth],
                ancestor
            ))
        end
    end
end


## Make the path and write the file
data_path = joinpath("data", "scaffold")
ispath(data_path) || mkdir(data_path)
CSV.write(joinpath(data_path, "ictv.csv"), unique(ictv))
