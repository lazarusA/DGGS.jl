using DGGRID7_jll
using NearestNeighbors
using CSV
using DataFrames

function dg_call(meta::Dict)
    meta_string = ""
    for (key, val) in meta
        meta_string *= "$(key) $(val)\n"
    end

    tmp_dir = tempname()
    mkdir(tmp_dir)
    meta_path = tempname() # not inside tmp_dir to avoid name collision
    write(meta_path, meta_string)

    DGGRID7_jll.dggrid() do dggrid_path
        cd(tmp_dir)
        run(`$dggrid_path $(meta_path)`)
    end

    rm(meta_path)
    return (tmp_dir)
end

function generate_centers(grid_spec::GridSpec)
    # represent cells as kd-tree of center points
    # cell center points encode grid tpopology (e.g. hexagon or square) implicitly
    # Fast average search in O(log n) and efficient in batch processing
    meta = Dict(
        "dggrid_operation" => "GENERATE_GRID",
        "clip_subset_type" => "WHOLE_EARTH",
        "point_output_type" => "TEXT",
        "point_output_file_name" => "centers"
    )

    if Symbol(grid_spec.type) in GridPresets
        meta["dggs_type"] = string(grid_spec.type)
    else
        meta["dggs_type"] = "CUSTOM"
        meta["dggs_topology"] = string(grid_spec.topology)
        meta["dggs_proj"] = string(grid_spec.projection)
        meta["dggs_res_spec"] = string(grid_spec.resolution)
    end

    out_dir = dg_call(meta)

    df = CSV.read("$(out_dir)/centers.txt", DataFrame; header=["name", "lon", "lat"], footerskip=1)
    kd_tree = df[:, 2:3] |> Matrix |> transpose |> KDTree

    rm(out_dir, recursive=true)
    return (kd_tree)
end