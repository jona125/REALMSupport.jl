using REALMSupport.RegisterCore: CenterIndexedArray
using RegisterMismatch

@testset "Translation function test" begin
    outer = reshape(1:480, 24, 20)
    A = outer[1:16, 3:18]
    B = outer[3:18, 2:17]
    C = outer[5:20, 1:16]

    mm = CenterIndexedArray(zeros(11, 11, 3))
    mm_r = zeros(2,3)
    mm[:, :, -1] = translate(A, A, (5, 5))
    mm_r[:, 1] .= Tuple(register_translate(A, A, (5, 5)))
    mm[:, :, 0] = translate(A, B, (5, 5))
    mm_r[:, 2] .= Tuple(register_translate(A, B, (5, 5)))
    mm[:, :, 1] = translate(A, C, (5, 5))
    mm_r[:, 3] .= Tuple(register_translate(A, C, (5, 5)))

    move = [0 2 4; 0 0 0]
    matrix = Float64.(zeros(4))
    result = translate_optim(mm, matrix, move; g_abstol = 1e-14)

    @test minimum(result) < 1e-3
    @test reshape(Optim.minimizer(result), 2, 2) * move ≈ mm_r rtol = 1e-4
    #display(reshape(Optim.minimizer(result), 2, 2))
   
    # test none diagonal matrix
    move = [0 0 0; 0 0.5 1]
    matrix = Float64.(zeros(4))
    result = translate_optim(mm, matrix, move; g_abstol = 1e-14)

    @test minimum(result) < 1e-3
    @test reshape(Optim.minimizer(result), 2, 2) * move ≈ mm_r rtol = 0.5


    #3d translation test
    outer = reshape(1:9600, 24, 20, 20)
    A = outer[3:16, 7:12, 10:14]
    B = outer[5:18, 7:12, 10:14]
    C = outer[7:20, 7:12, 10:14]
    D = outer[3:16, 6:11, 10:14]
    E = outer[3:16, 5:10, 10:14]
    F = outer[3:16, 7:12, 11:15]
    G = outer[3:16, 7:12, 12:16]

    mm = CenterIndexedArray(zeros(15, 15, 15, 7))
    mm_r = zeros(3, 7)
    mm[:, :, :, -3] = translate(A, A, (7, 7, 7))
    mm_r[:, 1] .= Tuple(register_translate(A, A, (7, 7, 7)))
    mm[:, :, :, -2] = translate(A, B, (7, 7, 7))
    mm_r[:, 2] .= Tuple(register_translate(A, B, (7, 7, 7)))
    mm[:, :, :, -1] = translate(A, C, (7, 7, 7))
    mm_r[:, 3] .= Tuple(register_translate(A, C, (7, 7, 7)))
    mm[:, :, :, 0] = translate(A, D, (7, 7, 7))
    mm_r[:, 4] .= Tuple(register_translate(A, D, (7, 7, 7)))
    mm[:, :, :, 1] = translate(A, E, (7, 7, 7))
    mm_r[:, 5] .= Tuple(register_translate(A, E, (7, 7, 7)))
    mm[:, :, :, 2] = translate(A, F, (7, 7, 7))
    mm_r[:, 6] .= Tuple(register_translate(A, F, (7, 7, 7)))
    mm[:, :, :, 3] = translate(A, G, (7, 7, 7))
    mm_r[:, 7] .= Tuple(register_translate(A, G, (7, 7, 7)))


    move = [0 1 2 0 0 0 0; 0 0 0 1 2 0 0; 0 0 0 0 0 1 2]
    matrix = Float64.(zeros(9))
    result = translate_optim(mm, matrix, move; g_abstol = 1e-8)

    @test minimum(result) < 1e-3
    @test reshape(Optim.minimizer(result), 3, 3) * move ≈ mm_r rtol = 0.5
    #display(reshape(Optim.minimizer(result), 3, 3))
end
