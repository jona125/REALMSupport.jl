
export gauss_line_fit

function gaussclossure(X::AbstractVector)
    function gaussloss(params)
        b, a, σ = params[1], params[2], params[3]
        x = a * [exp(-(t)^2 / (2 * σ^2)) for t in axes(X, 1)]
        x .+= b
        return sum(abs2, x - X)
    end
    return gaussloss
end

function gauss_line_fit(X::AbstractVector; kwargs...)
    f = gaussclossure(X)
    mX = minimum(X)
    sX = sum(X .- mX)
    σ² = sum(i^2 * (X[i] .- mX) for i in axes(X, 1)) / sX
    σ = sqrt(max(σ², oftype(σ², 1e-4)))  # σ >= 0.01 since we only have integer-scale resolution
    params = [mX, sX / (σ * sqrt(2π)), σ]

    #result = optimize(f, params, Newton(), Optim.Options(; kwargs...); autodiff = :forward)
    result = optimize(f, params, BFGS(), Optim.Options(; kwargs...))
    Optim.converged(result) || @warn "Optimization failed to converge"
    return result
    #return Optim.minimizer(result)
end
