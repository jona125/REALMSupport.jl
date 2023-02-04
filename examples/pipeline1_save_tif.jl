using REALMSupport, Images

file = readdir()
filelist = filter(x -> occursin(".imagine", x), file)

for i = 1:length(filelist)
    img = load(filelist[i])
    transfertotif(img, filelist[i][1:end-8], 0)
end
