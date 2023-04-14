function calculateThresholdPressureSnapOff_Valvatne(element,Pc_max_drainage)
if strcmp(element.geometry , 'Circle')== 1
    element.imbThresholdPressure_SnapOff = nan;
else 
    halfAngles = [element.halfAngle1, element.halfAngle2,element.halfAngle3, element.halfAngle4];
    maxAdvAngle = pi/2 - min(halfAngles);
    if strcmp(element.geometry , 'Triangle')== 1
        if element.advancingContactAngle < maxAdvAngle %Spontaneous Imbibition
            Pc_a = element.IFT_NperMeter / element.radius *(cos(element.advancingContactAngle)-...
                2*sin(element.advancingContactAngle)/(cot(element.halfAngle1)+cot(element.halfAngle2)));
            Pc_b = element.IFT_NperMeter / element.radius *...
                (cos(element.advancingContactAngle)*cot(element.halfAngle1)-sin(element.advancingContactAngle)+...
                cos(element.recedingContactAngle)*cot(element.halfAngle3)-sin(element.recedingContactAngle))/...
                ((cot(element.halfAngle1)+cot(element.halfAngle2)));
            element.imbThresholdPressure_SnapOff = max(Pc_a,Pc_b);
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
        % elemnt is square
        if element.advancingContactAngle <= pi/4
            %eq C34
            element.imbThresholdPressure_SnapOff = element.IFT_NperMeter / element.radius * ...
                (cot(pi/4)*cos(element.advancingContactAngle)-sin(element.advancingContactAngle));
        elseif element.advancingContactAngle > pi/4 && element.advancingContactAngle <= 3*pi/4
            element.imbThresholdPressure_SnapOff = Pc_max_drainage*cos(element.advancingContactAngle + pi/4)/...
                cos(element.recedingContactAngle + pi/4);
            if element.imbThresholdPressure_SnapOff > 0
                element.imbThresholdPressure_SnapOff = -1 *element.imbThresholdPressure_SnapOff;
            end
        elseif element.advancingContactAngle > 3*pi/4
            element.imbThresholdPressure_SnapOff = -Pc_max_drainage/cos(element.recedingContactAngle + min(halfAngles));
        end
    end
end
end