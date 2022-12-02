% Clearing the workspace
clear
% clearing the current window
clc

%% Flow
import quasiStatic.*

networkFileName = 'simple_9_homogen_highAR'; % for flow simulation 

% Pressure difference
inletPressure = 1;
outletPressure = 0;

% Crearing an object of the network
network = Network(networkFileName, inletPressure, outletPressure);
network.deltaS_input = 0.1;
network.Pc_interval = 10;%/network.deltaS_input; %20;
network.max_Pc = 10000;
network.min_Pc = -10000;

%% Calculating network propeties by running single-phase flow
tic
network.name = networkFileName;
network.calculateNetworkProperties(inletPressure, outletPressure);
network.networkStochastic(networkFileName); 
% network.networkInfoPlots('True');  
network.visualization(networkFileName,'Initializing',0) 
toc   

%% Two-phase flow simulations

% Calculationg capillary pressure & relative permeability during Primary Drainage
tic
fprintf('=============================== Drainage Start =====================================\n'); 
% network.PrimaryDrainage(inletPressure, outletPressure);  
network.PrimaryDrainage_20191207(inletPressure, outletPressure);  
% network.PrimaryDrainage_20191207new(inletPressure, outletPressure);   
toc 

% Calculationg capillary pressure & relative permeability during Secondary Imbibition
tic
fprintf('=============================== Imbibition Start =====================================\n'); 
network.SecondaryImbibition(inletPressure, outletPressure); 
toc 

%% Reactive
% Calculationg solute transport_Diffusion in singlePhase flow
% tic
% soluteConcentration = 1;
% poreVolumeInjected = network.poreVolume*1; 
% poreVolumeSimulation = network.poreVolume*2;
% fprintf('=============================== Diffusion Start =====================================\n'); 
% network.calculateReactiveTransport_SinglePhaseDiffusion(inletPressure, outletPressure, soluteConcentration, poreVolumeSimulation, poreVolumeInjected);
% fprintf('=============================== Desorption Start =====================================\n'); 
% network.calculateReactiveTransport_SinglePhaseDesorption(inletPressure, outletPressure, soluteConcentration, poreVolumeSimulation, poreVolumeInjected);
% toc
 