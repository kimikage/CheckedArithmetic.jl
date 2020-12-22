module Saturating

export saturating_neg, saturating_abs, saturating_add, saturating_sub, saturating_mul,
       saturating_div, saturating_rem, saturating_fld, saturating_mod, saturating_cld,
       saturating_fdiv

import ..CheckedArithmeticCore: BitSigned, BitUnsigned, BitInteger
using Base.Checked

"""
    saturating_neg(x)

Calculate `-x`, while saturating at numeric bounds.
"""
saturating_neg(x::Integer) = saturating_sub(zero(x), x)

"""
    saturating_abs(x)

Calculate `|x|`, while saturating at numeric bounds.
"""
saturating_abs(x::Integer) = ifelse(x < zero(x), saturating_neg(x), x)

"""
    saturating_add(x)

Calculate `x + y`, while saturating at numeric bounds.
"""
saturating_add(x::Integer, y::Integer) = saturating_add(promote(x, y)...)
saturating_add(x::T, y::T) where {T <: Integer} = _saturating_add(x, y)
saturating_add(x::Bool, y::Bool) = x + y
saturating_add(x::BigInt, y::BigInt) = x + y
saturating_add(x, y, z...) = saturating_add(saturating_add(x, y), z...)

"""
    saturating_sub(x)

Calculate `x - y`, while saturating at numeric bounds.
"""
saturating_sub(x::Integer, y::Integer) = saturating_sub(promote(x, y)...)
saturating_sub(x::T, y::T) where {T <: Integer} = _saturating_sub(x, y)
saturating_sub(x::Bool, y::Bool) = x - y
saturating_sub(x::BigInt, y::BigInt) = x - y
saturating_sub(x, y, z...) = saturating_sub(saturating_sub(x, y), z...)

"""
    saturating_mul(x)

Calculate `x * y`, while saturating at numeric bounds.
"""
saturating_mul(x::Integer, y::Integer) = saturating_mul(promote(x, y)...)
saturating_mul(x::T, y::T) where {T <: Integer} = _saturating_mul(x, y)
saturating_mul(x::Bool, y::Bool) = x * y
saturating_mul(x::BigInt, y::BigInt) = x * y
saturating_mul(x, y, z...) = saturating_mul(saturating_mul(x, y), z...)

saturating_div(x::Integer, y::Integer) = saturating_div(promote(x, y)...)
saturating_rem(x::Integer, y::Integer) = saturating_rem(promote(x, y)...)
saturating_fld(x::Integer, y::Integer) = saturating_fld(promote(x, y)...)
saturating_mod(x::Integer, y::Integer) = saturating_mod(promote(x, y)...)
saturating_cld(x::Integer, y::Integer) = saturating_cld(promote(x, y)...)

saturating_fdiv(x::Integer, y::Integer) = saturating_div(x, y)


function saturating_div(x::T, y::T, r::RoundingMode = RoundToZero) where {T <: Integer}
    _saturating_div(x, y, r)
end
saturating_fld(x::T, y::T) where {T <: Integer} = saturating_div(x, y, RoundDown)
saturating_cld(x::T, y::T) where {T <: Integer} = saturating_div(x, y, RoundUp)

function saturating_rem(x::T, y::T, r::RoundingMode = RoundToZero) where {T <: Integer}
    _saturating_rem(x, y, r)
end
saturating_mod(x::T, y::T) where {T <: Integer} = saturating_rem(x, y, RoundDown)


function _sat_ir(op, T)
    fix = occursin("fix", op)
    t = "i$(8sizeof(T))"
    s = T <: Signed ? "s" : "u"
    f = "@llvm.$s$op.sat.$t"
    scale = fix ? ", i32" : ""
    z = fix ? "0" : ""
    decl = "declare $t $f($t, $t $scale)"
    ir = """
        %3 = call $t $f($t %0, $t %1 $scale $z)
        ret $t %3"""
    mod = """
        $decl
        define $t @entry($t, $t) alwaysinline {
        $ir
        }"""
    @static if VERSION >= v"1.6.0-DEV674"
        return quote
            Base.@_inline_meta
            Base.llvmcall($(mod, "entry"), T, Tuple{T, T}, x, y)
        end
    else
        return quote
            Base.@_inline_meta
            Base.llvmcall($(decl, ir), T, Tuple{T, T}, x, y)
        end
    end
end

@static if Base.libllvm_version >= v"8.0.0"
    function saturating_add(x::T, y::T) where {T <: BitInteger}
        if @generated
            return _sat_ir("add", T)
        else
            return _saturating_add(x, y)
        end
    end
end
function _saturating_add(x::T, y::T) where {T <: Integer}
    x + ifelse(x < zero(T), max(y, typemin(T) - x), min(y, typemax(T) - x))
end
function _saturating_add(x::T, y::T) where {T <: Unsigned}
    x + min(~x, y)
end

@static if Base.libllvm_version >= v"8.0.0"
    function saturating_sub(x::T, y::T) where {T <: BitInteger}
        if @generated
            return _sat_ir("sub", T)
        else
            return _saturating_sub(x, y)
        end
    end
end
function _saturating_sub(x::T, y::T) where {T <: Integer}
    x - ifelse(x < zero(T), min(y, x - typemin(T)), max(y, x - typemax(T)))
end
function _saturating_sub(x::T, y::T) where {T <: Unsigned}
    x - min(x, y)
end

#=
@static if Base.libllvm_version >= v"8.0.0"
    function saturating_mul(x::T, y::T) where {T <: BitInteger}
        if @generated
            return _sat_ir("mul.fix", T) # smul.fix.sat is slow on x86-64
        else
            return _saturating_mul(x, y)
        end
    end
end
=#
# TODO: benchmark umul.fix.sat with LLVM v10 or later

function _saturating_mul(x::T, y::T) where {T <: Integer}
    min(max(widemul(x, y), typemin(T)), typemax(T)) % T
end
function _saturating_mul(x::T, y::T) where {T <: Union{Int128, UInt128}}
    r, f = mul_with_overflow(x, y) # avoid BigInt operations
    f || return r
    T <: Unsigned ? typemax(T) : signbit(x) ⊻ signbit(y) ? typemin(T) : typemax(T)
end

function _saturating_div(x::T, y::T, r::RoundingMode) where {T <: BitInteger}
    z = round(Float64(x) / Float64(y), r)
    isnan(z) && return zero(T)
    if T <: Unsigned
        isfinite(z) ? trunc(T, z) : typemax(T)
    else
        trunc(T, clamp(z, typemin(T), typemax(T)))
    end
end
function _saturating_rem(x::T, y::T, r::RoundingMode) where {T <: BitInteger}
    T <: Unsigned && r isa RoundingMode{:Up} && return zero(T)
    x - saturating_div(x, y, r) * y
end

end #module
