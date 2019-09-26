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
        export $(esc(name))
        $(esc(name))(x) = x # identity by default
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
@rule flatten(ex::SymExpr) = flatten(ex.f, ex)

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

function count_terms(ex::SymExpr)
    terms = Dict{Any, Int}()
    for each in ex
        if haskey(each in terms)
            terms[each] += 1
        else
            terms[each] = 1
        end
    end
    return terms
end

function accumulate_numerics(f, ex::SymExpr)
    # skip simple cases
    if (length(ex.args) == 2) && (ex.args[1] isa Number) && !(ex.args[2] isa Number)
        return ex.args[1], ex.args[2]
    end

    i = findfirst(x->isa(x, Number), ex.args)
    i == nothing && return nothing, ex
    α = ex.args[i]
    args = ex.args[1:i-1]
    for k in i+1:length(ex.args)
        if ex.args[k] isa Number
            α = f(α, ex.args[k])
        else
            push!(args, ex.args[k])
        end
    end
    isempty(args) && return α, nothing
    return α, SymExpr(*, args)
end

@rule function eval_numeric(ex::SymExpr{typeof(*)})
    ex = maprule(flatten, ex)
    α, term = accumulate_numerics(*, ex)
    α === nothing && return ex
    term === nothing && return α
    isone(α) && return term
    return α * term
end

function eval_numeric(ex::SymExpr{typeof(+)})
    ex = maprule(flatten, ex)
    α, term = accumulate_numerics(+, ex)
    α === nothing && return ex
    term === nothing && return α
    iszero(α) && return term
    return α + term
end


"""
    merge_terms(x)

Merge similar terms in expression `x`.
"""
@rule function merge_terms(ex::SymExpr{typeof(+)})
    ex = maprule(flatten, ex) # make things easier if we flatten
    terms = Dict{Any, Int}()
    for each in ex.args
        count_term!(+, terms, each)
    end

    args = []
    for (t, α) in terms
        if isone(α)
            push!(args, t)
        else
            push!(args, α * t)
        end
    end
    return SymExpr(+, args)
end

function count_terms!(f::typeof(+), terms::Dict, ex::SymExpr{typeof(*)})
    α, ex = accumulate_numerics(*, ex) # make sure * terms are in "α * term" form
    iszero(α) && return

    if haskey(terms, ex)
        terms[ex] += 1
    else
        terms[ex] = 1
    end
    return
end

function merge_terms(::typeof(*), ex::SymExpr)
    ex = flatten(*, ex)
    terms = Dict{Any, Int}()
    α = 1
    for each in ex.args
        if each isa Number
            α *= each
        elseif haskey(terms, each)
            terms[each] += 1
        else
            terms[each] = 1
        end
    end

    iszero(α) && return 0

    args = []
    for (term, k) in terms
        if isone(k)
            push!(args, term)
        else
            push!(args, term^k)
        end
    end

    isempty(args) && return 0

    if length(args) == 1
        ex = args[1]
    else
        ex = SymExpr(*, args)
    end
    if isone(α)
        return ex
    else
        return α * ex
    end
end

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

"""
    rm_zeros(x)

Remove zeros in expression `x`.
"""
@rule function rm_zeros(ex::SymExpr)
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
    iszero(ex.args[1]) && return 1
    return ex
end

is_negone(x) = x == -one(x)

@rule function rm_ones(x::SymExpr)
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

@rule function simple_power(ex::SymExpr{typeof(^)})
    x, n = ex.args[1], ex.args[2]
    return simple_power(ex, x, n)
end

is_exponential(x) = false
is_exponential(x::SymExpr{typeof(exp)}) = true

has_exponential(x) = false
function has_exponential(x::SymExpr)
    for each in x.args
        is_exponential(each) && return true
    end
    return false
end

function simple_power(ex::SymExpr{typeof(*)})
    has_exponential(ex) || return ex

    exp_args = []
    args = []

    for each in ex.args
        if is_exponential(each)
            push!(exp_args, each.args[1])
        else
            push!(args, each)
        end
    end

    length(exp_args) == 1 && return ex
    push!(args, SymExpr(exp, [SymExpr(+, exp_args)]))
    return SymExpr(*, args)
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

is_imaginary_unit(x) = false
is_imaginary_unit(x::Im) = true

function literal_im_pow(n::Int)
    n == 1 ? Im()  :
    n == 2 ? -1    :
    n == 3 ? -Im() :
    n == 0 ? 1     :
    literal_im_pow(rem(n, 4))
end

@rule function merge_complex(x::SymExpr{typeof(*)})
    count = 0
    args = []
    for each in x.args
        if is_imaginary_unit(each)
            count += 1
        else
            push!(args, each)
        end
    end
    i = literal_im_pow(count)
    isone(i) && return SymExpr(*, args)
    push!(args, i)
    return SymExpr(*, args)
end

export maprule, simplify, simplify_step
"""
    maprule(rule, x)

Map simplification rule `rule` to expression `x`
recursively.
"""
maprule(rule, x) = x

function maprule(rule, ex::SymExpr)
    nex = rule(ex)
    if nex isa SymExpr
        return SymExpr(nex.f, map(x->maprule(rule, x), nex.args))
    else
        return nex
    end
end

maprule(rule, ex::SymReal) = maprule(rule, data(ex))
maprule(rule, ex::SymComplex) = maprule(rule, data(ex))

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

function simplify(ex::T; rules=DEFINED_RULES, maxstep=1000) where {T <: Union{SymReal, SymComplex}}
    T(simplify(data(ex), rules=rules, maxstep=maxstep))
end

# simplify
function simplify(ex::AbstractArray{T}; rules=DEFINED_RULES, maxstep=1000) where {T <: Union{SymReal, SymComplex}}
    broadcast(ex) do x
        simplify(x, rules=DEFINED_RULES, maxstep=maxstep)
    end
end
