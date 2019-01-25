classdef Link < Element & Fluids
    
    %LINK is a class for link objects
    %   Detailed explanation goes here
    
    properties
        pore1Index
        pore2Index
        length %total length of the link (pore center to pore center)
        pore1Length
        pore2Length
        linkLength  % only the length of the link
        
    end
    
    methods
        function obj = Link(index,... 
                            pore1Index,... 
                            pore2Index,...
                            radius,...
                            shapeFactor,...
                            length,...
                            pore1Length,...
                            pore2Length,...
                            linkLength,...
                            volume,...
                            clayVolume)
            %UNTITLED3 Construct an instance of this class
            %   Detailed explanation goes here
            obj.index = index;
            %This condition is to set the nodes with index -1 in node1 and
            %nodes with 0 index in node2
            if pore2Index == -1 || pore1Index == 0
                obj.pore1Index = pore2Index; 
                obj.pore2Index = pore1Index;
                obj.pore1Length = pore2Length;
                obj.pore2Length = pore1Length;                  
            else            
                obj.pore1Index = pore1Index; 
                obj.pore2Index = pore2Index;
                obj.pore1Length = pore1Length;
                obj.pore2Length = pore2Length;
            end
                   
            obj.radius = radius;
            obj.shapeFactor = shapeFactor;
            obj.length = length;
            obj.linkLength = linkLength;
            obj.volume = volume;
            obj.clayVolume = clayVolume;
%             water_viscosity = 0.001;
%             sig_ow = 20e-3; % N/m
            
            
            %Cheking inlet or outlet status of the link
            obj.isInlet  = false;
            obj.isOutlet = false;
            if obj.pore1Index == -1 
                obj.isInlet = true;
            elseif obj.pore2Index == 0
                obj.isOutlet = true;
            end
            
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
                obj.conductance = 3 * obj.area^2 * obj.shapeFactor /obj.waterViscosity / 5;
            elseif obj.shapeFactor > sqrt(3) / 36 && obj.shapeFactor <= 1 / 16
                obj.geometry = 'Square';
                obj.halfAngle1 = pi / 4;
                obj.halfAngle2 = pi / 4;
                obj.halfAngle3 = pi / 4;
                obj.halfAngle4 = pi / 4;
                obj.area = 4*obj.radius^2;                
                obj.conductance = 0.5623 * obj.area^2 * obj.shapeFactor /obj.waterViscosity;
            elseif obj.shapeFactor > 1 / 16
                obj.geometry = 'Circle';
                obj.halfAngle1 = nan;
                obj.halfAngle2 = nan;
                obj.halfAngle3 = nan;
                obj.halfAngle4 = nan;
                obj.area = pi*obj.radius^2;                
                obj.conductance = 0.5 * obj.area^2 * obj.shapeFactor /water_viscosity;
            end
            obj.thresholdPressure = obj.calculateThresholdPressurePistonLike();
        end
        
    end
end

