%% Network Properties calculation
function output_networkStochasticAndPlotInfo_singlePhaseFlow(obj, network)

%% Stocastics of network
network.ThSD = zeros(network.numberOfLinks,1);
network.ThSD_length = zeros(network.numberOfLinks,1);
network.PSD = zeros(network.numberOfNodes,1);
CoordinationNumber = zeros(network.numberOfNodes,1);
throatRadius = zeros(network.numberOfLinks,1);
network.numOfInletLinks = 0;
network.numOfOutletLinks = 0;
network.averageCoordinationNumber = 0;
network.numOfIsolatedElements = 0;
network.numOfTriangularElements = 0;
network.numOfCircularElements = 0;
network.numOfSquareElements = 0;
network.numOfTriangularPores = 0;
network.numOfCircularPores = 0;
network.numOfSquarePores = 0;
nodesVolume = 0;
linksVolume = 0;

for ii = 1:network.numberOfNodes
    network.Nodes{ii}.calculateElementsProperties
    nodesVolume = nodesVolume + (network.Nodes{ii}.volume);
    CoordinationNumber(ii,1) = network.Nodes{ii}.connectionNumber;
    network.PSD(ii,1) = 2 * network.Nodes{ii}.radius;
    %Isolated element
    if network.Nodes{ii}.connectionNumber == 0
        network.numOfIsolatedElements = network.numOfIsolatedElements + 1;
    end
    if strcmp(network.Nodes{ii}.geometry , 'Circle')== 1
        network.numOfCircularPores = network.numOfCircularPores+1;
        network.numOfCircularElements = network.numOfCircularElements+1;
    elseif strcmp(network.Nodes{ii}.geometry , 'Triangle')== 1
        network.numOfTriangularPores = network.numOfTriangularPores+1;
        network.numOfTriangularElements = network.numOfTriangularElements+1;
    else
        network.numOfSquarePores = network.numOfSquarePores+1;
        network.numOfSquareElements = network.numOfSquareElements+1;
    end
end

for ii = 1:network.numberOfLinks
    network.Links{ii}.calculateElementsProperties
    throatRadius(ii,1) = network.Links{ii}.radius;
    linksVolume = linksVolume + (network.Links{ii}.volume);
    network.ThSD (ii,1)= 2 * network.Links{ii}.radius;
    network.ThSD_length (ii,1)= network.Links{ii}.length;
    if network.Links{ii}.isInlet
        network.numOfInletLinks = network.numOfInletLinks + 1;
    elseif network.Links{ii}.isOutlet
        network.numOfOutletLinks = network.numOfOutletLinks+1;
    end
    if strcmp(network.Links{ii}.geometry , 'Circle')== 1
        network.numOfCircularElements = network.numOfCircularElements+1;
    elseif strcmp(network.Links{ii}.geometry , 'Triangle')== 1
        network.numOfTriangularElements = network.numOfTriangularElements+1;
    else
        network.numOfSquareElements = network.numOfSquareElements+1;
    end
end
network.numOfTriangularLinks = network.numOfTriangularElements - network.numOfTriangularPores;
network.numOfSquareLinks = network.numOfSquareElements - network.numOfSquarePores;
network.numOfCircularLinks = network.numOfCircularElements - network.numOfCircularPores;

network.averageCoordinationNumber = mean(CoordinationNumber);
network.averageThroatRadius = mean(throatRadius, 'all');
network.stdCoordinationNumber = std(CoordinationNumber);
network.maxCoordinationNumber = max(CoordinationNumber);
network.networkVolume_m3 = network.xDimension_m * network.yDimension_m * network.zDimension_m;
network.networkPoreVolume_m3 = linksVolume + nodesVolume;
network.porosity = network.networkPoreVolume_m3 / (network.xDimension_m * network.yDimension_m * network.zDimension_m);

if network.calculateSinglePhasePressureDistribution
    calculateAbsolutePermeability(network);
end

if network.visualization 
    network.IO.visualization(network,'Initializing',0) 
end

LogicalStr = {'False', 'True'};

%% printing
fprintf('\n=============================== Network Information =====================================\n');
fprintf('Network:                                            %s \n', network.name);
fprintf('Dimension of network in x-axis (m):                 %d \n', network.xDimension_m);
fprintf('Dimension of network in y-axis (m):                 %d \n', network.yDimension_m);
fprintf('Dimension of network in z-axis (m):                 %d \n', network.zDimension_m);
fprintf('Number of pores:                                    %d \n', network.numberOfNodes);
fprintf('Number of throats:                                  %d \n', network.numberOfLinks);
fprintf('Net porosity:                                       %d \n', network.porosity);
fprintf('Absolute permeability (mD):                         %d \n', network.absolutePermeability_mD);
fprintf('Absolute permeability (m2):                         %E \n', network.absolutePermeability_m2);
fprintf('\n=========================================================================================\n');

%% Saving info to text file

savingFolder = strcat(pwd,'/results/',network.name,'/');
if ~exist(savingFolder, 'dir')
    mkdir(savingFolder)
end
fileName = strcat(network.name,'_stocastic.txt');
vtkFileID = fopen(fullfile(savingFolder,fileName),'w');

if vtkFileID == -1
    error('Cannot open file for writing.');
end

fprintf( vtkFileID, '\n===============================Network Information=====================================\n');
fprintf( vtkFileID, 'Network:                                            %s \n', network.name);
fprintf( vtkFileID, 'Dimension of network in x-axis (m):                 %d \n', network.xDimension_m);
fprintf( vtkFileID, 'Dimension of network in y-axis (m):                 %d \n', network.yDimension_m);
fprintf( vtkFileID, 'Dimension of network in z-axis (m):                 %d \n', network.zDimension_m);
fprintf( vtkFileID, 'Number of pores:                                    %d \n', network.numberOfNodes);
fprintf( vtkFileID, 'Number of throats:                                  %d \n', network.numberOfLinks);
fprintf( vtkFileID, 'Net porosity:                                       %d \n', network.porosity);
fprintf( vtkFileID, 'Absolute permeability (mD):                         %d \n', network.absolutePermeability_mD);
fprintf( vtkFileID, 'Absolute permeability (m2):                         %E \n', network.absolutePermeability_m2);
fprintf( vtkFileID, '======================================================================================\n');
fprintf( vtkFileID, 'Average connection number:                          %d \n', network.averageCoordinationNumber);
fprintf( vtkFileID, 'StandardDeviation connection number:                %d \n', network.stdCoordinationNumber);
fprintf( vtkFileID, 'Number of connections to inlet:                     %d \n', network.numOfInletLinks);
fprintf( vtkFileID, 'Number of connections to outlet:                    %d \n', network.numOfOutletLinks);
fprintf( vtkFileID, 'Number of physically isolated elements:             %d \n', network.numOfIsolatedElements);
fprintf( vtkFileID, 'Number of triangular shaped elements:               %d \n', network.numOfTriangularElements);
fprintf( vtkFileID, 'Number of square shaped elements:                   %d \n', network.numOfSquareElements);
fprintf( vtkFileID, 'Number of circular shaped elements:                 %d \n', network.numOfCircularElements);
fprintf( vtkFileID, 'Number of triangular shaped pores:                  %d \n', network.numOfTriangularPores);
fprintf( vtkFileID, 'Number of square shaped pores:                      %d \n', network.numOfSquarePores);
fprintf( vtkFileID, 'Number of circular shaped pores:                    %d \n', network.numOfCircularPores);
fprintf( vtkFileID, 'Number of triangular shaped pores:                  %d \n', network.numOfTriangularLinks);
fprintf( vtkFileID, 'Number of square shaped pores:                      %d \n', network.numOfSquareLinks);
fprintf( vtkFileID, 'Number of circular shaped pores:                    %d \n', network.numOfCircularLinks);
fprintf( vtkFileID, 'MeanPoreInscribedRadius (m):                        %d \n', mean(network.PSD)/2);
fprintf( vtkFileID, 'StandardDeviationPoreInscribedRadius (m):           %d \n', std(network.PSD)/2);
fprintf( vtkFileID, 'MeanThroatInscribedRadius (m):                      %d \n', mean(network.ThSD)/2);
fprintf( vtkFileID, 'StandardDeviationThroatInscribedRadius (m):         %d \n', std(network.ThSD)/2);
fprintf( vtkFileID, 'MinThroatInscribedLength (m):                       %d \n', min(network.ThSD_length));
fprintf( vtkFileID, 'MeanThroatInscribedLength (m):                      %d \n', mean(network.ThSD_length));
fprintf( vtkFileID, 'StandardDeviationThroatInscribedLength (m):         %d \n', std(network.ThSD_length));
fprintf( vtkFileID, '======================================================================================\n\n');

fprintf( vtkFileID, '\n=================================Input Data ====================================\n');   
fprintf( vtkFileID, 'Is Single Phase Pressure Distribution calculated?   %s \n', LogicalStr{network.calculateSinglePhasePressureDistribution+1});
fprintf( vtkFileID, 'Flow visualization?                                 %s \n', LogicalStr{network.visualization+1});
fprintf( vtkFileID, '=================================================================================\n\n');

%% Plotting info and save as jpg

% Plot Pore & Throat size distribution ====================================

fig = figure('name','Pore Size Distribution');
title('Pore Size Distribution')
hist(network.PSD);
title('Pore Size Distribution')
xlabel('Pore radius (m)')
ylabel('Frequency')
hold on

saveas(fig,[savingFolder strcat(network.name, '_PSD.jpg')]);
close(fig)

fig = figure('name','Throat Size Distribution');
hist(network.ThSD);
title('Throat Size Distribution')
xlabel('Throat radius (m)')
ylabel('Frequency')
hold on

saveas(fig,[savingFolder strcat(network.name, '_TSD.jpg')]);
close(fig)


if network.calculateSinglePhasePressureDistribution
    
    % Plot Pressure =======================================================
    fig = figure('name','Pressure Distribution');
    % a , b are 2 surfaces perpendicular to x-direction with
    % distance equals to intervalx
     
    n = 5;
    intervalx = 0 : (network.xDimension_m/n) : network.xDimension_m; 
    x = zeros(n+1,1);
    press_x = zeros(n+1,1);
    
    x(1) = intervalx(1);
    x(n+1) = intervalx(end);
    press_x(1) = network.inletPressure_Pa;
    press_x(n+1) = network.outletPressure_Pa;
    
    for i = 2:n
        count = 0;
%         area = 0;
        for ii = 1:network.numberOfNodes
            if network.Nodes{ii}.x_coordinate >= intervalx(i-1) && network.Nodes{ii}.x_coordinate < intervalx(i)
                press_x(i) = press_x(i) + network.Nodes{ii}.wettingPhasePressure;
%                 press_x(i) = press_x(i) + network.Nodes{ii}.wettingPhasePressure*network.Nodes{ii}.area;
%                 area= area+network.Nodes{ii}.area;
                count= count+1;
            end
        end
        if count
            press_x(i) = press_x(i)/count;
            x(i) = intervalx(i);
        else
            press_x(i) = NaN;
            x(i) = NaN;
        end 
    end
    plot(x, press_x, '*')
    title('Pressure drop in x-direction')
    xlabel('X(m)')
    xlim([0 network.xDimension_m])
    ylim([network.outletPressure_Pa network.inletPressure_Pa])
    ylabel('Pressure(Pa)')
    
    saveas(fig,[savingFolder strcat(network.name, '_PressureDistribution.jpg')]);
    close(fig)
end
end
