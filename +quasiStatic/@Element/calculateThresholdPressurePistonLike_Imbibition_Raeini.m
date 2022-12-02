function calculateThresholdPressurePistonLike_Imbibition_Raeini(element, Pc_max_drainage)

if strcmp(element.geometry , 'Circle')== 1
    % Based on Al-Futaisi&Patzek_2001: eqs 2-5 & Piri_2005: eq C4
    element.imbThresholdPressure_PistonLike = 2*element.sig_ow *cos(element.advancingContactAngle)/element.radius;
    element.oilLayerExist(1,:) = nan;
else
    % Based on  Al-Futaisi&Patzek_2001: eqs 2-4 & 6-10
    halfAngles = [element.halfAngle1, element.halfAngle2,element.halfAngle3, element.halfAngle4];
    if strcmp(element.geometry , 'Triangle')== 1
        nc = 3;
    else
        nc = 4;
    end
    
    nominator = 0;
    for i = 1:nc
        if ~isnan(halfAngles(i))
            nominator = nominator + cos(element.recedingContactAngle + halfAngles(i));
        end
    end
    a = (-4 * element.shapeFactor * nominator)/...
        ((element.radius * Pc_max_drainage / element.sig_ow) - cos(element.recedingContactAngle)+...
        12 * element.shapeFactor * sin(element.recedingContactAngle));
    if a >1
        a = 1;
    elseif a< -1
        a = -1;
    end
    maxAdvAngle = acos (a);
    if element.advancingContactAngle <= maxAdvAngle % Spontaneous imbibition
        newPc = 1.1 * element.sig_ow * 2 * cos(element.advancingContactAngle) / element.radius;
        MAX_NEWT_ITR = 50000;
        for itr = 1:MAX_NEWT_ITR
            sumOne = 0; sumTwo = 0; sumThree = 0; sumFour = 0;
            oldPc = newPc;
            for i = 1:nc
                hingTeta = element.advancingContactAngle;
                b_i = element.sig_ow / oldPc * cos(hingTeta +  halfAngles(i))/sin(halfAngles(i));
                if b_i< 0
                    b_i = 0;
                end
                partus = b_i * sin(halfAngles(i)) * oldPc / element.sig_ow;
                if partus > 1
                    partus = 1;
                elseif partus < -1
                    partus = -1;
                end
                sumOne = sumOne + b_i * cos(hingTeta);
                sumTwo = sumTwo + pi / 2 - hingTeta - halfAngles(i);
                sumThree = sumThree + asin(partus);
                sumFour = sumFour + b_i;
            end
            a = 2 * sumThree - sumTwo;
            bb = cos(element.advancingContactAngle) * element.radius / 2 / element.shapeFactor - 2 * sumFour + sumOne;
            c = -element.area;
            root_s = bb ^ 2 - 4 * a  * c;
            if root_s > 0
                newPc2 = element.sig_ow * 2 * a / ( -bb + sqrt(root_s));
            else
                newPc2 = element.sig_ow * 2 * a / (-bb);
            end
            newPc = newPc2;
            err = 2 * abs(newPc - oldPc) / (abs(oldPc) + abs(newPc)+0.001);
            if err < 10^-11
                break;
            end
        end
        element.imbThresholdPressure_PistonLike = newPc;
        if err <0.1 && err > 0.0001
            fprintf('err %f\n',element.index);
        end
    elseif element.advancingContactAngle < pi/2 + max(halfAngles) % Forced imbibition
        element.imbThresholdPressure_PistonLike = 2 * element.sig_ow * cos(element.advancingContactAngle) / element.radius;
    elseif element.advancingContactAngle >= pi/2 + max(halfAngles) % Forced imbibition
        element.imbThresholdPressure_PistonLike = -calculateThresholdPressurePistonLike_drainage(element, (pi - element.advancingContactAngle));
    end
end
end