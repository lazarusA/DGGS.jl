using DGGRID7_jll
import CSV: read
using DataFrames

Projections = [:isea, :fuller]
Topologies = [:hexagon, :triangle, :diamond]
Apertures = [3, 4, 7]

"""
Execute sytem call of DGGRID binary
"""
function call_dggrid(meta::Dict; verbose=false)
    meta_string = ""
    for (key, val) in meta
        meta_string *= "$(key) $(val)\n"
    end

    tmp_dir = tempname()
    mkdir(tmp_dir)
    meta_path = tempname() # not inside tmp_dir to avoid name collision
    write(meta_path, meta_string)

    DGGRID7_jll.dggrid() do dggrid_path
        old_pwd = pwd()
        cd(tmp_dir)
        oldstd = stdout
        if !verbose
            redirect_stdout(devnull)
        end
        run(`$dggrid_path $(meta_path)`)
        cd(old_pwd)
        redirect_stdout(oldstd)
    end

    rm(meta_path)
    return (tmp_dir)
end

"""
Get a DataFrame of cell center points
"""
function get_dggrid_grid_table(type::Symbol, topology::Symbol, projection::Symbol, level::Int)
    meta = Dict(
        "dggrid_operation" => "GENERATE_GRID",
        "clip_subset_type" => "WHOLE_EARTH",
        "point_output_type" => "TEXT",
        "point_output_file_name" => "centers"
    )

    meta["dggs_type"] = "CUSTOM"
    meta["dggs_topology"] = uppercase(string(topology))
    meta["dggs_proj"] = uppercase(string(projection))
    meta["dggs_res_spec"] = uppercase(string(level))

    out_dir = call_dggrid(meta)

    df = read("$(out_dir)/centers.txt", DataFrame; header=["name", "lon", "lat"], footerskip=1)
    rm(out_dir, recursive=true)
    return df
end
