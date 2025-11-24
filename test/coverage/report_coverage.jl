using Coverage

cov = process_folder("src")
covered_lines, total_lines = get_summary(cov)
percent = covered_lines/total_lines*100
println("Overall coverage: $(round(percent, digits=2))%")
min_cov = 60.0
if percent < min_cov
	println("❌ Coverage below minimum (expected ≥ $min_cov%)")
	exit(1)
else
	println("✅ Coverage OK (≥ $min_cov%)")
end

# Write LCOV file for tools like Codecov
LCOV.writefile("lcov.info", cov)

