using Images, Statistics
using CoordinateTransformations, Rotations, OffsetArrays

function normal(img)
   max_num = maximum(img)
   return img ./ max_num
end

function img_sub(img)
    for i in (1:size(img)[3]).+axes(img)[3].offset
        img[:,:,i] .-= mean(img[:,:,i])
    end
    return img
end

function pipeline2(img;z_set = 1 ,x_angle = 0.0 ,y_angle = 0.0 ,z_angle = 0.0)
    v = [0.0, 0.0, 0.0]
    tr = zeros(3,3)
    [tr[x,x] = 1.0 for x in 1:3]
    tr[2:3,2:3] = RotMatrix(z_angle)
    tr[1:2,1:2] = RotMatrix(y_angle)
    (tr[3,3],tr[1,3],tr[3,1],tr[1,1]) = RotMatrix(x_angle)
    if z_set == 1
        M = [-9.40453e-6  -0.00145012  1.19443
              3.22872e-5   1.37811     0.000187239
              -1.79544     -0.0268617   0.0203941]
        rot = AffineMap(M*tr,v)
    else
        M = [-9.63642e-7  -0.000522643   0.831357
              5.66957e-6   1.56471      -0.00101736
              -1.82755     -0.00239608   -0.00096341]
        rot = AffineMap(M*tr,v)
    end
        
    img_r = warp(img,rot)
    img_nor = normal(img_r)
    img_nor = permutedims(img_nor, [2,3,1])
    img_nor = img_sub(img_nor)
    return img_nor
end
