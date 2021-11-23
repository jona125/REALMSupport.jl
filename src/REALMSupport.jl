module REALMSupport

using Images,ImageSegmentation, ImageTransformations, Optim
using ImageView, Plots, Makie
using Statistics, OffsetArrays
using FileIO, Printf, ProgressMeter


include("grid_fun.jl")
include("gauss_fit.jl")


export grid_fun, gauss_fit

export grid_resolution, Gauss_line_fit

end
