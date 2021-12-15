using Images, ImageView, GLMakie
using Printf, FileIO

function coord_trans(img, angle, tilt, mask)
    (p, y, s) = size(img)
    img_trans = zeros(
        floor(Int, s * cos(tilt) + p * cos(angle)) + 12,
        y,
        floor(Int, s * sin(tilt) + p * sin(angle)),
    )
    img_mask = zeros(
        floor(Int, s * cos(tilt) + p * cos(angle)) + 12,
        y,
        floor(Int, s * sin(tilt) + p * sin(angle)),
    )
    for i = 1:p
        for j = 1:s
            new_x = floor(Int, s * cos(tilt) - j * cos(tilt) + i * cos(angle)) + 6
            new_z = floor(Int, j * sin(tilt) + i * sin(angle))
            new_z == 0 ? new_z = 1 : new_z
            for h = -5:6
                img_trans[new_x+h, :, new_z] += img[i, :, j]
                for k = 1:y
                    img[i, k, j] != 0 ? img_mask[new_x+h, k, new_z] += 1 : 1
                end
            end
        end
    end
    img_mask[img_mask.<3] .= mask
    img_mask[img_mask.>=3] .= 1
    return img_trans .* img_mask
end

function normal(img)
    max_num = maximum(img)
    return img / max_num
end

function plot_REALM(filename, angle, tilt)

    img = load(@sprintf("%s.tif", filename))
    img_coord = coord_trans(img, angle * pi / 180, tilt * pi / 180, 0)
    img_nor = normal(img_coord)
    scene = Scene()
    scene = volume(img_nor, algorithm = :mip)

    display(scene)
end
#p = scene[end]
#p.absorption = 8
