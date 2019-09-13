export flatten, merge_terms
# simplification

const DEFINED_RULES = Any[]

function define_rule(name)
    global  DEFINED_RULES
    
    if name in DEFINED_RULES
        @warn "$name is already registered"
    else
        push!(DEFINED_RULES, name)
    end
end

handle(::Any) = nothing
handle(x::Symbol) = x
handle(expr::Expr) = handle(Val(expr.head), expr)

handle(::Val{:block}, expr) = filter(x -> x !== nothing, map(handle, expr.args))
handle(::Val{:const}, expr) = handle(expr.args[1])
handle(::Val{:(=)}, expr) = handle(expr.args[1])
handle(::Val{:function}, expr) = handle(expr.args[1])
handle(::Val{:where}, expr) = handle(expr.args[1])

handle(::Val{:<:}, expr) = handle(expr.args[1])
handle(::Val{:curly}, expr) = handle(expr.args[1])
handle(::Val{:call}, expr) = handle(expr.args[1])

macro rule(ex::Expr)
    name = handle(ex)
    quote
        Base.@__doc__ $(esc(ex))
        define_rule($(esc(name)))
    end
end

has_same_operator(f::T, ex::SymExpr{T}) where T = true
has_same_operator(f, ex::SymExpr) = f == ex.f
has_same_operator(f, ex) = false

"""
    flatten(x)

Return flattened expression `x`.
"""
@rule function flatten end

flatten(x) = x
flatten(ex::SymExpr) = flatten(ex.f, ex)

"""
    is_associative(x)

Check if `x` is associative.
"""
is_associative(x) = false
is_associative(::typeof(*)) = true
is_associative(::typeof(+)) = true

function flatten(f::F, ex::SymExpr{F}) where F
    !is_associative(f) && return ex
    args = []
    for each in ex.args
        if has_same_operator(f, each)
            append!(args, each.args)
        else
            push!(args, each)
        end
    end
    SymExpr(f, args)
end

"""
    merge_terms(x)

Merge similar terms in expression `x`.
"""
@rule merge_terms(x) = x
merge_terms(f, x) = x

function count_terms(ex::SymExpr)
    terms = IdDict{Any, Int}()
    for each in ex.args
        if haskey(terms, each)
            terms[each] += 1
        else
            terms[each] = 1
        end
    end
    return terms
end

function merge_terms(ex::SymExpr)
    merge_terms(ex.f, ex)
end


# function merge_terms(::typeof(-), ex::SymExpr)
#     length(ex.args) == 1 && return ex
#     if ex.args[1] == ex.args[2]
#         return Zero()
#     else
#         return ex
#     end
# end

function merge_terms(::typeof(+), ex::SymExpr)
    ex = flatten(+, ex)

    terms = count_terms(ex)

    args = []
    for (term, α) in terms
        if isone(α)
            push!(args, term)
        else
            push!(args, SymExpr(*, [α, term]))
        end
    end

    isempty(args) && return 0
    if length(args) == 1
        return args[1]
    else
        SymExpr(+, args)
    end
end

function merge_terms(::typeof(*), ex::SymExpr)
    ex = flatten(*, ex)
    terms = count_terms(ex)
    args = []
    for (term, α) in terms
        if isone(α)
            push!(args, term)
        else
            push!(args, term^α)
        end
    end

    isempty(args) && return 0
    if length(args) == 1
        return args[1]
    else
        SymExpr(*, args)
    end
end

merge_sign(ex) = ex
@rule function merge_sign(ex::SymExpr{typeof(+)})
    args = []
    prev = first(ex.args)
    for k in 2:length(ex.args)
        curr = ex.args[k]
        if signbit(curr)
            prev = SymExpr(-, [prev, -curr])
            push!(args, prev)
        else
            push!(args, prev)
            prev = curr
        end
    end
    curr = last(ex.args)
    if signbit(curr)
        prev = SymExpr(-, [prev, -curr])
    else
        push!(args, prev)
        prev = curr
    end
    
    if length(args) == 1
        return args[1]
    else
        return SymExpr(+, args)
    end
end


export rm_zeros

"""
    rm_zeros(x)

Remove zeros in expression `x`.
"""
@rule rm_zeros(x) = x
function rm_zeros(ex::SymExpr)
    rm_zeros(ex.f, ex)
end

rm_zeros(f, ex::SymExpr) = ex
function rm_zeros(::typeof(*), ex::SymExpr{typeof(*)})
    ex = flatten(ex)
    for each in ex.args
        if iszero(each)
            return 0
        end
    end
    return ex
end

function rm_zeros(f::F, ex::SymExpr{F}) where {F <: Union{typeof(+), typeof(-)}}
    ex = flatten(ex)
    args = []
    for each in ex.args
        if !iszero(each)
            push!(args, each)
        end
    end
    isempty(args) && return 0
    return SymExpr(f, args)
end

function rm_zeros(::typeof(^), ex::SymExpr{typeof(^)})
    ex = flatten(ex)
    iszero(ex.args[1]) && return 0
    iszero(ex.args[2]) && return 1
    return ex
end

function rm_zeros(::typeof(/), ex::SymExpr{typeof(/)})
    if iszero(ex.args[1])
        if iszero(ex.args[2])
            return NaN
        else
            return 0
        end
    else
        if iszero(ex.args[2])
            return SymInf()
        else
            return ex
        end
    end
end

function rm_zeros(::typeof(exp), ex::SymExpr{typeof(exp)})
    iszero(ex.args[1]) && return One()
    return ex
end

is_negone(x) = x == -one(x)

@rule rm_ones(x) = x
rm_ones(f, ex) = ex
function rm_ones(x::SymExpr)
    rm_ones(x.f, x)
end

function rm_ones(::typeof(*), ex::SymExpr)
    args = []
    sign = false
    for each in ex.args
        if isone(each)
            continue
        elseif is_negone(each)
            sign = !sign
        else
            push!(args, each)
        end
    end

    isempty(args) && return 0
    if sign
        return -SymExpr(*, args)
    else
        return SymExpr(*, args)
    end
end

function rm_ones(::typeof(/), ex::SymExpr)
    isone(ex.args[2]) && return ex.args[1]
    return ex
end

complex_exp(x) = x
@rule function complex_exp(ex::SymExpr{typeof(exp)})
    isreal(ex.args[1]) && return ex
    ex.args[1] isa SymComplex && return ex

    r, x = pi_rational(ex.args[1])
    x === nothing && return ex # not rational

    x = periodic_pi_factor(x)
    x == 2 && return exp(r) * One()
    x == 1 && return exp(r) * -One()
    x == 1//2 && return exp(r) * im

    sqrthalf = SymExpr(/, 1, SymExpr(sqrt, 2))
    x == 1//4 && return Complex{SymReal}(sqrthalf, sqrthalf)
    
    # fallback
    x = SymReal(SymExpr(*, [x, Constant{:π}()]))
    return SymExpr(exp, [Complex{SymReal}(0, x)])
end

# deal with π
haspi(x) = false
haspi(::Constant{:π}) = true

function haspi(x::SymExpr)
    for each in x.args
        haspi(each) && return true
    end
    return false
end

ispi(x) = false
ispi(::Constant{:π}) = true
ispi(::Irrational{:π}) = true

pi_factor(x) = x
function pi_factor(x::SymExpr{typeof(*)})
    length(x.args) == 2 || return nothing # has to be x * π, or we wait until we have this
    ispi(x.args[2]) && return x.args[1]
    ispi(x.args[1]) && return x.args[2]
end

pi_rational(x) = error("expect complex number")
pi_rational(x::SymComplex) = pi_rational(data(x))
pi_rational(x::Complex) = x.re, pi_rational(data(x.im))
function pi_rational(ex::SymExpr{typeof(*)})
    length(ex.args) == 2 || return nothing
    α = pi_factor(ex)
    α === nothing && return nothing
    isinteger(α) && return convert(Int, α)
    α isa Rational && return α

    return nothing
end

function pi_rational(ex::SymExpr{typeof(/)})
    haspi(ex.args[1]) || return nothing # not interested
    α = pi_factor(ex.args[1])
    α === nothing && return nothing
    β = ex.args[2]
    # can't simplify irrational
    # there might be a way to find out if x/y is rational
    # we do not deal with this for now
    (isinteger(α) && isinteger(β)) || return nothing
    α = convert(Int, α)
    β = convert(Int, β)
    iszero(rem(α, β)) || return (α // β)

    return convert(Int, α ÷ β)
end

function periodic_pi_factor(x::Int)
    if isodd(x)
        return 1
    else
        return 2
    end
end

function periodic_pi_factor(x::Rational)
    if x.num < 0
        m = -x.num ÷ x.den
        if isodd(m)
            x = x + m + 1
        else
            x = x + m + 2
        end
    end

    a =  x.num ÷ x.den

    t = x - a
    isodd(a) ? t + 1 : t
end

simple_power(x) = x

@rule function simple_power(ex::SymExpr{typeof(^)})
    x, n = ex.args[1], ex.args[2]
    return simple_power(ex, x, n)
end

function simple_power(ex::SymExpr, x, n)
    return ex
end

function simple_power(ex::SymExpr, x::SymExpr{typeof(^)}, n)
    return SymExpr(^, x.args[1], x.args[2] * n)
end

function simple_power(ex::SymExpr, x::SymExpr{typeof(exp)}, n)
    return SymExpr(exp, x.args[1] * n)
end

function simple_power(ex::SymExpr, x::Complex{Bool}, n)
    iszero(x) && return 0

    if iszero(real(x))
        r = rem(n, 4)
        r == 1 && return im
        r == 2 && return -One()
        r == 3 && return -im
        r == 0 && return One()
    elseif iszero(imag(x))
        return One()
    else
        r = SymExpr(sqrt, [Constant{2}()])
        angle = SymExpr(/, [Constant{:π}(), 4])
        return exp(Complex{SymReal}(SymReal(0), SymReal(angle)))
    end
end

merge_complex(x) = x
iscomplex(x) = false
iscomplex(::Complex) = true

function hascomplex(x::SymExpr)
    for each in x.args
        iscomplex(each) && return true
    end
    return false
end

@rule function merge_complex(x::SymExpr{typeof(*)})
    hascomplex(x) || return x
    re = real(x.args[1])
    im = imag(x.args[1])

    for k in 2:length(x.args)

        u = real(x.args[k])
        v = imag(x.args[k])

        re = re * u - im * v
        im = re * v + im * u
    end

    if iszero(im)
        return re
    else
        return Complex{SymReal}(SymReal(re), SymReal(im))
    end
end

export maprule, simplify, simplify_step
"""
    maprule(rule, x)

Map simplification rule `rule` to expression `x`
recursively.
"""
maprule(rule, x) = x
maprule(rule, x::T) where {T <: Union{SymReal, SymComplex}} =
    T(maprule(rule, data(x)))

function maprule(rule, ex::SymExpr)
    nex = rule(ex)
    if nex isa SymExpr
        return SymExpr(nex.f, map(x->maprule(rule, x), nex.args))
    else
        return nex
    end
end

simplify_step(ex) = ex
function simplify_step(ex::SymExpr; rules=DEFINED_RULES)
    for r in rules
        ex = maprule(r, ex)
    end
    return ex
end

simplify(x; rules=DEFINED_RULES, maxstep=1000) = x

function simplify(ex::SymExpr; rules=DEFINED_RULES, maxstep=1000)
    prev = ex
    for k in 1:maxstep
        curr = simplify_step(prev)
        if curr == prev
            return curr
        end
        prev = curr
    end
    @warn "simplification does not converge"
    return prev
end
