clc; clear
fileName = 'Berea';

% Pressure difference
inletPressure = 1;
outletPressure = 0;

network = Network(fileName);
% network.calculatePorosity();
% fprintf('Porosity of the model is: %3.5f \n', network.Porosity);
 
network.pressureDistribution(1,0);
network.calculateAbsolutePermeability();
% network.calculateRelativePermeability();
% network.PrimaryDrainage();

press = zeros(network.numberOfNodes,1);
x = zeros(network.numberOfNodes,1);
for ii = 1:network.numberOfNodes
    press(ii) = network.Nodes{ii}.waterPressure;
    x(ii) = network.Nodes{ii}.x_coordinate;
end
plot(x, press, '*')