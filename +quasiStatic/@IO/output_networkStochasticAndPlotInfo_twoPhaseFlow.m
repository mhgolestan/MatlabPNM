%% Network Properties calculation
function output_networkStochasticAndPlotInfo_twoPhaseFlow(obj, network)

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

%% Saving info to text file

savingFolder = strcat(pwd,'/results/',network.name,'/');
if ~exist(savingFolder, 'dir')
    mkdir(savingFolder)
end
fileName = strcat(network.name,'_twoPhaseFlowReport.txt');
vtkFileID = fopen(fullfile(savingFolder,fileName),'w');

if vtkFileID == -1
    error('Cannot open file for writing.');
end

LogicalStr = {'False', 'True'};

% Stocastics ==============================================================
fprintf( vtkFileID, '\n===============================Network Information============================\n');
fprintf( vtkFileID, 'Network:                                            %s \n', network.name);
fprintf( vtkFileID, 'Dimension of network in x-axis (m):                 %d \n', network.xDimension_m);
fprintf( vtkFileID, 'Dimension of network in y-axis (m):                 %d \n', network.yDimension_m);
fprintf( vtkFileID, 'Dimension of network in z-axis (m):                 %d \n', network.zDimension_m);
fprintf( vtkFileID, 'Number of pores:                                    %d \n', network.numberOfNodes);
fprintf( vtkFileID, 'Number of throats:                                  %d \n', network.numberOfLinks);
fprintf( vtkFileID, 'Net porosity:                                       %d \n', network.porosity);
fprintf( vtkFileID, 'Absolute permeability (mD):                         %d \n', network.absolutePermeability_mD);
fprintf( vtkFileID, 'Absolute permeability (m2):                         %E \n', network.absolutePermeability_m2);
fprintf( vtkFileID, '================================================================================\n');
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
fprintf( vtkFileID, '================================================================================\n');

fprintf( vtkFileID, '\n=================================Input Data ====================================\n');
fprintf( vtkFileID, 'Receding contact angle (o):                         %d \n', network.recedingContactAngle);
fprintf( vtkFileID, 'Advancing contact angle (o):                        %d \n', network.advancingContactAngle);
fprintf( vtkFileID, 'Rand seed for imbibition filling:                   %d \n', network.randSeed);
fprintf( vtkFileID, 'Minimum capillary pressure (Pa):                    %d \n', network.min_Pc_Pa);
fprintf( vtkFileID, 'Maximum capillary pressure (Pa):                    %d \n', network.max_Pc_Pa);
fprintf( vtkFileID, 'Delta saturation for output visualization:          %d \n', network.deltaS_input);
fprintf( vtkFileID, 'Number of intervals for capillary pressure:         %d \n', network.NoOfPc_interval);
fprintf( vtkFileID, 'Type of Pore Body Filling Algorithm:                %s \n', network.typeOfPoreBodyFillingAlgorithm);
fprintf( vtkFileID, 'Is relative permeability calculated?                %s \n', LogicalStr{network.calculateRelativePermeability+1});
fprintf( vtkFileID, 'wettingPhase viscosity (Pa.S):                      %d \n', network.wettingPhase_Viscosity_PaS);
fprintf( vtkFileID, 'nonWettingPhase viscosity (Pa.S):                   %d \n', network.nonWettingPhase_Viscosity_PaS);
fprintf( vtkFileID, 'IFT (N/m):                                          %d \n', network.IFT_NperMeter);
fprintf( vtkFileID, 'Flow visualization?                                 %s \n', LogicalStr{network.flowVisualization+1});
fprintf( vtkFileID, '=================================================================================\n\n');


% Drainage data ===========================================================
[nrows_D,~] = size(network.DrainageData);
if nrows_D > 0
    
    fprintf( vtkFileID, '==================================== Primary Drainage =====================================\n\n');
    
    for row = 1:nrows_D
        if network.calculateRelativePermeability
            fprintf(vtkFileID,'Sw:%1.5f \t Pc(Pa):%8.5f \t No. of invasion:%3.0f \t K_rw:%1.5f \t K_rnw:%1.5f \n',...
                network.DrainageData(row,1), network.DrainageData(row,2), network.DrainageData(row,5), network.DrainageData(row,3), network.DrainageData(row,4));
            
        else
            fprintf(vtkFileID,'Sw:%d \t Pc(Pa):%d \t No. of invasion:%d\n',...
                network.DrainageData(row,1), network.DrainageData(row,2), network.DrainageData(row,5));
        end
    end
    
    fprintf( vtkFileID, '\n========================= Network state at the end of Primary Drainage ====================\n\n');
    fprintf( vtkFileID, 'Maximum capillary pressure reached (Pa):   %8.5f \n', network.DrainageData(end,2));
    fprintf( vtkFileID, 'Residual water saturation:                 %1.5f \n', network.DrainageData(end,1));
    fprintf( vtkFileID, 'Number of invaded elements:                %1.0f \n', network.DrainageData(end,5));
    fprintf( vtkFileID, 'Number of uninvaded elements:              %1.0f \n', network.numberOfNodes + network.numberOfLinks - network.DrainageData(end,5));
    fprintf( vtkFileID, '===========================================================================================\n\n');
    
end

% Imbibition data ===========================================================
[nrows_I,~] = size(network.ImbibitionData);
if nrows_I > 0
    
    fprintf( vtkFileID, '=================================== Secondary Imbibition ==================================\n\n');
    
    for row = 1:nrows_I
        if network.calculateRelativePermeability
            fprintf(vtkFileID,'Sw:%1.5f \t Pc(Pa):%8.5f \t No. of invasion:%3.0f \t K_rw:%1.5f \t K_rnw:%1.5f \n',...
                network.ImbibitionData(row,1), network.ImbibitionData(row,2), network.ImbibitionData(row,5), network.ImbibitionData(row,3), network.ImbibitionData(row,4));
            
        else
            fprintf(vtkFileID,'Sw:%d \t Pc(Pa):%d \t No. of invasion:%d\n',...
                network.ImbibitionData(row,1), network.ImbibitionData(row,2), network.ImbibitionData(row,5));
        end
    end
    fprintf( vtkFileID, '\n=============== Network state at the end of Secondary Imbibition ==========================\n\n');
    fprintf( vtkFileID, 'Minimum capillary pressure reached (Pa):   %1.5f \n', network.ImbibitionData(end,2));
    fprintf( vtkFileID, 'Maximum water saturation:                  %1.5f \n', network.ImbibitionData(end,1));
    fprintf( vtkFileID, 'Number of invaded elements:                %1.0f \n', network.ImbibitionData(end,5));
    fprintf( vtkFileID, 'Number of uninvaded elements:              %1.0f \n', network.numberOfNodes + network.numberOfLinks - network.ImbibitionData(end,5));
    fprintf( vtkFileID, '\n ============== Pore Filling process at the end of Secondary Imbibition ===================\n\n');
    fprintf( vtkFileID, 'Number of uninvaded pores:                 %1.0f \n', network.numberOfNodes - network.ImbibitionData(end,9)- network.ImbibitionData(end,10));
    fprintf( vtkFileID, 'Number of Snap off in pores:               %1.0f \n', network.ImbibitionData(end,9));
    fprintf( vtkFileID, 'Number of Pore body filling in pores:      %1.0f \n', network.ImbibitionData(end,10));
    fprintf( vtkFileID, '\n ============== Throat Filling process at the end of Secondary Imbibition =================\n\n');
    fprintf( vtkFileID, 'Number of uninvaded throats:               %1.0f \n', network.numberOfLinks - network.ImbibitionData(end,6)- network.ImbibitionData(end,7));
    fprintf( vtkFileID, 'Number of Snap off in throats:             %1.0f \n', network.ImbibitionData(end,6));
    fprintf( vtkFileID, 'Number of Piston like in throats:          %1.0f \n', network.ImbibitionData(end,7));
    fprintf( vtkFileID, '===========================================================================================\n\n');
end

%% Plotting info and save as jpg


if nrows_D > 0 && nrows_I == 0
    fig = figure('name','Primary Drainage Cappilary Pressure & Relative Permeability Curves', 'units','normalized','outerposition',[0 0 1 1]);
    subplot(1,2,1);
    plot(network.DrainageData(:,1),network.DrainageData(:,2),'-r')
    legend('Primary Drainage P_c')
    xlabel('Sw')
    xlim([0 1])
    xticks(0:0.2:1);
    ylabel('Pc (Pa)')
    title('Capillary Pressure Curve')
    %     pbaspect([1 1 1])
    
    if network.calculateRelativePermeability
        hold on
        subplot(1,2,2);
        plot(network.DrainageData(:,1),network.DrainageData(:,3),'-b',network.DrainageData(:,1),network.DrainageData(:,4),'-r')
        xlabel('Sw')
        xlim([0 1])
        xticks(0:0.2:1);
        ylabel('Reative Permeability')
        ylim([0 1])
        yticks(0:0.2:1);
        legend('Drainage Kr_w','Drainage Kr_{nw}')
        pbaspect([1 1 1])
        title('Relative Permeability Curves')
    end
    saveas(fig,[savingFolder strcat(network.name, '_Pc-KrCurves_Drainage.jpg')]);
    
elseif nrows_D > 0 && nrows_I > 0
    fig = figure('name','Primary Drainage & Secondary Imbibition Cappilary Pressure & Relative Permeability Curves', 'units','normalized','outerposition',[0 0 1 1]);
    subplot(1,2,1);
    plot(network.DrainageData(:,1),network.DrainageData(:,2),'-r')
    hold on
    plot(network.ImbibitionData(:,1),network.ImbibitionData(:,2),'-.b')
    legend('Primary Drainage P_c','Secondary Imbibition P_c')
    xlabel('Sw')
    xlim([0 1])
    xticks(0:0.2:1);
    ylabel('Pc (Pa)')
    title('Capillary Pressure Curves')
    %     pbaspect([1 1 1])
    
    if network.calculateRelativePermeability
        subplot(1,2,2);
        plot(network.DrainageData(:,1),network.DrainageData(:,3),'-b',network.DrainageData(:,1),network.DrainageData(:,4),'-r')
        hold on
        plot(network.ImbibitionData(:,1),network.ImbibitionData(:,3),'-.b',network.ImbibitionData(:,1),network.ImbibitionData(:,4),'-.r')
        xlabel('Sw')
        xlim([0 1])
        xticks(0:0.2:1);
        ylabel('Reative Permeability')
        ylim([0 1])
        yticks(0:0.2:1);
        legend('Drainage Kr_w','Drainage Kr_{nw}','Imbibition Kr_w','Imbibition Kr_{nw}')
        pbaspect([1 1 1])
        title('Relative Permeability Curves')
    end
    
    saveas(fig,[savingFolder strcat(network.name, '_Pc-KrCurves_Drainage-Imbibition.jpg')]);
    
end
