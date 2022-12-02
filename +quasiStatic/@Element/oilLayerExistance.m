function oilLayerExistance(element)

if strcmp(element.geometry , 'Circle')== 1
    element.oilLayerExist(1,:) = nan;
else
    halfAngles = [element.halfAngle1, element.halfAngle2,element.halfAngle3, element.halfAngle4];
    for i = 1:4
        if ~isnan(halfAngles(i)) && element.advancingContactAngle >= pi/2 + halfAngles(i)
            element.oilLayerExist(1,i) = 1;
        end
    end
end
end