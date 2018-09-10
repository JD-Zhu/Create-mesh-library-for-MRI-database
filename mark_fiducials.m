%% Initially, load example headshape and sensor positions (for plotting in quality check)

% Headshape example
hsp = ft_read_headshape('2784_AG_ME155_2017_11_17.hsp');
hsp = ft_convert_units(hsp, 'mm');

% Sensors
sensors = ft_read_sens('2784_AG_ME155_2017_11_17_test.con');
sensors = ft_convert_units(sensors, 'mm');


%% For each separate MRI, do the following (Steps 1 ~ 7) ...

% read the Nifti file 
mri = ft_read_mri('SLIM-T1w.nii');


%% Steps 1~2: mark fiducials & realign to 'bti' coordinate system

% Mark the nasion (pressing "n"), lpa ("l") and rpa ("r").
% Then finish with "q".
cfg = [];
cfg.method = 'interactive';
cfg.coordsys = 'bti'; % realign to 'bti' coordinate system
mri_realigned = ft_volumerealign(cfg, mri);

save mri_realigned mri_realigned

% check that the MRI is consistent after realignment
ft_determine_coordsys(mri_realigned, 'interactive', 'no');
hold on;
drawnow; % workaround to prevent some MATLAB versions (2012b and 2014b) from crashing
ft_plot_headshape(hsp, 'vertexsize',4);
ft_plot_sens(sensors);
drawnow; view([190 0]);
print('initial_realign', '-dpng', '-r100');

% If this plot is upside down you have marked 'l' and 'r' the wrong way
% around - please re-do(!)

fprintf('Saving fiducial co-ordinates to file\n');

% read out the fiducial coordinates & save
nas = mri_realigned.cfg.fiducial.nas;
lpa = mri_realigned.cfg.fiducial.lpa;
rpa = mri_realigned.cfg.fiducial.rpa;

save('nas_lpa_rpa.mat', 'mri_realigned', 'nas', 'lpa', 'rpa');

% transformation matrix of individual MRI
vox2head = (mri.transform);

% transform voxel indices to MRI head coordinates
head_Nas          = ft_warp_apply(vox2head, nas, 'homogenous'); % nasion
head_Lpa          = ft_warp_apply(vox2head, lpa, 'homogenous'); % Left preauricular
head_Rpa          = ft_warp_apply(vox2head, rpa, 'homogenous'); % Right preauricular

% Save marked fiducials for later
fids = [head_Nas; head_Lpa; head_Rpa];
save('fiducials.txt', 'fids', '-ascii', '-double', '-tabs')


%% Step 3: Create scalp mesh
% Segment the mri preserving scalp info

% If the resulting mesh looks weird, please adjust the cfg.scalpthreshold
% parameter until it looks correct (0.05-0.09)
% If it is still weird after trying different threshold values (this might
% happen for a few MRI scans), write down the subject number!

cfg = [];
cfg.output    = 'scalp';
cfg.scalpsmooth = 5;
cfg.scalpthreshold = 0.08; % Try 0.05 - 0.09
scalp  = ft_volumesegment(cfg, mri_realigned);

% Create mesh out of scalp surface
cfg = [];
cfg.method = 'isosurface';
cfg.numvertices = 10000;
mesh = ft_prepare_mesh(cfg,scalp);
mesh = ft_convert_units(mesh,'mm');

figure; ft_plot_mesh(mesh,'facecolor','skin'); alpha(0.2);
camlight left; camlight right; material dull; hold on;
view([0,0]);
print('qc_mesh','-dpng','-r100');

save mesh mesh

% Plot figure of mesh
figure; subplot(1,2,1); ft_plot_mesh(mesh,'facecolor','skin'); alpha(0.2);
camlight left; camlight right; material dull; hold on;
ft_plot_headshape(hsp, 'vertexsize',1); view([0,0]);
subplot(1,2,2); ft_plot_mesh(mesh,'facecolor','skin'); alpha(0.2);
camlight left; camlight right; material dull; hold on;
ft_plot_headshape(hsp, 'vertexsize',1); view([0,90]);
print('qc_mesh_with_hsp','-dpng','-r100');

close all



%% Steps 4~6: segment MRI, create headmodel & sourcemodel
% (do this in a separate script after PACE project)

% cfg           = [];
% cfg.output    = 'brain';
% mri_segmented  = ft_volumesegment(cfg, mri_realigned);
% 
% %% Create singleshell headmodel
% cfg = [];
% cfg.method='singleshell';
% headmodel_singleshell = ft_prepare_headmodel(cfg, mri_segmented); % in cm, create headmodel
% 
% figure;ft_plot_headshape(hsp) %plot headshape
% ft_plot_sens(sens, 'style', 'k*')
% ft_plot_vol(headmodel_singleshell,  'facecolor', 'cortex', 'edgecolor', 'cortex'); alpha(1.0); hold on;
% ft_plot_mesh(mesh,'facecolor','skin'); alpha(0.2);
% camlight left; camlight right; material dull; hold on;
% view([90,0]); 
% print('headmodel_quality','-dpdf');


% % Also mark the AC (pressing "a") and PC ("p")
% cfg = [];
% cfg.method = 'interactive';
% cfg.coordsys = 'acpc';
% mri_realigned = ft_volumerealign(cfg, mri);
% 
% % read out the fiducial coordinates & save
% ac = mri_realigned.cfg.fiducial.ac;
% pc = mri_realigned.cfg.fiducial.pc;
% xz = mri_realigned.cfg.fiducial.xzpoint;
%         
% save('ac_pc.mat', 'mri_realigned', 'ac', 'pc', 'xz');
