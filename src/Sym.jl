module Sym
import MLStyle: @as_record, gen_match
import MLStyle
export @match, Term, @as_record

include("engine.jl")
include("support_patterns.jl")
include("print.jl")

end # module
