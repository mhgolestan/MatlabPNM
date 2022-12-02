%% Pressure distribution calculation of single phase flow
function pressureDistribution_singlePhaseFlow (network, inletPressure, outletPressure)
Factor = zeros(network.numberOfNodes, network.numberOfNodes);
B = zeros(network.numberOfNodes, 1);

for ii = 1:network.numberOfLinks
    
    node1Index = network.Links{ii}.pore1Index;
    node2Index = network.Links{ii}.pore2Index;
    
    % if the link is connected to inlet (index of node 1 is -1 which does not exist)
    if network.Links{ii}.isInlet 
        network.Links{ii}.nodeLinkSystemConductanceSinglePhase = ((network.Links{ii}.linkLength /...
            network.Links{ii}.conductanceSinglePhase) +...
            ((network.Links{ii}.pore2Length / network.Nodes{node2Index}.conductanceSinglePhase)))^-1;
        
        Factor(node2Index, node2Index) = Factor(node2Index, node2Index) + network.Links{ii}.nodeLinkSystemConductanceSinglePhase;
        B(node2Index) = network.Links{ii}.nodeLinkSystemConductanceSinglePhase * inletPressure;
        
        % if the link is connected to outlet (index of node 2 is 0 which does not exist)
    elseif network.Links{ii}.isOutlet
        network.Links{ii}.nodeLinkSystemConductanceSinglePhase = ( (network.Links{ii}.linkLength /...
            network.Links{ii}.conductanceSinglePhase) +...
            ((network.Links{ii}.pore1Length / network.Nodes{node1Index}.conductanceSinglePhase)))^-1;
        Factor(node1Index, node1Index) = Factor(node1Index, node1Index) + network.Links{ii}.nodeLinkSystemConductanceSinglePhase;
        B(node1Index) = network.Links{ii}.nodeLinkSystemConductanceSinglePhase * outletPressure;
        
        %if the link is neither inlet nor outlet
    else 
        network.Links{ii}.nodeLinkSystemConductanceSinglePhase = ((network.Links{ii}.linkLength /...
            network.Links{ii}.conductanceSinglePhase) +...
            ((network.Links{ii}.pore1Length / network.Nodes{node1Index}.conductanceSinglePhase) +...
            (network.Links{ii}.pore2Length / network.Nodes{node2Index}.conductanceSinglePhase)))^-1;
        
        Factor(node1Index, node1Index) = Factor(node1Index, node1Index) + network.Links{ii}.nodeLinkSystemConductanceSinglePhase;
        Factor(node2Index, node2Index) = Factor(node2Index, node2Index) + network.Links{ii}.nodeLinkSystemConductanceSinglePhase;
        Factor(node1Index, node2Index) = Factor(node1Index, node2Index) - network.Links{ii}.nodeLinkSystemConductanceSinglePhase;
        Factor(node2Index, node1Index) = Factor(node2Index, node1Index) - network.Links{ii}.nodeLinkSystemConductanceSinglePhase;
        
    end
end

% using GMRES method to solve the pressure distribution
nodesPressure = gmres(Factor, B,[], 1e-10, network.numberOfNodes);

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