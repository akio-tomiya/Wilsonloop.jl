using Wilsonloop
using Documenter

DocMeta.setdocmeta!(Wilsonloop, :DocTestSetup, :(using Wilsonloop); recursive=true)

makedocs(;
    modules=[Wilsonloop],
    authors="cometscome <cometscome@gmail.com> and contributors",
    repo="https://github.com/cometscome/Wilsonloop.jl/blob/{commit}{path}#{line}",
    sitename="Wilsonloop.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://cometscome.github.io/Wilsonloop.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/cometscome/Wilsonloop.jl",
    devbranch="main",
)
