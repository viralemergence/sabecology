import Pkg; Pkg.activate(".")

using ExcelFiles
using DataFrames
import CSV
using GBIF

## Read the raw data
anth_data_path = joinpath(pwd(), "data", "raw", "Anthony", "GB_CoV_VRL_noSeqs2.csv")
anth_raw = CSV.read(anth_data_path; missingstring="NA")

## Load the ICTV master data
ictv_path = joinpath(pwd(), "data", "scaffold", "ictv.csv")
ictv = CSV.read(ictv_path, types=[String, String, String, Union{String,Missing}])

## Load the dataframes templates and other functions
include(joinpath(pwd(), "data", "scaffold", "lib", "methods.jl"))

## Map the viruses
anthony_entities_virus = DataFrame(
    name = String[],
    match = Union{String,Missing}[]
)

## Virus mapping
match_virus = r"(\w+)vir(us|idae|inae|ales)"
unique_virus_names = unique(anth_raw.gbGenus)

for virus_name in unique_virus_names
    regex_match = match(match_virus, virus_name)
    
    if isnothing(regex_match)
        push!(anthony_entities_virus, (
            virus_name, missing
        ))
    else
        matching_idx = findfirst(lowercase.(ictv.name) .== lowercase(regex_match.match))
        if isnothing(matching_idx)
            push!(anthony_entities_virus, (
                virus_name, missing
            ))
        else
            push!(anthony_entities_virus, (
                virus_name, ictv.id[matching_idx]
            ))
        end
    end
end

## stop
    
    
    








## Hosts
unique_anth_hosts = filter(!ismissing, unique(anth_raw.gbHost))

for (i, host) in enumerate(unique_anth_hosts)
    entity_hash = hash(host*"Anth")
    match_gbif = missing
    try
        match_gbif = taxon(host, strict=false)
    catch
        continue
    end
    # Add to the taxonomy table
    match_gbif_hash = ismissing(match_gbif) ? missing : hash(match_gbif)
    if !isnothing(match_gbif)
        push!(anth_host,
            (match_gbif_hash, convert(Tuple, match_gbif)...)
        )
    end
    # Add to the entity table
    push!(anth_entities, (entity_hash, :host, host, :Anthony, i, match_gbif_hash))
end

## Virus
match_virus = r"(\w+)vir(us|idae|inae|ales)"
unique_virus_names = unique(anth_raw.gbGenus)

# Known to genus only
anth_genus = anth_virus[.!ismissing.(anth_virus.viral_genus),:]

# Known to family only
anth_family = anth_virus[ismissing.(anth_virus.viral_genus),:]
anth_family = anth_family[.!ismissing.(anth_family.viral_family),:]

# Known to order only
anth_order = anth_virus[ismissing.(anth_virus.viral_genus),:]
anth_order = anth_order[ismissing.(anth_order.viral_family),:]
anth_order = anth_order[.!ismissing.(anth_order.viral_order),:]

for i in 1:length(unique_virus_names)
    orig_name = unique_virus_names[i]
    regex_match = match(match_virus, orig_name)
    
    # We stop if there is no match
    isnothing(regex_match) && continue

    # Moving on...
    correct_name = titlecase(regex_match.match)
    virus_id = hash(orig_name*"Anthony")

    @info (virus_id, correct_name)
    
    # Known genus?
    matched_genus = findall(anth_genus.viral_genus .== correct_name)
    if length(matched_genus) == 1
        genus_id = anth_genus.id[only(matched_genus)]
        push!(anth_entities, (
            virus_id, :virus, orig_name, :Anthony, i, genus_id
        ))
        continue
    end
    @info "$(correct_name) unmatched at genus level"

    # Known family?
    matched_family = findall(anth_family.viral_family .== correct_name)
    if length(matched_family) == 1
        genus_id = anth_family.id[only(matched_family)]
        push!(anth_entities, (
            virus_id, :virus, orig_name, :Anthony, i, genus_id
        ))
        continue
    end
    @info "$(correct_name) unmatched at family level"

    # Known order?
    matched_order = findall(anth_order.viral_order .== correct_name)
    if length(matched_order) == 1
        genus_id = anth_order.id[only(matched_order)]
        push!(anth_entities, (
            virus_id, :virus, orig_name, :Anthony, i, genus_id
        ))
        continue
    end
    @info "$(correct_name) unmatched at order level"


end

## Associations

## Make the path
data_path = joinpath("data", "scaffold", "Anthony")
ispath(data_path) || mkdir(data_path)

## Write the files
CSV.write(joinpath(data_path, "entities.csv"), unique(anth_entities))
CSV.write(joinpath(data_path, "host_taxonomy.csv"), unique(anth_host))
CSV.write(joinpath(data_path, "virus_taxonomy.csv"), unique(anth_virus))
CSV.write(joinpath(data_path, "associations.csv"), unique(anth_associations))
