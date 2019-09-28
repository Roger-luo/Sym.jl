# traits
abstract type Property end
struct Associative <: Property end
struct Communitive <: Property end
struct AntiCommunitive <: Property end
struct NoProperty <: Property end

Property(::Type{F}, xs...) where F = Property(F.instance, xs...)
Property(f, xs...) = NoProperty()

const ASSOCIATE_AND_COMMUNITIVE = (Associative(), Communitive())
Property(::typeof(*), xs::Number...) = ASSOCIATE_AND_COMMUNITIVE
Property(::typeof(+), xs::Number...) = ASSOCIATE_AND_COMMUNITIVE
Property(::typeof(-), xs::Number...) = AntiCommunitive()

const RESERVED_TOKENS = [:im, :π, :ℯ]
isinfix(x::Symbol) = Base.isbinaryoperator(x)
isinfix(x) = Base.isbinaryoperator(nameof(x))
