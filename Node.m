classdef Node < Element 
    
    properties
        x_coordinate
        y_coordinate
        z_coordinate
        connectionNumber
        connectedNodes
        connectedLinks
        ThresholdPressure_PoreBodyFilling
        
        adsorbedConcentration_SolidFluid = 0;
        adsorbedConcentration_FluidFluid = 0;

    end
    
    methods
        function obj = Node(index,...
                            x_coordinate,...
                            y_coordinate,...
                            z_coordinate,...
                            connectionNumber,...
                            connectionData,...
                            volume,...
                            radius,...
                            shapeFactor,...
                            clayVolume)
            %UNTITLED Construct an instance of this class
            %   Detailed explanation goes here
            obj.index = index;
            obj.x_coordinate = x_coordinate;
            obj.y_coordinate = y_coordinate;
            obj.z_coordinate = z_coordinate;
            obj.connectionNumber = connectionNumber;  
            obj.connectedNodes = connectionData(1:connectionNumber);
            if connectionData(connectionNumber + 1) == 1
                obj.isInlet = true;
            else
                obj.isInlet = false;
            end
            if connectionData(connectionNumber + 2) == 1
                obj.isOutlet = true;
            else
                obj.isOutlet = false;
            end
            obj.connectedLinks = connectionData(connectionNumber + 3: end);
            obj.volume = volume;
            obj.radius = radius;
            obj.shapeFactor = shapeFactor;
            obj.clayVolume = clayVolume;
            water_viscosity = 0.001;
%             sig_ow = 20e-3; % N/m
            
            
            % Geometry and conductance specification of the elements is
            % based of : Patzek, T. W., & Silin, D. B. (2001). Shape factor and hydraulic conductance in noncircular capillaries: I. One-phase creeping flow. Journal of Colloid and Interface Science. https://doi.org/10.1006/jcis.2000.7413
            % For ducts with square cross-sections, all four half-angles are equal to /4? and G = 1/16 . Circular ducts have no corners and G =1/ 4? . For simplicity, all ducts with shape factors between those of equilateral triangle and square can be mapped onto squares, and those with shape factors above 1/16 onto circles.
            % we'd better to insert star shapes later
            if obj.shapeFactor > 0 && obj.shapeFactor <= sqrt(3) / 36
                obj.geometry = 'Triangle';
                betha2_min         = atan((2 / sqrt(3)) * cos((acos(-12 * sqrt(3) * obj.shapeFactor)) / 3 + (4 * pi / 3)));
                betha2_max         = atan((2 / sqrt(3)) * cos((acos(-12 * sqrt(3) * obj.shapeFactor)) / 3 ));
                obj.halfAngle2     = betha2_min + rand * (betha2_max - betha2_min);
                obj.halfAngle1 = -0.5 * obj.halfAngle2 + 0.5 * asin((tan(obj.halfAngle2) + 4 * obj.shapeFactor) * sin(obj.halfAngle2) / (tan(obj.halfAngle2) - 4 * obj.shapeFactor));
                obj.halfAngle3 = pi / 2 - obj.halfAngle1 - obj.halfAngle2;
                obj.halfAngle4 = nan;
                obj.area = obj.radius^2/4/obj.shapeFactor;                
                obj.conductance = 3 * obj.area^2 * obj.shapeFactor /water_viscosity / 5;
            elseif obj.shapeFactor > sqrt(3) / 36 && obj.shapeFactor <= 1 / 16
                obj.geometry = 'Square';
                obj.halfAngle1 = pi / 4;
                obj.halfAngle2 = pi / 4;
                obj.halfAngle3 = pi / 4;
                obj.halfAngle4 = pi / 4;
                obj.area = 4*obj.radius^2;                
                obj.conductance = 0.5623 * obj.area^2 * obj.shapeFactor /water_viscosity;
            elseif obj.shapeFactor > 1 / 16
                obj.geometry = 'Circle';
                obj.halfAngle1 = nan;
                obj.halfAngle2 = nan;
                obj.halfAngle3 = nan;
                obj.halfAngle4 = nan;
                obj.area = pi*obj.radius^2;                
                obj.conductance = 0.5 * obj.area^2 * obj.shapeFactor /water_viscosity;
            end   
        end
        %% PoreBodyFilling 
        function [ThresholdPressure_PoreBodyFilling, oilLayerExist] = calculateThresholdPressurePoreBodyFilling_Patzek (obj,network, Pc) 
         % Based on Patzek: eqs 42-49
         oilLayerExist = nan;
         W = [0;0.72;0.45;1.2;1.5;5];
         attachedThroats = obj.connectedLinks;
         oilFilledAttachedThroats = zeros(obj.connectionNumber,1);
         a = 0;
         for i = 1:obj.connectionNumber
             if network.Links{attachedThroats(i)}.occupancy == 'B'
                 a = a+1;
                 oilFilledAttachedThroats(a,1) = attachedThroats(i);
             end
         end
         oilFilledAttachedThroats = nonzeros(oilFilledAttachedThroats);
         z = length(oilFilledAttachedThroats); % number of oil filled attached throats         
         if z == 0
             ThresholdPressure_PoreBodyFilling = nan;
         elseif z == 1
             [ThresholdPressure_PoreBodyFilling,oilLayerExist] =...
                 calculateThresholdPressurePistonLike_Imbibition(obj, network.Pc_drain_max, Pc);
         else
            if z > 5
                w = W(6);
            else
                w = W(z);
            end             
             nominator = 0;
             denominator = 0;
             sumOfThroatRadius = 0;
             for ii = 1:z
                 randNumber = rand;
                 sumOfThroatRadius = sumOfThroatRadius + network.Links{oilFilledAttachedThroats(ii)}.radius;
                 nominator = nominator + randNumber * sumOfThroatRadius;
                 denominator = denominator + randNumber;
             end
             R_ave = (obj.radius + w * nominator / denominator)/cos(obj.advancingContactAngle);
             ThresholdPressure_PoreBodyFilling = 2*obj.sig_ow/R_ave; 
         end        
        end
        function [ThresholdPressure_PoreBodyFilling, oilLayerExist] = calculateThresholdPressurePoreBodyFilling_Blunt1 (obj,network, Pc) 
         % Based on Blunt1
         oilLayerExist = nan;
         W = [0;2.5;5;20;100];
         attachedThroats = obj.connectedLinks;
         oilFilledAttachedThroats = zeros(obj.connectionNumber,1);
         a = 0;
         for i = 1:obj.connectionNumber
             if network.Links{attachedThroats(i)}.occupancy == 'B'
                 a = a+1;
                 oilFilledAttachedThroats(a,1) = attachedThroats(i);
             end
         end
         oilFilledAttachedThroats = nonzeros(oilFilledAttachedThroats);
         z = length(oilFilledAttachedThroats); % number of oil filled attached throats         
         if z == 0
             ThresholdPressure_PoreBodyFilling = nan;
         elseif z == 1
             [ThresholdPressure_PoreBodyFilling,oilLayerExist] =...
                 calculateThresholdPressurePistonLike_Imbibition(obj, network.Pc_drain_max, Pc);
         else
             if z > 5
                 w = W(5);
             else
                 w = W(z);
             end
             nominator = 0;
             
             for ii = 1:z
                  
                 randNumber = rand;
                 nominator = nominator + randNumber * w;
             end
             ThresholdPressure_PoreBodyFilling = 2*obj.sig_ow * cos(obj.advancingContactAngle)/(obj.radius + nominator); 
         end        
        end
        function [ThresholdPressure_PoreBodyFilling, oilLayerExist] = calculateThresholdPressurePoreBodyFilling (obj,network, Pc) 
         % Based on Blunt2
         oilLayerExist = nan;
         W = 15000;
         attachedThroats = obj.connectedLinks;
         oilFilledAttachedThroats = zeros(obj.connectionNumber,1);
         a = 0;
         for i = 1:obj.connectionNumber
             if network.Links{attachedThroats(i)}.occupancy == 'B'
                 a = a+1;
                 oilFilledAttachedThroats(a,1) = attachedThroats(i);
             end
         end
         oilFilledAttachedThroats = nonzeros(oilFilledAttachedThroats);
         z = length(oilFilledAttachedThroats); % number of oil filled attached throats         
         if z == 0
             ThresholdPressure_PoreBodyFilling = nan;
         elseif z == 1
             [ThresholdPressure_PoreBodyFilling,oilLayerExist] =...
                 calculateThresholdPressurePistonLike_Imbibition(obj, network.Pc_drain_max, Pc);
         else            
            nominator = 0;
             for ii = 1:z
                 randNumber = rand;
                 nominator = nominator + randNumber * W;
             end
             ThresholdPressure_PoreBodyFilling = 2*obj.sig_ow * cos(obj.advancingContactAngle)/obj.radius - obj.sig_ow *nominator; 
        end
        
        end
        function [ThresholdPressure_PoreBodyFilling, oilLayerExist] = calculateThresholdPressurePoreBodyFilling_Valvatne (obj,network, Pc) 
         % Based on Valvatne
         oilLayerExist = nan;
         W = 0.03/sqrt(network.absolutePermeability/1.01325E+15);
         attachedThroats = obj.connectedLinks;
         oilFilledAttachedThroats = zeros(obj.connectionNumber,1);
         for i = 1:obj.connectionNumber
             if network.Links{attachedThroats(i)}.occupancy == 'B'
                 oilFilledAttachedThroats(i,1) = attachedThroats(i);
             end
         end
         oilFilledAttachedThroats = nonzeros(oilFilledAttachedThroats);
         z = length(oilFilledAttachedThroats); % number of oil filled attached throats         
         if z == 0
             ThresholdPressure_PoreBodyFilling = nan;
         elseif z == 1
             [ThresholdPressure_PoreBodyFilling,oilLayerExist] =...
                 calculateThresholdPressurePistonLike_Imbibition(obj, network.Pc_drain_max, Pc);
         else            
            nominator = 0;
             for ii = 1:z
                 randNumber = rand;
                 nominator = nominator + randNumber * W;
             end
             ThresholdPressure_PoreBodyFilling = 2*obj.sig_ow * cos(obj.advancingContactAngle)/obj.radius - obj.sig_ow *nominator; 
        end
        
        end
        function [ThresholdPressure_PoreBodyFilling, oilLayerExist] = calculateThresholdPressurePoreBodyFilling_Oren1 (obj,network, Pc) 
         % Based on Oren1
         oilLayerExist = nan;
         W = [0;0.5;1;2;5;10];
         attachedThroats = obj.connectedLinks;
         oilFilledAttachedThroats = zeros(obj.connectionNumber,1);
         a = 0;
         for i = 1:obj.connectionNumber
             if network.Links{attachedThroats(i)}.occupancy == 'B'
                 a = a+1;
                 oilFilledAttachedThroats(a,1) = attachedThroats(i);
             end
         end
         oilFilledAttachedThroats = nonzeros(oilFilledAttachedThroats);
         z = length(oilFilledAttachedThroats); % number of oil filled attached throats         
         if z == 0
             ThresholdPressure_PoreBodyFilling = nan;
         elseif z == 1
             [ThresholdPressure_PoreBodyFilling,oilLayerExist] =...
                 calculateThresholdPressurePistonLike_Imbibition(obj, network.Pc_drain_max, Pc);
         else            
            nominator = 0;
             for ii = 1:z
                 if z > 5
                     w = W(6);
                 else
                     w = W(z);
                 end 
                 randNumber = rand;
                 nominator = nominator + randNumber * w * network.Links{oilFilledAttachedThroats(ii,1)}.radius;
             end
             ThresholdPressure_PoreBodyFilling = 2*obj.sig_ow * cos(obj.advancingContactAngle)/(obj.radius + nominator); 
         end        
        end
        function [ThresholdPressure_PoreBodyFilling, oilLayerExist] = calculateThresholdPressurePoreBodyFilling_Oren2 (obj,network, Pc) 
         % Based on Oren2
         oilLayerExist = nan;
         W = [0;0.5;1;2;5;10];
         attachedThroats = obj.connectedLinks;
         oilFilledAttachedThroats = zeros(obj.connectionNumber,1);
         a = 0;
         for i = 1:obj.connectionNumber
             if network.Links{attachedThroats(i)}.occupancy == 'B'
                 a = a+1;
                 oilFilledAttachedThroats(a,1) = attachedThroats(i);
             end
         end
         oilFilledAttachedThroats = nonzeros(oilFilledAttachedThroats);
         z = length(oilFilledAttachedThroats); % number of oil filled attached throats         
         if z == 0
             ThresholdPressure_PoreBodyFilling = nan;
         elseif z == 1
             [ThresholdPressure_PoreBodyFilling,oilLayerExist] =...
                 calculateThresholdPressurePistonLike_Imbibition(obj, network.Pc_drain_max, Pc);
         else            
            nominator = 0;
             for ii = 1:z
                 if z > 5
                     w = W(6);
                 else
                     w = W(z);
                 end 
                 randNumber = rand;
                 nominator = nominator + randNumber * w * network.Links{oilFilledAttachedThroats(ii,1)}.radius;
             end
             ThresholdPressure_PoreBodyFilling = (1 + 2 * sqrt(pi * obj.shapeFactor))*obj.sig_ow * cos(obj.advancingContactAngle)/...
                 (obj.radius + nominator); 
         end        
        end
       
    end
end

