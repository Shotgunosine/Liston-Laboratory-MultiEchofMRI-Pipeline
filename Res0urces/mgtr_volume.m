% read in mask and define all "in-brain" voxels;
mask = niftiread([Subdir '/func/xfms/rest/T1w_acpc_brain_func_mask.nii.gz']);
info_3D = niftiinfo([Subdir '/func/xfms/rest/T1w_acpc_brain_func_mask.nii.gz']); % nii info; used for writing the output.
dims = size(mask); % mask dims;
mask = reshape(mask,[dims(1)*dims(2)*dims(3),1]);
brain_voxels = find(mask==1); % define all in-brain voxels;

% adjust header info;
info_3D.Datatype = 'double';
info_3D.BitsPerPixel = 64;

% load input data;
data = niftiread(Input);
dims = size(data); % data dims;
data = reshape(data,[dims(1)*dims(2)*dims(3),dims(4)]);
info_4D = niftiinfo(Input); % nii info; used for writing the output.
data_mean = mean(data,2); % hold onto this for a moment...

% load motion data
mcf = load(MCF);

% calculate expanded motion variables
mcfdims = size(mcf);
mcflen = mcfdims(1);
derivatives(2:mcflen, :) = mcf(2:mcflen, :) - mcf(1:(mcflen-1), :);
squares = mcf.^2;
square_derivatives = derivatives.^2;

rot_x = mcf(:,1);
rot_y = mcf(:,2);
rot_z = mcf(:,3);
trn_x = mcf(:,4);
trn_y = mcf(:,5);
trn_z = mcf(:,6);

drot_x = derivatives(:,1);
drot_y = derivatives(:,2);
drot_z = derivatives(:,3);
dtrn_x = derivatives(:,4);
dtrn_y = derivatives(:,5);
dtrn_z = derivatives(:,6);

srot_x = squares(:,1);
srot_y = squares(:,2);
srot_z = squares(:,3);
strn_x = squares(:,4);
strn_y = squares(:,5);
strn_z = squares(:,6);

sdrot_x = square_derivatives(:,1);
sdrot_y = square_derivatives(:,2);
sdrot_z = square_derivatives(:,3);
sdtrn_x = square_derivatives(:,4);
sdtrn_y = square_derivatives(:,5);
sdtrn_z = square_derivatives(:,6);

% create cortical ribbon file; if needed
if ~exist([Subdir '/func/rois/CorticalRibbon.nii.gz'],'file')
    str = strsplit(Subdir,'/'); Subject = str{end}; % infer subject name
    system(['mri_convert -i ' Subdir '/anat/T1w/' Subject '/mri/lh.ribbon.mgz -o ' Subdir '/func/rois/lh.ribbon.nii.gz --like ' Subdir '/func/xfms/rest/T1w_acpc_brain_func_mask.nii.gz > /dev/null 2>&1']);
    system(['mri_convert -i ' Subdir '/anat/T1w/' Subject '/mri/rh.ribbon.mgz -o ' Subdir '/func/rois/rh.ribbon.nii.gz --like ' Subdir '/func/xfms/rest/T1w_acpc_brain_func_mask.nii.gz > /dev/null 2>&1']);
    system(['fslmaths ' Subdir '/func/rois/lh.ribbon.nii.gz -add ' Subdir '/func/rois/rh.ribbon.nii.gz ' Subdir '/func/rois/CorticalRibbon.nii.gz > /dev/null 2>&1']);
    system(['fslmaths ' Subdir '/func/rois/CorticalRibbon.nii.gz -bin ' Subdir '/func/rois/CorticalRibbon.nii.gz']);
    system(['rm ' Subdir '/func/rois/*.ribbon.*']); % clean up;
end

% read in mask and define all "in-brain" voxels;
gray = niftiread([Subdir '/func/rois/CorticalRibbon.nii.gz']);
gray = reshape(gray,[dims(1)*dims(2)*dims(3),1]);

% calculate the global signal;
gs = mean(data(gray==1,:));

% preallocate betas;
b = zeros(size(data,1),1);

% sweep all in-brain voxels;
for i = 1:length(brain_voxels)
    
    % remove the mean gray matter signal;
    [betas,~,data(brain_voxels(i),:),~,~] = regress(data(brain_voxels(i),:)',[gs' ones(length(gs),1) rot_x rot_y rot_z trn_x trn_y trn_z drot_x drot_y drot_z dtrn_x dtrn_y dtrn_z srot_x srot_y srot_z strn_x strn_y strn_z sdrot_x sdrot_y sdrot_z sdtrn_x sdtrn_y sdtrn_z ]); % could consider adding first-order temporal deriv. 
    b(brain_voxels(i)) = betas(1); % log the gs beta;
     warning('off','last');
    
end

% reshape, write, and compress ocme+meica+mgtr time-series
data = reshape(data + data_mean,[dims(1),dims(2),dims(3),dims(4)]); % add the temporal mean back in; 
info_4D.Filename = Output_MGTR;
system(['rm ' Output_MGTR '*']);
niftiwrite(data,Output_MGTR,info_4D);
system(['gzip ' Output_MGTR '.nii']);

% reshape, write, and compress beta map;
b = reshape(b,[dims(1),dims(2),dims(3),1]);
info_3D.Filename = Output_Betas;
system(['rm ' Output_Betas '*']);
niftiwrite(b,Output_Betas,info_3D);
system(['gzip ' Output_Betas '.nii']);


