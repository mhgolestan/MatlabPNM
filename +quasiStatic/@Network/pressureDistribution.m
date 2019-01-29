function pressureDistribution (obj, inletPressure, outletPressure)
    % pressureDistribution Summary of this method goes here
    %   Detailed explanation goes here
    Factor = zeros(obj.numberOfNodes, obj.numberOfNodes);
    B = zeros(obj.numberOfNodes, 1);

%             for thisNodeIndex = 1:obj.numberOfNodes
%                 connectedLinksToThisNode = obj.Nodes{thisNodeIndex}.connectedLinks;
%                 connectedNodesToThisNode = obj.Nodes{thisNodeIndex}.connectedNodes;
%                 
%                 for iterator = 1:length(connectedLinksToThisNode)
%                    nodeLinkSystemConductance = 0;
%                    connectedLinkIndex = connectedLinksToThisNode(iterator);
%                    connectedNodeIndex = connectedNodesToThisNode(iterator);
%                    if obj.Links{connectedLinkIndex}.isInlet
%                        nodeLinkSystemConductance = ((obj.Links{connectedLinkIndex}.linkLength /...
%                         obj.Links{connectedLinkIndex}.conductance) +...
%                         0.5 *...
%                         ((obj.Links{connectedLinkIndex}.pore2Length / obj.Nodes{thisNodeIndex}.conductance)))^-1;
%                     
%                     Factor(thisNodeIndex, thisNodeIndex) = Factor(thisNodeIndex, thisNodeIndex) + nodeLinkSystemConductance;
%                     B(thisNodeIndex) = nodeLinkSystemConductance * inletPressure;
% 
%                    elseif obj.Links{connectedLinkIndex}.isOutlet
%                        nodeLinkSystemConductance = ((obj.Links{connectedLinkIndex}.linkLength /...
%                         obj.Links{connectedLinkIndex}.conductance) +...
%                         0.5 *...
%                         ((obj.Links{connectedLinkIndex}.pore1Length / obj.Nodes{thisNodeIndex}.conductance)))^-1;
%                     
%                     Factor(thisNodeIndex, thisNodeIndex) = Factor(thisNodeIndex, thisNodeIndex) + nodeLinkSystemConductance;
%                     B(thisNodeIndex) = nodeLinkSystemConductance * outletPressure;
%                    
%                    else
%                        if thisNodeIndex == obj.Links{connectedLinkIndex}.pore1Index
%                            nodeLinkSystemConductance = ((obj.Links{connectedLinkIndex}.linkLength /...
%                             obj.Links{connectedLinkIndex}.conductance) +...
%                             0.5 *...
%                             ((obj.Links{connectedLinkIndex}.pore1Length / obj.Nodes{thisNodeIndex}.conductance) +...
%                             (obj.Links{connectedLinkIndex}.pore2Length / obj.Nodes{connectedNodeIndex}.conductance)))^-1;  
%                        else
%                          nodeLinkSystemConductance = ((obj.Links{connectedLinkIndex}.linkLength /...
%                             obj.Links{connectedLinkIndex}.conductance) +...
%                             0.5 *...
%                             ((obj.Links{connectedLinkIndex}.pore2Length / obj.Nodes{thisNodeIndex}.conductance) +...
%                             (obj.Links{connectedLinkIndex}.pore1Length / obj.Nodes{connectedNodeIndex}.conductance)))^-1;  
%                        end
%                        
%                         Factor(thisNodeIndex, thisNodeIndex) = Factor(thisNodeIndex, thisNodeIndex) + nodeLinkSystemConductance;
%                             
%                         Factor(thisNodeIndex, connectedNodeIndex) = Factor(thisNodeIndex, connectedNodeIndex) - nodeLinkSystemConductance;
% %                         Factor(connectedNodeIndex, thisNodeIndex) = Factor(connectedNodeIndex, thisNodeIndex) - nodeLinkSystemConductance;
% 
%                    end
%                end
%             end

    for ii = 1:obj.numberOfLinks

        node1Index = obj.Links{ii}.pore1Index;
        node2Index = obj.Links{ii}.pore2Index;

        % if the link is connected to inlet (index of node 1 is -1 which does not exist) 
        if obj.Links{ii}.isInlet
            nodeLinkSystemConductance = ((obj.Links{ii}.linkLength /...
                obj.Links{ii}.conductance) +...
                0.5 *...
                ((obj.Links{ii}.pore2Length / obj.Nodes{node2Index}.conductance)))^-1;

            Factor(node2Index, node2Index) = Factor(node2Index, node2Index) + nodeLinkSystemConductance;
            B(node2Index) = nodeLinkSystemConductance * inletPressure;
%                     B(node2Index) = nodeLinkSystemConductance * (inletPressure-9810*obj.Nodes{node2Index}.z_coordinate);
        % if the link is connected to outlet (index of node 2 is 0 which does not exist)
        elseif obj.Links{ii}.isOutlet
             nodeLinkSystemConductance = ( (obj.Links{ii}.linkLength /...
                obj.Links{ii}.conductance) +...
                0.5 *...
                ((obj.Links{ii}.pore1Length / obj.Nodes{node1Index}.conductance)))^-1;
            Factor(node1Index, node1Index) = Factor(node1Index, node1Index) + nodeLinkSystemConductance;
            B(node1Index) = nodeLinkSystemConductance * outletPressure;
%                     B(node1Index) = nodeLinkSystemConductance * (outletPressure-9810*obj.Nodes{node1Index}.z_coordinate);

        %if the link is neither inlet nor outlet    
        else
            nodeLinkSystemConductance = ((obj.Links{ii}.linkLength /...
                obj.Links{ii}.conductance) +...
                0.5 *...
                ((obj.Links{ii}.pore1Length / obj.Nodes{node1Index}.conductance) +...
                (obj.Links{ii}.pore2Length / obj.Nodes{node2Index}.conductance)))^-1;   

            Factor(node1Index, node1Index) = Factor(node1Index, node1Index) + nodeLinkSystemConductance;
            Factor(node2Index, node2Index) = Factor(node2Index, node2Index) + nodeLinkSystemConductance;
            Factor(node1Index, node2Index) = Factor(node1Index, node2Index) - nodeLinkSystemConductance;
            Factor(node2Index, node1Index) = Factor(node2Index, node1Index) - nodeLinkSystemConductance;

        end     
    end

    % using Preconditioned conjugate gradients method to solve the
    % pressure distribution 
    nodesPressure = pcg(Factor, B, 1e-7, 1000);

    %assign the pressure values to each node
    for ii = 1:obj.numberOfNodes
        obj.Nodes{ii}.waterPressure = nodesPressure(ii);      
    end

    %assign pressure values to links, since the surface where
    %flowrate is calculated through might pass through the links
    for ii = 1:obj.numberOfLinks
        if obj.Links{ii}.isInlet
            obj.Links{ii}.waterPressure =...
                obj.Nodes{obj.Links{ii}.pore2Index}.waterPressure;
        elseif obj.Links{ii}.isOutlet
            obj.Links{ii}.waterPressure =...
                obj.Nodes{obj.Links{ii}.pore1Index}.waterPressure;                    
        else
            obj.Links{ii}.waterPressure =...
                (obj.Nodes{obj.Links{ii}.pore1Index}.waterPressure + ...
                obj.Nodes{obj.Links{ii}.pore2Index}.waterPressure) / 2;
        end
    end
end
