function calculateThresholdPressurePoreBodyFilling_Blunt1 (element,network)
% Based on Blunt1
if element.advancingContactAngle < pi/2
element.nonWettingLayerExist(1,:) = nan;
W = [0;2.5;5;20;100];
attachedThroats = element.connectedLinks;

z = 0;% number of nonWetting filled attached throats
for i = 1:element.connectionNumber
    if network.Links{attachedThroats(i)}.occupancy == 'B'
        z=z+1;
    end
end

if z == 0
    element.imbThresholdPressure_PoreBodyFilling = nan;
elseif z == 1
    %              element.calculateThresholdPressurePistonLike_Imbibition(network.Pc_drain_max_Pa);
    element.imbThresholdPressure_PoreBodyFilling = element.imbThresholdPressure_PistonLike;
else
    nominator = 0;
    
    rng(network.randSeed);
    randNo = rand(1,z);
    for ii = 1:z
        if z > 5
            w = W(5);
        else
            w = W(z);
        end
        randNumber = randNo(ii);
        nominator = nominator + randNumber * w;
    end
    element.imbThresholdPressure_PoreBodyFilling = 2*element.IFT_NperMeter * cos(element.advancingContactAngle)/(element.radius + nominator);
end
else
    element.imbThresholdPressure_PoreBodyFilling = 2*element.IFT_NperMeter * cos(element.advancingContactAngle)/element.radius;
end   

end