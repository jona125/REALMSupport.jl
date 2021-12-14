export flat_recon

function flat_recon(img,filename,step=9,Save=True)
	img_cut = img

	(x,y,z) = size(img_cut)

	img_re = zeros(z*step,y,Int(floor(x/step)))
	
	@showprogress "Image Reconstruction for Record %s..." for i in 1:z
		for j in 1:Int(floor(x/step))
			#for h in 0:step-1
			img_re[1+(i-1)*step:i*step,:,j] = img_cut[(j-1)*step+1:j*step,:,i]
		end
	end

	if Save
		img_save(img_re,"/home/jchang/image/result/",(@sprintf("%s-.tif", filename)))
	end
	return img_re
end
