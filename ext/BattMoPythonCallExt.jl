module BattMoPythonCallExt

using BattMo
using PythonCall: pyconvert, Py

function BattMo.make_invokable(func::Py)
    return (args...) -> pyconvert(Float64, func(args...))
end

end
