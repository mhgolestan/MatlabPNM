function calculateConductance_and_Saturation_Drainage(network, Pc)
Pc = abs(Pc);
waterVolume = 0;
vol = 0;

for i = 1:network.numberOfNodes
    network.Nodes{i}.calculateConductance_Drainage(Pc);
    
    % Water Saturation Calculation
    if ~network.Nodes{i}.isInlet && ~network.Nodes{i}.isOutlet
        waterVolume = waterVolume + (network.Nodes{i}.waterCrossSectionArea )...
            / network.Nodes{i}.area *network.Nodes{i}.volume + network.Nodes{i}.clayVolume;
        vol = vol + network.Nodes{i}.volume + network.Nodes{i}.clayVolume;
    end
end
for i = 1:network.numberOfLinks
    network.Links{i}.calculateConductance_Drainage(Pc);
    
    % Water Saturation Calculation
    if ~network.Links{i}.isInlet && ~network.Links{i}.isOutlet
        waterVolume = waterVolume + (network.Links{i}.waterCrossSectionArea )...
            / network.Links{i}.area * network.Links{i}.volume + network.Links{i}.clayVolume;
        vol = vol + network.Links{i}.volume + network.Links{i}.clayVolume;
    end
end
network.waterSaturation = waterVolume / vol;