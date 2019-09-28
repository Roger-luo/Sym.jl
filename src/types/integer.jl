export SymInteger

struct SymInteger <: Integer
    ex::Expression
end

SymInteger(name::Symbol) = SymInteger(Variable(name))
SymInteger(x::SymInteger) = x
SymInteger(x::Integer) = SymInteger(Numeric(x))
SymInteger(x::Irrational{sym}) where sym = SymInteger(Constant(sym))

DOMAIN_TYPES[:Integer] = SymInteger

term(x::SymInteger) = x.ex
Base.show(io::IO, t::SymInteger) = print(io, t.ex)

for (M, f, arity) in DiffRules.diffrules()
    op = :($M.$f)

    if arity == 1
        @eval $op(x::SymInteger) = track($op, x)
    elseif arity == 2
        @eval $op(x::SymInteger, y::SymInteger) = track($op, x, y)
    end
end

Base.promote_rule(::Type{<:SymInteger}, ::Type{<:Integer}) = SymInteger
Base.convert(::Type{<:SymInteger}, x::SymInteger) = x
Base.convert(::Type{<:SymInteger}, x::Integer) = SymInteger(x)
Base.convert(::Type{<:SymInteger}, x::Irrational{sym}) where sym = SymInteger(x)

# Int specific
Base.xor(a::SymInteger, b::SymInteger) = track(xor, a, b)
