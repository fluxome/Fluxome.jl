using Fluxome
using Documenter

DocMeta.setdocmeta!(Fluxome, :DocTestSetup, :(using Fluxome); recursive = true)

makedocs(;
    modules = [Fluxome],
    authors = "Fluxome Contributors",
    repo = "https://github.com/fluxome/Fluxome.jl/blob/{commit}{path}#{line}",
    sitename = "Fluxome.jl",
    format = Documenter.HTML(;
        prettyurls = get(ENV, "CI", "false") == "true",
        canonical = "https://fluxome.github.io/Fluxome.jl",
        edit_link = "main",
        assets = String[]
    ),
    pages = [
        "Home" => "index.md"
    ]
)

deploydocs(;
    repo = "github.com/fluxome/Fluxome.jl",
    devbranch = "main"
)
