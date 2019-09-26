eval_args(mod::Module, ex) = ex
eval_args(mod::Module, s::Symbol) = s === :_ ? s : Expr(:&, mod.eval(s))
eval_args(mod::Module, ex::Expr) =
    @match ex begin
        Expr(:call, :of_mlstyle, a) => a
        Expr(:call, f, args...) =>
            let f = eval_args(mod, f)
                args = :[$((eval_args(mod, arg) for arg in args)...)]
                Expr(:call, :Term, f, args)
            end
    end

macro match!(target, cbl)
    Meta.isexpr(cbl, :block) ||
        error("invalid syntax, match cases should be given in form of begin ... end.")
    cbl.args = map(cbl.args) do case
        @match case begin
            ::LineNumberNode => case
            :($a => $b) => begin
                a = eval_args(__module__, a)
                :($a => $b)
            end
        end
    end
    gen_match(target, cbl, __source__, __module__) |> esc
end