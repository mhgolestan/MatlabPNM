classdef Element<quasiStatic.Fluids
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        % properties set from the link and node input files
        index
        radius
        shapeFactor
        volume
        clayVolume
        isInlet
        isOutlet
        
        % Calculated properties
        
        geometry % geometrical shape of the element 
        halfAngle1
        halfAngle2
        halfAngle3
        halfAngle4
        area   
        
        % Element conductance & area
        conductanceSinglePhase                
        
        waterPressure
        oilPressure      
        
        occupancy = 'A';  % Element filled by Water 
         
    end  
    
    methods
        function calculateElementsProperties(obj) 
            
            % Geometry and conductance specification of the elements is
            % based of : Patzek, T. W., & Silin, D. B. (2001). Shape factor and hydraulic conductance in noncircular capillaries: I. One-phase creeping flow. Journal of Colloid and Interface Science. https://doi.org/10.1006/jcis.2000.7413
            % For ducts with square cross-sections, all four half-angles are equal to /4? and G = 1/16 . Circular ducts have no corners and G =1/ 4? . For simplicity, all ducts with shape factors between those of equilateral triangle and square can be mapped onto squares, and those with shape factors above 1/16 onto circles.
            % we'd better to insert star shapes later
            if  obj.shapeFactor <= sqrt(3) / 36
                obj.shapeFactor = max(obj.shapeFactor, 10^-7);
                obj.geometry = 'Triangle';
                betha2_min = atan((2 / sqrt(3)) * cos((acos(-12 * sqrt(3) * obj.shapeFactor)) / 3 + (4 * pi / 3)));
                betha2_max = atan((2 / sqrt(3)) * cos((acos(-12 * sqrt(3) * obj.shapeFactor)) / 3 ));
                % rand(0.25-0.75)
                rand_1 = 0.5*(rand+0.5);
                obj.halfAngle2 = betha2_min + rand_1 * (betha2_max - betha2_min);
                obj.halfAngle1 = -0.5 * obj.halfAngle2 + 0.5 * asin((tan(obj.halfAngle2) + 4 * obj.shapeFactor) * sin(obj.halfAngle2) / (tan(obj.halfAngle2) - 4 * obj.shapeFactor));
                obj.halfAngle3 = pi / 2 - obj.halfAngle1 - obj.halfAngle2;
                obj.halfAngle4 = nan;
                obj.area = obj.radius^2/4/obj.shapeFactor;                
                obj.conductanceSinglePhase = 3 * obj.area^2 * obj.shapeFactor /obj.waterViscosity / 5;   
            elseif obj.shapeFactor > sqrt(3) / 36 && obj.shapeFactor <= 1 / 16
                obj.geometry = 'Square';
                obj.halfAngle1 = pi / 4;
                obj.halfAngle2 = pi / 4;
                obj.halfAngle3 = pi / 4;
                obj.halfAngle4 = pi / 4;
                obj.area = 4*obj.radius^2;                
                obj.conductanceSinglePhase = 0.5623 * obj.area^2 * obj.shapeFactor /obj.waterViscosity; 
            elseif obj.shapeFactor > 1 / 16
                obj.geometry = 'Circle';
                obj.halfAngle1 = nan;
                obj.halfAngle2 = nan;
                obj.halfAngle3 = nan;
                obj.halfAngle4 = nan;
                obj.area = pi*obj.radius^2;                
                obj.conductanceSinglePhase = 0.5 * obj.area^2 * obj.shapeFactor /obj.waterViscosity;  
            end
                if obj.volume == 0
                    obj.volume = obj.area * obj.length;
                end
        end
          
    end

end

