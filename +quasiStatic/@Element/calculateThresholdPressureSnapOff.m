function calculateThresholdPressureSnapOff(element,Pc_max_drainage)

if strcmp(element.geometry , 'Circle')== 1
    element.imbThresholdPressure_SnapOff = nan;
else
    r_dr = element.IFT_NperMeter / Pc_max_drainage;
    % Based on  Zolfaghari_2014: eqs 4.31
    if strcmp(element.geometry , 'Triangle')== 1
        A = zeros(1,7);
        if element.advancingContactAngle <= pi/2 - element.halfAngle1 %Spontaneous Imbibition
            A(1) = cos(element.advancingContactAngle) - 2 * sin(element.advancingContactAngle)/ ...
                (cot(element.halfAngle1)+cot(element.halfAngle2));
            A(2) = cos(element.advancingContactAngle) - 2 * sin(element.advancingContactAngle)/ ...
                (cot(element.halfAngle1)+cot(element.halfAngle3));
            A(3) = cos(element.advancingContactAngle) - 2 * sin(element.advancingContactAngle)/ ...
                (cot(element.halfAngle2)+cot(element.halfAngle3));
            A(4) = (cos(element.advancingContactAngle)*cot(element.halfAngle1)-sin(element.advancingContactAngle)) / ...
                (cot(element.halfAngle1)+cot(element.halfAngle3)- r_dr * element.radius * ...
                cos(element.recedingContactAngle + element.halfAngle3)/sin(element.halfAngle3));
            A(5) = (cos(element.advancingContactAngle)*cot(element.halfAngle2)-sin(element.advancingContactAngle)) / ...
                (cot(element.halfAngle2)+cot(element.halfAngle3)- r_dr * element.radius * ...
                cos(element.recedingContactAngle + element.halfAngle3)/sin(element.halfAngle3));
            if element.advancingContactAngle > pi/2 - element.halfAngle2
                A(6) = Pc_max_drainage * cos(element.advancingContactAngle + element.halfAngle2) / ...
                    cos(element.recedingContactAngle + element.halfAngle2);
            elseif element.advancingContactAngle > pi/2 - element.halfAngle3
                A(7) = Pc_max_drainage * cos(element.advancingContactAngle + element.halfAngle3) / ...
                    cos(element.recedingContactAngle + element.halfAngle3);
            end
            max_A = max(A);
            element.imbThresholdPressure_SnapOff = element.IFT_NperMeter /element.radius * max_A;
        else  % Forced imbibition part
            element.imbThresholdPressure_SnapOff = Pc_max_drainage * cos(element.advancingContactAngle + element.halfAngle1) / ...
                cos(element.recedingContactAngle + element.halfAngle1);
        end
        
    else % elemnt is square
        if element.advancingContactAngle <= pi/4 %Spontaneous Imbibition
            element.imbThresholdPressure_SnapOff = element.IFT_NperMeter / element.radius * ...
                (cos(element.advancingContactAngle)-sin(element.advancingContactAngle));
            % Forced imbibition part
        elseif element.advancingContactAngle > pi/4 && element.advancingContactAngle <= 3*pi/4
            element.imbThresholdPressure_SnapOff = Pc_max_drainage*cos(element.advancingContactAngle + pi/4)/...
                cos(element.recedingContactAngle + pi/4);
        elseif element.advancingContactAngle > 3*pi/4
            element.imbThresholdPressure_SnapOff = -Pc_max_drainage/cos(element.recedingContactAngle + pi/4);
        end
    end
end
end