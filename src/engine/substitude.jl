export substitude

function substitude(d::Dict{Variable}, t::Term)
    Term(t.head, map(x->substitude(d, x), t.args))
end

substitude(d::Dict{Variable}, t::Variable) = haskey(d, t) ? d[t] : t
substitude(d::Dict{Variable}, t) = t

substitude(::Pair, t) = t
function substitude(d::Pair{<:Term, <:Expression}, t::Term)
    p, s = d
    m = match(p, t)
    if m !== nothing
        for each in m
            s = substitude(each, s)
        end
        return s
    end

    return Term(substitude(d, t.head), map(x->substitude(d, x), t.args))
end
