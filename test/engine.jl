using Test, Revise, Sym

@vars x y

t = @term sin(2x)

p = sin(x)

m = match(p, t)

findfirst(m) do d
    haskey(d, )
end

substitude(Dict(x=>π), t)

match(@term(-x*y), @term(-x * x))


p = @term(sin(2π) + y)
t = @term(sin(2π) + x)
substitude(p=>y, t)

d = p=>Numeric(0)

t

match(p, t)