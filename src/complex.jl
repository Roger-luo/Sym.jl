abstract type AbstractComplex <: Number end

struct SymComplex <: AbstractComplex
    data
end


data(x::SymComplex) = x.data

Base.real(x::SymComplex) = real(data(x))
Base.imag(x::SymComplex) = imag(data(x))

# eliminate potential nested symbol
SymComplex(x::SymComplex) = x
SymComplex(f, args...) = SymComplex(f, args)
SymComplex(f, args::Tuple) = SymComplex(f(map(data, args)...))

Base.Complex(x::SymReal, y::SymReal) = Complex{SymReal}(x, y)

function Base.show(io::IO, z::Complex{<:SymReal})
    r, i = reim(z)
    compact = get(io, :compact, false)
    if !iszero(r)
        show(io, r)
    end

    if signbit(i) && !isnan(i)
        i = -i
        print(io, compact ? "-" : " - ")
    else
        iszero(r) || print(io, compact ? "+" : " + ")
    end
    iszero(i) && return
    show(inline(io), i)

    if _show_prod_sym(i)
        print(io, "*")
    end
    print(io, "im")
end

_show_prod_sym(i::Integer) = false
_show_prod_sym(i::Bool) = true
_show_prod_sym(i::AbstractFloat) = !isfinite(i)
_show_prod_sym(i::SymReal) = _show_prod_sym(i.data)
_show_prod_sym(i::SymExpr) = false
_show_prod_sym(i) = true # show * by default


Base.show(io::IO, x::SymComplex) = print(io, x.data)
# promotions
Base.promote_rule(::Type{<:AbstractComplex}, ::Type{T}) where T = SymComplex

function Base.:(*)(x::Complex{Bool}, y::SymReal)
    Complex{SymReal}(SymReal(x.re * data(y)), SymReal(x.im * data(y)))
end

function Base.:(*)(x::Complex, y::SymReal)
    Complex{SymReal}(SymReal(x.re * data(y)), SymReal(x.im * data(y)))
end

Base.:(*)(x::SymReal, y::Complex) = SymComplex(*, x, y)
Base.:(*)(x::SymReal, y::Complex{Bool}) = SymComplex(*, x, y)
Base.:(+)(x::SymReal, y::Complex) = SymComplex(*, x, y)

function simplify(ex::Complex{SymReal}; rules=DEFINED_RULES, maxstep=1000)
    re = simplify(ex.re; rules=rules, maxstep=maxstep)
    im = simplify(ex.im; rules=rules, maxstep=maxstep)
    return Complex{SymReal}(SymReal(re), SymReal(im))
end

function simplify_step(ex::Complex{SymReal}; rules=DEFINED_RULES)
    re = simplify_step(data(ex.re); rules=rules)
    im = simplify_step(data(ex.im); rules=rules)
    return Complex{SymReal}(SymReal(re), SymReal(im))
end


function maprule(rule, ex::Complex{SymReal})
    re = maprule(rule, data(ex.re))
    im = maprule(rule, data(ex.im))
    return Complex{SymReal}(SymReal(re), SymReal(im))
end
