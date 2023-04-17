function calculateThresholdPressurePoreBodyFilling_Blunt2 (element,network)
% Based on Blunt2, book 2017 Page 135
if element.advancingContactAngle < pi/2
element.nonWettingLayerExist(1,:) = nan;
W =1/network.averageThroatRadius; % for Berea should be 15000; %m^(-1) based on Blunt2, book 2017 Page 135, inversed of an averaged throat size
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
    randNo =rand(1,z);
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