clear all;
close all;


%% Initially, load example headshape and sensor positions
% (for plotting in quality check)

% Headshape example
hsp = ft_read_headshape('..\\2784_AG_ME155_2017_11_17.hsp');
hsp = ft_convert_units(hsp, 'mm');

% Sensors example
sensors = ft_read_sens('..\\2784_AG_ME155_2017_11_17_test.con');
sensors = ft_convert_units(sensors, 'mm');


%% For each separate MRI, do the following (Steps 1 ~ 7) ...

% read the Nifti file 
mri = ft_read_mri('SLIM-T1w.nii');


%% Steps 1~2: mark fiducials & realign to 'bti' coordinate system

repeat = true;
while (repeat)
    % Mark the nasion (pressing "n"), lpa ("l") and rpa ("r").
    % Then finish with "q".
    cfg = [];
    cfg.method = 'interactive';
    cfg.coordsys = 'bti'; % realign to 'bti' coordinate system
    mri_realigned = ft_volumerealign(cfg, mri);

    % read out the fiducial coordinates
    nas = mri_realigned.cfg.fiducial.nas;
    lpa = mri_realigned.cfg.fiducial.lpa;
    rpa = mri_realigned.cfg.fiducial.rpa;

    % check if any of the fiducial coordinates contains NaN
    % (i.e. not properly marked)
    if isnan(nas(1)) || isnan(lpa(1)) || isnan(rpa(1))
        msg = sprintf('One or more fiducials were not specified. Please try again!\n\nMake sure you mark all 3 positions: nasion (n), left pre-auricular (l), and right pre-auricular (r).');
        waitfor(msgbox(msg, 'Error'));
    else % if all marked, we are done
        repeat = false;
    end
end

save mri_realigned mri_realigned


%% quality check
% check that the MRI is consistent after realignment

ft_determine_coordsys(mri_realigned, 'interactive', 'no');
hold on;
drawnow; % workaround to prevent some MATLAB versions (2012b and 2014b) from crashing
ft_plot_headshape(hsp, 'vertexsize',4);
ft_plot_sens(sensors);
drawnow; view([190 0]);
print('initial_realign', '-dpng', '-r100'); % save the figure as a picture

uiwait(gcf); % wait for user to close the figure

% If the QC plot is upside down, that means you have marked 'l' and 'r' 
% the wrong way around - please re-do(!)
msg = sprintf('\nDid the plot look ok?\n');
title = 'Quality check';
answer = questdlg(msg, title, 'Yes, save and continue', 'No, exit and redo', 'Yes, save and continue'); % set 'yes' as default
switch answer
    case 'No, exit and redo'
        %close all;
        return; % terminate the script
end

%% save fiducial information
fprintf('\nSaving fiducial co-ordinates to file\n\n');

% get transformation matrix of individual MRI
vox2head = (mri.transform);

% transform voxel indices to MRI head coordinates
head_Nas          = ft_warp_apply(vox2head, nas, 'homogenous'); % nasion
head_Lpa          = ft_warp_apply(vox2head, lpa, 'homogenous'); % Left preauricular
head_Rpa          = ft_warp_apply(vox2head, rpa, 'homogenous'); % Right preauricular

% Save fiducials to file
fids = [head_Nas; head_Lpa; head_Rpa];
save('fiducials.txt', 'fids', '-ascii', '-double', '-tabs')


%% Step 3: Create scalp mesh
% Segment the mri preserving scalp info

scalpthreshold = 0.08; % we use 0.08 as default, as it usually works best
                       % manual adjustment available in QC section below
                       
repeat = true;
while (repeat)
    cfg = [];
    cfg.output    = 'scalp';
    cfg.scalpsmooth = 5;
    cfg.scalpthreshold = scalpthreshold;
    scalp  = ft_volumesegment(cfg, mri_realigned);

    % Create mesh out of scalp surface
    cfg = [];
    cfg.method = 'isosurface';
    cfg.numvertices = 10000;
    mesh = ft_prepare_mesh(cfg, scalp);
    mesh = ft_convert_units(mesh, 'mm');

    %% quality check
    figure; ft_plot_mesh(mesh,'facecolor','skin'); alpha(0.2);
    camlight left; camlight right; material dull; hold on;
    view([0,0]);
    print('qc_mesh', '-dpng', '-r100');
    
    uiwait(gcf);
    
    % If the resulting mesh looks weird, prompt user to adjust the
    % scalp threshold (try 0.05-0.09) until it looks correct 
    % If it is still weird after trying different threshold values (this might
    % happen for a few MRI scans), write down the subject number!
    msg = sprintf('\nWould you like to adjust the scalp threshold?\n(Try 0.05-0.09)\n\nIf it still looks weird after trying different values, write down\nthe subject number!\n');
    title = 'Quality check';
    answer = inputdlg(msg, title);
    if isempty(answer) % no change to scalp threshold, we are done
        repeat = false;
    else % change to new threshold
        scalpthreshold = str2double(cell2mat(answer)); % convert to double
    end
end

save mesh mesh

% Plot figure of mesh (show 2 different angles for the saved figure)
figure; 
subplot(1,2,1); ft_plot_mesh(mesh,'facecolor','skin'); alpha(0.2);
camlight left; camlight right; material dull; hold on;
ft_plot_headshape(hsp, 'vertexsize',1); view([0,0]);
subplot(1,2,2); ft_plot_mesh(mesh,'facecolor','skin'); alpha(0.2);
camlight left; camlight right; material dull; hold on;
ft_plot_headshape(hsp, 'vertexsize',1); view([0,90]);
print('qc_mesh_with_hsp', '-dpng', '-r100');

uiwait(gcf);



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


%% In addition: mark the AC (pressing "a") and PC ("p")

repeat = true;
while (repeat)
    cfg = [];
    cfg.method = 'interactive';
    cfg.coordsys = 'acpc';
    mri_realigned_acpc = ft_volumerealign(cfg, mri);

    % read out the fiducial coordinates
    ac = mri_realigned_acpc.cfg.fiducial.ac;
    pc = mri_realigned_acpc.cfg.fiducial.pc;
    xz = mri_realigned_acpc.cfg.fiducial.xzpoint;

    % check if any of the fiducial coordinates contains NaN
    % (i.e. not properly marked)
    if isnan(ac(1)) || isnan(pc(1)) || isnan(xz(1))
        msg = sprintf('One or more fiducials were not specified. Please try again!\n\nMake sure you mark all 3 positions: anterior commisure (a), posterior commisure (p), and xzpoint (z).');
        waitfor(msgbox(msg, 'Error'));
    else % if all marked, we are done
        repeat = false;
    end
end
        
% finished marking AC/PC, save the results
save('ac_pc.mat', 'mri_realigned_acpc');
