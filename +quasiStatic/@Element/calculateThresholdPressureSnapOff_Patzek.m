function calculateThresholdPressureSnapOff_Patzek(element,Pc_max_drainage)

if strcmp(element.geometry , 'Circle')== 1
    element.imbThresholdPressure_SnapOff = nan;
else
    % Based on  Al-Futaisi&Patzek_2003: eqs 12-14
    halfAngles = [element.halfAngle1, element.halfAngle2,element.halfAngle3, element.halfAngle4];
    maxAdvAngle = pi/2 - min(halfAngles);
    if strcmp(element.geometry , 'Triangle')== 1
        nc = 3;
        if element.advancingContactAngle < maxAdvAngle %Spontaneous Imbibition
            
            rso = zeros(1,nc);
            for edge = 1:nc
                
                rso1 = element.IFT_NperMeter / element.imbThresholdPressure_PistonLike;
                rso2 = rso1*2;
                
                while abs(rso1 - rso2) > 10^-8
                    rso1 = rso2;
                    hingeAngle_ii = acos((element.IFT_NperMeter / rso1)*...
                        cos(element.recedingContactAngle + halfAngles(1))/Pc_max_drainage) - halfAngles(1);
                    if hingeAngle_ii <= element.advancingContactAngle
                        E1_i = cos(element.recedingContactAngle + halfAngles(1))/sin(halfAngles(1));
                    else
                        E1_i = cos(element.advancingContactAngle + halfAngles(1))/sin(halfAngles(1));
                    end
                    
                    hingeAngle_jj = acos((element.IFT_NperMeter / rso1)*...
                        cos(element.recedingContactAngle + halfAngles(2)) / Pc_max_drainage) - halfAngles(2);
                    if hingeAngle_jj <= element.advancingContactAngle
                        E1_j = cos(element.recedingContactAngle + halfAngles(2))/sin(halfAngles(2));
                    else
                        E1_j = cos(element.advancingContactAngle + halfAngles(2))/sin(halfAngles(2));
                    end
                    
                    hingeAngle_kk = acos((element.IFT_NperMeter / rso1)*...
                        cos(element.recedingContactAngle + halfAngles(3)) / Pc_max_drainage) - halfAngles(3);
                    if hingeAngle_kk <= element.advancingContactAngle
                        E1_k = cos(element.recedingContactAngle + halfAngles(3))/sin(halfAngles(3));
                    else
                        E1_k = cos(element.advancingContactAngle + halfAngles(3))/sin(halfAngles(3));
                    end
                    
                    rso12 = element.radius *(cot(halfAngles(1))+ cot(halfAngles(2))) / (E1_i + E1_j);
                    rso23 = element.radius *(cot(halfAngles(2))+ cot(halfAngles(3))) / (E1_j + E1_k);
                    rso31 = element.radius *(cot(halfAngles(3))+ cot(halfAngles(1))) / (E1_k + E1_i);
                    r2 = min(rso12,rso23);
                    rso = min(r2,rso31);
                end
            end
            element.imbThresholdPressure_SnapOff = element.IFT_NperMeter / rso;
            
            % Forced imbibition part
        elseif element.advancingContactAngle == maxAdvAngle
            element.imbThresholdPressure_SnapOff = 0;
        elseif element.advancingContactAngle > maxAdvAngle && element.advancingContactAngle < pi - min(halfAngles)
            element.imbThresholdPressure_SnapOff = Pc_max_drainage*cos(element.advancingContactAngle + min(halfAngles))/...
                cos(element.recedingContactAngle + min(halfAngles));
        elseif element.advancingContactAngle >= pi - min(halfAngles)
            element.imbThresholdPressure_SnapOff = -Pc_max_drainage/cos(element.recedingContactAngle + min(halfAngles));
        end
    else
        % elemnt is square : Piri
        if element.advancingContactAngle <= pi/4
            %eq C34
            element.imbThresholdPressure_SnapOff = element.IFT_NperMeter / element.radius * ...
                (cot(pi/4)*cos(element.advancingContactAngle)-sin(element.advancingContactAngle));
        elseif element.advancingContactAngle > pi/4 && element.advancingContactAngle <= 3*pi/4
            element.imbThresholdPressure_SnapOff = Pc_max_drainage*cos(element.advancingContactAngle + pi/4)/...
                cos(element.recedingContactAngle + pi/4);
        elseif element.advancingContactAngle > 3*pi/4
            element.imbThresholdPressure_SnapOff = -Pc_max_drainage/cos(element.recedingContactAngle + min(halfAngles));
        end
    end
end
end