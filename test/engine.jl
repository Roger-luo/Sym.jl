using Test, Revise, Sym

@vars x y

p = sin(2Constant(:π))

ismatch(x^0, p^0)

-x * y

@which -x

using Combinatorics: combinations, permutations

for each in permutations([x, y, x, x])
    @show each
end
