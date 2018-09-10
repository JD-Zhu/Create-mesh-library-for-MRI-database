%=================================================
% PLEASE SPECIFY THE LOCATION OF THE MRI DATABASE:
DataFolder = 'E:\No-Backup\MRI_databases\SLIM\';

% Or use GUI folder selection
%DataFolder = uigetdir('E:\No-Backup\MRI_databases\SLIM\', 'Select the folder containing the MRI database');
%DataFolder = [DataFolder '\'];
%=================================================
%%
fprintf('\nLocation of MRI database:\n    %s\n', DataFolder);

% loop through all subjects
SubjectIDs = dir([DataFolder 'sub-*']);
SubjectIDs = {SubjectIDs.name}; % extract the names into a cell array

for i = 1:length(SubjectIDs)    
    
    SubjectID = cell2mat(SubjectIDs(i));
    SubjectFolder = [DataFolder SubjectID '\'];
    output_file_nas_lpa_rpa = [SubjectFolder 'nas_lpa_rpa.mat'];
    output_file_ac_pc = [SubjectFolder 'ac_pc.mat'];
    processed_this_round = false;
    
    % mark nas/lpa/rpa for this MRI & save
    if (exist(output_file_nas_lpa_rpa, 'file') ~= 2)    
        processed_this_round = true;
        fprintf(['\nCURRENT SUBJECT: ' SubjectID ' (mark nas/lpa/rpa)\n\n']);
        
        % read the DICOM files 
        mri = ft_read_mri([SubjectFolder 'SLIM-T1w.nii']);

        repeat = true;
        while (repeat)
            % Make sure you know which side is the right side (e.g. using the vitamin E marker).
            % Assign the nasion (pressing "n"), left ("l") and right ("r") with the crosshairs on
            % the ear markers. Then finish with "q".
            cfg = [];
            cfg.method = 'interactive';
            cfg.coordsys = 'bti';
            mri_realigned = ft_volumerealign(cfg, mri);

            % read out the fiducial coordinates & save
            nas = mri_realigned.cfg.fiducial.nas;
            lpa = mri_realigned.cfg.fiducial.lpa;
            rpa = mri_realigned.cfg.fiducial.rpa;

            % check if any of the fiducial coordinates contains NaN
            % (i.e. not properly marked)
            if isnan(nas(1)) || isnan(lpa(1)) || isnan(rpa(1))
                msg = sprintf('Error: One or more fiducials were not specified. Please try again!\n\nMake sure you mark all 3 positions: nasion (n), left pre-auricular (l), and right pre-auricular (r).');
                waitfor(msgbox(msg, SubjectID));
            else % if all marked, we are done
                repeat = false;
            end
        end
        
        % finished marking fiducials for this MRI, save the results
        save(output_file_nas_lpa_rpa, 'mri_realigned', 'nas', 'lpa', 'rpa');
    end
    
    % mark AC/PC for this MRI & save
    if (exist(output_file_ac_pc, 'file') ~= 2)    
        processed_this_round = true;
        fprintf(['\nCURRENT SUBJECT: ' SubjectID ' (mark AC/PC/xzpoint)\n\n']);
        
        % read the DICOM files 
        mri = ft_read_mri([SubjectFolder 'SLIM-T1w.nii']);

        repeat = true;
        while (repeat)
            cfg = [];
            cfg.method = 'interactive';
            cfg.coordsys = 'acpc';
            mri_realigned = ft_volumerealign(cfg, mri);

            % read out the fiducial coordinates & save
            ac = mri_realigned.cfg.fiducial.ac;
            pc = mri_realigned.cfg.fiducial.pc;
            xz = mri_realigned.cfg.fiducial.xzpoint;

            % check if any of the fiducial coordinates contains NaN
            % (i.e. not properly marked)
            if isnan(ac(1)) || isnan(pc(1)) || isnan(xz(1))
                msg = sprintf('Error: One or more fiducials were not specified. Please try again!\n\nMake sure you mark all 3 positions: anterior commisure (a), posterior commisure (p), and xzpoint (z).');
                waitfor(msgbox(msg, SubjectID));
            else % if all marked, we are done
                repeat = false;
            end
        end
        
        % finished marking fiducials for this MRI, save the results
        save(output_file_ac_pc, 'mri_realigned', 'ac', 'pc', 'xz');
    end
    

    % Optionally, export the realigned MRI (also showing fiducials)
    % so it can be displayed in SPM/MRIcron 
    % (for quality checking)
    %{
    cfg = [];
    cfg.parameter     = 'anatomy';
    cfg.filename      = [SubjectFolder 'mri_realigned'];
    cfg.filetype      = 'nifti';

    cfg.fiducial.nas  = nas;
    cfg.fiducial.lpa  = lpa;
    cfg.fiducial.rpa  = rpa;
    cfg.markfiducial  = 'yes';

    ft_volumewrite(cfg, mri_realigned);
    %}


    % ask the user: keep going or take a break?
    % this allows us to terminate gracefully (not leaving behind open
    % windows etc)
    if (processed_this_round)
        msg = sprintf('\nJust completed: %s\nTotal %d subjects completed so far!\n\nWould you like to keep going?', SubjectID, i);
        answer = questdlg(msg, 'Next subject', 'Yes', 'No', 'Yes'); % set 'yes' as default
        switch answer
            case 'No'
                break;
        end
    end    
end

% check if the entire database is finished, or just done for the day
if i >= length(SubjectIDs) 
    msgbox('Congratulations - you have finished processing the entire MRI database!', 'Congratulations');
else
    msgbox('Done for now? You can resume next time by running the script again (your progress has been saved).', 'Done for now');
end
