# general case
# we track everything
using DiffRules, SpecialFunctions, NaNMath

for (M, f, arity) in DiffRules.diffrules()
    fun = :($M.$f)

    if arity == 1
        @eval $fun(x::AbstractExpr) = SymExpr($fun, x)
        @eval $fun(x::SymReal) = SymReal($fun, x)
        @eval $fun(x::SymComplex) = SymComplex($fun, x)
        @eval $fun(x::Complex{SymReal}) = SymComplex(SymExpr($fun, x))
    elseif arity == 2
        @eval $fun(x::AbstractExpr, y::Number) = SymExpr($fun, x, y)
        @eval $fun(x::Number, y::AbstractExpr) = SymExpr($fun, x, y)
        @eval $fun(x::AbstractExpr, y::AbstractExpr) = SymExpr($fun, x, y)

        @eval $fun(x::SymReal, y::SymReal) = SymReal($fun, x, y)
        @eval $fun(x::SymComplex, y::SymComplex) = SymComplex($fun, x, y)

        @eval $fun(x::AbstractExpr, y::Irrational{sym}) where sym = SymExpr($fun, x, Constant(sym))
        @eval $fun(x::Irrational{sym}, y::AbstractExpr) where sym = SymExpr($fun, Constant(sym), y)

        @eval $fun(x::SymReal, y::Irrational{sym}) where sym = SymReal($fun, x, Constant(sym))
        @eval $fun(x::Irrational{sym}, y::SymReal) where sym = SymReal($fun, Constant(sym), y)

        @eval $fun(x::SymComplex, y::Irrational{sym}) where sym = SymComplex($fun, x, Constant(sym))
        @eval $fun(x::Irrational{sym}, y::SymComplex) where sym = SymComplex($fun, Constant(sym), y)
    end
end
