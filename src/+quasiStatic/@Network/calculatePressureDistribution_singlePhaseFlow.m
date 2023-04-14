%% Pressure distribution calculation of single phase flow
function calculatePressureDistribution_singlePhaseFlow (network)
Factor = zeros(network.numberOfNodes, network.numberOfNodes);
B = zeros(network.numberOfNodes, 1);

for ii = 1:network.numberOfLinks
    
    node1Index = network.Links{ii}.pore1Index;
    node2Index = network.Links{ii}.pore2Index;
    
    % if the link is connected to inlet (index of node 1 is -1 which does not exist)
    if network.Links{ii}.isInlet 
        network.Links{ii}.nodeLinkSystemConductanceSinglePhase = ((network.Links{ii}.linkLength / network.Links{ii}.conductanceSinglePhase) +...
            ((network.Links{ii}.pore2Length / network.Nodes{node2Index}.conductanceSinglePhase)))^-1;
        
        Factor(node2Index, node2Index) = Factor(node2Index, node2Index) + network.Links{ii}.nodeLinkSystemConductanceSinglePhase;
        B(node2Index) = network.Links{ii}.nodeLinkSystemConductanceSinglePhase * network.inletPressure_Pa;
        
        % if the link is connected to outlet (index of node 2 is 0 which does not exist)
    elseif network.Links{ii}.isOutlet
        network.Links{ii}.nodeLinkSystemConductanceSinglePhase = ( (network.Links{ii}.linkLength / network.Links{ii}.conductanceSinglePhase) +...
            ((network.Links{ii}.pore1Length / network.Nodes{node1Index}.conductanceSinglePhase)))^-1;
        Factor(node1Index, node1Index) = Factor(node1Index, node1Index) + network.Links{ii}.nodeLinkSystemConductanceSinglePhase;
        B(node1Index) = network.Links{ii}.nodeLinkSystemConductanceSinglePhase * network.outletPressure_Pa;
        
        %if the link is neither inlet nor outlet
    else 
        network.Links{ii}.nodeLinkSystemConductanceSinglePhase = ((network.Links{ii}.linkLength / network.Links{ii}.conductanceSinglePhase) +...
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
    if nodesPressure(ii) > network.inletPressure_Pa
        warning ('Pressure distribution shows outrange pressure, then program enforce to have a pressure inside the boundary pressures!');         
        network.Nodes{ii}.wettingPhasePressure = network.inletPressure_Pa;
    elseif nodesPressure(ii) < network.outletPressure_Pa
        warning ('Pressure distribution shows outrange pressure, then program enforce to have a pressure inside the boundary pressures!'); 
        network.Nodes{ii}.wettingPhasePressure = network.outletPressure_Pa;
    else
        network.Nodes{ii}.wettingPhasePressure = nodesPressure(ii);
    end
end

%assign pressure values to links, since the surface where
%flowrate is calculated through might pass through the links
for ii = 1:network.numberOfLinks
    if network.Links{ii}.isInlet
        network.Links{ii}.wettingPhasePressure =...
            (network.inletPressure_Pa+network.Nodes{network.Links{ii}.pore2Index}.wettingPhasePressure)/2;
    elseif network.Links{ii}.isOutlet
        network.Links{ii}.wettingPhasePressure =...
            (network.Nodes{network.Links{ii}.pore1Index}.wettingPhasePressure+network.outletPressure_Pa)/2;
    else
        network.Links{ii}.wettingPhasePressure =...
            (network.Nodes{network.Links{ii}.pore1Index}.wettingPhasePressure + ...
            network.Nodes{network.Links{ii}.pore2Index}.wettingPhasePressure) / 2;
    end
end

end