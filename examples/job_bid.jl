import Pkg
Pkg.activate("/storage1/fs1/holy/Active/jchang/.julia/dev/REALMSupport")

cd(ARGS[1])
include(ARGS[2])
using Images, FileIO, Printf
using JLD2
file = readdir()
filelist = filter(x -> occursin(".imagine", x), file)

for i = 1:length(filelist)
    img = load(filelist[i])
    img = img.data.data
    shape = size(img)

    img = reshape(img, shape[1], shape[2], Int(shape[3] / 2), shape[4] * 2)
    img = convert.(Gray{N0f16}, img)
    img_re = img
    for i = 2:2:(shape[4]*2)
        img_re[:, :, :, i] = img[:, :, end:-1:1, i]
    end
    img = nothing
    GC.gc(true)
    GC.gc(true)
    GC.gc(true)
    img_s = convert(Array{N0f16}, img_re[:, :, :, 1])
    img_nor = pipeline2(img_s)
    img_s = nothing
    jldsave(
        @sprintf("%s_re.jld2", filelist[i][1:end-8]),
        image = img_nor,
        image_ori = img_re,
    )
    img_nor = nothing
    img_re = nothing
    GC.gc(true)
    GC.gc(true)
    GC.gc(true)
end
