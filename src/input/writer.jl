export write_to_json_file


"""
	write_to_json_file(file_path::String, data::AbstractInput)
	write_to_json_file(file_path::String, data::AbstractDict)

Writes the contents of `data` to a JSON file at the specified `file_path`.

# Arguments
- `file_path::String`: The path (including filename) where the JSON file will be saved.
- `data`: A dictionary to serialize, or an `AbstractInput` whose `.all` field/property contains the data to write.

# Behavior
- Opens the file at `file_path` in write mode.
- Serializes the dictionary to JSON format with indentation of 4 spaces.
- Sorts dictionary keys alphabetically at every nesting level, including objects inside arrays.
- Writes the JSON data to the file.
- Prints a success message upon completion.
- If an error occurs (e.g., file system permission issues), catches the exception and prints an error message.

# Returns
- Nothing (side-effect only: writes file and prints status messages).

# Example
```julia
write_to_json_file("output/config.json", sim_input)
```
"""
function write_to_json_file(file_path::String, data::AbstractInput)
    return write_to_json_file(file_path, data.all)
end

function write_to_json_file(file_path::String, data::AbstractDict)
    return try
        open(file_path, "w") do io
            JSON.json(io, data; pretty = 4, sort_keys = true)
        end
        println("Data successfully written to $file_path")
    catch e
        println("An error occurred while writing to the file: $e")
    end
end
