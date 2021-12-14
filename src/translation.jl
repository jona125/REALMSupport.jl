
export translate, translate_optim

function checkoffsetbound(matrix, idx)
    for i in size(idx,1)
        if abs(idx[i]) < abs(bounds(matrix)[i][1])
            return false
        end
    end
    return true
end

function translationclossure(mm::AbstractArray{T,N},movement) where {T,N}
    function translation_loss(matrix)
        dims = N-1
        c = reshape(matrix,dims,dims) * movement
        #c .+= (size(mm,1)+1)/2
        loss = zero(eltype(mm))
        for i in size(c,2)
            idx = Vector{T}(c[:,i])
            checkoffsetbound(mm,idx) || return typemax(eltype(loss))
            loss += mm[idx...,i]
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


function translate_optim(mm::AbstractArray{T,N}, initial_matrix, movement; kwargs...) where {T,N}
    shift = Int((size(mm,1)-1)/2)
    mm = OffsetArray(mm,-shift:shift,-shift:shift,1:size(mm,N))
	itp_mm = interpolate(mm, BSpline(Quadratic(Free(OnGrid()))))
	f = translationclossure(itp_mm,movement)
    result = optimize(f, initial_matrix, LBFGS(), Optim.Options(; kwargs...))
    Optim.converged(result) || @warn "Optimization failed to converge"
	return result
end
