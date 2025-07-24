
function reaction_rate_constant_ne(cs, refT)

	k = 0.6 * (-1.4132e-29 * (cs)^5 + 5.5715e-25 * (cs)^4 - 7.5952e-21 * (cs)^3 + 4.0981e-17(cs)^2 - 6.9205e-14 * (cs) + 4.1515e-11)
	return k

end


function reaction_rate_constant_pe(cs, refT)

	k = 1.5 * (4.2884e-34 * (cs)^6 - 2.641e-29 * (cs)^5 + 6.4845e-25 * (cs)^4 - 8.06e-21 * (cs)^3 + 5.3039e-17 * (cs)^2 - 1.7493e-13 * (cs) + 2.3728e-10)
	return k

end

@eval Main reaction_rate_constant_pe = $reaction_rate_constant_pe
@eval Main reaction_rate_constant_pe = $reaction_rate_constant_pe