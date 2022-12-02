function visualization(obj,networkFileName, process,ii)
format long
num = num2str(ii, '%0.3d');

currentFoldet = pwd;
networkFileFullPath = strcat(currentFoldet, '/Results/');
fileName = strcat(networkFileName,'_',process,num,'.vtk'); 
vtkFileID = fopen(fullfile(networkFileFullPath,fileName),'w');   
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

for i = 1:obj.numberOfLinks
    if obj.Links{i}.isInlet
        ID = obj.Links{i}.pore2Index;
        fprintf( vtkFileID,'%d %d %d \n', obj.Nodes{ID}.x_coordinate-obj.Links{i}.length, obj.Nodes{ID}.y_coordinate, obj.Nodes{ID}.z_coordinate);
    elseif obj.Links{i}.isOutlet
        ID = obj.Links{i}.pore1Index;
        fprintf( vtkFileID,'%d %d %d \n', obj.Nodes{ID}.x_coordinate+obj.Links{i}.length, obj.Nodes{ID}.y_coordinate, obj.Nodes{ID}.z_coordinate);
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
    fprintf ( vtkFileID, 'POINT_DATA  %d \n', obj.numberOfNodes+imaginaryPoints);
    %%%%%%%%%%%%%%%%%%%%%%%%%%% Radius
    fprintf ( vtkFileID, 'SCALARS radius float  %d \n', 1);
    fprintf ( vtkFileID, 'LOOKUP_TABLE default\n');
    for i = 1:obj.numberOfNodes
        fprintf( vtkFileID,'%d \n', obj.Nodes{i}.radius);
    end
    for i = 1:obj.numberOfNodes
        if obj.Nodes{i}.isInlet
            fprintf( vtkFileID,'%d \n', obj.Nodes{i}.radius);
        elseif obj.Nodes{i}.isOutlet
            fprintf( vtkFileID,'%d \n', obj.Nodes{i}.radius);
        end
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%% Pressure
    fprintf ( vtkFileID, 'SCALARS pressure float  %d \n', 1);
    fprintf ( vtkFileID, 'LOOKUP_TABLE default\n');
    for i = 1:obj.numberOfNodes
        fprintf( vtkFileID,'%d \n', obj.Nodes{i}.waterPressure);
    end
    for i = 1:obj.numberOfNodes
        if obj.Nodes{i}.isInlet
            fprintf( vtkFileID,'%d \n', 1);
        elseif obj.Nodes{i}.isOutlet
            fprintf( vtkFileID,'%d \n', 0);
        end
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PoreLabel
    fprintf ( vtkFileID, 'SCALARS poreLabel float  %d \n', 1);
    fprintf ( vtkFileID, 'LOOKUP_TABLE default\n');
    for i = 1:obj.numberOfNodes
        fprintf( vtkFileID,'%d \n', -1);
    end
    for i = 1:obj.numberOfNodes
        if obj.Nodes{i}.isInlet
            fprintf( vtkFileID,'%d \n', 2);
        elseif obj.Nodes{i}.isOutlet
            fprintf( vtkFileID,'%d \n', 3);
        end
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PoreVolume
    fprintf ( vtkFileID, 'SCALARS poreVolume float  %d \n', 1);
    fprintf ( vtkFileID, 'LOOKUP_TABLE default\n');
    for i = 1:obj.numberOfNodes
        fprintf( vtkFileID,'%d \n', obj.Nodes{i}.volume);
    end
    for i = 1:obj.numberOfNodes
        if obj.Nodes{i}.isInlet
            fprintf( vtkFileID,'%d \n', 0);
        elseif obj.Nodes{i}.isOutlet
            fprintf( vtkFileID,'%d \n', 0);
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PoreLabel_sub
    fprintf ( vtkFileID, 'SCALARS poreLabelSub float  %d \n', 1);
    fprintf ( vtkFileID, 'LOOKUP_TABLE default\n');
    for i = 1:obj.numberOfNodes
        if obj.Nodes{i}.isInSubArea           
            fprintf( vtkFileID,'%d \n', 1);
        else
            fprintf( vtkFileID,'%d \n', 0);
        end 
    end
    for i = 1:obj.numberOfNodes
        if obj.Nodes{i}.isInlet
            fprintf( vtkFileID,'%d \n', 0);
        elseif obj.Nodes{i}.isOutlet
            fprintf( vtkFileID,'%d \n', 0);
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Pressure
    fprintf ( vtkFileID, 'CELL_DATA  %d \n',obj.numberOfLinks);
    fprintf ( vtkFileID, 'SCALARS pressure float  %d \n', 1);
    fprintf ( vtkFileID, 'LOOKUP_TABLE default\n');
    for i = 1:obj.numberOfLinks
        fprintf( vtkFileID,'%d \n', obj.Links{i}.waterPressure);
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Throat label 
    fprintf ( vtkFileID, 'SCALARS throatLabel float  %d \n', 1);
    fprintf ( vtkFileID, 'LOOKUP_TABLE default\n');
    for i = 1:obj.numberOfLinks
        if obj.Links{i}.isInlet
            fprintf( vtkFileID,'%d \n', 2);
        elseif obj.Links{i}.isOutlet
            fprintf( vtkFileID,'%d \n', 3);
        else
            fprintf( vtkFileID,'%d \n', -1);
        end        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Throat Label_sub
    fprintf ( vtkFileID, 'SCALARS throatLabelSub float  %d \n', 1);
    fprintf ( vtkFileID, 'LOOKUP_TABLE default\n');
    for i = 1:obj.numberOfLinks
        if obj.Links{i}.isInSubArea            
            fprintf( vtkFileID,'%d \n', 1);
        else
            fprintf( vtkFileID,'%d \n', 0);
        end
    end 

    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% length 
    fprintf ( vtkFileID, 'SCALARS theoatLength float  %d \n', 1);
    fprintf ( vtkFileID, 'LOOKUP_TABLE default\n');
    for i = 1:obj.numberOfLinks
        fprintf( vtkFileID,'%d \n', obj.Links{i}.length);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Radius 
    fprintf ( vtkFileID, 'SCALARS radius float  %d \n', 1);
    fprintf ( vtkFileID, 'LOOKUP_TABLE default\n');
    for i = 1:obj.numberOfLinks
        fprintf( vtkFileID,'%d \n', obj.Links{i}.radius);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Area 
    fprintf ( vtkFileID, 'SCALARS area float  %d \n', 1);
    fprintf ( vtkFileID, 'LOOKUP_TABLE default\n');
    for i = 1:obj.numberOfLinks
        fprintf( vtkFileID,'%d \n', obj.Links{i}.area);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% shapefactor 
    fprintf ( vtkFileID, 'SCALARS shapefactor float  %d \n', 1);
    fprintf ( vtkFileID, 'LOOKUP_TABLE default\n');
    for i = 1:obj.numberOfLinks
        fprintf( vtkFileID,'%d \n', obj.Links{i}.shapeFactor);
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% transmissibilityWithPores 
    fprintf ( vtkFileID, 'SCALARS transmissibilityWithPores float  %d \n', 1);
    fprintf ( vtkFileID, 'LOOKUP_TABLE default\n');
    for i = 1:obj.numberOfLinks
    node1Index = obj.Links{i}.pore1Index;
    node2Index = obj.Links{i}.pore2Index;
        if obj.Links{i}.isInlet
            conductanceSinglePhaseWithPores = ((obj.Links{i}.length  /obj.Links{i}.conductanceSinglePhase) +...
            ((obj.Links{i}.pore2Length/ obj.Nodes{node2Index}.conductanceSinglePhase)))^-1;
        elseif obj.Links{i}.isOutlet
        conductanceSinglePhaseWithPores = ( (obj.Links{i}.length  / obj.Links{i}.conductanceSinglePhase) +...
            ((obj.Links{i}.pore1Length / obj.Nodes{node1Index}.conductanceSinglePhase)))^-1;
        else
        conductanceSinglePhaseWithPores = ((obj.Links{i}.length / obj.Links{i}.conductanceSinglePhase) +...
            ((obj.Links{i}.pore1Length / obj.Nodes{node1Index}.conductanceSinglePhase) +...
            (obj.Links{i}.pore2Length / obj.Nodes{node2Index}.conductanceSinglePhase)))^-1;
        end        
        fprintf( vtkFileID,'%d \n', conductanceSinglePhaseWithPores);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% transmissibility 
    fprintf ( vtkFileID, 'SCALARS transmissibility float  %d \n', 1);
    fprintf ( vtkFileID, 'LOOKUP_TABLE default\n');
    for i = 1:obj.numberOfLinks
        fprintf( vtkFileID,'%d \n', obj.Links{i}.conductanceSinglePhase/obj.Links{i}.length);
    end
        
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% volumeFlux 
    fprintf ( vtkFileID, 'SCALARS volumeFlux float  %d \n', 1);
    fprintf ( vtkFileID, 'LOOKUP_TABLE default\n');
    for i = 1:obj.numberOfLinks
    node1Index = obj.Links{i}.pore1Index;
    node2Index = obj.Links{i}.pore2Index;
        if obj.Links{i}.isInlet
        volumeFlux = obj.Links{i}.conductanceSinglePhase/obj.Links{i}.length/obj.waterViscosity * ...
            (obj.inletPressure - obj.Nodes{node2Index}.waterPressure);
        elseif obj.Links{i}.isOutlet
        volumeFlux = obj.Links{i}.conductanceSinglePhase/obj.Links{i}.length/obj.waterViscosity * ...
            (obj.Nodes{node1Index}.waterPressure - obj.outletPressure);
        else
        volumeFlux = obj.Links{i}.conductanceSinglePhase/obj.Links{i}.length /obj.waterViscosity* ...
            abs(obj.Nodes{node1Index}.waterPressure - obj.Nodes{node2Index}.waterPressure); 
        end        
        fprintf( vtkFileID,'%d \n', volumeFlux);
    end
    
    
    
    
    % Diffusion
elseif strcmp(process , 'Diff')== 1 || strcmp(process , 'Desorption')== 1
    fprintf ( vtkFileID, 'POINT_DATA  %d \n', obj.numberOfNodes+imaginaryPoints);
    fprintf ( vtkFileID, 'SCALARS radius float  %d \n', 1);
    fprintf ( vtkFileID, 'LOOKUP_TABLE default\n');
    for i = 1:obj.numberOfNodes
        fprintf( vtkFileID,'%d \n', obj.Nodes{i}.radius);
    end
    for i = 1:obj.numberOfNodes
        if obj.Nodes{i}.isInlet
            fprintf( vtkFileID,'%d \n',0);
        elseif obj.Nodes{i}.isOutlet
            fprintf( vtkFileID,'%d \n', 0);
        end
    end
    fprintf ( vtkFileID, 'SCALARS pressure float  %d \n', 1);
    fprintf ( vtkFileID, 'LOOKUP_TABLE default\n');
    for i = 1:obj.numberOfNodes
        fprintf( vtkFileID,'%d \n', obj.Nodes{i}.waterPressure);
    end
    for i = 1:obj.numberOfNodes
        if obj.Nodes{i}.isInlet
            fprintf( vtkFileID,'%d \n', 1);
        elseif obj.Nodes{i}.isOutlet
            fprintf( vtkFileID,'%d \n', 0);
        end
    end
    fprintf ( vtkFileID, 'SCALARS concentration float  %d \n', 1);
    fprintf ( vtkFileID, 'LOOKUP_TABLE default\n');
    for i = 1:obj.numberOfNodes
        fprintf( vtkFileID,'%3.8f \n', obj.Nodes{i}.concentration(ii));
    end
    for i = 1:obj.numberOfNodes
        if obj.Nodes{i}.isInlet
            fprintf( vtkFileID,'%3.8f \n', 1);
        elseif obj.Nodes{i}.isOutlet
            fprintf( vtkFileID,'%3.8f \n', 0);
        end
    end
    
    fprintf ( vtkFileID, 'CELL_DATA  %d \n',obj.numberOfLinks );
    fprintf ( vtkFileID, 'SCALARS radius float  %d \n', 1);
    fprintf ( vtkFileID, 'LOOKUP_TABLE default\n');
    for i = 1:obj.numberOfLinks
        fprintf( vtkFileID,'%3.8f \n', obj.Links{i}.radius);
    end
    fprintf ( vtkFileID, 'SCALARS pressure float  %d \n', 1);
    fprintf ( vtkFileID, 'LOOKUP_TABLE default\n');
    for i = 1:obj.numberOfLinks
        fprintf( vtkFileID,'%3.8f \n', obj.Links{i}.waterPressure);
    end
    fprintf ( vtkFileID, 'SCALARS concentration float  %d \n', 1);
    fprintf ( vtkFileID, 'LOOKUP_TABLE default\n');
    for i = 1:obj.numberOfLinks
        fprintf( vtkFileID,'%3.8f \n', obj.Links{i}.concentration(ii));
    end
    % Primary Drainage
elseif strcmp(process , 'PD')== 1 || strcmp(process , 'SI')== 1
    fprintf ( vtkFileID, 'POINT_DATA  %d \n', obj.numberOfNodes+imaginaryPoints);
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
    fprintf ( vtkFileID, 'SCALARS pressure float  %d \n', 1);
    fprintf ( vtkFileID, 'LOOKUP_TABLE default\n');
    for i = 1:obj.numberOfNodes
        fprintf( vtkFileID,'%3.8f \n', obj.Nodes{i}.waterPressure);
    end
    for i = 1:obj.numberOfNodes
        if strcmp(process , 'PD')== 1
            if obj.Nodes{i}.isInlet
                fprintf( vtkFileID,'%3.8f \n', 0);
            elseif obj.Nodes{i}.isOutlet
                fprintf( vtkFileID,'%3.8f \n', 1);
            end
        elseif strcmp(process , 'SI')== 1
            if obj.Nodes{i}.isInlet
                fprintf( vtkFileID,'%3.8f \n', 1);
            elseif obj.Nodes{i}.isOutlet
                fprintf( vtkFileID,'%3.8f \n', 0);
            end
        end
    end
    fprintf ( vtkFileID, 'SCALARS waterSaturation float  %d \n', 1);
    fprintf ( vtkFileID, 'LOOKUP_TABLE default\n');
    for i = 1:obj.numberOfNodes
        fprintf( vtkFileID,'%3.8f \n', obj.Nodes{i}.waterSaturation);
    end
    for i = 1:obj.numberOfNodes
        if strcmp(process , 'PD')== 1
            if obj.Nodes{i}.isInlet
                fprintf( vtkFileID,'%3.8f \n', 0);
            elseif obj.Nodes{i}.isOutlet
                fprintf( vtkFileID,'%3.8f \n', 1);
            end
        elseif strcmp(process , 'SI')== 1
            if obj.Nodes{i}.isInlet
                fprintf( vtkFileID,'%3.8f \n', 1);
            elseif obj.Nodes{i}.isOutlet
                fprintf( vtkFileID,'%3.8f \n', 0);
            end
        end
    end
    
    fprintf ( vtkFileID, 'CELL_DATA  %d \n',obj.numberOfLinks);
    fprintf ( vtkFileID, 'SCALARS radius float  %d \n', 1);
    fprintf ( vtkFileID, 'LOOKUP_TABLE default\n');
    for i = 1:obj.numberOfLinks
        fprintf( vtkFileID,'%3.8f \n', obj.Links{i}.radius);
    end
    fprintf ( vtkFileID, 'SCALARS pressure float  %d \n', 1);
    fprintf ( vtkFileID, 'LOOKUP_TABLE default\n');
    for i = 1:obj.numberOfLinks
        fprintf( vtkFileID,'%3.8f \n', obj.Links{i}.waterPressure);
    end
    fprintf ( vtkFileID, 'SCALARS waterSaturation float  %d \n', 1);
    fprintf ( vtkFileID, 'LOOKUP_TABLE default\n');
    for i = 1:obj.numberOfLinks
        fprintf( vtkFileID,'%3.8f \n', obj.Links{i}.waterSaturation);
    end
end

end