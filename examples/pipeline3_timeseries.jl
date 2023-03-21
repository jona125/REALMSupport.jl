using Images, ImageView, OffsetArrays
using Printf
include("pipeline2_3d_trans.jl")


files = readdir()
filelist = filter(x -> occursin(".tif", x), files)
filelist = filter(x -> occursin(@sprintf("%s", name), x), filelist)


for i = 1:length(filelist)
    img = load(@sprintf("%s", filelist[i]))
    img_nor = pipeline2(img)
    img_save(
        OffsetArrays.no_offset_view(img_nor),
        pwd(),
        @sprintf("%s_t.tif", filelist[i][1:end-4])
    )
end

files = readdir()
filelist = filter(x -> occursin("t.tif", x), files)
filelist = filter(x -> occursin(@sprintf("%s", name), x), filelist)
