function [krw, kro] = calculateRelativePermeability_Imbibition (network, outletPressure_Pa, LinkL, LinkL_W, cluster_A_nums, cluster_A)

wettingPhaseFlowRate = 0;
nonWettingFlowRate = 0;
%search through all the links
for ii = 1:network.numberOfLinks
    
    node1Index = network.Links{ii}.pore1Index;
    if network.Links{ii}.isOutlet
        % calculate the flow rate of the fluid
        if any(LinkL_W(ii) == cluster_A(:))
            wettingPhaseFlowRate = wettingPhaseFlowRate + ...
                abs(network.Links{ii}.nodeLinkSystemConductance_W * ...
                (outletPressure_Pa - network.Nodes{node1Index}.wettingPhasePressure));
        end
        % calculate the flow rate of the fluid
        if any(LinkL(ii) == cluster_A_nums(:))
            nonWettingFlowRate = nonWettingFlowRate + ...
                abs(network.Links{ii}.nodeLinkSystemConductance_O * ...
                (outletPressure_Pa - network.Nodes{node1Index}.nonWettingPressure));
        end
    end
    
end
krw = wettingPhaseFlowRate/network.totalFlowRate_m3PerS;
if krw > 1
    krw = 1;
elseif krw <0
    krw = 0;
end
kro = nonWettingFlowRate * network.nonWettingPhase_Viscosity_PaS/network.totalFlowRate_m3PerS / network.wettingPhase_Viscosity_PaS;
if kro > 1
    kro = 1;
elseif kro <0
    kro = 0;
end
end