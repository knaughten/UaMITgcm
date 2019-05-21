myCluster = parcluster('local');
myCluster.JobStorageLocation = '/home/n02/n02/janryd69/work/matlab_scratch';
parpool(myCluster,6);

