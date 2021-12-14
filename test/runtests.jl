using REALMSupport
using Test, Optim, OffsetArrays, Statistics

@testset "REALMSupport" begin
    include("grid_test.jl")
    include("gauss_fit_test.jl")
    include("register_test.jl")
end
