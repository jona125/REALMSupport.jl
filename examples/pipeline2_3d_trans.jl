using Images, Statistics
using CoordinateTransformations,
    Rotations, OffsetArrays, MappedArrays, Base.PermutedDimsArrays

function normal(img)
    max_num = maximum(img)
    return img ./ max_num
end

function img_sub(img)
    for i in (1:size(img)[3]) .+ axes(img)[3].offset
        img[:, :, i] .-= mean(img[:, :, i])
    end
    return img
end

function pipeline2(img;x_angle = 0.0, y_angle = 0.0, z_angle = 0.0)
    v = [0.0, 0.0, 0.0]
    tr = zeros(3, 3)
    [tr[x, x] = 4 for x = 1:3]
    tr[2:3, 2:3] = RotMatrix(z_angle)
    tr[1:2, 1:2] = RotMatrix(y_angle)
    (tr[3, 3], tr[1, 3], tr[3, 1], tr[1, 1]) = RotMatrix(x_angle)
    tr[3,3] *= 4
    tr[2,2] *= 4
    M = [
        -0.4375 0.0 1.25
        0.328125 -1.25 -0.9375
        0.25 0.0 0.0
    ]
    rot = AffineMap(M * tr, v)

    img_r = warp(img, rot)
    img_nor = normal(img_r)
    #img_nor = permutedims(img_nor, [2, 3, 1])
    img_nor = img_sub(img_nor)

    #img_r = WarpedView(img, rot)
    #img_nor = mappedarray(normal, img_r)
    #img_nor = PermutedDimsArray(img_nor, [2, 3, 1])
    #img_nor = mappedarray(img_sub, img_nor)
    return img_nor
end
