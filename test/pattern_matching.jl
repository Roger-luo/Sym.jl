using MLStyle
using Sym

x, y = Variable(:x), Variable(:y)

function foo(ex)
    @match ex begin
        SymExpr(*, $a, $b) => "mul"
        _ => nothing
    end
end

ex = x * y

dump(ex)