%% Flow rate calculation for each phase in the netwrok
function calculateFlowRate(obj, inletPressure, outletPressure)
% Fluid = water
pressureDistribution_singlePhaseFlow(obj, inletPressure,outletPressure);

% calculate flow rate in Inlet_Links
obj.totalFlowRate = 0;
for ii = 1:obj.numberOfLinks
    
    node1Index = obj.Links{ii}.pore1Index;
    
    if obj.Links{ii}.isOutlet
        
        % calculate the flow rate of the fluid
        obj.totalFlowRate = obj.totalFlowRate + ...
            obj.Links{ii}.nodeLinkSystemConductanceSinglePhase * ...
            (obj.Nodes{node1Index}.waterPressure - outletPressure);
    end
end

% calculate velocity through the network
obj.velocity = obj.totalFlowRate/(obj.yDimension * obj.zDimension);

% for quasi-static, capillaryNumber must be less than 10e-4
obj.capillaryNumber = obj.waterViscosity * obj.velocity/ obj.sig_ow;
end
