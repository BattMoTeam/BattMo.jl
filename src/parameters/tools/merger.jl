export mergeInputParams

#########################################################
# Functions to combine the battmo style parameter sets


function recursiveMergeDict(d1, d2; warn = false)

	if isa(d1, Dict) && isa(d2, Dict)

		combiner(d1, d2) = recursiveMergeDict(d1, d2; warn = warn)
		return mergewith(combiner, d1, d2)

	else

		if (d1 != d2) && warn
			println("Some variables have distinct values, we use the value give by the first one")
		end

		return d1

	end
end

""" 
   mergeInputParams(inputparams1::T, inputparams2::T; warn = false) where {T <: DictInputParams}


# Arguments

- `inputparams1  ::T` : First input parameter structure
- `inputparams2  ::T` : Second input parameter structure
- `warn = false` : If option `warn` is true, then give a warning when two distinct values are given for the same field. The first value has other precedence.

# Returns
A `DictInputParams` structure whose field are the composition of the two input parameter structures.
"""
function mergeInputParams(inputparams1::T, inputparams2::T; warn = false) where {T <: BattMoFormattedInput}

	dict1 = inputparams1.dict
	dict2 = inputparams2.dict

	combiner(d1, d2) = recursiveMergeDict(d1, d2; warn = warn)
	dict = mergewith!(combiner, dict1, dict2)

	return T(dict)

end



