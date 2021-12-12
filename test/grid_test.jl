

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
end
