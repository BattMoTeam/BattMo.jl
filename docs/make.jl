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
		"Tutorial 1 - Useful tools" => "1_useful_tools",
		"Tutorial 2 - Run a simulation" => "2_run_a_simulation",
		"Tutorial 3 - Handle outputs" => "3_handle_outputs",
		"Tutorial 4 - Select a model" => "4_select_a_model",
		"Tutorial 5 - Create parameter sets" => "5_create_parameter_sets",
		"Tutorial 6 - Handle cell parameters" => "6_handle_cell_parameters",
		"Tutorial 7 - Handle cycling protocol" => "7_handle_cycling_protocols",
		"Tutorial 8 - Compute cell KPIs" => "8_compute_cell_kpis",
		"Tutorial 9 - Run a parameter sweep" => "9_run_parameter_sweep",
		"Tutorial 10 - Handle grid and time resolution" => "10_handling_grid_time_resolution",
		"Tutorial 11 - Handle solver settings" => "11_handling_solver_settings",
	]

	examples = [
		"Cycle example" => "example_cycle",
		"1D plotting" => "example_1d_plotting",
		"Drive cycle example" => "example_run_current_function",
		"3D Pouch example" => "example_3D_pouch",
		"3D cylindrical" => "example_3D_cylindrical",
		"Calibration example" => "example_calibration",
		"SEI layer growth" => "example_sei",
		"DFN sodiun ion " => "example_chayambuka",
		"Headless UI " => "example_headless",
	]

	tutorials_markdown = []
	examples_markdown = []
	function update_footer(content, pth, dir)
		return content * "\n\n # ## Example on GitHub\n " *
			   "# If you would like to run this example yourself, it can be downloaded from " *
			   "the BattMo.jl GitHub repository [as a script](https://github.com/BattMoTeam/BattMo.jl/blob/main/$dir/$pth.jl)."#, " *
		#"or as a [Jupyter Notebook](https://github.com/BattMoTeam/BattMo.jl/blob/gh-pages/dev/final_site/notebooks/$pth.ipynb)"
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
			upd(content) = update_footer(content, pth, "examples/beginner_tutorials")
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
			upd(content) = update_footer(content, pth, "examples")
			Literate.markdown(in_pth, examples_out_dir, preprocess = upd)
		end
	end
	## Docs
	if isnothing(build_format)
		build_format = DocumenterVitepress.MarkdownVitepress(
			repo = "github.com/BattMoTeam/BattMo.jl.git",
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
		"Battery models" => [
		"Lithium ion model" => "manuals/user_guide/pxd_model.md"
		"Sodium ion model" => "manuals/user_guide/sodium_ion_model.md"
	],
		"Sub-models" => [
		"Overview" => "manuals/user_guide/sub_models.md",
		"Ramp up" => "manuals/user_guide/ramp_up.md",
		"SEI" => "manuals/user_guide/sei_model.md",
		"Temperature dependence" => "manuals/user_guide/arrhenius.md"
	],
		"Public API" => [
		"Input terminology" => "manuals/user_guide/terminology.md",
		"Simulation dependent input parameters" => "manuals/user_guide/simulation_dependent_input.md",
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
	],
		"PyBattMo" => [
		"Installation" => "manuals/pybattmo/installation.md",
		"Examples" => "manuals/pybattmo/examples.md"
	]],
	)
	if build_notebooks
		# Subfolder of final site build folder
		notebook_dir = joinpath(@__DIR__, "src", "public", "notebooks")
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
		DocumenterVitepress.deploydocs(;
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
