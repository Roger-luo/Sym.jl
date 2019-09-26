using Test, Sym

# workaround for https://github.com/thautwarm/MLStyle.jl/issues/75
@as_record Term

x = Term(+, 1, 2)
@test @match x begin
    1 + 2 => true
    mlstyle(_) => false
end

@test @match x begin
    Term(+, 1, 2) => true
    _ => false
end

@test @match Term(sin, Term(*, 2, π)) begin
    sin(2π) => true
    mlstyle(_) => false
end

@test @match Term(sin, Term(*, 2, π)) begin
    Term(sin, Term(*, 2, π)) => true
    mlstyle(_) => false
end


@test @match Term(sin, Term(*, 2, π)) begin
    mlstyle(Term(f, args)) => f == sin
    _ => false
end
