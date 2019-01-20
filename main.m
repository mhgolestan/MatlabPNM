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
<<<<<<< HEAD
% network.PrimaryDrainage();
||||||| merged common ancestors
network.PrimaryDrainage();
=======
% network.PrimaryDrainage();

press = zeros(network.numberOfNodes,1);
x = zeros(network.numberOfNodes,1);
for ii = 1:network.numberOfNodes
    press(ii) = network.Nodes{ii}.waterPressure;
    x(ii) = network.Nodes{ii}.x_coordinate;
end
plot(x, press, '*')
>>>>>>> 42f52909bcdc50e7fda9a57d8d0d225859b0f03d
