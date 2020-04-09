entity_match = DataFrame(
    id = UInt64[],
    type = Symbol[],
    name = String[],
    origin = Symbol[],
    row = Integer[],
    match = Union{UInt64,Missing}[]
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
    genus = Union{String,Missing}[]
)

associations = DataFrame(
    interaction_id = UInt64[],
    host = UInt64[],
    virus = UInt64[],
    source = Symbol[],
    index = Int64[],
    method = Union{Symbol,Missing}[]
)