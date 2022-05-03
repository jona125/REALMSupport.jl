using Images, ImageSegmentation, Statistics, ProgressMeter, Printf, FileIO
using CoordinateTransformations, Rotations, OffsetArrays, Optim, FFTW
using REALMSupport
kernel = Kernel.gaussian((5, 5, 5))
FFTW.set_num_threads(16)

function beadstest(img, filename)
    x_width = []
    y_width = []
    z_width = []
    p_axis = []
    #peak = []

    (x, y, z) = size(img)
    filtered = zeros(x, y, z)

    M = [
        -0.140292 -0.0912973 1.13447
        -0.0273906 -0.940779 -0.0213417
        -1.00816 0.0545783 0.161258
    ]
    v = [0.0, 0.0, 0.0]
    rot = AffineMap(M, v)
    #tilt = LinearMap(RotY(-0.19))
    img_r = warp(img, rot)
    #img_r = warp(img,tilt)
    filtered = warp(filtered, rot)

    #ro = imfilter(img_r,kernel)

    replace!(img_r, NaN => 0)

    beads = findlocalmaxima(img_r)
    select = img_r[beads] .> mean(img_r) + 2 * std(img_r)
    @show(size(beads[select]), mean(img_r) + 1 * std(img_r))

    @showprogress @sprintf("Filtering of Record %s...", filename) for coord in beads[select]
        checkbounds(Bool, img_r, coord[1] - 10, coord[2] - 30, coord[3] - 10) || continue
        checkbounds(Bool, img_r, coord[1] + 10, coord[2] + 30, coord[3] + 10) || continue
        img_window =
            img_r[coord[1]-10:coord[1]+10, coord[2]-30:coord[2]+30, coord[3]-10:coord[3]+10]
        img_x = OffsetArray(vec(mean(mean(img_window, dims = 3), dims = 2)), -10:10)
        x_res = gauss_line_fit(img_x; g_abstol = 1e-14)

        img_y = OffsetArray(vec(mean(mean(img_window, dims = 3), dims = 1)), -30:30)
        y_res = gauss_line_fit(img_y; g_abstol = 1e-14)

        img_z = OffsetArray(vec(mean(mean(img_window, dims = 2), dims = 1)), -10:10)
        z_res = gauss_line_fit(img_z; g_abstol = 1e-14)

        x_params = Optim.minimizer(x_res)
        y_params = Optim.minimizer(y_res)
        z_params = Optim.minimizer(z_res)

        a = x_params[2]
        b = y_params[2]
        c = z_params[2]
        if a > 50 || b > 50 || c > 50 || a < 0 || b < 0 || c < 0
            continue
        end
        #if (x_params[1]+y_params[1]+z_params[1])/3 < mean(img_r) + 3*std(img_r)
        #	continue
        #end
        push!(x_width, a)
        push!(y_width, b)
        push!(z_width, c)
        push!(p_axis, coord[2])
        #push!(peak,(x_params[1]+y_params[1])/2)
        @show(x_params[2], y_params[2], z_params[2], coord)

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
    replace!(filtered, NaN => 0)
    img3 = Gray.(convert(Array{N0f16}, OffsetArrays.no_offset_view(filtered)))
    img4 = Gray.(convert.(Normed{UInt16,16}, img3))

    img_save(img4, "/home/jchang/image/result/", @sprintf("%s-fi.tif", filename))
    @show(mean(x_width), mean(y_width), mean(z_width))
    return x_width, y_width, z_width, p_axis
end

function supportfunc(x_width, y_width, p_axis, img)

    boxrange = 50
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
    for i = 1:boxrange
        if size(y_box, 1) != 0
            xy_[i] = mean(y_box[i])
        end
    end

    scene_xy = Scene()
    #GLMakie.scatter!(scene_xy,x_,y_)
    scene_xy = Plots.plot(x_, y_, seriestype = :scatter)
    scene_box = Plots.plot(1:boxrange, xy_)

    xp_ = zeros(maximum(p_axis), 1)
    for i = 1:maximum(p_axis)
        if size(p_[i], 1) != 0
            xp_[i] = Int(round(mean(p_[i])))
        end
    end

    scene_xp = Plots.plot(
        1:maximum(p_axis),
        vec(xp_),
        axis = (limits = (1, maximum(p_axis), 1, 20),),
    )
    return scene_xy, scene_box, scene_xp
end
