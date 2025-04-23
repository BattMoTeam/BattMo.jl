export write_to_json_file

function write_to_json_file(file_path::String, data::AbstractInput)
	try
		open(file_path, "w") do io
			JSON.print(io, data.all, 4)
		end
		println("Data successfully written to $file_path")
	catch e
		println("An error occurred while writing to the file: $e")
	end
end
