export SymComplex

abstract type AbstractComplex <: Number end

struct SymComplex <: AbstractComplex
    data
end

data(x::SymComplex) = x.data

# eliminate potential nested symbol
SymComplex(x::SymComplex) = x
SymComplex(f, args...) = SymComplex(f, args)
SymComplex(f, args::Tuple) = SymComplex(f(map(data, args)...))
SymComplex(x::Complex) = SymComplex(data(x.re) + Im() * data(x.im))
SymComplex(x::SymReal) = SymComplex(data(x))
SymComplex(x::Irrational{sym}) where sym = SymComplex(Constant{sym}())

Base.show(io::IO, x::SymComplex) = print(io, x.data)
Base.convert(::Type{SymComplex}, x::Number) = SymComplex(x)

# handling Bool
Base.:(+)(x::SymReal, z::Complex{Bool}) = SymComplex(+, promote(x, z)...)
Base.:(+)(z::Complex{Bool}, x::SymReal) = SymComplex(+, promote(z, x)...)
Base.:(-)(x::SymReal, z::Complex{Bool}) = SymComplex(-, promote(x, z)...)
Base.:(-)(z::Complex{Bool}, x::SymReal) = SymComplex(-, promote(z, x)...)
Base.:(*)(x::SymReal, z::Complex{Bool}) = SymComplex(*, promote(x, z)...)
Base.:(*)(z::Complex{Bool}, x::SymReal) = SymComplex(*, promote(z, x)...)
