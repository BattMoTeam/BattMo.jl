# RGB values sampled from Fabio Crameri's Scientific colour maps (vik).
#
# Reference: Crameri, F. (2018). Scientific colour maps.
# https://doi.org/10.5281/zenodo.1243862
# Palette license: MIT (https://www.fabiocrameri.ch/colourmaps/).
#
# Copyright (c) 2023 Fabio Crameri
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

export component_color

"""
    component_color(component::Union{AbstractString, Symbol})

Return the component's `(red, green, blue)` tuple, with channels in `[0, 1]`.
The tuple can be passed directly as a Makie `color`.

`Electrolyte` uses the separator color for geometry plots.
"""
function component_color(component::Union{AbstractString, Symbol})
    name = Symbol(component)
    if name in (:NegativeElectrodeCurrentCollector, :NegativeCurrentCollector)
        return (0.0013282353685692549, 0.069835904057998568, 0.37952893214298428)
    elseif name in (:NegativeElectrodeActiveMaterial, :NegativeElectrodeCoating, :NegativeElectrode)
        return (0.18590652487535614, 0.48820275524502127, 0.65125366317890188)
    elseif name in (:Separator, :Electrolyte)
        return (0.92438393215110315, 0.89876971218096036, 0.88329883347047033)
    elseif name in (:PositiveElectrodeActiveMaterial, :PositiveElectrodeCoating, :PositiveElectrode)
        return (0.76501266999171258, 0.44521068081483917, 0.26142055070720216)
    elseif name in (:PositiveElectrodeCurrentCollector, :PositiveCurrentCollector)
        return (0.35042305157605391, 6.1141134250659732e-5, 0.030499162905118213)
    else
        throw(ArgumentError("Unknown battery component: $component"))
    end
end
