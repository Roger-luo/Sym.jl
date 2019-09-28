# Sym

[![Build Status](https://travis-ci.com/Roger-luo/Sym.jl.svg?branch=master)](https://travis-ci.com/Roger-luo/Sym.jl)
[![Codecov](https://codecov.io/gh/Roger-luo/Sym.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/Roger-luo/Sym.jl)
[![Coveralls](https://coveralls.io/repos/github/Roger-luo/Sym.jl/badge.svg?branch=master)](https://coveralls.io/github/Roger-luo/Sym.jl?branch=master)

This is a package for symbolic computation in Julia with correct type bounds. It provides `SymReal`, `SymInteger`, `SymComplex` and `SymNumber` for each different
mathematical domain with correct subtyping. Unlike other symbolic engines provides only symbolic types that are subtypes of `Number`. This will make a lot more generic Julia function defined on such domain "just work".

## Installation

```jl
pkg> add https://github.com/Roger-luo/Sym.jl.git
```

## Acknowledgement

I appreciate the discussion under ModelingToolkit and slack with Mason Protter, Harrison Grodin, Chris Rackauckas and Taine Zhao. The implementation of pattern matching is taken from [Simplify](https://github.com/HarrisonGrodin/Simplify.jl)
with a few modifications. In the future, I may replace the current naive
rewrite system with the [Rewrite.jl](https://github.com/HarrisonGrodin/Rewrite.jl).

## License

This package is released under Apache License 2.0.