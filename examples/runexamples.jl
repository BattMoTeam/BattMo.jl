# Run all the examples in this folder and in the beginner_tutorials
# folder, and catch any errors that occur

failed = String[]

topfiles = [
    f for f in readdir(pwd(); join = false)
        if endswith(f, ".jl") && f != "runexamples.jl"
]

tutorialfiles = [
    f for f in readdir(joinpath(pwd(), "beginner_tutorials"); join = true)
        if endswith(f, ".jl")
]

files = vcat(sort(topfiles), sort(tutorialfiles))

for file in files
    try
        println("Including $file")
        include(file)
    catch err
        push!(failed, file)
        @warn "Failed to include $file" exception = (err, catch_backtrace())
    end
end

println("Failed files:")
foreach(println, failed)
