%% AbsolutePermeability
function calculateAbsolutePermeability(network)
calculateFlowRate(network);
unitConvertor = 1/0.987*10^15; % unit conversion from m2 to miliDarcy
network.absolutePermeability_mD = unitConvertor * network.velocity_mPerS * network.xDimension_m / (network.inletPressure_Pa -network.outletPressure_Pa );
format longE
network.absolutePermeability_m2 = network.velocity_mPerS * network.xDimension_m / (network.inletPressure_Pa -network.outletPressure_Pa );
end
