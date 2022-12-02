function calculateConductance_Drainage(element, Pc)
% Based on Blunt 2017
if element.occupancy == 'B' %element was occupied by oil
    
    if strcmp(element.geometry , 'Circle')== 1
        element.waterCrossSectionArea = 0;
        element.waterSaturation = 0;
        element.waterConductance = 0;
        element.oilCrossSectionArea = element.area;
        element.oilSaturation = 1;
        element.oilConductance = element.area^2 * 0.5 * element.shapeFactor /element.oilViscosity;
        
    else
        halfAngles = [element.halfAngle1, element.halfAngle2,element.halfAngle3, element.halfAngle4];
        cornerArea = zeros(1,4);
        cornerConductance = zeros(1,4);
        %Raduis of Curvature
        Rc = element.sig_ow / abs(Pc);
        for jj = 1:4
            if ~isnan(halfAngles(jj)) && halfAngles(jj) < pi/2 - element.recedingContactAngle
                
                element.waterCornerExist(1,jj) = 1;
                
                % Apex & length of corner: eq 3.6-3.7
                element.b(jj) = element.sig_ow / Pc * ...
                    cos(element.recedingContactAngle + halfAngles(jj)) * sin(halfAngles(jj)); 
                
                % Area: eq 3.8
                cornerArea(jj) = Rc ^2 * (cos(element.recedingContactAngle)*...
                    cos(halfAngles(jj)+ element.recedingContactAngle) / sin (halfAngles(jj))+ ...
                    element.recedingContactAngle + halfAngles(jj) - pi/2);
                
                %Conductance
                % Based on Piri_2005: eq B(10 - 15)
                f = 1; % no-flow boundary condition suitable for oil-water interfaces
                F1 = pi/2 - halfAngles(jj) - element.recedingContactAngle;
                F2 = cot(halfAngles(jj)) * cos(element.recedingContactAngle) - sin(element.recedingContactAngle);
                F3 = (pi/2 - halfAngles(jj)) * tan(halfAngles(jj));
                
                if (element.recedingContactAngle <= pi/2 - halfAngles(jj))  % Positive Curvature
                    cornerConductance(jj) = (cornerArea(jj)^2 * (1 - sin(halfAngles(jj)))^2 * ...
                        (F2 * cos(element.recedingContactAngle) - F1) * F3 ^ 2) / ...
                        (12 * element.waterViscosity * ((sin(halfAngles(jj))) * ...
                        (1 - F3) * (F2 + f * F1))^ 2);
                elseif (element.recedingContactAngle > pi/2 - halfAngles(jj)) % Negative Curvature
                    cornerConductance(jj) = (cornerArea(jj)^2 * tan(halfAngles(jj))* ...
                        (1 - sin(halfAngles(jj)))^2 * F3 ^ 2) / ...
                        (12 * element.waterViscosity *(sin(halfAngles(jj)))^2*(1 - F3) * (1 + f * F3)^ 2);
                end
            end
            element.waterCrossSectionArea = sum(cornerArea);
            element.waterConductance = sum(cornerConductance);
        end
        element.oilCrossSectionArea = element.area - element.waterCrossSectionArea;
        if strcmp(element.geometry , 'Triangle')== 1
            element.oilConductance = element.oilCrossSectionArea^2 * 3  * element.shapeFactor / element.oilViscosity/5;
        elseif strcmp(element.geometry , 'Square')== 1
            element.oilConductance = element.oilCrossSectionArea^2 *0.5623 * element.shapeFactor /element.oilViscosity;
        end
        element.waterSaturation = element.waterCrossSectionArea/element.area;
        element.oilSaturation = element.oilCrossSectionArea/element.area;
    end
else
    element.waterCrossSectionArea = element.area;
    element.waterConductance = element.conductanceSinglePhase;
    element.oilCrossSectionArea = 0;
    element.oilConductance = 0;
    element.waterSaturation = 1;
    element.oilSaturation = 0;
end