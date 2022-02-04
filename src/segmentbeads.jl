
export beads_segment

function beads_segment(img::AbstractArray, threshold::Int64, maxsize = 1000, n_std = 3)
    filtered = zeros(eltype(img), axes(img))

    m = mean(img)
    s = std(img)
    img[img.>m+n_std*s] .= 1
    img[img.!=1] .= 0

    label = label_components(img)
    out = component_pixels(label)
    out_fil = filter(out) do item
        length(item) >= threshold && length(item) <= maxsize
    end

    for vec in out_fil
        filtered[vec] = img[vec]
    end

    return filtered
end

function component_pixels(labels)
    n = maximum(labels)
    cp = [CartesianIndex{ndims(labels)}[] for _ = 1:n]
    for i in CartesianIndices(labels)
        c = labels[i]
        if c != 0
            push!(cp[c], i)
        end
    end
    return cp
end
