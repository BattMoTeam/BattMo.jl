module BattMoGLMakieExt

using BattMo, GLMakie

function BattMo.independent_figure_GLMakie(fig::Figure)
    return display(GLMakie.Screen(), fig)
end
end
