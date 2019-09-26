Base.iszero(::Val{N}) where N = false
Base.iszero(::Val{0}) = true
Base.isone(::Val{1}) = true
Base.isone(::Val{N}) where N = false
