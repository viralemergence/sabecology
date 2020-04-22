import Pkg; Pkg.activate(".")

using CSV
using DataFrames

## Prepare the folders
data_path = joinpath(pwd(), "data", "flat")

## Type annotations for the various files
taxo_types = [String, fill(Union{String,Missing}, 7)..., fill(Union{Int64,Missing}, 7)...]
entity_types = [String, String, String, Union{String,Missing}]
associations_types = [String, String, String, String, String, String]
ictv_types = [String, String, String, Union{String,Missing}]

## Load the files
hosts = CSV.read(joinpath(data_path, "hosts.csv"); types=taxo_types)
viruses = CSV.read(joinpath(data_path, "virus.csv"); types=ictv_types)
associations = CSV.read(joinpath(data_path, "associations.csv"); types=associations_types)
hosts_entities = CSV.read(joinpath(data_path, "entities_hosts.csv"); types=entity_types)
viruses_entities = CSV.read(joinpath(data_path, "entities_virus.csv"); types=entity_types)

## Merge the stuff
# TODO rename the intermediary files
hosts_merged = join(hosts_entities, hosts; on=:match => :id, makeunique=true)
viruses_merged = join(viruses_entities, viruses; on=:match => :id, makeunique=true)
associations_merged = join(join(viruses_merged, associations; on=:id=>:virus, makeunique=true), hosts_merged; on=:host=>:id, makeunique=true)

## Get the bats
bats = associations_merged[associations_merged.order .== "Chiroptera",:]
bats = bats[.!ismissing.(bats.genus),:]
rename!(bats, :name_1 => :virus)
select!(bats, Not(r"_id"))
select!(bats, Not(r"_1"))
select!(bats, Not(r"_2"))
for c in [:method, :species, :id, :match, :host, :index, :source, :name, :origin, :kingdom, :phylum, :class, :order]
    select!(bats, Not(c))
end
bats = bats[(bats.rank.=="Genus").|(bats.rank.=="Subgenus"),:]
vgen = Union{Missing,String}[]
vsubgen = Union{Missing,String}[]
for row in eachrow(bats)
    if row.rank == "Genus"
        push!(vgen, row.virus)
        push!(vsubgen, missing)
    else
        push!(vgen, viruses.name[findfirst(viruses.id .== row.ancestor)])
        push!(vsubgen, row.virus)
    end
end
select!(bats, Not(:virus))
select!(bats, Not(:rank))
select!(bats, Not(:ancestor))
rename!(bats, :family => :host_family)
rename!(bats, :genus => :host_genus)
bats.virus_genus = vgen
bats.virus_subgenus = vsubgen

sort!(bats, :virus_genus)

## Write stuff
net_path = joinpath(pwd(), "data", "interactions")
ispath(net_path) || mkdir(net_path)
CSV.write(joinpath(net_path, "chiroptera.csv"), unique(bats))