Base.iszero(::Val{N}) where N = false
Base.iszero(::Val{0}) = true
