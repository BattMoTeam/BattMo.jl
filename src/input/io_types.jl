import JSON
import MAT

export readBattMoMatlabInputFile, readBattMoJsonInputFile

function readBattMoMatlabInputFile(inputFileName::String)
    inputparams = MatlabInputParams(MAT.matread(inputFileName))
    return inputparams
end

function readBattMoJsonInputFile(inputFileName::String)
    inputparams = InputParams(JSON.parsefile(inputFileName))
    return inputparams
end


