classdef Network < handle & Fluids 
    
    properties
        Nodes
        Links
        xDimension
        yDimension
        zDimension
        
        numberOfNodes        
        numberOfLinks
        numOfInletLinks      
        numOfOutletLinks
        maxCoordinationNumber  
        
        Porosity
        poreVolume
        absolutePermeability
        
        totalFlowRate
        velocity
        capillaryNumber
        Pc_drain_max
        
        DrainageData
        ImbibitionData         
    end    
    methods
        %% Cunstructor function
        function obj = Network(fileName) 
            
            % Opening the files
            link_1_fileID = fopen(strcat(fileName, '_link1.dat'));
            obj.numberOfLinks = str2num(fgetl(link_1_fileID));
            link_2_fileID = fopen(strcat(fileName, '_link2.dat'));
            
            node_2_fileID = fopen(strcat(fileName, '_node2.dat'));            
            node_1_fileID = fopen(strcat(fileName, '_node1.dat'));
            temp = str2num(fgetl(node_1_fileID));
            obj.numberOfNodes = temp(1);
            
            % Network dimension
            obj.xDimension = temp(2);
            obj.yDimension = temp(3);
            obj.zDimension = temp(4);
            
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
            
        end
        %% Porosity calculation
        function calculatePorosity(obj)
            nodesVolume = 0;
            linksVolume = 0;
            obj.numOfInletLinks = 0;
            obj.numOfOutletLinks = 0; 
            
            for ii = 1:obj.numberOfNodes
                nodesVolume = nodesVolume + (obj.Nodes{ii}.volume); 
                obj.maxCoordinationNumber(ii,1) = obj.Nodes{ii}.connectionNumber;                
            end 
            obj.maxCoordinationNumber = max(obj.maxCoordinationNumber); 
            
            for ii = 1:obj.numberOfLinks 
                linksVolume = linksVolume + (obj.Links{ii}.volume);
                if obj.Links{ii}.isInlet
                    obj.numOfInletLinks = obj.numOfInletLinks + 1;
                elseif obj.Links{ii}.isOutlet
                    obj.numOfOutletLinks = obj.numOfOutletLinks+1; 
                end                
            end 
            
            obj.poreVolume = linksVolume + nodesVolume;
            obj.Porosity = obj.poreVolume / (obj.xDimension * obj.yDimension * obj.zDimension);              
        end       
        %% Pressure distribution calculation of single phase flow       
        function pressureDistribution_singlePhaseFlow (obj, inletPressure, outletPressure)
            Factor = zeros(obj.numberOfNodes, obj.numberOfNodes);
            B = zeros(obj.numberOfNodes, 1);
     
            for ii = 1:obj.numberOfLinks
                
                node1Index = obj.Links{ii}.pore1Index;
                node2Index = obj.Links{ii}.pore2Index;

                % if the link is connected to inlet (index of node 1 is -1 which does not exist) 
                if obj.Links{ii}.isInlet
                    nodeLinkSystemConductance = ((obj.Links{ii}.linkLength /...
                        obj.Links{ii}.conductance) +...
                        ((obj.Links{ii}.pore2Length / obj.Nodes{node2Index}.conductance)))^-1;
                    
                    Factor(node2Index, node2Index) = Factor(node2Index, node2Index) + nodeLinkSystemConductance;
                    B(node2Index) = nodeLinkSystemConductance * inletPressure;

                % if the link is connected to outlet (index of node 2 is 0 which does not exist)
                elseif obj.Links{ii}.isOutlet
                     nodeLinkSystemConductance = ( (obj.Links{ii}.linkLength /...
                        obj.Links{ii}.conductance) +...
                        ((obj.Links{ii}.pore1Length / obj.Nodes{node1Index}.conductance)))^-1;
                    Factor(node1Index, node1Index) = Factor(node1Index, node1Index) + nodeLinkSystemConductance;
                    B(node1Index) = nodeLinkSystemConductance * outletPressure;
                    
                %if the link is neither inlet nor outlet    
                else
                    nodeLinkSystemConductance = ((obj.Links{ii}.linkLength /...
                        obj.Links{ii}.conductance) +...
                        ((obj.Links{ii}.pore1Length / obj.Nodes{node1Index}.conductance) +...
                        (obj.Links{ii}.pore2Length / obj.Nodes{node2Index}.conductance)))^-1;   
                
                    Factor(node1Index, node1Index) = Factor(node1Index, node1Index) + nodeLinkSystemConductance;
                    Factor(node2Index, node2Index) = Factor(node2Index, node2Index) + nodeLinkSystemConductance;
                    Factor(node1Index, node2Index) = Factor(node1Index, node2Index) - nodeLinkSystemConductance;
                    Factor(node2Index, node1Index) = Factor(node2Index, node1Index) - nodeLinkSystemConductance;
                   
                end     
            end
            
            % using Preconditioned conjugate gradients method to solve the
            % pressure distribution 
            nodesPressure = pcg(Factor, B, 1e-7, 1000);
            
            %assign the pressure values to each node
            for ii = 1:obj.numberOfNodes
                if nodesPressure(ii) > inletPressure
                    obj.Nodes{ii}.waterPressure = inletPressure; 
                elseif nodesPressure(ii) < outletPressure
                    obj.Nodes{ii}.waterPressure = outletPressure; 
                else
                    obj.Nodes{ii}.waterPressure = nodesPressure(ii); 
                end
            end
            %assign pressure values to links, since the surface where
            %flowrate is calculated through might pass through the links
            for ii = 1:obj.numberOfLinks
                if obj.Links{ii}.isInlet
                    obj.Links{ii}.waterPressure =...
                        (inletPressure+obj.Nodes{obj.Links{ii}.pore2Index}.waterPressure)/2;
                elseif obj.Links{ii}.isOutlet
                    obj.Links{ii}.waterPressure =...
                        (obj.Nodes{obj.Links{ii}.pore1Index}.waterPressure+outletPressure)/2;                    
                else
                    obj.Links{ii}.waterPressure =...
                        (obj.Nodes{obj.Links{ii}.pore1Index}.waterPressure + ...
                        obj.Nodes{obj.Links{ii}.pore2Index}.waterPressure) / 2;
                end
            end
        end 
        %% Flow rate calculation for each phase in the netwrok
        function calculateFlowRate(obj, inletPressure, outletPressure)
            % Fluid : water
            
            pressureDistribution_singlePhaseFlow(obj, inletPressure,outletPressure); 
            
            FlowRate = 0;
            % calculate flow rate in Inlet_Links
            for ii = 1:obj.numberOfLinks 
                
                    node2Index = obj.Links{ii}.pore2Index;
                    
               if obj.Links{ii}.isInlet
                    
                    %calculate the conductivity of the linkNode system
                    nodeLinkSystemConductance = ((obj.Links{ii}.linkLength /...
                        obj.Links{ii}.conductance) +...
                        ((obj.Links{ii}.pore2Length / obj.Nodes{node2Index}.conductance)))^-1;
                    
                    % calculate the flow rate of the fluid
                    FlowRate = FlowRate + ...
                        abs(nodeLinkSystemConductance * ...
                        (1 - obj.Nodes{node2Index}.waterPressure));
                end
            end
            
            % calculate velocity through the network 
            obj.totalFlowRate = FlowRate;
            obj.velocity = obj.totalFlowRate/(obj.yDimension * obj.zDimension);
            
            % for quasi-static, capillaryNumber must be less than 10e-4
            obj.capillaryNumber = obj.waterViscosity * obj.velocity/ obj.sig_ow;  
        end
        %% AbsolutePermeability
        function calculateAbsolutePermeability(obj, inletPressure, outletPressure)
            %AbsolutePermeability calculates the absolute permeability of
            %the network
            calculateFlowRate(obj, inletPressure, outletPressure);
            
            % for pressure difference in the formula the corresponding
            % pressure drop between the vertical surfaces should be
            % calculated (based on Piri B1 formula)
            
            unitConvertor = 1.01325E+15; % unit conversion from m2 to miliDarcy
            obj.absolutePermeability = unitConvertor * obj.velocity * obj.xDimension * obj.waterViscosity;
        end           
        %% Conductance Calculation 2-Phase Flow
        function calculateConductance(obj, Pc, Cycle) 
            Pc = abs(Pc);
            for i = 1:obj.numberOfNodes
                if strcmp(Cycle , 'Drainage')== 1
                    [obj.Nodes{i}.waterCrossSectionArea, obj.Nodes{i}.waterConductance,...
                        obj.Nodes{i}.oilCrossSectionArea, obj.Nodes{i}.oilConductance] =...
                        obj.Nodes{i}.calculateConductance_Drainage(Pc, obj.Nodes{i}.recedingContactAngle);     
               
                else % imbibition
                    [obj.Nodes{i}.waterCrossSectionArea, obj.Nodes{i}.waterConductance,...
                        obj.Nodes{i}.oilCrossSectionArea, obj.Nodes{i}.oilConductance] =...
                        obj.Nodes{i}.calculateConductance_Imbibition(obj, Pc);                       
                end
            end
            for i = 1:obj.numberOfLinks
                if strcmp(Cycle , 'Drainage')== 1                 
                   [obj.Links{i}.waterCrossSectionArea, obj.Links{i}.waterConductance,...
                        obj.Links{i}.oilCrossSectionArea, obj.Links{i}.oilConductance] =...
                        obj.Links{i}.calculateConductance_Drainage(Pc, obj.Links{i}.recedingContactAngle);     
                else % imbibition
                    [obj.Links{i}.waterCrossSectionArea, obj.Links{i}.waterConductance,...
                        obj.Links{i}.oilCrossSectionArea, obj.Links{i}.oilConductance] =...
                        obj.Links{i}.calculateConductance_Imbibition(obj, Pc);      
                    
                end
            end            
        end
        %% Saturation Calculation
        function Sw = calculateSaturations(obj)            
            % Water Saturation Calculation
            waterVolume = 0;   
            vol = 0;
            for i = 1:obj.numberOfNodes
                if ~obj.Nodes{i}.isInlet && ~obj.Nodes{i}.isOutlet 
                    waterVolume = waterVolume + (obj.Nodes{i}.waterCrossSectionArea / obj.Nodes{i}.area *...
                        obj.Nodes{i}.volume) +...
                        obj.Nodes{i}.clayVolume;                
                    vol = vol + obj.Nodes{i}.volume;
                end
            end
            for i = 1:obj.numberOfLinks   
                if ~obj.Links{i}.isInlet && ~obj.Links{i}.isOutlet 
                     waterVolume = waterVolume+ (obj.Links{i}.waterCrossSectionArea  / obj.Links{i}.area *...
                        obj.Links{i}.volume) + obj.Links{i}.clayVolume;
                     vol = vol + obj.Links{i}.volume;
                end
            end  
            Sw = waterVolume / vol;            
        end        
        %% Pressure distribution calculation in pore_Two-Phases 
        function pressureDistribution_TwoPhases(obj, inletPressure, outletPressure) 
            
            Factor_W = zeros(obj.numberOfNodes, obj.numberOfNodes);
            B_W = zeros(obj.numberOfNodes, 1);
            Factor_O = zeros(obj.numberOfNodes, obj.numberOfNodes);
            B_O = zeros(obj.numberOfNodes, 1);
            
            % calculation of pressure distribution
            for ii = 1:obj.numberOfLinks  
                
                node1Index = obj.Links{ii}.pore1Index;
                node2Index = obj.Links{ii}.pore2Index;
                
                % if the link is connected to inlet (index of node 1 is -1 which does not exist) 
                if obj.Links{ii}.isInlet
                    
                    obj.Links{ii}.nodeLinkSystemConductance_O = ((obj.Links{ii}.linkLength /...
                        obj.Links{ii}.oilConductance) +...
                        ((obj.Links{ii}.pore2Length / obj.Nodes{node2Index}.oilConductance)))^-1;     
                    
                    Factor_O(node2Index, node2Index) = Factor_O(node2Index, node2Index) + obj.Links{ii}.nodeLinkSystemConductance_O;
                    B_O(node2Index) = obj.Links{ii}.nodeLinkSystemConductance_O * inletPressure;
                    
                    obj.Links{ii}.nodeLinkSystemConductance_W = ((obj.Links{ii}.linkLength /...
                        obj.Links{ii}.waterConductance) +...
                        ((obj.Links{ii}.pore2Length / obj.Nodes{node2Index}.waterConductance)))^-1;   
                    
                    Factor_W(node2Index, node2Index) = Factor_W(node2Index, node2Index) + obj.Links{ii}.nodeLinkSystemConductance_W;
                    B_W(node2Index) = obj.Links{ii}.nodeLinkSystemConductance_W * inletPressure;
                    
                % if the link is connected to outlet (index of node 2 is 0 which does not exist)
                elseif obj.Links{ii}.isOutlet
                    
                    obj.Links{ii}.nodeLinkSystemConductance_O = ( (obj.Links{ii}.linkLength /...
                        obj.Links{ii}.oilConductance) +...
                        ((obj.Links{ii}.pore1Length / obj.Nodes{node1Index}.oilConductance)))^-1;
                    
                    Factor_O(node1Index, node1Index) = Factor_O(node1Index, node1Index) + obj.Links{ii}.nodeLinkSystemConductance_O;
                    B_O(node1Index) = obj.Links{ii}.nodeLinkSystemConductance_O * outletPressure;  
                    
                    obj.Links{ii}.nodeLinkSystemConductance_W = ( (obj.Links{ii}.linkLength /...
                        obj.Links{ii}.waterConductance) +...
                        ((obj.Links{ii}.pore1Length / obj.Nodes{node1Index}.waterConductance)))^-1;
                    
                    Factor_W(node1Index, node1Index) = Factor_W(node1Index, node1Index) + obj.Links{ii}.nodeLinkSystemConductance_W;
                    B_W(node1Index) = obj.Links{ii}.nodeLinkSystemConductance_W * outletPressure;   
                    
                %if the link is neither inlet nor outlet    
                else
                    obj.Links{ii}.nodeLinkSystemConductance_W = ((obj.Links{ii}.linkLength /...
                        obj.Links{ii}.waterConductance) +...
                        ((obj.Links{ii}.pore1Length / obj.Nodes{node1Index}.waterConductance) +...
                        (obj.Links{ii}.pore2Length / obj.Nodes{node2Index}.waterConductance)))^-1;  
                    
                    Factor_W(node1Index, node1Index) = Factor_W(node1Index, node1Index) + obj.Links{ii}.nodeLinkSystemConductance_W;
                    Factor_W(node2Index, node2Index) = Factor_W(node2Index, node2Index) + obj.Links{ii}.nodeLinkSystemConductance_W;
                    Factor_W(node1Index, node2Index) = Factor_W(node1Index, node2Index) - obj.Links{ii}.nodeLinkSystemConductance_W;
                    Factor_W(node2Index, node1Index) = Factor_W(node2Index, node1Index) - obj.Links{ii}.nodeLinkSystemConductance_W;  
                    
                    obj.Links{ii}.nodeLinkSystemConductance_O = ((obj.Links{ii}.linkLength /...
                        obj.Links{ii}.oilConductance) +...
                        ((obj.Links{ii}.pore1Length / obj.Nodes{node1Index}.oilConductance) +...
                        (obj.Links{ii}.pore2Length / obj.Nodes{node2Index}.oilConductance)))^-1;                
                    Factor_O(node1Index, node1Index) = Factor_O(node1Index, node1Index) + obj.Links{ii}.nodeLinkSystemConductance_O;
                    Factor_O(node2Index, node2Index) = Factor_O(node2Index, node2Index) + obj.Links{ii}.nodeLinkSystemConductance_O;
                    Factor_O(node1Index, node2Index) = Factor_O(node1Index, node2Index) - obj.Links{ii}.nodeLinkSystemConductance_O;
                    Factor_O(node2Index, node1Index) = Factor_O(node2Index, node1Index) - obj.Links{ii}.nodeLinkSystemConductance_O;                   
                end     
            end
            
            % using Preconditioned conjugate gradients method to solve the
            % pressure distribution 
            nodesWaterPressure = pcg(Factor_W, B_W, 1e-7, 1000);            
            nodesOilPressure = pcg(Factor_O, B_O, 1e-7, 1000); 
            
            %assign the pressure values to each node
            for ii = 1:obj.numberOfNodes
                if nodesWaterPressure(ii)> inletPressure
                    obj.Nodes{ii}.waterPressure = inletPressure;
                elseif nodesWaterPressure(ii)< outletPressure
                    obj.Nodes{ii}.waterPressure = outletPressure;
                else
                obj.Nodes{ii}.waterPressure = nodesWaterPressure(ii);        
                end
                if nodesOilPressure(ii)> inletPressure
                    obj.Nodes{ii}.oilPressure = inletPressure;
                elseif nodesOilPressure(ii)< outletPressure
                    obj.Nodes{ii}.oilPressure = outletPressure;
                else
                obj.Nodes{ii}.oilPressure = nodesOilPressure(ii);        
                end
            end
            
            %assign pressure values to links, since the surface where
            %flowrate is calculated through might pass through the links
            for ii = 1:obj.numberOfLinks
                if obj.Links{ii}.isInlet
                    obj.Links{ii}.waterPressure =...
                        (inletPressure+obj.Nodes{obj.Links{ii}.pore2Index}.waterPressure)/2;
                    obj.Links{ii}.oilPressure =...
                        (inletPressure+obj.Nodes{obj.Links{ii}.pore2Index}.oilPressure)/2;
                elseif obj.Links{ii}.isOutlet
                    obj.Links{ii}.waterPressure =...
                        (obj.Nodes{obj.Links{ii}.pore1Index}.waterPressure+outletPressure)/2; 
                    obj.Links{ii}.oilPressure =...
                        (obj.Nodes{obj.Links{ii}.pore1Index}.oilPressure+outletPressure)/2;      
                else
                    obj.Links{ii}.waterPressure =...
                        (obj.Nodes{obj.Links{ii}.pore1Index}.waterPressure + ...
                        obj.Nodes{obj.Links{ii}.pore2Index}.waterPressure) / 2;
                    obj.Links{ii}.oilPressure =...
                        (obj.Nodes{obj.Links{ii}.pore1Index}.oilPressure + ...
                        obj.Nodes{obj.Links{ii}.pore2Index}.oilPressure) / 2;
                end
            end              
        end
        %% Relative Permeability
        function [krw, kro] = calculateRelativePermeability (obj, inletPressure)
              
            waterFlowRate = 0;   
            oilFlowRate = 0;
            
            %search through all the links
            for ii = 1:obj.numberOfLinks 
                  
                node2Index = obj.Links{ii}.pore2Index;
                
                if obj.Links{ii}.isInlet   
                     
                        % calculate the flow rate of the fluid
                        waterFlowRate = waterFlowRate + ...
                            abs(obj.Links{ii}.nodeLinkSystemConductance_W * ...
                            (inletPressure - obj.Nodes{node2Index}.waterPressure));  
                        
                        % calculate the flow rate of the fluid
                        oilFlowRate = oilFlowRate + ...
                            abs(obj.Links{ii}.nodeLinkSystemConductance_O * ...
                            (inletPressure - obj.Nodes{node2Index}.oilPressure));  
                end 
            end                
            krw = waterFlowRate/obj.totalFlowRate;
            if krw > 1
                krw = 1;
            elseif krw <0
                krw = 0;
            end
            kro = oilFlowRate * obj.oilViscosity/obj.totalFlowRate / obj.waterViscosity;
            if kro > 1
                kro = 1;
            elseif kro <0
                kro = 0;
            end
        end
        %% Relative Permeability_imb
        function [krw, kro] = calculateRelativePermeability_Imb (obj, inletPressure, LinkL, cluster_A_nums)
              
            waterFlowRate = 0;   
            oilFlowRate = 0;
            
            %search through all the links
            for ii = 1:obj.numberOfLinks 
                  
                node2Index = obj.Links{ii}.pore2Index;
                
                if obj.Links{ii}.isInlet   
                     
                        % calculate the flow rate of the fluid
                        waterFlowRate = waterFlowRate + ...
                            abs(obj.Links{ii}.nodeLinkSystemConductance_W * ...
                            (inletPressure - obj.Nodes{node2Index}.waterPressure));  
                       if any(LinkL(ii) == cluster_A_nums(:)) 
                        % calculate the flow rate of the fluid
                        oilFlowRate = oilFlowRate + ...
                            abs(obj.Links{ii}.nodeLinkSystemConductance_O * ...
                            (inletPressure - obj.Nodes{node2Index}.oilPressure)); 
                       end
                end 
            end                
            krw = waterFlowRate/obj.totalFlowRate;
            if krw > 1
                krw = 1;
            elseif krw <0
                krw = 0;
            end
            kro = oilFlowRate * obj.oilViscosity/obj.totalFlowRate / obj.waterViscosity;
            if kro > 1
                kro = 1;
            elseif kro <0
                kro = 0;
            end
        end        
        %% Primary Drainage
        function PrimaryDrainage(obj, inletPressure, outletPressure)        
             %% determining the capillary pressure level interval
             Pc_threshold = zeros(2*obj.numberOfLinks,1);  
             Pc_threshold_n = zeros(obj.numberOfLinks,1); 
             for i = 1:obj.numberOfLinks                
                 obj.Links{i}.thresholdPressure = obj.Links{i}.calculateThresholdPressurePistonLike(obj.Links{i}.recedingContactAngle);
                 Pc_threshold(i) = obj.Links{i}.thresholdPressure;
                 obj.Links{i}.occupancy = 'A';
             end
             for i = 1:obj.numberOfNodes                
                  obj.Nodes{i}.thresholdPressure = obj.Nodes{i}.calculateThresholdPressurePistonLike(obj.Nodes{i}.recedingContactAngle);
                  obj.Nodes{i}.occupancy = 'A';
             end 
             
             % Pc_interval
             max_Pc = max(Pc_threshold); 
             Pc_interval = max_Pc/20;   
              
             Pc = 0;   
             t = 1; 
             invaded = 0;
             obj.Pc_drain_max = max_Pc;
             obj.DrainageData = zeros(21,5);
             obj.DrainageData(1,:) = [1, 0, 1, 0, 0]; 
             
             %% Cycle of increasing Pressure
             while Pc <= obj.Pc_drain_max  
                           
             %% Find new inlet-Links with threshold pressure < Pc             
             for i = 1:obj.numberOfLinks                  
                  node1Index = obj.Links{i}.pore1Index;
                  node2Index = obj.Links{i}.pore2Index;
                  if obj.Links{i}.isInlet && obj.Links{i}.occupancy == 'A'
                     if Pc_threshold(i) <= Pc  
                         if obj.Nodes{node2Index}.occupancy == 'A' && obj.Nodes{node2Index}.thresholdPressure <=Pc
                         Pc_threshold_n(i,1)= Pc_threshold(i);
                         end
                     end
                  elseif obj.Links{i}.isOutlet && obj.Links{i}.occupancy == 'A'                     
                           if obj.Nodes{node1Index}.occupancy == 'B' && Pc_threshold(i) <= Pc
                               obj.Links{i}.occupancy = 'B'; 
                               invaded = invaded + 1;
                           end
                  elseif ~obj.Links{i}.isOutlet && ~obj.Links{i}.isInlet && obj.Links{i}.occupancy == 'A' && Pc_threshold(i) < Pc                      
                      if obj.Nodes{node1Index}.occupancy == 'B' 
                          if obj.Nodes{node2Index}.occupancy == 'A' && obj.Nodes{node2Index}.thresholdPressure <Pc
                              Pc_threshold_n(i,1)= Pc_threshold(i);
                          end
                      elseif obj.Nodes{node2Index}.occupancy == 'B'
                          if obj.Nodes{node1Index}.occupancy == 'A' && obj.Nodes{node1Index}.thresholdPressure <Pc
                              Pc_threshold_n(i,1)= Pc_threshold(i);
                          end
                      end                      
                 end
             end
                 
             %% Add Links which have Pc_threshold < Pc in each steps and also have oil-saturated neighbour Node 
             while min(nonzeros(Pc_threshold_n))<= Pc
                 
                 %check & sort Links based on Pc_Threshold
                 [~, ix] = sort(Pc_threshold_n(1:end), 1);
                 i = ix(obj.numberOfLinks - length(nonzeros(Pc_threshold_n))+1);
                 Pc_threshold_n(i) = 0;       
                 
                 node1Index = obj.Links{i}.pore1Index;
                 node2Index = obj.Links{i}.pore2Index;
                 
                 if obj.Links{i}.isInlet && obj.Links{i}.occupancy == 'A'&& Pc_threshold(i) <= Pc
                         obj.Links{i}.occupancy = 'B'; 
                         invaded = invaded + 1;
                         if obj.Nodes{node2Index}.occupancy == 'A' && obj.Nodes{node2Index}.thresholdPressure <=Pc
                             obj.Nodes{node2Index}.occupancy = 'B'; 
                             invaded = invaded + 1;
                             for j=1:obj.Nodes{node2Index}.connectionNumber
                                 if obj.Nodes{node2Index}.connectedLinks(j)~=i
                                     Pc_threshold_n(obj.Nodes{node2Index}.connectedLinks(j),1)= Pc_threshold(obj.Nodes{node2Index}.connectedLinks(j));
                                 end
                             end
                         end
                  elseif obj.Links{i}.isOutlet && obj.Links{i}.occupancy == 'A'                     
                           if obj.Nodes{node1Index}.occupancy == 'B' && Pc_threshold(i) <= Pc
                               obj.Links{i}.occupancy = 'B'; 
                               invaded = invaded + 1;
                           end
                  elseif ~obj.Links{i}.isOutlet && ~obj.Links{i}.isInlet && obj.Links{i}.occupancy == 'A' && Pc_threshold(i) <= Pc                      
                      if strcmp(obj.Nodes{node1Index}.geometry , 'Circle')== 1 && strcmp(obj.Nodes{node2Index}.geometry , 'Circle')== 1 
                      if obj.Nodes{node1Index}.occupancy == 'B' && obj.Nodes{node2Index}.occupancy == 'A' 
                          obj.Links{i}.occupancy = 'B';
                          invaded = invaded + 1;
                          if obj.Nodes{node2Index}.occupancy == 'A' && obj.Nodes{node2Index}.thresholdPressure <=Pc
                              obj.Nodes{node2Index}.occupancy = 'B'; 
                              invaded = invaded + 1;
                              for j=1:obj.Nodes{node2Index}.connectionNumber
                                 if obj.Nodes{node2Index}.connectedLinks(j)~=i
                                     Pc_threshold_n(obj.Nodes{node2Index}.connectedLinks(j),1)= Pc_threshold(obj.Nodes{node2Index}.connectedLinks(j));
                                 end
                             end
                          end
                      elseif obj.Nodes{node2Index}.occupancy == 'B' && obj.Nodes{node1Index}.occupancy == 'A' 
                          obj.Links{i}.occupancy = 'B';
                          invaded = invaded+1;
                          if obj.Nodes{node1Index}.occupancy == 'A' && obj.Nodes{node1Index}.thresholdPressure <=Pc
                              obj.Nodes{node1Index}.occupancy = 'B'; 
                              invaded = invaded + 1;
                              for j=1:obj.Nodes{node1Index}.connectionNumber
                                 if obj.Nodes{node1Index}.connectedLinks(j)~=i
                                     Pc_threshold_n(obj.Nodes{node1Index}.connectedLinks(j),1)= Pc_threshold(obj.Nodes{node1Index}.connectedLinks(j));
                                 end
                             end
                          end
                      end
                      else 
                      invaded = invaded + 1;
                      if obj.Nodes{node1Index}.occupancy == 'B' 
                          obj.Links{i}.occupancy = 'B';                         
                          if obj.Nodes{node2Index}.occupancy == 'A' && obj.Nodes{node2Index}.thresholdPressure <=Pc
                              obj.Nodes{node2Index}.occupancy = 'B'; 
                              invaded = invaded + 1;
                              for j=1:obj.Nodes{node2Index}.connectionNumber
                                 if obj.Nodes{node2Index}.connectedLinks(j)~=i
                                     Pc_threshold_n(obj.Nodes{node2Index}.connectedLinks(j),1)= Pc_threshold(obj.Nodes{node2Index}.connectedLinks(j));
                                 end
                             end
                          end
                      end
                      if obj.Nodes{node2Index}.occupancy == 'B' 
                          obj.Links{i}.occupancy = 'B';                         
                          if obj.Nodes{node1Index}.occupancy == 'A' && obj.Nodes{node1Index}.thresholdPressure <=Pc
                              obj.Nodes{node1Index}.occupancy = 'B'; 
                              invaded = invaded + 1;
                              for j=1:obj.Nodes{node1Index}.connectionNumber
                                 if obj.Nodes{node1Index}.connectedLinks(j)~=i
                                     Pc_threshold_n(obj.Nodes{node1Index}.connectedLinks(j),1)= Pc_threshold(obj.Nodes{node1Index}.connectedLinks(j));
                                 end
                             end
                          end
                      end
                      end
                 end
             end
             
             % Updating element saturations and conductances
             calculateConductance(obj, Pc, 'Drainage'); 
             pressureDistribution_TwoPhases(obj, inletPressure, outletPressure);
             Sw = calculateSaturations(obj); 
             
             % Relative Permeability Calculation 
             [Krw , Kro] = calculateRelativePermeability (obj, inletPressure);  
             obj.DrainageData(t,:) = [Sw, Pc, Krw, Kro, invaded]; 
             
             Pc = Pc + Pc_interval;    
             t = t + 1;   
             
             end  
             
             A = obj.DrainageData(1:t-1,:);
             xlswrite('Drainage',A);             
        end        
        %% Clustering
        function [NumberOfClusters, NodeL, LinkL,cluster_A_nums] = Clustering(obj)
            % Arguments of HoshenKopelman function            
            NodeS = zeros(obj.numberOfNodes,1);
            LinksOfNode = zeros(obj.numberOfNodes,obj.maxCoordinationNumber);
            NodeNext = zeros(obj.numberOfNodes,obj.maxCoordinationNumber);
            for i = 1:obj.numberOfNodes
                NodeS(i,1) = obj.Nodes{i}.occupancy; % nodes with oil(1),nodes with water(0)
                if ~obj.Nodes{i}.isInlet && ~obj.Nodes{i}.isOutlet
                LinksOfNode(i,1:obj.Nodes{i}.connectionNumber) = obj.Nodes{i}.connectedLinks;
                NodeNext(i,1:obj.Nodes{i}.connectionNumber) = obj.Nodes{i}.connectedNodes;
                else
                    a = 1;
                    for j = 1:obj.Nodes{i}.connectionNumber
                        if ~obj.Links{obj.Nodes{i}.connectedLinks(j)}.isInlet && ~obj.Links{obj.Nodes{i}.connectedLinks(j)}.isOutlet                                                        
                            LinksOfNode(i,a) = obj.Nodes{i}.connectedLinks(j);
                            NodeNext(i,a) = obj.Nodes{i}.connectedNodes(j);
                            a = a+1;
                        end
                    end
                end
            end  
            LinkS = zeros(obj.numberOfLinks,1);
            for i =1:obj.numberOfLinks
                if ~obj.Links{i}.isInlet && ~obj.Links{i}.isOutlet
                    LinkS(i,1) = obj.Links{i}.occupancy; % throats with oil(1), throats with water(0)
                end
            end            
            OFlag = 'B'; %oil clusters has numbers 1:NumberOfClusters %water clusters are 0
            
            % HoshenKopelman Algorithm for clustering
            [NumberOfClusters, NodeL, LinkL] = modifiedHKNonLattice(NodeS, LinkS,NodeNext, LinksOfNode, OFlag); 
            
            % Modify number of inlet & outlet Links of Clusters
            for i =1:obj.numberOfLinks
                if obj.Links{i}.isInlet 
                    if any(obj.Links{i}.oilLayerExist) || obj.Links{i}.occupancy == 'B'
                        if obj.Nodes{obj.Links{i}.pore2Index}.occupancy == 'B' || any(obj.Links{i}.oilLayerExist)
                            LinkL(i,1) = NodeL(obj.Links{i}.pore2Index);
                        end
                    end
                    
                elseif obj.Links{i}.isOutlet
                    if (obj.Links{i}.occupancy == 'B' || any(obj.Links{i}.oilLayerExist)) 
                        if obj.Nodes{obj.Links{i}.pore1Index}.occupancy == 'B' || any(obj.Links{i}.oilLayerExist)
                            LinkL(i,1) = NodeL(obj.Links{i}.pore1Index);                
                        end
                    end
                end
            end             
            
            inlet_cluster_indx = zeros(obj.numOfInletLinks,2);
            outlet_cluster_indx = zeros(obj.numOfOutletLinks,2);
            inlet = 1;
            outlet = 1;
            for i = 1:obj.numberOfLinks
                if obj.Links{i}.isInlet
                    inlet_cluster_indx(inlet,1) = obj.Links{i}.index;
                    inlet_cluster_indx(inlet,2) = LinkL(i,1);
                    inlet = inlet +1;
                elseif obj.Links{i}.isOutlet
                    outlet_cluster_indx(outlet,1) = obj.Links{i}.index;
                    outlet_cluster_indx(outlet,2) = LinkL(i,1);
                    outlet = outlet + 1;    
                end
            end                       
            
            a = 0;
            A = zeros(max(obj.numOfOutletLinks , obj.numOfInletLinks),1);
            for i = 1:length(outlet_cluster_indx)
                if outlet_cluster_indx(i,2) ~= 0
                    for j = 1:length(inlet_cluster_indx(:,2))
                        if outlet_cluster_indx(i,2) == inlet_cluster_indx(j,2)
                            if ~any(outlet_cluster_indx(i,2) == A(:,1))
                                a = a+1;
                                A(a,1) = outlet_cluster_indx(i,2);
                                break
                            end
                        end
                    end
                end
            end
            cluster_A_nums = nonzeros(A);           
            
        end        
        %% Secondary Imbibition
        function ScoendaryImbibition(obj, inletPressure, outletPressure)    
            
            %counter for invaded elements
            numOfLinks_SnapOff = 0;
            numOfLinks_PistoneLike = 0;
            numOfLinks_LayerCollapse = 0;
            numOfNodes_SnapOff = 0;
            numOfNodes_PoreBodyFilling = 0;
            numOfNodes_LayerCollapse = 0;

            %% Calculating throat Snap-Off & Pistone-Like displacement & layer collapse            
            for i = 1:obj.numberOfLinks  
                if obj.Links{i}.occupancy == 'B' % if the throat is oil filled                   
                    obj.Links{i}.ThresholdPressure_SnapOff = ...
                        obj.Links{i}.calculateThresholdPressureSnapOff (obj.Pc_drain_max); 
                    [obj.Links{i}.ThresholdPressure_PistonLike, obj.Links{i}.oilLayerExist] =...
                        obj.Links{i}.calculateThresholdPressurePistonLike_Imbibition (obj.Pc_drain_max, obj.Pc_drain_max);
                end
            end
            
            %% Calculating Pore Snap-Off & Pore-Body Filling displacement & layer collapse            
            for i = 1:obj.numberOfNodes  

                if obj.Nodes{i}.occupancy == 'B' % if the throat is oil filled
                    
                    obj.Nodes{i}.ThresholdPressure_SnapOff = ...
                        obj.Nodes{i}.calculateThresholdPressureSnapOff (obj.Pc_drain_max); 
                    [obj.Nodes{i}.ThresholdPressure_PoreBodyFilling, obj.Nodes{i}.oilLayerExist] = ...
                        obj.Nodes{i}.calculateThresholdPressurePoreBodyFilling (obj,obj.Pc_drain_max); 
                end  
            end  
            
             Pc_imb = obj.Pc_drain_max; 
             t = 1;       
             obj.ImbibitionData = zeros(100,11);
             obj.ImbibitionData(1,:) = ...
                 [obj.DrainageData(end,1),obj.Pc_drain_max,0,1,0,0,0,0,0,0,0];
             
             percList = zeros(2*obj.numberOfNodes+2*obj.numberOfLinks,4);
            
            [~, ~, ~, cluster_A_nums] = Clustering(obj);  
            Pc_min = Pc_imb;
                
            while (~isempty(cluster_A_nums) )  
                
               [~, NodeL, LinkL, cluster_A_nums] = Clustering(obj);  
             
             %% Percolation List           
                a = 1; 
                for i = 1:obj.numberOfLinks         
                    
                    node1Index = obj.Links{i}.pore1Index;
                    node2Index = obj.Links{i}.pore2Index;
                    
                    if (any(LinkL(i) == cluster_A_nums(:)) && ~any(obj.Links{i}.ThresholdPressure_LayerCollapse(1,:)))
                        
                         [obj.Links{i}.ThresholdPressure_PistonLike, obj.Links{i}.oilLayerExist] =...
                        obj.Links{i}.calculateThresholdPressurePistonLike_Imbibition (obj.Pc_drain_max, Pc_imb); 
                
                         if obj.Links{i}.isInlet            
                             
                             if any(obj.Links{i}.ThresholdPressure_PistonLike)
                                
                                percList(a,1) = i;
                                percList(a,2) = 2;
                                percList(a,3) = 2;
                                percList(a,4) = obj.Links{i}.ThresholdPressure_PistonLike ;
                                a = a + 1;
                             end
                         elseif obj.Links{i}.isOutlet
                             
                             if (obj.Nodes{node1Index}.occupancy == 'A' || ...
                                     (obj.Nodes{node1Index}.occupancy == 'B' ...
                                     && any(obj.Nodes{node1Index}.oilLayerExist))) && ...
                                     any(obj.Links{i}.ThresholdPressure_PistonLike)
                                 
                                     percList(a,1) = i;
                                     percList(a,2) = 2;
                                     percList(a,3) = 2;
                                     percList(a,4) = obj.Links{i}.ThresholdPressure_PistonLike ;
                                     a = a + 1;
                             elseif any(obj.Links{i}.ThresholdPressure_SnapOff)
                                     percList(a,1) = i;
                                     percList(a,2) = 2;
                                     percList(a,3) = 1;
                                     percList(a,4) = obj.Links{i}.ThresholdPressure_SnapOff;
                                     a = a + 1;
                             end        
                            
                         else
                             if ((obj.Nodes{node1Index}.occupancy == 'A' || ...
                                     (obj.Nodes{node1Index}.occupancy == 'B' ...
                                     && any(obj.Nodes{node1Index}.oilLayerExist))) ||...
                                     (obj.Nodes{node2Index}.occupancy == 'A' || ...
                                     (obj.Nodes{node2Index}.occupancy == 'B' ...
                                     && any(obj.Nodes{node2Index}.oilLayerExist))))  && ...
                                     any(obj.Links{i}.ThresholdPressure_PistonLike)
                                     
                                     percList(a,1) = i;
                                     percList(a,2) = 2;
                                     percList(a,3) = 2;
                                     percList(a,4) = obj.Links{i}.ThresholdPressure_PistonLike ;
                                     a = a + 1;
                             elseif any(obj.Links{i}.ThresholdPressure_SnapOff)
                                 percList(a,1) = i;
                                 percList(a,2) = 2;
                                 percList(a,3) = 1;
                                 percList(a,4) = obj.Links{i}.ThresholdPressure_SnapOff;
                                 a = a + 1;
                             end
                         end
                    end
                end
                for i = 1:obj.numberOfNodes
                    
                    if ((any(NodeL(i) == cluster_A_nums(:)) && ~any(obj.Nodes{i}.ThresholdPressure_LayerCollapse(:,1))))                            
                        
                        filledThroats = 0;
                        for j = 1:obj.Nodes{i}.connectionNumber                            
                            if obj.Links{obj.Nodes{i}.connectedLinks(j)}.occupancy == 'A' || ...
                                    ((any(LinkL(obj.Nodes{i}.connectedLinks(j)) == cluster_A_nums(:))) &&...
                                    any(obj.Links{obj.Nodes{i}.connectedLinks(j)}.ThresholdPressure_LayerCollapse(:,1))) 
                                
                                filledThroats = filledThroats + 1;
                            end
                        end
                            [obj.Nodes{i}.ThresholdPressure_PoreBodyFilling, obj.Nodes{i}.oilLayerExist] = ...
                                obj.Nodes{i}.calculateThresholdPressurePoreBodyFilling (obj, Pc_imb);                    
                        
                        if filledThroats ~= 0 && any(obj.Nodes{i}.ThresholdPressure_PoreBodyFilling)
                                percList(a,1) = i;
                                percList(a,2) = 1;
                                percList(a,3) = 2;
                                percList(a,4) = obj.Nodes{i}.ThresholdPressure_PoreBodyFilling; % pore body filling threshold pressure
                                a = a + 1;
                        elseif any(obj.Nodes{i}.ThresholdPressure_SnapOff)
                            percList(a,1) = i;
                            percList(a,2) = 1;
                            percList(a,3) = 1;
                            percList(a,4) = obj.Nodes{i}.ThresholdPressure_SnapOff; % snap off threshold pressure
                            a = a + 1;
                        end
                        
                    end
                end
                
                percList = sortrows(percList,-4);
                if Pc_imb > percList(1,4)
                    Pc_imb = percList(1,4);
                end
                t = t+1; 
                
                %% Percolation Section                
                while  (~isempty(cluster_A_nums))
                    
                    % Descending sorting of threshold pressures
                    percList = sortrows(percList,-4);                      
                    new = 0;         
                    
                    if percList(1,4) >= Pc_imb
                        
                        %% if the first element is a throat
                        if percList(1,2) == 2 
                            
                            linkIndex = percList(1,1);
                            node1Index = obj.Links{linkIndex}.pore1Index;
                            node2Index = obj.Links{linkIndex}.pore2Index;
                            
                            if any(LinkL(linkIndex) == cluster_A_nums(:))                           
                                
                                if percList(1,3) == 2                                                 
                                    
                                    if obj.Links{linkIndex}.isInlet 
                                         
                                        if ~isnan(obj.Links{linkIndex}.oilLayerExist) % If layer formation is possible
                                            
                                            obj.Links{linkIndex}.occupancy = 'B'; % make the throat oil type                                   
                                            
                                            % calculating Pc collapse of the layers
                                            obj.Links{linkIndex}.ThresholdPressure_LayerCollapse(1,:) =...
                                                obj.Links{linkIndex}.calculateThresholdPressureLayerCollapse (obj.Pc_drain_max, Pc_imb);
                                            obj.Links{linkIndex}.oilLayerExist =1;
                                        else
                                            obj.Links{linkIndex}.occupancy = 'A';  
                                        end
                                         
                                        numOfLinks_PistoneLike = numOfLinks_PistoneLike + 1;
                                        
                                            if percList(1,4) < Pc_min
                                                Pc_min = percList(1,4);
                                            end
                                        eliminateThroatIndex = find(percList(:,1) == linkIndex & percList(:,2) == 2 & percList(:,3) == 1);
                                        percList(eliminateThroatIndex,:) = 0; 
                                        
                                        eliminatePoreIndex2 = find(percList(:,1) == node2Index & percList(:,2) == 1 & percList(:,3) == 2);
                                        percList(eliminatePoreIndex2,:) = 0; 
                                        
                                        if ~any(obj.Nodes{node2Index}.oilLayerExist) && ... % no layer exist in the pore
                                                (any(NodeL(node2Index) == cluster_A_nums(:)))
                                            
                                            % Updating pore body filling of the pore
                                            [obj.Nodes{node2Index}.ThresholdPressure_PoreBodyFilling, obj.Nodes{node2Index}.oilLayerExist] = ...
                                                obj.Nodes{node2Index}.calculateThresholdPressurePoreBodyFilling (obj,Pc_imb);
                                            if any(obj.Nodes{node2Index}.ThresholdPressure_PoreBodyFilling) 
                                                
                                                new = new+1;
                                                percList(end-new,:) = [node2Index, 1, 2, obj.Nodes{node2Index}.ThresholdPressure_PoreBodyFilling];
                                            end
                                        end
                                        
                                    elseif obj.Links{linkIndex}.isOutlet
                                        
                                        if (obj.Nodes{node1Index}.occupancy == 'A' || ...
                                                (obj.Nodes{node1Index}.occupancy == 'B' && any(obj.Nodes{node1Index}.oilLayerExist))) 
                                            
                                            if ~isnan(obj.Links{linkIndex}.oilLayerExist) % If layer formation is possible
                                                
                                                obj.Links{linkIndex}.occupancy = 'B'; % make the throat oil type                                   
                                                
                                                % calculating Pc collapse of the layers
                                                obj.Links{linkIndex}.ThresholdPressure_LayerCollapse(1,:) =...
                                                    obj.Links{linkIndex}.calculateThresholdPressureLayerCollapse (obj.Pc_drain_max, Pc_imb);
                                                obj.Links{linkIndex}.oilLayerExist =1;
                                            else
                                                obj.Links{linkIndex}.occupancy = 'A';  
                                            end
                                             
                                            numOfLinks_PistoneLike = numOfLinks_PistoneLike + 1;
               
                                            if percList(1,4) < Pc_min
                                                Pc_min = percList(1,4);
                                            end                             
                                            eliminateThroatIndex = find(percList(:,1) == linkIndex & percList(:,2) == 2 & percList(:,3) == 1);
                                            percList(eliminateThroatIndex,:) = 0;
                                            eliminatePoreIndex1 = find(percList(:,1) == node1Index & percList(:,2) == 1 & percList(:,3) == 2);
                                            percList(eliminatePoreIndex1,:) = 0;
                                            
                                            if ~any(obj.Nodes{node1Index}.oilLayerExist) && ... % no layer exist in the pore
                                                    (any(NodeL(node1Index) == cluster_A_nums(:)))
                                                
                                                % Updating pore body filling of the pore
                                                [obj.Nodes{node1Index}.ThresholdPressure_PoreBodyFilling, obj.Nodes{node1Index}.oilLayerExist] = ...
                                                    obj.Nodes{node1Index}.calculateThresholdPressurePoreBodyFilling(obj,Pc_imb);
                                                                                                
                                                if any(obj.Nodes{node1Index}.ThresholdPressure_PoreBodyFilling) 
                                                    new = new+1;
                                                    percList(end-new,:) = [node1Index, 1, 2, obj.Nodes{node1Index}.ThresholdPressure_PoreBodyFilling];  
                                                end
                                            end
                                        end
                                        
                                    elseif ~obj.Links{linkIndex}.isOutlet && ~obj.Links{linkIndex}.isInlet
                                        
                                        if ((obj.Nodes{node1Index}.occupancy == 'A' || ...
                                                (obj.Nodes{node1Index}.occupancy == 'B' ...
                                                && any(obj.Nodes{node1Index}.oilLayerExist))) ||...
                                                (obj.Nodes{node2Index}.occupancy == 'A' || ...
                                                (obj.Nodes{node2Index}.occupancy == 'B' ...
                                                && any(obj.Nodes{node2Index}.oilLayerExist))))
                                            
                                            if ~isnan(obj.Links{linkIndex}.oilLayerExist) % If layer formation is possible
                                                
                                                obj.Links{linkIndex}.occupancy = 'B'; % make the throat oil type 
                                                % calculating Pc collapse of the layers
                                                obj.Links{linkIndex}.ThresholdPressure_LayerCollapse(1,:) =...
                                                    obj.Links{linkIndex}.calculateThresholdPressureLayerCollapse (obj.Pc_drain_max, Pc_imb);
                                                obj.Links{linkIndex}.oilLayerExist =1;
                                            else
                                                obj.Links{linkIndex}.occupancy = 'A'; 
                                            end 
                                            
                                            numOfLinks_PistoneLike = numOfLinks_PistoneLike + 1;
               
                                            if percList(1,4) < Pc_min
                                                Pc_min = percList(1,4);
                                            end                             
                                            eliminateThroatIndex = find(percList(:,1) == linkIndex & percList(:,2) == 2 & percList(:,3) == 1);
                                            percList(eliminateThroatIndex,:) = 0;
                                            eliminatePoreIndex1 = find(percList(:,1) == node1Index & percList(:,2) == 1 & percList(:,3) == 2);
                                            percList(eliminatePoreIndex1,:) = 0;
                                            eliminatePoreIndex2 = find(percList(:,1) == node2Index & percList(:,2) == 1 & percList(:,3) == 2);
                                            
                                            percList(eliminatePoreIndex2,:) = 0;
                                            
                                            if ~any(obj.Nodes{node1Index}.oilLayerExist) && ... % no layer exist in the pore
                                                    (any(NodeL(node1Index) == cluster_A_nums(:)))
                                                
                                                % Updating pore body filling of the pore
                                                [obj.Nodes{node1Index}.ThresholdPressure_PoreBodyFilling, obj.Nodes{node1Index}.oilLayerExist] = ...
                                                    obj.Nodes{node1Index}.calculateThresholdPressurePoreBodyFilling(obj,Pc_imb);
                                                
                                                if any(obj.Nodes{node1Index}.ThresholdPressure_PoreBodyFilling)
                                                    
                                                    new = new+1;
                                                    percList(end-new,:) = [node1Index, 1, 2, obj.Nodes{node1Index}.ThresholdPressure_PoreBodyFilling];                                    
                                                end
                                            end
                                            
                                            if ~any(obj.Nodes{node2Index}.oilLayerExist) && ... % no layer exist in the pore
                                                    (any(NodeL(node2Index) == cluster_A_nums(:))) 
                                                
                                                % Updating pore body filling of the pore
                                                [obj.Nodes{node2Index}.ThresholdPressure_PoreBodyFilling, obj.Nodes{node2Index}.oilLayerExist] = ...
                                                    obj.Nodes{node2Index}.calculateThresholdPressurePoreBodyFilling(obj,Pc_imb);
                                                
                                                if any(obj.Nodes{node2Index}.ThresholdPressure_PoreBodyFilling) 
                                                    
                                                    new = new+1;
                                                    percList(end-new,:) = [node2Index, 1, 2, obj.Nodes{node2Index}.ThresholdPressure_PoreBodyFilling];
                                                end
                                            end
                                        end
                                    end
                                    
                                elseif percList(1,3)==1
                                    
                                    if ~isnan(obj.Links{linkIndex}.oilLayerExist) % If layer formation is possible
                                        
                                        obj.Links{linkIndex}.occupancy = 'B'; % make the throat oil type                                   
                                        
                                        % calculating Pc collapse of the layers
                                        obj.Links{linkIndex}.ThresholdPressure_LayerCollapse(1,:) =...
                                            obj.Links{linkIndex}.calculateThresholdPressureLayerCollapse (obj.Pc_drain_max, Pc_imb);
                                        obj.Links{linkIndex}.oilLayerExist =1;
                                    else
                                        obj.Links{linkIndex}.occupancy = 'A';   
                                    end
                                     
                                    numOfLinks_SnapOff = numOfLinks_SnapOff + 1;
               
                                        if percList(1,4) < Pc_min
                                            Pc_min = percList(1,4);
                                        end                     
                                    eliminateThroatIndex = find(percList(:,1) == linkIndex & percList(:,2) == 2 & percList(:,3) == 2);
                                    percList(eliminateThroatIndex,:) = 0; 
                                    
                                    if obj.Links{linkIndex}.isInlet                                    
                                        
                                        eliminatePoreIndex2 = find(percList(:,1) == node2Index & percList(:,2) == 1 & percList(:,3) == 1);
                                        percList(eliminatePoreIndex2,:) = 0; 
                                                                            
                                        eliminatePoreIndex2 = find(percList(:,1) == node2Index & percList(:,2) == 1 & percList(:,3) == 2);
                                        percList(eliminatePoreIndex2,:) = 0; 
                                        
                                        if ~any(obj.Nodes{node2Index}.oilLayerExist) && ... % no layer exist in the pore
                                                (any(NodeL(node2Index) == cluster_A_nums(:)))
                                            
                                            % Updating pore body filling of the pore
                                            [obj.Nodes{node2Index}.ThresholdPressure_PoreBodyFilling, obj.Nodes{node2Index}.oilLayerExist] = ...
                                                obj.Nodes{node2Index}.calculateThresholdPressurePoreBodyFilling(obj,Pc_imb);
                                                                                                                                
                                            if any(obj.Nodes{node2Index}.ThresholdPressure_PoreBodyFilling)
                                                
                                                new = new+1;
                                                percList(end-new,:) = [node2Index, 1, 2, obj.Nodes{node2Index}.ThresholdPressure_PoreBodyFilling];
                                                
                                            end
                                        end
                                        
                                    elseif obj.Links{linkIndex}.isOutlet
                                        
                                        eliminatePoreIndex1 = find(percList(:,1) == node1Index & percList(:,2) == 1 & percList(:,3) == 1);
                                        percList(eliminatePoreIndex1,:) = 0;                   
                                        eliminatePoreIndex1 = find(percList(:,1) == node1Index & percList(:,2) == 1 & percList(:,3) == 2);
                                        percList(eliminatePoreIndex1,:) = 0;
                                        
                                        
                                        if ~any(obj.Nodes{node1Index}.oilLayerExist) && ... % no layer exist in the pore
                                                (any(NodeL(node1Index) == cluster_A_nums(:))) 
                                            
                                            % Updating pore body filling of the pore
                                            [obj.Nodes{node1Index}.ThresholdPressure_PoreBodyFilling, obj.Nodes{node1Index}.oilLayerExist] = ...
                                                obj.Nodes{node1Index}.calculateThresholdPressurePoreBodyFilling(obj,Pc_imb);
                                            
                                            if any(obj.Nodes{node1Index}.ThresholdPressure_PoreBodyFilling)                                                 
                                                
                                                new = new+1;
                                                percList(end-new,:) = [node1Index, 1, 2, obj.Nodes{node1Index}.ThresholdPressure_PoreBodyFilling];  
                                            end
                                        end
                                        
                                    elseif ~obj.Links{linkIndex}.isOutlet && ~obj.Links{linkIndex}.isInlet
                                        
                                        eliminatePoreIndex1 = find(percList(:,1) == node1Index & percList(:,2) == 1 & percList(:,3) == 1);
                                        percList(eliminatePoreIndex1,:) = 0;                   
                                        eliminatePoreIndex1 = find(percList(:,1) == node2Index & percList(:,2) == 1 & percList(:,3) == 1);
                                        percList(eliminatePoreIndex1,:) = 0;   
                                        eliminatePoreIndex1 = find(percList(:,1) == node1Index & percList(:,2) == 1 & percList(:,3) == 2);
                                        percList(eliminatePoreIndex1,:) = 0;    
                                        eliminatePoreIndex1 = find(percList(:,1) == node2Index & percList(:,2) == 1 & percList(:,3) == 2);
                                        percList(eliminatePoreIndex1,:) = 0; 
                                        
                                        if ~any(obj.Nodes{node1Index}.oilLayerExist) && ... % no layer exist in the pore
                                                (any(NodeL(node1Index) == cluster_A_nums(:)))
                                                                                    
                                            % Updating pore body filling of the pore
                                            [obj.Nodes{node1Index}.ThresholdPressure_PoreBodyFilling, obj.Nodes{node1Index}.oilLayerExist] = ...
                                                obj.Nodes{node1Index}.calculateThresholdPressurePoreBodyFilling(obj,Pc_imb);
                                                                                    
                                            if any(obj.Nodes{node1Index}.ThresholdPressure_PoreBodyFilling)                                                                                         
                                                new = new+1;                                          
                                                percList(end-new,:) = [node1Index, 1, 2, obj.Nodes{node1Index}.ThresholdPressure_PoreBodyFilling];                                    
                                            end
                                        end
                                        
                                        if ~any(obj.Nodes{node2Index}.oilLayerExist) && ... % no layer exist in the pore
                                                (any(NodeL(node2Index) == cluster_A_nums(:))) 
                                            
                                            % Updating pore body filling of the pore
                                            [obj.Nodes{node2Index}.ThresholdPressure_PoreBodyFilling, obj.Nodes{node2Index}.oilLayerExist] = ...
                                                obj.Nodes{node2Index}.calculateThresholdPressurePoreBodyFilling(obj,Pc_imb);
                                            
                                            if any(obj.Nodes{node2Index}.ThresholdPressure_PoreBodyFilling) 
                                                
                                                new = new+1;
                                                percList(end-new,:) = [node2Index, 1, 2, obj.Nodes{node2Index}.ThresholdPressure_PoreBodyFilling];
                                            end
                                        end
                                    end
                                end
                            end
                            
                            %% if the first element is a pore
                        elseif percList(1,2) == 1 
                            
                            nodeIndex = percList(1,1);
                            
                            if any(NodeL(nodeIndex) == cluster_A_nums(:)) 
                                
                                if percList(1,3) == 2  
                                    
                                    if ~isnan(obj.Nodes{nodeIndex}.oilLayerExist) % If layer formation is impossible
                                                                                
                                        obj.Nodes{nodeIndex}.occupancy = 'B'; % make the pore oil type                               
                                        
                                        % calculating Pc collapse of the layers
                                        obj.Nodes{percList(1,1)}.ThresholdPressure_LayerCollapse(1,:) =...
                                            obj.Nodes{percList(1,1)}.calculateThresholdPressureLayerCollapse (obj.Pc_drain_max, Pc_imb);
                                        obj.Nodes{percList(1,1)}.oilLayerExist =1;                                    
                                    else % if no layer will not form
                                        
                                        obj.Nodes{nodeIndex}.occupancy = 'A'; % make the pore water type   
                                        numOfNodes_PoreBodyFilling = numOfNodes_PoreBodyFilling + 1;  
                                        
                                        if percList(1,4) < Pc_min
                                            Pc_min = percList(1,4);
                                        end
                                    end                                    
                                    
                                    eliminatedPoreIndex = find(percList(:,1) == nodeIndex & percList(:,2) == 1 & percList(:,3) == 1);
                                    percList(eliminatedPoreIndex,:) = 0; 
                                    
                                    for ii = 1:obj.Nodes{nodeIndex}.connectionNumber
                                                                                
                                        eliminatedthroat = find(percList(:,1) == obj.Nodes{nodeIndex}.connectedLinks(ii) &...
                                            percList(:,2) == 2 & percList(:,3) == 2);
                                        
                                        percList(eliminatedthroat,:) = 0;        
                                        
                                        if (any(obj.Links{obj.Nodes{nodeIndex}.connectedLinks(ii)}.ThresholdPressure_PistonLike)) &&...
                                                ~any(obj.Links{obj.Nodes{nodeIndex}.connectedLinks(ii)}.ThresholdPressure_LayerCollapse(1,:)) && ...
                                                (any(LinkL(obj.Links{obj.Nodes{nodeIndex}.connectedLinks(ii)}.index) == cluster_A_nums(:)))
                                            
                                            new = new +1;
                                            percList(end-new,:) = [obj.Nodes{nodeIndex}.connectedLinks(ii), 2 ,2 ,...
                                                obj.Links{obj.Nodes{nodeIndex}.connectedLinks(ii)}.ThresholdPressure_PistonLike];
                                        end
                                    end
                                elseif percList(1,3) == 1
                                    
                                    obj.Nodes{nodeIndex}.occupancy = 'A';
  
                                    obj.Nodes{nodeIndex}.oilLayerExist = nan;
                                                    
                                    numOfNodes_SnapOff = numOfNodes_SnapOff + 1;               
                                    
                                    if percList(1,4) < Pc_min
                                        Pc_min = percList(1,4);
                                    end
                                    eliminatedPoreIndex = find(percList(:,1) == nodeIndex & percList(:,2) == 1 & percList(:,3) == 2);
                                    percList(eliminatedPoreIndex,:) = 0; 
                                                                                                                                            
                                    for ii = 1:obj.Nodes{nodeIndex}.connectionNumber                                  
                                        
                                        eliminatedthroat = find(percList(:,1) == obj.Nodes{nodeIndex}.connectedLinks(ii) &...
                                            percList(:,2) == 2 & percList(:,3) == 1);
                                        percList(eliminatedthroat,:) = 0;   
                                        
                                        obj.Links{obj.Nodes{nodeIndex}.connectedLinks(ii)}.ThresholdPressure_SnapOff = nan; 
                                        eliminatedthroat = find(percList(:,1) == obj.Nodes{nodeIndex}.connectedLinks(ii) &...
                                            percList(:,2) == 2 & percList(:,3) == 2);
                                        percList(eliminatedthroat,:) = 0;
                                        
                                        if (any(obj.Links{obj.Nodes{nodeIndex}.connectedLinks(ii)}.ThresholdPressure_PistonLike)) &&...
                                                ~any(obj.Links{obj.Nodes{nodeIndex}.connectedLinks(ii)}.ThresholdPressure_LayerCollapse(1,:)) && ...
                                                (any(LinkL(obj.Nodes{nodeIndex}.connectedLinks(ii)) == cluster_A_nums(:))) 
                                            new = new +1;
                                            percList(end-new,:) = [obj.Nodes{nodeIndex}.connectedLinks(ii), 2 ,2 ,...
                                                obj.Links{obj.Nodes{nodeIndex}.connectedLinks(ii)}.ThresholdPressure_PistonLike];
                                        end
                                    end
                                end
                            end
                        end
                        
                        percList(1,:)=0;
                        [~, NodeL, LinkL, cluster_A_nums] = Clustering(obj);    
                    else
                        break
                    end
                end
                
                if Pc_imb < 0
                    %% Updating Pc collapse of the layers
                    for ii = 1:obj.numberOfNodes

                        if ~isnan(obj.Nodes{ii}.oilLayerExist) && any(obj.Nodes{ii}.ThresholdPressure_LayerCollapse(1,:))... 
                                && (any(NodeL(ii) == cluster_A_nums(:)) )

                            % Updating Pc of layer collapse
                            % Cheking layer collapse
                            for jj = 1:4
                                if ~isnan(obj.Nodes{ii}.ThresholdPressure_LayerCollapse(1,j)) && ...
                                        obj.Nodes{ii}.ThresholdPressure_LayerCollapse(1,j) > Pc_imb

                                    obj.Nodes{ii}.ThresholdPressure_LayerCollapse(1,j) = nan;
 
                                    numOfNodes_LayerCollapse = numOfNodes_LayerCollapse + 1; 
                                end
                            end

                            if ~any(obj.Nodes{ii}.ThresholdPressure_LayerCollapse(1,:))

                                obj.Nodes{ii}.occupancy = 'A';
                                obj.Nodes{ii}.oilLayerExist = nan;
                            end
                        end
                    end
                    for ii = 1:obj.numberOfLinks

                        if ~isnan(obj.Links{ii}.oilLayerExist) && any(obj.Links{ii}.ThresholdPressure_LayerCollapse(1,:))...
                                && (any(LinkL(ii) == cluster_A_nums(:)))

                            % Updating Pc of layer collapse        
                            % Cheking layer collapse
                            for jj = 1:4

                                if ~isnan(obj.Links{ii}.ThresholdPressure_LayerCollapse(1,j)) && ...
                                        obj.Links{ii}.ThresholdPressure_LayerCollapse(1,j) > Pc_imb

                                    obj.Links{ii}.ThresholdPressure_LayerCollapse(1,j) = nan;
 
                                    numOfLinks_LayerCollapse = numOfLinks_LayerCollapse + 1;
                                end
                            end
                            if ~any(obj.Links{ii}.ThresholdPressure_LayerCollapse(1,:))

                                obj.Links{ii}.occupancy = 'A';
                                obj.Links{ii}.oilLayerExist = nan;
                            end
                        end
                    end
                end                   
                
                invaded = numOfLinks_SnapOff + numOfLinks_PistoneLike + ...
                    numOfNodes_SnapOff + numOfNodes_PoreBodyFilling + numOfNodes_LayerCollapse;
                
                %% Updating saturations and conductances 
                calculateConductance(obj, Pc_min, 'Imbibition');                  
                Sw_imb = calculateSaturations(obj);   
                pressureDistribution_TwoPhases(obj, inletPressure, outletPressure); 
                [Krw_imb, Kro_imb] = calculateRelativePermeability_Imb (obj, inletPressure, LinkL, cluster_A_nums);  
                obj.ImbibitionData(t,:) = ...
                    [Sw_imb,Pc_min,Krw_imb, Kro_imb,invaded, ...
                    numOfLinks_SnapOff,numOfLinks_PistoneLike, ...
                    numOfLinks_LayerCollapse,numOfNodes_SnapOff, ...
                    numOfNodes_PoreBodyFilling,numOfNodes_LayerCollapse];
                
                Pc_imb = Pc_imb - 1000;  
                [~, ~, ~, cluster_A_nums] = Clustering(obj);  
            end
            
             B = obj.ImbibitionData(1:t,:);
             xlswrite('Imbibition',B);
        end      
        %% vtk file generation
        function vtkOutput(obj)
            vtkFileID = fopen('output.vtk','w');
            if vtkFileID == -1
                error('Cannot open file for writing.');
            end
            title = 'output';
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

