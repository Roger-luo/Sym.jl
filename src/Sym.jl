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

function simplify(ex::T; rules=DEFINED_RULES, maxstep=1000) where {T <: Union{SymReal, SymComplex}}
    T(simplify(data(ex), rules=rules, maxstep=maxstep))
end

# simplify
function simplify(ex::AbstractArray{T}; rules=DEFINED_RULES, maxstep=1000) where {T <: Union{SymReal, SymComplex}}
    broadcast(ex) do x
        simplify(x, rules=DEFINED_RULES, maxstep=maxstep)
    end
end

# libs
include("math.jl")

include("simplify.jl")

end # module
