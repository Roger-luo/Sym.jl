export @sym

struct SymReal <: Real
    data
end
data(x::SymReal) = x.data

# eliminate potential nested symbol
SymReal(x::SymReal) = x
SymReal(f, args...) = SymReal(f, args)
SymReal(f, args::Tuple) = SymReal(f(map(data, args)...))

Base.convert(::Type{SymReal}, x::SymExpr) = SymReal(x)

function symm(ex::Expr)
    if ex.head === :call && ex.args[1] === :in
        ex.args[2] isa Symbol || throw(Meta.ParseError("expect a symbol got $(ex.args[2])"))
        ex.args[3] === :Real && 
            return :($(esc(ex.args[2])) = SymReal(Variable($(QuoteNode(ex.args[2])))); nothing)

    elseif ex.head === :tuple
        return Expr(:block, map(symm, ex.args)..., nothing)
    end

    throw(Meta.ParseError("Invalid expression: $ex"))
end

macro sym(ex)
    symm(ex)
end

isexpr(x::SymReal) = isexpr(x.data)

Base.show(io::IO, x::SymReal) = print(io, x.data)

# promotions
Base.promote_rule(::Type{<:SymReal}, ::Type{T}) where {T<:Real} = SymReal

# unary
Base.signbit(x::SymReal) = signbit(data(x))
Base.iszero(x::SymReal) = iszero(data(x))

Base.literal_pow(::typeof(^), x::SymReal, n::Val{N}) where N = SymReal(^, x, n)
Base.literal_pow(::typeof(^), x::SymReal, n::Val{1}) = x
