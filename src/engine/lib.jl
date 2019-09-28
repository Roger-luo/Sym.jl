# this part is just defined for debug convenience
using DiffRules, SpecialFunctions, NaNMath

for (M, f, arity) in DiffRules.diffrules()
    op = :($M.$f)

    if arity == 1
        @eval $op(x::Expression) = Term($op, x)
    elseif arity == 2
        @eval $op(x::Expression, y::Expression) = Term($op, x, y)
        @eval $op(x::Number, y::Expression) = Term($op, Numeric(x), y)
        @eval $op(x::Expression, y::Number) = Term($op, x, Numeric(y))

        @eval $op(x::Irrational, y::Expression) = Term($op, Constant(x), y)
        @eval $op(x::Expression, y::Irrational) = Term($op, x, Constant(y))
    end
end
