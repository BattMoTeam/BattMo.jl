using BattMo
using Jutul
using Literate
using Documenter
using GLMakie

using DocumenterCitations
using DocumenterVitepress
##
cd(@__DIR__)
function build_battmo_docs(build_format = nothing;
        build_examples = true,
        build_validation_examples = build_examples,
        build_notebooks = true,
        clean = true,
        deploy = true
    )
    # In case we want to include docs of Jutul functions
    DocMeta.setdocmeta!(BattMo, :DocTestSetup, :(using BattMo; using Jutul); recursive=true)
    DocMeta.setdocmeta!(Jutul, :DocTestSetup, :(using Jutul); recursive=true)
    bib = CitationBibliography(joinpath(@__DIR__, "src", "refs.bib"))

    ## Literate pass
    # Base directory
    jutul_dir = realpath(joinpath(@__DIR__, ".."))
    # Convert examples as .jl files to markdown
    examples = [
        "Cycling example" => "example_cycle",
        "Battery example" => "example_battery",
        "3D demo example" => "example_3d_demo",
    ]
    examples_markdown = []
    validation_markdown = []
    intros_markdown = []
    function update_footer(content, pth)
        return content*"\n\n # ## Example on GitHub\n "*
        "# If you would like to run this example yourself, it can be downloaded from "*
        "the BattMo.jl GitHub repository [as a script](https://https://github.com/BattMoTeam/BattMo.jl/blob/main/examples/$pth.jl), "*
        "or as a [Jupyter Notebook](https://https://github.com/BattMoTeam/BattMo.jl/blob/gh-pages/dev/final_site/notebooks/$pth.ipynb)"
    end
    if clean
        for (ex, pth) in examples
            delpath = joinpath(@__DIR__, "src", "examples", "$pth.md")
            if isfile(delpath)
                println("Deleting generated example \"$ex\":\n\t$delpath")
                rm(delpath)
            else
                println("Did not find generated example \"$ex\", skipping removal:\n\t$delpath")
            end
        end
    end
    example_path(pth) = joinpath(jutul_dir, "examples", "$pth.jl")
    out_dir = joinpath(@__DIR__, "src", "examples")
    notebook_dir = joinpath(@__DIR__, "assets")
    for (ex, pth) in examples
        in_pth = example_path(pth)
        is_validation = startswith(ex, "Validation:")
        is_intro = startswith(ex, "Intro: ")
        is_example = !(is_intro || is_validation)
        if is_validation
            ex_dest = validation_markdown
            do_build = build_validation_examples
        else
            if is_intro
                ex_dest = intros_markdown
            else
                ex_dest = examples_markdown
            end
            do_build = build_examples
        end
        if do_build
            push!(ex_dest, ex => joinpath("examples", "$pth.md"))
            upd(content) = update_footer(content, pth)
            Literate.markdown(in_pth, out_dir, preprocess = upd)
        end
    end
    ## Docs
    if isnothing(build_format)
        build_format = DocumenterVitepress.MarkdownVitepress(
            repo = "github.com/sintefmath/BattMo.jl",
            devbranch = "main",
            devurl = "dev"
        )
    end
    makedocs(;
        modules=[BattMo, Jutul],
        authors="SINTEF BattMo team and contributors",
        repo="https://https://github.com/BattMoTeam/BattMo.jl/blob/{commit}{path}#{line}",
        sitename="BattMo.jl",
        warnonly = true,
        plugins=[bib],
        format=build_format,
        pages=[
            "Introduction" => [
                "BattMo.jl" => "index.md",
            ],
            "Manual" => [
                "High level API" => "man/highlevel.md",
            ],
            "Examples: Introduction" => intros_markdown,
            "Examples: Usage" => examples_markdown,
            "Examples: Validation" => validation_markdown
        ],
    )
    if build_notebooks
        # Subfolder of final site build folder
        notebook_dir = joinpath(@__DIR__, "build", "final_site", "notebooks")
        mkpath(notebook_dir)
        for (ex, pth) in examples
            in_pth = example_path(pth)
            @info "$ex Writing notebook to $notebook_dir"
            Literate.notebook(in_pth, notebook_dir, execute = false)
        end
    end
    if deploy
        deploydocs(;
            repo="https://github.com/BattMoTeam/BattMo.jl.git",
            devbranch="main",
            target = "build", # this is where Vitepress stores its output
            branch = "gh-pages",
            push_preview = true
        )
    end
    GLMakie.closeall()
end
##
# build_battmo_docs(build_examples = false, build_validation_examples = false)
build_battmo_docs()
