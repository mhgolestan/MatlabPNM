function calculateConductance_Imbibition(element, network, Pc)

Pc = abs(Pc);

if ~any(element.nonWettingLayerExist)
    
    if element.occupancy == 'B'
        
        if strcmp(element.geometry , 'Circle')== 1
            element.wettingPhaseCrossSectionArea = 0;
            element.wettingPhaseConductance = 0;
            element.nonWettingCrossSectionArea = element.area;
            element.nonWettingConductance = element.nonWettingCrossSectionArea^2 * 0.5 * element.shapeFactor /element.nonWettingPhase_Viscosity_PaS;
            element.wettingPhaseSaturation = 0;
            element.nonWettingSaturation = 1;
        else
            if strcmp(element.geometry , 'Triangle')== 1
                nc = 3;
            else
                nc = 4;
            end 
            
            R = network.IFT_NperMeter / Pc; %Radius of Curvature
            R_min = network.IFT_NperMeter / network.Pc_drain_max_Pa;
            
            halfAngles = [element.halfAngle1, element.halfAngle2,element.halfAngle3, element.halfAngle4];
            cornerArea = zeros(1,nc);
            cornerConductance = zeros(1,nc);
            for jj = 1:nc
                
                part = R_min * cos(element.recedingContactAngle+halfAngles(jj))/R;
                element.hingeAngles(jj) = acos( part)-halfAngles(jj);
                element.hingeAngles(jj) = min(element.hingeAngles(jj), element.advancingContactAngle);
                element.b(jj) = R * cos(element.hingeAngles(jj) + halfAngles(jj))/ sin(halfAngles(jj));
                
                if element.b(jj) < 0
                    element.b(jj) = 0;
                else
                    
                    % Area
                    % Based on Valvatne 3.45-3.49
                    if abs(element.hingeAngles(jj) + halfAngles(jj) - pi/2) < 0.01
                        cornerArea(jj) = sin(halfAngles(jj))*cos(halfAngles(jj));
                    else
                        cornerArea(jj) = (sin(halfAngles(jj))/cos(halfAngles(jj)+element.hingeAngles(jj))) ^2 ...
                            * (cos(element.hingeAngles(jj))*cos(halfAngles(jj)+element.hingeAngles(jj))/ sin(halfAngles(jj))+ ...
                            element.hingeAngles(jj) + halfAngles(jj) - pi/2);
                    end
                    %Conductance
                    Gstar = (sin(halfAngles(jj))*cos(halfAngles(jj)))/(4*(1+sin(halfAngles(jj)))^2);
                    Gc = Gstar;
                    if abs(element.hingeAngles(jj) + halfAngles(jj) - pi/2) > 0.01
                        Gc = cornerArea(jj)/...
                            (4*(1-(sin(halfAngles(jj))/cos(halfAngles(jj)+element.hingeAngles(jj)))*...
                            (element.hingeAngles(jj) + halfAngles(jj) - pi/2))^2);
                    end
                    C = 0.364 + 0.28 * Gstar/Gc;
                    cornerArea(jj) = cornerArea(jj) * element.b(jj)^2;
                    cornerConductance(jj) =  C * cornerArea(jj)^2 * Gc /element.wettingPhase_Viscosity_PaS;
                end
            end
            
            element.wettingPhaseConductance = sum(cornerConductance);
            element.wettingPhaseCrossSectionArea = sum(cornerArea);
            element.wettingPhaseSaturation = min(element.wettingPhaseCrossSectionArea / element.area, 1);
            element.nonWettingSaturation = max(1-element.wettingPhaseSaturation,0);
            
            if strcmp(element.geometry , 'Triangle')== 1
                element.nonWettingConductance = element.area^2 * 3  * element.shapeFactor / element.nonWettingPhase_Viscosity_PaS/5 *element.nonWettingSaturation;
            elseif strcmp(element.geometry , 'Square')== 1
                element.nonWettingConductance = element.area^2 *0.5623 * element.shapeFactor /element.nonWettingPhase_Viscosity_PaS*element.nonWettingSaturation;
            end
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
            if part > 1
                part = 1;
            elseif part < -1
                part = -1;
            end
            thetaHingRec = acos( part)-halfAngles(jj);
            thetaHingRec = min (thetaHingRec, element.advancingContactAngle);
            
            % Area of corner wettingPhase
            if (halfAngles(jj) + thetaHingRec) == pi/2
                inerArea(jj) = (R * cos(thetaHingRec + halfAngles(jj))/ sin (halfAngles(jj)))^2 *...
                    sin(halfAngles(jj)) * cos(halfAngles(jj));
            else
                inerArea(jj) = R ^2 * (cos(thetaHingRec)*...
                    (cot(halfAngles(jj)) * cos(thetaHingRec) - sin(thetaHingRec))+ ...
                    thetaHingRec+ halfAngles(jj) - pi/2);
            end
            % Conductance of corner wettingPhase
            if thetaHingRec <= pi/2 - halfAngles(jj) % Positive Curvature
                f = 1; % no-flow boundary condition suitable for nonWetting-wettingPhase interfaces
                F1 = pi/2 - halfAngles(jj) - thetaHingRec;
                F2 = cot(halfAngles(jj)) * cos(thetaHingRec) - sin(thetaHingRec);
                F3 = (pi/2 - halfAngles(jj)) * tan(halfAngles(jj));
                
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
    element.wettingPhaseSaturation = element.wettingPhaseCrossSectionArea / element.area;
    element.nonWettingSaturation = element.nonWettingCrossSectionArea / element.area;
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