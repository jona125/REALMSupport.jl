using Images, ImageView
using CoordinateTransformations, Rotations, OffsetArrays

function normal(img)
    max_num = maximum(img)
    return img ./ max_num
end

function pipeline2(img)
    M = [
        0.000163234 4.73411e-5 0.860779
        0.0050956 0.637071 0.0214116
        0.684893 -0.00907678 0.00739394
    ]
    v = [0.0, 0.0, 0.0]

    rot = AffineMap(M * [1 0 0; 0 1 0; 0 0 1], v)
    img_r = warp(img, rot)
    img_nor = normal(img_r)
    return img_nor
end
