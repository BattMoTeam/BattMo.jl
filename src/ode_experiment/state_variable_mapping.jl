import Jutul
import BattMo
import LinearAlgebra
using SparseArrays

function approx_jac(func, t, Δy,y,dy,sim,forces)
    n=length(y)
    jac=SparseArrays.spzeros(n,n)
    iid= Matrix(LinearAlgebra.I,n,n)
    for i=1:n
        y1 = y + iid[:,i]*Δy[1]
        dy1 = dy + iid[:,i]*Δy[2]
        fΔy=zeros(n)
        f=zeros(n)
        func(fΔy,dy1,y1,nothing,t,deepcopy(sim),deepcopy(forces))
        func(f,dy,y,nothing,t,deepcopy(sim),deepcopy(forces))
        jac[:,i].=(fΔy - f)./LinearAlgebra.norm(Δy)
    end
    return jac
end

function odeFun_big!(res,dX,X,p,t,sim,forces)
    """
    We solve the problem defining X = [m ; u] so that f(dX,X,t) = [f₁ ; f₂] = 0:
    f₁ = ∂m/∂t + r(u) = 0
    f₂ =   m   - M(u) = 0 
    """
    len = Integer(length(X)/2)
    dt=0.000001
    r= Jutul.model_residual(sim, X[len+1:end], X[len+1:end], dt, forces = forces, time = t - dt,include_accumulation=false, update_secondary=true)
    M,_=Jutul.model_accumulation(sim,X[len+1:end])
    res[1:len]=dX[1:len] + r
    res[len+1:end] = X[1:len] - M
end

struct ODEParam 
    sim
    forces
    function ODEParam(sim,forces)
        return new(deepcopy(sim),deepcopy(forces))
    end
end

import DiffEqBase

#Avoids issues inside DiffEqBase
DiffEqBase.anyeltypedual(p::ODEParam, counter::Int64 =0) = Any

function odeFun!(res,dy,y,p,t)
    """
    Solve the problem using the approximation ∂m/∂t = ∂m/∂y ∂y/∂t
    """
    dt=1e-8
    r=Jutul.model_residual(p.sim,y,y,dt;forces=p.forces,time=t,include_accumulation=false,update_secondary=true)
    _,m_jac = Jutul.model_accumulation(p.sim,y)
    #Calculate ∂m/∂t = ∂m/∂y ∂y/∂t
    ∂m∂t = m_jac * dy
    res .= ∂m∂t + r
end

function odeFun_jac!(Jacobian,dy,y,p,gamma,t)
    """
    Calculate jacobian of the residual function
    """
    dt=1e-8
    r=Jutul.model_residual(p.sim,y,y,dt;forces=p.forces,time=t,include_accumulation=false,update_secondary=true)
    _,m_jac = Jutul.model_accumulation(p.sim,y)
    jac = p.sim.storage.LinearizedSystem.jac
    I, J, V = findnz(m_jac)
    for (i, j, v) in zip(I, J, V)
        jac[i, j] += v * gamma
    end
    @. Jacobian = jac
    nothing
end