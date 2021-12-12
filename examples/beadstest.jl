using Images, ImageSegmentation, GLMakie, Statistics, ProgressMeter, Printf, Plots, FileIO
using CoordinateTransformations, Rotations, OffsetArrays
using REALMSupport.gauss_fit
kernel = Kernel.gaussian((5,5,5))


function beadstest(data)
	img = load(data)
	open(@sprintf("%s.txt",data),"w") do io
        write(io, "x  y  p  positions\n")
	x_width = []
	y_width = []
	p_axis = []
	peak = []
	scene = Scene()
	
	M = [4.0 0.0 0.0;0.0 1.0 0.0;0.0 0.0 1.0]
	v = [0.0, 0.0, 0.0]	
	rot = AffineMap(M,v)
	tilt = LinearMap(RotY(-0.19))
	img_r = warp(img,rot)
	img_r = warp(img_r,tilt)
	
	#img_org = convert(OffsetArray{Float64,3},ro)
	ro = imfilter(img_r,kernel)
	
	beads = findlocalmaxima(ro)
	select = ro[beads] .> mean(img_r) + 3*std(img_r)
	@show beads[select]
	
	img_nor = img_r ./ maximum(img_r)
	GLMakie.volume!(scene,OffsetArrays.no_offset_view(img_nor),algorithm=:mip)
	
			
	for coord in beads[select]
		img_window = img_r[coord[1]-10:coord[1]+10,coord[2]-10:coord[2]+10,coord[3]]
		img_x = OffsetArray(vec(mean(img_window,dims=1)),-10:10)
		x_res = gauss_line_fit(img_x)
	
		img_y = OffsetArray(vec(mean(img_window,dims=2)),-10:10)
	        y_res = gauss_line_fit(img_y)
		
		x_params = Optim.minimizer(x_res)
		y_params = Optim.minimizer(y_res)		

		a = x_params[2]
		b = y_params[2]
		if a > 50 || b > 50 || a < 0 || b < 0
			continue
		end
		if (x_params[1]+y_params[1])/2 < mean(img_r) + 3*std(img_r)
			continue
		end
		push!(x_width,a)
	        push!(y_width,b)
		push!(p_axis,coord[1])
		write(io, @sprintf("%d  %d  %d\n",a,b,coord[1]))
		push!(peak,(x_params[1]+y_params[1])/2)
			
		
		e_x = collect(range(-a,a,length=100))
		e_y = [b*sqrt(1-t^2/a^2) for t in e_x]
		append!(e_y , [-b*sqrt(1-t^2/a^2) for t in e_x])
		append!(e_x,e_x)
		e_x .+= coord[2]
		e_y .+= coord[1]

		GLMakie.scatter!(scene,[coord[1]],[coord[2]],[coord[3]],markersize=10,color=:red)
		#GLMakie.scatter!(scene,e_y,e_x,[coord[3]],markersize=1,color=:red)
	end
	return x_width,y_width,p_axis,scene
	end
end

function supportfunc(x_width,y_width,p_axis,data)
	img = load(data)

	# data convert for plotting
	x_ = convert(Array{Float32,1},x_width)
	y_ = convert(Array{Float32,1},y_width)
	y_box = [Vector{Float64}() for _ in 1:20]
	p_ = [Vector{Float64}() for _ in 1:maximum(p_axis)]
	
	# group x data
	for i in 1:size(x_,1)
		push!(p_[p_axis[i]], x_[i])
		push!(y_box[Int(round(x_[i]))], y_[i])
	end
	
	xy_ = zeros(20,1)
	for i in 1:20
		if size(y_box,1) != 0
			xy_[i] = mean(y_box[i])
		end
	end
	
	scene_xy = Scene()
	GLMakie.scatter!(scene_xy,x_,y_)
	#Plots.plot(1:20,xy_)
	
	xp_ = zeros(maximum(p_axis),1)
	for i in 1:maximum(p_axis)
		if size(p_[i],1) != 0
			xp_[i] = Int(round(mean(p_[i])))
		end
	end
	
	scene_xp = Plots.plot(1:maximum(p_axis),vec(xp_),axis = (limits = (1, maximum(p_axis), 1, 20),))
	return scene_xy,scene_xp
end


