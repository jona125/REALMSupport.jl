using Images, ImageSegmentation, Statistics, ProgressMeter, Printf, FileIO
using CoordinateTransformations, Rotations, OffsetArrays, Optim, FFTW
using REALMSupport
using pd_density
kernel = Kernel.gaussian((5, 5, 5))
FFTW.set_num_threads(4)
debug = Ref(Any[])

function trans(theta, ori)
    v = [0.0, 0.0, 1.0]
    tr = zeros(3, 3)
    [tr[x, x] = 1.0 for x = 1:3]
    tm = recenter(RotMatrix(theta), ori[1:2])
    v[1:2] = tm.translation
    tr[1:2, 1:2] = tm.linear
    return AffineMap(tr, v)
end

function xy2rthe(coord, ori)
    return sqrt((coord[1] - ori[1])^2 + (coord[2] - ori[2])^2),
    atan((coord[2] - ori[2]) / (coord[1] - ori[1]))
end

function fwhm(signal)
    data = signal .- mean(signal)
    data .-= minimum(data)

    half_value = maximum(data) / 2
    peak = findall(data .> half_value)
    if length(peak) <= 2 ||
       !checkbounds(Bool, data, peak[end] + 1) ||
       !checkbounds(Bool, data, peak[1] - 1)
        return 0, 0
    end
    buff =
        (half_value - data[peak[1]-1]) / (data[peak[1]] - data[peak[1]-1]) +
        (half_value - data[peak[end]]) / (data[peak[end]+1] - data[peak[end]])
    return maximum(signal), peak[end] - peak[1] + buff
end

function axis_crop(img_window, range)
    # Gaussian fitting in three axis
    img_x = OffsetArray(vec(mean(mean(img_window; dims = 3); dims = 2)), -range:range)
    img_y = OffsetArray(vec(mean(mean(img_window; dims = 3); dims = 1)), -range:range)
    img_z = OffsetArray(vec(mean(mean(img_window; dims = 2); dims = 1)), -range:range)
    return img_x, img_y, img_z
end

function img_rot(img, coord, ori, x_range, y_range, z_range)
    r, theta = xy2rthe(coord, ori)
    trfm = trans(theta, ori)
    img_ = img_crop(
        img,
        coord,
        Int(round(max(x_range, y_range) * 1.5)),
        Int(round(max(x_range, y_range) * 1.5)),
        Int(round(z_range * 1.5)),
    )
    if img_ == nothing
        return nothing
    end
    img_ = WarpedView(img_, trfm)
    return img_crop(img_, Int.(floor.(center(img_))), x_range, y_range, z_range)
end

function img_crop(img, coord, x_range, y_range, z_range)
    checkbounds(Bool, img, coord[1] - x_range, coord[2] - y_range, coord[3] - z_range) ||
        return nothing
    checkbounds(Bool, img, coord[1] + x_range, coord[2] + y_range, coord[3] + z_range) ||
        return nothing
    img_window = img[
        coord[1]-x_range:coord[1]+x_range,
        coord[2]-y_range:coord[2]+y_range,
        coord[3]-z_range:coord[3]+z_range,
    ]
    return img_window
end

function beadstest(
    img,
    filename::AbstractString,
    path::AbstractString,
    ow::Bool = false,
    REALM::Bool = false,
    debug_mode::Bool = false,
    fitting_method = 1;
    kwargs...,
)
    x_width = []
    y_width = []
    z_width = []
    p = []
    r = []

    # Process image to 3d translate real world x-y-z
    img_r = REALM ? pipeline2(img; z_set = 3) : img
    filtered = zeros(axes(img_r))

    #ro = imfilter(img_r,kernel)

    # Find local maxima for beads
    # beads = findlocalmaxima(img_r)
    # select = img_r[beads] .> mean(img_r) + 3 * std(img_r)
    # @show(size(beads[select]), mean(img_r) + 3 * std(img_r))

    if ow
        dct = record_points(@sprintf("%s_psf.csv", filename), img_r; overwrite = ow)
    end

    beads = split.(readlines(@sprintf("%s_psf.csv", filename)), ",")

    ori = parse.(Int64, beads[1])
    range = 10
    # Run through all identified local maximum point
    #@showprogress @sprintf("Filtering of Record %s...", filename) 
    Threads.@threads for i = 2:length(beads)
        if debug_mode && Bool(length(findall(x -> x == i, black_list)))
            continue
        end
        coord = beads[i]
        coord = parse.(Int64, coord)
        img_window = img_crop(img_r, coord, range, range, range)
        if img_window == nothing
            continue
        end
        replace!(img_window, NaN => 0.0)

        img_x, img_y, img_z = axis_crop(img_window, range)
        
        # Calculate shift
        x_shift = findfirst(i -> i .> median(cumsum(img_x)), cumsum(img_x))
        y_shift = findfirst(i -> i .> median(cumsum(img_y)), cumsum(img_y))
        z_shift = findfirst(i -> i .> median(cumsum(img_z)), cumsum(img_z))

        # Crop new window
        coord = [coord[1] + x_shift, coord[2] + y_shift, coord[3] + z_shift]
        if fitting_method == 3 
            img_window = img_crop(img_r, coord, range, range, range)
        else
            img_window = img_rot(img_r, coord, ori, range, range, range)
        end
        if img_window == nothing
            continue
        end
        replace!(img_window, NaN => 0.0)

        debug[] = deepcopy(coord)

        if fitting_method == 1
            img_x, img_y, img_z = axis_crop(img_window, range)
            #fwhm fitting version
            x_params = fwhm(img_x)
            y_params = fwhm(img_y)
            z_params = fwhm(img_z)

        elseif fitting_method == 2
            img_x, img_y, img_z = axis_crop(img_window, range)
            x_res = gauss_line_fit(img_x; g_abstol = 1e-14)
            y_res = gauss_line_fit(img_y; g_abstol = 1e-14)
            z_res = gauss_line_fit(img_z; g_abstol = 1e-14)

            x_params = Optim.minimizer(x_res)
            y_params = Optim.minimizer(y_res)
            z_params = Optim.minimizer(z_res)

        elseif fitting_method == 3
            n = 1.33
            lambda = 0.53
            NA = 0.5
            Z_orders = 14
            pixel_spacing = [0.49, 0.49, 3]

            img_g = zeros(size(img_window))
            img_g[range-1:range, range-3:range+2, range-1:range] .= 1.0
            initial_param = pd_density.InitialParam(n, NA, lambda, Z_orders, pixel_spacing)
            result = zernike_img_fit(img_window, initial_param; F = img_g, g_abstol = 1e-14)

            params = Optim.minimizer(result)
            x_params = y_params = z_params = params
            maximum(params) > 1000.0 ? continue : push!(p, params)
            open(@sprintf("%s_fitting.csv", filename), "a") do f
                println(f, "$coord, $params")
            end

        end

        a = x_params[2]
        b = y_params[2]
        c = z_params[2]
        #if a > 1000 || b > 1000 || c > 1000 || a <= 0.01 || b <= 0.01 || c <= 0.01 || isnan(a)
        #    debug_mode ? error([i,a,b,c]) : continue
        #end
        push!(x_width, a)
        push!(y_width, b)
        push!(z_width, c)
        push!(r, xy2rthe(coord, ori)[1])

        x_ = Int(floor(x_params[2]))
        y_ = Int(floor(y_params[2]))
        z_ = Int(floor(z_params[2]))

        @show(coord)

        checkbounds(Bool, img_r, coord[1] - x_, coord[2] - y_, coord[3] - z_) || continue
        checkbounds(Bool, img_r, coord[1] + x_, coord[2] + y_, coord[3] + z_) || continue

        filtered[
            coord[1]-x_:coord[1]+x_,
            coord[2]-y_:coord[2]+y_,
            coord[3]-z_:coord[3]+z_,
        ] = img_r[coord[1]-x_:coord[1]+x_, coord[2]-y_:coord[2]+y_, coord[3]-z_:coord[3]+z_]

    end
    filtered .-= minimum(filtered)
    filtered = Gray.(convert(Array{N0f16}, OffsetArrays.no_offset_view(filtered)))

    img_save(filtered, path, @sprintf("%s-fi.tif", filename))
    #@show(mean(x_width),mean(y_width),mean(z_width))
    return x_width, y_width, z_width, p, r
end

function supportfunc(x_width, y_width, p_axis, img)

    boxrange = 70
    # data convert for plotting
    x_ = convert(Array{Float32,1}, x_width)
    y_ = convert(Array{Float32,1}, y_width)
    y_box = [Vector{Float64}() for _ = 1:boxrange]
    p_ = [Vector{Float64}() for _ = 1:maximum(p_axis)]

    # group x data
    for i = 1:size(x_, 1)
        push!(p_[p_axis[i]], x_[i])
        push!(y_box[Int(ceil(x_[i]))], y_[i])
    end

    xy_ = zeros(boxrange, 1)
    xy_e = zeros(boxrange, 1)
    for i = 1:boxrange
        if size(y_box, 1) != 0
            xy_[i] = mean(y_box[i])
            xy_e[i] = std(y_box[i])
        end
    end

    #scene_xy = Scene()
    #GLMakie.scatter!(scene_xy,x_,y_)
    #scene_xy = Plots.plot(x_,y_,seriestype = :scatter)
    #scene_box = Plots.plot(1:boxrange,xy_,yerror=xy_e)

    xp_ = zeros(maximum(p_axis), 1)
    for i = 1:maximum(p_axis)
        if size(p_[i], 1) != 0
            xp_[i] = Int(round(mean(p_[i])))
        end
    end

    #scene_xp = Plots.plot(1:maximum(p_axis),vec(xp_),axis = (limits = (1, maximum(p_axis), 1, 20),))
    #return scene_xy,scene_box, scene_xp
    return xy_, xy_e, xp_
end
