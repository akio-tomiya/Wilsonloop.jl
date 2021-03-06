using Wilsonloop
using Test

function test()

    

    println("plaq")
    plaq = make_plaq()
    display(plaq)
    for μ=1:4
        println("μ = $μ")
        staples = make_plaq_staple(μ)
        display(staples)
    end
    show(loops_staple_prime[(4,4)])

    #return

    loop = [(1,+1)]
    
    println(loop)
    w = Wilsonline(loop)
    loop2 = [(1,-1)]
    w2 = Wilsonline(loop2)


    V1 = derive_U(w,1)
    V2 = derive_U(w2,1)
    show(V1)
    println("d")
    show(V2)
    println("d")


    loop = [(1,+1),(2,+1),(1,-1),(2,-1)]
    println(loop)
    w = Wilsonline(loop)
    println("P: ")
    show(w)
    println("P^+: ")
    show(w')
    println("staple")
    for μ=1:4
        println("μ = $μ")
        V1 = make_staple(w,μ)
        V2 = make_staple(w',μ)
        show(V1)
        show(V2)
    end


    println("derive w")
    for μ=1:4
        dU = derive_U(w,μ)
        for i=1:length(dU)
            show(dU[i])
        end
    end

    println("-------------------------------------------------------")
    println("C and dC/dU")
    for μ=1:4
        C = make_Cμ(w,μ)
        #=
        V1 = make_staple(w,μ)
        V2 = make_staple(w',μ)
        C = eltype(V1)[]
        for i=1:length(V1)
            push!(C,V1[i]')
        end
        for i=1:length(V2)
            push!(C,V2[i]')
        end
        =#
        println("-------------------------------------------")
        println("μ = $μ")
        for i=1:length(C)
            println("---------------------------------------")
            println("C[$i]: ")
            show(C[i])
            for ν=1:4
                println("-----------------------------")
                println("ν = $ν")
                dCdU = derive_U(C[i],ν)
                println("dC_{$μ}/dU_{$ν}: ")
                for j=1:length(dCdU)
                    show(dCdU[j])
                end
            end
        end
    end

    println("-------------------------------------------------------")
    println("C and dC/dUdag")
    for μ=1:4
        C = make_Cμ(w,μ)
        #=
        V1 = make_staple(w,μ)
        V2 = make_staple(w',μ)
        C = eltype(V1)[]
        for i=1:length(V1)
            push!(C,V1[i]')
        end
        for i=1:length(V2)
            push!(C,V2[i]')
        end
        =#
        println("-------------------------------------------")
        println("μ = $μ")
        for i=1:length(C)
            println("---------------------------------------")
            println("C[$i]: ")
            show(C[i])
            for ν=1:4
                println("-----------------------------")
                println("ν = $ν")
                dCdU = derive_Udag(C[i],ν)
                println("dC_{$μ}/dUdag_{$ν}: ")
                for j=1:length(dCdU)
                    show(dCdU[j])
                end
            end
        end
    end

    #=
    w = Wilsonline(loop)
    println("P: ")
    display(w)
    println("P^+: ")
    display(w')
    println("staple")
    make_staples(w)
    =#
end


@testset "Wilsonloop.jl" begin
    test()
    @test true
    # Write your tests here.
end
