% Single phase Reactive transport_Mehmani_2015 fullyImplicit
function calculateReactiveTransport_SinglePhaseDiffusion_Mehmani(network, inletPressure, outletPressure, soluteConcentration, poreVolumeSimulation, poreVolumeInjected)
                        
            residenceTime_link = zeros(network.numberOfLinks,1);
            flowRate_link = zeros(network.numberOfLinks,1);
            effectiveDiffusion = 10^ (-9);
            diffusion_link = zeros(network.numberOfLinks,1);            
            network.pecletNumber = 3;
            
            while network.capillaryNumber > 10^(-7) || abs(network.pecletNumber-1) > 10 ^(-2) % for Capillary dominant flow
            % calculate pressure distribution
            pressureDistribution_singlePhaseFlow_Cylindrical (network, inletPressure, outletPressure); 
            network.totalFlowRate = 0;
            % calculate flowrate of links residence time
            for ii = 1:network.numberOfLinks
                
                node1Index = network.Links{ii}.pore1Index;
                node2Index = network.Links{ii}.pore2Index;
                
                if ~network.Links{ii}.isInlet && ~network.Links{ii}.isOutlet
                    
                    % calculate the flow rate of the fluid
                    flowRate_link(ii) = network.Links{ii}.cylindricalConductanceSinglePhase * ...
                        abs(network.Nodes{node1Index}.waterPressure - ...
                        network.Nodes{node2Index}.waterPressure);
                    
                elseif network.Links{ii}.isInlet
                    
                    % calculate the flow rate of the fluid
                    flowRate_link(ii) = network.Links{ii}.cylindricalConductanceSinglePhase * ...
                        abs(inletPressure - ...
                        network.Nodes{node2Index}.waterPressure);
                else
                    
                    % calculate the flow rate of the fluid
                    flowRate_link(ii) = network.Links{ii}.cylindricalConductanceSinglePhase * ...
                        abs(network.Nodes{node1Index}.waterPressure - ...
                        outletPressure); 
                    network.totalFlowRate = network.totalFlowRate + flowRate_link(ii);
                end 
                residenceTime_link(ii) = network.Links{ii}.volume/flowRate_link(ii);
                diffusion_link (ii) = effectiveDiffusion * network.Links{ii}.area / network.Links{ii}.linkLength;
            end 
            timeStep = min(nonzeros(residenceTime_link));
%             timeStep = timeStep *10;
            network.velocity = network.totalFlowRate * network.xDimension / network.poreVolume;
            
            % for quasi-static must be less than 10e-7
            network.capillaryNumber = network.waterViscosity * network.velocity/ network.sig_ow;               
            % for perfect mixing must be less than 1: diffusion is dominant rather than advection
            network.pecletNumber = network.xDimension * network.velocity / effectiveDiffusion;
            
            % reset inlet pressure
            if (network.pecletNumber-1) > 10 ^(-2)
                inletPressure = inletPressure*0.93;
                network.pecletNumber
            elseif (1-network.pecletNumber) > 10^(-2)
                inletPressure = inletPressure*1.1; 
                network.pecletNumber               
            end
            
            end
            inletPressure
             
            flowRate_node = zeros(network.numberOfNodes,1);
            diffusion_node = zeros(network.numberOfNodes,1);
            A = zeros(network.numberOfNodes,1);  
            G = zeros(network.numberOfNodes,1);  
            B = diffusion_link;   
            I = zeros(network.numberOfLinks,1);
            H = zeros(network.numberOfLinks,1); 
            for i = 1:network.numberOfNodes  
                    
                for j = 1:network.Nodes{i}.connectionNumber 
                    
                    connectedLinkIndex = network.Nodes{i}.connectedLinks(j);                    
                    connectedNodeIndex = network.Nodes{i}.connectedNodes(j);      
                    
                    I(connectedLinkIndex) = timeStep / network.Links{connectedLinkIndex}.volume;
                    H(connectedLinkIndex) = 1 + timeStep / network.Links{connectedLinkIndex}.volume * ...
                        (flowRate_link(connectedLinkIndex)+ diffusion_link(connectedLinkIndex)); 
                                        
                    % determine link flowing into this node
                    if connectedNodeIndex ~= 0 && connectedNodeIndex ~= -1                        
                        
                        if network.Nodes{connectedNodeIndex}.waterPressure > network.Nodes{i}.waterPressure                             
                            flowRate_node(i) = flowRate_node(i) + flowRate_link(connectedLinkIndex); 
                            diffusion_node(i) = diffusion_node(i) + diffusion_link(connectedLinkIndex);  
                        end
                            
                    elseif connectedNodeIndex == -1                                                
                            flowRate_node(i) = flowRate_node(i) + flowRate_link(connectedLinkIndex); 
                            diffusion_node(i) = diffusion_node(i) + diffusion_link(connectedLinkIndex); 
                    end
                end 
                A(i) = 1 + timeStep / network.Nodes{i}.volume * (flowRate_node(i) + diffusion_node(i));
                G(i) = timeStep / network.Nodes{i}.volume;
            end
            
            % calculation of 3 Unknowns (concentration of nodes & links) in each timeStep
            
            t = 0;
            time = 0;
            simulationTime = poreVolumeSimulation / network.totalFlowRate;
            injectionTime = poreVolumeInjected / network.totalFlowRate;
            
            fprintf('TimePV %3.5f\n',network.poreVolume/network.totalFlowRate);            
            fprintf('simulationTime %3.5f\n',simulationTime);
            fprintf('injectionTime %3.5f\n',injectionTime);
            fprintf('injectionT  %3.5f\n',round(injectionTime/timeStep)+1);
            
            % Plot & Animation
            figure('name','BTC')
            title('Break Through Curve')
            xlabel('Time(s)')
            ylabel('DimensionlessConcentration(-)')
            h = animatedline;
            h.Color = 'b';
            h.LineStyle = '-';
            h.LineWidth = 2;
            axis([0 simulationTime 0 1])
            
            timePlot = zeros(round(simulationTime/timeStep)+1 ,1);
            flux_averagedConcentration = zeros(round(simulationTime/timeStep)+1 ,1);
            network.BreakThroughCurve_singlePhase = zeros(round(simulationTime/timeStep)+1 ,2);
            soluteConcentration1 = soluteConcentration;
            
            while time < simulationTime
                
                if time > injectionTime
                    soluteConcentration = 0;
                end
                
                t = t+1;
                time = time + timeStep;
                timePlot(t) = time;
                sumOfConcentration = 0;
                sumOfFlowRate = 0;
                
                Factor = zeros(network.numberOfNodes + network.numberOfLinks, network.numberOfNodes + network.numberOfLinks);
                Known = zeros(network.numberOfNodes + network.numberOfLinks, 1);
                
                % calculate concentration of nodes & links based on eq. 8 & 9
                for i = 1:network.numberOfNodes + network.numberOfLinks
                    if i <= network.numberOfNodes
                        for j = 1:network.Nodes{i}.connectionNumber
                            
                            connectedLinkIndex = network.Nodes{i}.connectedLinks(j);
                            connectedNodeIndex = network.Nodes{i}.connectedNodes(j);
                            jj = network.numberOfNodes + connectedLinkIndex; 
                            
                            % determine link flowing into this node
                            if connectedNodeIndex ~= 0 && connectedNodeIndex ~= -1
                                
                                if network.Nodes{connectedNodeIndex}.waterPressure > network.Nodes{i}.waterPressure 
                                Factor(i, jj) = Factor(i, jj) - ...
                                    G(i)*(B(connectedLinkIndex)+flowRate_link(connectedLinkIndex))* network.Links{connectedLinkIndex}.concentration(t);
                                end
                                
                            elseif connectedNodeIndex == -1                                 
                                Factor(i, jj) = Factor(i, jj) - ...
                                    G(i)*(B(connectedLinkIndex)+flowRate_link(connectedLinkIndex))* network.Links{connectedLinkIndex}.concentration(t); 
                            end
                        end
                        
                        Factor(i, i) = A(i); 
                        Known(i,1) = network.Nodes{i}.concentration(t);
                    else
                        jj = i - network.numberOfNodes;
                        node1Index = network.Links{jj}.pore1Index;
                        node2Index = network.Links{jj}.pore2Index;
                        
                        if ~network.Links{jj}.isInlet && ~network.Links{jj}.isOutlet
                            if network.Nodes{node1Index}.waterPressure > network.Nodes{node2Index}.waterPressure
                                Factor(i, node1Index) = -I(jj)*(flowRate_link(jj)+ B(jj)) ;
                                Factor(i, node2Index) = -I(jj)*B(jj);
                            elseif network.Nodes{node2Index}.waterPressure > network.Nodes{node1Index}.waterPressure
                                Factor(i, node2Index) = -I(jj)*(flowRate_link(jj)+ B(jj)) ;
                                Factor(i, node1Index) = -I(jj)*B(jj);
                            end                            
                            Known(i,1) = network.Links{jj}.concentration(t);
                            Factor(i, i) = H(jj) ;
                            
                        elseif network.Links{jj}.isInlet
                            Factor(i, node2Index) = -I(jj)*B(jj);
                            Known(i,1) = network.Links{jj}.concentration(t) + I(jj)*(flowRate_link(jj)+ B(jj))*soluteConcentration;
                            Factor(i, i) = H(jj) ;
                            
                        elseif network.Links{jj}.isOutlet
                            Factor(i, node1Index) = -I(jj)*(flowRate_link(jj)+ B(jj));
                            Known(i,1) = network.Links{jj}.concentration(t);
                            Factor(i, i) = H(jj)-I(jj)*B(jj) ;
                        end 
                    end
                end
                
                nodesConcentration_new = gmres (Factor, Known,[], 1e-10, network.numberOfNodes + network.numberOfLinks);
                
                % asign new concentration of nodes
                for i = 1:network.numberOfNodes
                    if nodesConcentration_new(i) > soluteConcentration1
                        network.Nodes{i}.concentration(t+1) = soluteConcentration1;
                    else
                        network.Nodes{i}.concentration(t+1) = nodesConcentration_new(i);
                    end
                end
                
                % calculate new concentration of links
                for i = 1:network.numberOfLinks
                    jj = i + network.numberOfNodes;
                    if nodesConcentration_new(jj) > soluteConcentration1
                        network.Links{i}.concentration(t+1) = soluteConcentration1;
                    else
                        network.Links{i}.concentration(t+1) = nodesConcentration_new(jj);
                    end
                    if network.Links{i}.isOutlet 
                        sumOfConcentration = sumOfConcentration + ...
                            network.Links{i}.concentration(t)*flowRate_link(i);
                        sumOfFlowRate = sumOfFlowRate + flowRate_link(i);
                    end
                end
                % calculate BreakThroughCurve at outlet of network
                flux_averagedConcentration(t) = sumOfConcentration / sumOfFlowRate / soluteConcentration1;
                
                % Plot & Animation
                addpoints(h,timePlot(t),flux_averagedConcentration(t));
                drawnow
                
                network.BreakThroughCurve_singlePhase(t,1) = timePlot(t);
                network.BreakThroughCurve_singlePhase(t,2) = flux_averagedConcentration(t);
                
                if mod(t,10)==0
                    network.visualization('Diff',t);
                end
            end 
            
            % Plot
            plot(timePlot,flux_averagedConcentration,'*');
        end
        