export SymNumber
struct SymNumber <: Number
    ex::Expression
end

SymNumber(name::Symbol) = SymNumber(Variable(name))
SymNumber(x::Number) = SymNumber(Numeric(x))
SymNumber(x::Irrational{sym}) where sym = SymNumber(Constant(sym))
SymNumber(x::SymReal) = SymNumber(term(x))
SymNumber(x::SymComplex) = SymNumber(term(x))

term(x::SymNumber) = x.ex
Base.show(io::IO, t::SymNumber) = print(io, t.ex)

for (M, f, arity) in DiffRules.diffrules()
    op = :($M.$f)

    if arity == 1
        @eval $op(x::SymNumber) = track($op, x)
    elseif arity == 2
        @eval $op(x::SymNumber, y::SymNumber) = track($op, x, y)
    end
end

Base.promote_rule(::Type{<:SymNumber}, ::Type{<:Number}) = SymNumber
Base.promote_rule(::Type{<:SymNumber}, ::Type{<:SymComplex}) = SymNumber

Base.convert(::Type{<:SymNumber}, x::SymNumber) = x
Base.convert(::Type{<:SymNumber}, x::Number) = SymNumber(x)
Base.convert(::Type{<:SymNumber}, x::Irrational) = SymNumber(x)

Base.convert(::Type{<:SymNumber}, x::SymReal) = SymNumber(x)
Base.convert(::Type{<:SymNumber}, x::SymComplex) = SymNumber(x)
