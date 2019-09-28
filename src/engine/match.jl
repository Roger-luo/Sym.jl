# shamelessly took from Simplify.jl

using Combinatorics: combinations, permutations
export ismatch, Match, match, match!

mutable struct Match <: AbstractSet{AbstractDict{Variable, Any}}
    matches::Set{Dict{Variable, Any}}
end

Match(xs::Union{Pair,Dict}...) = Match(Set(Dict.(xs)))
Base.zero(::Type{Match}) = Match()
Base.one(::Type{Match}) = Match(Dict())
Base.length(Θ::Match) = length(Θ.matches)
Base.iterate(Θ::Match) = iterate(Θ.matches)
Base.iterate(Θ::Match, state) = iterate(Θ.matches, state)
Base.push!(Θ::Match, items...) = (push!(Θ.matches, items...); Θ)
Base.push!(θ::Match, items::Pair{Variable}...) = push!(θ, Dict{Variable, Any}(items...))
Base.copy(Θ::Match) = Match(copy(Θ.matches))
Base.union(Θ₁::Match, Θ₂::Match) = Match(union(Θ₁.matches, Θ₂.matches))

function Base.merge!(Θ::Match, Θs::Match...)
    for Θ′ ∈ Θs
        result = Match()
        for σ′ ∈ Θ′
            foreach(Θ) do σ
                res = copy(σ)
                for (k, v) in σ′
                    if haskey(σ, k)
                        σ[k] == v || return
                    end
                    res[k] = v
                end
                push!(result, res)
            end
        end
        Θ.matches = result
    end
    Θ
end
Base.merge(σ::Match, σs::Match...) = merge!(one(Match), σ, σs...)

Base.match(pattern::Expression, term::Expression) = match!(one(Match), pattern, term)

function Base.match(pattern::Expression, term::Expression, θ::Match)
    m = match(pattern, term)
    m === nothing && return
    return merge(m, θ)
end

match!(m::Match, p, t) = p == t ? m : nothing
match!(m::Match, x::Variable, t::Expression) = push!(m, x=>t)
match!(m::Match, p::Term{F}, t::Term{F}) where F = match!(m, Property(p.head), p, t)

# and
function match!(m::Match, properties::Tuple, p::Term, t::Term)
    for each in properties
        match!(m, each, p, t)
    end
    return m
end

# fallback
function match!(m::Match, ::Property, p::Term, t::Term)
    length(p) == length(t) || return
    match!(m, p.head, t.head) === nothing && return

    for (x, y) in zip(p.args, t.args)
        o = match(x, y)
        o === nothing && return
        merge!(m, o)
    end
    return m
end

function match!(m::Match, ::Communitive, p::Term, t::Term)
    nomatch = false
    for perm in permutations(t.args)
        t′ = Term(t.head, perm)
        if match!(m, NoProperty(), p, t′) !== nothing
            nomatch = true
        end
    end
    nomatch || return
    return m
end

# shamelessly took from Simplify
function match!(m::Match, ::Associative, p::Term, t::Term)
    match!(m, p.head, t.head)
    length(p) > length(t) && return m

    match!(m, p.head, t.head) === nothing && return

    length(p) > length(t) && return
    n_free = length(t) - length(p)
    n_vars = count(x -> x isa Variable, p.args)

    for k in Iterators.product((0:n_free for i in 1:n_vars)...)
        (isempty(k) ? 0 : sum(k)) == n_free || continue
        i, j = 1, 1
        for pk in p.args
            l_sub = 0
            if pk isa Variable
                l_sub += k[j]
                j += 1
            end
            s′ = l_sub > 0 ? Term(t.head, t.args[i:i+l_sub]) : t.args[i]
            match!(m, pk, s′) === nothing && break
            i += l_sub + 1
        end
    end
    return m
end
