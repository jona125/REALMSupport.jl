
function gauss_test(base_signal, tgt_peak, tgt_sigma, input_length, rand_mag; kwargs...)
    # gaussian distribution fitting
    ax = Base.IdentityUnitRange(-input_length:input_length)
    X = tgt_peak * [exp(-t^2 / (2 * tgt_sigma^2)) for t in ax]
    X = X .+ base_signal
    X =
        X +
        OffsetArray(rand(2 * input_length + 1) .- 0.5, -input_length:input_length) *
        tgt_peak *
        rand_mag
    res = gauss_line_fit(X; kwargs...)
    params = Optim.minimizer(res)
    @show(params)
    @test params[1] ≈ base_signal atol =
        10000 * (rand_mag + sqrt(eps())) * base_signal / sqrt(2 * input_length + 1)
    @test params[2] ≈ tgt_peak atol =
        10000 * (rand_mag + sqrt(eps())) * tgt_peak / sqrt(2 * input_length + 1)
    @test params[3] ≈ tgt_sigma atol =
        10000 * (rand_mag + sqrt(eps())) * tgt_sigma / sqrt(2 * input_length + 1)
end

@testset "Gaussian fitting" begin
    base_signal = 1e-2
    tgt_peak = 1e-4
    tgt_sigma = 3
    input_length = 5


    # gaussian distribution fitting
    gauss_test(base_signal, tgt_peak, tgt_sigma, input_length, 0; g_abstol = 1e-14)

    # gaussian distribution fitting with random added
    gauss_test(base_signal, tgt_peak, tgt_sigma, input_length, 0.03)

    tgt_sigma = 10
    # gaussian distribution fitting wide shape
    gauss_test(base_signal, tgt_peak, tgt_sigma, input_length, 0; g_abstol = 1e-14)

    # wide gaussian distribution fitting with random added
    gauss_test(base_signal, tgt_peak, tgt_sigma, input_length, 0.03)


    tgt_sigma = 1
    # gaussian distribution fitting wide shape
    gauss_test(base_signal, tgt_peak, tgt_sigma, input_length, 0; g_abstol = 1e-14)


    # wide gaussian distribution fitting with random added
    gauss_test(base_signal, tgt_peak, tgt_sigma, input_length, 0.03)

    tgt_sigma = 15
    # gaussian distribution fitting over range
    gauss_test(base_signal, tgt_peak, tgt_sigma, input_length, 0; g_abstol = 1e-14)

    # wide gaussian distribution fitting with random added
    gauss_test(base_signal, tgt_peak, tgt_sigma, input_length, 0.03)

    # delta function fitting
    X_d = zeros(1, 2 * input_length + 1)
    X_d = OffsetArray(vec(X_d), -input_length:input_length)
    X_d[0] = 1
end
