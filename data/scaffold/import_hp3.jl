import Pkg; Pkg.activate(".")

using DataFrames
import CSV
using GBIF

## Load the dataframes templates and other functions
include(joinpath("lib", "dataframes.jl"))
include(joinpath("lib", "methods.jl"))

## Specify the paths
hp3_path = joinpath("data", "raw", "HP3")
hp3_files = ["associations", "hosts", "viruses"]

## Load the files
hp3_assoc, hp3_hosts, hp3_viruses = [CSV.read(joinpath(hp3_path, "$(hp3f).csv")) for hp3f in hp3_files]

## Cleanup the ICTV master dataframe
ictv_master = CSV.read(joinpath("data", "raw", "ictv_master.csv"))[!,1:18]
select!(ictv_master, Not(Symbol("Type Species?")))
for c_name in names(ictv_master)
    levels = unique(ictv_master[!,c_name]) 
    if length(levels)==1
        if ismissing(only(levels))
            select!(ictv_master, Not(c_name))
        end
    end
end
ictv_records = unique(ictv_master, Not(:Sort))

## Subset the ICTV file
for virus in eachrow(ictv_records)
    push!(
        virus_taxonomy,
        (
            hash(virus),
            virus.Realm,
            virus.Phylum,
            virus.Class,
            virus.Order,
            virus.Family,
            virus.Genus,
            virus.Species
        )
    )
end

## Populate the tables with host information
for (idx, host_row) in enumerate(eachrow(hp3_hosts))
    host_name = "$(host_row.hGenus) $(host_row.hSpecies)"
    # Prepare the entity match
    entity_hash = hash(host_row.hHostNameFinal*"HP3")
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