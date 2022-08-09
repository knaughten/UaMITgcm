function runLocal

addpath(genpath('/media/wchm8/mainJDeRydt/UaMITgcm_v2/UaMITgcm_archer2/UaSource_7Dec2021'));
addpath(genpath('/media/wchm8/mainJDeRydt/UaMITgcm_v2/UaMITgcm_archer2/coupling'));

fileID = fopen('options_for_ua','w');
fprintf(fileID,'AMUND_999\n');
fprintf(fileID,'/media/wchm8/mainJDeRydt/UaMITgcm_v2/UaMITgcm_development/AMUND_999/output/\n');
fprintf(fileID,'calendar\nNewMeltrate.mat\nDataForMIT.mat\nmatlab\nlatlon');
fclose(fileID);

%copyfile('/media/janryd69/mainJDeRydt/UaMITgcm_v2/Ua_InputData/Amundsen_Inverse_ERS_1996_dhdtErr0.1_MITmelt_gsC100000_gsA100000_gaC1_gaA100_kH100_Weertman_m3_Bedmachine20200715_InverseRestartFile.mat','./PTDC_801-RestartFile.mat');

callUa;

