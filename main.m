% Clearing the workspace
clear
% clearing the current window
clc

import quasiStatic.*

% Getting the working directory
currentFoldet = pwd;

networkFileName = 'CARB'; 

% Pressure difference
inletPressure = 1;
outletPressure = 0;

% Crearing an object of the network
network = Network(networkFileName);

% Calculating network propeties by running single-phase flow
tic
network.calculateNetworkProperties(inletPressure, outletPressure);
network.networkInfo();
network.visualization('Initializing', 0);
toc  
 