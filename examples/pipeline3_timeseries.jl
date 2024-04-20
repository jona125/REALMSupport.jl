using Images, REALMSupport
using Printf, FileIO
include("pipeline2_3d_trans.jl")

files = readdir()
name = filter(x -> occursin(".imagine", x), files)
name = [x[1:end-8] for x in name]

for i = 1:length(name)
    filelist = filter(x -> occursin(".tif", x), files)
    filelist = filter(x -> occursin(@sprintf("%s", name[i]), x), filelist)

    img = load(@sprintf("%s", filelist[1]))
    img_nor = pipeline2(img)
    img_s = zeros(size(img_nor)[1:2]..., length(filelist))
    img_s[:, :, 1] = img_nor[:, :, z_stack]

    for j = 2:length(filelist)
        img = load(@sprintf("%s", filelist[j]))
        img_nor = pipeline2(img)
        img_s[:, :, parse(Int64, filelist[j][length(name[i])+2:end-4])] =
            img_nor[:, :, z_stack]
        img_nor = nothing
    end

    FileIO.save(@sprintf("%s_%s_t.tif", name[i], z_stack), img_s)
    img_s = nothing
end
