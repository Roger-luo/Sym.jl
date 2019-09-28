const INFIX_OPERATORS = [:(+), :(-), :(*), :(/), :(\), :(÷), :(%)]
const RESERVED_TOKENS = [:im, :π, :ℯ]

macro operator(op, properties...)
end

const operator_property = @enum associative infix
@operator + associative infix
