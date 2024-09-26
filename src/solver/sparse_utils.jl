# copy form SparseArrays to get indices of slicing in sparse matrices
using SparseArrays
function getindex_I_sorted_linear_new(A::SparseArrays.AbstractSparseMatrixCSC{Tv,Ti}, I::AbstractVector, J::AbstractVector) where {Tv,Ti}
    SparseArrays.require_one_based_indexing(A, I, J)
    nI = length(I)
    nJ = length(J)

    colptrA = SparseArrays.getcolptr(A); rowvalA = SparseArrays.rowvals(A); nzvalA = nonzeros(A)
    colptrS = Vector{Ti}(undef, nJ+1)
    colptrS[1] = 1
    cacheI = zeros(Int, size(A, 1))

    ptrS   = 1
    # build the cache and determine result size
    @inbounds for j = 1:nJ
        col = J[j]
        ptrI::Int = 1 # runs through I
        ptrA::Int = colptrA[col]
        stopA::Int = colptrA[col+1]
        while ptrI <= nI && ptrA < stopA
            rowA = rowvalA[ptrA]
            rowI = I[ptrI]

            if rowI > rowA
                ptrA += 1
            elseif rowI < rowA
                ptrI += 1
            else
                (cacheI[rowA] == 0) && (cacheI[rowA] = ptrI)
                ptrS += 1
                ptrI += 1
            end
        end
        colptrS[j+1] = ptrS
    end

    rowvalS = Vector{Ti}(undef, ptrS-1)
    nzvalS  = Vector{Tv}(undef, ptrS-1)

    # fill the values
    ptrS = 1
    colptrAl = Vector{Ti}()
    @inbounds for j = 1:nJ
        col = J[j]
        ptrA::Int = colptrA[col]
        stopA::Int = colptrA[col+1]
        while ptrA < stopA
            rowA = rowvalA[ptrA]
            ptrI = cacheI[rowA]
            if ptrI > 0
                while ptrI <= nI && I[ptrI] == rowA
                    rowvalS[ptrS] = ptrI
                    nzvalS[ptrS] = nzvalA[ptrA]
                    push!(colptrAl,ptrA)
                    ptrS += 1
                    ptrI += 1
                end
            end
            ptrA += 1
        end
    end
    #return @if_move_fixed A SparseMatrixCSC(nI, nJ, colptrS, rowvalS, nzvalS)
    Al = SparseMatrixCSC(nI, nJ, colptrS, rowvalS, nzvalS)
    return (Al,colptrAl)
end
function getindex_I_sorted_bsearch_I_new(A::SparseArrays.AbstractSparseMatrixCSC{Tv,Ti}, I::AbstractVector, J::AbstractVector) where {Tv,Ti}
    SparseArrays.require_one_based_indexing(A, I, J)
    nI = length(I)
    nJ = length(J)

    colptrA = SparseArrays.getcolptr(A); rowvalA = rowvals(A); nzvalA = nonzeros(A)
    colptrS = Vector{Ti}(undef, nJ+1)
    colptrS[1] = 1

    m = size(A, 1)

    # cacheI is used first to store num occurrences of each row in columns of interest
    # and later to store position of first occurrence of each row in I
    cacheI = zeros(Int, m)

    # count rows
    @inbounds for j = 1:nJ
        col = J[j]
        for ptrA in colptrA[col]:(colptrA[col+1]-1)
            cacheI[rowvalA[ptrA]] += 1
        end
    end

    # fill cache and count nnz
    ptrS::Int = 0
    ptrI::Int = 1
    @inbounds for j = 1:m
        cval = cacheI[j]
        (cval == 0) && continue
        ptrI = searchsortedfirst(I, j, ptrI, nI, Base.Order.Forward)
        cacheI[j] = ptrI
        while ptrI <= nI && I[ptrI] == j
            ptrS += cval
            ptrI += 1
        end
        if ptrI > nI
            @simd for i=(j+1):m; @inbounds cacheI[i]=ptrI; end
            break
        end
    end
    rowvalS = Vector{Ti}(undef, ptrS)
    nzvalS  = Vector{Tv}(undef, ptrS)
    colptrS[nJ+1] = ptrS+1

    # fill the values
    colptrAl = Vector{Ti}()
    ptrS = 1
    @inbounds for j = 1:nJ
        col = J[j]
        ptrA::Int = colptrA[col]
        stopA::Int = colptrA[col+1]
        while ptrA < stopA
            rowA = rowvalA[ptrA]
            ptrI = cacheI[rowA]
            (ptrI > nI) && break
            if ptrI > 0
                while I[ptrI] == rowA
                    rowvalS[ptrS] = ptrI
                    nzvalS[ptrS] = nzvalA[ptrA]
                    push!(colptrAl, ptrA)
                    ptrS += 1
                    ptrI += 1
                    (ptrI > nI) && break
                end
            end
            ptrA += 1
        end
        colptrS[j+1] = ptrS
    end
    #return @if_move_fixed A SparseMatrixCSC(nI, nJ, colptrS, rowvalS, nzvalS)
    Al = SparseMatrixCSC(nI, nJ, colptrS, rowvalS, nzvalS)
    return (Al,colptrAl)
end