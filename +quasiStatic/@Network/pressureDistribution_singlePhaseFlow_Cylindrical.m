function pressureDistribution_singlePhaseFlow_Cylindrical (network, inletPressure, outletPressure)
% Pressure distribution calculation in Cylindrical pore_Single-Phase
Factor = zeros(network.numberOfNodes, network.numberOfNodes);
B = zeros(network.numberOfNodes, 1);

for ii = 1:network.numberOfLinks
    
    node1Index = network.Links{ii}.pore1Index;
    node2Index = network.Links{ii}.pore2Index;
    
    % Calculate conductance based on Raoof thesis
    network.Links{ii}.cylindricalConductanceSinglePhase = pi * network.Links{ii}.radius ^ 4 /...
        (8 * network.waterViscosity * network.Links{ii}.length);
    
    % if the link is connected to inlet (index of node 1 is -1 which does not exist)
    if network.Links{ii}.isInlet
        
        Factor(node2Index, node2Index) = Factor(node2Index, node2Index) + ...
            network.Links{ii}.cylindricalConductanceSinglePhase;
        B(node2Index) = network.Links{ii}.cylindricalConductanceSinglePhase * inletPressure;
        
        % if the link is connected to outlet (index of node 2 is 0 which does not exist)
    elseif network.Links{ii}.isOutlet
        
        Factor(node1Index, node1Index) = Factor(node1Index, node1Index) + ...
            network.Links{ii}.cylindricalConductanceSinglePhase;
        B(node1Index) = network.Links{ii}.cylindricalConductanceSinglePhase * outletPressure;
        
        %if the link is neither inlet nor outlet
    else
        Factor(node1Index, node1Index) = Factor(node1Index, node1Index) + ...
            network.Links{ii}.cylindricalConductanceSinglePhase;
        Factor(node2Index, node2Index) = Factor(node2Index, node2Index) + ...
            network.Links{ii}.cylindricalConductanceSinglePhase;
        Factor(node1Index, node2Index) = Factor(node1Index, node2Index) - ...
            network.Links{ii}.cylindricalConductanceSinglePhase;
        Factor(node2Index, node1Index) = Factor(node2Index, node1Index) - ...
            network.Links{ii}.cylindricalConductanceSinglePhase;
    end
end

% using GMRES method to solve the pressure distribution
nodesPressure = gmres(Factor, B,[], 1e-7, network.numberOfNodes);

%assign the pressure values to each node
for ii = 1:network.numberOfNodes
    if nodesPressure(ii) > inletPressure
        network.Nodes{ii}.waterPressure = inletPressure;
    elseif nodesPressure(ii) < outletPressure
        network.Nodes{ii}.waterPressure = outletPressure;
    else
        network.Nodes{ii}.waterPressure = nodesPressure(ii);
    end
end

%assign pressure values to links, since the surface where
%flowrate is calculated through might pass through the links
for ii = 1:network.numberOfLinks
    if network.Links{ii}.isInlet
        network.Links{ii}.waterPressure =...
            (1+network.Nodes{network.Links{ii}.pore2Index}.waterPressure)/2;
    elseif network.Links{ii}.isOutlet
        network.Links{ii}.waterPressure =...
            network.Nodes{network.Links{ii}.pore1Index}.waterPressure/2;
    else
        network.Links{ii}.waterPressure =...
            (network.Nodes{network.Links{ii}.pore1Index}.waterPressure + ...
            network.Nodes{network.Links{ii}.pore2Index}.waterPressure) / 2;
    end
end

end
