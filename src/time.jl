
export timeseries

#files=readdir()
#filelist=filter(x->occursin(".tif",x),files)
#filelist=filter(x->occursin(@sprintf("%s",date),x),filelist)
#@show filelist

function timeseries(filelist, s, bi = 0)
    filename = filelist[1][1:end-4]

    img = load(@sprintf("%s.tif", filename))
    img = convert(Array{N0f16}, img)
    img_re = []

    (x, y, z) = size(img)


    if bi == 1
        img_re = zeros(Int(floor(x / 2)), y, size(filelist, 1) * 2)

        for k = 1:size(filelist, 1)
            filename = filelist[k][1:end-4]
            i = split(filelist[k], "_")[end-1]
            i = parse(Int64, i)
            img = load(@sprintf("%s.tif", filename))
            img = convert(Array{N0f16}, img)

            img_re[:, :, i*2-1] = img[1:Int(floor(x / 2)), :, s]
            img_re[end:-1:1, :, i*2] = img[end-Int(floor(x / 2)):end-1, :, s]
        end

    else
        img_re = zeros(x, y, size(filelist, 1))

        for k = 1:size(filelist, 1)
            filename = filelist[k][1:end-4]
            i = split(filelist[k], "_")[end-1]
            i = parse(Int64, i)
            img = load(@sprintf("%s.tif", filename))
            img = convert(Array{N0f16}, img)

            img_re[:, :, i] = img[:, :, s]
        end
    end
    return img_re
end
