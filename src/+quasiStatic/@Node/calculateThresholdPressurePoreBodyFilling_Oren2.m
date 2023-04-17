function calculateThresholdPressurePoreBodyFilling_Oren2 (element,network)
% Based on Oren2
if element.advancingContactAngle < pi/2
element.nonWettingLayerExist(1,:) = nan;
W = [0;0.5;1;2;5;10];
attachedThroats = element.connectedLinks;
nonWettingFilledAttachedThroats_radius = zeros(element.connectionNumber, 1);


z = 0;% number of nonWetting filled attached throats
for i = 1:element.connectionNumber
    if network.Links{attachedThroats(i)}.occupancy == 'B'
        nonWettingFilledAttachedThroats_radius (i) = network.Links{attachedThroats(i)}.radius;
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
        randNumber = randNo(ii); 
        if z > 5
            w = W(6);
        else
            w = W(z);
        end 
        nominator = nominator + randNumber * w *  nonWettingFilledAttachedThroats_radius(ii,1);
    end
    element.imbThresholdPressure_PoreBodyFilling = (1 + 2 * sqrt(pi * element.shapeFactor))*element.IFT_NperMeter * cos(element.advancingContactAngle)/...
        (element.radius + nominator);
end
else
    element.imbThresholdPressure_PoreBodyFilling = 2*element.IFT_NperMeter * cos(element.advancingContactAngle)/element.radius;
end   

end
  