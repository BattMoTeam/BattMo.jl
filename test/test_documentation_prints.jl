using BattMo
using Test
using HTTP

@testset "Submodel documentation links" begin
	meta_data = BattMo.get_parameter_meta_data()

	for (param, info) in meta_data
		if get(info, "is_sub_model", false)
			doc_url = get(info, "documentation", nothing)

			if isnothing(doc_url) || doc_url == "-"
				@info "No documentation URL for submodel: $param"
				continue
			end

			@testset "$param" begin
				try
					response = HTTP.get(doc_url; redirect_limit = 5, readtimeout = 10)
					@test response.status == 200
				catch e
					@warn "Failed to access URL for $param: $doc_url" exception = e
					@test false  # Fails the test
				end
			end
		end
	end
end
