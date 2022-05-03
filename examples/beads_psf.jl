using Images, StaticArrays, LinearAlgebra, Statistics
using FileIO, ProgressMeter, Printf, ImageSegmentation
#using Plots, ImageView

include("psf_fun.jl")
include("s_save_image.jl")
include("filter.jl")
include("psf_analyze.jl")
include("beadstest.jl")

THRESHOLD = 7

print("Disk label: ")
label = chomp(readline())

print("Date: ")
date = chomp(readline())
#date="20190315"
@show date

cd(@sprintf("/mnt/%s/jchang/%s/", label, date))
files = readdir()
filelist = filter(x -> occursin(".imagine", x), files)
@show filelist

print("add scale bar(Y as 1, N as 0): ")
r = chomp(readline())
r = parse(Int, r)

l = 0
if r == 1
    print("The length of scale bar(in px): ")
    l = chomp(readline())
    l = parse(Int, l)
end

print("Background Filename: ")
BG_filename = chomp(readline())

if BG_filename == ""
    BG_filename = filelist[1][1:end-8]
    BG_filename *= "_1"
end

print("Save every file during process (1 as Yes, 0 as No): ")
Save = chomp(readline())
Save = (Save == "1")

for k = 1:size(filelist, 1)
    filename = filelist[k][1:end-8]
    exp = load(@sprintf("%s.imagine", filename))

    transfertotif(exp, filename, r, l) # save .imagine into .tif
    files = readdir()
    framelist = filter(x -> occursin(".tif", x), files)
    framelist = filter(x -> occursin(@sprintf("%s", filename), x), framelist)

    for i = 1:size(framelist, 1)
        filename = framelist[i][1:end-4]
        exp = load(@sprintf("%s.tif", filename))

        #img = BG_subtraction(exp,BG_filename,filename,Save)# filter image with background signal
        img = convert(Array{N0f16}, exp)
        img = beads_segment(img, THRESHOLD, 10000, 3)
        #psf_analyze(img,filename)
        img3 = Gray.(convert(Array{N0f16}, OffsetArrays.no_offset_view(img)))
        img4 = Gray.(convert.(Normed{UInt16,16}, img3))
        img_save(img, "/home/jchang/image/result/", @sprintf("%s-fi.tif", filename))
    end
end
