@testset "Translation function test" begin
    outer = reshape(1:120, 12, 10)
    A = outer[1:8, 1:8]
    B = outer[3:10, 2:9]
    C = outer[5:12, 3:10]

    mm = zeros(11, 11, 3)
    mm[:, :, 1] = translate(A, A, (5, 5))
    mm[:, :, 2] = translate(A, B, (5, 5))
    mm[:, :, 3] = translate(A, C, (5, 5))

    move = [0 1 2; 0 0 0]
    matrix = Float64[1 1 1 1]
    result = translate_optim(mm, matrix, move)

    @test minimum(result) < 1e-3
end
