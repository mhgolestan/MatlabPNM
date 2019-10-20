function visualization(obj, process, ii)
num = num2str(ii, '%0.3d');
fileName = strcat(process,'_glyph',num,'.vtk');
vtkFileID = fopen(fileName,'w');
if vtkFileID == -1
    error('Cannot open file for writing.');
end
title = fileName;
imaginaryPoints = obj.numOfInletLinks + obj.numOfOutletLinks;
points = obj.numberOfNodes+imaginaryPoints;
fprintf ( vtkFileID, '# vtk DataFile Version 2.0\n' );
fprintf ( vtkFileID, '%s\n', title );
fprintf ( vtkFileID, 'ASCII\n' );
fprintf ( vtkFileID, '\n' );
fprintf ( vtkFileID, 'DATASET POLYDATA\n' );

fprintf ( vtkFileID, 'POINTS %d double\n', points );
for i = 1:obj.numberOfNodes
    fprintf( vtkFileID,'%d %d %d \n', obj.Nodes{i}.x_coordinate, obj.Nodes{i}.y_coordinate, obj.Nodes{i}.z_coordinate);
end

for i = 1:obj.numberOfNodes
    if obj.Nodes{i}.isInlet
        fprintf( vtkFileID,'%d %d %d \n', obj.Nodes{i}.x_coordinate-3*obj.Nodes{i}.radius, obj.Nodes{i}.y_coordinate, obj.Nodes{i}.z_coordinate);
    elseif obj.Nodes{i}.isOutlet
        fprintf( vtkFileID,'%d %d %d \n', obj.Nodes{i}.x_coordinate+3*obj.Nodes{i}.radius, obj.Nodes{i}.y_coordinate, obj.Nodes{i}.z_coordinate);
    end
end

fprintf ( vtkFileID, 'LINES %d %d\n', obj.numberOfLinks, 3*obj.numberOfLinks);
imagine = -1;
for i = 1:obj.numberOfLinks
    pore1Index = obj.Links{i}.pore1Index-1;
    pore2Index = obj.Links{i}.pore2Index-1;
    if ~obj.Links{i}.isInlet && ~obj.Links{i}.isOutlet
        fprintf( vtkFileID,'%d %d %d %d\n', 2, pore2Index,pore1Index);
    elseif obj.Links{i}.isInlet
        imagine = imagine + 1;
        fprintf( vtkFileID,'%d %d %d %d\n', 2, pore2Index,obj.numberOfNodes+imagine);
    else
        imagine = imagine + 1;
        fprintf( vtkFileID,'%d %d %d %d\n', 2, obj.numberOfNodes+imagine,pore1Index);
    end
end

% Initializing
if strcmp(process , 'Initializing')== 1
    
    % Nodes Data
    fprintf ( vtkFileID, 'POINT_DATA  %d \n', obj.numberOfNodes+imaginaryPoints);
    % Volume
    fprintf ( vtkFileID, 'SCALARS radius float  %d \n', 1);
    fprintf ( vtkFileID, 'LOOKUP_TABLE default\n');
    for i = 1:obj.numberOfNodes
        fprintf( vtkFileID,'%3.8f \n', obj.Nodes{i}.radius);
    end
    for i = 1:obj.numberOfNodes
        if obj.Nodes{i}.isInlet
            fprintf( vtkFileID,'%3.8f \n', 0);
        elseif obj.Nodes{i}.isOutlet
            fprintf( vtkFileID,'%3.8f \n', 0);
        end
    end
    % Pressure
    fprintf ( vtkFileID, 'SCALARS pressure float  %d \n', 1);
    fprintf ( vtkFileID, 'LOOKUP_TABLE default\n');
    for i = 1:obj.numberOfNodes
        fprintf( vtkFileID,'%3.8f \n', obj.Nodes{i}.waterPressure);
    end
    for i = 1:obj.numberOfNodes
        if obj.Nodes{i}.isInlet
            fprintf( vtkFileID,'%3.8f \n', 1);
        elseif obj.Nodes{i}.isOutlet
            fprintf( vtkFileID,'%3.8f \n', 0);
        end
    end
    
    % Links Data
    fprintf ( vtkFileID, 'CELL_DATA  %d \n',obj.numberOfLinks);
    % Volume
    fprintf ( vtkFileID, 'SCALARS radius float  %d \n', 1);
    fprintf ( vtkFileID, 'LOOKUP_TABLE default\n');
    for i = 1:obj.numberOfLinks
        fprintf( vtkFileID,'%3.8f \n', obj.Links{i}.radius);
    end
    % Pressure
    fprintf ( vtkFileID, 'SCALARS pressure float  %d \n', 1);
    fprintf ( vtkFileID, 'LOOKUP_TABLE default\n');
    for i = 1:obj.numberOfLinks
        fprintf( vtkFileID,'%3.8f \n', obj.Links{i}.waterPressure);
    end 
end