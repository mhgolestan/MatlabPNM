function PrimaryDrainage(obj)              
     %% determining the capillary pressure level interval
     Pc_threshold = zeros(obj.numberOfLinks,1);  
     Pc_threshold_n = zeros(obj.numberOfLinks,1); 
     for i = 1:obj.numberOfLinks                
         Pc_threshold(i) = obj.Links{i}.thresholdPressure;
     end

     % Pc_interval
     max_Pc = max(Pc_threshold);
     min_Pc = min(Pc_threshold);
     Pc_interval = (max_Pc - min_Pc)/40;
     Pc_drain_max = 0.5*max_Pc;
%              simTimes = Pc_drain_max / Pc_interval;
     fprintf('\nPc_interval is: %f \n', Pc_interval);
     fprintf('Pc_drain_max is: %f \n', Pc_drain_max);       
     Pc = 0;   
     t = 1;
     obj.Sw_drain(t,1) = 1; 
     obj.Pc_drain_curve(t,1) = 0;

     %% Cycle of increasing Pressure
     while Pc < Pc_drain_max              

     % Pc Step Calculation 
     if  obj.Sw_drain(t,1) > 0.9 
         Pc = Pc + 0.2*Pc_interval;
     else
         Pc = Pc + Pc_interval;                 
     end    
     t = t + 1;
     %% Find new inlet-Links with threshold pressure < Pc             
     for i = 1:obj.numberOfLinks                  
          node1Index = obj.Links{i}.pore1Index;
          node2Index = obj.Links{i}.pore2Index;
          if obj.Links{i}.isInlet && obj.Links{i}.occupancy == 'A'
             if Pc_threshold(i) <= Pc  
%                          obj.Links{i}.occupancy = 'B';
                 if obj.Nodes{node2Index}.occupancy == 'A' && obj.Nodes{node2Index}.thresholdPressure <=Pc
                 Pc_threshold_n(i,1)= Pc_threshold(i);
                 end
             end
          elseif obj.Links{i}.isOutlet && obj.Links{i}.occupancy == 'A'                     
                   if obj.Nodes{node1Index}.occupancy == 'B' && Pc_threshold(i) <= Pc
                       obj.Links{i}.occupancy = 'B';
                   end
          elseif ~obj.Links{i}.isOutlet && ~obj.Links{i}.isInlet && obj.Links{i}.occupancy == 'A' && Pc_threshold(i) <= Pc                      
              if obj.Nodes{node1Index}.occupancy == 'B' 
%                           obj.Links{i}.occupancy = 'B';
                  if obj.Nodes{node2Index}.occupancy == 'A' && obj.Nodes{node2Index}.thresholdPressure <=Pc
                      Pc_threshold_n(i,1)= Pc_threshold(i);
                  end
              elseif obj.Nodes{node2Index}.occupancy == 'B'
%                           obj.Links{i}.occupancy = 'B';
                  if obj.Nodes{node1Index}.occupancy == 'A' && obj.Nodes{node1Index}.thresholdPressure <=Pc
                      Pc_threshold_n(i,1)= Pc_threshold(i);
                  end
              end                      
         end
     end

     %% Add Links which have Pc_threshold < Pc in each steps and also have oil-saturated neighbour Node 
     while min(nonzeros(Pc_threshold_n))<= Pc
         %check & sort Links based on Pc_Threshold
         [~, ix] = sort(Pc_threshold_n(1:end), 1);
%                  throat_list = ix;
         i = ix(obj.numberOfLinks - length(nonzeros(Pc_threshold_n))+1);
         Pc_threshold_n(i) = 0;                 
         node1Index = obj.Links{i}.pore1Index;
         node2Index = obj.Links{i}.pore2Index;
         if obj.Links{i}.isInlet && obj.Links{i}.occupancy == 'A'&& Pc_threshold(i) <= Pc
                 obj.Links{i}.occupancy = 'B';
                 if obj.Nodes{node2Index}.occupancy == 'A' && obj.Nodes{node2Index}.thresholdPressure <=Pc
                     obj.Nodes{node2Index}.occupancy = 'B';
                     for j=1:obj.Nodes{node2Index}.connectionNumber
                         if obj.Nodes{node2Index}.connectedLinks(j)~=i
                             Pc_threshold_n(obj.Nodes{node2Index}.connectedLinks(j),1)= Pc_threshold(obj.Nodes{node2Index}.connectedLinks(j));
                         end
                     end
                 end
          elseif obj.Links{i}.isOutlet && obj.Links{i}.occupancy == 'A'                     
                   if obj.Nodes{node1Index}.occupancy == 'B' && Pc_threshold(i) <= Pc
                       obj.Links{i}.occupancy = 'B';
                   end
          elseif ~obj.Links{i}.isOutlet && ~obj.Links{i}.isInlet && obj.Links{i}.occupancy == 'A' && Pc_threshold(i) <= Pc                      
              if obj.Nodes{node1Index}.occupancy == 'B' 
                  obj.Links{i}.occupancy = 'B';
                  if obj.Nodes{node2Index}.occupancy == 'A' && obj.Nodes{node2Index}.thresholdPressure <=Pc
                      obj.Nodes{node2Index}.occupancy = 'B';
                      for j=1:obj.Nodes{node2Index}.connectionNumber
                         if obj.Nodes{node2Index}.connectedLinks(j)~=i
                             Pc_threshold_n(obj.Nodes{node2Index}.connectedLinks(j),1)= Pc_threshold(obj.Nodes{node2Index}.connectedLinks(j));
                         end
                     end
                  end
              elseif obj.Nodes{node2Index}.occupancy == 'B'
                  obj.Links{i}.occupancy = 'B';
                  if obj.Nodes{node1Index}.occupancy == 'A' && obj.Nodes{node1Index}.thresholdPressure <=Pc
                      obj.Nodes{node1Index}.occupancy = 'B';
                      for j=1:obj.Nodes{node1Index}.connectionNumber
                         if obj.Nodes{node1Index}.connectedLinks(j)~=i
                             Pc_threshold_n(obj.Nodes{node1Index}.connectedLinks(j),1)= Pc_threshold(obj.Nodes{node1Index}.connectedLinks(j));
                         end
                     end
                  end
              end
         end
%                  if obj.Links{throat_list(end)}.occupancy == 'A' 
%                      obj.Links{throat_list(index)}.occupancy = 'B';                     
%                      node1Index = obj.Links{throat_list(end)}.pore1Index;
%                      node2Index = obj.Links{throat_list(end)}.pore2Index;
%                      % if the link is connected to inlet (index of node 1 is -1 which does not exist) 
%                      if obj.Links{throat_list(end)}.isInlet
%                          if obj.Nodes{node2Index}.occupancy == 'A' && obj.Nodes{node2Index}.thresholdPressure <= Pc
%                              obj.Nodes{node_index}.occupancy = 'B';
%                               Pc_threshold_n(obj.Nodes{node_index}.connectedLinks)= Pc_threshold(obj.Nodes{node_index}.connectedLinks);                             
%                              new = new + obj.Nodes{node_index}.connectionNumber;
%                          end 
%                      elseif ~obj.Links{throat_list(index)}.isInlet && ~obj.Links{throat_list(index)}.isOutlet
%                          if obj.Nodes{node1Index}.occupancy == 'A' && obj.Nodes{node1Index}.thresholdPressure <= Pc
%                              obj.Nodes{node1Index}.occupancy = 'B';                                 
%                              Pc_threshold_n(obj.Nodes{node1Index}.connectedLinks)= Pc_threshold(obj.Nodes{node1Index}.connectedLinks);                         
%                              new = new + obj.Nodes{node1Index}.connectionNumber;
%                          end
%                          if obj.Nodes{node2Index}.occupancy == 'A' && obj.Nodes{node2Index}.thresholdPressure <= Pc
%                              obj.Nodes{node2Index}.occupancy = 'B';
%                              Pc_threshold_n(obj.Nodes{node2Index}.connectedLinks)= Pc_threshold(obj.Nodes{node2Index}.connectedLinks);
%                              new = new + obj.Nodes{node2Index}.connectionNumber;
%                          end
%                      end   
%                  end
%                  Pc_threshold_n(throat_list(index))=0;
     end

     % Updating element saturations and conductances
     obj.Sw_drain(t,1) = calculateSaturations(obj, Pc);            

     % Preparing Pc , Sw & Kr data                  
     obj.Pc_drain_curve(t,1) = Pc;               

     %% Relative Permeability Calculation
     % [kr_oil(t,1),kr_water(t,1)] = k_rel(1,0);         

     end             
     fprintf('simTimes is: %f \n', t);         
     plot(obj.Sw_drain,obj.Pc_drain_curve,'--r')
     title('Drainage Cappilary Pressure Curves')
     xlabel('Sw')
     xlim([0 1.05])
     ylabel('Pc (Pa)')
     legend('Drainage Pc')      
end
