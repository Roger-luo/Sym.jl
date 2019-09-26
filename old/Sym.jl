module Sym

include("engine.jl")

"""
    data(x)

Return the data stored by symbolic types.
"""
data(x) = x

include("patch.jl")
include("real.jl")
include("complex.jl")
include("promotions.jl")

SymReal(x::SymComplex) = throw(InexactError(:SymReal, SymReal, x))

# libs
include("math.jl")
include("simplify.jl")

export @sym
function symm(ex::Expr)
    if ex.head === :call && ex.args[1] === :in
        ex.args[2] isa Symbol || throw(Meta.ParseError("expect a symbol got $(ex.args[2])"))
        ex.args[3] === :Real && 
            return :($(esc(ex.args[2])) = SymReal(Variable($(QuoteNode(ex.args[2])))); nothing)

    elseif ex.head === :tuple
        return Expr(:block, map(symm, ex.args)..., nothing)
    end

    throw(Meta.ParseError("Invalid expression: $ex"))
end

macro sym(ex)
    symm(ex)
end

end # module
