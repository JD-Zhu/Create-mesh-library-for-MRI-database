% read the DICOM files 
mri = ft_read_mri('SLIM-T1w.nii');
mri.coordsys = 'ctf';

% segment into brain, skull and scalp 
cfg              = [];
cfg.output       = {'brain','skull','scalp'};
bss              = ft_volumesegment(cfg, mri);     % the mri is the same as in the code before

cfg              = [];
cfg.funparameter = 'scalp';
cfg.location     = 'center';
ft_sourceplot(cfg, bss);