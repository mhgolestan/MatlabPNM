function calculateThresholdPressurePoreBodyFilling_Patzek (element,network)
% Based on Patzek: eqs 42-49
element.oilLayerExist(1,:) = nan;
W = [0;0.72;0.45;1.2;1.5;5];
attachedThroats = element.connectedLinks;

z = 0;% number of oil filled attached throats
for i = 1:element.connectionNumber
    if network.Links{attachedThroats(i)}.occupancy == 'B'
        z=z+1;
    end
end

if z == 0
    element.imbThresholdPressure_PoreBodyFilling = nan;
elseif z == 1
    %              element.calculateThresholdPressurePistonLike_Imbibition(network.Pc_drain_max);
    element.imbThresholdPressure_PoreBodyFilling = element.imbThresholdPressure_PistonLike;
else
    if z > 5
        w = W(6);
    else
        w = W(z);
    end
    nominator = 0;
    denominator = 0;
    sumOfThroatRadius = 0;
    for ii = 1:z
        randNumber = rand;
        sumOfThroatRadius = sumOfThroatRadius + network.Links{oilFilledAttachedThroats(ii)}.radius;
        nominator = nominator + randNumber * sumOfThroatRadius;
        denominator = denominator + randNumber;
    end
    R_ave = (element.radius + w * nominator / denominator)/cos(element.advancingContactAngle);
    element.imbThresholdPressure_PoreBodyFilling = 2*element.sig_ow/R_ave;
end
end