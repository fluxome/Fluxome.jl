using SafeTestsets
using Test

@time begin

    @time @testset "Doctests" begin include("doctests.jl") end

    @time @safetestset "Integration: immigration-death model" begin
        include("integration/immigrationdeath.jl") 
    end
    
    @time @safetestset "Integration: switching-emission-degradation model" begin
        include("integration/switchingemissiondeath.jl") 
    end

end
