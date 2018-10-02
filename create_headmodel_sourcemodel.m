%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create meshes, headmodels and sourcemodels for MEG sourcespace analysis 
% from child templates (obtained from John Richards at USC).
%
% John Richards (USC, USA) retains all copyrights to the templates.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% specify path to marked MRI database & location to save QC output
MRI_DATABASE = 'D:\Judy\PACE\SLIM_marked\';
QC_DIR = [MRI_DATABASE '..\qc'];

list_of_subs = listFolders(MRI_DATABASE);

for sub = 1:length(list_of_subs)
    try
        %% Set up directory to hold info for each age
        dir_for_loop = [MRI_DATABASE list_of_subs{sub}];
        
        cd(dir_for_loop)
        
        %% Load the brain
        
        load('mri_realigned.mat');
        load('mesh.mat');
        
        %% Segment
        cfg           = [];
        cfg.output    = 'brain';
        mri_segmented  = ft_volumesegment(cfg, mri_realigned);
        
        %% Create singleshell headmodel
        cfg = [];
        cfg.tissue = 'brain';
        cfg.method='singleshell';
        headmodel_singleshell = ft_prepare_headmodel(cfg, mri_segmented);
        
        %     % Transform based on fiducials
        %     headmodel_singleshell = ft_transform_vol(inv(mri_orig.transform),headmodel_singleshell);
        %     headmodel_singleshell = ft_transform_vol(mri_realigned.transform,headmodel_singleshell);
        
        % Create Figure
        figure;ft_plot_vol(headmodel_singleshell);
        ft_plot_mesh(mesh); alpha 0.3; view([0,0]);
        print('qc_headmodel','-dpng','-r100');
        
        % Save headmodel
        headmodel = headmodel_singleshell;
        save headmodel headmodel;
        
        %% Create sourcemodel
        
        sourcemodel_mm = [10 8 5];
        
        for size = 1:length(sourcemodel_mm);
            
            fprintf('Creating %dmm sourcemodel\n');
            
            % create the subject specific grid, using the template grid that has just been created
            cfg                = [];
            cfg.grid.warpmni   = 'yes';
            cfg.grid.resolution = sourcemodel_mm(size);
            cfg.grid.nonlinear = 'yes'; % use non-linear normalization
            cfg.mri            = mri_realigned;
            cfg.grid.unit      ='mm';
            cfg.inwardshift = '-1.5';
            grid               = ft_prepare_sourcemodel(cfg);
            
            % Transform based on fiducials
            %         grid.pos = ft_warp_apply(inv(mri_orig.transform),grid.pos);
            %         grid.pos = ft_warp_apply(mri_realigned.transform,grid.pos);
            
            % Save
            sourcemodel3d = grid;
            save(sprintf('sourcemodel3d_%dmm',sourcemodel_mm(size)),'sourcemodel3d');
            
            % Create figure and save
            figure;ft_plot_mesh(grid.pos(grid.inside,:)); view([0,0]);
            print(sprintf('qc_sourcemodel3d_shape_%dmm',sourcemodel_mm(size)),'-dpng','-r100');
            
            figure; ft_plot_vol(headmodel_singleshell); alpha 0.3;
            ft_plot_mesh(mesh); alpha 0.3;
            ft_plot_mesh(grid.pos(grid.inside,:)); view([0,0]);
            
            print(sprintf('qc_sourcemodel3d_%dmm',sourcemodel_mm(size)),'-dpng','-r100');
            
            % Clear for next loop
            clear grid sourcemodel3d
        end
        
        % Clear for next loop
        clear mesh headmodel mri_realigned headmodel_singleshell mri_segmented
        close all
        
        fprintf('Finished... CHECK for quality control\n');
        
    catch
        cd(QC_DIR)
        txt_to_save = [list_of_subs{sub} ' could not be saved'];
        save(sprintf('%s',list_of_subs{sub}),'txt_to_save');
        clear txt_to_save
    end
end


%% Example call to child_MEMES
%{
dir_name    = '/Users/44737483/Documents/scripts_mcq/child_test/2913/'
elpfile     = '/Users/44737483/Documents/scripts_mcq/child_test/2913/2913_ES_ME125_2018_02_24.elp';
hspfile     = '/Users/44737483/Documents/scripts_mcq/child_test/2913/2913_ES_ME125_2018_02_24.hsp';
confile     = '/Users/44737483/Documents/scripts_mcq/child_test/2913/2913_ES_ME125_2018_02_24_B1.con';
mrkfile     = '/Users/44737483/Documents/scripts_mcq/child_test/2913/2913_ES_ME125_2018_02_24_INI.mrk';

path_to_MRI_library = '/Users/44737483/Documents/scripts_mcq/MRIDataBase_JohnRichards_USC/database_for_MEMES/';

child_MEMES(dir_name,elpfile,hspfile,confile,mrkfile,path_to_MRI_library,'')
%}
