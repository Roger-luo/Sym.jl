using Test, Sym
using MLStyle

# workaround for https://github.com/thautwarm/MLStyle.jl/issues/75
@as_record Term

x = Term(+, 1, 2)
@test @match! x begin
    1 + 2 => true
    of_mlstyle(_) => false
end

@test @match! Term(sin, Term(*, 2, π)) begin
    sin(2π) => true
    of_mlstyle(_) => false
end
