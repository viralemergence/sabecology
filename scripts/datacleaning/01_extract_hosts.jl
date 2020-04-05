## Prepare
import Pkg; Pkg.activate(".")

using ExcelFiles
using DataFrames
import GBIF
import CSV

## Read the Excel file
const data_sheet_name = "GB_CoV_VRL_noSeqs"
const raw_metadata_path = joinpath("data", "raw", "$(data_sheet_name).xls")

raw_data = DataFrame(load(raw_metadata_path, data_sheet_name))

## Get the unique list of hosts
hosts = unique(raw_data.gbHost)
filter!(s -> s != "NA", hosts)

## Prepare a list of hosts
taxonomy = DataFrame(
original=String[],
match = Symbol[],
confidence = Union{Int64,Missing}[],
level = Union{Symbol,Missing}[],
name=Union{Missing,String}[],
kingdom=Union{String,Missing}[],
kingdom_id=Union{Int64,Missing}[],
phylum=Union{String,Missing}[],
phylum_id=Union{Int64,Missing}[],
class=Union{String,Missing}[],
class_id=Union{Int64,Missing}[],
order=Union{String,Missing}[],
order_id=Union{Int64,Missing}[],
family=Union{String,Missing}[],
family_id=Union{Int64,Missing}[],
genus=Union{String,Missing}[],
genus_id=Union{Int64,Missing}[],
species=Union{String,Missing}[],
species_id=Union{Int64,Missing}[]
)

unknown_taxonomy = DataFrame(string = String[], count = Integer[])

## Read the corrected species names
known_vernaculars_csv = CSV.read(joinpath("data", "extra", "hostnames.csv"), delim=';')

known_vernaculars = Dict([r.string => r.species_name for r in eachrow(known_vernaculars_csv)])

## Query the possible hosts
for host in hosts
    host_to_query = haskey(known_vernaculars, host) ? known_vernaculars[host] : host
    @info host_to_query
    try
        t = GBIF.taxon(host_to_query, strict=false)
        levels = [:kingdom, :phylum, :class, :order, :family, :genus, :species]
        level = levels[findlast(l -> getfield(t, l) !== nothing, levels)]
        info = []
        for l in levels
            push!(info, getfield(t, l).first)
            push!(info, getfield(t, l).second)
        end
        push!(taxonomy, (host_to_query, t.match, t.confidence, level, t.name, info...))
    catch
        push!(unknown_taxonomy, (host_to_query, sum(raw_data.gbHost .== host)))
    end
end

# This sorts the list of unknown hosts by number of times they appear, so the
# topmost species are more important to validate.
sort!(unknown_taxonomy, :count, rev=true)
sort!(taxonomy, :match)

## Create the folder if the folder is not present
hostnames_path = joinpath("data", "hostnames")
ispath(hostnames_path) || mkpath(hostnames_path)

## Write the unkown hosts to a file
CSV.write(joinpath(hostnames_path, "found.csv"), taxonomy)
CSV.write(joinpath(hostnames_path, "unknown.csv"), unknown_taxonomy)