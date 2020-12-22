module Wrapping

export wrapping_neg, wrapping_abs, wrapping_add, wrapping_sub, wrapping_mul,
       wrapping_div, wrapping_rem, wrapping_fld, wrapping_mod, wrapping_cld,
       wrapping_fdiv

wrapping_neg(x::Integer) = -x
wrapping_abs(x::Integer) = abs(x)
wrapping_add(x::Integer, y::Integer) = x + y
wrapping_add(x, y, z...) = wrapping_add(x + y, z...)

wrapping_sub(x::Integer, y::Integer) = x - y
wrapping_sub(x, y, z...) = wrapping_sub(x - y, z...)

wrapping_mul(x::Integer, y::Integer) = x * y
wrapping_div(x::Integer, y::Integer) = div(x, y)
wrapping_rem(x::Integer, y::Integer) = rem(x, y)
wrapping_fld(x::Integer, y::Integer) = fld(x, y)
wrapping_mod(x::Integer, y::Integer) = mod(x, y)
wrapping_cld(x::Integer, y::Integer) = cld(x, y)

wrapping_fdiv(x::Integer, y::Integer) = div(x, y)


end #module
