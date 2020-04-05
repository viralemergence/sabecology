## Load the packages
import Pkg; Pkg.activate(".")

using GBIF
using DataFrames
import CSV

occurrences_path = joinpath("data", "occurrences")
ispath(occurrences_path) || mkpath(occurrences_path)

## Load the csv file for hosts
hosts = CSV.read(joinpath("data", "hostnames", "found.csv"))

## Get the unique rows (i.e. minus the `original` column)
unique_taxa = unique(select(hosts, Not(:original)))

## Get 20 records for the first few taxa as a test
for taxa_row in eachrow(unique_taxa[1:4,:])
    taxid = taxa_row[Symbol(taxa_row.level)]
    @info "Getting occurrences for $(taxid)"
    best_resolved = taxon(taxid)
    occ = occurrences(best_resolved, "limit" => 200)
    # FIXME get more occurrences here
    get_up_to = min(occ.count, 1000)
    while length(occ) < get_up_to
        occurrences!(occ)
    end
    filter!(have_ok_coordinates, occ)
    occ_df = DataFrame(name = String[], occid = Int64[], latitude = Float64[], longitude = Float64[])
    for occurrence in occ
        if !ismissing(occurrence.latitude)
            if !ismissing(occurrence.longitude)
                push!(occ_df, (taxid, occurrence.key, occurrence.latitude, occurrence.longitude))
            end
        end
    end
    try
        CSV.write(joinpath(occurrences_path, replace(taxid, " "=> "_")*".csv"), occ_df)
    catch
        @warn "Writing CSV failed for $(taxid)"
    end
end