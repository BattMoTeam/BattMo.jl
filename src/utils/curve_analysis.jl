export trapz, rmse, compute_dqdv

"""
    trapz(x, y)

Integrate `y` with respect to `x` using the trapezoidal rule.
"""
function trapz(x, y)
    length(x) == length(y) || throw(ArgumentError("x and y must have equal length."))
    length(x) >= 2 || throw(ArgumentError("At least two points are required."))
    return sum((y[1:(end - 1)] .+ y[2:end]) .* diff(x)) / 2
end

"""
    rmse(x, y0, y1)

Compute the root mean squared error using trapezoidal integration over `x`.
"""
function rmse(x, y0, y1)
    length(x) == length(y0) == length(y1) || throw(ArgumentError("x, y0, and y1 must have equal length."))
    x[end] > x[1] || throw(ArgumentError("x[end] must be greater than x[1]."))
    return sqrt(trapz(x, (y1 .- y0) .^ 2) / (x[end] - x[1]))
end

function gaussian_smooth(values; sigma = 1.0, truncate = 4.0)
    length(values) == 1 && return copy(values)
    radius = round(Int, truncate * sigma)
    offsets = collect(-radius:radius)
    weights = exp.(-0.5 .* (offsets ./ sigma) .^ 2)
    weights ./= sum(weights)
    n = length(values)

    function reflected_index(i)
        while i < 1 || i > n
            i = i < 1 ? 1 - i : 2 * n + 1 - i
        end
        return i
    end

    return [
        sum(weights[j] * values[reflected_index(i + offsets[j])] for j in eachindex(weights))
        for i in eachindex(values)
    ]
end

"""
    compute_dqdv(q, v; bin_size = nothing, nbins = nothing, smooth = true)

Compute a differential-capacity curve using an equal-width voltage histogram.
Either `bin_size` or `nbins` must be provided. If both are provided, `nbins`
takes precedence. Gaussian smoothing with `sigma = 1` is enabled by default.

Returns `(voltage, dqdv)`. For decreasing-voltage curves, both arrays are
reversed and the differential capacity is negated.
"""
function compute_dqdv(q, v; bin_size = nothing, nbins = nothing, smooth = true)
    length(q) == length(v) || throw(ArgumentError("q and v must have equal length."))
    length(q) >= 2 || throw(ArgumentError("At least two points are required."))
    all(isfinite, q) && all(isfinite, v) || throw(ArgumentError("q and v must contain only finite values."))
    isnothing(bin_size) && isnothing(nbins) && throw(ArgumentError("Either bin_size or nbins must be provided."))

    vmin, vmax = extrema(v)
    vmax > vmin || throw(ArgumentError("Voltage values must span a non-zero interval."))
    if isnothing(nbins)
        bin_size > 0 || throw(ArgumentError("bin_size must be positive."))
        nbins = floor(Int, (vmax - vmin) / bin_size)
    end
    nbins isa Integer && nbins > 0 || throw(ArgumentError("nbins must be a positive integer."))

    bin_width = (vmax - vmin) / nbins
    counts = zeros(Float64, nbins)
    for voltage in v
        index = voltage == vmax ? nbins : floor(Int, (voltage - vmin) / bin_width) + 1
        counts[index] += 1
    end

    counts ./= length(v) * bin_width
    counts .*= maximum(q) - minimum(q)
    smooth && (counts = gaussian_smooth(counts))

    bin_centers = collect(range(vmin + bin_width / 2, step = bin_width, length = nbins))
    if v[end] > v[1]
        return (bin_centers, counts)
    else
        return (reverse(bin_centers), -reverse(counts))
    end
end
