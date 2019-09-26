export SymReal

struct SymReal <: Real
    data
end
data(x::SymReal) = x.data

# eliminate potential nested symbol
SymReal(x::SymReal) = x
SymReal(x::Complex) = throw(InexactError(:SymReal, SymReal, x))
SymReal(x::Irrational{sym}) where sym = SymReal(Constant{sym}())
SymReal(f, args...) = SymReal(f, args)
SymReal(f, args::Tuple) = SymReal(f(map(data, args)...))

Base.convert(::Type{SymReal}, x::SymExpr) = SymReal(x)
Base.convert(::Type{SymReal}, x::Number) = SymReal(x)
Base.convert(::Type{SymReal}, x::SymReal) = x

isexpr(x::SymReal) = isexpr(x.data)

Base.show(io::IO, x::SymReal) = print(io, x.data)

# unary
Base.signbit(x::SymReal) = signbit(data(x))
Base.iszero(x::SymReal) = iszero(data(x))

Base.literal_pow(::typeof(^), x::SymReal, n::Val{N}) where N = SymReal(Base.literal_pow, ^, x, n)
Base.literal_pow(::typeof(^), x::SymReal, n::Val{1}) = x
