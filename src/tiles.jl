"Geographical bounding box given a xyz tile"
function BBox(x, y, z)
    #@see https://wiki.openstreetmap.org/wiki/Slippy_map_tilenames

    n = 2^z
    lon_min = x / n * 360.0 - 180.0
    lat_min = atan(sinh(π * (1 - 2 * (y + 1) / n))) |> rad2deg

    lon_max = (x + 1) / n * 360.0 - 180.0
    lat_max = atan(sinh(π * (1 - 2 * y / n))) |> rad2deg

    return BBox(lon_min, lon_max, lat_min, lat_max)
end

# @see https://wiki.openstreetmap.org/wiki/Slippy_map_tilenames#Julia
lng2tile(lng, zoom) = floor((lng + 180) / 360 * 2^zoom)
lat2tile(lat, zoom) = floor((1 - log(tan(lat * pi / 180) + 1 / cos(lat * pi / 180)) / pi) / 2 * 2^zoom)
tile2lng(x, z) = (x / 2^z * 360) - 180
tile2lat(y, z) = 180 / pi * atan(0.5 * (exp(pi - 2 * pi * y / 2^z) - exp(2 * pi * y / 2^z - pi)))

get_level(z) = z + 2 # 7 # level that has a similar number of cells than pixeles of the tile at zoom 0 (256^2)

"""
(pre) calculate x,y,z to cell_ids for lookup cahce in tile server

`max_z`: maximum z level of xyz tiles, result in `max_z` + 1 levels
"""
function cache_xyz_to_q2di(dir::String; max_z=3, tile_length=256)
    isdir(dir) || mkdir(dir)

    # flatten tasks to increase multi CPU utilization
    tiles_keys = [IterTools.product(0:2^z-1, 0:2^z-1, z) for z in 0:max_z] |> Iterators.flatten |> collect

    # ensure thread saftey. Results might come in differnt order
    p = Progress(length(tiles_keys))
    Threads.nthreads() == 1 && @warn "Multithreading is not active. Please consider to start julia with --threads auto"
    Threads.@threads for i in eachindex(tiles_keys)
        x, y, z = tiles_keys[i]
        result_path = "$dir/$x.$y.$z.dat"
        if isfile(result_path)
            next!(p)
            continue
        end

        level = get_level(z)
        result = transform_points(x, y, z, level)
        # directly serialize to prevent OOM kill
        serialize(result_path, result)
        next!(p)
    end
    finish!(p)
end

function color_value(value, color_scale::ColorScale; null_color=RGBA{Float64}(0, 0, 0, 0))
    ismissing(value) && return null_color
    isnan(value) && return null_color
    return color_scale.schema[value] |> RGBA
end

function calculate_tile(dggs::GridSystem, color_scale::ColorScale, x, y, z; query_str="all", tile_length=256, cache_path=missing)
    cell_cube = dggs[get_level(z)]
    cell_cube = query(cell_cube, query_str)
    # TODO: Check if only spatial dimensions left
    tile_values = GeoCube(cell_cube, x, y, z; cache_path=cache_path).data.data
    scaled = (tile_values .- color_scale.min_value) / (color_scale.max_value - color_scale.min_value)
    image = map(x -> color_value(x, color_scale), scaled)
    io = IOBuffer()
    save(Stream(format"PNG", io), image)
    return io.data
end