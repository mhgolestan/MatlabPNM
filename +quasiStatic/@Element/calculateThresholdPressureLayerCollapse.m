function calculateThresholdPressureLayerCollapse(element, Pc_max_drainage)

if strcmp(element.geometry , 'Circle')== 1
    element.imbThresholdPressure_LayerCollapse = nan(1,4);
else
    halfAngles = [element.halfAngle1, element.halfAngle2,element.halfAngle3, element.halfAngle4];
    if strcmp(element.geometry , 'Triangle')== 1
        nc = 3;
    elseif strcmp(element.geometry , 'Square')== 1
        nc = 4;
    end
    element.imbThresholdPressure_LayerCollapse = nan(1, 4); hingingAngles = zeros(1,4);   b_i = zeros(nc , 1);
    for i = 1:nc
        b_i(i) = element.sig_ow / Pc_max_drainage * cos(hingingAngles(i) + halfAngles(i))/sin(halfAngles(i));
        element.imbThresholdPressure_LayerCollapse(i) = element.sig_ow / b_i(i)*...
            (cot(halfAngles(i))+ (2*sin(halfAngles(i))*cos(element.advancingContactAngle))- ...
            sqrt((sin(element.advancingContactAngle))^2-4*sin(halfAngles(i))^2-4*sin(halfAngles(i))*cos(element.advancingContactAngle)));
    end
    
end
end