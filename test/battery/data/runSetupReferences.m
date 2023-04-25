casenames = {'p1d_40'};

battmo_folder = fileparts(mfilename('fullpath'));
battmo_folder = fullfile(battmo_folder, '../../..');

if exist('setupMatlabReference') == 0
    % we add the setup function in matlab path
    import_folder = fullfile(battmo_folder, 'src/utils/');
    addpath(import_folder)
end

jsonfolder = fullfile(battmo_folder, 'test/battery/data/jsonfiles/');
datafolder = fullfile(battmo_folder, 'test/battery/data');

for icase = 1 : numel(casenames)
    casename = casenames{icase};
    setupMatlabReference(casename, jsonfolder, datafolder);
end



