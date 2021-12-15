export centerofmass, findmid

# find center of mass in 2D image
function centerofmass(img)
    x_pos = []
    y_pos = []
    for i = 1:size(img, 3)
        tmp = img[:, :, i]
        x_data = mean(tmp, dims = 2)
        push!(x_pos, findmid(x_data))
        y_data = mean(tmp, dims = 1)
        push!(y_pos, findmid(y_data))
    end
    return x_pos, y_pos
end

# find weighted center in axis
function findmid(data)
    weighted_sum = 0
    int_sum = 0
    for i = 1:length(data)
        weighted_sum += data[i] * i
        int_sum += data[i]
    end
    return weighted_sum / int_sum
end
