# a fake one
function print_infix(io::IO, op::Symbol, xs...)
end

function print_term(io::IO, t::Term)
    @match t begin
        Term(*, mlstyle(a::Number), mlstyle(x::Variable)) => print(io, a, x)
        Term(*, mlstyle(xs...)) => print_infix(io, :*, xs...)
        _ => error("invalid term")
    end
end
