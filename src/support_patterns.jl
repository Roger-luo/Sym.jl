@as_record internal Term

symbolic_pattern(mod::Module, ex) = ex
symbolic_pattern(mod::Module, s::Symbol) = s === :_ ? s : Expr(:&, mod.eval(s))
function symbolic_pattern(mod::Module, ex::Expr)
    rec(x) = symbolic_pattern(mod, x)
    MLStyle.@match ex begin
        Expr(:call, :mlstyle, a) => mlstyle_pattern(mod, a)
        Expr(:call, :Term, f, args...) &&
            if isdefined(mod, :Term) &&
               getfield(mod, :Term) == Term
            end ||
        Expr(:call, f, args...) =>
            let f = symbolic_pattern(mod, f)
                args = :[$((symbolic_pattern(mod, arg) for arg in args)...)]
                Expr(:call, :Term, f, args)
            end
        Expr(hd, tl...) => Expr(hd, map(rec, tl)...)
    end
end

mlstyle_pattern(mod::Module, ex) = ex
function mlstyle_pattern(mod::Module, ex::Expr)
    rec(x) = mlstyle_pattern(mod, x)
    MLStyle.@match ex begin
        Expr(:call, :symbolic, a) => symbolic_pattern(mod, a)
        Expr(hd, tl...) => Expr(hd, map(rec, tl)...)
    end
end


macro match(target, cbl)
    Meta.isexpr(cbl, :block) ||
        error("invalid syntax, match cases should be given in form of begin ... end.")
    cbl.args = map(cbl.args) do case
        MLStyle.@match case begin
            ::LineNumberNode => case
            :($a => $b) => begin
                a = symbolic_pattern(__module__, a)
                :($a => $b)
            end
        end
    end
    gen_match(target, cbl, __source__, __module__) |> esc
end