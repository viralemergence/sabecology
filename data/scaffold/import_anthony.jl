import Pkg; Pkg.activate(".")

using DataFrames
import CSV
using GBIF

## Load the dataframes templates and other functions
include(joinpath("lib", "dataframes.jl"))
include(joinpath("lib", "methods.jl"))

## Prepare the scaffolds
entity_match = entity_scaffold()
host_taxonomy = host_scaffold()
virus_taxonomy = virus_scaffold()
associations = associations_scaffold()
