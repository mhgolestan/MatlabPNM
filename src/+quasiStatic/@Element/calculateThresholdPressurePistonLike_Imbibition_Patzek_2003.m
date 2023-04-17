function calculateThresholdPressurePistonLike_Imbibition_Patzek_2003(element, Pc_max_drainage) 

if strcmp(element.geometry , 'Circle')== 1 
    element.imbThresholdPressure_PistonLike = 2*element.IFT_NperMeter *cos(element.advancingContactAngle)/element.radius;
    element.nonWettingLayerExist(1,:) = nan;
else 
    halfAngles = [element.halfAngle1, element.halfAngle2,element.halfAngle3, element.halfAngle4];
    hingingAngles = zeros(1,4);
    b_i = zeros(1,4);
    if strcmp(element.geometry , 'Triangle')== 1
        nc = 3;
    else
        nc = 4;
    end
    nominator = 0; alpha = zeros(nc,1);
    for i = 1:nc
        if ~isnan(halfAngles(i))
            nominator = nominator + cos(element.recedingContactAngle + halfAngles(i));
        end
    end
    maxAdvAngle = acos ((-4 * element.shapeFactor * nominator)/...
        ((element.radius * Pc_max_drainage / element.IFT_NperMeter) - cos(element.recedingContactAngle)+...
        4 * nc * element.shapeFactor * sin(element.recedingContactAngle)));
    rpd = element.IFT_NperMeter / Pc_max_drainage;
    rp = rpd *2;
    if element.advancingContactAngle <= maxAdvAngle %Spontaneous Imbibibtion
        rp1 = 2 * rp;
        rp2 = rp;
        while abs(rp2 - rp1) > 10^-10
            rp1 = rp2;
            nominator1 = 0; nominator2 =0;
            for ii = 1:nc
                if ~isnan(halfAngles(ii))
                    hingingAngles(ii) = acos((rpd / rp1)*cos(element.recedingContactAngle + halfAngles(ii))) - halfAngles(ii);
                    if hingingAngles(ii) <= element.advancingContactAngle
                        b_i(1,ii) = element.b(ii);
                        alpha(ii) = asin(b_i(1,ii)/rp1*sin(halfAngles(ii)));
                    else
                        b_i(1,ii) = rp1 * cos(element.advancingContactAngle + halfAngles(ii))/sin(halfAngles(ii));
                        alpha(ii) = pi/2-element.advancingContactAngle- halfAngles(ii);
                    end
                    if b_i(1,ii) < 0
                        b_i(1,ii) = 0;
                    end
                    hingingAngles(ii) = min(hingingAngles(ii) , element.advancingContactAngle);
                    nominator1 = nominator1 + b_i(1,ii)*cos(hingingAngles(ii));
                    nominator2 = nominator2 + (pi/2 - hingingAngles(ii) - halfAngles(ii));
                end
            end
            rp2 = ((element.radius ^ 2 / 4 / element.shapeFactor) -rp1*nominator1 + rp1^2 *nominator2) /...
                (2*rp1 * sum(alpha) + cos(element.advancingContactAngle)*...
                ((element.radius/2/element.shapeFactor) - 2 * sum(b_i)));
        end
        element.imbThresholdPressure_PistonLike = element.IFT_NperMeter / rp2;
        element.nonWettingLayerExist(1,:) = nan;
    elseif element.advancingContactAngle > maxAdvAngle && element.advancingContactAngle < pi/2 + max(halfAngles) %Forced Imbibition
        element.imbThresholdPressure_PistonLike = 2 * element.IFT_NperMeter * cos(element.advancingContactAngle) / element.radius;
        element.nonWettingLayerExist(1,:) = nan;
    elseif element.advancingContactAngle >= pi/2 + max(halfAngles) %Forced Imbibition
        element.imbThresholdPressure_PistonLike = -calculateThresholdPressurePistonLike_drainage(element, (pi - element.advancingContactAngle));
    end
end
end