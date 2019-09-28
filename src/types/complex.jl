export SymComplex

struct SymComplex <: Number
    ex::Expression
end

SymComplex(name::Symbol) = SymComplex(Variable(name))
SymComplex(x::SymComplex) = x
SymComplex(x::Number) = SymComplex(Numeric(x))
SymComplex(x::Complex) = SymComplex(Numeric(real(x)) + Numeric(imag(x)) * Im()) 
SymComplex(x::Irrational{sym}) where sym = SymComplex(Constant(sym))
SymComplex(x::SymReal) = SymComplex(term(x))
SymComplex(x::SymInteger) = SymComplex(term(x))

DOMAIN_TYPES[:Complex] = SymComplex

term(x::SymComplex) = x.ex
Base.show(io::IO, t::SymComplex) = print(io, t.ex)

for (M, f, arity) in DiffRules.diffrules()
    op = :($M.$f)

    if arity == 1
        @eval $op(x::SymComplex) = track($op, x)
    elseif arity == 2
        @eval $op(x::SymComplex, y::SymComplex) = track($op, x, y)
        @eval $op(x::SymReal, y::Complex{Bool}) = track($op, promote(x, y)...)
        @eval $op(x::Complex{Bool}, y::SymReal) = track($op, promote(x, y)...)
    end
end

Base.promote_rule(::Type{<:SymComplex}, ::Type{<:Number}) = SymComplex
Base.promote_rule(::Type{<:SymReal}, ::Type{<:Complex}) = SymComplex

Base.convert(::Type{<:SymComplex}, x::SymComplex) = x
Base.convert(::Type{<:SymComplex}, x::Number) = SymComplex(x)
Base.convert(::Type{<:SymComplex}, x::Complex) = SymComplex(x)
Base.convert(::Type{<:SymComplex}, x::Irrational) = SymComplex(x)
