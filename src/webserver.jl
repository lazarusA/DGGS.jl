function run_webserver(; kwargs...)
  # Threads.nthreads() == 1 || error("The web server must run in a single thread")

  cell_ids_cache = try
    deserialize("data/xyz_to_q2di.cache.bin")
  catch e
    missing
  end

  dggs = GridSystem("data/modis-ndvi.dggs.zarr")
  color_scale = ColorScale(ColorSchemes.viridis, filter_null(minimum)(dggs[2].data), filter_null(maximum)(dggs[2].data))

  @swagger """
  /tile/{z}/{x}/{y}/tile.png:
    get:
      description: Calculate a XYZ tile
      parameters:
        - name: x
          in: path
          required: true
          description: Column [OSM](https://wiki.openstreetmap.org/wiki/Slippy_map_tilenames)
          schema:
            type : number
        - name: y
          in: path
          required: true
          description: Row see [OSM](https://wiki.openstreetmap.org/wiki/Slippy_map_tilenames)
          schema:
            type : number
        - name: z
          in: path
          required: true
          description: Zoom level see [OSM](https://wiki.openstreetmap.org/wiki/Zoom_levels)
          schema:
            type : number
      responses:
        '200':
          description: Successfully returned the tile
  """
  @get "/tile/{z}/{x}/{y}/tile.png" function (req::HTTP.Request, z::Int, x::Int, y::Int)
    params = HTTP.queryparams(req)
    tile = calculate_tile(dggs, color_scale, x, y, z; cache=cell_ids_cache)
    response_headers = [
      "Content-Type" => "image/png",
      # "cache-control" => "max-age=23117, stale-while-revalidate=604800, stale-if-error=604800"
    ]
    response = HTTP.Response(200, response_headers, tile)
    return response
  end

  @get "/dggs/zooms/{z}" function (req::HTTP.Request, z::Int)
    Dict(
      :level => get_level(z)
    )
  end

  # TODO: Use Artifacts, see https://github.com/JuliaPackaging/ArtifactUtils.jl to upload directory to github
  dynamicfiles("/home/dloos/prj/DGGS.jl/src/assets/www", "/")

  info = Dict("title" => "DGGSexplorer API", "version" => "1.0.0")
  openApi = OpenAPI("3.0", info)
  swagger_document = build(openApi)
  mergeschema(swagger_document)

  serveparallel(; kwargs...)
end