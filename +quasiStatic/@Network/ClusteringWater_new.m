function [waterInletClusterIndex, waterOutletClusterIndex] = ClusteringWater_new(network)
 
for i = 1:network.numberOfNodes
    network.Nodes{i}.isVisited = false;
    network.Nodes{i}.waterConnectedOutlet = false;
    network.Nodes{i}.waterClusterIndex = nan; 
end
for i =1:network.numberOfLinks
    network.Links{i}.isVisited = false; 
    network.Links{i}.waterConnectedOutlet = false;
    network.Links{i}.waterClusterIndex = nan;
end
waterOutletClusterIndex = 0;

for i = 1:network.numOfOutletLinks
    linkIndex = network.OutletLinksIndex(i);
    if ~network.Links{linkIndex}.isVisited &&...
            (network.Links{linkIndex}.occupancy == 'A' || any(network.Links{linkIndex}.waterCornerExist))
        waterOutletClusterIndex = waterOutletClusterIndex +1;
        network.Links{linkIndex}.isVisited = true;
        network.Links{linkIndex}.waterConnectedOutlet = true;
        network.Links{linkIndex}.SweepWaterAdjacentPores(network, waterOutletClusterIndex);
    end
end

waterInletClusterIndex = zeros(network.numOfInletLinks);
for i = 1:network.numOfInletLinks
    linkIndex = network.InletLinksIndex(i);
    if any(network.Links{linkIndex}.waterClusterIndex) 
        waterInletClusterIndex = network.Links{linkIndex}.waterClusterIndex;
    end
end
waterInletClusterIndex = nonzeros(waterInletClusterIndex);