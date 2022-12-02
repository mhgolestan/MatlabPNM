function [oilInletClusterIndex, oilOutletClusterIndex] = ClusteringOil_new(network)
 
for i = 1:network.numberOfNodes
    network.Nodes{i}.isVisited = false;
    network.Nodes{i}.oilConnectedOutlet = false;  
    network.Nodes{i}.oilClusterIndex = nan;
end
for i =1:network.numberOfLinks
    network.Links{i}.isVisited = false;
    network.Links{i}.oilConnectedOutlet = false; 
    network.Links{i}.oilClusterIndex = nan; 
end

oilOutletClusterIndex = 0;
for i = 1:network.numOfOutletLinks
    linkIndex = network.OutletLinksIndex(i);
    if ~network.Links{linkIndex}.isVisited && ...
            (network.Links{linkIndex}.occupancy == 'B' || any(network.Links{linkIndex}.oilLayerExist)) 
        oilOutletClusterIndex = oilOutletClusterIndex +1;
        network.Links{linkIndex}.isVisited = true;
        network.Links{linkIndex}.oilConnectedOutlet = true;
        network.Links{linkIndex}.SweepOilAdjacentPores(network, oilOutletClusterIndex);
    end
end

oilInletClusterIndex = zeros(network.numOfInletLinks);
for i = 1:network.numOfInletLinks
    linkIndex = network.InletLinksIndex(i);
    if any(network.Links{linkIndex}.oilClusterIndex) 
        oilInletClusterIndex = network.Links{linkIndex}.oilClusterIndex;
    end
end
oilInletClusterIndex = nonzeros(oilInletClusterIndex);