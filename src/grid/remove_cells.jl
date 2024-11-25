using StatsBase

export remove_cells

function map_excluding(indices)
    """
    indices is an array with 1's and 0's. 1 indicating the cell/face/node should be removed
    """

    ind =  .!indices
    return cumsum(ind) .* ind
end

function remove_cells(G_raw::AbstractDict, cells)

   if isempty(cells)
      cellmap = collect(1 : Int(G_raw["cells"]["num"]));
      nodemap = collect(1 : Int(G_raw["nodes"]["num"]));
      facemap = collect(1 : Int(G_raw["faces"]["num"]));

      return G_raw, cellmap, facemap, nodemap
   end

   G = deepcopy(G_raw)

   """
   Int almost everything
   """

   if haskey(G["faces"], "nodes")
      G["faces"]["nodes"]        = Int.(G["faces"]["nodes"])
      G["nodes"]["num"]          = Int.(G["nodes"]["num"])
   end


   G["faces"]["neighbors"]    = Int.(G["faces"]["neighbors"])
   G["faces"]["num"]          = Int.(G["faces"]["num"])
   G["faces"]["nodePos"]      = Int.(G["faces"]["nodePos"])

   G["cells"]["faces"]        = Int.(G["cells"]["faces"])
   G["cells"]["facePos"]      = Int.(G["cells"]["facePos"])
   G["cells"]["num"]          = Int.(G["cells"]["num"])


   all_cells = collect(1 : G["cells"]["num"])
   ind = all_cells .∈ Ref(cells)
   cellmap = map_excluding(ind)

   if haskey(G["cells"], "numFaces")
      numFaces = Int.(G["cells"]["numfaces"]) # This Int is necessary since the values read are floats
      G["cells"]["numFaces"] = G["cells"]["numFaces"][.!ind]
   else
      numFaces = diff(G["cells"]["facePos"], dims = 1)
   end

   RLdecode = StatsBase.inverse_rle(ind, numFaces[:])
   RemoveIndices = 0 .== RLdecode
   G["cells"]["faces"] = G["cells"]["faces"][RemoveIndices,:]

   n = G["faces"]["neighbors"]
   G["faces"]["neighbors"][n[:,1].>0,1] = cellmap[n[n[:,1].>0,1]]
   G["faces"]["neighbors"][n[:,2].>0,2] = cellmap[n[n[:,2].>0,2]]
    
   
   numFaces = numFaces[.!ind]
   G["cells"]["num"] -= length(cells)
   G["cells"]["facePos"] = cumsum([1;numFaces], dims = 1)
   if haskey(G["cells"], "indexMap")
      G["cells"]["indexMap"] = Int.(G["cells"]["indexMap"][.!ind]) # This Int is necessary since the values read are floats
   end

   ind = 0 .∈ G["faces"]["neighbors"]
   ind = ind[:,1] .&& ind[:,2]
   facemap = map_excluding(ind)

   if haskey(G["faces"], "nodes")
      if haskey(G["faces"], "numNodes")
         numNodes = G["faces"]["numNodes"]
         G["faces"]["numNodes"] = G["faces"]["numNodes"][.!ind]
      else
         numNodes = diff(G["faces"]["nodePos"], dims = 1)
      end  

      RLdecode = StatsBase.inverse_rle(ind, numNodes[:])
      RemoveIndices = 0 .== RLdecode
      G["faces"]["nodes"] = G["faces"]["nodes"][RemoveIndices,:]
   end
   
   G["cells"]["faces"][:,1] = facemap[G["cells"]["faces"][:,1]]

   G["faces"]["neighbors"] = G["faces"]["neighbors"][.!ind,:]

   if haskey(G["faces"], "nodes")
      numNodes = numNodes[.!ind]
      G["faces"]["nodePos"] = cumsum([1; numNodes], dims = 1)
   end

   G["faces"]["num"] -= sum(ind)

   
   if haskey(G["faces"], "nodes")
      ind = trues(G["nodes"]["num"])
      ind[G["faces"]["nodes"]] = falses(length(G["faces"]["nodes"]))
      nodemap = map_excluding(ind)
   
      G["nodes"]["coords"] = G["nodes"]["coords"][.!ind,:]
      G["nodes"]["num"] -= sum(ind)
      G["faces"]["nodes"] = nodemap[G["faces"]["nodes"]]

   else
       nodemap = []
   end

    cellmap = findall(!iszero, cellmap) 
    facemap = findall(!iszero, facemap) 
    nodemap = findall(!iszero, nodemap) 

    maps = (cellmap = cellmap,
            facemap = facemap,
            nodemap = nodemap)
    
    return G, maps
end
