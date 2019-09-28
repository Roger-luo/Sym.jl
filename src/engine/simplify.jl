export simplify

function simplify(t::Term, rules, maxstep=1000)
    for _ in 1:maxstep
        prev = t
        for r in rules
            t = replace(t, r)
        end
        prev == t && return t
    end
    # fail to simplify
    return t
end
