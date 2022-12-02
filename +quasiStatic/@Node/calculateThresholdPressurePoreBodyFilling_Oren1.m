function calculateThresholdPressurePoreBodyFilling_Oren1 (element,network)
% Based on Oren1
element.oilLayerExist(1,:) = nan;
W = [0;0.5;1;2;5;10];
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
    nominator = 0;
    for ii = 1:z
        if z > 5
            w = W(6);
        else
            w = W(z);
        end
        randNumber = rand;
        nominator = nominator + randNumber * w * network.Links{oilFilledAttachedThroats(ii,1)}.radius;
    end
    element.imbThresholdPressure_PoreBodyFilling = 2*element.sig_ow * cos(element.advancingContactAngle)/(element.radius + nominator);
end
end