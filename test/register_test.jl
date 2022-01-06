using REALMSupport.RegisterCore: CenterIndexedArray

@testset "Translation function test" begin
    outer = reshape(1:480, 24, 20)
    A = outer[1:16, 3:18]
    B = outer[3:18, 2:17]
    C = outer[5:20, 1:16]

    mm = CenterIndexedArray(zeros(11, 11, 3))
    mm[:, :, -1] = translate(A, A, (5, 5))
    mm[:, :, 0] = translate(A, B, (5, 5))
    mm[:, :, 1] = translate(A, C, (5, 5))

    move = [0 1 2; 0 0 0]
    matrix = Float64[1 0 0 1]
    result = translate_optim(mm, matrix, move; g_abstol = 1e-14)

    @test minimum(result) < 1e-3
    display(reshape(Optim.minimizer(result), 2, 2))

    #3d translation test
    outer = reshape(1:9600, 24, 20, 20)
    A = outer[3:16, 7:12, 10:14]
    B = outer[5:18, 6:11, 10:14]
    C = outer[7:20, 5:10, 10:14]
    D = outer[3:16, 6:11, 10:14]
    E = outer[3:16, 5:10, 10:14]

    mm = CenterIndexedArray(zeros(7, 7, 3, 5))
    mm[:, :, :, -2] = translate(A, A, (3, 3, 1))
    mm[:, :, :, -1] = translate(A, B, (3, 3, 1))
    mm[:, :, :, 0] = translate(A, C, (3, 3, 1))
    mm[:, :, :, 1] = translate(A, D, (3, 3, 1))
    mm[:, :, :, 2] = translate(A, E, (3, 3, 1))

    move = [0 1 2 0 0; 0 0 0 1 2; 0 0 0 0 0]
    matrix = Float64[1 1 0 1 1 0 1 1 0]
    result = translate_optim(mm, matrix, move; g_abstol = 1e-14)

    @test minimum(result) < 1e-3
    display(reshape(Optim.minimizer(result), 3, 3))
end
