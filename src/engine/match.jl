using Combinatorics: combinations, permutations
export ismatch, Match, match, match!

# traits
abstract type Property end
struct Associative <: Property end
struct Communitive <: Property end
struct AntiCommunitive <: Property end
struct NoProperty <: Property end

Property(::Type{F}, xs...) where F = Property(F.instance, xs...)
Property(f, xs...) = NoProperty()

const ASSOCIATE_AND_COMMUNITIVE = (Associative(), Communitive())
Property(::typeof(*), xs::Number...) = ASSOCIATE_AND_COMMUNITIVE
Property(::typeof(+), xs::Number...) = ASSOCIATE_AND_COMMUNITIVE
Property(::typeof(-), xs::Number...) = AntiCommunitive()

# shamelessly copied from Simplify.jl
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

match(pattern::Expression, term::Expression) = match!(one(Match), pattern, term)

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
    length(p) == length(t) || return nothing
    match!(m, p.head, t.head) === nothing && return nothing

    for (x, y) in zip(p.args, t.args)
        o = match(x, y)
        o === nothing && return nothing
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
    nomatch || return nothing
    return m
end

# shamelessly took from Simplify
# function match!(m::Match, ::Associative, p::Term, t::Term)
#     match!(m, p.head, t.head)
#     length(p) > length(t) && return m

#     k = 1
#     for pk in p.args
#         match!(m, pk, t.args[k])
#     end
# end
