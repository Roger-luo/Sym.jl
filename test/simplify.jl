using Test, Sym
using Sym: data

x, y, z = Variable.([:x, :y, :z])

@testset "flatten" begin
    @test maprule(flatten, x + y + z) == SymExpr(+, [x, y, z])
    @test maprule(flatten, x + y * z + x) == SymExpr(+, [x, y*z, x])
end

@testset "merge terms" begin
    @test eval_numeric(4x * 2x) == 8 * (x * x)

    @test maprule(merge_terms, 2x * 2x) == 4 * x^2
    @test maprule(merge_terms, 2x * 0 * x) == 0
    @test maprule(merge_terms, x + 2x) == SymExpr(*, [4, x])
end
