using Images, ImageSegmentation, Statistics, ProgressMeter, Printf, FileIO
using CoordinateTransformations, Rotations, OffsetArrays, Optim, FFTW
using REALMSupport
kernel = Kernel.gaussian((5, 5, 5))
FFTW.set_num_threads(4)

function beadstest(img, filename, path)
    x_width = []
    y_width = []
    z_width = []

    (x, y, z) = size(img)

    # Process image to 3d translate real world x-y-z
    img_r = pipeline2(img; z_set = 1)
    filtered = zeros(axes(img_r))
    replace!(img_r, NaN => 0)

    beads = findlocalmaxima(img_r)
    select = img_r[beads] .> mean(img_r) + std(img_r)
    @show(size(beads[select]), mean(img_r) + std(img_r))


    # Run through all identified local maximum point
    @showprogress @sprintf("Filtering of Record %s...", filename) for coord in beads[select]
        checkbounds(Bool, img_r, coord[1] - 10, coord[2] - 10, coord[3] - 2) || continue
        checkbounds(Bool, img_r, coord[1] + 10, coord[2] + 10, coord[3] + 2) || continue
        img_window =
            img_r[coord[1]-10:coord[1]+10, coord[2]-10:coord[2]+10, coord[3]-2:coord[3]+2]
        # Filter out noise spots that is small group of signals
        img_m = img_window
        img_m[img_m.>mean(img_r)+std(img_r)] .= 1
        img_m[img_m.!=1] .= 0
        label = label_components(img_m)
        out = component_pixels(label)

        # Gaussian fitting in three axis
        img_x = OffsetArray(vec(mean(mean(img_window, dims = 3), dims = 2)), -10:10)
        x_res = gauss_line_fit(img_x; g_abstol = 1e-14)

        img_y = OffsetArray(vec(mean(mean(img_window, dims = 3), dims = 1)), -10:10)
        y_res = gauss_line_fit(img_y; g_abstol = 1e-14)

        img_z = OffsetArray(vec(mean(mean(img_window, dims = 2), dims = 1)), -2:2)
        z_res = gauss_line_fit(img_z; g_abstol = 1e-14)

        x_params = Optim.minimizer(x_res)
        y_params = Optim.minimizer(y_res)
        z_params = Optim.minimizer(z_res)


        # Check unrelated fitting results
        a = x_params[2]
        b = y_params[2]
        c = z_params[2]
        if a > 20 || b > 20 || c > 4 || a <= 0.01 || b <= 0.01 || c <= 0.01
            continue
        end

        push!(x_width, a)
        push!(y_width, b)
        push!(z_width, c)

        # Update filtered image with beads contained and filter out extra pixels
        x_ = Int(floor(x_params[2]))
        y_ = Int(floor(y_params[2]))
        z_ = Int(floor(z_params[2]))

        checkbounds(Bool, img_r, coord[1] - x_, coord[2] - y_, coord[3] - z_) || continue
        checkbounds(Bool, img_r, coord[1] + x_, coord[2] + y_, coord[3] + z_) || continue

        filtered[
            coord[1]-x_:coord[1]+x_,
            coord[2]-y_:coord[2]+y_,
            coord[3]-z_:coord[3]+z_,
        ] = img_r[coord[1]-x_:coord[1]+x_, coord[2]-y_:coord[2]+y_, coord[3]-z_:coord[3]+z_]

    end

    # Saved image and return psf info
    replace!(filtered, NaN => 0)
    filtered .-= minimum(filtered)
    filtered = normal(filtered)
    img3 = Gray.(convert(Array{N0f16}, OffsetArrays.no_offset_view(filtered)))
    img4 = Gray.(convert.(Normed{UInt16,16}, img3))

    img_save(img4, path, @sprintf("%s-fi.tif", filename))
    return x_width, y_width, z_width
end

function supportfunc(x_width, y_width, p_axis, img)

    boxrange = 60
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
