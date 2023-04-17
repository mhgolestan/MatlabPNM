%% Flow rate calculation for each phase in the netwrok
function calculateFlowRate(network)
% Fluid = wettingPhase
calculatePressureDistribution_singlePhaseFlow(network);

% calculate flow rate in Inlet_Links
network.totalFlowRate_m3PerS = 0;
for ii = 1:network.numberOfLinks
    
    node1Index = network.Links{ii}.pore1Index;
    
    if network.Links{ii}.isOutlet
        
        % calculate the flow rate of the fluid
        network.totalFlowRate_m3PerS = network.totalFlowRate_m3PerS + ...
            network.Links{ii}.nodeLinkSystemConductanceSinglePhase * ...
            (network.Nodes{node1Index}.wettingPhasePressure - network.outletPressure_Pa);
    end
end

% calculate velocity_mPerS through the network
network.velocity_mPerS = network.totalFlowRate_m3PerS/(network.yDimension_m * network.zDimension_m);

% for quasi-static, capillaryNumber must be less than 10e-4
network.capillaryNumber = network.wettingPhase_Viscosity_PaS * network.velocity_mPerS/ network.IFT_NperMeter;
end
