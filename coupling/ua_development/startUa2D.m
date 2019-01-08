% Wrapper function to act as the main program for Matlab compiler.
function [] = startUa2D()

setenv('UaHomeDirectory','./')
UaHomeDirectory=getenv('UaHomeDirectory'); addpath(genpath(UaHomeDirectory))
callUa

end
