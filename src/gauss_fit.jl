
export gauss_line_fit

function gaussclossure(X::AbstractVector)
	function gaussloss(params)
		a, σ = params[1], params[2]
		x = a * [exp(-(t)^2/(2*σ^2)) for t in axes(X,1)]
		return sum(abs2, x - X)
	end
	return gaussloss
end

function gauss_line_fit(X::AbstractVector; kwargs...)
	f = gaussclossure(X)
	sX = sum(X)
	σ² = sum(i^2 * X[i] for i in axes(X,1))/sX
	σ  = sqrt(max(σ², oftype(σ², 1e-4)))  # σ >= 0.01 since we only have integer-scale resolution
	params = [sX/(σ*sqrt(2π)), σ]

	result = optimize(f, params, Newton(), Optim.Options(; kwargs...); autodiff=:forward)
	Optim.converged(result) || @warn "Optimization failed to converge"
	return result
	#return Optim.minimizer(result)
end
