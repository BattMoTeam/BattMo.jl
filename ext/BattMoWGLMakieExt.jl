module BattMoMakieExt

using BattMo, WGLMakie

function BattMo.independent_figure_WGLMakie(fig::Figure)
	display(WGLMakie.Screen(), fig)
end
end
