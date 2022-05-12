import sys
from xmitgcm import open_mdsdataset

delta_t=int(sys.argv[1])
ref_date=str(sys.argv[2])
ds=open_mdsdataset('../run/', delta_t=delta_t, ref_date=ref_date)
ds.to_netcdf('../run/output.nc', unlimited_dims=['time'])
