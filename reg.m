function reg()
addpath('utils');
dirs = dir('.\data');
dirs(1:2) = [];
subjects = {dirs.name};
for i=1:length(subjects)
    %读取nii数据
    subject = subjects{i};
    subject_path = ['data\',subject];
    date_dir = dir(subject_path);
    mri_path = date_dir(~cell2mat({date_dir.isdir})).name;
    mri_path = [subject_path,'\', mri_path];
    date_dir = date_dir(cell2mat({date_dir.isdir}));
    date_dir(1:2) = [];
    
    for j=1:length(date_dir)
        moving_path = getAllFiles([subject_path,'\',date_dir(j).name]);
        moving_path = moving_path{1};
        movingVolume = niftiread(moving_path);
        moving_info = niftiinfo(moving_path);
        movingVolume(isnan(movingVolume)) = 0;
        fixedVolume = niftiread(mri_path);
        fixed_info = niftiinfo(mri_path);
    
        %% 完成的配准代码_1的结果保存在这里
       [movingRegisteredVolume, phi1]  = datscan_to_mri(movingVolume, ...
           fixedVolume, moving_info,fixed_info);
        %将得到的配准结果保存为nii文件
        temp = split(moving_path, '\');
        temp_path = ['.\data\',temp{2},'\',temp{3},'\r',temp{4}];

        niftiwrite(movingRegisteredVolume, temp_path, moving_info);
    end

    date_dir = dir(subject_path);
    mri_path = date_dir(~cell2mat({date_dir.isdir})).name;
    mri_path = [subject_path,'\', mri_path];
    date_dir = date_dir(cell2mat({date_dir.isdir}));
    date_dir(1:2) = [];
    
    tmp_path = '.\tpm\TPM.nii';
    movingVolume = niftiread(mri_path);
    moving_info = niftiinfo(mri_path);
    movingVolume(isnan(movingVolume)) = 0;
    fixedVolume = niftiread(tmp_path);
    fixed_info = niftiinfo(tmp_path);
    %% 完成的配准代码_2的结果保存在这里
    phi2  = mri_to_tpm(movingVolume, fixedVolume, moving_info, fixed_info);
    

    date_dir = dir(subject_path);
    date_dir = date_dir(cell2mat({date_dir.isdir}));
    date_dir(1:2) = [];

    %% 对每个datscan作用这个变换
    for j=1:length(date_dir)
        moving_path = getAllFiles([subject_path,'\',date_dir(j).name]);
        moving_path = moving_path{2};
        movingVolume = niftiread(moving_path);
        moving_info = niftiinfo(moving_path);
        movingVolume(isnan(movingVolume)) = 0;
        %% 对每个datscan作用这个变换
        movingRegisteredVolume = transform2(movingVolume, phi1, phi2);
        %将得到的配准结果保存为rr为前缀的nii文件
        temp = split(moving_path, '\');
        temp_path = ['.\data\',temp{2},'\',temp{3},'\r',temp{4}];
        %% 可以保持PixelDimensions和ImageSize与moving_info中的值相同,或者根据配准代码_2修改moving_info对应的值
        niftiwrite(movingRegisteredVolume, temp_path, moving_info);
    end



    
end



% 强度归一化

dirs = dir('.\data');
dirs(1:2) = [];
dirs = {dirs.name};

mask = niftiread('.\mask\roccipital.nii');
mask = double(mask);
mask_num = sum(mask,'all');

for i=1:length(dirs)
    dates = dir(['.\data\',dirs{i}]);
    dates = dates(cell2mat({dates.isdir}));
    dates(1:2) = [];
    dates = {dates.name};
    for k=1:length(dates)
        all_files = getAllFiles(['.\data\',dirs{i},'\',dates{k}]);
        image = all_files(cellfun(@(x)contains(x, '\w'), all_files));
        image = image{1};
        [filepath,name,ext] = fileparts(image);
        output_path = [filepath,'\n',name,ext];
        V = spm_vol([image,',1']);
        Y = spm_read_vols(V);
        temp = Y .* mask;
        const = nansum(temp,'all') / mask_num; %#ok<*NANSUM> 
        Y(~isnan(Y)) = (Y(~isnan(Y))-const) / const;
        V.dt = [16, 0];
        V.fname = output_path;
        spm_write_vol(V,Y);      
    end
end




%% 生成效果参考图片_version2
addpath('utils');


dirs = dir('.\data');
dirs(1:2) = [];
subjects = {dirs.name};
inds = 24:47;

caudate_margin = niftiread('.\mask\Margin Caudate.nii');
putamen_margin = niftiread('.\mask\Margin Putamen.nii');


for i=1:length(subjects)
    all_files = getAllFiles(['.\data\',subjects{i}]);
    mri_idx = cellfun(@(x)contains(x, '\w')&(~contains(x, 'DaTSCAN')), all_files);
    dat_idx = cellfun(@(x)contains(x, '\wr'), all_files);
    mri_path = all_files{mri_idx};
    V_mri = double(niftiread(mri_path));
    V_mri(isnan(V_mri)) = 0;
    V_mri = (V_mri - min(V_mri, [], 'all')) / (max(V_mri, [], 'all') - min(V_mri, [], 'all'));
    dat_path = all_files(dat_idx);
    for j=1:length(dat_path)
        figure(1);
        set(gcf, 'unit', 'centimeters', 'position', [3 3 30 11]);
        V_dat = double(niftiread(dat_path{j}));
        V_dat(isnan(V_dat)) = 0;
        V_dat = (V_dat - min(V_dat, [], 'all')) / (max(V_dat, [], 'all') - min(V_dat, [], 'all'));
        I_checkboard = zeros(89,105,length(inds));
        for k=1:length(inds)
            temp1 = padarray(V_mri(:,:,inds(k)), [5,5]);
            temp2 = padarray(V_dat(:,:,inds(k)), [5,5]);
            I_checkboard(:,:,k) = cbimage(temp1, temp2, 4);
        end
        subplot(1,3,1);
        montage(I_checkboard, 'size', [6, 4]);
        
        I_checkboard = zeros(89,105,3,length(inds));
        for k=1:length(inds)
            temp = repmat(padarray(V_dat(:,:,inds(k)), [5,5]),[1,1,3]);
            caudate_mask = repmat(padarray(caudate_margin(:,:,inds(k)), [5,5]),[1,1,3]);
            caudate_mask(:,:,3) = 0;
            putamen_mask = repmat(padarray(putamen_margin(:,:,inds(k)), [5,5]),[1,1,3]);
            putamen_mask(:,:,1) = 0;
            mask = imadd(caudate_mask, putamen_mask);
            I_checkboard(:, :, :, k) = imadd(double(mask)*0.3, temp);
        end
        subplot(1,3,2);
        montage(I_checkboard,'size',[6,4]);
        
        I_checkboard = zeros(89,105,length(inds));
        for k=1:length(inds)
            I_checkboard(:, :, k) = padarray(V_dat(:,:,inds(k)), [5,5]);
        end
        subplot(1,3,3);
        montage(I_checkboard,'size',[6,4]);

        temp = split(dat_path{j}, '\');
        sgtitle([temp{3},': ',temp{4}]);
        saveas(gcf,['./check_results_v2/',temp{3},'-',temp{4},'.jpg']);
    end
end

end


%% 需要完成的配准代码_1_datscan以mri为参考的配准代码
function [movingRegisteredVolume, phi] = datscan_to_mri( ...
    movingVolume, fixedVolume, moving_info, fixed_info)
    % 多模态图像配准函数
    % 输入:
    %   movingVolume - 需要配准的浮动图像 (3D 矩阵)
    %   fixedVolume  - 参考图像 (3D 矩阵)
    %   moving_info  - moving_volume的元信息，需要用到的部分已经在代码中获得
    %   fixed_info  -  fixed_volume的元信息，需要用到的部分已经在代码中获得

    % 输出:
    %   movingRegisteredVolume - 配准后的浮动图像 (3D 矩阵)

    
 
   
end



%% 需要完成的配准代码_2_获得mri到tpm的矩阵
function phi = mri_to_tpm(movingVolume, fixedVolume, moving_info, fixed_info)
    % 多模态图像配准函数
    % 输入:
    %   movingVolume - 需要配准的浮动图像 (3D 矩阵)
    %   fixedVolume  - 参考图像 (3D 矩阵)
    %   moving_info  - moving_volume的元信息，需要用到的部分已经在代码中获得
    %   fixed_info  -  fixed_volume的元信息，需要用到的部分已经在代码中获得

   

end


function movingVolume1 = transform2(movingVolume, phi1, phi2)

end