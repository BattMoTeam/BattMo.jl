using JSON

export write_to_json_file

"""
    write_to_json_file(file_path::String, data::Union{AbstractInput, AbstractDict, NamedTuple})

Writes an input object, dictionary, or named tuple to a JSON file at the
specified `file_path`.

# Arguments
- `file_path::String`: The path, including filename, where the JSON file will be saved.
- `data::AbstractInput`: An input object whose `.all` field is serialized.
- `data::AbstractDict`: A dictionary serialized directly.
- `data::NamedTuple`: A named tuple serialized directly.

# Behavior
- Opens the file at `file_path` in write mode.
- Serializes the input data to JSON format with indentation of 4 spaces.
- Prints a success message if writing completes successfully.
- If any error occurs during file opening, serialization, or writing, catches the exception and prints an error message.

# Returns
- `nothing`.

# Example
```julia
write_to_json_file("output/config.json", sim_input)
write_to_json_file("output/config.json", Dict("a" => 1, "b" => 2))
write_to_json_file("output/config.json", (a = 1, b = 2))
```
"""
function write_to_json_file(
        file_path::String,
        data::Union{AbstractInput, AbstractDict, NamedTuple},
    )
    json_data = data isa AbstractInput ? data.all : data

    return try
        open(file_path, "w") do io
            JSON.print(io, json_data, 4)
        end

        println("Data successfully written to $file_path")
    catch e
        println("An error occurred while writing to the file: $e")
    end
end
