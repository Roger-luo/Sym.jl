abstract type AbstractExpr end

struct Variable <: AbstractExpr
    name::Symbol
end

struct Im <: AbstractExpr end
struct Constant{sym} <: AbstractExpr end
Constant(sym::Symbol) = Constant{sym}()

struct SymExpr{F} <: AbstractExpr
    f::F
    args::Vector
end

SymExpr(f, args...) = SymExpr(f, collect(args))

"""
    isexpr(ex)

Return `true` if ex is an non-primitive (non-leaf) expression.
"""
isexpr(x) = false
isexpr(::SymExpr) = true

Base.signbit(::AbstractExpr) = false
Base.signbit(x::SymExpr{typeof(-)}) = length(x.args) == 1

function inline(io::IO)
    get(io, :inline, false) || return IOContext(io, :inline=>true)
    return io
end

function noinline(io::IO)
    if haskey(io, :inline)
        return IOContext(io, :inline=>false)
    end
    return io
end

Base.show(io::IO, x::Variable) = print(io, x.name)
Base.show(io::IO, x::Im) = print(io, "im")
Base.show(io::IO, x::Constant{sym}) where sym = print(io, sym)
function Base.show(io::IO, ex::SymExpr)
    print_expr(io, ex, ex)
end

is_infix(x) = false

function print_expr(io::IO, root::SymExpr, ex::SymExpr)
    isinline = get(io, :inline, false)
    print_parathesis = (isinline && is_infix(ex.f)) ||
        (root !== ex && is_infix(ex.f))
    if print_parathesis
        print(io, "(")
    end

    print_expr(io, root, ex, ex.f)

    if print_parathesis
        print(io, ")")
    end
end

# use its own printing if it is not an composite expression
print_expr(io::IO, root::SymExpr, ex) = print(io, ex)
print_expr_without_parathesis(io::IO, root::SymExpr, ex) = print(io, ex)
print_expr_without_parathesis(io::IO, root::SymExpr, ex::SymExpr) =
    print_expr(io, root, ex, ex.f)
function print_expr(io::IO, root::SymExpr, ex::SymExpr, f)
    print(io, f, "(")
    for k in eachindex(ex.args)
        # we do not print outer most parathesis
        # for normal function calls
        print_expr_without_parathesis(io, root, ex.args[k])
        if k != lastindex(ex.args)
            print(io, ", ")
        end
    end
    print(io, ")")
end

# infix
for op in [:+, :*, :/, :-]
    @eval is_infix(::typeof($op)) = true
    @eval function print_expr(io::IO, root::SymExpr, ex::SymExpr, f::typeof($op))
        print_prefix(io, ex, f)
        nargs = length(ex.args)
        prev = first(ex.args)
        print_expr(io, root, prev)

        for k in 2:nargs
            curr = ex.args[k]
            if show_infix_operator(f, prev, curr)
                print(io, " ", $op, " ")
            end
            print_expr(io, root, curr)
        end
    end
end

show_infix_operator(f, prev, curr) = true
show_infix_operator(::typeof(*), prev::Integer, curr::Variable) = false
show_infix_operator(::typeof(*), prev, curr::SymExpr) = !is_infix(curr.f)
show_infix_operator(::typeof(*), prev::SymExpr, curr) = !is_infix(prev.f)
show_infix_operator(::typeof(*), prev::SymExpr, curr::SymExpr) = false

show_infix_operator(::typeof(*), prev, curr::SymExpr{typeof(^)}) = true
show_infix_operator(::typeof(*), prev::SymExpr{typeof(^)}, curr) = true
show_infix_operator(::typeof(*), prev::SymExpr, curr::SymExpr{typeof(^)}) = true
show_infix_operator(::typeof(*), prev::SymExpr{typeof(^)}, curr::SymExpr) = true
show_infix_operator(::typeof(*), prev::SymExpr{typeof(^)}, curr::SymExpr{typeof(^)}) = true


print_prefix(io::IO, ex, f) = nothing
print_prefix(io::IO, ex::SymExpr, f::typeof(-)) = length(ex.args) == 1 && print(io, "-")

function print_expr(io::IO, root::SymExpr, ex::SymExpr, f::typeof(^))
    _print_power(io, ex, ex.args[1], ex.args[2])
end

function _print_power(io::IO, ex::SymExpr, x, y)
    print(io, x, "^", y)
end

for (k, s) in enumerate("²³⁴⁵⁶⁷⁸⁹")
    @eval _print_power(io::IO, ex::SymExpr, x, n::Val{$(k+1)}) =
        print(io, x, $s)
end

Base.:(==)(x::SymExpr, y::SymExpr) = false
function Base.:(==)(x::SymExpr{F}, y::SymExpr{F}) where F
    x.args == y.args
end

## Bool
Base.:(+)(x::Bool, y::AbstractExpr) = x ? 1 + y : y
Base.:(+)(x::AbstractExpr, y::Bool) = y ? x + 1 : x

Base.:(*)(x::Bool, y::AbstractExpr) = x ? y : 0
Base.:(*)(x::AbstractExpr, y::Bool) = y ? x : 0

# unary
Base.zero(x::AbstractExpr) = 0
Base.one(x::AbstractExpr) = 1
Base.sin(::Constant{:π}) = 0
Base.cos(::Constant{:π}) = -1

function Base.:(-)(x::SymExpr{typeof(-)})
    if length(x.args) == 1
        return x.args[1]
    else
        return SymExpr(+, [-x.args[1], -x.args[2]])
    end
end
