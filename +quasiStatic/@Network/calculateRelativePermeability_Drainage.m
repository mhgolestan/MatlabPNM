
function [krw, kro] = calculateRelativePermeability_Drainage(network, outletPressure, LinkL, LinkL_W, cluster_A_nums, cluster_A)

waterFlowRate = 0;
oilFlowRate = 0;

%search through all the links
for ii = 1:network.numberOfLinks
    
    node1Index = network.Links{ii}.pore1Index;
    if network.Links{ii}.isOutlet
        
        % calculate the flow rate of the fluid
        %                         if any(LinkL_W(ii) == cluster_A(:))
        waterFlowRate = waterFlowRate + ...
            network.Links{ii}.nodeLinkSystemConductance_W * ...
            (network.Nodes{node1Index}.waterPressure - outletPressure);
        %                         end
        
        %                         if any(LinkL(ii) == cluster_A_nums(:))
        % calculate the flow rate of the fluid
        oilFlowRate = oilFlowRate + ...
            network.Links{ii}.nodeLinkSystemConductance_O * ...
            (network.Nodes{node1Index}.oilPressure - outletPressure);
        %                         end
    end
end
krw = waterFlowRate/network.totalFlowRate;
if krw > 1
    krw = 1;
elseif krw <0
    krw = 0;
end
kro = oilFlowRate * network.oilViscosity/network.totalFlowRate / network.waterViscosity;
if kro > 1
    kro = 1;
elseif kro <0
    kro = 0;
end