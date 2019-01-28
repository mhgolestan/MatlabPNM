% Clearing the workspace
clear
% clearing the current window
clc
% Getting the working directory
currentFoldet = pwd;

networkFileName = 'C1';
networkFileFullPath = strcat(currentFoldet, '\Input\NetworkDataFile\' , networkFileName);


% Pressure difference
inletPressure = 1;
outletPressure = 0;

network = Network(networkFileFullPath);
network.calculatePorosity();
fprintf('Porosity of the model is: %3.5f \n', network.Porosity);

% network.pressureDistribution(1,0);
% network.calculateAbsolutePermeability();
% fprintf('%3.5f \n', network.absolutePermeability)
% network.calculateRelativePermeability();
network.PrimaryDrainage();

press = zeros(network.numberOfNodes,1);
x = zeros(network.numberOfNodes,1);
index = zeros(network.numberOfNodes,1);
for ii = 1:network.numberOfNodes
    if network.Nodes{ii}.y_coordinate == network.Nodes{1}.y_coordinate
    press(ii) = network.Nodes{ii}.waterPressure;
    index(ii) = network.Nodes{ii}.index;
    x(ii) = network.Nodes{ii}.x_coordinate;
    end
end
plot(x, press, '*')