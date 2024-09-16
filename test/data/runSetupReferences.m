casenames = {'p2d_40_no_cc',
             'p2d_40',
             '3d_demo_case'};

battmo_folder = fileparts(mfilename('fullpath'));
battmo_folder = fullfile(battmo_folder, '../..');

if exist('setupMatlabReference') == 0
    % we add the setup function in matlab path
    import_folder = fullfile(battmo_folder, 'src/matlab_interface/');
    addpath(import_folder)
end

jsonfolder = fullfile(battmo_folder, 'test/data/jsonfiles/');
datafolder = fullfile(battmo_folder, 'test/data/matlab_files');

for icase = 1 : numel(casenames)
    casename = casenames{icase};
    setupMatlabReference(casename, jsonfolder, datafolder, 'runSimulation', true);
end



