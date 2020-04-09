import Pkg; Pkg.activate(".")

using DataFrames
import CSV
using GBIF

## Specify the paths
hp3_path = joinpath("data", "raw", "HP3")
hp3_files = ["associations", "hosts", "viruses"]

## Load the files
hp3_assoc, hp3_hosts, hp3_viruses = [CSV.read(joinpath(hp3_path, "$(hp3f).csv")) for hp3f in hp3_files]

## Cleanup the ICTV master dataframe
ictv_master = CSV.read(joinpath("data", "raw", "ictv_master.csv"))
select!(ictv_master, Not(:Column23))
#select!(ictv_master, Not(:))

## Function to hash the names and generate unique identifiers
function generate_unique_names(text::String, source::String)
    return hash(source * text)
end

## Prepare a name match and a taxonomy table

entity_match = DataFrame(
    id = UInt64[],
    type = Symbol[],
    name = String[],
    origin = Symbol[],
    row = Integer[],
    match = Union{UInt64,Nothing}[]
)

host_taxonomy = DataFrame(
    id = UInt64[],
    kingdom = Union{String,Missing}[],
    phylum = Union{String,Missing}[],
    class = Union{String,Missing}[],
    order = Union{String,Missing}[],
    family = Union{String,Missing}[],
    genus = Union{String,Missing}[],
    species = Union{String,Missing}[],
    kingdom_id = Union{Integer,Missing}[],
    phylum_id = Union{Integer,Missing}[],
    class_id = Union{Integer,Missing}[],
    order_id = Union{Integer,Missing}[],
    family_id = Union{Integer,Missing}[],
    genus_id = Union{Integer,Missing}[],
    species_id = Union{Integer,Missing}[]
)

virus_taxonomy = DataFrame(
    id = UInt64[],
    kingdom = Union{String,Missing}[],
    phylum = Union{String,Missing}[],
    class = Union{String,Missing}[],
    order = Union{String,Missing}[],
    family = Union{String,Missing}[],
    genus = Union{String,Missing}[],
    species = Union{String,Missing}[],
    kingdom_id = Union{Integer,Missing}[],
    phylum_id = Union{Integer,Missing}[],
    class_id = Union{Integer,Missing}[],
    order_id = Union{Integer,Missing}[],
    family_id = Union{Integer,Missing}[],
    genus_id = Union{Integer,Missing}[],
    species_id = Union{Integer,Missing}[]
)

## Facilitate the unpacking of GBIF objects
function Base.convert(::Type{Tuple}, tax::GBIFTaxon)
    txt = Union{String,Missing}[]
    idx = Union{Integer,Missing}[]
    for l in [:kingdom, :phylum, :class, :order, :family, :genus, :species]
        if !ismissing(getfield(tax, l))
            push!(txt, getfield(tax, l).first)
            push!(idx, getfield(tax, l).second)
        else
            push!(txt, missing)
            push!(idx, missing)
        end
    end
    return (txt..., idx...)
end

## Populate the tables with host information
for (idx, host_row) in enumerate(eachrow(hp3_hosts))
    host_name = "$(host_row.hGenus) $(host_row.hSpecies)"
    # Prepare the entity match
    entity_hash = generate_unique_names(host_row.hHostNameFinal, "HP3")
    entity_row = idx
    match_gbif = nothing
    try
        match_gbif = taxon(host_name, strict=false)
    catch
        continue
    end
    # Add to the taxonomy table
    match_gbif_hash = isnothing(match_gbif) ? nothing : hash(match_gbif)
    if !isnothing(match_gbif)
        push!(host_taxonomy, (
            match_gbif_hash,
            convert(Tuple, match_gbif)...
        ))
    end
    # Return everything
    push!(entity_match, (entity_hash, :host, host_row.hHostNameFinal, :HP3, idx, match_gbif_hash))
end

## Populate with the virus information
for (idx, virus_row) in enumerate(eachrow(hp3_viruses))
    virus_name = "$(virus_row.vGenus)"
    # Prepare the entity match
    entity_hash = generate_unique_names(virus_row.vVirusNameCorrected, "HP3")
    entity_row = idx
    match_gbif = nothing
    try
        match_gbif = taxon(virus_name, rank=:GENUS, strict=true)
    catch
        continue
    end
    # Add to the taxonomy table
    match_gbif_hash = isnothing(match_gbif) ? nothing : hash(match_gbif)
    if !isnothing(match_gbif)
        push!(taxonomy, (
            match_gbif_hash,
            convert(Tuple, match_gbif)...
        ))
    end
    # Return everything
    push!(entity_match, (entity_hash, virus_row.vVirusNameCorrected, :HP3, idx, match_gbif_hash))
end

## Prepare a trait table

# TODO

## Prepare an association table
associations = DataFrame(
    interaction_id = UInt64[],
    host_id = UInt64[],
    virus_id = UInt64[],
    source = Symbol[],
    index = Int64[],
    method = Union{Symbol,Missing}[]
)

for (i,row) in enumerate(eachrow(hp3_assoc))
    vir_row = findfirst(entity_match.name .== row.vVirusNameCorrected)
    hos_row = findfirst(entity_match.name .== row.hHostNameFinal)
    if !isnothing(vir_row) & !isnothing(hos_row)
        int_hash = hash(row.vVirusNameCorrected*row.hHostNameFinal*"HP3")
        push!(associations, (
            int_hash,
            entity_match.id[hos_row],
            entity_match.id[vir_row],
            :HP3,
            i,
            Symbol(replace(replace(row.DetectionMethod, ", " => "_"), " " => "_"))
        ))
    end
end

## Make the path
data_path = joinpath("data", "scaffold", "HP3")
ispath(data_path) || mkdir(data_path)

## Write the files
CSV.write(joinpath(data_path, "entities.csv"), unique(entity_match))
CSV.write(joinpath(data_path, "taxonomy.csv"), unique(taxonomy))
CSV.write(joinpath(data_path, "associations.csv"), unique(associations))