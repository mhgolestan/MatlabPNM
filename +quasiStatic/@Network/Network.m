classdef Network < handle & quasiStatic.Fluids 
    %Network Summary of this class goes here
    %   This class contain nodes and links of the network
    
    properties
        % Construction of a network object
        name
        Nodes
        Links
        IO
        
        % Stocastic information
        xDimension_m
        yDimension_m
        zDimension_m
        
        numberOfNodes
        numberOfLinks
        numOfInletLinks
        numOfOutletLinks
        numOfIsolatedElements
        
        numOfSquareElements
        numOfCircularElements
        numOfTriangularElements
        numOfSquarePores
        numOfCircularPores
        numOfTriangularPores
        numOfSquareLinks
        numOfCircularLinks
        numOfTriangularLinks
        
        maxCoordinationNumber
        stdCoordinationNumber
        averageCoordinationNumber
        averageThroatRadius
        
        PSD
        ThSD
        ThSD_length
        
        porosity
        networkVolume_m3
        networkPoreVolume_m3
                
        % Single phase flow
        inletPressure_Pa  = 1;
        outletPressure_Pa = 0;
        calculateSinglePhasePressureDistribution = false;
        absolutePermeability_mD
        absolutePermeability_m2        
        totalFlowRate_m3PerS
        velocity_mPerS
        visualization
        
        % Two phase flow
        randSeed
        flowVisualization = false;
        recedingContactAngle
        advancingContactAngle
        typeOfPoreBodyFillingAlgorithm = '';
        calculateRelativePermeability = false;        
        capillaryNumber 
        deltaS_input = 0.1;
        NoOfPc_interval = 1;
        max_Pc_Pa
        min_Pc_Pa
        Pc_drain_max_Pa  
        wettingPhaseSaturation       
        sequence % control of filling in Imbibition
        thresholdPressure_Pa % control of thresholdPressure_Pa in Imbibition
                             
        DrainageData   
        ImbibitionData       
        DrainageData_table 
        ImbibitionData_table   
    end
    
    methods
        %% Cunstructor function
        
        function network = Network(fileName)
            %Network Construct an instance of this class 
            
            % current path
            currentFoldet = pwd;
            networkFileFullPath = strcat(currentFoldet, '/datasets/NetworkDataFiles/' , fileName);
            
            
            % Opening the files
            link_1_fileID = fopen(strcat(networkFileFullPath, '_link1.dat'));
            network.numberOfLinks = str2num(fgetl(link_1_fileID));
            link_2_fileID = fopen(strcat(networkFileFullPath, '_link2.dat'));
            
            node_2_fileID = fopen(strcat(networkFileFullPath, '_node2.dat'));
            node_1_fileID = fopen(strcat(networkFileFullPath, '_node1.dat'));
            temp = str2num(fgetl(node_1_fileID));
            network.numberOfNodes = temp(1);
            
            % Network dimension
            network.xDimension_m = temp(2);
            network.yDimension_m = temp(3);
            network.zDimension_m = temp(4);
            
            % Initializing Nodes and Links parameters
            network.Nodes = cell(network.numberOfNodes,1);
            network.Links = cell(network.numberOfLinks,1);
            
            %
            for i = 1:network.numberOfNodes
                node_1_values = str2num(fgetl(node_1_fileID));
                node_2_values = str2num(fgetl(node_2_fileID));
                network.Nodes{i} = quasiStatic.Node(node_1_values(1),... %pore index
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
            
            for i = 1:network.numberOfLinks
                link_1_values = str2num(fgetl(link_1_fileID));
                link_2_values = str2num(fgetl(link_2_fileID));
                network.Links{i} = quasiStatic.Link(link_1_values(1),... %index
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
             
            
            network.IO = quasiStatic.IO();
            
            %closing the files
            fclose(link_1_fileID); fclose(link_2_fileID);
            fclose(node_1_fileID); fclose(node_2_fileID);
        end
         
        %% Two Phase         
            
        % Primary Drainage
        primaryDrainage(network) % correct but not filling in the 
        primaryDrainage_20191207(network) 
        primaryDrainage_20191207new(network) 
        
        % Secondary Imbibition
        secondaryImbibition(network) 
        secondaryImbibition_20191207(network) 
        secondaryImbibition_20191207new(network)           
         
        %% Rewriting network Data 
        
%         networkRewriting(network)
%         networkRewriting_addProps(network)
%         networkRewritingWithImagenaryPores(network) 
         
    end
end

