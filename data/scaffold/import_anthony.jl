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

## Read the HP3 data

hp3_virus = CSV.read(joinpath(pwd(), "data", "scaffold", "HP3", "virus_taxonomy.csv"))
hp3_host = CSV.read(joinpath(pwd(), "data", "scaffold", "HP3", "host_taxonomy.csv"))
hp3_entities = CSV.read(joinpath(pwd(), "data", "scaffold", "HP3", "entities.csv"))
hp3_associations = CSV.read(joinpath(pwd(), "data", "scaffold", "HP3", "associations.csv"))


## Read the Anthony dataset from the Excel file
const data_sheet_name = "GB_CoV_VRL_noSeqs"
const raw_metadata_path = joinpath("data", "raw", "$(data_sheet_name).xls")

anth_raw = DataFrame(load(raw_metadata_path, data_sheet_name))

## Remove the un-necessary columns

