
# generator for cartesian product
function xypairs(::Type{T}) where T
    xs = typemin(T):typemax(T)
    ((x, y) for x in xs, y in xs)
end
