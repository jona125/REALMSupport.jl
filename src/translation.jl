
export translate, translate_optim

function translationclossure(mm, movement)
    function translation_loss(matrix)
        c = reshape(matrix, 2, 2) * movement
        c .+= (size(mm, 1) + 1) / 2
        loss = zero(eltype(mm))
        for i in size(c, 2)
            idx1, idx2 = c[1, i], c[2, i]
            checkbounds(Bool, mm, idx1, idx2, i) || return typemax(loss)
            loss += mm[idx1, idx2, i]
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
