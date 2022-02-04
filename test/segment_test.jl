@testset "Test beads segmentation" begin
    A = [
        1 0 0 1 0
        1 0 1 1 1
    ]

    tgt = [
        0 0 0 1 0
        0 0 1 1 1
    ]

    threshold = 3
    @test beads_segment(A, threshold) == tgt

end
