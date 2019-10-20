%% AbsolutePermeability
function calculateAbsolutePermeability(obj, inletPressure, outletPressure)
calculateFlowRate(obj, inletPressure, outletPressure);
unitConvertor = 1/0.987*10^15; % unit conversion from m2 to miliDarcy
obj.absolutePermeability = unitConvertor * obj.velocity * obj.xDimension * obj.waterViscosity/ (inletPressure -outletPressure );
format longE
obj.absolutePermeability_m2 = obj.velocity * obj.xDimension * obj.waterViscosity/ (inletPressure -outletPressure );
end
