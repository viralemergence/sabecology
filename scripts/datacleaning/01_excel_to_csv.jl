## Prepare
import Pkg
Pkg.activate(".")

using ExcelFiles
using DataFrames
import CSV

## Read the Excel file
const data_sheet_name = "GB_CoV_VRL_noSeqs"
const raw_metadata_path = joinpath("data", "raw", "$(data_sheet_name).xls")

raw_data = DataFrame(load(raw_metadata_path, data_sheet_name))

## Write the Excel file to CSV
const usable_file_path = joinpath("data", "usable", "$(data_sheet_name).csv")
CSV.write(usable_file_path, raw_data)