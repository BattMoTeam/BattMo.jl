export setup_ocp_evaluation_expression_from_string,
	setup_diffusivity_evaluation_expression_from_string,
	setup_conductivity_evaluation_expression_from_string

function setup_ocp_evaluation_expression_from_string(str)
	""" setup the Expr from a sting for the OCP function, with the proper signature."""

	str = "function f(c, T, refT, cmax) return $str end"
	return Meta.parse(str)

end

function setup_diffusivity_evaluation_expression_from_string(str)
	""" setup the Expr from a sting for the electrolyte diffusivity function, with the proper signature."""

	str = "function f(c, T) return $str end"
	return Meta.parse(str)

end

function setup_conductivity_evaluation_expression_from_string(str)
	""" setup the Expr from a sting for the electrolyte conductivity function, with the proper signature."""

	str = "function f(c, T) return $str end"
	return Meta.parse(str)

end
