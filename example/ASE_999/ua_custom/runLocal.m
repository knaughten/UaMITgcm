function runLocal

addpath(genpath('/media/janryd69/mainJDeRydt/UaMITgcm_v2/UaMITgcm_git/UaSource_beta_25Mar2020'));
addpath(genpath('/media/janryd69/mainJDeRydt/UaMITgcm_v2/UaMITgcm_git/coupling'));

fileID = fopen('options_for_ua','w');
fprintf(fileID,'PTDC_801\n');
fprintf(fileID,'/media/janryd69/mainJDeRydt/UaMITgcm_v2/cases/PTDC_666/output/\n');
fprintf(fileID,'calendar\nNewMeltrate.mat\nDataForMIT.mat\nmatlab\nxy');
fclose(fileID);

copyfile('/media/janryd69/mainJDeRydt/UaMITgcm_v2/Ua_InputData/Amundsen_Inverse_ERS_1996_dhdtErr0.1_MITmelt_gsC100000_gsA100000_gaC1_gaA100_kH100_Weertman_m3_Bedmachine20200715_InverseRestartFile.mat','./PTDC_801-RestartFile.mat');

callUa;

