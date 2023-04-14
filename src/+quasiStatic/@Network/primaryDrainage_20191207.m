% Primary Drainage
% This strategy does meet the oredering of filling from left to right
% rather than easily follows the ordering based on the indexing of the emelemnts

function primaryDrainage_20191207(network)

% determining the capillary pressure level interval
Pc_threshold = nan(network.numberOfLinks,1);
for i = 1:network.numberOfLinks
    network.Links{i}.recedingContactAngle = network.recedingContactAngle;
    network.Links{i}.advancingContactAngle = network.advancingContactAngle;
    
    network.Links{i}.wettingPhasePressure = 0;
    network.Links{i}.calculateThresholdPressurePistonLike_drainage();
    Pc_threshold(i,1) = network.Links{i}.drainThresholdPressure_PistonLike;
end
for i = 1:network.numberOfNodes
    network.Nodes{i}.recedingContactAngle = network.recedingContactAngle;
    network.Nodes{i}.advancingContactAngle = network.advancingContactAngle;
    network.Nodes{i}.wettingPhasePressure = 0;
    network.Nodes{i}.calculateThresholdPressurePistonLike_drainage();
end

max_Pc_Pa = max(Pc_threshold);
min_Pc_Pa = 0;%min(nonzeros(Pc_threshold));
NoOfPc_interval = (max_Pc_Pa-min_Pc_Pa)/network.NoOfPc_interval;

Pc = min_Pc_Pa;
lastMaxP = Pc;
Pc_threshold = nan(network.numberOfLinks,2);
t = 1;
invaded = 0;
network.Pc_drain_max_Pa = network.max_Pc_Pa; %max_Pc_Pa;
network.DrainageData = zeros(network.NoOfPc_interval,5);

% initializing clusters
LinkL = zeros(network.numberOfLinks);
cluster_A_nums =[];
[~, NodeL_W, LinkL_W,cluster_A,cluster_B] = clustering_wettingPhase(network);

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
while Pc <= network.Pc_drain_max_Pa *1.0001 %&& (any(nonzeros(Pc_threshold(:,1))))
    press = 1;
    deltaS = 0;
    deltaV = 0;
    
    if (any(nonzeros(Pc_threshold(:,1))) && min(Pc_threshold(:,1))<= Pc)
        pressure = 1;
    else
        pressure = 0;
    end
    
    % Add Links which have Pc_threshold < Pc in each steps and also have nonWetting-saturated neighbour Node
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
        if network.Links{i}.isInlet && network.Links{i}.occupancy == 'A'
            
            network.Links{i}.occupancy = 'B';
            invaded = invaded + 1;
            deltaV = deltaV + network.Links{i}.volume ;
            jj = node2Index;
            if network.Nodes{jj}.occupancy == 'A' && ...
                    (any(NodeL_W(jj) == cluster_A(:)) ||  any(NodeL_W(jj) == cluster_B(:)))
                
                network.Nodes{jj}.occupancy = 'B';
                invaded = invaded + 1;
                deltaV = deltaV + network.Nodes{jj}.volume ;
                
                for j=1:network.Nodes{jj}.connectionNumber
                    linkIndex = network.Nodes{jj}.connectedLinks(j);
                    
                    if network.Links{linkIndex}.occupancy == 'A' &&...
                            (any(LinkL_W(linkIndex) == cluster_A(:)) ||  any(LinkL_W(linkIndex) == cluster_B(:)))
                        Pc_threshold(linkIndex,1)= network.Links{linkIndex}.drainThresholdPressure_PistonLike;
                        neighbour = neighbour +1;
                        Pc_threshold(linkIndex,2)=neighbour;
                    end
                end
            end
        elseif network.Links{i}.isOutlet && network.Links{i}.occupancy == 'A'
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
                jj = node2Index;
                if network.Nodes{jj}.occupancy == 'A' && ...
                        (any(NodeL_W(jj) == cluster_A(:)) ||  any(NodeL_W(jj) == cluster_B(:)))
                    network.Nodes{jj}.occupancy = 'B';
                    invaded = invaded + 1;
                    deltaV = deltaV + network.Nodes{jj}.volume ;
                    for j=1:network.Nodes{jj}.connectionNumber
                        linkIndex = network.Nodes{jj}.connectedLinks(j);
                        if network.Links{linkIndex}.occupancy == 'A' &&...
                                (any(LinkL_W(linkIndex) == cluster_A(:)) ||  any(LinkL_W(linkIndex) == cluster_B(:)))
                            Pc_threshold(linkIndex,1)= network.Links{linkIndex}.drainThresholdPressure_PistonLike;
                            neighbour = neighbour +1;
                            Pc_threshold(linkIndex,2)=neighbour;
                        end
                    end
                end
                jj = node1Index;
                if network.Nodes{jj}.occupancy == 'A' && ...
                        (any(NodeL_W(jj) == cluster_A(:)) ||  any(NodeL_W(jj) == cluster_B(:)))
                    network.Nodes{jj}.occupancy = 'B';
                    invaded = invaded + 1;
                    deltaV = deltaV + network.Nodes{jj}.volume ;
                    for j=1:network.Nodes{jj}.connectionNumber
                        linkIndex = network.Nodes{jj}.connectedLinks(j);
                        if network.Links{linkIndex}.occupancy == 'A' &&...
                                (any(LinkL_W(linkIndex) == cluster_A(:)) ||  any(LinkL_W(linkIndex) == cluster_B(:)))
                            Pc_threshold(linkIndex,1)= network.Links{linkIndex}.drainThresholdPressure_PistonLike;
                            neighbour = neighbour +1;
                            Pc_threshold(linkIndex,2)=neighbour;
                        end
                    end
                end
            end
        end
        deltaS = deltaV /network.networkPoreVolume_m3 ;
        if deltaS > network.deltaS_input
            press = 0;
        end
        if any(Pc_threshold(:,1)) && min(Pc_threshold(:,1))<= Pc
            pressure = 1;
        else
            pressure = 0;
        end
        
        %         if invaded == 1 || invaded == 2
        %             break
        %         end
    end
    if Pc == max_Pc_Pa
        lastMaxP = max_Pc_Pa;
    end
    
    % Updating element saturations and conductances
    calculateConductance_and_Saturation_Drainage(network, Pc);
    
    % Relative Permeability Calculation
    
    if network.calculateRelativePermeability
        calculatePressureDistribution_TwoPhases(network, network.inletPressure_Pa, network.outletPressure_Pa);
        [Kr_w , Kr_nw] = calculateRelativePermeability_Drainage (network, network.outletPressure_Pa, LinkL, LinkL_W, cluster_A_nums, cluster_A);
    else
        Kr_w =NaN;
        Kr_nw=NaN;
    end
    network.DrainageData(t,:) = [network.wettingPhaseSaturation, Pc, Kr_w, Kr_nw, invaded];
    if network.flowVisualization
        network.IO.visualization(network,'PD',t);
    end
    if invaded ~= 0
        [~, ~, LinkL,cluster_A_nums,~] = clustering_nonWettingPhase(network);
    end
    [~, NodeL_W, LinkL_W,cluster_A,cluster_B] = clustering_wettingPhase(network);
    
    % Pc Step Calculation
    if press ~= 0
        Pc = Pc + NoOfPc_interval;
    end
    t = t + 1;
end
rowNames = {'Sw', 'Pc (Pa)', 'Kr_w', 'Kr_nw', 'No. of invaded'};
network.DrainageData_table = array2table(network.DrainageData, 'VariableNames',rowNames);
end