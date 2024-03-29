module Wilsonloop
export make_staple,
    Wilsonline,
    make_staple_and_loop,
    derive_U,
    make_Cμ,
    make_plaq_staple,
    make_plaq,
    loops_staple_prime,
    get_position,
    derive_Udag,
    make_loops_fromname,
    make_chair,
    get_rightlinks,
    get_leftlinks,
    get_direction,
    loops_plaq,
    loops_rect,
    check_plaqset,
    isdag
using LaTeXStrings
using LinearAlgebra
import Base
import Base.:(==)

abstract type Gaugelink{Dim} end

struct GLink{Dim} <: Gaugelink{Dim}
    direction::Int8
    position::NTuple{Dim,Int64}
    isdag::Bool

    function GLink{Dim}(direction, position, isdag = false) where {Dim}
        return new{Dim}(direction, position, isdag)
    end
end

struct Adjoint_GLink{Dim} <: Gaugelink{Dim}
    parent::GLink{Dim}
end

function LinearAlgebra.adjoint(glink::Adjoint_GLink{Dim}) where {Dim}
    return GLink{Dim}(glink.direction, glink.position, true)#, glink.parent
end


function LinearAlgebra.adjoint(glink::GLink{Dim}) where {Dim}
    return GLink{Dim}(glink.direction, glink.position, !(glink.isdag))
    #        return Adjoint_GLink{Dim}(glink)
end


function get_direction(glink::GLink)
    return glink.direction
end

function get_position(glink::GLink)
    return glink.position
end

function isdag(glink::GLink)
    return glink.isdag
end


function set_position(glink::GLink{Dim}, position) where {Dim}
    return GLink{Dim}(glink.direction, position, glink.isdag)
end


mutable struct Wilsonline{Dim}
    glinks::Vector{GLink{Dim}}
    #glinks::Array{Union{GLink{Dim},Adjoint_GLink{Dim}},1}

    Wilsonline(; Dim = 4) = new{Dim}([])
    Wilsonline(glinks; Dim = 4) = new{Dim}(glinks)
    function Wilsonline(segments_in::Array{Tuple{T,T},1}; Dim = 4) where {T<:Integer}
        segments = make_links(segments_in)
        numline = length(segments)
        glinks = Array{GLink{Dim},1}(undef, numline)
        #glinks = Array{Union{GLink{Dim},Adjoint_GLink{Dim}},1}(undef,numline)
        position = zeros(Int64, Dim)
        for (i, segment) in enumerate(segments)
            dimension = segment[1]
            hoppingdirection = segment[2]

            if hoppingdirection == 1
                glinks[i] = GLink{Dim}(dimension, Tuple(position))
                position[dimension] += 1
            elseif hoppingdirection == -1
                position[dimension] += -1
                glinks[i] = GLink{Dim}(dimension, Tuple(position))'
            else
                error(
                    "hoppingdirection in segment should be 1 or -1. But now $hoppingdirection",
                )
            end
        end
        return new{Dim}(glinks)
    end
end


function ==(x::GLink{Dim}, y::GLink{Dim}) where {Dim}
    if x.isdag != y.isdag
        return false
    end

    if x.direction == y.direction && x.position == y.position
        return true
    else
        return false
    end
end

function ==(x::Wilsonline{Dim}, y::Wilsonline{Dim}) where {Dim}
    flag = true
    if length(x) != length(y)
        return false
    end

    for i = 1:length(x)
        if x[i] != y[i]
            return false
        end
    end
    return true
end

struct DwDU{Dim}
    parent::Wilsonline{Dim}
    insertindex::Int64
    position::NTuple{Dim,Int64}
    leftlinks::Wilsonline{Dim}
    rightlinks::Wilsonline{Dim}
    μ::Int8
end

function get_leftlinks(dw::DwDU)
    return dw.leftlinks
end

function get_rightlinks(dw::DwDU)
    return dw.rightlinks
end

function get_position(dw::DwDU)
    return dw.position
end



function Base.push!(w::Wilsonline, link)
    push!(w.glinks, link)
end

function Base.append!(w::Wilsonline, a::Wilsonline)
    append!(w.glinks, a.glinks)
end

function Base.length(w::Wilsonline)
    return length(w.glinks)
end

function Base.getindex(w::Wilsonline, i)
    return w.glinks[i]
end

function Base.lastindex(w::Wilsonline)
    return length(w)
end

function LinearAlgebra.adjoint(w::Wilsonline{Dim}) where {Dim}
    wa = Wilsonline(; Dim = Dim)
    numlinks = length(w)
    for i = numlinks:-1:1
        push!(wa, w[i]')
    end
    return wa
end

function LinearAlgebra.adjoint(ws::Array{<:Wilsonline{Dim},1}) where {Dim}
    num = length(ws)
    wad = Array{eltype(ws),1}(undef, num)
    for i = 1:num
        wad[i] = ws[i]'
    end
    return wad
end


function Base.show(io::IO, ws::Array{<:Wilsonline{Dim},1}) where {Dim}
    for i = 1:length(ws)
        if i == 1
            st = "st"
        elseif i == 2
            st = "nd"
        elseif i == 3
            st = "rd"
        else
            st = "th"
        end
        println(io, "$i-$st loop")
        show(io, ws[i])
        #display(io,ws[i])
    end
end

function Base.display(ws::Array{<:Wilsonline{Dim},1}) where {Dim}
    for i = 1:length(ws)
        if i == 1
            st = "st"
        elseif i == 2
            st = "nd"
        elseif i == 3
            st = "rd"
        else
            st = "th"
        end
        println("$i-$st loop")
        display(ws[i])
    end
end

function get_printstring_direction(glink::Gaugelink{Dim}) where {Dim}

    nstring = "n"

    position = get_position(glink)
    for μ = 1:Dim
        m = position[μ]
        if m != 0
            if abs(m) == 1
                if m > 0
                    nstring = nstring * "+e_{$(μ)}"
                else
                    nstring = nstring * "-e_{$(μ)}"
                end
            else
                if m > 0
                    nstring = nstring * "+$(m)e_{$(μ)}"
                else
                    nstring = nstring * "-$(abs(m))e_{$(μ)}"
                end
            end
        end
    end
    return nstring
end

function get_printstring(glink::Gaugelink{Dim}) where {Dim}
    direction = get_direction(glink)
    dagornot = ifelse(glink.isdag, "^{\\dagger}","")
    #dagornot = ifelse(typeof(glink) <: GLink, "", "^{\\dagger}")
    nstring = get_printstring_direction(glink)
    return "U$(dagornot)_{$(direction)}($(nstring))"
end

function Base.show(io::IO, glink::Gaugelink{Dim}) where {Dim}
    outputstring = get_printstring(glink)
    show(io, latexstring(outputstring))
    return latexstring(outputstring)
end


function Base.show(io::IO, w::Wilsonline{Dim}) where {Dim}
    outputstring = ""
    for (i, glink) in enumerate(w.glinks)
        outputstring = outputstring * get_printstring(glink)
    end
    show(io, latexstring(outputstring))
    println("\t")
    #println(io,outputstring)
    #return latexstring(outputstring)
end

function make_staple(w::Wilsonline{Dim}, μ) where {Dim}
    dwdUs = derive_U(w, μ)
    numstaples = length(dwdUs)
    staple = Array{typeof(w),1}(undef, numstaples)
    for i = 1:numstaples
        wi = Wilsonline(Dim = Dim)
        append!(wi, get_rightlinks(dwdUs[i]))
        append!(wi, get_leftlinks(dwdUs[i]))
        staple[i] = wi
    end
    return staple
end

function make_Cμ(w::Wilsonline{Dim}, μ) where {Dim}
    V1 = make_staple(w, μ)
    V2 = make_staple(w', μ)
    C = eltype(V1)[]
    for i = 1:length(V1)
        push!(C, V1[i]')
    end
    for i = 1:length(V2)
        push!(C, V2[i]')
    end
    return C
end

function make_staple_and_loop(w::Wilsonline{Dim}, μ) where {Dim}
    C = make_staple(w, μ)
    append!(C, make_staple(w', μ))
    numstaple = length(C)
    CUdag = Array{typeof(w),1}(undef, numstaple)
    Udag = GLink{Dim}(μ, (0, 0, 0, 0))'
    for i = 1:numstaple
        CUdag[i] = deepcopy(C[i])'
        push!(CUdag[i], Udag)
        #CUdag[i] = CUdag[i]'
    end
    return CUdag
end

function check_link(w, μ)
    numlinks = length(w)
    linkindices = Int64[]
    for i = 1:numlinks
        link = w[i]
        if link.isdag == false
            #typeof(link) <: GLink
            if link.direction == μ
                append!(linkindices, i)
            end
        end
    end
    return linkindices
end

function check_link_dag(w, μ)
    numlinks = length(w)
    linkindices = Int64[]
    for i = 1:numlinks
        link = w[i]
        if link.isdag
            #if typeof(link) <: Adjoint_GLink
            if get_direction(link) == μ
                append!(linkindices, i)
            end
        end
    end
    return linkindices
end

"""
    like U U U U -> U U otimes U 
"""
function derive_U(w::Wilsonline{Dim}, μ) where {Dim}
    numlinks = length(w)
    linkindices = check_link(w, μ)
    numstaples = length(linkindices)
    dwdU = Array{DwDU{Dim},1}(undef, numstaples)

    for (i, ith) in enumerate(linkindices)
        #wi =Wilsonline(Dim=Dim)
        rightlinks = Wilsonline(Dim = Dim)
        leftlinks = Wilsonline(Dim = Dim)
        origin = w[ith].position
        position = zero(collect(origin))
        position[w[ith].direction] += 1

        for j = ith+1:numlinks
            link = w[j]

            if link.isdag == false
                #if typeof(link) <: GLink 
                link_rev = set_position(link, Tuple(position))
                position[get_direction(link)] += 1
            else
                position[get_direction(link)] += -1
                link_rev = set_position(link, Tuple(position))
            end
            push!(rightlinks, link_rev)

            #push!(rightlinks,link) 
        end

        for j = 1:ith-1
            link = w[j]

            position = collect(get_position(link)) .- origin
            link_rev = set_position(link, Tuple(position))
            push!(leftlinks, link_rev)

            #push!(leftlinks,link)
        end
        dwdU[i] = DwDU{Dim}(w, ith, origin, leftlinks, rightlinks, μ)
        #println("μ = ",μ)
        #display(wi)
    end
    return dwdU
end

"""
    like U U U U -> U U otimes U 
"""
function derive_Udag(w::Wilsonline{Dim}, μ) where {Dim}
    #error("not yet")
    numlinks = length(w)
    linkindices = check_link_dag(w, μ)
    numstaples = length(linkindices)
    dwdUdag = Array{DwDU{Dim},1}(undef, numstaples)

    for (i, ith) in enumerate(linkindices)
        #wi =Wilsonline(Dim=Dim)
        rightlinks = Wilsonline(Dim = Dim)
        leftlinks = Wilsonline(Dim = Dim)
        origin = get_position(w[ith]) #.position
        position = zero(collect(origin))
        #position[w[ith].direction] += 1

        for j = ith+1:numlinks
            link = w[j]

            push!(rightlinks, link)
        end

        for j = 1:ith-1
            link = w[j]

            push!(leftlinks, link)
        end
        dwdUdag[i] = DwDU{Dim}(w, ith, origin, leftlinks, rightlinks, μ)
        #println("μ = ",μ)
        #display(wi)
    end
    return dwdUdag
end

function Base.display(dwdU::DwDU{Dim}) where {Dim}
    outputstring = ""
    if length(dwdU.leftlinks.glinks) == 0
        outputstring = outputstring * "I "
    else
        for glink in dwdU.leftlinks.glinks
            outputstring = outputstring * get_printstring(glink)
        end
    end

    outputstring = outputstring * " \\otimes "

    if length(dwdU.rightlinks.glinks) == 0
        outputstring = outputstring * "I "
    else
        for glink in dwdU.rightlinks.glinks
            outputstring = outputstring * get_printstring(glink)
        end
    end

    nstring = get_printstring_direction(dwdU.parent.glinks[dwdU.insertindex])

    outputstring = outputstring * "\\delta_{m,$(nstring)}"

    println(outputstring)
    return outputstring
end

function Base.show(io::IO, dwdU::Array{DwDU{Dim},1}) where {Dim}
    for i = 1:length(dwdU)
        if i == 1
            st = "st"
        elseif i == 2
            st = "nd"
        elseif i == 3
            st = "rd"
        else
            st = "th"
        end
        println("$i-$st loop")
        show(dwdU[i])

    end
end

function Base.show(io::IO, dwdU::DwDU{Dim}) where {Dim}
    outputstring = ""
    if length(dwdU.leftlinks.glinks) == 0
        outputstring = outputstring * "I "
    else
        for glink in dwdU.leftlinks.glinks
            outputstring = outputstring * get_printstring(glink)
        end
    end

    outputstring = outputstring * " \\otimes "

    if length(dwdU.rightlinks.glinks) == 0
        outputstring = outputstring * "I "
    else
        for glink in dwdU.rightlinks.glinks
            outputstring = outputstring * get_printstring(glink)
        end
    end

    nstring = get_printstring_direction(dwdU.parent.glinks[dwdU.insertindex])

    outputstring = outputstring * "\\delta_{m,$(nstring)}"

    show(io, latexstring(outputstring))
    println("\t")
    #println(outputstring)
    return outputstring
end

function make_links(segments::Array{Tuple{T,T},1}) where {T<:Integer}
    links = Tuple{Int8,Int8}[]
    for segment in segments
        s = sign(segment[2])
        if segment[2] == 0
            push!(links, (segment[1], 0))
        else
            #@assert segment[2] != 0
            for i = 1:abs(segment[2])
                push!(links, (segment[1], s * 1))
            end
        end
    end
    return links
end

function make_plaq(μ, ν; Dim = 4)
    return Wilsonline([(μ, 1), (ν, 1), (μ, -1), (ν, -1)], Dim = Dim)
end

function make_plaq(; Dim = 4)
    loops = Wilsonline{Dim}[]
    for μ = 1:Dim
        #for ν=1:4
        for ν = μ:Dim
            if ν == μ
                continue
            end

            plaq = make_plaq(μ, ν, Dim = Dim)
            push!(loops, plaq)
        end
    end
    return loops
end

function construct_plaq()
    loops_plaq = Dict{Tuple{Int8,Int8,Int8},Any}()
    for Dim = 1:4
        for μ = 1:Dim
            for ν = μ:Dim
                if μ == ν
                    continue
                end
                loops_plaq[(Dim, μ, ν)] = make_plaq(μ, ν, Dim = Dim)
            end
        end
    end
    return loops_plaq
end

function make_rect(; Dim = 4)
    loops = Wilsonline{Dim}[]
    for μ = 1:Dim
        for ν = μ:Dim
            if ν == μ
                continue
            end
            #loop = make_links([(μ,1),(ν,2),(μ,-1),(ν,-2)])

            loop1 = Wilsonline([(μ, 1), (ν, 2), (μ, -1), (ν, -2)], Dim = Dim)
            #loop1 = Wilson_loop([(μ,1),(ν,2),(μ,-1),(ν,-2)])
            #loop1 = Wilson_loop(loop,Tuple(origin))
            push!(loops, loop1)
            loop1 = Wilsonline([(μ, 2), (ν, 1), (μ, -2), (ν, -1)], Dim = Dim)
            #loop1 = Wilson_loop([(μ,2),(ν,1),(μ,-2),(ν,-1)])
            push!(loops, loop1)
        end
    end
    return loops
end

function construct_rect()
    loops_rect = Dict{Tuple{Int8,Int8,Int8,Int8},Any}()
    for Dim = 1:4
        for μ = 1:Dim
            for ν = μ:Dim
                if μ == ν
                    continue
                end
                loops_rect[(Dim, μ, ν, 1)] =
                    Wilsonline([(μ, 1), (ν, 2), (μ, -1), (ν, -2)], Dim = Dim)
                loops_rect[(Dim, μ, ν, 2)] =
                    Wilsonline([(μ, 2), (ν, 1), (μ, -2), (ν, -1)], Dim = Dim)
            end
        end
    end
    return loops_rect
end

function make_cloverloops(μ, ν; Dim = 4)
    loops = Wilsonline{Dim}[]
    loop_righttop = Wilsonline([(μ, 1), (ν, 1), (μ, -1), (ν, -1)])
    loop_lefttop = Wilsonline([(ν, 1), (μ, -1), (ν, -1), (μ, 1)])
    loop_rightbottom = Wilsonline([(ν, -1), (μ, 1), (ν, 1), (μ, -1)])
    loop_leftbottom = Wilsonline([(μ, -1), (ν, -1), (μ, 1), (ν, 1)])
    push!(loops, loop_righttop)
    push!(loops, loop_lefttop)
    push!(loops, loop_rightbottom)
    push!(loops, loop_leftbottom)
    return loops
end


function make_polyakov(μ, Lμ; Dim = 4)
    loops = Wilsonline{Dim}[]
    loop1 = Wilsonline([(μ, Lμ)], Dim = Dim)
    push!(loops, loop1)
    return loops
end

function make_polyakov_xyz(Lμ; Dim = 4)
    loops = Wilsonline{Dim}[]
    for μ = 1:3
        loop1 = Wilsonline([(μ, Lμ)], Dim = Dim)
        push!(loops, loop1)
    end
    return loops
end


function make_loopforactions(couplinglist, L)
    Dim = length(L)
    loops = Array{Array{Wilsonline{Dim},1},1}(undef, length(couplinglist))
    for (i, name) in enumerate(couplinglist)
        if name == "plaquette"
            loops[i] = make_plaq(Dim = Dim)
        elseif name == "rectangular"
            loops[i] = make_rect(Dim = Dim)
        elseif name == "chair"
            loops[i] = make_chair(Dim = Dim)
        elseif name == "polyakov_t"
            μ = Dim
            loops[i] = make_polyakov(μ, L[μ], Dim = Dim)
        elseif name == "polyakov_z"
            @assert Dim > 3 "Dimension should be Dim > 3 but now Dim = $Dim"
            μ = 3
            loops[i] = make_polyakov(μ, L[μ], Dim = Dim)
        elseif name == "polyakov_y"
            @assert Dim > 2 "Dimension should be Dim > 2 but now Dim = $Dim"
            μ = 2
            loops[i] = make_polyakov(μ, L[μ], Dim = Dim)
        elseif name == "polyakov_x"
            μ = 1
            loops[i] = make_polyakov(μ, L[μ], Dim = Dim)
        else
            error("$name is not supported!")
        end
    end
    return loops
end

function make_loops_fromname(name; Dim = 4, L = nothing)
    if L != nothing
        @assert Dim == length(L)
    end

    if name == "plaquette"
        loops = make_plaq(Dim = Dim)
    elseif name == "rectangular"
        loops = make_rect(Dim = Dim)
    elseif name == "chair"
        loops = make_chair(Dim = Dim)
    elseif name == "polyakov_t"
        @assert L != nothing "system size should be given to obtain polyakov loops. please do like make_loops(\"polyakov_t\";Dim=4,L=[4,4,4,4])"
        μ = Dim
        loops = make_polyakov(μ, L[μ], Dim = Dim)
    elseif name == "polyakov_z"
        @assert L != nothing "system size should be given to obtain polyakov loops. please do like make_loops(\"polyakov_z\";Dim=4,L=[4,4,4,4])"
        @assert Dim > 3 "Dimension should be Dim > 3 but now Dim = $Dim"
        μ = 3
        loops = make_polyakov(μ, L[μ], Dim = Dim)
    elseif name == "polyakov_y"
        @assert L != nothing "system size should be given to obtain polyakov loops. please do like make_loops(\"polyakov_y\";Dim=4,L=[4,4,4,4])"
        @assert Dim > 2 "Dimension should be Dim > 2 but now Dim = $Dim"
        μ = 2
        loops = make_polyakov(μ, L[μ], Dim = Dim)
    elseif name == "polyakov_x"
        @assert L != nothing "system size should be given to obtain polyakov loops. please do like make_loops(\"polyakov_x\";Dim=4,L=[4,4,4,4])"
        μ = 1
        loops = make_polyakov(μ, L[μ], Dim = Dim)
    else
        error("$name is not supported!")
    end

    return loops
end

function make_chair(; Dim = 4)
    @assert Dim == 4 "only Dim = 4 is supported now"
    #loopset = []
    loopset = Wilsonline{Dim}[]
    set1 = (1, 2, 3)
    set2 = (1, 2, 4)
    set3 = (2, 3, 4)
    set4 = (1, 3, 4)

    for set in (set1, set2, set3, set4)
        mu, nu, rho = set
        origin = zeros(Int8, 4)
        loop = [(mu, 1), (nu, 1), (rho, 1), (mu, -1), (rho, -1), (nu, -1)]
        loop1 = Wilsonline(loop, Dim = Dim)
        push!(loopset, loop1)

        mu, rho, nu = set
        loop = [(mu, 1), (nu, 1), (rho, 1), (mu, -1), (rho, -1), (nu, -1)]
        loop1 = Wilsonline(loop, Dim = Dim)
        push!(loopset, loop1)

        nu, rho, mu = set
        loop = [(mu, 1), (nu, 1), (rho, 1), (mu, -1), (rho, -1), (nu, -1)]
        loop1 = Wilsonline(loop, Dim = Dim)
        push!(loopset, loop1)

        nu, mu, rho = set
        loop = [(mu, 1), (nu, 1), (rho, 1), (mu, -1), (rho, -1), (nu, -1)]
        loop1 = Wilsonline(loop, Dim = Dim)
        push!(loopset, loop1)

        rho, mu, nu = set
        loop = [(mu, 1), (nu, 1), (rho, 1), (mu, -1), (rho, -1), (nu, -1)]
        loop1 = Wilsonline(loop, Dim = Dim)
        push!(loopset, loop1)

        rho, nu, mu = set
        loop = [(mu, 1), (nu, 1), (rho, 1), (mu, -1), (rho, -1), (nu, -1)]
        loop1 = Wilsonline(loop, Dim = Dim)
        push!(loopset, loop1)

    end
    return loopset
end


function make_plaq_staple(μ; Dim = 4)
    loops = Wilsonline{Dim}[]
    plaqs = make_plaq(Dim = Dim)
    numplaq = length(plaqs)
    for i = 1:numplaq
        plaq = plaqs[i]
        staples = make_staple(plaq, μ)
        for j = 1:length(staples)
            push!(loops, staples[j])
        end

        plaqdag = plaqs[i]'
        staples = make_staple(plaqdag, μ)
        for j = 1:length(staples)
            push!(loops, staples[j])
        end
    end

    return loops
end

function construct_staple_prime()
    loops_staple_prime = Dict{Tuple{Int8,Int8},Any}()
    for Dim = 1:4
        for μ = 1:Dim
            loops_staple_prime[(Dim, μ)] = make_plaq_staple(μ, Dim = Dim)'
        end
    end
    return loops_staple_prime
end

function construct_staple()
    loops_staple = Dict{Tuple{Int8,Int8},Any}()
    for Dim = 1:4
        for μ = 1:Dim
            loops_staple[(Dim, μ)] = make_plaq_staple(μ, Dim = Dim)
        end
    end
    return loops_staple
end


const loops_staple_prime = construct_staple_prime()
const loops_staple = construct_staple()
const loops_plaq = construct_plaq()
const loops_rect = construct_rect()

function check_plaqset(wi::Wilsonline{Dim}) where {Dim}
    flag = false
    for μ = 1:Dim
        for ν = μ:Dim
            if μ == ν
                continue
            end
            loop = loops_plaq[(Dim, μ, ν)]
            if loop == wi
                #println("match!")
                flag = true
                break
            end
        end
        if flag
            continue
        end
    end

    return flag
end

function check_plaqset(w::Vector{Wilsonline{Dim}}) where {Dim}
    flag = false
    for wi in w
        flag = check_plaqset(wi)
        if flag != true
            return false
        end
    end

    return flag
end

function check_rectset(wi::Wilsonline{Dim}) where {Dim}
    flag = false
    direction = (0, 0)
    for μ = 1:Dim
        for ν = μ:Dim
            if μ == ν
                continue
            end
            loop = loops_rect[(Dim, μ, ν, 1)]
            if loop == wi
                #println("match!")
                direction = (μ, ν)
                flag = true
                break
            end

            loop = loops_rect[(Dim, μ, ν, 2)]
            if loop == wi
                #println("match!")
                direction = (μ, ν)
                flag = true
                break
            end
        end
        if flag
            continue
        end
    end

    return flag, direction
end

function check_rectset(w::Vector{Wilsonline{Dim}}) where {Dim}
    flag = false
    direction = (0, 0)
    for wi in w
        flag, direction = check_rectset(wi)
        if flag != true
            return false, direction
        end
    end

    return flag, direction
end



end
