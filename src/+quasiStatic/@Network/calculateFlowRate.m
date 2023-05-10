function calculateFlowRate(network)

% Flow rate calculation for a single phase in the netwrok
%
% Parameters
% ----------
%   network: object form netwrok class
%       Input value 1
%
% Returns
% -------
%   The input object is used to apply boundary conditions and call the function to calaulate pressure distribution accross the network and calculate outflow form the right side of the 3D netwrok and return the result as the feature "totalFlowRate_m3PerS" of the network object
%
% Example
% -------
% calculateFlowRate(network)

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
