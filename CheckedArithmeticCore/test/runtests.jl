using CheckedArithmeticCore
using Test

@testset "checked" begin
    include("checked.jl")
end
@testset "saturating" begin
    include("saturating.jl")
end
@testset "wrapping" begin
    include("wrapping.jl")
end

struct MyType end
struct MySafeType end
Base.convert(::Type{MySafeType}, ::MyType) = MySafeType()
CheckedArithmeticCore.safearg_type(::Type{MyType}) = MySafeType
CheckedArithmeticCore.accumulatortype(::typeof(+), ::Type{MyType}) = MyType
CheckedArithmeticCore.accumulatortype(::typeof(+), ::Type{MySafeType}) = MySafeType
CheckedArithmeticCore.accumulatortype(::typeof(*), ::Type{MyType}) = MySafeType
CheckedArithmeticCore.accumulatortype(::typeof(*), ::Type{MySafeType}) = MySafeType
Base.promote_rule(::Type{MyType}, ::Type{MySafeType}) = MySafeType

@testset "safearg" begin
    # fallback
    @test safearg(MyType()) === MySafeType()
end

@testset "safeconvert" begin
    # fallback
    @test safeconvert(UInt16, 0x12) === 0x0012
end

@testset "accumlatortype" begin
    # fallback
    @test accumulatortype(MyType) === MySafeType
    @test accumulatortype(MyType, MyType) === MySafeType
    @test accumulatortype(+, MyType) === MyType
    @test accumulatortype(*, MyType) === MySafeType
    @test accumulatortype(+, MyType, MySafeType) === MySafeType
    @test accumulatortype(*, MySafeType, MyType) === MySafeType
end

@testset "acc" begin
    @test acc(MyType()) === MySafeType()
    @test acc(+, MyType()) === MyType()
end
