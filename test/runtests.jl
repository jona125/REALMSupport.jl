using REALMSupport.grid_fun, REALMSupport.gauss_fit
using Test

@testset "Grid diameter identify" begin
        l=12
        p=66

        img = zeros(1,500)
        for i in 20:length(img)
                if(mod(i,p)<l)
                        img[i] = 1
                end
        end


        img1 = img + rand(1:500,1,500)/2500

        img2 = zeros(1,500)
        for i in 20:length(img)
                img2[i] = (img[i-4]+img[i-3]+img[i-2]+img[i-1]+img[i])/5
        end

        img3 = img2 + rand(1:500,1,500)/2500

        # sharp grids
        stript,space = grid_resolution(img)
        @test stript ≈ l atol = 1
        @test space ≈ p atol = 1

        # sharp grids with random
        stript,space = grid_resolution(img1)
        @test stript ≈ l atol = 1
        @test space ≈ p atol = 1

        # moving average grids window 5
        stript,space = grid_resolution(img2)
        @test stript ≈ l+2 atol = 1
        @test space ≈ p atol = 1

        # moving average grids window 5 with random
        stript,space = grid_resolution(img3)
        @test stript ≈ l+2 atol = 1
        @test space ≈ p atol = 1
end;


@testset "Gaussian fitting" begin
        tgt_peak = 1e-4
        tgt_sigma = 3
        input_length = 12


        # gaussian distribution fitting
        X = tgt_peak * [exp(-(t-input_length/2)^2/(2*tgt_sigma^2)) for t = 1:input_length]
        params = Gauss_line_fit(X)
        @test abs(params[1] - tgt_peak) / tgt_peak < 1
        @test params[2] ≈ tgt_sigma atol = 0.5

        # gaussian distribution fitting with random added
        X_r = X + rand(input_length)*tgt_peak*0.01
        params = Gauss_line_fit(X_r)
        @test abs(params[1] - tgt_peak) / tgt_peak < 1
        @test params[2] ≈ tgt_sigma atol = 0.5


        tgt_sigma = 10
        # gaussian distribution fitting wide shape
        X = tgt_peak * [exp(-(t-input_length/2)^2/(2*tgt_sigma^2)) for t = 1:input_length]
        params = Gauss_line_fit(X)
        @test abs(params[1] - tgt_peak) / tgt_peak < 1
        @test params[2] ≈ tgt_sigma atol = 0.5


        # wide gaussian distribution fitting with random added
        X_r = X + rand(input_length)*tgt_peak*0.01
        params = Gauss_line_fit(X_r)
        @test abs(params[1] - tgt_peak) / tgt_peak < 1
        @test params[2] ≈ tgt_sigma atol = 0.5


        tgt_sigma = 1
        # gaussian distribution fitting wide shape
        X = tgt_peak*[exp(-(t-input_length/2)^2/(2*tgt_sigma^2)) for t in 1:input_length]
        params = Gauss_line_fit(X)
        @test abs(params[1] - tgt_peak) / tgt_peak < 1
        @test params[2] ≈ tgt_sigma atol = 0.5

        # wide gaussian distribution fitting with random added
        X_r = X + rand(input_length)*tgt_peak*0.01
        params = Gauss_line_fit(X_r)
        @test abs(params[1] - tgt_peak) / tgt_peak < 1
        @test params[2] ≈ tgt_sigma atol = 0.5

        tgt_sigma = 15
        # gaussian distribution fitting over range
        X = tgt_peak*[exp(-(t-input_length/2)^2/(2*tgt_sigma^2)) for t in 1:input_length]
        params = Gauss_line_fit(X)
        @test abs(params[1] - tgt_peak) / tgt_peak < 1
        @test params[2] ≈ tgt_sigma atol = 0.5


        # wide gaussian distribution fitting with random added
        X_r = X + rand(input_length)*tgt_peak*0.01
        params = Gauss_line_fit(X_r)
        @test abs(params[1] - tgt_peak) / tgt_peak < 1
        @test params[2] ≈ tgt_sigma atol = 0.5


        # delta function fitting
        X_d = zeros(1,input_length)
        X_d[Int(input_length/2)] = 1
        params = Gauss_line_fit(vec(X_d))
        @test params[1] ≈ 1 atol = 0.5
        @test params[2] ≈ 0 atol = 0.5

        # flat signal fitting
        X_f = ones(1,input_length)
        params = Gauss_line_fit(vec(X_f))
        @test params[1] ≈ 1 atol = 0.5
        @test params[2] > input_length
end;

