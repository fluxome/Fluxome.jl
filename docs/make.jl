using fluxome
using Documenter

DocMeta.setdocmeta!(fluxome, :DocTestSetup, :(using fluxome); recursive=true)

makedocs(;
    modules=[fluxome],
    authors="Biotheory Lab",
    repo="https://github.com/biotheorylab/fluxome.jl/blob/{commit}{path}#{line}",
    sitename="fluxome.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://biotheorylab.github.io/fluxome.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/biotheorylab/fluxome.jl",
    devbranch="main",
)
