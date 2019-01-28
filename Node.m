classdef Node < Element
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        x_coordinate
        y_coordinate
        z_coordinate
        connectionNumber
        connectedNodes
        connectedLinks
        length

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
            sig_ow = 20e-3; % N/m
            
            
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
             obj.thresholdPressure = obj.calculateThresholdPressurePistonLike();
        end
        
    end
end

