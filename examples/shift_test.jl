using REALMSupport
using REALMSupport.RegisterCore: CenterIndexedArray
using Optim, Images, RegisterMismatch, FFTW
FFTW.set_num_threads(16)

filelist = readdir()
filelist = filter(x -> occursin("-fi.tif", x), filelist)
filelist = filter(x -> occursin("20220317_1um", x), filelist)

mm = CenterIndexedArray(zeros(241, 241, 241, size(filelist, 1)))
mm_r = []
img_org = load("20220317_1um_x-0_1_1-fi.tif")

for (i, j) in enumerate(axes(mm, 4))
    img = load(filelist[i])
    mm[:, :, :, j] = translate(img_org, img, (120, 120, 120))
    push!(mm_r, register_translate(img_org, img, (120, 120, 120)))
end

move = [
    20 20 40 40 0 0 -20 -20 -40 -40 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
    0 0 0 0 0 0 0 0 0 0 20 20 40 40 0 -20 -20 -40 -40 0 0 0 0 0 0 0 0 0 0
    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 20 20 40 40 0 0 -20 -20 -40 -40
]


#move = [20 20 20 40 40 40 0 0 0 -20 -20 -20 -40 -40 -40 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 20 20 20 40 40 40 0 0 0 -20 -20 -20 -40 -40 -40 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 20 20 20 40 40 40 0 0 0 -20 -20 -20 -40 -40 -40]
#move = [ 20 40 0 -20 -40 0 0 0 0 0 0 0 0 0 0; 0 0 0 0 0 20 40 0 -20 -40 0 0 0 0 0; 0 0 0 0 0 0 0 0 0 0 20 40 0 -20 -40]

matrix = Float64[-0.01 0 -1.84 0 1.56 0 1.198 0 -0.39]

result = translate_optim(mm, matrix, move; g_abstol = 1e-14)

mat = reshape(Optim.minimizer(result), 3, 3)
display(mat)
display((mat * move)')
display(mm_r)
