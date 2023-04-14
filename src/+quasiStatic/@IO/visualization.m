function visualization(obj, network, process,ii)
format long
num = num2str(ii, '%0.3d');


savingFolder = strcat(pwd,'/results/',network.name,'/visualization');
if ~exist(savingFolder, 'dir')
    mkdir(savingFolder)
end
 
fileName = strcat(network.name,'_',process,'_',num,'.vtk'); 
vtkFileID = fopen(fullfile(savingFolder,fileName),'w');   


if vtkFileID == -1
    error('Cannot open file for writing.');
end
title = fileName;
imaginaryPoints = network.numOfInletLinks + network.numOfOutletLinks;
points = network.numberOfNodes+imaginaryPoints;
fprintf ( vtkFileID, '# vtk DataFile Version 2.0\n' );
fprintf ( vtkFileID, '%s\n', title );
fprintf ( vtkFileID, 'ASCII\n' );
fprintf ( vtkFileID, '\n' );
fprintf ( vtkFileID, 'DATASET POLYDATA\n' );

fprintf ( vtkFileID, 'POINTS %d double\n', points );
for i = 1:network.numberOfNodes
    fprintf( vtkFileID,'%d %d %d \n', network.Nodes{i}.x_coordinate, network.Nodes{i}.y_coordinate, network.Nodes{i}.z_coordinate);
end

for i = 1:network.numberOfLinks
    if network.Links{i}.isInlet
        ID = network.Links{i}.pore2Index;
        fprintf( vtkFileID,'%d %d %d \n', network.Nodes{ID}.x_coordinate-network.Links{i}.length, network.Nodes{ID}.y_coordinate, network.Nodes{ID}.z_coordinate);
    elseif network.Links{i}.isOutlet
        ID = network.Links{i}.pore1Index;
        fprintf( vtkFileID,'%d %d %d \n', network.Nodes{ID}.x_coordinate+network.Links{i}.length, network.Nodes{ID}.y_coordinate, network.Nodes{ID}.z_coordinate);
    end
end


fprintf ( vtkFileID, 'LINES %d %d\n', network.numberOfLinks, 3*network.numberOfLinks);
imagine = -1;
for i = 1:network.numberOfLinks
    pore1Index = network.Links{i}.pore1Index-1;
    pore2Index = network.Links{i}.pore2Index-1;
    if ~network.Links{i}.isInlet && ~network.Links{i}.isOutlet
        fprintf( vtkFileID,'%d %d %d %d\n', 2, pore2Index,pore1Index);
    elseif network.Links{i}.isInlet
        imagine = imagine + 1;
        fprintf( vtkFileID,'%d %d %d %d\n', 2, pore2Index,network.numberOfNodes+imagine);
    else
        imagine = imagine + 1;
        fprintf( vtkFileID,'%d %d %d %d\n', 2, network.numberOfNodes+imagine,pore1Index);
    end
end

%% Initializing
if strcmp(process , 'Initializing')== 1
    fprintf ( vtkFileID, 'POINT_DATA  %d \n', network.numberOfNodes+imaginaryPoints);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%% Radius
    fprintf ( vtkFileID, 'SCALARS radius float  %d \n', 1);
    fprintf ( vtkFileID, 'LOOKUP_TABLE default\n');
    for i = 1:network.numberOfNodes
        fprintf( vtkFileID,'%d \n', network.Nodes{i}.radius);
    end
    for i = 1:network.numberOfNodes
        if network.Nodes{i}.isInlet
            fprintf( vtkFileID,'%d \n', network.Nodes{i}.radius);
        elseif network.Nodes{i}.isOutlet
            fprintf( vtkFileID,'%d \n', network.Nodes{i}.radius);
        end
    end
    
if network.calculateSinglePhasePressureDistribution
    %%%%%%%%%%%%%%%%%%%%%%%%%%% Pressure
    fprintf ( vtkFileID, 'SCALARS pressure float  %d \n', 1);
    fprintf ( vtkFileID, 'LOOKUP_TABLE default\n');
    for i = 1:network.numberOfNodes
        fprintf( vtkFileID,'%d \n', network.Nodes{i}.wettingPhasePressure);
    end
    for i = 1:network.numberOfNodes
        if network.Nodes{i}.isInlet
            fprintf( vtkFileID,'%d \n', 1);
        elseif network.Nodes{i}.isOutlet
            fprintf( vtkFileID,'%d \n', 0);
        end
    end
end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PoreID
    fprintf ( vtkFileID, 'SCALARS ID float  %d \n', 1);
    fprintf ( vtkFileID, 'LOOKUP_TABLE default\n');
    for i = 1:network.numberOfNodes
        fprintf( vtkFileID,'%d \n', network.Nodes{i}.index);
    end
    for i = 1:network.numberOfNodes
        if network.Nodes{i}.isInlet
            fprintf( vtkFileID,'%d \n', 0);
        elseif network.Nodes{i}.isOutlet
            fprintf( vtkFileID,'%d \n', 0);
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PoreLabel
    fprintf ( vtkFileID, 'SCALARS poreLabel float  %d \n', 1);
    fprintf ( vtkFileID, 'LOOKUP_TABLE default\n');
    for i = 1:network.numberOfNodes
        fprintf( vtkFileID,'%d \n', -1);
    end
    for i = 1:network.numberOfNodes
        if network.Nodes{i}.isInlet
            fprintf( vtkFileID,'%d \n', 2);
        elseif network.Nodes{i}.isOutlet
            fprintf( vtkFileID,'%d \n', 3);
        end
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PoreVolume
    fprintf ( vtkFileID, 'SCALARS networkPoreVolume_m3 float  %d \n', 1);
    fprintf ( vtkFileID, 'LOOKUP_TABLE default\n');
    for i = 1:network.numberOfNodes
        fprintf( vtkFileID,'%d \n', network.Nodes{i}.volume);
    end
    for i = 1:network.numberOfNodes
        if network.Nodes{i}.isInlet
            fprintf( vtkFileID,'%d \n', 0);
        elseif network.Nodes{i}.isOutlet
            fprintf( vtkFileID,'%d \n', 0);
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PoreLabel_sub
    fprintf ( vtkFileID, 'SCALARS poreLabelSub float  %d \n', 1);
    fprintf ( vtkFileID, 'LOOKUP_TABLE default\n');
    for i = 1:network.numberOfNodes
        if network.Nodes{i}.isInSubArea           
            fprintf( vtkFileID,'%d \n', 1);
        else
            fprintf( vtkFileID,'%d \n', 0);
        end 
    end
    for i = 1:network.numberOfNodes
        if network.Nodes{i}.isInlet
            fprintf( vtkFileID,'%d \n', 0);
        elseif network.Nodes{i}.isOutlet
            fprintf( vtkFileID,'%d \n', 0);
        end
    end
     
    fprintf ( vtkFileID, 'CELL_DATA  %d \n',network.numberOfLinks);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Throat label 
    fprintf ( vtkFileID, 'SCALARS throatLabel float  %d \n', 1);
    fprintf ( vtkFileID, 'LOOKUP_TABLE default\n');
    for i = 1:network.numberOfLinks
        if network.Links{i}.isInlet
            fprintf( vtkFileID,'%d \n', 2);
        elseif network.Links{i}.isOutlet
            fprintf( vtkFileID,'%d \n', 3);
        else
            fprintf( vtkFileID,'%d \n', -1);
        end        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Throat ID 
    fprintf ( vtkFileID, 'SCALARS throatID float  %d \n', 1);
    fprintf ( vtkFileID, 'LOOKUP_TABLE default\n');
    for i = 1:network.numberOfLinks 
        fprintf( vtkFileID,'%d \n', network.Links{i}.index);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Throat Label_sub
    fprintf ( vtkFileID, 'SCALARS throatLabelSub float  %d \n', 1);
    fprintf ( vtkFileID, 'LOOKUP_TABLE default\n');
    for i = 1:network.numberOfLinks
        if network.Links{i}.isInSubArea            
            fprintf( vtkFileID,'%d \n', 1);
        else
            fprintf( vtkFileID,'%d \n', 0);
        end
    end 

    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% length 
    fprintf ( vtkFileID, 'SCALARS theoatLength float  %d \n', 1);
    fprintf ( vtkFileID, 'LOOKUP_TABLE default\n');
    for i = 1:network.numberOfLinks
        fprintf( vtkFileID,'%d \n', network.Links{i}.length);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Radius 
    fprintf ( vtkFileID, 'SCALARS radius float  %d \n', 1);
    fprintf ( vtkFileID, 'LOOKUP_TABLE default\n');
    for i = 1:network.numberOfLinks
        fprintf( vtkFileID,'%d \n', network.Links{i}.radius);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Area 
    fprintf ( vtkFileID, 'SCALARS area float  %d \n', 1);
    fprintf ( vtkFileID, 'LOOKUP_TABLE default\n');
    for i = 1:network.numberOfLinks
        fprintf( vtkFileID,'%d \n', network.Links{i}.area);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% shapefactor 
    fprintf ( vtkFileID, 'SCALARS shapefactor float  %d \n', 1);
    fprintf ( vtkFileID, 'LOOKUP_TABLE default\n');
    for i = 1:network.numberOfLinks
        fprintf( vtkFileID,'%d \n', network.Links{i}.shapeFactor);
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% transmissibilityWithPores 
    fprintf ( vtkFileID, 'SCALARS transmissibilityWithPores float  %d \n', 1);
    fprintf ( vtkFileID, 'LOOKUP_TABLE default\n');
    for i = 1:network.numberOfLinks
    node1Index = network.Links{i}.pore1Index;
    node2Index = network.Links{i}.pore2Index;
        if network.Links{i}.isInlet
            conductanceSinglePhaseWithPores = ((network.Links{i}.length  /network.Links{i}.conductanceSinglePhase) +...
            ((network.Links{i}.pore2Length/ network.Nodes{node2Index}.conductanceSinglePhase)))^-1;
        elseif network.Links{i}.isOutlet
        conductanceSinglePhaseWithPores = ( (network.Links{i}.length  / network.Links{i}.conductanceSinglePhase) +...
            ((network.Links{i}.pore1Length / network.Nodes{node1Index}.conductanceSinglePhase)))^-1;
        else
        conductanceSinglePhaseWithPores = ((network.Links{i}.length / network.Links{i}.conductanceSinglePhase) +...
            ((network.Links{i}.pore1Length / network.Nodes{node1Index}.conductanceSinglePhase) +...
            (network.Links{i}.pore2Length / network.Nodes{node2Index}.conductanceSinglePhase)))^-1;
        end        
        fprintf( vtkFileID,'%d \n', conductanceSinglePhaseWithPores);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% transmissibility 
    fprintf ( vtkFileID, 'SCALARS transmissibility float  %d \n', 1);
    fprintf ( vtkFileID, 'LOOKUP_TABLE default\n');
    for i = 1:network.numberOfLinks
        fprintf( vtkFileID,'%d \n', network.Links{i}.conductanceSinglePhase/network.Links{i}.length);
    end
    
    
if network.calculateSinglePhasePressureDistribution
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Pressure
    fprintf ( vtkFileID, 'SCALARS pressure float  %d \n', 1);
    fprintf ( vtkFileID, 'LOOKUP_TABLE default\n');
    for i = 1:network.numberOfLinks
        fprintf( vtkFileID,'%d \n', network.Links{i}.wettingPhasePressure);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% volumeFlux 
    fprintf ( vtkFileID, 'SCALARS volumeFlux float  %d \n', 1);
    fprintf ( vtkFileID, 'LOOKUP_TABLE default\n');
    for i = 1:network.numberOfLinks
    node1Index = network.Links{i}.pore1Index;
    node2Index = network.Links{i}.pore2Index;
        if network.Links{i}.isInlet
        volumeFlux = network.Links{i}.conductanceSinglePhase/network.Links{i}.length/network.wettingPhase_Viscosity_PaS * ...
            (network.inletPressure_Pa - network.Nodes{node2Index}.wettingPhasePressure);
        elseif network.Links{i}.isOutlet
        volumeFlux = network.Links{i}.conductanceSinglePhase/network.Links{i}.length/network.wettingPhase_Viscosity_PaS * ...
            (network.Nodes{node1Index}.wettingPhasePressure - network.outletPressure_Pa);
        else
        volumeFlux = network.Links{i}.conductanceSinglePhase/network.Links{i}.length /network.wettingPhase_Viscosity_PaS* ...
            abs(network.Nodes{node1Index}.wettingPhasePressure - network.Nodes{node2Index}.wettingPhasePressure); 
        end        
        fprintf( vtkFileID,'%d \n', volumeFlux);
    end
end
     
    %% Two phase flow
elseif strcmp(process , 'PD')== 1 || strcmp(process , 'SI')== 1
    fprintf ( vtkFileID, 'POINT_DATA  %d \n', network.numberOfNodes+imaginaryPoints);
    fprintf ( vtkFileID, 'SCALARS radius float  %d \n', 1);
    fprintf ( vtkFileID, 'LOOKUP_TABLE default\n');
    for i = 1:network.numberOfNodes
        fprintf( vtkFileID,'%d \n', network.Nodes{i}.radius);
    end
    for i = 1:network.numberOfNodes
        if network.Nodes{i}.isInlet
            fprintf( vtkFileID,'%d \n', 0);
        elseif network.Nodes{i}.isOutlet
            fprintf( vtkFileID,'%d \n', 0);
        end
    end
    fprintf ( vtkFileID, 'SCALARS pressure float  %d \n', 1);
    fprintf ( vtkFileID, 'LOOKUP_TABLE default\n');
    for i = 1:network.numberOfNodes
        fprintf( vtkFileID,'%d \n', network.Nodes{i}.wettingPhasePressure);
    end
    for i = 1:network.numberOfNodes
        if strcmp(process , 'PD')== 1
            if network.Nodes{i}.isInlet
                fprintf( vtkFileID,'%d \n', 0);
            elseif network.Nodes{i}.isOutlet
                fprintf( vtkFileID,'%d \n', 1);
            end
        elseif strcmp(process , 'SI')== 1
            if network.Nodes{i}.isInlet
                fprintf( vtkFileID,'%d \n', 1);
            elseif network.Nodes{i}.isOutlet
                fprintf( vtkFileID,'%d \n', 0);
            end
        end
    end
    fprintf ( vtkFileID, 'SCALARS wettingPhaseSaturation float  %d \n', 1);
    fprintf ( vtkFileID, 'LOOKUP_TABLE default\n');
    for i = 1:network.numberOfNodes
        fprintf( vtkFileID,'%d \n', network.Nodes{i}.wettingPhaseSaturation);
    end
    for i = 1:network.numberOfNodes
        if strcmp(process , 'PD')== 1
            if network.Nodes{i}.isInlet
                fprintf( vtkFileID,'%d \n', 0);
            elseif network.Nodes{i}.isOutlet
                fprintf( vtkFileID,'%d \n', 1);
            end
        elseif strcmp(process , 'SI')== 1
            if network.Nodes{i}.isInlet
                fprintf( vtkFileID,'%d \n', 1);
            elseif network.Nodes{i}.isOutlet
                fprintf( vtkFileID,'%d \n', 0);
            end
        end
    end
    
    fprintf ( vtkFileID, 'CELL_DATA  %d \n',network.numberOfLinks);
    fprintf ( vtkFileID, 'SCALARS radius float  %d \n', 1);
    fprintf ( vtkFileID, 'LOOKUP_TABLE default\n');
    for i = 1:network.numberOfLinks
        fprintf( vtkFileID,'%d \n', network.Links{i}.radius);
    end
    fprintf ( vtkFileID, 'SCALARS pressure float  %d \n', 1);
    fprintf ( vtkFileID, 'LOOKUP_TABLE default\n');
    for i = 1:network.numberOfLinks
        fprintf( vtkFileID,'%d \n', network.Links{i}.wettingPhasePressure);
    end
    fprintf ( vtkFileID, 'SCALARS wettingPhaseSaturation float  %d \n', 1);
    fprintf ( vtkFileID, 'LOOKUP_TABLE default\n');
    for i = 1:network.numberOfLinks
        fprintf( vtkFileID,'%d \n', network.Links{i}.wettingPhaseSaturation);
    end
end

end