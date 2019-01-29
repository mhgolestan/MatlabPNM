function calculateAbsolutePermeability(obj)
    %AbsolutePermeability calculates the absolute permeability of
    %the network
    %   Detailed explanation goes here
    obj.pressureDistribution(1,0);
    obj.calculateFlowRate();
    % unit conversion from m2 to Darcy
%             unitConvertor = 1.01325E+15;
    % for pressure difference in the formula the corresponding
    % pressure drop between the vertical surfaces should be
    % calculated (based on Piri B1 formula)
%             obj.absolutePermeability = unitConvertor * obj.totalFlowRate * obj.xDimension / (obj.yDimension* obj.zDimension); %/ ()
    unitConvertor = 1.01325E+15;
    obj.absolutePermeability = unitConvertor * obj.totalFlowRate * obj.xDimension * obj.waterViscosity / (obj.yDimension * obj.zDimension); 
end
