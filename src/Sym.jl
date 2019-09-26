module Sym
import MLStyle: @match, @as_record, gen_match
export @match!, Term

include("engine.jl")
include("support_patterns.jl")

end # module
