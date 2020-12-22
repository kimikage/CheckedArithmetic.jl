using CheckedArithmeticCore
using BenchmarkTools

BenchmarkTools.DEFAULT_PARAMETERS.seconds = 1

xs = Dict{Type, Matrix}()
ys = Dict{Type, Matrix}()
zs = Dict{Type, Matrix}()

eltypes = (Int8, UInt8, Int16, UInt16, Int32, UInt32)
for T in eltypes
    push!(xs, T => rand(T, 1000, 1000))
    push!(ys, T => rand(T, 1000, 1000))
    push!(zs, T => zeros(T, 1000, 1000))
end

SUITE = BenchmarkGroup()
for op in ("neg", "abs", "add", "sub", "mul")
    SUITE[op] = BenchmarkGroup()
    for T in eltypes
        SUITE[op][string(T)] = BenchmarkGroup()
    end
end

for T in eltypes
    x = xs[T]::Matrix{T}
    y = ys[T]::Matrix{T}
    z = zs[T]::Matrix{T}
    t = string(T)
    SUITE["neg"][t]["wrapping"  ] = @benchmarkable   wrapping_neg.($x)
    SUITE["neg"][t]["saturating"] = @benchmarkable saturating_neg.($x)
    SUITE["neg"][t]["checked"   ] = @benchmarkable    checked_neg.($z)

    SUITE["abs"][t]["wrapping"  ] = @benchmarkable   wrapping_abs.($x)
    SUITE["abs"][t]["saturating"] = @benchmarkable saturating_abs.($x)
    SUITE["abs"][t]["checked"   ] = @benchmarkable    checked_abs.($z)

    SUITE["add"][t]["wrapping"  ] = @benchmarkable   wrapping_add.($x, $y)
    SUITE["add"][t]["saturating"] = @benchmarkable saturating_add.($x, $y)
    SUITE["add"][t]["checked"   ] = @benchmarkable    checked_add.($x, $z)

    SUITE["sub"][t]["wrapping"  ] = @benchmarkable   wrapping_sub.($x, $y)
    SUITE["sub"][t]["saturating"] = @benchmarkable saturating_sub.($x, $y)
    SUITE["sub"][t]["checked"   ] = @benchmarkable    checked_sub.($x, $z)

    SUITE["mul"][t]["wrapping"  ] = @benchmarkable   wrapping_mul.($x, $y)
    SUITE["mul"][t]["saturating"] = @benchmarkable saturating_mul.($x, $y)
    SUITE["mul"][t]["checked"   ] = @benchmarkable    checked_mul.($x, $z)
end
