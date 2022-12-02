% Primary Drainage
% This strategy does not meet the oredering of filling from left to right
% However it follows the ordering based on the indexing of the emelemnts

function PrimaryDrainage(network, inletPressure, outletPressure)

% determining the capillary pressure level interval
Pc_threshold = nan(network.numberOfLinks+network.numberOfNodes,1);
for i = 1:network.numberOfLinks
    network.Links{i}.waterPressure = 0;
    network.Links{i}.calculateThresholdPressurePistonLike_drainage();
    Pc_threshold(i,1) = network.Links{i}.drainThresholdPressure_PistonLike;
end
for i = 1:network.numberOfNodes
    network.Nodes{i}.waterPressure = 0;
    network.Nodes{i}.calculateThresholdPressurePistonLike_drainage();
    Pc_threshold(i+network.numberOfLinks) = network.Nodes{i}.drainThresholdPressure_PistonLike;
end
max_Pc = max(Pc_threshold);
min_Pc = 0;% min(nonzeros(Pc_threshold));
Pc_interval = (max_Pc-min_Pc)/network.Pc_interval;
Pc_threshold = nan(2*network.numberOfLinks,1);
Pc = min_Pc; 

t = 1;
invaded = 0;
network.Pc_drain_max = network.max_Pc;
network.DrainageData = zeros(network.Pc_interval,5);

% initializing clusters
LinkL = zeros(network.numberOfLinks);
cluster_A_nums =[];
[~, NodeL_W, LinkL_W,cluster_A,cluster_B] = Clustering_water(network);

% Cycle of increasing Pressure
while Pc <= network.Pc_drain_max 
    press = 1;
    % Find new inlet-Links with threshold pressure < Pc
    for i = 1:network.numberOfLinks
        node1Index = network.Links{i}.pore1Index;
        node2Index = network.Links{i}.pore2Index;
        if network.Links{i}.isInlet && network.Links{i}.occupancy == 'A'
            if (any(LinkL_W(i) == cluster_A(:))) && network.Links{i}.drainThresholdPressure_PistonLike <= Pc
                network.Links{i}.occupancy = 'B';
                invaded = invaded + 1;
                if  network.Nodes{node2Index}.occupancy == 'A'  &&...
                        (any(NodeL_W(node2Index) == cluster_A(:)) ||  any(NodeL_W(node2Index) == cluster_B(:)))
                    
                    Pc_threshold(node2Index+network.numberOfLinks) = network.Nodes{node2Index}.drainThresholdPressure_PistonLike;
                end
            end
        elseif network.Links{i}.isOutlet && network.Links{i}.occupancy == 'A'
            if network.Nodes{node1Index}.occupancy == 'B'
                Pc_threshold(i)=network.Links{i}.drainThresholdPressure_PistonLike;
            end
        elseif ~network.Links{i}.isOutlet && ~network.Links{i}.isInlet && network.Links{i}.occupancy == 'A'
            if network.Nodes{node1Index}.occupancy == 'B' || network.Nodes{node2Index}.occupancy == 'B'
                if (any(LinkL_W(i) == cluster_A(:)) ||  any(LinkL_W(i) == cluster_B(:)))
                    Pc_threshold(i)= network.Links{i}.drainThresholdPressure_PistonLike;
                end
            end
        end
    end
    deltaS = 0;
    deltaV = 0;
    if (any(nonzeros(Pc_threshold)) && min(Pc_threshold)<= Pc)  
        pressure = 1;
    else
        pressure = 0;
    end
    lastMaxP = Pc;
    % Add Links which have Pc_threshold < Pc in each steps and also have oil-saturated neighbour Node
    while  pressure == 1 && deltaS <= network.deltaS_input
        
        %check & sort Links based on Pc_Threshold
        [~, i] = min(Pc_threshold);
        
        if lastMaxP < Pc_threshold(i)
            lastMaxP = Pc_threshold(i);
        end
        Pc_threshold(i) = nan;
        if i <= network.numberOfLinks
            
            node1Index = network.Links{i}.pore1Index;
            node2Index = network.Links{i}.pore2Index;
            
            if network.Links{i}.isOutlet && network.Links{i}.occupancy == 'A'
                if network.Nodes{node1Index}.occupancy == 'B'
                    
                    network.Links{i}.occupancy = 'B';
                    invaded = invaded + 1;
                    deltaV = deltaV + network.Links{i}.volume ;
                end
            elseif ~network.Links{i}.isOutlet && ~network.Links{i}.isInlet && network.Links{i}.occupancy == 'A'
                if network.Nodes{node1Index}.occupancy == 'B' || network.Nodes{node2Index}.occupancy == 'B'  &&...
                        (any(LinkL_W(i) == cluster_A(:)) ||  any(LinkL_W(i) == cluster_B(:)))
                    
                    network.Links{i}.occupancy = 'B';
                    invaded = invaded + 1;
                    deltaV = deltaV + network.Links{i}.volume ;
                    
                    if  network.Nodes{node2Index}.occupancy == 'A' && ...
                            (any(NodeL_W(node2Index) == cluster_A(:)) ||  any(NodeL_W(node2Index) == cluster_B(:)))
                        
                        Pc_threshold(node2Index+network.numberOfLinks) = network.Nodes{node2Index}.drainThresholdPressure_PistonLike;
                    end
                    
                    if network.Nodes{node1Index}.occupancy == 'A' && ...
                            (any(NodeL_W(node1Index) == cluster_A(:)) ||  any(NodeL_W(node1Index) == cluster_B(:)))
                        
                        Pc_threshold(node1Index+network.numberOfLinks) = network.Nodes{node1Index}.drainThresholdPressure_PistonLike;
                    end
                end
            end
        else
            jj = i - network.numberOfLinks;
            if (any(NodeL_W(jj) == cluster_A(:)) ||  any(NodeL_W(jj) == cluster_B(:)))
                network.Nodes{jj}.occupancy = 'B';
                invaded = invaded + 1;
                deltaV = deltaV + network.Nodes{jj}.volume ;
                for j=1:network.Nodes{jj}.connectionNumber
                    linkIndex = network.Nodes{jj}.connectedLinks(j);
                    if network.Links{linkIndex}.occupancy == 'A' &&...
                            (any(LinkL_W(linkIndex) == cluster_A(:)) ||  any(LinkL_W(linkIndex) == cluster_B(:)))
                        Pc_threshold(linkIndex)= network.Links{linkIndex}.drainThresholdPressure_PistonLike;
                    end
                end
            end
        end
        deltaS = deltaV /network.poreVolume ;
        if deltaS > network.deltaS_input
            press = 0;
        end
        if any (Pc_threshold) && min(Pc_threshold)<= Pc
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
    [Krw , Kro] = calculateRelativePermeability_Drainage (network, outletPressure, LinkL, LinkL_W, cluster_A_nums, cluster_A);
    network.DrainageData(t,:) = [network.waterSaturation, lastMaxP, Krw, Kro, invaded];
    network.visualization(network.name,'PD',t);
    if invaded ~= 0
        [~, ~, LinkL,cluster_A_nums,~] = Clustering_oil(network);
    end
    [~, NodeL_W, LinkL_W,cluster_A,cluster_B] = Clustering_water(network);
    
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