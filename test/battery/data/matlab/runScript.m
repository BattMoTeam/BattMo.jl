%% Script for BattMo.m to produce reference solution

mrstModule add ad-core mrst-gui mpfa agmg linearsolvers

%% P1D case

% 
jsonstruct = parseBattmoJson('./p1dcase.json');

% No thermal effects (given temperature)
jsonstruct.use_thermal = false;
%
jsonstruct.use_particle_diffusion = false;


CRate = jsonstruct.Control.CRate;
jsonstruct.TimeStepping.totalTime = 1.4*hour/CRate;
jsonstruct.TimeStepping.N = 40;

%% We start the simulation
% We use the function :code:`runBatteryJson` to run the simulation with json input structure

output = runBatteryJson(jsonstruct);
