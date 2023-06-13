#using Jutul
#using JutulDarcy


using MAT
export get_boundary, get_tensorprod, exported_model_to_domain, get_ref_states

function get_boundary(name)
    
    fn = string(dirname(pathof(Jutul)), "/../data/testgrids/", name, "_T.mat")
    exported = MAT.matread(fn)

    exported
    bccells = copy((exported["bccells"]))
    T = copy((exported["T"]))

    bccells = Int64.(bccells)

    return (bccells[:, 1], T[:, 1])
    
end

function get_tensorprod(name = "square_current_collector")

    fn = string(dirname(pathof(BattMo)), "/../test/battery/data/", name, "_P.mat")
    exported = MAT.matread(fn)

    exported
    P = copy((exported["P"]))
    S = copy((exported["S"]))

    return P, S
    
end

function exported_model_to_domain(exported;
                                  bcfaces    = nothing, 
                                  general_ad = false)

    """ Returns domain"""

    N = exported["G"]["faces"]["neighbors"]
    N = Int64.(N)

    if !isnothing(bcfaces)
        isboundary = (N[bcfaces, 1].==0) .| (N[bcfaces, 2].==0)
        @assert all(isboundary)
    
        bc_cells = N[bcfaces, 1] + N[bcfaces, 2]
        bc_hfT = getHalfTrans(exported, bcfaces)
    else
        bc_hfT = []
        bc_cells = []
    end
    
    vf = []
    if haskey(exported, "volumeFraction")
        vf = exported["volumeFraction"][:, 1]
    end
    
    internal_faces = (N[:, 2] .> 0) .& (N[:, 1] .> 0)
    N = copy(N[internal_faces, :]')
    
    face_areas   = vec(exported["G"]["faces"]["areas"][internal_faces])
    face_normals = exported["G"]["faces"]["normals"][internal_faces, :]./face_areas
    face_normals = copy(face_normals')
    if length(exported["G"]["cells"]["volumes"])==1
        volumes    = exported["G"]["cells"]["volumes"]
        volumes    = Vector{Float64}(undef, 1)
        volumes[1] = exported["G"]["cells"]["volumes"]
    else
        volumes = vec(exported["G"]["cells"]["volumes"])
    end
    # P = exported["operators"]["cellFluxOp"]["P"]
    # S = exported["operators"]["cellFluxOp"]["S"]
    P = []
    S = []
    T = exported["operators"]["T"].*2.0*1.0
    G = MinimalECTPFAGrid(volumes, N, vec(T);
                          bc_cells = bc_cells,
                          bc_hfT   = bc_hfT,
                          P        = P,
                          S        = S,
                          vf       = vf)

    nc = length(volumes)
    if general_ad
        flow = PotentialFlow(G)
    else
        flow = TwoPointPotentialFlowHardCoded(G)
    end
    disc = (charge_flow = flow,)
    domain = DiscretizedDomain(G, disc)

    return domain
    
end

function get_ref_states(j2m, ref_states)
    
    m2j = Dict(value => key for (key, value) in j2m)
    rs = [ 
        Dict(m2j[k] => v[:, 1] for (k, v) in state if k in keys(m2j))
        for state in ref_states
        ]
    if :C in keys(j2m)
        [s[:C] = s[:C][1][:, 1] for s in rs]
    end
    
    return rs
    
end

