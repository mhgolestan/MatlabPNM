function calculateFlowRate(obj)
    % location of the surface whcih the flow rate should be
    % calculated through is the half distance of the network
    surfaceLocation = obj.xDimension / 2;
    flowRate = 0;

    %search through all the links
    for ii = 1:obj.numberOfLinks
        %the link should not be nether inlet nor outlet becasue it
        %makes problem in the index of the connected nodes
        if ~obj.Links{ii}.isInlet && ~obj.Links{ii}.isOutlet

            node1Index = obj.Links{ii}.pore1Index;
            node2Index = obj.Links{ii}.pore2Index;
           %if the two connected nodes pass through the sufrace
            %count the flow of fluid passing the link connecting
            %them
            if (obj.Nodes{node1Index}.x_coordinate < surfaceLocation && ...
                    obj.Nodes{node2Index}.x_coordinate > surfaceLocation) ||...
                (obj.Nodes{node2Index}.x_coordinate < surfaceLocation && ...
                    obj.Nodes{node1Index}.x_coordinate > surfaceLocation)    


                %calculate the conductivity of the linkNode system
                nodeLinkSystemConductance = ((obj.Links{ii}.linkLength /...
                    obj.Links{ii}.conductance) +...
                    0.5 *...
                    ((obj.Links{ii}.pore1Length / obj.Nodes{node1Index}.conductance) +...
                    (obj.Links{ii}.pore2Length / obj.Nodes{node2Index}.conductance)))^-1;

                % calculate the flow rate of the fluid
                flowRate = flowRate + ...
                    abs(nodeLinkSystemConductance * ...
                    (obj.Nodes{node1Index}.waterPressure - ...                         
                    obj.Nodes{node2Index}.waterPressure));    
%                           + 9810*(obj.Nodes{node1Index}.z_coordinate-obj.Nodes{node2Index}.z_coordinate)-...
            end
        end 
    end
    obj.totalFlowRate = flowRate;           
end
