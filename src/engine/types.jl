export Expression, Constant, Numeric, Im, Term
export @vars, Variable
export @term

abstract type Expression end
struct Variable <: Expression
    name::Symbol
end

struct Numeric{T} <: Expression
    value::T
end

struct Constant{sym} <: Expression end
struct Im <: Expression end

Constant(sym::Symbol) = Constant{sym}()
Constant(x::Irrational{sym}) where sym = Constant{sym}()

struct Term{F} <: Expression
    head::F
    args::Vector
end

Term(f::F, xs...) where F = Term(f, collect(xs))

Base.length(t::Term) = length(t.args)
Base.length(::Variable) = 1
Base.length(::Constant) = 1
Base.length(::Im) = 1

Base.:(==)(::Term, ::Term) = false
Base.:(==)(t1::Term{F}, t2::Term{F}) where F = t1.args == t2.args

Base.:(==)(x::Number, y::Numeric) = x == y.value
Base.:(==)(x::Numeric, y::Number) = x.value == y
Base.:(==)(x::Numeric, y::Numeric) = x.value == y.value

Base.Int(x::Numeric) = Int(x.value)

Base.convert(::Type{<:Expression}, x::Number) = Numeric(x)
Base.convert(::Type{<:Expression}, ::Irrational{sym}) where sym = Constant(sym)

macro term(ex)
    term_m(ex)
end
to_expr(x) = x
to_expr(x::Number) = Numeric(x)
to_expr(x::Irrational) = Constant(x)

term_m(x) = :(to_expr($x))

function term_m(ex::Expr)
    ex.head === :call || throw(Meta.ParseError("expect function call"))
    :(Term($(term_m.(ex.args)...)))
end

# macro constructors
function varm(xs::Symbol...)
    ts = Expr(:tuple)
    vs = Expr(:tuple)
    for x in xs
        if x in RESERVED_TOKENS
            throw(Meta.ParseError("$x is reserved, use another variable name"))
        end
        push!(vs.args, x)
        push!(ts.args, :(Variable($(Meta.quot(x)))))
    end
    return :($vs = $ts)
end

macro vars(xs::Symbol...)
    return esc(varm(xs...))
end

macro vars(xs...)
    quote
        throw(Meta.ParseError("expect symbols got $xs"))
    end
end
