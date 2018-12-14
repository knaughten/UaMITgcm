function setup_Ua(sourcedir)

p = genpath(sourcedir);
addpath(p);
setenv('UaHomeDirectory',sourcedir);
setenv('AntarcticGlobalDataSets','');
setenv('RootDir',sourcedir);
