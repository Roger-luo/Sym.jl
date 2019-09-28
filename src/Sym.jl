module Sym
import MLStyle: @as_record, gen_match
import MLStyle
export @match, Term, @as_record

using DiffRules, SpecialFunctions, NaNMath

include("engine/engine.jl")
include("types/types.jl")
include("support_patterns.jl")

end # module
