"""Expand each value by the corresponding non-negative repetition count."""
function _expand_run_lengths(values::AbstractVector, counts::AbstractVector{<:Integer})
    length(values) == length(counts) ||
        throw(DimensionMismatch("values and counts must have the same length"))
    all(>=(0), counts) || throw(ArgumentError("repetition counts must be non-negative"))

    expanded = Vector{eltype(values)}(undef, sum(counts))
    offset = 0
    for index in eachindex(values, counts)
        count = counts[index]
        if count > 0
            fill!(view(expanded, (offset + 1):(offset + count)), values[index])
            offset += count
        end
    end
    return expanded
end
