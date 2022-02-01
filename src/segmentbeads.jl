
export beads_segment

function beads_segment(img::AbstractArray,threshold)
    filtered = zeros(size(img))
    
    m = mean(img)
    s = std(img)
    img[img.>m+3*s] .= 1
    img[img.!=1] .= 0

    label = label_components(img)
    out = component_pixels(label)
    out_fil = filter(out) do item
                length(item) >= threshold && length(item) <= 1000
              end

    @showprogress @sprintf("Filtering %s",filename) for vec in out_fil
        for coord in vec
            filtered[coord] = img[coord]
        end
    end

    replace!(filtered, NaN=>0)
    img3 = Gray.(convert(Array{N0f16},OffsetArrays.no_offset_view(filtered)))
    img4 = Gray.(convert.(Normed{UInt16,16},img3))
    return img4
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
