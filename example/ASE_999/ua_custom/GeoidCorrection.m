function [geoidcorr] = GeoidCorrection(X,Y)

persistent Fg

if isempty(Fg)

	if ~exist('./GriddedInterpolant_geoid-eigen-6c2-390129.mat')
        
		%froot = '/Users/janderydt/Documents/Work_Data/PIG_DEMs/EIGEN';
		froot = '/media/wchm8/JDeRydt-1/Antarctic_datasets/EIGEN';

		% correct elevations for geoid - use EIGEN geoid

		%fname=strcat(froot,'/eigen-gl04c-389835.gdf');
		%fname=strcat(froot,'/eigen-6c2-389833.gdf');
		fname=strcat(froot,'/eigen-6c2-390129.gdf');
		%load(fname,'geoid');
		delimiter = ' ';
		startRow = 36;
		formatSpec = '%f%f%f%f%[^\n\r]';
		%% Open the text file.
		fileID = fopen(fname,'r');
		dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'MultipleDelimsAsOne', true, 'EmptyValue' ,NaN,'HeaderLines' ,startRow-1, 'ReturnOnError', false);
		%% Close the text file.
		fclose(fileID);
		glon = dataArray{:, 1};
		glat = dataArray{:, 2};
		geoid = dataArray{:, 4};
		clearvars filename delimiter startRow formatSpec fileID dataArray ans;	
		I = find(isnan(geoid));
		glon(I) = []; glat(I)=[]; geoid(I)=[];
		
		[gx,gy]=ll2psxy(glat,glon-360,-71,0);

		geoid=reshape(geoid,[],1);
		gx=reshape(gx,[],1);
		gy=reshape(gy,[],1);

		Fg_scattered = scatteredInterpolant(gx,gy,geoid,'linear','nearest');
        
        %% create gridded interpolant
        dx = 5e3; dy = 5e3;
        x = [min(gx(:)):dx:max(gx(:))];
        y = [min(gy(:)):dy:max(gy(:))];
        [Xinterp,Yinterp] = ndgrid(x,y);
        
        Fg = griddedInterpolant(Xinterp,Yinterp,Fg_scattered(Xinterp,Yinterp));
 
		save('GriddedInterpolant_geoid-eigen-6c2-390129.mat','Fg');
	else
		load GriddedInterpolant_geoid-eigen-6c2-390129.mat
	end

end

geoidcorr = Fg(X(:),Y(:));
geoidcorr = reshape(geoidcorr,size(X));
geoidcorr(isnan(geoidcorr))=0;
