import Pkg
Pkg.activate("/storage1/fs1/holy/Active/jchang/.julia/dev/REALMSupport")
Pkg.instantiate()


include("pipeline2_3d_trans.jl")
include("video_write.jl")

cd(ARGS[1])
using Images, FileIO, Printf
using JLD2

@show("load JLD2 file")
data = jldopen(ARGS[2])
img = data["image_ori"]
data = nothing
img = convert(Array{N0f16}, img)
percentage_scale = 0.6
img_s = img[:, :, :, 1]
new_size = trunc.(Int, size(img_s) .* percentage_scale)
img_s = imresize(img_s, new_size);
img_s = pipeline2(
    img_s;
    z_set = parse(Int64, ARGS[4]),
    z_angle = parse(Float64, ARGS[5]),
    x_angle = parse(Float64, ARGS[6]),
    y_angle = parse(Float64, ARGS[7]),
)
img_ = zeros(size(img_s)[1], size(img_s)[2], size(img)[4])
for i = 1:size(img)[4]
    img_s = img[:, :, :, i]

    img_s = imresize(img_s, new_size)
    @show("image transformation")
    img_re = pipeline2(
        img_s;
        z_set = parse(Int64, ARGS[4]),
        z_angle = parse(Float64, ARGS[5]),
        x_angle = parse(Float64, ARGS[6]),
        y_angle = parse(Float64, ARGS[7]),
    )
    img_s = nothing
    img_re = img_sub(img_re)
    img_re .-= minimum(img_re)
    img_re ./= (mean(img_re) + 5 * std(img_re))
    img_re[img_re.>1] .= 1.0
    img_re = OffsetArrays.no_offset_view(img_re)
    img_[:, :, i] = img_re[:, :, parse(Int64, ARGS[3])]
    img_re = nothing
end
img = nothing

for i in (1:size(img_)[3])
    img_[:, :, i] .-= mean(img_[:, :, i])
end

img_ .-= minimum(img_)
img_ = normal(img_)

if isodd(size(img_)[1])
    img_ = img_[1:end-1, :, :]
end

if isodd(size(img_)[2])
    img_ = img_[:, 1:end-1, :]
end

if isodd(size(img_)[3])
    img_ = img_[:, :, 1:end-1]
end

@show("save video")
writegif(@sprintf("%s.gif", ARGS[2][1:end-8]), img_; fps = 24)
#writevideo(@sprintf("%s.mp4",ARGS[2][1:end-8]),img_;fps=4)
