using BattMo

fn = string(dirname(pathof(BattMo)), "/../examples/4680/4680_matlab_input.mat")
inputparams = readBattMoMatlabInputFile(fn)

output = run_battery(inputparams)
