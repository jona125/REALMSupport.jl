using REALMSupport.RegisterCore:CenterIndexedArray

@testset "Translation function test" begin
	outer = reshape(1:480, 24, 20)
	A = outer[1:16,1:16]
	B = outer[3:18,2:17]
	C = outer[5:20,3:18]

    mm = CenterIndexedArray(zeros(11,11,3))
	mm[:,:,-1] = translate(A,A,(5,5))
	mm[:,:,0] = translate(A,B,(5,5))
	mm[:,:,1] = translate(A,C,(5,5))
    
	move = [0 1 2;0 0 0]
	matrix  = Float64[1 0 0 1]
	result = translate_optim(mm,matrix,move; g_abstol=1e-14)

	@test minimum(result) < 1e-3
end


