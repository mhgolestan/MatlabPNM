function calculateConductance_Imbibition_Patzek_Piri(element, network, Pc)
Pc = abs(Pc);
if ~any(element.nonWettingLayerExist)
    
    if element.occupancy == 'B'
        
        if strcmp(element.geometry , 'Circle')== 1
            
            element.wettingPhaseCrossSectionArea = 0;
            element.wettingPhaseConductance = 0;
            element.nonWettingCrossSectionArea = element.area;
            element.nonWettingConductance = element.conductanceSinglePhase;
            element.wettingPhaseSaturation = 0;
            element.nonWettingSaturation = 1;
        else
            
            halfAngles = [element.halfAngle1, element.halfAngle2,element.halfAngle3, element.halfAngle4];
            cornerArea = zeros(1,4);    cornerConductance = zeros(1,4);
            % Based on  Al-Futaisi&Patzek_2003: eqs 12-14
            for i = 1:4
                if ~isnan(halfAngles(i)) && ~isnan(element.wettingPhaseCornerExist(i))
                    %Raduis of Curvature
                    rso1 = element.IFT_NperMeter / Pc;
                    rpd = element.IFT_NperMeter / network.Pc_drain_max_Pa;
%                   r_adv = abs(rpd * cos(element.recedingContactAngle+halfAngles(i))/cos(element.advancingContactAngle+halfAngles(i)));
%                   if rso1 > r_adv
%                       rso1 = r_adv;
%                   end
                    part = rpd * cos(element.recedingContactAngle+halfAngles(i))/rso1;
                    element.hingeAngles(i) = acos(part) - halfAngles(i);
                    element.hingeAngles(i) = min (element.hingeAngles(i), element.advancingContactAngle);
                    element.b(i) = rso1*cos(element.hingeAngles(i) + halfAngles(i))/sin(halfAngles(i));
                    if element.b(i) > element.radius / tan(halfAngles(i))
                        element.b(i) = element.radius / tan(halfAngles(i));
                    end
                    % Area
                    % Based on Piri_2005: eq A4 & A5
                    if (element.hingeAngles(i) + element.recedingContactAngle) == pi/2
                        cornerArea(i) = (rso1 * cos(element.hingeAngles(i) + halfAngles(i))/ sin (halfAngles(i)))^2 *...
                            sin(halfAngles(i)) * cos(halfAngles(i));
                    else
                        cornerArea(i) = rso1 ^2 * (cos(element.hingeAngles(i))*...
                            (cot(halfAngles(i)) * cos(element.hingeAngles(i)) - sin(element.hingeAngles(i)))+ ...
                            element.hingeAngles(i) + halfAngles(i) - pi/2);
                    end
                    %Conductance
                    % Based on Piri_2005: eq B(10 - 15)
                    f = 1; % no-flow boundary condition suitable for nonWetting-wettingPhase interfaces
                    F1 = pi/2 - halfAngles(i) - element.hingeAngles(i);
                    F2 = cot(halfAngles(i)) * cos(element.hingeAngles(i)) - sin(element.hingeAngles(i));
                    F3 = (pi/2 - halfAngles(i)) * tan(halfAngles(i));
                    
                    if (element.hingeAngles(i) <= pi/2 - halfAngles(i))  % Positive Curvature
                        cornerConductance(i) = (cornerArea(i)^2 * (1 - sin(halfAngles(i)))^2 * ...
                            (F2 * cos(element.hingeAngles(i)) - F1) * F3 ^ 2) / ...
                            (12 * element.wettingPhase_Viscosity_PaS * ((sin(halfAngles(i))) * ...
                            (1 - F3) * (F2 + f * F1))^ 2);
                    elseif (element.hingeAngles(i) > pi/2 - halfAngles(i)) % Negative Curvature
                        cornerConductance(i) = (cornerArea(i)^2 * tan(halfAngles(i))* ...
                            (1 - sin(halfAngles(i)))^2 * F3 ^ 2) / ...
                            (12 * element.wettingPhase_Viscosity_PaS *(sin(halfAngles(i)))^2*(1 - F3) * (1 + f * F3)^ 2);
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
    
else
    if strcmp(element.geometry , 'Triangle')== 1
        nc = 3;
    else
        nc = 4;
    end
    
    R = network.IFT_NperMeter / Pc; %Radius of Curvature
    halfAngles = [element.halfAngle1, element.halfAngle2,element.halfAngle3, element.halfAngle4];
    inerArea = zeros(1,nc);
    outerArea = zeros(1,nc);
    layerArea = zeros(1,nc);
    inerConductance = zeros(1,nc);
    layerConductance = zeros(1,nc);
    for jj = 1:nc
        if ~isnan(element.nonWettingLayerExist(1,jj)) %if the layer exist in the corner
            
            R_min = network.IFT_NperMeter / network.Pc_drain_max_Pa;
            part = R_min * cos(element.recedingContactAngle+halfAngles(jj))/R;
            thetaHingRec = acos( part)-halfAngles(jj);
            thetaHingRec = min(thetaHingRec, element.advancingContactAngle);
            
            % Area of corner wettingPhase
            if (halfAngles(jj) + thetaHingRec) == pi/2
                inerArea(jj) = (R * cos(thetaHingRec + halfAngles(jj))/ sin (halfAngles(jj)))^2 *...
                    sin(halfAngles(jj)) * cos(halfAngles(jj));
            else
                inerArea(jj) = R ^2 * (cos(thetaHingRec)*...
                    (cot(halfAngles(jj)) * cos(thetaHingRec) - sin(thetaHingRec))+ ...
                    thetaHingRec+ halfAngles(jj) - pi/2);
            end
            
            f = 1; % no-flow boundary condition suitable for nonWetting-wettingPhase interfaces
            F1 = pi/2 - halfAngles(jj) - thetaHingRec;
            F2 = cot(halfAngles(jj)) * cos(thetaHingRec) - sin(thetaHingRec);
            F3 = (pi/2 - halfAngles(jj)) * tan(halfAngles(jj));
            
            % Conductance of corner wettingPhase
            if thetaHingRec <= pi/2 - halfAngles(jj) % Positive Curvature
                
                inerConductance(jj) = (inerArea(jj)^2 * (1 - sin(halfAngles(jj)))^2 * ...
                    (F2 * cos(thetaHingRec) - F1) * F3 ^ 2) / ...
                    (12 * network.wettingPhase_Viscosity_PaS * ((sin(halfAngles(jj))) * ...
                    (1 - F3) * (F2 + f * F1))^ 2);
            elseif (thetaHingRec > pi/2 - halfAngles(jj)) % Negative Curvature
                inerConductance(jj) = (inerArea(jj)^2 * tan(halfAngles(jj))* ...
                    (1 - sin(halfAngles(jj)))^2 * F3 ^ 2) / ...
                    (12 * network.wettingPhase_Viscosity_PaS *(sin(halfAngles(jj)))^2*(1 - F3) * (1 + f * F3)^ 2);
            end
            
            thetaHingAdv = pi - element.advancingContactAngle;
            if (halfAngles(jj) + thetaHingAdv) == pi/2
                outerArea(jj) = (R * cos(thetaHingAdv + halfAngles(jj))/ sin (halfAngles(jj)))^2 *...
                    sin(halfAngles(jj)) * cos(halfAngles(jj));
            else
                outerArea(jj) = R ^2 * (cos(thetaHingAdv)*...
                    (cot(halfAngles(jj)) * cos(thetaHingAdv) - sin(thetaHingAdv))+ ...
                    thetaHingAdv+ halfAngles(jj) - pi/2);
            end
            % Area of nonWetting layer
            layerArea(jj) = outerArea(jj)-inerArea(jj);
            % Conductance of nonWetting layer
            F3_layer = (pi/2 - halfAngles(jj)) * tan(halfAngles(jj));
            layerConductance(jj) = (layerArea(jj)^3 * (1 - sin(halfAngles(jj)))^2 * ...
                tan(halfAngles(jj)) * F3_layer ^ 2) / ...
                (12 * network.nonWettingPhase_Viscosity_PaS *outerArea(jj)* (sin(halfAngles(jj)))^2 * ...
                (1 - F3_layer) * (1 + F3_layer - (1- F3) * sqrt(inerArea(jj)/outerArea(jj))));
        end
    end
    % Center wettingPhase area and conductance
    centerWaterArea = element.area - sum(outerArea);
    if strcmp(element.geometry , 'Triangle')== 1
        centerWaterConductance = 3 *element.radius^2*centerWaterArea/20/network.wettingPhase_Viscosity_PaS;
    else
        centerWaterConductance = 0.5623 * element.shapeFactor * centerWaterArea^2/network.wettingPhase_Viscosity_PaS;
    end
    
    element.wettingPhaseCrossSectionArea = element.area - sum(layerArea);
    element.wettingPhaseConductance = centerWaterConductance + sum(inerConductance);
    element.nonWettingCrossSectionArea = sum(layerArea);
    element.nonWettingConductance = sum(layerConductance);
    element.wettingPhaseSaturation = element.wettingPhaseCrossSectionArea/element.area;
    element.nonWettingSaturation = element.nonWettingCrossSectionArea/element.area;
end

if element.wettingPhaseSaturation > 1
    % Control
    fprintf('sat %f %4.0d  %f \n',Pc, element.index,element.wettingPhaseSaturation);
    element.control(1:3) = [Pc, element.imbThresholdPressure_PistonLike, element.imbThresholdPressure_SnapOff];
    
    element.wettingPhaseCrossSectionArea = element.area;
    element.wettingPhaseConductance = element.conductanceSinglePhase;
    element.nonWettingCrossSectionArea = 0;
    element.nonWettingConductance = 0;
    element.wettingPhaseSaturation = 1;
    element.nonWettingSaturation = 0;
end
end