import Pkg; Pkg.activate(".")

using ExcelFiles
using DataFrames
import CSV

## Read the cleaned hostnames
hostnames_clean = CSV.read(joinpath("data", "hostnames", "found.csv"))

## Read the original Excel file
raw_metadata_path = joinpath("data", "raw", "GB_CoV_VRL_noSeqs.xls")
raw_data = DataFrame(load(raw_metadata_path, "GB_CoV_VRL_noSeqs"))

## Select only the relevant columns for the raw data
usable_columns = select(raw_data, [:gbAccession, :gbGenus, :gbHost])
rename!(usable_columns, [:accession, :virus, :host])

## Merge the two dataframes
interaction_data = join(usable_columns, hostnames_clean, on = :host => :original)

## Drop a few columns that are not required for the analysis
select!(interaction_data, Not(:match))
select!(interaction_data, Not(:confidence))
select!(interaction_data, Not(:host))

## Cleanup the virus column
# FIXME this bit is currently an un-holly mess of regex and ad-hoc rules and
# should most likely be its own job in the workflow
virus_names = DataFrame(original = String[], virus_cleaned = String[])
match_virus = r"(\w+)vir(us|ales|idae|inae|ina)"
for virus in unique(interaction_data.virus)
    push!(virus_names, (virus, titlecase(match(match_virus, virus).match)))
end

## Merge the virus file with the interactions file
interaction_data = join(virus_names, interaction_data, on = :original => :virus)

## Rename the columns and sort
rename!(interaction_data, :virus_cleaned => :virus)
sort!(interaction_data,  [:virus, :name])
select!(interaction_data, Not(:original))

## Save the file to a new location
network_path = joinpath("data", "network")
ispath(network_path) || mkpath(network_path)
CSV.write(joinpath(network_path, "interactions.csv"), interaction_data)