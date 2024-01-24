# DGGS.jl <img src="docs/src/assets/logo.drawio.svg" align="right" height="138" />

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://danlooo.github.io/DGGS.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://danlooo.github.io/DGGS.jl/dev/)
[![Build Status](https://github.com/danlooo/DGGS.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/danlooo/DGGS.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/danlooo/DGGS.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/danlooo/DGGS.jl)

DGGS.jl is a Julia Package for scalable geospatial analysis using Discrete Global Grid Systems (DGGS), which tessellate the surface of the earth with hierarchical cells of equal area, minimizing distortion and loading time of large geospatial datasets, which is crucial in spatial statistics and building Machine Learning models.

## Important Note

This project is currently under intensive development.
The API is not considered stable yet.
There may be errors in some outputs.
We do not take any warranty for that.
Please test this package with caution.
Bug reports and feature requests are welcome.
Please create a [new issue](https://github.com/danlooo/DGGS.jl/issues/new) for this.

## Get Started

DGGS.jl currently only officially supports Julia 1.9 running on a 64bit Linux machine.
This package can be installed in Julia with the following commands:

```Julia
using Pkg
Pkg.add(url="https://github.com/danlooo/DGGS.jl.git")
```

Create a DGGS based on a synthetic data in a geographical grid:

```julia
using DGGS
lon_range = -180:180
lat_range = -90:90
level = 6
data = [exp(cosd(lon)) + 3(lat / 90) for lat in lat_range, lon in lon_range]
dggs = GridSystem(data, lon_range, lat_range, level)
```
```
[ Info: Step 1/2: Transform coordinates
[ Info: Step 2/2: Re-grid the data
DGGS GridSystem
Levels: 2,3,4,5,6
Dim{:q2di_i} Sampled{Int64} 0:1:15 ForwardOrdered Regular Points,
Dim{:q2di_j} Sampled{Int64} 0:1:15 ForwardOrdered Regular Points,
Dim{:q2di_n} Sampled{Int64} 0:11 ForwardOrdered Regular Points
```

Write DGGS data to disk and load them back:

```
write("example.dggs", dggs)
dggs2 = GridSystem("example.dggs")
```
The data can be visualized using `plot(dggs)`.

## Development

This project is based on [DGGRID](https://github.com/sahrk/DGGRID).

## Funding

<p>
<a href = "https://earthmonitor.org/">
<img src="https://earthmonitor.org/wp-content/uploads/2022/04/european-union-155207_640-300x200.png" align="left" height="50" />
</a>

<a href = "https://earthmonitor.org/">
<img src="https://earthmonitor.org/wp-content/uploads/2022/04/OEM_Logo_Horizontal_Dark_Transparent_Background_205x38.png" align="left" height="50" />
</a>
</p>

This project has received funding from the [Open-Earth-Monitor Cyberinfrastructure](https://earthmonitor.org/) project that is part of European Union's Horizon Europe research and innovation programme under grant agreement No. [101059548](https://cordis.europa.eu/project/id/101059548).