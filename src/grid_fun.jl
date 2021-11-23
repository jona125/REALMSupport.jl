module GridFun

INITIAL_FLAG = 1 == 1

using Statistics
export fwhm, grid_resolution, grid_slice

function fwhm(data,b_mean,b_std)
	half_value = b_mean + 2*b_std
	peak = findall(data.>half_value)       
	if(length(peak)<=5)
		return 0,0
	end
	return (peak[end][1] - peak[1][1]), (peak[end][1] + peak[1][1])/2 #findmid(data)
end

function grid_resolution(data)
	# Input (mean cross section , mean background)
	# Output (mean band tickness, mean space tickness)
	diff_l = data[4:end] - data[1:end-3]
	b_mean = mean(abs.(diff_l))
	b_std = std(abs.(diff_l))
	peak = findall(abs.(diff_l).>b_mean+b_std)
	flag = diff_l[peak[1]] > 0 ? 1 : 0
	prev = peak[1]
	space, stript, count = 0, 0, 0
	for idx in peak
		if flag == 0 && diff_l[idx] > 0
			space += idx - prev
			flag = 1
			prev = idx
		end
		if flag == 1 && diff_l[idx] < 0
			stript += idx - prev
			flag = 0
			prev = idx
			count += 1
		end
	end
	return stript/count, space/(count-1)
end

function grid_slice(img)
	img = convert(Array{N0f16}, img)
	b_mean = mean(img)
	flag = Bool.(INITIAL_FLAG)
	width_temp = []
	pos_temp = []
	stript_temp = []
	space_temp = []
	frame = 1
	# loop through every frame
	for i in 5:size(img,3)
		img1 = img[:,:,i]
		line = mean(img1,dims=2)
		b_std = std(line)
		# skip frames without signal
		if(b_std > b_mean/1) 
			if(flag == INITIAL_FLAG)
				flag = !flag
				frame = i
			end
			continue 
		end
		# take moving average in line signal
		new_line = zeros(size(line,1),1)
		for i in 5:size(line,1)
			new_line[i] = mean(line[i-4:i])
		end
		# calculate image signal range
		(width , mid) = fwhm(new_line,b_mean,b_std)
		# analysis resolution
	#	img_l = mean(img1,dims=1)[1,:,1]
	#	if width != 0
	#		stript_width, space_width = grid_resolution(img_l)
	#	else
	#		stript_width, space_width = (0,0)
	#	end
		width != 0 && push!(width_temp,width)
		mid != 0 && push!(pos_temp,mid)
	end
	img_l = mean(mean(img,dims=3),dims=1)[1,:,1]
	stript_width , space_width = grid_resolution(img_l)
	if isempty(width_temp)
		width_temp = 0
	end
	if isempty(pos_temp)
		pos_temp = 0
	end
	return width_temp,pos_temp, frame, stript_width, space_width
end

end
