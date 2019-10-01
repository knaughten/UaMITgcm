function ua_postprocess (expt_name, output_path, out_file)

% Get paths to each segment
files = dir(output_path);
segment_dir = [];
for i=1:length(files)
    if files(i).isdir && ~isempty(str2num(files(i).name))
        segment_dir(end+1)= str2num(files(i).name);
    end
end
segment_dir = sort(segment_dir);

% Initialise arrays
time_ts = [];
iceVAF_ts = [];
iceVolume_ts = [];
groundedArea_ts = [];
xGL_all = {};
yGL_all = {};

% Loop over segments
for i=1:length(segment_dir)
    
    % Get paths to each Ua output file within this segment
    path = [output_path,'/',num2str(segment_dir(i)),'/Ua/'];
    files = dir(path);
    ua_files = {};
    for j=1:length(files)
        fname = files(j).name;
        if startsWith(fname,expt_name) && endsWith(fname,'.mat') && ~endsWith(fname, 'RestartFile.mat')
            ua_files{end+1}=[path,fname];
        end
    end
    ua_files = sort(ua_files);
    
    % Loop over files
    for j=1:length(ua_files)
        disp(['Processing ',ua_files{j}]);
        % Read the data we need
        load(ua_files{j},'CtrlVar','MUA','h','B','S','rho','rhow','GF','time')
        % Save the time value
        time_ts(end+1) = time;
        % Calculate timeseries variables and save
        [iceVAF,iceVolume,groundedArea] = CalcVAF(CtrlVar,MUA,h,B,S,rho,rhow,GF);
        iceVAF_ts(end+1) = iceVAF.Total;
        iceVolume_ts(end+1) = iceVolume.Total;
        groundedArea_ts(end+1) = groundedArea.Total;
        % Calculate grounding line coordinates and save
        GLgeo = GLgeometry(MUA.connectivity,MUA.coordinates,GF,CtrlVar);
        [xGL, yGL] = ArrangeGroundingLinePos(CtrlVar,GLgeo,1);
        xGL_all{end+1} = xGL;
        yGL_all{end+1} = yGL;
    end
end       

% Have to pad grounding line coordinates with NaNs so they're regular 2D
% arrays
disp(['Preparing GL coordinates for writing'])
num_GL = max(cellfun('size',xGL_all,1));
num_time = length(time_ts);
xGL_new = NaN*ones(num_GL,num_time);
yGL_new = NaN*ones(num_GL,num_time);
for t=1:num_time
    m_t = length(xGL_all{t});
    xGL_new(1:m_t,t) = xGL_all{t};
    yGL_new(1:m_t,t) = yGL_all{t};
end

% Write NetCDF file
disp(['Writing ', out_file])
ts_vars = {'time', 'iceVAF', 'iceVolume', 'groundedArea'};
ts_units = {'s', 'm^3', 'm^3', 'm^2'};
ts_data = {time_ts, iceVAF_ts, iceVolume_ts, groundedArea_ts};
for i=1:length(ts_vars)
    nccreate(out_file, ts_vars{i}, 'Dimensions', {'time', num_time}, 'Format', 'netcdf4');
    ncwriteatt(out_file, ts_vars{i}, 'units', ts_units{i});
    ncwrite(out_file, ts_vars{i}, ts_data{i});
end
gl_vars = {'xGL', 'yGL'};
gl_data = {xGL_new, yGL_new};
for i=1:length(gl_vars)
    nccreate(out_file, gl_vars{i}, 'Dimensions', {'i', Inf, 'time', num_time}, 'Format', 'netcdf4', 'FillValue', NaN)
    ncwriteatt(out_file, gl_vars{i}, 'units', 'm');
    ncwrite(out_file, gl_vars{i}, gl_data{i});
end

end
    

