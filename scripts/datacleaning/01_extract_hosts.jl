## Prepare
import Pkg
Pkg.activate(".")

using ExcelFiles
using DataFrames
using DelimitedFiles
import GBIF
import CSV

## Read the Excel file
const data_sheet_name = "GB_CoV_VRL_noSeqs"
const raw_metadata_path = joinpath("data", "raw", "$(data_sheet_name).xls")

raw_data = DataFrame(load(raw_metadata_path, data_sheet_name))

## Get the unique list of hosts
hosts = unique(raw_data.gbHost)
filter!(s -> s != "NA", hosts)

## Start querying the hosts
unknown_hosts = String[]

for host in hosts[1:10]
    @info host
    try
        GBIF.taxon(host, strict=false)
    catch
        push!(unknown_hosts, host)
    end
end

## Create the folder if the folder is not present
hostnames_path = joinpath("data", "hostnames")
ispath(hostnames_path) || mkpath(hostnames_path)

## Write the unkown hosts to a file
writedlm(joinpath(hostnames_path, "unknown.txt"), unknown_hosts)