using Test, Sym

@sym x in Real, y in Real, z in Real

@testset "Boolean arithmetics" begin
    @test x * true == x
    @test x * false == 0
    @test x + true == x + 1
end
