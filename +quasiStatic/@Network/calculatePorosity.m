%% Porosity calculation
function obj = calculatePorosity(obj)
    nodesVolume = 0;
    linksVolume = 0;
    for ii = 1:obj.numberOfNodes
        nodesVolume = nodesVolume + (obj.Nodes{ii}.volume);
    end
    for ii = 1:obj.numberOfLinks
        linksVolume = linksVolume + (obj.Links{ii}.volume);   
    end
    obj.Porosity = (linksVolume + nodesVolume) / (obj.xDimension * obj.yDimension * obj.zDimension);  
    obj.poreVolume = linksVolume + nodesVolume;
end 