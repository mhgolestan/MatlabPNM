% Clearing the workspace
clear 
close all
% clearing the current window
clc

% Sum two numbers with MATLAB
%
% Parameters
% ----------
%   a: double
%       Input value 1
%   b: double
%       Input value 2
%
% Returns
% -------
%   The input values summed
%
% Example
% -------
% sumNumbers_matlab(2,2)

%% Flow module
import quasiStatic.*

% Crearing an object of the network
networkFileName = 'simple_9_homogen_highAR';  
network = Network(networkFileName);

%% Calculating network propeties and running single-phase flow

network.name = networkFileName;

network.visualization = true; % Paraview visualization, single phase pressure distribution if calculatePressureDistribution!
network.calculateSinglePhasePressureDistribution = true;
if network.calculateSinglePhasePressureDistribution
    network.inletPressure_Pa  = 1;
    network.outletPressure_Pa = 0;
end 

network.IO.output_networkStochasticAndPlotInfo_singlePhaseFlow(network); 
  
%% Two-phase flow simulations

network.max_Pc_Pa = 10000;
network.min_Pc_Pa = -10000;
network.deltaS_input = 0.1;
network.NoOfPc_interval = 10;
network.randSeed = 0;

% typeOfPoreBodyFillingAlgorithm = {Blunt1, Blunt2, Oren1, Oren2, Patzek, Valvatne (uses absolute permeability)}
network.typeOfPoreBodyFillingAlgorithm = 'Valvatne'; 

network.calculateRelativePermeability = true;
network.recedingContactAngle = 0*pi/180;
network.advancingContactAngle = 0*pi/180;
network.flowVisualization = true;

if network.calculateRelativePermeability
    network.inletPressure_Pa  = 1;
    network.outletPressure_Pa = 0;    
end

% Calculationg capillary pressure & relative permeability during Primary Drainage
fprintf('================================ Drainage Start =========================================\n'); 
% network.primaryDrainage();  
network.primaryDrainage_20191207();      
% network.IO.output_networkStochasticAndPlotInfo_twoPhaseFlow(network); 

% Calculationg capillary pressure & relative permeability during Secondary Imbibition
fprintf('================================ Imbibition Start =======================================\n'); 
% network.secondaryImbibition(); 
network.secondaryImbibition_20191207(); 
% network.secondaryImbibition_20191207new(); 
network.IO.output_networkStochasticAndPlotInfo_twoPhaseFlow(network); 
 
