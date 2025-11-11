#!/usr/bin/env julia

# === CONFIG ===
src_dir = "src"
min_cov = 60.0

println("🔍 Analyzing coverage in \"$src_dir\"")

# === Find all .cov files ===
function find_cov_files(dir)
	result = String[]
	for (root, _, files) in walkdir(dir)
		for f in files
			if endswith(f, ".cov")
				push!(result, joinpath(root, f))
			end
		end
	end
	return result
end

# === Analyze one .cov file ===
function analyze_cov_file(path::String)
	jl_file = replace(path, r"\.cov$" => "")
	uncovered_lines = Int[]
	total_executable = 0
	covered = 0

	open(path, "r") do io
		i = 0
		for rawline in eachline(io)
			i += 1
			s = strip(rawline)
			isempty(s) && continue

			parts = split(s; limit = 2)
			count_str = parts[1]

			if count_str == "-"
				continue
			end

			count = tryparse(Int, count_str)
			isnothing(count) && continue

			total_executable += 1
			if count == 0
				push!(uncovered_lines, i)
			elseif count > 0
				covered += 1
			end
		end
	end

	percent = total_executable == 0 ? 0.0 : covered / total_executable * 100
	return (file = jl_file, uncovered_lines, percent)
end

# === Main analysis ===
cov_files = find_cov_files(src_dir)

if isempty(cov_files)
	println("⚠️  No .cov files found in $src_dir — did you run tests with coverage enabled?")
	exit(0)
end

results = [analyze_cov_file(f) for f in cov_files]

# === Pretty print summary table ===
println("\n📊 Coverage Summary:\n")

max_file_len = maximum(length(r.file) for r in results)
header_file = "File" * " "^(max_file_len - length("File"))
println(header_file, " │ Coverage ")
println("─"^max_file_len, "─┼───────────────────────────────")

for r in results
	uncovered = isempty(r.uncovered_lines) ? "—" : join(r.uncovered_lines, ", ")
	file_col = rpad(r.file, max_file_len)
	cov_col = lpad(string(round(r.percent, digits = 2)) * " %", 9)
	println(file_col, " │ ", cov_col) #, " │ ", uncovered)
end

# === Compute and check average ===
avg_cov = sum(r.percent for r in results) / length(results)
println("\nOverall average coverage: ", round(avg_cov, digits = 2), "%")

if avg_cov < min_cov
	println("❌ Coverage below minimum threshold ($(min_cov)%)")
	exit(1)
else
	println("✅ Coverage meets minimum threshold ($(min_cov)%)")
end
