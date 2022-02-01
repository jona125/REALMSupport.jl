using REALMSupport
using REALMSupport.RegisterCore: CenterIndexedArray
using Optim, Images, RegisterMismatch

filelist = readdir()
filelist = filter(x -> occursin(".tif", x), filelist)
filelist = filter(x -> occursin("1um", x), filelist)

mm = CenterIndexedArray(zeros(201, 201, 201, size(filelist, 1)))
mm_r = []
img_org = load("20211013_1um-x-0_1.tif")

for (i, j) in enumerate(axes(mm, 4))
    img = load(filelist[i])
    mm[:, :, :, j] = translate(img_org, img, (100, 100, 100))
    push!(mm_r, register_translate(img_org, img, (100, 100, 100)))
end

display(mm)

move = [
    40 80 0 -40 -80 0 0 0 0 0 0 0 0
    0 0 0 0 0 0 0 0 0 0 0 0 0
    0 0 0 0 0 10 20 30 40 -10 -20 -30 -40
]

matrix = Float64[-0.17 0 -1.18 0 0 0 0.55 0 -0.01]

result = translate_optim(mm, matrix, move; g_abstol = 1e-14)

mat = reshape(Optim.minimizer(result), 3, 3)
display(mat)
