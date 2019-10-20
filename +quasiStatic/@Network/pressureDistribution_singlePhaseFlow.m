%% Pressure distribution calculation of single phase flow
function pressureDistribution_singlePhaseFlow (obj, inletPressure, outletPressure)
Factor = zeros(obj.numberOfNodes, obj.numberOfNodes);
B = zeros(obj.numberOfNodes, 1);

for ii = 1:obj.numberOfLinks
    
    node1Index = obj.Links{ii}.pore1Index;
    node2Index = obj.Links{ii}.pore2Index;
    
    % if the link is connected to inlet (index of node 1 is -1 which does not exist)
    if obj.Links{ii}.isInlet
        obj.Links{ii}.nodeLinkSystemConductanceSinglePhase = ((obj.Links{ii}.linkLength /...
            obj.Links{ii}.conductanceSinglePhase) +...
            ((obj.Links{ii}.pore2Length / obj.Nodes{node2Index}.conductanceSinglePhase)))^-1;
        
        Factor(node2Index, node2Index) = Factor(node2Index, node2Index) + obj.Links{ii}.nodeLinkSystemConductanceSinglePhase;
        B(node2Index) = obj.Links{ii}.nodeLinkSystemConductanceSinglePhase * inletPressure;
        
        % if the link is connected to outlet (index of node 2 is 0 which does not exist)
    elseif obj.Links{ii}.isOutlet
        obj.Links{ii}.nodeLinkSystemConductanceSinglePhase = ( (obj.Links{ii}.linkLength /...
            obj.Links{ii}.conductanceSinglePhase) +...
            ((obj.Links{ii}.pore1Length / obj.Nodes{node1Index}.conductanceSinglePhase)))^-1;
        Factor(node1Index, node1Index) = Factor(node1Index, node1Index) + obj.Links{ii}.nodeLinkSystemConductanceSinglePhase;
        B(node1Index) = obj.Links{ii}.nodeLinkSystemConductanceSinglePhase * outletPressure;
        
        %if the link is neither inlet nor outlet
    else
        obj.Links{ii}.nodeLinkSystemConductanceSinglePhase = ((obj.Links{ii}.linkLength /...
            obj.Links{ii}.conductanceSinglePhase) +...
            ((obj.Links{ii}.pore1Length / obj.Nodes{node1Index}.conductanceSinglePhase) +...
            (obj.Links{ii}.pore2Length / obj.Nodes{node2Index}.conductanceSinglePhase)))^-1;
        
        Factor(node1Index, node1Index) = Factor(node1Index, node1Index) + obj.Links{ii}.nodeLinkSystemConductanceSinglePhase;
        Factor(node2Index, node2Index) = Factor(node2Index, node2Index) + obj.Links{ii}.nodeLinkSystemConductanceSinglePhase;
        Factor(node1Index, node2Index) = Factor(node1Index, node2Index) - obj.Links{ii}.nodeLinkSystemConductanceSinglePhase;
        Factor(node2Index, node1Index) = Factor(node2Index, node1Index) - obj.Links{ii}.nodeLinkSystemConductanceSinglePhase;
        
    end
end

% using GMRES method to solve the pressure distribution
nodesPressure = gmres(Factor, B,[], 1e-10, obj.numberOfNodes);

%assign the pressure values to each node
for ii = 1:obj.numberOfNodes
    if nodesPressure(ii) > inletPressure
        obj.Nodes{ii}.waterPressure = inletPressure;
    elseif nodesPressure(ii) < outletPressure
        obj.Nodes{ii}.waterPressure = outletPressure;
    else
        obj.Nodes{ii}.waterPressure = nodesPressure(ii);
    end
end

%assign pressure values to links, since the surface where
%flowrate is calculated through might pass through the links
for ii = 1:obj.numberOfLinks
    if obj.Links{ii}.isInlet
        obj.Links{ii}.waterPressure =...
            (1+obj.Nodes{obj.Links{ii}.pore2Index}.waterPressure)/2;
    elseif obj.Links{ii}.isOutlet
        obj.Links{ii}.waterPressure =...
            obj.Nodes{obj.Links{ii}.pore1Index}.waterPressure/2;
    else
        obj.Links{ii}.waterPressure =...
            (obj.Nodes{obj.Links{ii}.pore1Index}.waterPressure + ...
            obj.Nodes{obj.Links{ii}.pore2Index}.waterPressure) / 2;
    end
end

end