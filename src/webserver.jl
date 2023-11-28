using Oxygen
using SwaggerMarkdown
using HTTP


lon_range = -180:180
lat_range = -90:90
time_range = 0:10
geo_data = [t * exp(cosd(lon + (t * 10))) + 3((lat - 50) / 90) for lon in lon_range, lat in lat_range, t in time_range]
axlist = (
  Dim{:lon}(lon_range),
  Dim{:lat}(lat_range),
  Dim{:time}(time_range)
)
geo_array = YAXArray(axlist, geo_data)
geo_cube = GeoCube(geo_array)
cell_cube = CellCube(geo_cube, 6)

function run_webserver(; kwargs...)
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
          description: Successfully returned an number.
  """
  @get "/tile/{z}/{x}/{y}/tile.png" function (req::HTTP.Request, z::Int, x::Int, y::Int)
    params = HTTP.queryparams(req)

    tile = calculate_tile(x, y, z)
    response_headers = [
      "Content-Type" => "image/png",
      # "cache-control" => "max-age=23117, stale-while-revalidate=604800, stale-if-error=604800"
    ]
    response = HTTP.Response(200, response_headers, tile)
    return response
  end

  # TODO: Use Artifacts, see https://github.com/JuliaPackaging/ArtifactUtils.jl to upload directory to github
  dynamicfiles("/home/dloos/prj/DGGS.jl/src/assets/www", "/")

  info = Dict("title" => "DGGSexplorer API", "version" => "1.0.0")
  openApi = OpenAPI("3.0", info)
  swagger_document = build(openApi)
  mergeschema(swagger_document)

  serve(; kwargs...)
end