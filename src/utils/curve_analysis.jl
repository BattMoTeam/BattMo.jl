export trapz, cumtrapz, rmse, dqdv, dvdq

"""
    trapz(x, y)

Integrate `y` with respect to `x` using the trapezoidal rule.
"""
function trapz(x, y)
    return last(cumtrapz(x, y))
end

"""
    cumtrapz(x, y)

Cumulatively integrate `y` with respect to `x` using the trapezoidal rule.
The returned vector has the same length as `x` and `y`, with zero as the
first value.
"""
function cumtrapz(x, y)
    length(x) == length(y) || throw(DimensionMismatch("x and y must have the same number of elements"))

    length(x) >= 2 || throw(ArgumentError("x must contain at least two points"))

    s = zero((x[2] - x[1]) * (y[1] + y[2]) / 2)
    cumulative = Vector{typeof(s)}(undef, length(x))
    cumulative[1] = s

    @inbounds for i in 1:(length(x) - 1)
        s += (x[i + 1] - x[i]) * (y[i] + y[i + 1]) / 2
        cumulative[i + 1] = s
    end

    return cumulative
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

    all(isfinite, yb) || throw(
        ArgumentError(
            "Interpolated values are not finite. Check that the finer grid is within " *
                "the range of the coarser grid, or use extrap=true or truncate=true."
        )
    )

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

# Check a curve for dqdv or dvdq: finite values of equal length, with strictly monotonic
# capacity that is also uniformly spaced if `uniform` is set.
function check_capacity_curve(q, v, caller; uniform)
    length(q) == length(v) || throw(ArgumentError("q and v must have equal length."))
    length(q) >= 2 || throw(ArgumentError("At least two points are required."))
    all(isfinite, q) && all(isfinite, v) || throw(ArgumentError("q and v must contain only finite values."))

    dq = diff(q)
    mean_dq = (last(q) - first(q)) / (length(q) - 1)
    if uniform
        # Subtracting nearby capacities can lose precision, especially for Float32.
        dq_atol = 2 * eps(float(maximum(abs, q)))
        uniform_q = !iszero(mean_dq) && all(
            step -> sign(step) == sign(mean_dq) && isapprox(step, mean_dq; rtol = 1.0e-6, atol = dq_atol), dq
        )
        uniform_q || throw(
            ArgumentError(
                "q must be strictly monotonic and uniformly spaced. " *
                    "Resample the curve onto a uniform capacity grid before calling $caller."
            )
        )
    else
        !iszero(mean_dq) && all(step -> sign(step) == sign(mean_dq), dq) ||
            throw(ArgumentError("q must be strictly monotonic."))
    end
    return nothing
end

# Return the number of equal-width bins over `span`; `nbins` takes precedence over `bin_size`.
function number_of_bins(span, bin_size, nbins)
    isnothing(bin_size) && isnothing(nbins) && throw(ArgumentError("Either bin_size or nbins must be provided."))
    if isnothing(nbins)
        bin_size > 0 || throw(ArgumentError("bin_size must be positive."))
        nbins = floor(Int, span / bin_size)
    end
    nbins isa Integer && nbins > 0 || throw(ArgumentError("nbins must be a positive integer."))
    return nbins
end

"""
    dqdv(q, v; bin_size = nothing, nbins = nothing, smooth = true)

Compute a differential-capacity curve using an equal-width voltage histogram.
Capacity values `q` must be strictly monotonic and uniformly spaced. Increments
are checked with relative tolerance `1e-6` and an allowance for floating-point
roundoff; otherwise an `ArgumentError` is thrown.
Either `bin_size` or `nbins` must be provided. If both are provided, `nbins`
takes precedence. Gaussian smoothing with `sigma = 1` is enabled by default.

Returns `(voltage, dqdv)`. For decreasing-voltage curves, both arrays are
reversed and the differential capacity is negated.

The histogram calculation follows Algorithm 1 in Eibar Flores and Simon Clark,
"Simple and Comparable Computation of Incremental Capacity Curves",
*Journal of The Electrochemical Society* **173**, 120520 (2026).
[DOI: 10.1149/1945-7111/ae7e5c](https://doi.org/10.1149/1945-7111/ae7e5c).
"""
function dqdv(q, v; bin_size = nothing, nbins = nothing, smooth = true)
    check_capacity_curve(q, v, "dqdv"; uniform = true)

    vmin, vmax = extrema(v)
    vmax > vmin || throw(ArgumentError("Voltage values must span a non-zero interval."))
    nbins = number_of_bins(vmax - vmin, bin_size, nbins)

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

"""
    dvdq(q, v; bin_size = nothing, nbins = nothing, smooth = true)

Compute a differential-voltage curve from an equal-width capacity histogram.
Capacity and voltage are averaged over the samples in each bin, and the
differential voltage between two neighbouring bins is the difference of their
mean voltages divided by the difference of their mean capacities. Every sample
contributes, so the noise of each bin mean falls with the square root of its
sample count. Capacity values `q` must be strictly monotonic, but need not be
uniformly spaced: placing each bin at its mean capacity keeps a linear curve
exact for any sampling. Every bin must contain at least one sample.
Either `bin_size` or `nbins` must be provided. If both are provided, `nbins`
takes precedence, and at least two bins are required. Gaussian smoothing with
`sigma = 1` is enabled by default.

Returns `(capacity, dvdq)` with `nbins - 1` values, each midway between the
mean capacities of two neighbouring bins and ordered as `q`. The differential
voltage keeps the sign of the curve, so it is negative for a discharge against
increasing discharged capacity.
"""
function dvdq(q, v; bin_size = nothing, nbins = nothing, smooth = true)
    check_capacity_curve(q, v, "dvdq"; uniform = false)
    nbins = number_of_bins(abs(last(q) - first(q)), bin_size, nbins)
    nbins >= 2 || throw(ArgumentError("dvdq needs at least two bins."))

    # Bins count from the start of the curve; q is monotonic, so each bin holds a contiguous range of samples.
    bin_width = (last(q) - first(q)) / nbins
    bins = [clamp(floor(Int, (capacity - first(q)) / bin_width) + 1, 1, nbins) for capacity in q]
    ranges = [searchsortedfirst(bins, bin):searchsortedlast(bins, bin) for bin in 1:nbins]
    all(!isempty, ranges) || throw(ArgumentError("Every capacity bin must contain a sample; use fewer or wider bins."))
    mean_q = [sum(view(q, range)) / length(range) for range in ranges]
    mean_v = [sum(view(v, range)) / length(range) for range in ranges]

    differential_voltage = diff(mean_v) ./ diff(mean_q)
    smooth && (differential_voltage = gaussian_smooth(differential_voltage))
    capacity = (mean_q[1:(end - 1)] .+ mean_q[2:end]) ./ 2
    return (capacity, differential_voltage)
end
