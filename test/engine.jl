using Test, Sym

@testset "test engine: $op" for op in [+, -, *, /, ^]
    @test op(Variable(:x), Variable(:y)) == SymExpr(op, [Variable(:x), Variable(:y)])
end

@testset "test constants" begin
    @test one(Variable(:x)) == 1
    @test zero(Variable(:x)) == 0
    @test sin(Constant{:π}()) == 0
    @test cos(Constant{:π}()) == -1
end

@testset "test -" begin
    ex = Variable(:x) + Variable(:y)
    ex = -ex
    @test -ex == SymExpr(+, [Variable(:x), Variable(:y)])
end
