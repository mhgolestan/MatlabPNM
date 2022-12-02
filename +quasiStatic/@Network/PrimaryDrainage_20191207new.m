%% Primary Drainage_newClusterAlgorithm
function PrimaryDrainage_20191207new(network, inletPressure, outletPressure)

% determining the capillary pressure level interval
Pc_threshold = nan(network.numberOfLinks,1);
for i = 1:network.numberOfLinks
    network.Links{i}.waterPressure = 0;
    network.Links{i}.calculateThresholdPressurePistonLike_drainage();
    Pc_threshold(i,1) = network.Links{i}.drainThresholdPressure_PistonLike;
end
for i = 1:network.numberOfNodes
    network.Nodes{i}.waterPressure = 0;
    network.Nodes{i}.calculateThresholdPressurePistonLike_drainage();
end

max_Pc = max(Pc_threshold);
Pc_interval = (max_Pc)/network.Pc_interval;
Pc_threshold = nan(2*network.numberOfLinks,2);
Pc = 0;
t = 1;
invaded = 0;
network.Pc_drain_max = max_Pc;
network.DrainageData = zeros(network.Pc_interval,5);

% initializing clusters
[oilInletClusterIndex, oilOutletClusterIndex] = ClusteringOil_new(network);
[waterInletClusterIndex, waterOutletClusterIndex] = ClusteringWater_new(network);

neighbour = 0;
% Find new inlet-Links with threshold pressure < Pc
for i = 1:network.numberOfLinks
    if network.Links{i}.isInlet && network.Links{i}.occupancy == 'A'
        Pc_threshold(i,1)=network.Links{i}.drainThresholdPressure_PistonLike;
        neighbour = neighbour +1;
        Pc_threshold(i,2)=neighbour;
    end
end

% Cycle of increasing Pressure
while Pc <= network.Pc_drain_max *1.0001
    
    press = 1;
    deltaS = 0;
    deltaV = 0;
    if (any(Pc_threshold(:,1)) && min(Pc_threshold(:,1))<= Pc)
        pressure = 1;
    else
        pressure = 0;
    end
    lastMaxP = Pc;
    
    % Add Links which have Pc_threshold < Pc in each steps and also have oil-saturated neighbour Node
    while  pressure == 1 && deltaS <= network.deltaS_input
        
        %check & sort Links based on Pc_Threshold
        [~,n] = min(Pc_threshold);
        if n(1) == n(2) || Pc_threshold(n(1),1) == Pc_threshold(n(2),1)
            i = n(2);
        else
            i = n(1);
        end
        
        if lastMaxP < Pc_threshold(i,1)
            lastMaxP = Pc_threshold(i,1);
        end
        Pc_threshold(i,1) = nan;
        Pc_threshold(i,2) = nan;
        node1Index = network.Links{i}.pore1Index;
        node2Index = network.Links{i}.pore2Index;
        if network.Links{i}.isInlet && network.Links{i}.occupancy == 'A'  && network.Links{i}.waterConnectedOutlet
            
            network.Links{i}.occupancy = 'B';
            %             network.Links{i}.waterConnectedOutlet = false;
            invaded = invaded + 1;
            deltaV = deltaV + network.Links{i}.volume ;
            
            jj = node2Index;
            if network.Nodes{jj}.occupancy == 'A' && network.Nodes{jj}.waterConnectedOutlet
                
                network.Nodes{jj}.occupancy = 'B';
                %                 network.Nodes{jj}.waterConnectedOutlet = false;
                invaded = invaded + 1;
                deltaV = deltaV + network.Nodes{jj}.volume ;
                
                for j=1:network.Nodes{jj}.connectionNumber
                    linkIndex = network.Nodes{jj}.connectedLinks(j);
                    
                    if network.Links{linkIndex}.occupancy == 'A' && network.Links{linkIndex}.waterConnectedOutlet
                        Pc_threshold(linkIndex,1)= network.Links{linkIndex}.drainThresholdPressure_PistonLike;
                        neighbour = neighbour +1;
                        Pc_threshold(linkIndex,2)=neighbour;
                    end
                end
            end
        elseif network.Links{i}.isOutlet && network.Links{i}.occupancy == 'A' && network.Links{i}.waterConnectedOutlet
            
            if network.Nodes{node1Index}.occupancy == 'B'
                
                network.Links{i}.occupancy = 'B';
                %                 network.Links{i}.waterConnectedOutlet = false;
                invaded = invaded + 1;
                deltaV = deltaV + network.Links{i}.volume ;
            end
        elseif ~network.Links{i}.isOutlet && ~network.Links{i}.isInlet && network.Links{i}.occupancy == 'A' && network.Links{i}.waterConnectedOutlet
            if network.Nodes{node1Index}.occupancy == 'B' || network.Nodes{node2Index}.occupancy == 'B'
                
                network.Links{i}.occupancy = 'B';
                %                 network.Links{i}.waterConnectedOutlet = false;
                invaded = invaded + 1;
                deltaV = deltaV + network.Links{i}.volume ;
                jj = node2Index;
                if network.Nodes{jj}.occupancy == 'A' && network.Nodes{jj}.waterConnectedOutlet
                    network.Nodes{jj}.occupancy = 'B';
                    %                     network.Nodes{jj}.waterConnectedOutlet = false;
                    invaded = invaded + 1;
                    deltaV = deltaV + network.Nodes{jj}.volume ;
                    for j=1:network.Nodes{jj}.connectionNumber
                        linkIndex = network.Nodes{jj}.connectedLinks(j);
                        if network.Links{linkIndex}.occupancy == 'A' && network.Links{linkIndex}.waterConnectedOutlet
                            Pc_threshold(linkIndex,1)= network.Links{linkIndex}.drainThresholdPressure_PistonLike;
                            neighbour = neighbour +1;
                            Pc_threshold(linkIndex,2)=neighbour;
                        end
                    end
                end
                jj = node1Index;
                if network.Nodes{jj}.occupancy == 'A' && network.Nodes{jj}.waterConnectedOutlet
                    network.Nodes{jj}.occupancy = 'B';
                    %                     network.Nodes{jj}.waterConnectedOutlet = false;
                    invaded = invaded + 1;
                    deltaV = deltaV + network.Nodes{jj}.volume ;
                    for j=1:network.Nodes{jj}.connectionNumber
                        linkIndex = network.Nodes{jj}.connectedLinks(j);
                        if network.Links{linkIndex}.occupancy == 'A' && network.Links{linkIndex}.waterConnectedOutlet
                            Pc_threshold(linkIndex,1)= network.Links{linkIndex}.drainThresholdPressure_PistonLike;
                            neighbour = neighbour +1;
                            Pc_threshold(linkIndex,2)=neighbour;
                        end
                    end
                end
            end
        end
        deltaS = deltaV /network.poreVolume ;
        if deltaS > network.deltaS_input
            press = 0;
        end
        if any(Pc_threshold(:,1)) && min(Pc_threshold(:,1))<= Pc
            pressure = 1;
        else
            pressure = 0;
        end
    end
    if Pc == max_Pc
        lastMaxP = max_Pc;
    end
    
    % Updating element saturations and conductances
    calculateConductance_and_Saturation_Drainage(network, lastMaxP);
    pressureDistribution_TwoPhases(network, inletPressure, outletPressure);
    
    % Relative Permeability Calculation
    [Krw , Kro] = calculateRelativePermeability_Drainage (network, outletPressure, ...
        waterInletClusterIndex, waterOutletClusterIndex, oilInletClusterIndex, oilOutletClusterIndex);
    network.DrainageData(t,:) = [network.waterSaturation, lastMaxP, Krw, Kro, invaded];
    network.visualization(network.name,'PD',t);
    if invaded ~= 0
        [oilInletClusterIndex, oilOutletClusterIndex] = network.ClusteringOil_new();
    end
    [waterInletClusterIndex, waterOutletClusterIndex] = network.ClusteringWater_new();
    
    % Pc Step Calculation
    if press ~= 0
        Pc = Pc + Pc_interval;
    end
    t = t + 1;
end
drainagePlotInfo(network)
rowNames = {'Sw', 'Pc (Pa)', 'Krw', 'Kro', 'No. of invaded'}; 
network.DrainageData = array2table(network.DrainageData, 'VariableNames',rowNames); 
end