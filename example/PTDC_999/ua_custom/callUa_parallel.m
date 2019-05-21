function callUa_parallel

setmcruserdata('ParallelProfile','local.settings');
setPool; % sets up pool of local workers

callUa; % calls Ua

end
