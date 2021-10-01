using REALMSupport
using Test

@testset "REALMSupport.jl" begin

    # Write your tests here.


function test_grid(data,l,p)
        stript,space = grid_resolution(data)
        return (stript - l, space - p)
end

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


@test (test_grid(img,l,p) .< 1) == (true,true)
@test (test_grid(img1,l,p) .< 1) == (true,true)
@test (test_grid(img2,l+2,p) .<1) == (true,true) 
@test (test_grid(img3,l+2,p) .<1) == (true,true) 
~                                                  

end
