classdef Element<Fluids
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
        conductance %Element conductance
        geometry % geometrical shape of the element
        halfAngle1
        halfAngle2
        halfAngle3
        halfAngle4
        area
        waterCrossSectionArea
        oilCrossSectionArea
        gasCrossSectionArea 

        
        %It's better to define the phase conductances and the area of each
        %fluid as a structure for this each element
        waterConductance
        oilConductance 
        gasConductance
        fluidConductances
        fluidCrossSectionAreas

        receedingContactAngle = 0;
        advandingContactAngle
        
        waterPressure
        oilPressure
        gasPressure
        thresholdPressure
        occupancy = 'A';
        
     
    end
    
    methods
        function ThresholdPressure = calculateThresholdPressurePistonLike (obj)
         % calculateThresholdPressurePistonLike Summary of this method goes here
         % Detailed explanation goes here  
             if strcmp(obj.geometry , 'Circle')== 1
                 ThresholdPressure = 2*obj.sig_ow *cos(obj.receedingContactAngle)/obj.radius;
             else
                 nominator = 0;
                 halfAngles = [obj.halfAngle1, obj.halfAngle2,obj.halfAngle3, obj.halfAngle4];
                 for jj = 1:4
                     if ~isnan(halfAngles(jj)) && halfAngles(jj) < pi/2 - obj.receedingContactAngle
                         E2 = cos(obj.receedingContactAngle + halfAngles(jj)) *...
                             cos(obj.receedingContactAngle) / sin(halfAngles(jj));
                         E0 = pi / 2 - obj.receedingContactAngle - halfAngles(jj);
                         nominator = nominator +  (E2 - E0);
                     end
                 end
                 ThresholdPressure = (obj.sig_ow / obj.radius)*...
                     cos(obj.receedingContactAngle)*(1+sqrt(1 -(4*obj.shapeFactor*...
                     nominator)/(cos(obj.receedingContactAngle)^2)));
             end
         end
        
         %% Conductance Calculation
         function [waterCrossSectionArea, waterConductance] = calculateWaterConductance(obj, network, Pc)       
             halfAngles = [obj.halfAngle1, obj.halfAngle2,obj.halfAngle3, obj.halfAngle4];
             cornerArea = zeros(1,4);
             cornerConductance = zeros(1,4);
             %Raduis of Curvature
             Rc = network.sig_ow / Pc;
             for jj = 1:4
                 if ~isnan(halfAngles(jj))
                     % Based on Piri_2005: eq A4 & A5 
                     if (halfAngles(jj) + obj.receedingContactAngle) == pi/2
                          cornerArea(jj) = (Rc * cos(obj.receedingContactAngle + halfAngles(jj))/ sin (halfAngles(jj)))^2 *...
                              sin(halfAngles(jj)) * cos(halfAngles(jj));
                      else
                          cornerArea(jj) = Rc ^2 * (cos(obj.receedingContactAngle)*...
                              (cot(halfAngles(jj)) * cos(obj.receedingContactAngle) - sin(obj.receedingContactAngle))+ ...
                              obj.receedingContactAngle + halfAngles(jj) - pi/2);
                     end   
                     % Based on Piri_2005: eq B(10 - 15)
                     f = 1;
                     F1 = pi/2 - halfAngles(jj) - obj.receedingContactAngle;
                     F2 = cot(halfAngles(jj)) * cos(obj.receedingContactAngle) - sin(obj.receedingContactAngle); 
                     F3 = (pi/2 - halfAngles(jj)) * tan(halfAngles(jj));
                     
                     if (obj.receedingContactAngle <= pi/2 - halfAngles(jj))                         
                         cornerConductance(jj) = (cornerArea(jj)^2 * (1 - sin(halfAngles(jj)))^2 * ...
                             (F2 * cos(obj.receedingContactAngle) - F1) * F3 ^ 2) / ...
                             (12 * network.waterViscosity * ((sin(halfAngles(jj))) * ...
                             (1 - F3) * (F2 + f * F1))^ 2);
                     elseif (obj.receedingContactAngle > pi/2 - halfAngles(jj))
                         cornerConductance(jj) = (cornerArea(jj)^2 * tan(halfAngles(jj))* ...
                             (1 - sin(halfAngles(jj)))^2 * F3 ^ 2) / ...
                             (12 * network.waterViscosity *(sin(halfAngles(jj)))^2*(1 - F3) * (1 + f * F3)^ 2);
%                      else
%                           cornerConductance(jj) = (A1^3 * (1 - sin(halfAngles(jj)))^2 * ...
%                              tan(halfAngles(jj)) * F3 ^ 2) / ...
%                               (12 * network.waterViscosity * (sin(halfAngles(jj)))^2 * ...
%                               (1 - F3) * (1 + f1*F3 - (1- f2*F3) * sqrt(A2/cornerArea(jj)))^ 2);
                     end
                 end
                 waterCrossSectionArea = sum(cornerArea);                 
                 waterConductance = sum(cornerConductance);
             end
         end
           
         function [oilCrossSectionArea, oilConductance] = calculateOilConductance(obj, network)                             
             oilCrossSectionArea = obj.area - obj.waterCrossSectionArea;
             if strcmp(obj.geometry , 'Circle')== 1
                 oilConductance = oilCrossSectionArea^2 * 0.5 * obj.shapeFactor /network.oilViscosity;
             elseif strcmp(obj.geometry , 'Triangle')== 1
                 oilConductance = oilCrossSectionArea^2 * 3  * obj.shapeFactor / network.oilViscosity/5;
             elseif strcmp(obj.geometry , 'Square')== 1
                 oilConductance = oilCrossSectionArea^2 *0.5623 * obj.area^2 * obj.shapeFactor /network.oilViscosity;
             end              
         end
    end

end

