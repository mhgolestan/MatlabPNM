classdef Network
    %Network Summary of this class goes here
    %   This class contain nodes and links of the network
    
    properties
        Nodes
        Links
        xDimention
        yDimention
        zDimention
        numberOfLinks
        numberOfNodes
        
        
        porosity
        absolutePermeability
    end
    
    methods
        function obj = Network(fileName)
            %Network Construct an instance of this class
            %   Detailed explanation goes here
            
%             fileName = 'Berea';
            
            % Opening the files
            link_1_fileID = fopen(strcat(fileName, '_link1.dat'));
            obj.numberOfLinks = str2num(fgetl(link_1_fileID));
            link_2_fileID = fopen(strcat(fileName, '_link2.dat'));
            
            node_2_fileID = fopen(strcat(fileName, '_node2.dat'));            
            node_1_fileID = fopen(strcat(fileName, '_node1.dat'));
            temp = str2num(fgetl(node_1_fileID));
            obj.numberOfNodes = temp(1);
            
            % Network dimention
            obj.xDimention = temp(2);
            obj.yDimention = temp(3);
            obj.zDimention = temp(4);
            
            % Initializing Nodes and Links parameters
            obj.Nodes = cell(obj.numberOfNodes,1);
            obj.Links = cell(obj.numberOfLinks,1);
            
            % 
            for i = 1:obj.numberOfNodes
                node_1_values = str2num(fgetl(node_1_fileID));
                node_2_values = str2num(fgetl(node_2_fileID));
                obj.Nodes{i} = Node(node_1_values(1),... %pore index
                                    node_1_values(2),... % pore x coordinate
                                    node_1_values(3),... % pore y coordinate
                                    node_1_values(4),... % pore z coordinate
                                    node_1_values(5),... %pore connection number
                                    node_1_values(6:end),... % inlet-outlet status and connected link index
                                    node_2_values(2),... % pore volume
                                    node_2_values(3),... % pore radius  
                                    node_2_values(4),... % pore shape factor 
                                    node_2_values(5)); % pore clay volume                        
            end        
            for i = 1:obj.numberOfLinks
               link_1_values = str2num(fgetl(link_1_fileID));
               link_2_values = str2num(fgetl(link_2_fileID));
               obj.Links{i} = Link(link_1_values(1),... %index 
                                    link_1_values(2),... %pore1Index,... 
                                    link_1_values(3),... %pore2Index,...
                                    link_1_values(4),... %radius,...
                                    link_1_values(5),... %shapeFactor,...
                                    link_1_values(6),... %length,...
                                    link_2_values(4),... %pore1Length,...
                                    link_2_values(5),... %pore2Length,...
                                    link_2_values(6),... %linkLength,...
                                    link_2_values(7),... %volume,...
                                    link_2_values(8)); %clayVolume
            end
            
            %closing the files
            fclose(link_1_fileID); fclose(link_2_fileID);
            fclose(node_1_fileID); fclose(node_2_fileID);
            
            %% Porosity calculation
            nodesVolume = 0;
            linksVolume = 0;
            for i = 1:obj.numberOfNodes
                nodesVolume = nodesVolume + (obj.Nodes{i}.volume) ;
            end
            for i = 1:obj.numberOfLinks
                linksVolume = linksVolume + (obj.Links{i}.volume) ;
            end
            obj.porosity = (linksVolume + nodesVolume) / (obj.xDimention * obj.yDimention * obj.zDimention);
           
        end
        %% 
        
        function calculateFlowRate(obj, inletPressure, outletPressure)
            A = zeros(obj.numberOfNodes, obj.numberOfNodes);
            C = zeros(obj.numberOfNodes, 1);
            
            for i = 1:obj.numberOfNodes
                C(i) = inletPressure * (obj.Nodes{i})
                
                
                if obj.Nodes{i}.isInlet
                    
                    
                    
                elseif obj.Nodes{i}.isOutlet
                    
                else
                    
                end
            end
            
        end
        
        function absolutePermeability =  AbsolutePermeabilityCalculation(obj,inletPressure)
            %AbsolutePermeability calculates the absolute permeability of
            %the network
            %   Detailed explanation goes here
            
%             absolutePermeability = obj.xDimention + inletPressure;
        end
        
        %%vtk file generation
        function vtkOutput(obj)
            vtkFileID = fopen('output.vtk','w');
            if vtkFileID == -1
                error('Cannot open file for writing.');
            end
            title = "output";
            fprintf ( vtkFileID, '# vtk DataFile Version 2.0\n' );
            fprintf ( vtkFileID, '%s\n', title );
            fprintf ( vtkFileID, 'ASCII\n' );
            fprintf ( vtkFileID, '\n' );
            fprintf ( vtkFileID, 'DATASET POLYDATA\n' );
            fprintf ( vtkFileID, 'POINTS %d double\n', obj.numberOfNodes );
            for i = 1:obj.numberOfNodes
                fprintf( vtkFileID,'%d %d %d \n', obj.Nodes{i}.x_coordinate, obj.Nodes{i}.y_coordinate, obj.Nodes{i}.z_coordinate );
            end
            
        end
    end
end
