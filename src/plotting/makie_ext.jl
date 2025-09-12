function independent_figure end
function independent_figure_GLMakie end
function independent_figure_WGLMakie end

function check_plotting_availability(; throw = true)
	ok = true
	try
		ok = check_plotting_availability_impl()
	catch e
		if throw
			if e isa MethodError
				error("""Plotting is not available. You need to have either a GLMakie or WGLMakie backend available. 
					GLMakie opens the plots in a separate window and is recommended for interactive plots.
					WGLMakie renders the plots in your browser. 

					To fix: using Pkg; Pkg.add(\"GLMakie\") and then call using GLMakie to enable plotting.
					
					or: using Pkg; Pkg.add(\"WGLMakie\") and then call using WGLMakie, activate_browser(), and using BattMoGLMakieExt to enable plotting.
					
					""")
			else
				rethrow(e)
			end
		else
			ok = false
		end
	end
	return ok
end

function check_plotting_availability_impl

end
