function generateLogo

newData1 = importdata('./NewLogo_Ua.png');

% Create new variables in the base workspace from those fields.
% vars = fieldnames(newData1);
% for i = 1:length(vars)
%     assignin('base', vars{i}, newData1.(vars{i}));
% end
% whos

logo = newData1.cdata(:,:,3)/255;

binaryImage = imclearborder(logo);
boundaries = bwboundaries(binaryImage);

% smooth boundaries
for ii=1:5
    x = boundaries{ii}(:,1);
    y = boundaries{ii}(:,2);
    CtrlVar.GLtension = 1;
    CtrlVar.GLds = 10;
    [boundaries_smooth{ii}(:,1),boundaries_smooth{ii}(:,2),~,~,~] = Smooth2dPos(x,y,CtrlVar);
end

CtrlVar = Ua2D_DefaultParameters();
CtrlVar.PlotNodes=0;
CtrlVar.MeshSizeMax=0.1; CtrlVar.MeshSizeMin=0.1;
MeshBoundaryCoordinates=[boundaries_smooth{1}(:,1) boundaries_smooth{1}(:,2);...
% ...       % Outer boundary (clockwise orientation)
                NaN NaN ;  flipdim(boundaries_smooth{3}(:,1),1) flipdim(boundaries_smooth{3}(:,2),1);...
                NaN NaN ;  flipdim(boundaries_smooth{4}(:,1),1) flipdim(boundaries_smooth{4}(:,2),1);...
                NaN NaN ;  flipdim(boundaries_smooth{5}(:,1),1) flipdim(boundaries_smooth{5}(:,2),1);...
                NaN NaN ;  boundaries_smooth{2}(:,1) boundaries_smooth{2}(:,2)
                ];%
%                NaN NaN ; -0.1 -0.5 ; -0.1 0 ; -0.8 0 ; -0.8 -0.5 ];         % another innner boundary (anticlockwise orientation)
UserVar=[];           
[UserVar,MUA]=genmesh2d(UserVar,CtrlVar,MeshBoundaryCoordinates); 

figure ;  PlotFEmesh(MUA.coordinates,MUA.connectivity,CtrlVar);
axis equal
axis off
title('');
drawnow

return
figure; hold on;
for ii=1:5
x = boundaries{ii}(:, 1);
y = boundaries{ii}(:, 2);
%plot(x, y, '-', 'LineWidth', 2);
x = boundaries_smooth{ii}(:, 1);
y = boundaries_smooth{ii}(:, 2);
plot(y,flipdim(x,1), '--o', 'LineWidth', 1);
axis equal
axis off
title('');
end

return