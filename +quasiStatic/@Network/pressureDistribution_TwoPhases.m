% Pressure distribution calculation in pore_Two-Phases
function pressureDistribution_TwoPhases(network, inletPressure, outletPressure)

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
            network.Links{ii}.oilConductance) +...
            ((network.Links{ii}.pore2Length / network.Nodes{node2Index}.oilConductance)))^-1;
        
        Factor_O(node2Index, node2Index) = Factor_O(node2Index, node2Index) + network.Links{ii}.nodeLinkSystemConductance_O;
        B_O(node2Index) = network.Links{ii}.nodeLinkSystemConductance_O * inletPressure;
        
        network.Links{ii}.nodeLinkSystemConductance_W = ((network.Links{ii}.linkLength /...
            network.Links{ii}.waterConductance) +...
            ((network.Links{ii}.pore2Length / network.Nodes{node2Index}.waterConductance)))^-1;
        
        Factor_W(node2Index, node2Index) = Factor_W(node2Index, node2Index) + network.Links{ii}.nodeLinkSystemConductance_W;
        B_W(node2Index) = network.Links{ii}.nodeLinkSystemConductance_W * inletPressure;
        
        % if the link is connected to outlet (index of node 2 is 0 which does not exist)
    elseif network.Links{ii}.isOutlet
        
        network.Links{ii}.nodeLinkSystemConductance_O = ( (network.Links{ii}.linkLength /...
            network.Links{ii}.oilConductance) +...
            ((network.Links{ii}.pore1Length / network.Nodes{node1Index}.oilConductance)))^-1;
        
        Factor_O(node1Index, node1Index) = Factor_O(node1Index, node1Index) + network.Links{ii}.nodeLinkSystemConductance_O;
        B_O(node1Index) = network.Links{ii}.nodeLinkSystemConductance_O * outletPressure;
        
        network.Links{ii}.nodeLinkSystemConductance_W = ( (network.Links{ii}.linkLength /...
            network.Links{ii}.waterConductance) +...
            ((network.Links{ii}.pore1Length / network.Nodes{node1Index}.waterConductance)))^-1;
        
        Factor_W(node1Index, node1Index) = Factor_W(node1Index, node1Index) + network.Links{ii}.nodeLinkSystemConductance_W;
        B_W(node1Index) = network.Links{ii}.nodeLinkSystemConductance_W * outletPressure;
        
        %if the link is neither inlet nor outlet
    else
        network.Links{ii}.nodeLinkSystemConductance_W = ((network.Links{ii}.linkLength /...
            network.Links{ii}.waterConductance) +...
            ((network.Links{ii}.pore1Length / network.Nodes{node1Index}.waterConductance) +...
            (network.Links{ii}.pore2Length / network.Nodes{node2Index}.waterConductance)))^-1;
        
        Factor_W(node1Index, node1Index) = Factor_W(node1Index, node1Index) + network.Links{ii}.nodeLinkSystemConductance_W;
        Factor_W(node2Index, node2Index) = Factor_W(node2Index, node2Index) + network.Links{ii}.nodeLinkSystemConductance_W;
        Factor_W(node1Index, node2Index) = Factor_W(node1Index, node2Index) - network.Links{ii}.nodeLinkSystemConductance_W;
        Factor_W(node2Index, node1Index) = Factor_W(node2Index, node1Index) - network.Links{ii}.nodeLinkSystemConductance_W;
        
        network.Links{ii}.nodeLinkSystemConductance_O = ((network.Links{ii}.linkLength /...
            network.Links{ii}.oilConductance) +...
            ((network.Links{ii}.pore1Length / network.Nodes{node1Index}.oilConductance) +...
            (network.Links{ii}.pore2Length / network.Nodes{node2Index}.oilConductance)))^-1;
        Factor_O(node1Index, node1Index) = Factor_O(node1Index, node1Index) + network.Links{ii}.nodeLinkSystemConductance_O;
        Factor_O(node2Index, node2Index) = Factor_O(node2Index, node2Index) + network.Links{ii}.nodeLinkSystemConductance_O;
        Factor_O(node1Index, node2Index) = Factor_O(node1Index, node2Index) - network.Links{ii}.nodeLinkSystemConductance_O;
        Factor_O(node2Index, node1Index) = Factor_O(node2Index, node1Index) - network.Links{ii}.nodeLinkSystemConductance_O;
    end
end

% using Preconditioned conjugate gradients method to solve the
% pressure distribution 
nodesWaterPressure = gmres(Factor_W, B_W,[], 1e-10, network.numberOfNodes);
nodesOilPressure = gmres(Factor_O, B_O,[], 1e-10, network.numberOfNodes); 
%             nodesWaterPressure = pcg(Factor_W, B_W, 1e-7, 1000);
%             nodesOilPressure = pcg(Factor_O, B_O, 1e-7, 1000);
%assign the pressure values to each node
for ii = 1:network.numberOfNodes
    if nodesWaterPressure(ii)> inletPressure
        network.Nodes{ii}.waterPressure = inletPressure;
    elseif nodesWaterPressure(ii)< outletPressure
        network.Nodes{ii}.waterPressure = outletPressure;
    else
        network.Nodes{ii}.waterPressure = nodesWaterPressure(ii);
    end
    if nodesOilPressure(ii)> inletPressure
        network.Nodes{ii}.oilPressure = inletPressure;
    elseif nodesOilPressure(ii)< outletPressure
        network.Nodes{ii}.oilPressure = outletPressure;
    else
        network.Nodes{ii}.oilPressure = nodesOilPressure(ii);
    end
end

%assign pressure values to links, since the surface where
%flowrate is calculated through might pass through the links
for ii = 1:network.numberOfLinks
    if network.Links{ii}.isInlet
        network.Links{ii}.waterPressure =...
            (1+network.Nodes{network.Links{ii}.pore2Index}.waterPressure)/2;
        network.Links{ii}.oilPressure =...
            (1+network.Nodes{network.Links{ii}.pore2Index}.oilPressure)/2;
    elseif network.Links{ii}.isOutlet
        network.Links{ii}.waterPressure =...
            network.Nodes{network.Links{ii}.pore1Index}.waterPressure/2;
        network.Links{ii}.oilPressure =...
            network.Nodes{network.Links{ii}.pore1Index}.oilPressure/2;
    else
        network.Links{ii}.waterPressure =...
            (network.Nodes{network.Links{ii}.pore1Index}.waterPressure + ...
            network.Nodes{network.Links{ii}.pore2Index}.waterPressure) / 2;
        network.Links{ii}.oilPressure =...
            (network.Nodes{network.Links{ii}.pore1Index}.oilPressure + ...
            network.Nodes{network.Links{ii}.pore2Index}.oilPressure) / 2;
    end
end 