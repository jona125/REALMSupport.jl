
export translate, translate_optim

function translationclossure(mm,movement)
        function translation_loss(matrix)
		c = reshape(matrix,2,2) * movement
		c .+= (size(mm,1)+1)/2
		loss = 0
                for i in size(c,2)
			loss += mm[c[1,i],c[2,i],i]
		end
		return loss
        end
        return translation_loss
end

function translate(fixed, moving, maxshift, thresh=nothing)
    mm = RegisterMismatch.mismatch(fixed, moving, maxshift)
    _, denom = RegisterMismatch.separate(mm)
    if thresh==nothing
        thresh = 0.25maximum(denom)
    end
    return [mm[i].num/mm[i].denom for (i,_) in enumerate(mm)]
end


function translate_optim(mm, initial_matrix, movement)
	itp_mm = interpolate(mm, BSpline(Quadratic(Free(OnGrid()))))
	f = translationclossure(itp_mm,movement)
	result = optimize(f, initial_matrix, LBFGS())
	return result
end
