function output = setupMatlabReference(casename, jsonfolder, datafolder, varargin)
%% Script for BattMo.m to produce reference solution
% - casename : is used to identify json file name for the input and saved data output
% - jsonfolder : folder where the json file is fetched
% - datafolder : folder where the computed data is saved

    opt = struct('runSimulation', true, ...
                 'doplot'       , true);
    opt = merge_options(opt, varargin{:});

    runSimulation = opt.runSimulation;
    
    battmo_folder = fileparts(mfilename('fullpath'));
    battmo_folder = fullfile(battmo_folder, '../..');

    % load json setup file

    json_filename = sprintf('%s.json', casename);
    json_filename = fullfile(jsonfolder, json_filename);

    if exist('parseBattmoJson') == 0
        fprintf('You need to install matlab battmo (https://github.com/BattMoTeam/BattMo).\n')
        return
    end

    jsonstruct = parseBattmoJson(json_filename);

    %% To run the simulation, you need to install matlab battmo

    mrstModule add ad-core mrst-gui mpfa agmg linearsolvers
    
    output = setupSimulationForJuliaBridge(jsonstruct, 'runSimulation', runSimulation);
    
    filename = sprintf('%s.mat', casename);
    filename = fullfile(datafolder, filename);

    model     = output.model;
    initstate = output.initstate;
    schedule  = output.schedule;

    if runSimulation
        states = output.states;
        save(filename, 'model', 'states', 'initstate', "schedule");
    else
        save(filename, 'model', 'initstate', "schedule");
    end
    
    if opt.doplot && runSimulation
        
        ind = cellfun(@(x) not(isempty(x)), states); 
        states = states(ind);
        E = cellfun(@(x) x.Control.E, states); 
        I = cellfun(@(x) x.Control.I, states);
        time = cellfun(@(x) x.time, states);
        plot(time, E)
        
    end
    
end
