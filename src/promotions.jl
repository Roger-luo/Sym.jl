# promotions
Base.promote_rule(::Type{SymReal}, ::Type{T}) where {T<:Real} = SymReal
Base.promote_rule(::Type{SymReal}, ::Type{<:Complex}) = SymComplex
Base.promote_rule(::Type{SymComplex}, ::Type{Any}) = SymComplex
Base.promote_rule(::Type{SymComplex}, ::Type{<:Real}) = SymComplex
Base.promote_rule(::Type{Complex{T}}, ::Type{SymReal}) where {T <: Real} = SymComplex
