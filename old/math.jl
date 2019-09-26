# general case
# we track everything
using DiffRules, SpecialFunctions, NaNMath

const __SYM_TYPES__ = [SymReal, SymComplex]
const __NUM_TYPES__ = [Complex{Bool}, Complex, Number, Real]

for (M, f, arity) in DiffRules.diffrules()
    fun = :($M.$f)
    
    if arity == 1
        @eval $fun(x::AbstractExpr) = SymExpr($fun, x)

        @eval $fun(x::SymReal) = SymReal($fun, x)
        @eval $fun(x::SymComplex) = SymComplex($fun, x)

        @eval Base.promote_op(::typeof($fun), S::Type{SymComplex}) = SymComplex
        @eval Base.promote_op(::typeof($fun), S::Type{SymReal}) = SymReal

    elseif arity == 2
        @eval $fun(x::AbstractExpr, y::Number) = SymExpr($fun, x, y)
        @eval $fun(x::Number, y::AbstractExpr) = SymExpr($fun, x, y)
        @eval $fun(x::AbstractExpr, y::AbstractExpr) = SymExpr($fun, x, y)

        @eval $fun(x::SymReal, y::SymReal) = SymReal($fun, x, y)
        @eval $fun(x::SymComplex, y::SymComplex) = SymComplex($fun, x, y)

        @eval $fun(x::AbstractExpr, y::Irrational{sym}) where sym = SymExpr($fun, x, Constant(sym))
        @eval $fun(x::Irrational{sym}, y::AbstractExpr) where sym = SymExpr($fun, Constant(sym), y)

        @eval Base.promote_op(::typeof($fun), S1::Type{SymComplex}, S2::Type{SymComplex}) = SymComplex
        @eval Base.promote_op(::typeof($fun), S1::Type{SymComplex}, S2::Type{<:Number}) = SymComplex
        @eval Base.promote_op(::typeof($fun), S1::Type{<:Number}, S2::Type{SymComplex}) = SymComplex

        @eval Base.promote_op(::typeof($fun), S1::Type{SymReal}, S2::Type{<:Real}) = SymReal
        @eval Base.promote_op(::typeof($fun), S1::Type{<:Real}, S2::Type{SymReal}) = SymReal
        @eval Base.promote_op(::typeof($fun), S1::Type{SymReal}, S2::Type{SymReal}) = SymReal
    end
end
