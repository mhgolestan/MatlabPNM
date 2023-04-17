function calculateConductance_Drainage(element, Pc)
% Based on Blunt 2017
if element.occupancy == 'B' %element was occupied by nonWetting
    
    if strcmp(element.geometry , 'Circle')== 1
        element.wettingPhaseCrossSectionArea = 0;
        element.wettingPhaseSaturation = 0;
        element.wettingPhaseConductance = 0;
        element.nonWettingCrossSectionArea = element.area;
        element.nonWettingSaturation = 1;
        element.nonWettingConductance = element.area^2 * 0.5 * element.shapeFactor /element.nonWettingPhase_Viscosity_PaS;
        
    else
        halfAngles = [element.halfAngle1, element.halfAngle2,element.halfAngle3, element.halfAngle4];
        cornerArea = zeros(1,4);
        cornerConductance = zeros(1,4);
        %Raduis of Curvature
        Rc = element.IFT_NperMeter / abs(Pc);
        for jj = 1:4
            if ~isnan(halfAngles(jj)) && halfAngles(jj) < pi/2 - element.recedingContactAngle
                
                element.wettingPhaseCornerExist(1,jj) = 1;
                
                % Apex & length of corner: eq 3.6-3.7
                element.b(jj) = element.IFT_NperMeter / Pc * ...
                    cos(element.recedingContactAngle + halfAngles(jj)) * sin(halfAngles(jj)); 
                
                % Area: eq 3.8
                cornerArea(jj) = Rc ^2 * (cos(element.recedingContactAngle)*...
                    cos(halfAngles(jj)+ element.recedingContactAngle) / sin (halfAngles(jj))+ ...
                    element.recedingContactAngle + halfAngles(jj) - pi/2);
                
                %Conductance
                % Based on Piri_2005: eq B(10 - 15)
                f = 1; % no-flow boundary condition suitable for nonWetting-wettingPhase interfaces
                F1 = pi/2 - halfAngles(jj) - element.recedingContactAngle;
                F2 = cot(halfAngles(jj)) * cos(element.recedingContactAngle) - sin(element.recedingContactAngle);
                F3 = (pi/2 - halfAngles(jj)) * tan(halfAngles(jj));
                
                if (element.recedingContactAngle <= pi/2 - halfAngles(jj))  % Positive Curvature
                    cornerConductance(jj) = (cornerArea(jj)^2 * (1 - sin(halfAngles(jj)))^2 * ...
                        (F2 * cos(element.recedingContactAngle) - F1) * F3 ^ 2) / ...
                        (12 * element.wettingPhase_Viscosity_PaS * ((sin(halfAngles(jj))) * ...
                        (1 - F3) * (F2 + f * F1))^ 2);
                elseif (element.recedingContactAngle > pi/2 - halfAngles(jj)) % Negative Curvature
                    cornerConductance(jj) = (cornerArea(jj)^2 * tan(halfAngles(jj))* ...
                        (1 - sin(halfAngles(jj)))^2 * F3 ^ 2) / ...
                        (12 * element.wettingPhase_Viscosity_PaS *(sin(halfAngles(jj)))^2*(1 - F3) * (1 + f * F3)^ 2);
                end
            end
            element.wettingPhaseCrossSectionArea = sum(cornerArea);
            element.wettingPhaseConductance = sum(cornerConductance);
        end
        element.nonWettingCrossSectionArea = element.area - element.wettingPhaseCrossSectionArea;
        if strcmp(element.geometry , 'Triangle')== 1
            element.nonWettingConductance = element.nonWettingCrossSectionArea^2 * 3  * element.shapeFactor / element.nonWettingPhase_Viscosity_PaS/5;
        elseif strcmp(element.geometry , 'Square')== 1
            element.nonWettingConductance = element.nonWettingCrossSectionArea^2 *0.5623 * element.shapeFactor /element.nonWettingPhase_Viscosity_PaS;
        end
        element.wettingPhaseSaturation = element.wettingPhaseCrossSectionArea/element.area;
        element.nonWettingSaturation = element.nonWettingCrossSectionArea/element.area;
    end
else
    element.wettingPhaseCrossSectionArea = element.area;
    element.wettingPhaseConductance = element.conductanceSinglePhase;
    element.nonWettingCrossSectionArea = 0;
    element.nonWettingConductance = 0;
    element.wettingPhaseSaturation = 1;
    element.nonWettingSaturation = 0;
end