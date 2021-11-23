module gauss_fit

using Optim, OffsetArrays
export Gauss_line_fit

function gaussclossure(X)
	function gaussloss(params)
		a, σ = params[1], params[2]
		x = a * [exp(-(t)^2/(2*σ^2)) for t in axes(X,1)]
		return sum(abs2, x - X)
	end
	return gaussloss
end

function gauss_line_fit(X)
	f = gaussclossure(X)
	params = [1e-8,0.5]

	result = optimize(f, params, LBFGS())
	Optim.converged(result) || @warn "Optimization failed to converge"
	return result
	#return Optim.minimizer(result)
end
end
