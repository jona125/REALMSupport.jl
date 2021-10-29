using Optim

function gaussclossure(X)
	function gaussloss(params)
		a, σ = params[1], params[2]
		x = a * [exp(-(t-length(X)/2)^2/(2*σ^2)) for t = 1:length(X)]
		return sum(abs2, x - X)
	end
	return gaussloss
end

function gauss_fit(X)
	f = gaussclossure(X)
	lower = [0, 0]
	upper = [1, 100]
	params = [1e-8,0.5]
	#result = optimize(f, params, Fminbox{MomentumGradientDescent}(); iterations = 1000)

	result = optimize(f, params, LBFGS())
	return Optim.minimizer(result)
end

