using BattMo
using Jutul
using Literate
using Documenter
using GLMakie

using DocumenterCitations
using DocumenterVitepress
##
cd(@__DIR__)
function build_battmo_docs(build_format              = nothing;
	build_examples            = true,
	build_tutorials           = build_examples,
	build_validation_examples = build_examples,
	build_notebooks           = true,
	clean                     = true,
	deploy                    = true,
)

	# In case we want to include docs of Jutul functions
	DocMeta.setdocmeta!(BattMo, :DocTestSetup, :(using BattMo; using Jutul); recursive = true)
	DocMeta.setdocmeta!(Jutul, :DocTestSetup, :(using Jutul); recursive = true)
	bib = CitationBibliography(joinpath(@__DIR__, "src", "refs.bib"))

	## Literate pass
	# Base directory
	battmo_dir = realpath(joinpath(@__DIR__, ".."))
	# Convert examples as .jl files to markdown
	tutorials = [
		"Tutorial 1 - Run a simulation" => "1_run_a_simulation",
		"Tutorial 2 - Specify a model" => "2_specify_a_model",
		"Tutorial 3 - Modify cell parameters" => "3_modify_cell_parameters",
		"Tutorial 4 - Modify cycling protocol" => "4_modify_cycling_protocol"]

	examples = [
		"Cycle example" => "example_cycle",
		"3D demo example" => "example_3d_demo",
		"SEI layer growth" => "example_sei",
	]

	tutorials_markdown = []
	examples_markdown = []
	function update_footer(content, pth)
		return content * "\n\n # ## Example on GitHub\n " *
			   "# If you would like to run this example yourself, it can be downloaded from " *
			   "the BattMo.jl GitHub repository [as a script](https://github.com/BattMoTeam/BattMo.jl/blob/main/examples/$pth.jl), " *
			   "or as a [Jupyter Notebook](https://github.com/BattMoTeam/BattMo.jl/blob/gh-pages/dev/final_site/notebooks/$pth.ipynb)"
	end
	if clean
		for (ex, pth) in tutorials
			delpath = joinpath(@__DIR__, "src", "tutorials", "$pth.md")
			if isfile(delpath)
				println("Deleting generated example \"$ex\":\n\t$delpath")
				rm(delpath)
			else
				println("Did not find generated example \"$ex\", skipping removal:\n\t$delpath")
			end
		end
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
	tutorial_path(pth) = joinpath(battmo_dir, "examples", "beginner_tutorials", "$pth.jl")
	example_path(pth) = joinpath(battmo_dir, "examples", "$pth.jl")
	examples_out_dir = joinpath(@__DIR__, "src", "examples")
	tutorials_out_dir = joinpath(@__DIR__, "src", "tutorials")
	notebook_dir = joinpath(@__DIR__, "assets")
	for (ex, pth) in tutorials
		in_pth = tutorial_path(pth)
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
				ex_dest = tutorials_markdown
			end
			do_build = build_tutorials
		end
		if do_build
			push!(ex_dest, ex => joinpath("tutorials", "$pth.md"))
			upd(content) = update_footer(content, pth)
			Literate.markdown(in_pth, tutorials_out_dir, preprocess = upd)
		end
	end
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
			Literate.markdown(in_pth, examples_out_dir, preprocess = upd)
		end
	end
	## Docs
	if isnothing(build_format)
		build_format = DocumenterVitepress.MarkdownVitepress(
			repo = "github.com/BattMoTeam/BattMo.jl",
			devbranch = "main",
			devurl = "dev",
		)
	end

	makedocs(;
		modules  = [BattMo],
		authors  = "SINTEF BattMo team and contributors",
		repo     = "https://github.com/BattMoTeam/BattMo.jl/blob/{commit}{path}#{line}",
		sitename = "BattMo.jl",
		warnonly = [:missing_docs],
		plugins  = [bib],
		format   = build_format,
		draft    = false,
		source   = "src",
		build    = "build",
		pages    = [
		"User Guide" => [
		"Getting started" => [
		"Installation" => "manuals/user_guide/installation.md",
		"Getting started" => "manuals/user_guide/getting_started.md"
	],
		"Models and architecture" => [
		"Models" => "manuals/user_guide/models.md"
	],
		"Public API" => [
		"Input terminology" => "manuals/user_guide/terminology.md",
		"Functions and types" => "manuals/user_guide/public_api.md"
	],
		"Tutorials" => tutorials_markdown
	],
		"Examples" => [
		"Advanced examples" => examples_markdown
	],
		"API Documentation" => [
		"High level API" => "manuals/api_documentation/highlevel.md"
	],
		"Contribution guide" => [
		"Contribute to BattMo.jl" => "manuals/contribution/contribution.md"
		"Jutul" => "manuals/contribution/jutul_integration.md"
	],
		"References" => [
		"Bibliography" => "extras/refs.md"
	]],
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

		for (ex, pth) in tutorials
			in_pth = tutorial_path(pth)
			@info "$ex Writing notebook to $notebook_dir"
			Literate.notebook(in_pth, notebook_dir, execute = false)
		end
	end
	if deploy
		deploydocs(;
			repo = "github.com/BattMoTeam/BattMo.jl",
			devbranch = "main",
			target = "build", # this is where Vitepress stores its output
			branch = "gh-pages",
			push_preview = true,
		)
	end
	GLMakie.closeall()
end
##
# build_battmo_docs(build_examples = false, build_validation_examples = false)
build_battmo_docs()
