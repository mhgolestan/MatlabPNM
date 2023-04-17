% Pressure distribution calculation in pore_Two-Phases
function calculatePressureDistribution_TwoPhases(network, inletPressure_Pa, outletPressure_Pa)

Factor_W = zeros(network.numberOfNodes, network.numberOfNodes);
B_W = zeros(network.numberOfNodes, 1);
Factor_O = zeros(network.numberOfNodes, network.numberOfNodes);
B_O = zeros(network.numberOfNodes, 1);

% calculation of pressure distribution
for ii = 1:network.numberOfLinks
    
    node1Index = network.Links{ii}.pore1Index;
    node2Index = network.Links{ii}.pore2Index;
    
    % if the link is connected to inlet (index of node 1 is -1 which does not exist)
    if network.Links{ii}.isInlet
        
        network.Links{ii}.nodeLinkSystemConductance_O = ((network.Links{ii}.linkLength /...
            network.Links{ii}.nonWettingConductance) +...
            ((network.Links{ii}.pore2Length / network.Nodes{node2Index}.nonWettingConductance)))^-1;
        
        Factor_O(node2Index, node2Index) = Factor_O(node2Index, node2Index) + network.Links{ii}.nodeLinkSystemConductance_O;
        B_O(node2Index) = network.Links{ii}.nodeLinkSystemConductance_O * inletPressure_Pa;
        
        network.Links{ii}.nodeLinkSystemConductance_W = ((network.Links{ii}.linkLength /...
            network.Links{ii}.wettingPhaseConductance) +...
            ((network.Links{ii}.pore2Length / network.Nodes{node2Index}.wettingPhaseConductance)))^-1;
        
        Factor_W(node2Index, node2Index) = Factor_W(node2Index, node2Index) + network.Links{ii}.nodeLinkSystemConductance_W;
        B_W(node2Index) = network.Links{ii}.nodeLinkSystemConductance_W * inletPressure_Pa;
        
        % if the link is connected to outlet (index of node 2 is 0 which does not exist)
    elseif network.Links{ii}.isOutlet
        
        network.Links{ii}.nodeLinkSystemConductance_O = ( (network.Links{ii}.linkLength /...
            network.Links{ii}.nonWettingConductance) +...
            ((network.Links{ii}.pore1Length / network.Nodes{node1Index}.nonWettingConductance)))^-1;
        
        Factor_O(node1Index, node1Index) = Factor_O(node1Index, node1Index) + network.Links{ii}.nodeLinkSystemConductance_O;
        B_O(node1Index) = network.Links{ii}.nodeLinkSystemConductance_O * outletPressure_Pa;
        
        network.Links{ii}.nodeLinkSystemConductance_W = ( (network.Links{ii}.linkLength /...
            network.Links{ii}.wettingPhaseConductance) +...
            ((network.Links{ii}.pore1Length / network.Nodes{node1Index}.wettingPhaseConductance)))^-1;
        
        Factor_W(node1Index, node1Index) = Factor_W(node1Index, node1Index) + network.Links{ii}.nodeLinkSystemConductance_W;
        B_W(node1Index) = network.Links{ii}.nodeLinkSystemConductance_W * outletPressure_Pa;
        
        %if the link is neither inlet nor outlet
    else
        network.Links{ii}.nodeLinkSystemConductance_W = ((network.Links{ii}.linkLength /...
            network.Links{ii}.wettingPhaseConductance) +...
            ((network.Links{ii}.pore1Length / network.Nodes{node1Index}.wettingPhaseConductance) +...
            (network.Links{ii}.pore2Length / network.Nodes{node2Index}.wettingPhaseConductance)))^-1;
        
        Factor_W(node1Index, node1Index) = Factor_W(node1Index, node1Index) + network.Links{ii}.nodeLinkSystemConductance_W;
        Factor_W(node2Index, node2Index) = Factor_W(node2Index, node2Index) + network.Links{ii}.nodeLinkSystemConductance_W;
        Factor_W(node1Index, node2Index) = Factor_W(node1Index, node2Index) - network.Links{ii}.nodeLinkSystemConductance_W;
        Factor_W(node2Index, node1Index) = Factor_W(node2Index, node1Index) - network.Links{ii}.nodeLinkSystemConductance_W;
        
        network.Links{ii}.nodeLinkSystemConductance_O = ((network.Links{ii}.linkLength /...
            network.Links{ii}.nonWettingConductance) +...
            ((network.Links{ii}.pore1Length / network.Nodes{node1Index}.nonWettingConductance) +...
            (network.Links{ii}.pore2Length / network.Nodes{node2Index}.nonWettingConductance)))^-1;
        Factor_O(node1Index, node1Index) = Factor_O(node1Index, node1Index) + network.Links{ii}.nodeLinkSystemConductance_O;
        Factor_O(node2Index, node2Index) = Factor_O(node2Index, node2Index) + network.Links{ii}.nodeLinkSystemConductance_O;
        Factor_O(node1Index, node2Index) = Factor_O(node1Index, node2Index) - network.Links{ii}.nodeLinkSystemConductance_O;
        Factor_O(node2Index, node1Index) = Factor_O(node2Index, node1Index) - network.Links{ii}.nodeLinkSystemConductance_O;
    end
end

% using Preconditioned conjugate gradients method to solve the
% pressure distribution 
nodesWaterPressure = gmres(Factor_W, B_W,[], 1e-10, network.numberOfNodes);
nodesnonWettingPhasePressure = gmres(Factor_O, B_O,[], 1e-10, network.numberOfNodes); 
%             nodesWaterPressure = pcg(Factor_W, B_W, 1e-7, 1000);
%             nodesnonWettingPhasePressure = pcg(Factor_O, B_O, 1e-7, 1000);
%assign the pressure values to each node
for ii = 1:network.numberOfNodes
    if nodesWaterPressure(ii)> inletPressure_Pa
        network.Nodes{ii}.wettingPhasePressure = inletPressure_Pa;
    elseif nodesWaterPressure(ii)< outletPressure_Pa
        network.Nodes{ii}.wettingPhasePressure = outletPressure_Pa;
    else
        network.Nodes{ii}.wettingPhasePressure = nodesWaterPressure(ii);
    end
    if nodesnonWettingPhasePressure(ii)> inletPressure_Pa
        network.Nodes{ii}.nonWettingPressure = inletPressure_Pa;
    elseif nodesnonWettingPhasePressure(ii)< outletPressure_Pa
        network.Nodes{ii}.nonWettingPressure = outletPressure_Pa;
    else
        network.Nodes{ii}.nonWettingPressure = nodesnonWettingPhasePressure(ii);
    end
end

%assign pressure values to links, since the surface where
%flowrate is calculated through might pass through the links
for ii = 1:network.numberOfLinks
    if network.Links{ii}.isInlet
        network.Links{ii}.wettingPhasePressure =...
            (1+network.Nodes{network.Links{ii}.pore2Index}.wettingPhasePressure)/2;
        network.Links{ii}.nonWettingPressure =...
            (1+network.Nodes{network.Links{ii}.pore2Index}.nonWettingPressure)/2;
    elseif network.Links{ii}.isOutlet
        network.Links{ii}.wettingPhasePressure =...
            network.Nodes{network.Links{ii}.pore1Index}.wettingPhasePressure/2;
        network.Links{ii}.nonWettingPressure =...
            network.Nodes{network.Links{ii}.pore1Index}.nonWettingPressure/2;
    else
        network.Links{ii}.wettingPhasePressure =...
            (network.Nodes{network.Links{ii}.pore1Index}.wettingPhasePressure + ...
            network.Nodes{network.Links{ii}.pore2Index}.wettingPhasePressure) / 2;
        network.Links{ii}.nonWettingPressure =...
            (network.Nodes{network.Links{ii}.pore1Index}.nonWettingPressure + ...
            network.Nodes{network.Links{ii}.pore2Index}.nonWettingPressure) / 2;
    end
end 