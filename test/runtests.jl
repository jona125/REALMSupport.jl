using REALMSupport.gauss_fit, REALMSupport.grid_fun
using Test, Optim, OffsetArrays

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
        @test space + stript ≈ p atol = 1

        # sharp grids with random
        stript,space = grid_resolution(img1)
        @test stript ≈ l atol = 1
        @test space + stript ≈ p atol = 1

        # moving average grids window 5
        stript,space = grid_resolution(img2)
        @test stript ≈ l atol = 1
        @test space + stript ≈ p atol = 1

        # moving average grids window 5 with random
        stript,space = grid_resolution(img3)
        @test stript ≈ l atol = 1
        @test space + stript ≈ p atol = 1
end;


function gauss_test(tgt_peak,tgt_sigma,input_length,rand_mag)
	# gaussian distribution fitting
	ax = Base.IdentityUnitRange(-input_length:input_length)
        X = tgt_peak * [exp(-t^2/(2*tgt_sigma^2)) for t in ax]
	X = X + OffsetArray(rand(2*input_length+1),-input_length:input_length)*tgt_peak*rand_mag
        res = Gauss_line_fit(X)
	params = Optim.minimizer(res)
        @test params[1] ≈ tgt_peak atol = 1e-5
        @test params[2] ≈ tgt_sigma atol = 1e-5
end

@testset "Gaussian fitting" begin
        tgt_peak = 1e-4
        tgt_sigma = 3
        input_length = 5


        # gaussian distribution fitting
	gauss_test(tgt_peak,tgt_sigma,input_length,0)

        # gaussian distribution fitting with random added
 	gauss_test(tgt_peak,tgt_sigma,input_length,0.03)

        tgt_sigma = 10
        # gaussian distribution fitting wide shape
  	gauss_test(tgt_peak,tgt_sigma,input_length,0)

        # wide gaussian distribution fitting with random added
   	gauss_test(tgt_peak,tgt_sigma,input_length,0.03)


	tgt_sigma = 1
	# gaussian distribution fitting wide shape
	gauss_test(tgt_peak,tgt_sigma,input_length,0)


        # wide gaussian distribution fitting with random added
	gauss_test(tgt_peak,tgt_sigma,input_length,0.03)

        tgt_sigma = 20
        # gaussian distribution fitting over range
	gauss_test(tgt_peak,tgt_sigma,input_length,0)

        # wide gaussian distribution fitting with random added
	gauss_test(tgt_peak,tgt_sigma,input_length,0.03)

        # delta function fitting
        X_d = zeros(1,2*input_length+1)
	X_d = OffsetArray(vec(X_d),-input_length:input_length)
        X_d[0] = 1
        res = Gauss_line_fit(vec(X_d))
	params = Optim.minimizer(res)
        @test params[1] ≈ 1 atol = 1e-5

        # flat signal fitting
        X_f = ones(1,2*input_length+1)
       	X_f = OffsetArray(vec(X_f),-input_length:input_length)
	res = Gauss_line_fit(vec(X_f))
       	params = Optim.minimizer(res)
	@test params[1] ≈ 1 atol = 1e-5
        @test params[2] > input_length
end;

