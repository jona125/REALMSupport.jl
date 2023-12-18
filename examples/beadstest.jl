using Images, ImageSegmentation, Statistics, ProgressMeter, Printf, FileIO
using CoordinateTransformations, Rotations, OffsetArrays, Optim, FFTW
using REALMSupport
kernel = Kernel.gaussian((5,5,5))
FFTW.set_num_threads(4)

function beadstest(img, filename, path,ow)
    x_width = []
    y_width = []
    z_width = []

    (x, y, z) = size(img)

    # Process image to 3d translate real world x-y-z
    img_r = pipeline2(img; z_set = 2)
    filtered = zeros(axes(img_r))
    
    #ro = imfilter(img_r,kernel)
    
    replace!(img_r, NaN=>0)


    # Find local maxima for beads
   # beads = findlocalmaxima(img_r)
   # select = img_r[beads] .> mean(img_r) + 3 * std(img_r)
   # @show(size(beads[select]), mean(img_r) + 3 * std(img_r))
    
    if ow
        dct = record_points(@sprintf("%s_psf.csv",filename),img_r;overwrite = ow)
    end

    beads = split.(readlines(@sprintf("%s_psf.csv",filename)),",")

    # Run through all identified local maximum point
    @showprogress @sprintf("Filtering of Record %s...", filename) for coord in beads#[select]
        coord = parse.(Int64,coord)
        checkbounds(Bool, img_r, coord[1] - 10, coord[2] - 10, coord[3] - 10) || continue
        checkbounds(Bool, img_r, coord[1] + 10, coord[2] + 10, coord[3] + 10) || continue
        img_window =
            img_r[coord[1]-10:coord[1]+10, coord[2]-10:coord[2]+10, coord[3]-10:coord[3]+10]

        # Gaussian fitting in three axis
        img_x = OffsetArray(vec(mean(mean(img_window, dims = 3), dims = 2)), -10:10)
        x_res = gauss_line_fit(img_x; g_abstol = 1e-14)

        img_y = OffsetArray(vec(mean(mean(img_window, dims = 3), dims = 1)), -10:10)
        y_res = gauss_line_fit(img_y; g_abstol = 1e-14)

        img_z = OffsetArray(vec(mean(mean(img_window, dims = 2), dims = 1)), -10:10)
        z_res = gauss_line_fit(img_z; g_abstol = 1e-14)

        x_params = Optim.minimizer(x_res)
		y_params = Optim.minimizer(y_res)		
        z_params = Optim.minimizer(z_res)

		a = x_params[2]
		b = y_params[2]
        c = z_params[2]
		#if a > 20 || b > 20 || c > 4 || a <= 0.01 || b <= 0.01|| c <= 0.01
		#	continue
		#end
		push!(x_width,a)
	    push!(y_width,b)
        push!(z_width,c)

        x_ = Int(floor(x_params[2]))
        y_ = Int(floor(y_params[2]))
        z_ = Int(floor(z_params[2]))
	
        checkbounds(Bool,img_r,coord[1]-x_,coord[2]-y_,coord[3]-z_) || continue
        checkbounds(Bool,img_r,coord[1]+x_,coord[2]+y_,coord[3]+z_) || continue

        filtered[coord[1]-x_:coord[1]+x_,coord[2]-y_:coord[2]+y_,coord[3]-z_:coord[3]+z_] = img_r[coord[1]-x_:coord[1]+x_,coord[2]-y_:coord[2]+y_,coord[3]-z_:coord[3]+z_]
		
	end
    replace!(filtered, NaN=>0)
    filtered .-= minimum(filtered)
    filtered = Gray.(convert(Array{N0f16}, OffsetArrays.no_offset_view(filtered)))

    img_save(img4,path,@sprintf("%s-fi.tif",filename))
    #@show(mean(x_width),mean(y_width),mean(z_width))
    return x_width, y_width, z_width
end

function supportfunc(x_width,y_width,p_axis,img)

    boxrange = 60
	# data convert for plotting
	x_ = convert(Array{Float32,1},x_width)
	y_ = convert(Array{Float32,1},y_width)
    y_box = [Vector{Float64}() for _ in 1:boxrange]
	p_ = [Vector{Float64}() for _ in 1:maximum(p_axis)]
	
	# group x data
	for i in 1:size(x_,1)
		push!(p_[p_axis[i]], x_[i])
		push!(y_box[Int(ceil(x_[i]))], y_[i])
	end
	
	xy_ = zeros(boxrange,1)
    xy_e = zeros(boxrange,1)
	for i in 1:boxrange
		if size(y_box,1) != 0
			xy_[i] = mean(y_box[i])
            xy_e[i] = std(y_box[i])
		end
	end
	
	#scene_xy = Scene()
	#GLMakie.scatter!(scene_xy,x_,y_)
    #scene_xy = Plots.plot(x_,y_,seriestype = :scatter)
	#scene_box = Plots.plot(1:boxrange,xy_,yerror=xy_e)
	
	xp_ = zeros(maximum(p_axis),1)
	for i in 1:maximum(p_axis)
		if size(p_[i],1) != 0
			xp_[i] = Int(round(mean(p_[i])))
		end
	end
	
	#scene_xp = Plots.plot(1:maximum(p_axis),vec(xp_),axis = (limits = (1, maximum(p_axis), 1, 20),))
	#return scene_xy,scene_box, scene_xp
    return xy_,xy_e,xp_
end


