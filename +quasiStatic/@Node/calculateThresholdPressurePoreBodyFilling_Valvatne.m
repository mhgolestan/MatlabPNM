function calculateThresholdPressurePoreBodyFilling_Valvatne(element,network)
% Based on Valvatne
if element.advancingContactAngle < pi/2
element.nonWettingLayerExist(1,:) = nan;
W = 0.03/sqrt(network.absolutePermeability_mD/1.01325E+15);
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
    rng(network.randSeed);
    randNo = rand(1,z);
    nominator = 0;
    for ii = 1:z
        randNumber = randNo(ii);
        nominator = nominator + randNumber * W;
    end
    element.imbThresholdPressure_PoreBodyFilling = 2*element.IFT_NperMeter * cos(element.advancingContactAngle)/element.radius - element.IFT_NperMeter *nominator;
end
else
    element.imbThresholdPressure_PoreBodyFilling = 2*element.IFT_NperMeter * cos(element.advancingContactAngle)/element.radius;
end   

end