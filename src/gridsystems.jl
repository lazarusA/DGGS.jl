function aggregate_cell_cube(xout, xin; agg_func=filter_null(mean))
    fac = ceil(Int, size(xin, 1) / size(xout, 1))
    for j in axes(xout, 2)
        for i in axes(xout, 1)
            iview = ((i-1)*fac+1):min(size(xin, 1), (i * fac))
            jview = ((j-1)*fac+1):min(size(xin, 2), (j * fac))
            xout[i, j] = agg_func(view(xin, iview, jview))
        end
    end
end

function GridSystem(cell_cube::CellCube)
    pyramid = Dict{Int,CellCube}()
    pyramid[cell_cube.level] = cell_cube

    for coarser_level in cell_cube.level-1:-1:2
        coarser_cell_array = mapCube(
            aggregate_cell_cube,
            pyramid[coarser_level+1].data,
            indims=InDims(:q2di_i, :q2di_j),
            outdims=OutDims(
                Dim{:q2di_i}(range(0; step=1, length=2^(coarser_level - 1))),
                Dim{:q2di_j}(range(0; step=1, length=2^(coarser_level - 1)))
            )
        )
        coarser_cell_cube = CellCube(coarser_cell_array, coarser_level)
        pyramid[coarser_level] = coarser_cell_cube
    end

    return GridSystem(pyramid)
end

GridSystem(geo_cube::GeoCube, level::Integer) = CellCube(geo_cube, level) |> GridSystem

GridSystem(data::AbstractMatrix{<:Number}, lon_range::AbstractRange{<:Real}, lat_range::AbstractRange{<:Real}, level::Integer) = GeoCube(data, lon_range, lat_range) |> x -> GridSystem(x, level)

function GridSystem(path::String)
    levels = []
    for (root, dirs, files) in walkdir(path)
        levels = dirs |> x -> parse.(Int, x) |> sort
        break
    end

    pyramid = Dict{Int,CellCube}()

    for level in levels
        cell_array = Cube("$path/$level")
        pyramid[level] = CellCube(cell_array, level)
    end

    return GridSystem(pyramid)
end

function Base.show(io::IO, ::MIME"text/plain", dggs::GridSystem)
    println(io, "DGGS GridSystem")
    println(io, "Levels: $(join(dggs.data |> keys |> collect |> sort, ","))")
    Base.show(io, "text/plain", dggs.data |> values |> first |> x -> x.data.axes)
end

function Base.write(path::String, dggs::GridSystem; kwargs...)
    mkdir(path)
    attrs = Dict(
        :Conventions => "Attribute Convention for Data Discovery 1-3, CF Conventions v1.8, DGGS data spec",
        :keywords => ["DGGS", "MODIS", "NDVI"],
        :title => "MODIS NDVI",
        :summary => "MODIS NDVI sattelite images 2001",
        :grid => Dict(
            :coordinate_conversions => [
                :version => 7.8,
                :address_type => "Q2DI",
                :type => "dggrid"
            ],
            :aperture => 4,
            :grid_system => Dict(
                :rotation_lon => 11.25,
                :polyhedron => "icosahedron",
                :name => "ISEA4H",
                :radius => 6371007.180918475,
                :polygon => "hexagon",
                :rotation_lat => 58.2825,
                :projection => "+isea",
                :rotation_azimuth => 0
            ),
            :resolutions => [
                Dict(:name => "spatial", :resolution => 4, :dimensions => ["q2di_i", "j", "n"]),
                Dict(:name => "temporal", :resolution => 1, :dimensions => ["Time"])
            ]
        )
    )
    JSON3.write("$path/.zattrs", attrs)
    write("$path/.zgroup", "{\"zarr_format\":2}")
    for cell_cube in values(dggs.data)
        cell_cube_path = "$path/$(cell_cube.level)"
        savecube(cell_cube.data, cell_cube_path; kwargs...)
    end
end

Base.getindex(dggs::GridSystem, level::Int) = dggs.data[level]
Base.setindex!(dggs::GridSystem, cell_cube::CellCube, level::Int) = dggs.data[level] = cell_cube

CellCube(dggs::GridSystem) = dggs[dggs.data|>keys|>maximum]
plot(dggs::GridSystem) = dggs |> CellCube |> plot