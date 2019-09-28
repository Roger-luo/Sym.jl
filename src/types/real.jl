export SymReal

struct SymReal <: Real
    ex::Expression
end

SymReal(name::Symbol) = SymReal(Variable(name))
SymReal(x::SymReal) = x
SymReal(x::Real) = SymReal(Numeric(x))
SymReal(::Irrational{sym}) where sym = SymReal(Constant(sym))
DOMAIN_TYPES[:Real] = SymReal

term(x::SymReal) = x.ex
Base.show(io::IO, t::SymReal) = print(io, t.ex)

for (M, f, arity) in DiffRules.diffrules()
    op = :($M.$f)

    if arity == 1
        @eval $op(x::SymReal) = track($op, x)
    elseif arity == 2
        @eval $op(x::SymReal, y::SymReal) = track($op, x, y)
    end
end

Base.promote_rule(::Type{<:SymReal}, ::Type{<:Real}) = SymReal
Base.convert(::Type{<:SymReal}, x::SymReal) = x
Base.convert(::Type{<:SymReal}, x::Real) = SymReal(x)
Base.convert(::Type{<:SymReal}, x::Irrational) = SymReal(x)
