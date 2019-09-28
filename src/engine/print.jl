print_infix(io::IO, op, xs...) = print_infix(io, op, xs)

function print_infix(io::IO, op, xs)
    compact = get(io, :compact, false)
    if length(xs) == 1
        # infix operator must have at least 2 args
        return print_func(io, op, xs[1])
    end

    for (k, x) in enumerate(xs)
        print(io, x)
        if k != lastindex(xs)
            if compact
                print(io, op)
            else
                print(io, " ", op, " ")
            end
        end
    end
end

print_func(io::IO, f, xs...) = print_func(io, f, xs)
print_func(io::IO, ::typeof(-), x) = print(io, "-", x)
function print_func(io::IO, f, xs)
    compact = get(io, :compact, false)
    print(io, f, "(")
    for (k, each) in enumerate(xs)
        print(io, each)
        if k != lastindex(xs)
            if compact
                print(io, ",")
            else
                print(io, ", ")
            end
        end
    end
    print(io, ")")
end

function print_term(io::IO, t::Term)
    if isinfix(t.head)
        print_infix(io, t.head, t.args)
    else
        print_func(io, t.head, t.args)
    end
end

const UNIPOW = Dict()

for (k, each) in enumerate("¹²³⁴⁵⁶⁷⁸⁹")
    UNIPOW[k] = each
end

function print_term(io::IO, t::Term{typeof(^)})
    compact = get(io, :compact, false)
    x, y = t.args
    if y in 1:9
        print(io, x, UNIPOW[Int(y)])
    else
        print(io, x, "^", y)
    end
end

Base.show(io::IO, x::Numeric) = print(io, x.value)
Base.show(io::IO, x::Variable) = print(io, x.name)
Base.show(io::IO, ::Im) = print(io, "im")
Base.show(io::IO, ::Constant{sym}) where sym = print(io, sym)
Base.show(io::IO, t::Term) = print_term(io, t)
