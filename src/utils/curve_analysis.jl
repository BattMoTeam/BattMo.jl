export trapz, rmse, compute_dqdv

"""
    trapz(x, y)

Integrate `y` with respect to `x` using the trapezoidal rule.
"""
function trapz(x, y)
    length(x) == length(y) || throw(DimensionMismatch("x and y must have the same number of elements"))

    length(x) >= 2 || throw(ArgumentError("x must contain at least two points"))

    s = zero((x[2] - x[1]) * (y[1] + y[2]))

    @inbounds for i in 1:(length(x) - 1)
        s += (x[i + 1] - x[i]) * (y[i] + y[i + 1])
    end

    return s / 2
end


"""
    rmse(x0, y0, x1, y1)

Compute the root mean squared error using trapezoidal integration`.
"""

function rmse(
        x1, y1,
        x2, y2;
        extrap::Bool = false,
        truncate::Bool = false,
    )

    length(x1) == length(y1) || throw(DimensionMismatch("x1 and y1 must have the same number of elements"))
    length(x2) == length(y2) || throw(DimensionMismatch("x2 and y2 must have the same number of elements"))

    function strictly_increasing(x)
        @inbounds for i in 2:length(x)
            x[i] > x[i - 1] || return false
        end
        return true
    end

    strictly_increasing(x1) || throw(ArgumentError("x1 must be strictly increasing"))
    strictly_increasing(x2) || throw(ArgumentError("x2 must be strictly increasing"))

    # Optionally truncate both datasets to their common x-range.
    # This preserves ordering and does not sort.
    if truncate
        xmin = max(first(x1), first(x2))
        xmax = min(last(x1), last(x2))

        xmin < xmax || throw(ArgumentError("datasets have no overlapping x-range"))

        idx1 = findall(x -> xmin <= x <= xmax, x1)
        idx2 = findall(x -> xmin <= x <= xmax, x2)

        x1 = x1[idx1]
        y1 = y1[idx1]
        x2 = x2[idx2]
        y2 = y2[idx2]
    end

    length(x1) >= 2 || throw(ArgumentError("x1 must contain at least two points after truncation"))
    length(x2) >= 2 || throw(ArgumentError("x2 must contain at least two points after truncation"))

    if length(x1) > length(x2) # Could also use median spacing
        # x1 is finer: interpolate y2 onto x1
        x = x1
        ya = y1
        # yb = Jutul.linear_interp(x2, y2, x)
        interp = Jutul.get_1d_interpolator(x2, y2)
        yb = interp.(x)
    else
        # x2 is finer: interpolate y1 onto x2
        x = x2
        ya = y2
        # yb = Jutul.linear_interp(x1, y1, x)
        interp = Jutul.get_1d_interpolator(x1, y1)
        yb = interp.(x)
    end

    all(isfinite, yb) || throw(ArgumentError("Interpolated values are not finite. Check that the finer grid is within the range of the coarser grid, or use extrap=true or truncate=true."))

    # Compute L2 error on the finer grid.
    l2sq = trapz(x, @. (ya - yb)^2)
    l2 = sqrt(l2sq)
    wl2 = sqrt(l2sq / (last(x) - first(x)))

    return wl2
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
