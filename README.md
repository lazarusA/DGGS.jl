# DGGS.jl <img src="logo.drawio.svg" align="right" height="138" />

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://danlooo.github.io/DGGS.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://danlooo.github.io/DGGS.jl/dev/)
[![Build Status](https://github.com/danlooo/DGGS.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/danlooo/DGGS.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/danlooo/DGGS.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/danlooo/DGGS.jl)

DGGS.jl is a Julia Package for scalable geospatial analysis using Discrete Global Grid Systems (DGGS), which tessellate the surface of the earth with hierarchical cells of equal area, minimizing distortion and loading time of large geospatial datasets, which is crucial in spatial statistics and building Machine Learning models.

## Get Started

This package can be installed in Julia with the following commands:

```Julia
using Pkg
Pkg.add("DGGS")
```

## Development

This project is based on [DGGRID](https://github.com/sahrk/DGGRID).