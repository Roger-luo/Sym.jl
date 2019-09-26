abstract type Expression end
struct Variable <: Expression
    name::Symbol
end

struct Constant{sym} <: Expression end
struct Im <: Expression end

struct Term{F} <: Expression
    head::F
    args::Vector{Any}
    Term(f::F, xs...) where F = new{F}(f, collect(xs))
end


Base.show(io::IO, x::Variable) = print(io, x.name)
Base.show(io::IO, ::Im) = print(io, "im")
Base.show(io::IO, ::Constant{sym}) where sym = print(io, sym)

for op in [:+, :-, :*, :/, :\]
    @eval Base.$op(x::Expression, y::Expression) = Term($op, x, y)
end
