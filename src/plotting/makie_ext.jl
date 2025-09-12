export activate_browser, deactivate_browser

function activate_browser()
	ENV["Browser"] = "true"
end

function deactivate_browser()
	ENV["Browser"] = "false"
end

function independent_figure(fig)
	display(fig)
end


function check_plotting_availability(; throw = true, interactive = false)
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
	if interactive
		plotting_check_interactive()
	end
	return ok
end

function check_plotting_availability_impl

end
