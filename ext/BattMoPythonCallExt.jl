module BattMoPythonCallExt

using BattMo
using PythonCall

function BattMo.make_invokable(func::PythonCall.Py)
    return (args...) -> pyconvert(Real, func(args...))
end

end
