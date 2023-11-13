import Pkg
Pkg.activate("/storage1/fs1/holy/Active/jchang/.julia/dev/REALMSupport")


using Images, StaticArrays, LinearAlgebra, Statistics, JLD2
using FileIO, ProgressMeter, ImageSegmentation
using REALMSupport
include("beadstest.jl")
include("pipeline2_3d_trans.jl")

cd(ARGS[1])

files = readdir()
filelist = filter(x->occursin(".imagine",x),files)

for k in 1:size(filelist,1)

    exp = load(filelist[k])
    exp = exp.data.data
    x_ = []
    y_ = []
    z_ = []
    for i in 1:size(exp,4)
        img = exp[:,:,:,i]
        img = convert(Array{Float64}, img)
        for ix in CartesianIndices(img)
            img[ix[1],ix[2],:] .-= mean(img[ix[1],ix[2],:])
        end
        img .-= minimum(img)
        img = normal(img)
        img = convert(Array{N0f16},img)
        x,y,z = beadstest(img,@sprintf("%s_%d",filelist[k][1:end-8],i),pwd())
        push!(x_,x)
        push!(y_,y)
        push!(z_,z)
        img = nothing
    end
    jldsave(@sprintf("%s_psf.jld2",filelist[k][1:end-8]);x_,y_,z_)
end

