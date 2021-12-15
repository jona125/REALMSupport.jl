function realm_align(file)
    filename = file[1][1:end-4]

    img = load(@sprintf("%s.tif", filename))
    img = convert(Array{N0f16}, img)
    img_l = mean(img, dims = 2)


    function img_dist(img1, img2, shift)
        x1 = size(img1)
        x2 = size(img2)
        dist = 0
        for i = (shift+1):x1[1]
            dist += (img1[i] - img2[i-shift])^2
        end
        return sqrt(dist)
    end

    img_1 = img_l[:, 1, 3]
    img_re = zeros(x, y, z)
    @showprogress "Aligning each frame....." for s = 1:z
        min_dist = 1000000
        shift = 0
        if s != 3
            for i = 0:6
                temp_dist = img_dist(img_1, img_l[:, 1, s], i * 9)
                if min_dist > temp_dist
                    min_dist = temp_dist
                    shift = i
                end
            end
        end
        img_re[shift*9+1:end, :, s] = img[1:end-shift*9, :, s]
    end

    img_re = Gray.(convert.(Normed{UInt16,16}, img_re))
    return img_re
end
