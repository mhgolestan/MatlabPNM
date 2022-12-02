function calculateConductance_and_Saturation_Imbibition(network, Pc, NodeL, NodeL_W, LinkL, LinkL_W, cluster_A_nums, cluster_A, cluster_B_nums, cluster_B)  
            Pc = abs(Pc);     
            waterVolume = 0;   
            vol = 0; 
            waterArea = zeros(network.numberOfLinks,4);
            
            for i = 1:network.numberOfNodes 
                    if (any(NodeL(i) == cluster_A_nums(:)) ||  any(NodeL(i) == cluster_B_nums(:)))
                        network.Nodes{i}.calculateConductance_Imbibition(network, Pc);   
                        
                    else
                        if isnan(network.Nodes{i}.imbPressureTrapped) && network.Nodes{i}.occupancy == 'B'
                            network.Nodes{i}.imbPressureTrapped = max(Pc, network.Nodes{i}.imbThresholdPressure_SnapOff);  
                        end 
                        if any(network.Nodes{i}.imbPressureTrapped) 
                            network.Nodes{i}.calculateConductance_Imbibition(network, network.Nodes{i}.imbPressureTrapped); 
                        elseif (any(NodeL_W(i) == cluster_A(:)) ||  any(NodeL_W(i) == cluster_B(:)))
                            network.Nodes{i}.calculateConductance_Imbibition(network, Pc);
                        end
                    end           
                % Water Saturation Calculation
                waterArea(i,1)=network.Nodes{i}.area;
                waterArea(i,2)=network.Nodes{i}.waterCrossSectionArea;
                if ~network.Nodes{i}.isInlet && ~network.Nodes{i}.isOutlet 
                    waterVolume = waterVolume + (network.Nodes{i}.waterCrossSectionArea )...
                        / network.Nodes{i}.area *network.Nodes{i}.volume + network.Nodes{i}.clayVolume;                
                    vol = vol + network.Nodes{i}.volume + network.Nodes{i}.clayVolume;
                end
            end
            
            for i = 1:network.numberOfLinks 
                    if (any(LinkL(i) == cluster_A_nums(:)) ||  any(LinkL(i) == cluster_B_nums(:)))
                        network.Links{i}.calculateConductance_Imbibition(network, Pc);    
                    else
                        if isnan(network.Links{i}.imbPressureTrapped) && network.Links{i}.occupancy == 'B'
                            network.Links{i}.imbPressureTrapped = max(Pc, network.Links{i}.imbThresholdPressure_SnapOff);    
                        end 
                        if any(network.Links{i}.imbPressureTrapped) 
                            network.Links{i}.calculateConductance_Imbibition(network, network.Links{i}.imbPressureTrapped); 
                        elseif (any(LinkL_W(i) == cluster_A(:)) ||  any(LinkL_W(i) == cluster_B(:)))
                            network.Links{i}.calculateConductance_Imbibition(network, Pc);
                        end
                    end 
                % Water Saturation Calculation                
                waterArea(i,3)=network.Links{i}.area;
                waterArea(i,4)=network.Links{i}.waterCrossSectionArea;
                if ~network.Links{i}.isInlet && ~network.Links{i}.isOutlet 
                     waterVolume = waterVolume + (network.Links{i}.waterCrossSectionArea )...
                         / network.Links{i}.area * network.Links{i}.volume + network.Links{i}.clayVolume;
                     vol = vol + network.Links{i}.volume + network.Links{i}.clayVolume;
                end
            end             
            network.waterSaturation = waterVolume / vol;     
        end