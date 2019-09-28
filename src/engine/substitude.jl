export substitude

function substitude(d::Dict{Variable}, t::Term)
    Term(t.head, map(x->substitude(d, x), t.args))
end

substitude(d::Dict{Variable}, t::Variable) = haskey(d, t) ? d[t] : t
substitude(d::Dict{Variable}, t) = t

Base.replace(t::Expression, ::Pair) = t

function Base.replace(t::Term, d::Pair{<:Term, <:Expression})
    p, s = d
    m = match(p, t)
    if m !== nothing
        for each in m
            s = substitude(each, s)
        end
        return s
    end

    return Term(replace(t.head, d), map(x->replace(x, d), t.args))
end
