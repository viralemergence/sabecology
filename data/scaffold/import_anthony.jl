import Pkg; Pkg.activate(".")

using ExcelFiles
using DataFrames
import CSV
using GBIF

## Load the dataframes templates and other functions
include(joinpath(pwd(), "data", "scaffold", "lib", "dataframes.jl"))
include(joinpath(pwd(), "data", "scaffold", "lib", "methods.jl"))

## Prepare the scaffolds
anth_entities = entity_scaffold()
anth_host = host_scaffold()
anth_virus = virus_scaffold()
anth_associations = associations_scaffold()

## Cleanup the ICTV master dataframe
ictv_master = CSV.read(joinpath(pwd(), "data", "raw", "ictv_master.csv"))[!,1:18]
select!(ictv_master, Not(Symbol("Type Species?")))
select!(ictv_master, Not(:Species))
select!(ictv_master, [:Sort, :Order, :Family, :Genus])
ictv_records = unique(ictv_master, Not(:Sort))

## Subset the ICTV file
for virus in eachrow(ictv_records)
    push!(
        anth_virus,
        (hash(virus), virus.Order, virus.Family, virus.Genus)
    )
end
for fam in eachrow(unique(select(ictv_records, [:Order, :Family])))
    push!(
        anth_virus,
        (hash(fam), fam.Order, fam.Family, missing)
    )
end
for ord in unique(anth_virus.viral_order)
    push!(
        anth_virus,
        (hash(ord), ord, missing, missing)
    )
end

## Read the Anthony dataset from the CSV file
anth_data_path = joinpath(pwd(), "data", "raw", "Anthony", "GB_CoV_VRL_noSeqs2.csv")
anth_raw = CSV.read(anth_data_path; missingstring="NA")

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
