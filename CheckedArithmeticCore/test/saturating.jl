using Test, CheckedArithmeticCore

include("utilities.jl")

@testset "saturating_neg" begin
    sneg(x::T) where {T} = T <: Unsigned ? zero(T) : x === typemin(T) ? typemax(T) : -x
    for T in (Int8, UInt8)
        @test all(x -> saturating_neg(x) === sneg(x), typemin(T):typemax(T))
    end

    @testset "saturating_neg $T" for T in (Int, Int128, UInt128)
        @test saturating_neg(zero(T)) === zero(T)
        @test saturating_neg(typemin(T)) === ifelse(T <: Unsigned, zero(T), typemax(T))
        @test saturating_neg(typemax(T)) === ifelse(T <: Unsigned, zero(T), -typemax(T))
    end
    @testset "saturating_neg Bool" begin
        @test saturating_neg(true) === checked_neg(true)
    end
    @testset "saturating_neg BigInt" begin
        @test saturating_neg(BigInt(1)) == BigInt(-1)
    end
end

@testset "saturating_abs" begin
    sabs(x::T) where {T} = T <: Unsigned ? x : x === typemin(T) ? typemax(T) : abs(x)
    for T in (Int8, UInt8)
        @test all(x -> saturating_abs(x) === sabs(x), typemin(T):typemax(T))
    end

    @testset "saturating_abs $T" for T in (Int, Int128, UInt128)
        @test saturating_abs(typemax(T)) === typemax(T)
        @test saturating_abs(typemin(T)) === ifelse(T <: Unsigned, zero(T), typemax(T))
    end
    @testset "saturating_abs Bool" begin
        @test saturating_abs(true) === checked_abs(true)
        @test saturating_abs(false) === checked_abs(false)
    end
    @testset "saturating_abs BigInt" begin
        @test saturating_abs(BigInt(-1)) == BigInt(1)
    end
end

@testset "saturating_add" begin
    function sadd(x::T, y::T) where T
        r, f = add_with_overflow(x, y)
        f || return r
        y < zero(T) ? typemin(T) : typemax(T)
    end

    for T in (Int8, UInt8)
        @test all(((x, y),) -> saturating_add(x, y) === sadd(x, y), xypairs(T))
    end

    @testset "saturating_add $T" for T in (Int, Int128, UInt128)
        @test saturating_add(zero(T), oneunit(T)) === oneunit(T)
        @test saturating_add(typemax(T), oneunit(T)) === typemax(T)
    end
    @testset "saturating_add Bool" begin
        @test saturating_add(true, true) === checked_add(true, true)
    end
    @testset "saturating_add BigInt" begin
        @test saturating_add(BigInt(1), BigInt(-1)) == BigInt(0)
    end
    @test saturating_add(typemax(Int), true) === typemax(Int)
    @test saturating_add(Int8(127), Int8(1), Int8(-1)) === Int8(126) # != 127
end

@testset "saturating_sub" begin
    function ssub(x::T, y::T) where T
        r, f = sub_with_overflow(x, y)
        f || return r
        y < zero(T) ? typemax(T) : typemin(T)
    end

    for T in (Int8, UInt8)
        @test all(((x, y),) -> saturating_sub(x, y) === ssub(x, y), xypairs(T))
    end

    @testset "saturating_sub $T" for T in (Int, Int128, UInt128)
        @test saturating_sub(oneunit(T), oneunit(T)) === zero(T)
        @test saturating_sub(typemin(T), oneunit(T)) === typemin(T)
    end
    @testset "saturating_sub Bool" begin
        @test saturating_sub(false, true) === checked_sub(false, true)
    end
    @testset "saturating_sub BigInt" begin
        @test saturating_sub(BigInt(0), BigInt(-1)) == BigInt(1)
    end
    @test saturating_sub(typemin(Int), true) === typemin(Int)
    @test saturating_sub(Int8(-128), Int8(1), Int8(-1)) === Int8(-127) # != -128
end

@testset "saturating_mul" begin
    function smul(x::T, y::T) where T
        r, f = mul_with_overflow(x, y)
        f || return r
        T <: Unsigned ? typemax(T) : signbit(x) ⊻ signbit(y) ? typemin(T) : typemax(T)
    end

    for T in (Int8, UInt8)
        @test all(((x, y),) -> saturating_mul(x, y) === smul(x, y), xypairs(T))
    end

    @testset "saturating_mul $T" for T in (Int, Int128, UInt128)
        @test saturating_mul(typemax(T), oneunit(T)) === typemax(T)
        @test saturating_mul(oneunit(T), typemin(T)) === typemin(T)
        @test saturating_mul(typemax(T), typemax(T)) === typemax(T)
        @test saturating_mul(typemax(T), typemin(T)) === typemin(T)
    end
    @testset "saturating_mul Bool" begin
        @test saturating_mul(true, true) === checked_mul(true, true)
    end
    @testset "saturating_mul BigInt" begin
        @test saturating_mul(BigInt(-1), BigInt(-1)) == BigInt(1)
    end
    @test saturating_mul(typemin(Int), true) === typemin(Int)
    @test saturating_mul(Int8(-128), Int8(-1), Int8(-1)) === Int8(-127) # != -128
end
