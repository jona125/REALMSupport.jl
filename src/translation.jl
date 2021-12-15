
export translate, translate_optim


function translationclossure(mm::AbstractArray{T,N}, movement) where {T,N}
    function translation_loss(matrix)
        dims = N - 1
        c = reshape(matrix, dims, dims) * movement
        #c .+= (size(mm,1)+1)/2
        loss = zero(eltype(mm))
        for (i, j) in enumerate(axes(mm, N))
            idx = c[:, i]
            checkbounds(Bool, mm, idx..., j) || return typemax(eltype(loss))
            loss += mm(idx..., j)
        end
        return loss
    end
    return translation_loss
end

function translate(fixed, moving, maxshift, thresh = nothing)
    mm = RegisterMismatch.mismatch(fixed, moving, maxshift)
    _, denom = RegisterMismatch.separate(mm)
    if thresh == nothing
        thresh = 0.25maximum(denom)
    end
    return RegisterCore.ratio.(mm, thresh, Inf)
end


function translate_optim(
    mm::AbstractArray{T,N},
    initial_matrix,
    movement;
    kwargs...,
) where {T,N}
    itp_mm = interpolate(mm, BSpline(Quadratic(Free(OnCell()))))
    f = translationclossure(itp_mm, movement)
    result = optimize(f, initial_matrix, LBFGS(), Optim.Options(; kwargs...))
    Optim.converged(result) || @warn "Optimization failed to converge"
    return result
end
