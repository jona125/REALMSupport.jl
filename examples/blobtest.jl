using Images, GLMakie, Statistics, ProgressMeter, Printf, Plots, FileIO, REALMSupport
#include("gauss_fit.jl")

function blobtest(data)
    img = load(data)
    open(@sprintf("%s.txt", data), "w") do io
        write(io, "x  y  p  positions\n")
        x_width = []
        y_width = []
        p_axis = []
        peak = []
        scene = Scene()
        scene



        #sl = 38
        for sl = 1:size(img, 3)
            slice = img[:, :, sl]

            img_gray = convert(Array{Float64,2}, Gray.(slice))

            beads = findlocalmaxima(ro)
            select = ro[beads] .> mean(ro) + 3 * std(ro)

            GLMakie.plot!(scene, img_gray)


            @showprogress @sprintf("Fitting slice %s...", sl) for coord in beads[select]
                if coord[1] < 6 ||
                   coord[2] < 6 ||
                   size(img, 1) - coord[1] < 6 ||
                   size(img, 2) - coord[2] < 6
                    continue
                end
                img_window = img_gray[coord[1]-5:coord[1]+5, coord[2]-5:coord[2]+5]
                img_x = mean(img_window, dims = 1)
                x_params = gauss_fit(vec(img_x))

                img_y = mean(img_window, dims = 2)
                y_params = gauss_fit(vec(img_y))

                a = x_params[2]
                b = y_params[2]
                if a > 20 || b > 20 || a < 0 || b < 0
                    continue
                end
                if (x_params[1] + y_params[1]) / 2 < mean(img) + 3 * std(img)
                    continue
                end
                push!(x_width, a)
                push!(y_width, b)
                push!(p_axis, coord[1])
                write(io, @sprintf("%d  %d  %d\n", a, b, coord[1]))
                push!(peak, (x_params[1] + y_params[1]) / 2)


                e_x = collect(range(-a, a, length = 100))
                e_y = [b * sqrt(1 - t^2 / a^2) for t in e_x]
                append!(e_y, [-b * sqrt(1 - t^2 / a^2) for t in e_x])
                append!(e_x, e_x)
                e_x .+= coord[2]
                e_y .+= coord[1]

                GLMakie.scatter!(scene, e_y, e_x, markersize = 1, color = :red)
            end
        end
        return x_width, y_width, p_axis, scene
    end
end

function supportfunc(x_width, y_width, p_axis)
    # data convert for plotting
    x_ = convert(Array{Float32,1}, x_width)
    y_ = convert(Array{Float32,1}, y_width)
    y_box = [Vector{Float64}() for _ = 1:20]
    p_ = [Vector{Float64}() for _ = 1:size(img, 1)]

    # group x data
    for i = 1:size(x_, 1)
        push!(p_[p_axis[i]], x_[i])
        push!(y_box[Int(round(x_[i]))], y_[i])
    end

    xy_ = zeros(20, 1)
    for i = 1:20
        if size(y_box, 1) != 0
            xy_[i] = mean(y_box[i])
        end
    end

    scene_xy = Scene()
    GLMakie.scatter!(scene_xy, x_, y_)
    #Plots.plot(1:20,xy_)

    xp_ = zeros(size(img, 1), 1)
    for i = 1:size(img, 1)
        if size(p_[i], 1) != 0
            xp_[i] = Int(round(mean(p_[i])))
        end
    end

    scene_xp =
        Plots.plot(1:size(img, 1), vec(xp_), axis = (limits = (1, size(img, 1), 1, 20),))
    return scene_xy, scene_xp
end
