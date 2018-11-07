##############################################################
# Classes and functions to prepare for the coupled simulation.
##############################################################

from config_options import *
from mitgcm_python.utils import real_dir


# Options object containing all the user-defined options, read from config_options.py and error checked

class Options:

    # Check and save all the options.
    def __init__ (self):

        # Inner function to report an illegal value
        def throw_error (var_name, var, legal=None):
            print 'Error reading config_options.py'
            print 'Invalid value of ' + var_name + ' = ' + str(var)
            if legal is not None:
                print 'Legal options are: '
                print legal
            sys.exit()

        # Inner function to error check a variable
        def check_value (var_name, var, type='str', legal=None):
            # First convert to the right type if needed
            if type == 'bool':
                # Careful with converting strings to boolean
                if var in [True, 'True', 'true', 'T', 't', 1]:
                    return True
                elif var in [False, 'False', 'false', 'F', 'f', 0]:
                    return False
                else:
                    throw_error(var_name, var, legal=[True, False])
            elif type in ['float', 'int']:
                # Try to convert to a number
                try:
                    if type == 'float':
                        var = float(var)
                    elif type == 'int':
                        var = int(var)
                except(ValueError):
                    throw_error(var_name, var, legal=legal)
            elif type == 'str':
                # Everything can be convererted to a string
                var = str(var)
            # Now check against legal options
            if legal is not None and var not in legal:
                throw_error(var_name, var, legal=legal)
            return var

        # Check all the variables and save them to this object
        self.mit_case_dir = real_dir(check_value('mit_case_dir', mit_case_dir))
        # Save the run directory derived from this
        self.mit_run_dir = self.mit_case_dir + 'run/'
        
        self.x_is_lon = check_value('x_is_lon', x_is_lon, type='bool')
        self.digging = check_value('digging', digging, legal=['none', 'bathy', 'draft'])
        self.pload_option = check_value('pload_option', pload_option, legal=['constant', 'nearest'])
        if self.pload_option == 'constant':
            self.pload_temp = check_value('pload_temp', pload_temp, type='float')
            self.pload_salt = check_value('pload_salt', pload_salt, type='float')
        else:
            # Set dummy values for pload_temp and pload_salt; since they're never used, there's no need to error check
            self.pload_temp = 0.
            self.pload_salt = 0.
            
        self.use_seaice = check_value('use_seaice', use_seaice, type='bool')
        self.hFacMin = check_value('hFacMin', hFacMin, type='float')
        self.hFacMinDr = check_value('hFacMinDr', hFacMinDr, type='float')
        self.readBinaryPrec = check_value('readBinaryPrec', readBinaryPrec, type='int', legal=[32, 64])
        self.readStatePrec = check_value('readStatePrec', readStatePrec, type='int', legal=[32, 64])
        self.rhoConst = check_value('rhoConst', rhoConst, type='float')
        self.eosType = check_value('eosType', eosType, legal=['MDJWF', 'JMD95', 'LINEAR'])
        if self.eosType == 'LINEAR':
            self.tAlpha = check_value('tAlpha', tAlpha, type='float')
            self.sBeta = check_value('sBeta', sBeta, type='float')
            self.Tref = check_value('Tref', Tref, type='float')
            self.Sref = check_value('Sref', Sref, type='float')
        else:
            # Dummy values
            self.tAlpha = 0.
            self.sBeta = 0.
            self.Tref = 0.
            self.Sref = 0.
            
        self.bathyFile = check_value('bathyFile', bathyFile)
        self.draftFile = check_value('draftFile', draftFile)
        self.ini_temp_file = check_value('ini_temp_file', ini_temp_file)
        self.ini_salt_file = check_value('ini_salt_file', ini_salt_file)
        self.ini_u_file = check_value('ini_u_file', ini_u_file)
        self.ini_v_file = check_value('ini_v_file', ini_v_file)
        if self.use_seaice:
            self.ini_area_file = check_value('ini_area_file', ini_area_file)
            self.ini_heff_file = check_value('ini_heff_file', ini_heff_file)
            self.ini_hsnow_file = check_value('ini_hsnow_file', ini_hsnow_file)
            self.ini_uice_file = check_value('ini_uice_file', ini_uice_file)
            self.ini_vice_file = check_value('ini_vice_file', ini_vice_file)
        else:
            self.ini_area_file = ''
            self.ini_heff_file = ''
            self.ini_hsnow_file = ''
            self.ini_uice_file = ''
            self.ini_vice_file = ''
        self.pload_file = check_value('pload_file', pload_file)
        self.ismr_head = check_value('ismr_head', ismr_head)
