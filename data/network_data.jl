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

## Merge the host entities
hosts_merged = join(hosts_entities, hosts; on=:match => :id)
rename!(hosts_merged, :name => :host_entity_name)
rename!(hosts_merged, :match => :host_match)
rename!(hosts_merged, :id => :host_entity_id)

## Merge the virus entities
viruses_merged = join(viruses_entities, viruses; on=:match => :id, makeunique=true)
rename!(viruses_merged, :id => :virus_entity_id)
rename!(viruses_merged, :name => :virus_entity_name)
rename!(viruses_merged, :match => :virus_match)
rename!(viruses_merged, :name_1 => :virus_name)

## Merge the associations
#rename!(associations, :id => :association_id)
associations_with_viruses = join(viruses_merged, associations; on=[:virus_entity_id=>:virus, :origin=>:source], makeunique=true)
associations_merged = join(associations_with_viruses, hosts_merged; on=[:origin, :host=>:host_entity_id], makeunique=true)

## Get the bats
bats = associations_merged[associations_merged.order .== "Chiroptera",:]
bats = bats[.!ismissing.(bats.species),:]
select!(bats, Not(r"_id"))
select!(bats, Not(r"_entity_name"))
select!(bats, Not(r"_match"))
for c in [:method, :index, :kingdom, :phylum, :class, :order, :host]
    select!(bats, Not(c))
end
bats = bats[(bats.rank.=="Genus").|(bats.rank.=="Subgenus"),:]
vgen = Union{Missing,String}[]
vsubgen = Union{Missing,String}[]
for row in eachrow(bats)
    if row.rank == "Genus"
        push!(vgen, row.virus_name)
        push!(vsubgen, missing)
    else
        push!(vgen, viruses.name[findfirst(viruses.id .== row.ancestor)])
        push!(vsubgen, row.virus_name)
    end
end
select!(bats, Not(:virus_name))
select!(bats, Not(:rank))
select!(bats, Not(:ancestor))
rename!(bats, :family => :host_family)
rename!(bats, :genus => :host_genus)
rename!(bats, :species => :host_species)
bats.virus_genus = vgen
bats.virus_subgenus = vsubgen

sort!(bats, :virus_genus)

## Write stuff
net_path = joinpath(pwd(), "data", "interactions")
ispath(net_path) || mkdir(net_path)
CSV.write(joinpath(net_path, "chiroptera.csv"), unique(bats))