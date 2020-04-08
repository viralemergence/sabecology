import Pkg; Pkg.activate(".")

using DataFrames
import CSV
using Query

## Specificy the paths
hp3_path = joinpath("data", "raw", "HP3")
hp3_files = ["associations", "hosts", "viruses"]

## Load the files
hp3 = [CSV.read(joinpath(hp3_path, "$(hp3f).csv")) for hp3f in hp3_files]
